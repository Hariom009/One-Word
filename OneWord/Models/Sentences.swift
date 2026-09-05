//
//  Sentences.swift
//  OneWord
//
//  The practice corpus: an English sentence and its German translation. App-only
//  — the widget shows a word, never a sentence — so this sits in OneWord/, not
//  Shared/, whose headers all declare "member of app + widget targets".
//
//  Bundled rather than translated at runtime: Translation.framework is macOS 15+
//  (and this SDK ships only a Mac Catalyst slice of it) while the app targets
//  14.0. Bundled pairs are also offline and stable across launches.
//

import Foundation

/// One practice pair. Plain value type: no UI, no platform imports.
nonisolated struct Sentence: Codable, Hashable, Identifiable {
    let en: String
    let de: String

    /// Stable id — the English sentence is unique in `sentences.json` (checked).
    var id: String { en }
}

// nonisolated for the same reason as WordProvider: the target defaults to
// MainActor isolation, but tools/check_sentences.sh compiles this file with
// plain swiftc, which does not. Marking the type gives both builds one meaning.
nonisolated enum Sentences {
    /// Decoded once — a `static let` initializer runs exactly once, lazily, so
    /// this needs none of WordProvider's NSCache machinery.
    static let all: [Sentence] = {
        guard let url = Bundle.main.url(forResource: "sentences", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("sentences.json is missing from the bundle — check target membership")
        }
        let list = decode(data)
        precondition(!list.isEmpty, "sentences.json is empty")
        return list
    }()

    /// The seam the check script uses: it has a file path, not a bundle.
    static func decode(_ data: Data) -> [Sentence] {
        do { return try JSONDecoder().decode([Sentence].self, from: data) }
        catch { fatalError("sentences.json failed to decode: \(error)") }
    }

    /// A random pair that is never `excluding`.
    ///
    /// Index arithmetic, not reject-and-retry: retry never terminates on a
    /// one-entry corpus, and "not the same twice" is impossible there anyway —
    /// so a lone entry is returned rather than looped on.
    /// `corpus` is injectable for the same reason WordProvider's init is: the
    /// check script has no bundle to read `all` from.
    static func random(excluding: Sentence? = nil, in corpus: [Sentence] = all) -> Sentence {
        guard let excluding, corpus.count > 1,
              let skip = corpus.firstIndex(of: excluding) else {
            return corpus.randomElement()!
        }
        let i = Int.random(in: 0..<(corpus.count - 1))
        return corpus[i < skip ? i : i + 1]
    }
}
