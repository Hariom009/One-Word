//
//  RelatedWords.swift
//  OneWord — app target ONLY (deliberately not in Shared/: the widget's memory
//  ceiling rules the index out there, and Shared headers promise both targets).
//
//  "In the same vein": for each word, its nearest neighbours inside the open
//  dictionary, ranked by cosine similarity of a bag-of-embeddings centroid over
//  term + definition. Design: Docs/02_Plan/RELATED_WORDS_PLAN.md (r4).
//

import Foundation
import NaturalLanguage
import Observation

/// The whole algorithm, as a pure value type. Built off the main actor, then
/// handed over and read on it — sequential use, never concurrent (the store
/// serializes builds). NOTE: the embedding is RETAINED and used again by
/// `nearestScored` on the main actor (the query centroid is built on demand), so
/// it is not confined to the build the way the plan originally claimed. Stress
/// test: 400 concurrent queries against 6 concurrent builds produced no wrong
/// results and no crash, but that is evidence, not a thread-safety guarantee.
nonisolated struct RelatedWordsIndex {
    private let entries: [(word: Word, vector: [Float], canon: String)]
    private let embedding: NLEmbedding

    /// Words that made it into the index (for the check script's coverage assert).
    var count: Int { entries.count }

    // ponytail: floor 0.55 is a tuning knob, not a truth — measured good matches
    // score 0.73–0.87 and the 20-entry books clear it too (top scores 0.58–0.85).
    // Raise it toward ~0.65 if near-floor strangers (curiosities) ever grate.
    private static let floor: Float = 0.55

    private static let stopwords: Set<String> = [
        "the", "and", "that", "this", "with", "from", "have", "been", "being",
        "which", "their", "there", "about", "into", "than", "them", "then",
        "when", "what", "your", "will", "would", "could", "should", "also",
        "some", "such", "very", "more", "most", "other", "only", "over",
    ]

    /// One canonical identity for every term comparison: captures are stored
    /// lowercased while `startup` has 175 mixed-case terms — raw equality would
    /// show `KPI` as "related" to a captured `kpi`.
    private static func canon(_ s: String) -> String {
        s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Same word, or a trivial inflection of it — the test that kills
    /// `warm` → `warmed`. Takes ALREADY-canonical strings (entries store theirs).
    ///
    /// The prefix test is what a bare 4-character stem misses: `joy` never
    /// reaches a 4-char stem, so `joy`/`joyf` never matched and `joyfulness`
    /// sailed through as a "related" word. Measured on emotions.json before
    /// this fix: joy → joyfulness, joyousness.
    private static func sameRoot(_ a: String, _ b: String) -> Bool {
        a.hasPrefix(b) || b.hasPrefix(a) || a.prefix(4) == b.prefix(4)
    }

    /// Normalised centroid of the word vectors of `text`'s tokens, or nil when
    /// nothing vectorises (an em-dash placeholder, an empty captured definition).
    private static func centroid(of text: String, _ embedding: NLEmbedding) -> [Float]? {
        let tokens = canon(text)
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { $0.count > 3 && !stopwords.contains($0) }
        var sum = [Double](repeating: 0, count: embedding.dimension)
        var hits = 0
        for token in tokens {
            guard let v = embedding.vector(for: token) else { continue }
            for i in 0..<sum.count { sum[i] += v[i] }
            hits += 1
        }
        guard hits > 0 else { return nil }
        let magnitude = (sum.reduce(0) { $0 + $1 * $1 }).squareRoot()
        guard magnitude > 0 else { return nil }
        return sum.map { Float($0 / magnitude) }
    }

    private static func dot(_ a: [Float], _ b: [Float]) -> Float {
        var s: Float = 0
        for i in 0..<a.count { s += a[i] * b[i] }
        return s
    }

    /// nil when NLEmbedding is unavailable, or when the build was cancelled
    /// part-way. Cancellation is cooperative — the store cancelling its task
    /// does nothing unless this loop checks.
    init?(words: [Word]) {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else { return nil }
        var entries: [(word: Word, vector: [Float], canon: String)] = []
        entries.reserveCapacity(words.count)
        for (i, word) in words.enumerated() {
            if i % 512 == 0 && Task.isCancelled { return nil }
            guard let vector = Self.centroid(of: word.term + " " + word.definition, embedding)
            else { continue }
            entries.append((word, vector, Self.canon(word.term)))
        }
        self.entries = entries
        self.embedding = embedding
    }

    /// The query's centroid is computed on demand from the PASSED word — never by
    /// index lookup: today's word can be a pinned capture that is absent from the
    /// book being searched. [] is the quiet answer for anything unvectorisable.
    func nearest(to word: Word, limit: Int = 3) -> [Word] {
        nearestScored(to: word, limit: limit).map(\.word)
    }

    /// `nearest` with the similarity scores kept. Exposed so the check script can
    /// assert the floor actually EXCLUDES — with inclusion-only assertions,
    /// deleting the floor entirely still passed every check (verified).
    func nearestScored(to word: Word, limit: Int = 3) -> [(word: Word, score: Float)] {
        // The em-dash teaching card is not a word — but its instructional
        // definition vectorises, so without this guard it would find "related"
        // words for a sentence about the Services menu.
        if word.term == SavedWords.placeholder.term { return [] }
        guard let query = Self.centroid(of: word.term + " " + word.definition, embedding)
        else { return [] }
        let queryCanon = Self.canon(word.term)
        var scored: [(entry: (word: Word, vector: [Float], canon: String), score: Float)] = []
        scored.reserveCapacity(64)
        for entry in entries {
            // Covers self-exclusion too: sameRoot is true when the canons match.
            if Self.sameRoot(entry.canon, queryCanon) { continue }
            let score = Self.dot(query, entry.vector)
            if score >= Self.floor { scored.append((entry, score)) }
        }
        scored.sort { $0.score > $1.score }
        var results: [(word: Word, score: Float)] = []
        var accepted: [String] = []
        for candidate in scored {
            // Same root test as above, so `wistful` and `wistfulness` can't both
            // take a slot — and short terms are covered here as well.
            if accepted.contains(where: { Self.sameRoot($0, candidate.entry.canon) }) { continue }
            results.append((candidate.entry.word, candidate.score))
            accepted.append(candidate.entry.canon)
            if results.count == limit { break }
        }
        return results
    }

    /// The similarity floor, for the check script's exclusion assertion.
    static var similarityFloor: Float { floor }
}

/// Owns the index for the open dictionary. One instance, injected through the
/// environment at the NavigationStack root, so every WordDetail in a chain —
/// however deep — serves itself from the same build.
@Observable
final class RelatedWordsStore {
    private var index: RelatedWordsIndex?
    private var builtFor: String?
    private var task: Task<Void, Never>?
    private var observer: (any NSObjectProtocol)?

    init() {
        // A capture updates the saved list in place, so `builtFor` alone would
        // hold a stale My Words index until relaunch. The Services flow posts
        // from off-main; queue: .main hops back.
        observer = NotificationCenter.default.addObserver(
            forName: SavedWords.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.builtFor == SavedWords.resource else { return }
                self.builtFor = nil
                self.load(SavedWords.resource)
            }
        }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
    }

    /// @concurrent, NOT a bare `nonisolated async`: under this project's
    /// SWIFT_APPROACHABLE_CONCURRENCY a nonisolated async func inherits the
    /// CALLER's actor and would run the ~2.4s build on the main thread with no
    /// warning. Measured — see Docs/02_Plan/RELATED_WORDS_PLAN.md §5. The book is decoded in
    /// here too, off the main actor: WordProvider is a nonisolated struct and
    /// the decode costs ~21ms that WordViewModel already pays once on main.
    @concurrent private nonisolated func build(_ resource: String) async -> RelatedWordsIndex? {
        RelatedWordsIndex(words: WordProvider(resource: resource).allWords)
    }

    /// Idempotent — `.task` re-fires every time a pushed detail pops back, and
    /// repeat calls for the same book must be free. Takes the book's id (the
    /// caller normalizes through `Wordbook.named`), which keeps this file free
    /// of UI types so the check script compiles it against Foundation alone.
    func load(_ bookID: String) {
        guard builtFor != bookID else { return }
        builtFor = bookID
        index = nil
        let previous = task
        previous?.cancel()
        task = Task { [weak self] in
            await previous?.value   // serialize: never two NLEmbedding builds alive
            guard !Task.isCancelled else { return }
            let index = await self?.build(bookID)
            guard !Task.isCancelled else { return }
            self?.index = index
        }
    }

    // ponytail: re-ranks once per body evaluation — measured 3.6ms at 12k words
    // after precomputing the canonical terms. Memoize by term if a bigger
    // dictionary ever lands.
    /// `bookID` is required, not decorative: without it the store happily serves
    /// whichever index is loaded. Switching dictionaries from the browse list
    /// mounts a WordDetail whose `body` runs BEFORE its `.task` — so the first
    /// render asked the previous book's index and got another dictionary's words
    /// back, with live navigation links. Mismatch now answers [] until the right
    /// index lands.
    func related(to word: Word, in bookID: String) -> [Word] {
        guard builtFor == bookID else { return [] }
        return index?.nearest(to: word) ?? []
    }
}
