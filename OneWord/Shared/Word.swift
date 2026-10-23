//
//  Word.swift
//  OneWord — Shared model (member of app + widget targets)
//

import Foundation

/// One dictionary entry. Plain value type: no UI, no platform imports.
struct Word: Codable, Identifiable, Hashable {
    let term: String
    let partOfSpeech: String
    let hindi: String
    let definition: String
    let example: String
    /// A bundled recording, `OneWord/Sounds/<sound>.m4a`, for books whose entries are
    /// sounds (Cats & Dogs). Absent from every other json, so it decodes as nil.
    var sound: String? = nil
    /// A bundled photo, `OneWord/Pictures/<image>.jpg`, for the picture book. Same
    /// shape as `sound`: absent from every other json, so it decodes as nil.
    var image: String? = nil

    /// Stable id — the term is unique in `words.json`.
    var id: String { term }
}
