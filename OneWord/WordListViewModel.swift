//
//  WordListViewModel.swift
//  OneWord
//
//  Browse/search over a chosen dictionary. Sorts once (alphabetical), filters by
//  term. Testable seam: pure over WordProvider, no view types.
//

import Foundation
import Observation

@Observable
final class WordListViewModel {
    private(set) var wordbook: Wordbook
    private(set) var allWords: [Word]

    init(wordbook: Wordbook = .selected) {
        self.wordbook = wordbook
        self.allWords = Self.load(wordbook)
    }

    /// Switch dictionaries and reload its words.
    func select(_ wordbook: Wordbook) {
        guard wordbook != self.wordbook else { return }
        self.wordbook = wordbook
        reload()
    }

    /// Re-read the current wordbook. Bookmarks isn't a file — it changes under us.
    func reload() { allWords = Self.load(wordbook) }

    var count: Int { allWords.count }

    /// Words whose term contains `query` (case/diacritic-insensitive). Empty query → all.
    func results(for query: String) -> [Word] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return allWords }
        return allWords.filter { $0.term.localizedCaseInsensitiveContains(q) }
    }

    private static func load(_ wordbook: Wordbook) -> [Word] {
        // WordProvider hands an empty Bookmarks list a placeholder so its
        // non-empty precondition holds (the widget shows it). A list wants the
        // empty state instead of a row reading "\u{2014}", so drop it here.
        WordProvider(resource: wordbook.id).allWords
            .filter { $0.term != SavedWords.placeholder.term }
            .sorted { $0.term.localizedCaseInsensitiveCompare($1.term) == .orderedAscending }
    }
}
