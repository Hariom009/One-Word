//
//  Wordbook.swift
//  OneWord
//
//  A selectable dictionary (word set). One today; more later — add an entry here
//  plus its bundled `<id>.json` and it shows up in the picker. Named `Wordbook`
//  to avoid clashing with Swift's `Dictionary`.
//  ponytail: covers are the only colored surface — the reading UI stays monochrome.
//  `cover` is the cloth colour sampled off each painted cover; `isLight` picks the lettering.
//

import SwiftUI

struct Wordbook: Identifiable, Hashable {
    let id: String       // also the bundled JSON resource name (`<id>.json`)
    let name: String     // shown on the book cover
    let cover: UInt      // cloth colour (hex), sampled off the painted cover — spines and chips are drawn in it
    let symbol: String   // SF Symbol for chips and rows
    let mark: String     // the big glyph on the cover — a letter or two, in the book's own script
    let image: String    // the painted cover in Assets (`Dictionary_of_<Name>`, title printed on), drawn on the shelf
    var height: CGFloat = 1  // how tall it stands on the shelf, as a share of its slot — each a little different, like real books

    static let everydayEnglish = Wordbook(id: "words", name: "Dictionary of Everyday English", cover: 0xD0C6BA, symbol: "textformat.abc", mark: "Aa", image: "Dictionary_of_EverydayEnglish", height: 1)
    static let emotions = Wordbook(id: "emotions", name: "Dictionary of Emotions", cover: 0x653739, symbol: "heart.fill", mark: "\u{2665}", image: "Dictionary_of_Emotions", height: 0.9)
    static let philosophy = Wordbook(id: "philosophy", name: "Dictionary of Philosophy", cover: 0x4B5544, symbol: "brain.head.profile", mark: "\u{03A6}", image: "Dictionary_of_Philosophy", height: 0.96)
    static let startup = Wordbook(id: "startup", name: "Dictionary of Corporate Slang", cover: 0x394C61, symbol: "briefcase.fill", mark: "TM", image: "Dictionary_of_CorporateSlang", height: 0.86)
    static let idioms = Wordbook(id: "idioms", name: "Dictionary of Idioms", cover: 0x3B5773, symbol: "quote.bubble.fill", mark: "\u{201D}", image: "Dictionary_of_Idioms", height: 0.93)
    static let classical = Wordbook(id: "classical", name: "Dictionary of Classical English", cover: 0x86786B, symbol: "building.columns.fill", mark: "\u{00C6}", image: "Dictionary_of_ClassicalEnglish", height: 0.98)
    static let urdu = Wordbook(id: "urdu", name: "Dictionary of Urdu", cover: 0x4C3344, symbol: "scroll.fill", mark: "\u{0627}\u{0631}\u{062F}\u{0648}", image: "Dictionary_of_Urdu", height: 0.88)
    static let german = Wordbook(id: "german", name: "Dictionary of German", cover: 0x4A5260, symbol: "puzzlepiece.fill", mark: "\u{00DF}", image: "Dictionary_of_German", height: 0.94)
    /// Not a bundled json — WordProvider resolves this id from the words you bookmarked.
    static let saved = Wordbook(id: SavedWords.resource, name: "Bookmarks", cover: 0x2A4634, symbol: "bookmark.fill", mark: "\u{2014}", image: "Dictionary_of_Philosophy")

    var coverColor: Color { Color(hex: cover) }

    /// Pale cloth (Everyday English's linen) takes dark lettering; the rest take light.
    var isLight: Bool {
        0.299 * Double((cover >> 16) & 0xFF) + 0.587 * Double((cover >> 8) & 0xFF) + 0.114 * Double(cover & 0xFF) > 150
    }

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
