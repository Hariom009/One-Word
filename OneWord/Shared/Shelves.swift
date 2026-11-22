//
//  Shelves.swift
//  OneWord — Shared (app + widget)
//
//  Which dictionaries this build puts in front of the reader, read from the bundled
//  Shelves.json. A release decides how many shelves to show by flipping a value there;
//  the books themselves stay bundled and their code stays compiled. The app filters
//  Wordbook.all through this, and the widget resolves its pick through it. Foundation
//  only, so the gate scripts can compile it on its own.
//

import Foundation

// nonisolated: the widget's timeline provider reads this off the main actor, as it does AppGroup.
nonisolated enum Shelves {
    /// Everyday English: always shown, and where a pick on a hidden shelf falls back to.
    static let fallback = "words"

    /// The ids Shelves.json switches on, plus the fallback.
    static let visible: Set<String> = load(Bundle.main.url(forResource: "Shelves", withExtension: "json"))

    static func isVisible(_ id: String) -> Bool { visible.contains(id) }

    /// The dictionary to actually show for `id`: itself, or Everyday English while it's hidden.
    static func resolve(_ id: String) -> String { isVisible(id) ? id : fallback }

    /// A missing or unreadable file shows Everyday English alone, not everything: a held-back
    /// book must never reach the store because the config failed to load.
    static func load(_ url: URL?) -> Set<String> {
        guard let url, let data = try? Data(contentsOf: url) else { return [fallback] }
        return parse(data)
    }

    static func parse(_ data: Data) -> Set<String> {
        struct File: Decodable { let shelves: [String: Bool] }
        guard let file = try? JSONDecoder().decode(File.self, from: data) else { return [fallback] }
        return Set(file.shelves.filter(\.value).keys).union([fallback])
    }
}
