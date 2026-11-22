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
    /// A bundled photo, `OneWord/Pictures/<image>.jpg`. Same shape as `sound`:
    /// absent from every json that hasn't been shot, so it decodes as nil and the
    /// entry draws the layout it always had.
    ///
    /// THE PHOTO CONTRACT, as the 243 Picture Book entries already shipping set it:
    /// JPEG, 800pt on the long edge, ~65KB each, named `<book>-<term-slug>`. It
    /// draws into a 200–320pt box with `scaledToFit` — fit, never fill, since a crop
    /// beheads the giraffe — so bigger than 800 buys nothing but bundle size.
    var image: String? = nil
    /// A bundled clip, `OneWord/Clips/<clip>.mp4`, showing the sound's context — the
    /// posture a bark comes with, the stretch before a trill. Silent by design: the
    /// `sound` recording is still the entry, played on demand. Absent everywhere it
    /// hasn't been shot, so it decodes as nil and the entry draws as it always did.
    var clip: String? = nil

    /// Stable id — the term is unique in `words.json`.
    var id: String { term }
}
