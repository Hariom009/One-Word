//
//  Wordbook.swift
//  OneWord
//
//  A selectable dictionary (word set). One today; more later — add an entry here
//  plus its bundled `<id>.json` and it shows up in the picker. Named `Wordbook`
//  to avoid clashing with Swift's `Dictionary`.
//  ponytail: covers are the only colored surface — the reading UI stays monochrome.
//  Keep every cover dark (L* low) so the white title/symbol stays legible.
//

import SwiftUI

struct Wordbook: Identifiable, Hashable {
    let id: String       // also the bundled JSON resource name (`<id>.json`)
    let name: String     // shown on the book cover
    let cover: UInt      // book cover (hex) — a muted hue each, so covers stay tellable apart
    let symbol: String   // SF Symbol for chips and rows
    let mark: String     // the big glyph on the cover — a letter or two, in the book's own script
    let image: String    // the painted cover in Assets (`book_<hue>`), drawn on the shelf

    static let everydayEnglish = Wordbook(id: "words", name: "Dictionary of Everyday English", cover: 0x1E232B, symbol: "textformat.abc", mark: "Aa", image: "book_pink")
    static let emotions = Wordbook(id: "emotions", name: "Dictionary of Emotions", cover: 0x5B2A33, symbol: "heart.fill", mark: "\u{2665}", image: "book_fade_brown")
    static let philosophy = Wordbook(id: "philosophy", name: "Dictionary of Philosophy", cover: 0x343A63, symbol: "brain.head.profile", mark: "\u{03A6}", image: "book_olive")
    static let startup = Wordbook(id: "startup", name: "Dictionary of Corporate Slang", cover: 0x2C4257, symbol: "briefcase.fill", mark: "TM", image: "book_cyan")
    static let idioms = Wordbook(id: "idioms", name: "Dictionary of Idioms", cover: 0x5A2B4E, symbol: "quote.bubble.fill", mark: "\u{201D}", image: "book_blue")
    static let classical = Wordbook(id: "classical", name: "Dictionary of Classical English", cover: 0x353D1E, symbol: "building.columns.fill", mark: "\u{00C6}", image: "book_red")
    static let urdu = Wordbook(id: "urdu", name: "Dictionary of Urdu", cover: 0x6B2E20, symbol: "scroll.fill", mark: "\u{0627}\u{0631}\u{062F}\u{0648}", image: "book_brown")
    static let german = Wordbook(id: "german", name: "Dictionary of German", cover: 0x274620, symbol: "puzzlepiece.fill", mark: "\u{00DF}", image: "book_purple")
    /// Not a bundled json — WordProvider resolves this id from the words you bookmarked.
    static let saved = Wordbook(id: SavedWords.resource, name: "Bookmarks", cover: 0x2A4634, symbol: "bookmark.fill", mark: "\u{2014}", image: "book_olive")

    var coverColor: Color { Color(hex: cover) }

    /// How many words the book holds. The provider caches each decode, so this is
    /// one read per dictionary per launch.
    var entryCount: Int { WordProvider(resource: id).allWords.count }

    /// "Dictionary of Emotions" -> "Emotions". The full name belongs on a cover;
    /// in a list row or a picker it's 14 characters of noise on every line.
    var shortName: String {
        name.hasPrefix("Dictionary of ") ? String(name.dropFirst(14)) : name
    }

    /// Every dictionary the app offers. Grow this as new word sets are added.
    static let all: [Wordbook] = [everydayEnglish, emotions, philosophy, startup, idioms, classical, urdu, german, saved]

    /// Resolve a stored id back to a Wordbook (falls back to the default).
    static func named(_ id: String) -> Wordbook {
        all.first { $0.id == id } ?? everydayEnglish
    }

    /// The currently selected dictionary, read straight from the App Group. View
    /// models default to this so a freshly built one already holds the right book
    /// — `select()` then no-ops instead of resetting the shared word offset.
    static var selected: Wordbook { named(AppGroup.defaults.string(forKey: "dictionaryID") ?? everydayEnglish.id) }
}
