//
//  WordListViewModel.swift
//  OneWord
//
//  Browse or search words. Pinned to a book (Bookmarks) it browses that one,
//  sorted once, alphabetical. With no book (the Search pane) there is nothing to
//  browse and every bundled book is searched, so what you can find never depends
//  on which dictionary happens to be picked. Testable seam: pure over
//  WordProvider, no view types.
//

import Foundation
import Observation

@Observable
final class WordListViewModel {
    /// A row: the word plus the book it came from. Search crosses books, so the
    /// term alone stopped being a unique id — "stab" sits in both Everyday
    /// English and Emotions, and a List given duplicate ids picks rows at random.
    struct Hit: Identifiable, Hashable {
        let word: Word
        let shelf: String
        /// Case/diacritic-folded term. Filtering tests this with a plain
        /// `contains` rather than `localizedCaseInsensitiveContains` over 20k
        /// words on every keystroke — and folding is what the filter always
        /// claimed to do anyway (the localized call never dropped diacritics).
        let key: String

        var id: String { shelf + "\u{0}" + word.term }
    }

    /// The book this list is pinned to. nil = the Search pane: no book to browse,
    /// every book to search.
    private let wordbook: Wordbook?
    /// The pinned book, alphabetical — what shows before you type.
    private(set) var rows: [Hit]

    init(wordbook: Wordbook?) {
        self.wordbook = wordbook
        self.rows = wordbook.map(Self.load) ?? []
    }

    /// Re-read the pinned book. Bookmarks isn't a file — it changes under us.
    func reload() { rows = wordbook.map(Self.load) ?? [] }

    var count: Int { rows.count }

    /// What a bookless search reaches — every bundled book, and their words.
    static let everywhereBooks: [Wordbook] = Wordbook.all.filter { $0.id != SavedWords.resource }
    static var everywhereCount: Int { everything.count }

    /// Words whose term contains `query`. Pinned to a book, an empty query browses
    /// it; unpinned, the search spans every bundled dictionary and shows nothing
    /// until you type — there is no one book to fall back to.
    func results(for query: String) -> [Hit] {
        let q = Self.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard wordbook != nil else {
            return q.isEmpty ? [] : Self.sorted(Self.everything.filter { $0.key.contains(q) })
        }
        return q.isEmpty ? rows : rows.filter { $0.key.contains(q) }
    }

    /// Every bundled book in one list, built on the first cross-book search and
    /// kept. Left unsorted: the matches get sorted instead, and that's a few
    /// hundred rows rather than twenty thousand.
    /// ponytail: Bookmarks is left out — it isn't a book you'd look in for
    /// something else, it changes under us, and it has its own pane and field.
    private static let everything: [Hit] = everywhereBooks.flatMap { WordListViewModel.hits($0) }

    private static func load(_ wordbook: Wordbook) -> [Hit] { sorted(hits(wordbook)) }

    private static func hits(_ wordbook: Wordbook) -> [Hit] {
        // WordProvider hands an empty Bookmarks list a placeholder so its
        // non-empty precondition holds (the widget shows it). A list wants the
        // empty state instead of a row reading "\u{2014}", so drop it here.
        WordProvider(resource: wordbook.id).allWords
            .filter { $0.term != SavedWords.placeholder.term }
            .map { Hit(word: $0, shelf: wordbook.id, key: fold($0.term)) }
    }

    private static func sorted(_ hits: [Hit]) -> [Hit] {
        hits.sorted { $0.word.term.localizedCaseInsensitiveCompare($1.word.term) == .orderedAscending }
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
