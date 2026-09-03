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
    let symbol: String   // SF Symbol stamped on the cover

    static let everydayEnglish = Wordbook(id: "words", name: "Dictionary of Everyday English", cover: 0x1E232B, symbol: "textformat.abc")
    static let emotions = Wordbook(id: "emotions", name: "Dictionary of Emotions", cover: 0x5B2A33, symbol: "heart.fill")
    static let philosophy = Wordbook(id: "philosophy", name: "Dictionary of Philosophy", cover: 0x343A63, symbol: "brain.head.profile")
    static let medical = Wordbook(id: "medical", name: "Dictionary of Medicine", cover: 0x1F4A47, symbol: "cross.case.fill")
    static let character = Wordbook(id: "character", name: "Dictionary of Character", cover: 0x4B3A2A, symbol: "person.fill.questionmark")
    static let eloquence = Wordbook(id: "eloquence", name: "Dictionary of Eloquence", cover: 0x46305A, symbol: "book.closed.fill")
    static let curiosities = Wordbook(id: "curiosities", name: "Dictionary of Curiosities", cover: 0x5C4413, symbol: "sparkles")
    static let startup = Wordbook(id: "startup", name: "Dictionary of Corporate Slang", cover: 0x2C4257, symbol: "briefcase.fill")
    static let idioms = Wordbook(id: "idioms", name: "Dictionary of Idioms", cover: 0x5A2B4E, symbol: "quote.bubble.fill")
    /// Not a bundled json — WordProvider resolves this id from the words you bookmarked.
    static let saved = Wordbook(id: SavedWords.resource, name: "Bookmarks", cover: 0x2A4634, symbol: "bookmark.fill")

    var coverColor: Color { Color(hex: cover) }

    /// "Dictionary of Emotions" -> "Emotions". The full name belongs on a cover;
    /// in a list row or a picker it's 14 characters of noise on every line.
    var shortName: String {
        name.hasPrefix("Dictionary of ") ? String(name.dropFirst(14)) : name
    }

    /// Every dictionary the app offers. Grow this as new word sets are added.
    static let all: [Wordbook] = [everydayEnglish, emotions, philosophy, medical, character, eloquence, curiosities, startup, idioms, saved]

    /// Resolve a stored id back to a Wordbook (falls back to the default).
    static func named(_ id: String) -> Wordbook {
        all.first { $0.id == id } ?? everydayEnglish
    }

    /// The currently selected dictionary, read straight from the App Group. View
    /// models default to this so a freshly built one already holds the right book
    /// — `select()` then no-ops instead of resetting the shared word offset.
    static var selected: Wordbook { named(AppGroup.defaults.string(forKey: "dictionaryID") ?? everydayEnglish.id) }
}
