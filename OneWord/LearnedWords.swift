//
//  LearnedWords.swift
//  OneWord
//
//  Every word you've actually laid eyes on and when you first saw it, kept per
//  dictionary so the profile can say how far you've got through each shelf and
//  the Learned pane can read as a log. Recorded from WordDetail — the one view
//  EVERY full-view route ends at (today's word, a peeked word, a search result,
//  a related word), so one call site covers all of them.
//
//  App target only: the widget shows a word but never a full view, so it has no
//  business marking anything learned.
//

import Foundation

/// One line of the reading log: the word, the shelf it was read in, and when.
/// Keyed by shelf AND term — meeting a word in two dictionaries is two sightings,
/// and the log shows both.
struct LearnedWord: Identifiable, Hashable {
    let word: Word
    let shelf: String
    let seenAt: Date

    var id: String { shelf + "\u{0}" + word.term }

    /// Migrated sightings carry no real time. Anything before the app existed is
    /// one of those, and the log groups them under "Earlier" instead of inventing
    /// a moment you were there.
    static let epoch = Date(timeIntervalSinceReferenceDate: 0)   // 2001-01-01
    var isTimestamped: Bool { seenAt >= Self.epoch }
}

enum LearnedWords {
    static let didChange = Notification.Name("LearnedWordsDidChange")

    private static let key = "learnedWords"

    /// dictionary id → (term → when you first saw it). Keyed by term, so re-reading
    /// a word is free and the count stays honest.
    // ponytail: one JSON blob in the App Group, same shape as SavedWords. Short
    // terms, so even a fully-read 12k dictionary is ~300KB — move to a file in the
    // group container if that stops being true.
    static var all: [String: [String: Date]] {
        get {
            guard let data = AppGroup.defaults.data(forKey: key) else { return [:] }
            if let learned = try? JSONDecoder().decode([String: [String: Date]].self, from: data) {
                return learned
            }
            // Recorded before the log kept times: a set of terms per shelf. Keep
            // them — a shelf count you earned shouldn't vanish because the shape
            // changed — stamped `distantPast` so the log calls them "Earlier".
            // The two shapes can't be confused: one nests arrays, the other objects.
            // Migrating on read, not in place; the next `record` writes it back.
            guard let old = try? JSONDecoder().decode([String: Set<String>].self, from: data)
            else { return [:] }
            return old.mapValues {
                Dictionary(uniqueKeysWithValues: $0.map { ($0, Date.distantPast) })
            }
        }
        set {
            // Not `set(try? encode(...))` — that passes nil on a failed encode, and
            // set(nil:) DELETES the key. Keep the old list rather than wipe it.
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            AppGroup.defaults.set(data, forKey: key)
        }
    }

    /// Mark a word as seen, stamped now. Idempotent — the recording view re-fires
    /// on every appearance, so the FIRST sighting is the one kept, and only a real
    /// change is announced (the profile and the log shouldn't churn).
    static func record(_ word: Word, in dictionaryID: String) {
        // The Bookmarks placeholder is instructions, not a word.
        guard word.term != SavedWords.placeholder.term else { return }
        var learned = all
        guard learned[dictionaryID]?[word.term] == nil else { return }
        learned[dictionaryID, default: [:]][word.term] = Date()
        all = learned
        NotificationCenter.default.post(name: didChange, object: nil)
    }

    static func count(in dictionaryID: String) -> Int { all[dictionaryID]?.count ?? 0 }

    /// The reading log, newest first: every sighting resolved back to a full word
    /// out of the shelf it was read in. Only the dictionaries you've actually
    /// opened get decoded, and WordProvider caches each one, so this is usually
    /// one or two lists rather than all ten.
    static var log: [LearnedWord] {
        // A shelf that has since been removed would fatalError in WordProvider.
        let shelves = Set(Wordbook.all.map(\.id))
        return all
            .filter { shelves.contains($0.key) }
            .flatMap { id, terms in
                WordProvider(resource: id).allWords.compactMap { word in
                    terms[word.term].map { LearnedWord(word: word, shelf: id, seenAt: $0) }
                }
            }
            .sorted { $0.seenAt > $1.seenAt }
    }

    /// Across every dictionary. A word met in two dictionaries counts in both —
    /// they're separate shelves and the per-shelf numbers have to add up.
    static var total: Int { all.values.reduce(0) { $0 + $1.count } }
}
