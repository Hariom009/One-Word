//
//  Wordbook.swift
//  OneWord
//
//  A selectable dictionary (word set). One today; more later — add an entry here
//  plus its bundled `<id>.json` and it shows up in the picker. Named `Wordbook`
//  to avoid clashing with Swift's `Dictionary`.
//

import SwiftUI

struct Wordbook: Identifiable, Hashable {
    let id: String       // also the bundled JSON resource name (`<id>.json`)
    let name: String     // shown on the book cover
    let cover: UInt      // book cover gray (hex) — a ramp, so covers stay tellable apart
    let symbol: String   // SF Symbol stamped on the cover

    static let everydayEnglish = Wordbook(id: "words", name: "Dictionary of Everyday English", cover: 0x141414, symbol: "textformat.abc")
    static let emotions = Wordbook(id: "emotions", name: "Dictionary of Emotions", cover: 0x262626, symbol: "heart.fill")
    static let philosophy = Wordbook(id: "philosophy", name: "Dictionary of Philosophy", cover: 0x383838, symbol: "brain.head.profile")
    static let medical = Wordbook(id: "medical", name: "Dictionary of Medicine", cover: 0x4A4A4A, symbol: "cross.case.fill")
    static let character = Wordbook(id: "character", name: "Dictionary of Character", cover: 0x5C5C5C, symbol: "person.fill.questionmark")
    static let eloquence = Wordbook(id: "eloquence", name: "Dictionary of Eloquence", cover: 0x6E6E6E, symbol: "book.closed.fill")
    static let curiosities = Wordbook(id: "curiosities", name: "Dictionary of Curiosities", cover: 0x808080, symbol: "sparkles")
    static let startup = Wordbook(id: "startup", name: "Dictionary of Corporate Slang", cover: 0xA4A4A4, symbol: "briefcase.fill")
    /// Not a bundled json — WordProvider resolves this id from the words you captured.
    static let saved = Wordbook(id: SavedWords.resource, name: "My Words", cover: 0x929292, symbol: "bookmark.fill")

    var coverColor: Color { Color(hex: cover) }

    /// Every dictionary the app offers. Grow this as new word sets are added.
    static let all: [Wordbook] = [everydayEnglish, emotions, philosophy, medical, character, eloquence, curiosities, startup, saved]

    /// Resolve a stored id back to a Wordbook (falls back to the default).
    static func named(_ id: String) -> Wordbook {
        all.first { $0.id == id } ?? everydayEnglish
    }
}
