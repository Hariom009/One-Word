//
//  RelatedWords.swift
//  OneWord — app target ONLY (deliberately not in Shared/: the widget's memory
//  ceiling rules the index out there, and Shared headers promise both targets).
//
//  "In the same vein": for each word, its nearest neighbours inside the open
//  dictionary, ranked by cosine similarity of a bag-of-embeddings centroid over
//  term + definition. Design: RELATED_WORDS_PLAN.md (r4).
//

import Foundation
import NaturalLanguage
import Observation

/// The whole algorithm, as a pure value type. Built off the main actor, then
/// handed over and read on it — sequential use, never concurrent (the store
/// serializes builds), which is what lets us not care whether NLEmbedding is
/// thread-safe.
nonisolated struct RelatedWordsIndex {
    private let entries: [(word: Word, vector: [Float])]
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

    /// 4-char canonical prefix — the dedupe key that kills `warm` → `warmed`.
    private static func stem(_ s: String) -> String { String(canon(s).prefix(4)) }

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
        var entries: [(word: Word, vector: [Float])] = []
        entries.reserveCapacity(words.count)
        for (i, word) in words.enumerated() {
            if i % 512 == 0 && Task.isCancelled { return nil }
            guard let vector = Self.centroid(of: word.term + " " + word.definition, embedding)
            else { continue }
            entries.append((word, vector))
        }
        self.entries = entries
        self.embedding = embedding
    }

    /// The query's centroid is computed on demand from the PASSED word — never by
    /// index lookup: today's word can be a pinned capture that is absent from the
    /// book being searched. [] is the quiet answer for anything unvectorisable.
    func nearest(to word: Word, limit: Int = 3) -> [Word] {
        // The em-dash teaching card is not a word — but its instructional
        // definition vectorises, so without this guard it would find "related"
        // words for a sentence about the Services menu.
        if word.term == SavedWords.placeholder.term { return [] }
        guard let query = Self.centroid(of: word.term + " " + word.definition, embedding)
        else { return [] }
        let queryCanon = Self.canon(word.term)
        let queryStem = Self.stem(word.term)
        var scored: [(word: Word, score: Float)] = []
        for entry in entries {
            if Self.canon(entry.word.term) == queryCanon { continue }
            if Self.stem(entry.word.term) == queryStem { continue }
            let score = Self.dot(query, entry.vector)
            if score >= Self.floor { scored.append((entry.word, score)) }
        }
        scored.sort { $0.score > $1.score }
        var results: [Word] = []
        var seenStems = Set<String>()
        for candidate in scored {
            let stem = Self.stem(candidate.word.term)
            guard seenStems.insert(stem).inserted else { continue }
            results.append(candidate.word)
            if results.count == limit { break }
        }
        return results
    }
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
    /// warning. Measured — see RELATED_WORDS_PLAN.md §5. The book is decoded in
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

    // ponytail: re-ranks once per body evaluation (~5ms at 12k words). Memoize
    // by term if a bigger dictionary ever lands.
    func related(to word: Word) -> [Word] { index?.nearest(to: word) ?? [] }
}
