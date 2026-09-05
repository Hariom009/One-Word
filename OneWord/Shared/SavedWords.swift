//
//  SavedWords.swift
//  OneWord — Shared (app + widget)
//
//  Words you chose to keep: bookmarked from the toolbar, or caught via the
//  Services shortcut in any app (which also pins one as today's word). The
//  Bookmarks pane. Lives in the App Group so the widget can show them too. Same shape as WordSelectionStore: Codable
//  through AppGroup.defaults, nonisolated because the widget's timeline provider
//  reads it off the main actor.
//

import Foundation
#if canImport(CoreServices)
import CoreServices
#endif

/// One captured word, plus when it was caught (the day decides if it takes over).
struct SavedWord: Codable, Identifiable, Hashable {
    let word: Word
    let savedAt: Date

    var id: String { word.term }
}

enum SavedWords {
    /// The resource name that means "the saved list", not a bundled `<id>.json`.
    nonisolated static let resource = "saved"

    nonisolated static let didChange = Notification.Name("SavedWordsDidChange")

    nonisolated private static let key = "savedWords"

    // ponytail: one JSON blob in UserDefaults — fine for the hundreds of words a
    // person actually captures. Move to a file in the group container if it grows.
    nonisolated static var all: [SavedWord] {
        get {
            guard let data = AppGroup.defaults.data(forKey: key),
                  let saved = try? JSONDecoder().decode([SavedWord].self, from: data)
            else { return [] }
            return saved
        }
        set {
            // Not `set(try? encode(...))` — that passes nil on a failed encode, and
            // set(nil:) DELETES the key. Keep the old list rather than wipe it.
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            AppGroup.defaults.set(data, forKey: key)
        }
    }

    /// Shown when nothing has been bookmarked yet — keeps the list non-empty (so
    /// WordProvider's precondition holds) and teaches the feature in the process.
    nonisolated static let placeholder = Word(
        term: "\u{2014}",
        partOfSpeech: "",
        hindi: "",
        definition: "Bookmark a word you like, or select one in any app and choose Services \u{25B8} Save to One Word. Either way it lands here.",
        example: ""
    )

    /// The just-captured word, if it still holds the day: pinned by `capture`,
    /// cleared the moment you press New Word, and expired at midnight regardless.
    nonisolated static var pinned: Word? {
        guard let term = WordSelectionStore.pinnedTerm,
              let entry = all.last(where: { $0.word.term == term }),
              Calendar.current.isDateInToday(entry.savedAt) else { return nil }
        return entry.word
    }

    /// Capture whatever was selected. Resolves a definition offline, newest last,
    /// and pins it as today's word. Returns the stored word, or nil if the
    /// selection wasn't a single word.
    @discardableResult
    nonisolated static func capture(_ selection: String) -> Word? {
        guard let term = normalize(selection) else { return nil }
        let word = lookUp(term) ?? Word(term: term, partOfSpeech: "", hindi: "",
                                        definition: "", example: "")
        // Re-saving an existing word moves it to the end — it becomes today's word again.
        var words = all.filter { $0.word.term != word.term }
        words.append(SavedWord(word: word, savedAt: Date()))
        all = words
        WordSelectionStore.pinnedTerm = word.term
        NotificationCenter.default.post(name: didChange, object: nil)
        return word
    }

    nonisolated static func contains(_ word: Word) -> Bool {
        all.contains { $0.word.term == word.term }
    }

    /// Bookmark / un-bookmark from inside the app. Unlike `capture`, this does NOT
    /// pin the word as today's — you liked it, you didn't ask to read it right now.
    /// Returns the new state, so the button can say what it did.
    @discardableResult
    nonisolated static func toggle(_ word: Word) -> Bool {
        guard word.term != placeholder.term else { return false }
        var words = all
        let wasSaved = words.contains { $0.word.term == word.term }
        words.removeAll { $0.word.term == word.term }
        if !wasSaved { words.append(SavedWord(word: word, savedAt: Date())) }
        // Un-bookmarking the pinned word would leave `pinned` resolving to nothing;
        // clear it so today's word falls back to the dictionary's instead.
        if wasSaved, WordSelectionStore.pinnedTerm == word.term { WordSelectionStore.pinnedTerm = nil }
        all = words
        NotificationCenter.default.post(name: didChange, object: nil)
        return !wasSaved
    }

    /// Trim whitespace and surrounding punctuation, lowercase to match the JSON's
    /// terms. Rejects phrases — the dictionaries are single words only.
    nonisolated static func normalize(_ selection: String) -> String? {
        let term = selection
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            .lowercased()
        guard !term.isEmpty, term.count <= 64,
              !term.contains(where: \.isWhitespace) else { return nil }
        return term
    }

    /// Definition, best source first: your own dictionaries (which carry Hindi, a
    /// part of speech and an example), then macOS's built-in dictionary. Both offline.
    nonisolated static func lookUp(_ term: String) -> Word? {
        // The selected book first, then Everyday English's 12k — covers most of it
        // without decoding all seven JSONs on every capture.
        for resource in [AppGroup.dictionaryID, "words"] where resource != Self.resource {
            if let hit = WordProvider(resource: resource).allWords
                .first(where: { $0.term == term }) {
                return hit
            }
        }
        return systemEntry(term)
    }

    /// macOS's own dictionary (verified working under App Sandbox). Returns the
    /// whole entry as one blob — headword, syllabification, pronunciation, every
    /// sense, derivatives and etymology run together — so `firstSense` cuts it
    /// down to something that fits on a card.
    nonisolated static func systemDefinition(_ term: String) -> String? {
        #if canImport(CoreServices)
        let range = CFRange(location: 0, length: term.utf16.count)
        guard let text = DCSCopyTextDefinition(nil, term as CFString, range)?
            .takeRetainedValue() as String? else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
        #else
        return nil
        #endif
    }

    nonisolated static func systemEntry(_ term: String) -> Word? {
        guard let raw = systemDefinition(term) else { return nil }
        let sense = firstSense(raw, term: term)
        guard !sense.definition.isEmpty else { return nil }
        return Word(term: term, partOfSpeech: sense.partOfSpeech, hindi: "",
                    definition: sense.definition, example: sense.example)
    }

    /// Reduce a system dictionary blob to its first sense. The shape is
    /// `word syl·la·bles | prəˌnʌnsiˈeɪʃn | adjective the meaning: an example. • …`
    /// ponytail: string surgery, not a parser — this format is stable and a miss
    /// just costs a slightly untidy card, never a crash.
    nonisolated static func firstSense(_ raw: String, term: String)
        -> (partOfSpeech: String, definition: String, example: String) {
        var text = raw

        // Drop the headword and the | pronunciation | that follows it.
        if let open = text.firstIndex(of: "|"),
           let close = text[text.index(after: open)...].firstIndex(of: "|") {
            text = String(text[text.index(after: close)...])
        } else if text.lowercased().hasPrefix(term.lowercased()) {
            text = String(text.dropFirst(term.count))
        }

        // Cut the later senses and the back matter.
        for marker in ["\u{2022}", "DERIVATIVES", "ORIGIN", "PHRASES", "PHRASAL VERBS", "USAGE"] {
            if let found = text.range(of: marker) { text = String(text[..<found.lowerBound]) }
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // A leading part of speech, longest first so "plural noun" beats "noun".
        var partOfSpeech = ""
        let kinds = ["plural noun", "abbreviation", "interjection", "preposition",
                     "conjunction", "exclamation", "adjective", "pronoun", "adverb",
                     "noun", "verb"]
        for kind in kinds where text.hasPrefix(kind + " ") {
            partOfSpeech = kind
            text = String(text.dropFirst(kind.count + 1))
            break
        }

        // "the meaning: an example"
        var definition = text
        var example = ""
        if let colon = text.firstIndex(of: ":") {
            definition = String(text[..<colon])
            example = String(text[text.index(after: colon)...])
        }
        return (partOfSpeech,
                tidy(definition, limit: 300),
                tidy(example, limit: 200))
    }

    /// Trim whitespace and a trailing full stop, and keep it card-sized.
    nonisolated private static func tidy(_ text: String, limit: Int) -> String {
        var out = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if out.count > limit {
            out = String(out.prefix(limit)).trimmingCharacters(in: .whitespaces) + "\u{2026}"
        }
        while out.hasSuffix(".") || out.hasSuffix(";") || out.hasSuffix(",") {
            out.removeLast()
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
