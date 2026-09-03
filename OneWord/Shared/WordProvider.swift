//
//  WordProvider.swift
//  OneWord — Shared model (member of app + widget targets)
//
//  The only thing that touches the bundle. Selection is date-derived and
//  deterministic, so the app and the widget compute the SAME word for a day
//  with no shared runtime state.
//

import Foundation

// nonisolated for the same reason as AppGroup — the widget and SavedWords.lookUp
// both build one off the main actor. It's a pure value type, so this is free.
nonisolated struct WordProvider {
    private let words: [Word]
    private let calendar: Calendar
    /// Reading order: a per-dictionary shuffle of `words.indices`, seeded by the
    /// dictionary id. The day walks THIS, not the file, so consecutive days are
    /// unrelated and two dictionaries never open on the same position. Being a
    /// permutation, every word still appears once before any repeats.
    private let order: [Int]

    /// Injectable init for tests; the default loads the bundled list.
    /// `seed` decorrelates dictionaries — the bundle init derives it from the id.
    init(words: [Word], seed: UInt64 = 0, calendar: Calendar = .current) {
        precondition(!words.isEmpty, "WordProvider needs at least one word")
        self.words = words
        self.calendar = calendar
        var rng = SplitMix64(seed: seed)
        // ponytail: stdlib shuffle. Its algorithm isn't a documented cross-version
        // guarantee, but app and widget share one runtime so they can never disagree —
        // a future stdlib change would only re-scatter the order, not desync them.
        self.order = Array(words.indices).shuffled(using: &rng)
    }

    /// The word for a given day, plus an optional manual `offset` (the widget's
    /// refresh button bumps this). Maps to a stable position so the same day+offset
    /// always yields the same word (and wraps once the list ends).
    ///
    /// A word you just captured takes the day, whatever dictionary is selected. That
    /// breaks no invariant: the refresh button already mutates today's word the same
    /// way, and app and widget both read the pin from the App Group, so they agree.
    func word(for date: Date, offset: Int = 0, pinned: Word? = nil) -> Word {
        if let pinned { return pinned }
        // Days since a fixed reference day → position. Non-negative via modulo fix-up.
        let day = calendar.startOfDay(for: date)
        let ref = calendar.startOfDay(for: Date(timeIntervalSinceReferenceDate: 0))
        let days = calendar.dateComponents([.day], from: ref, to: day).day ?? 0
        let position = (((days + offset) % order.count) + order.count) % order.count
        return words[order[position]]
    }

    /// The whole collection, for the browse/search list.
    var allWords: [Word] { words }
}

nonisolated extension WordProvider {
    /// Loads `words.json` from the given bundle. Traps on a missing/broken file —
    /// the word list ships with the app, so a failure here is a build error, not
    /// a runtime condition to recover from.
    init(bundle: Bundle = .main, resource: String = "words", calendar: Calendar = .current) {
        // "saved" isn't a bundled file — it's the words you captured yourself. Handled
        // here so EVERY caller (app and widget alike) is safe with it, rather than each
        // one having to remember to check. Empty → the placeholder keeps the
        // precondition above satisfied and explains the feature in the list.
        if resource == SavedWords.resource {
            let saved = SavedWords.all.map(\.word)
            self.init(words: saved.isEmpty ? [SavedWords.placeholder] : saved,
                      seed: Self.seed(for: resource), calendar: calendar)
            return
        }
        // Panes, dictionary switches and the profile's shelf scan all rebuild
        // providers; words.json alone is 3.7MB, so decode each list once.
        if bundle === Bundle.main, let cached = Self.cache.object(forKey: resource as NSString) {
            self.init(words: cached.words, seed: Self.seed(for: resource), calendar: calendar)
            return
        }
        guard let url = bundle.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("\(resource).json is missing from the bundle — check target membership")
        }
        do {
            let words = try JSONDecoder().decode([Word].self, from: data)
            if bundle === Bundle.main {
                Self.cache.setObject(WordList(words), forKey: resource as NSString)
            }
            self.init(words: words, seed: Self.seed(for: resource), calendar: calendar)
        } catch {
            fatalError("words.json failed to decode: \(error)")
        }
    }

    /// Decoded bundle lists, kept for the process. NSCache: thread-safe (the
    /// widget builds providers off the main actor) and evicts under pressure.
    /// "saved" never lands here — it's read fresh above, since it changes.
    private static let cache = NSCache<NSString, WordList>()

    /// FNV-1a over the dictionary id. Deliberately NOT `hashValue` — Swift seeds
    /// `Hasher` randomly per process, so the app and the widget would each shuffle
    /// differently and show different words for the same day.
    static func seed(for resource: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in resource.utf8 { hash = (hash ^ UInt64(byte)) &* 0x100_0000_01b3 }
        return hash
    }
}

/// NSCache stores objects, so the decoded list needs a box.
nonisolated private final class WordList: Sendable {
    let words: [Word]
    init(_ words: [Word]) { self.words = words }
}

/// Deterministic RNG for the shuffle — same seed, same order, in every process.
nonisolated private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
