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
    nonisolated struct Hit: Identifiable, Hashable {
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
    static func everywhereCount() async -> Int { await everything().count }

    /// The pinned book's words whose term contains `query`; an empty query browses
    /// it. The Search pane has no book and asks `search` instead.
    func results(for query: String) -> [Hit] {
        let q = Self.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        return q.isEmpty ? rows : rows.filter { $0.key.contains(q) }
    }

    /// Every bundled dictionary, searched at once. Nothing until you type — there
    /// is no one book to fall back to. Off the main thread end to end: the first
    /// call decodes every book (a 3.7MB words.json among them), and each one after
    /// filters ~20k rows, neither of which a keystroke should wait on.
    static func search(_ query: String) async -> [Hit] {
        let q = fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        let all = await everything()   // warms the decode even for an empty query
        guard !q.isEmpty else { return [] }
        return await filter(all, q)
    }

    /// Every bundled book in one list, decoded once and kept. A Task rather than
    /// the array: a second caller waits on the first build instead of starting
    /// its own, and the main thread never blocks on it.
    /// ponytail: Bookmarks is left out — it isn't a book you'd look in for
    /// something else, it changes under us, and it has its own pane and field.
    private static var everythingTask: Task<[Hit], Never>?
    private static func everything() async -> [Hit] {
        if let everythingTask { return await everythingTask.value }
        let ids = everywhereBooks.map(\.id)
        let task = Task { await build(ids) }
        everythingTask = task
        return await task.value
    }

    /// @concurrent, not a bare `nonisolated async`: under approachable concurrency
    /// the bare form inherits the caller's actor and would decode on main anyway.
    @concurrent private nonisolated static func build(_ ids: [String]) async -> [Hit] {
        ids.flatMap(hits)
    }

    /// Unsorted matches get sorted here: a few hundred rows rather than twenty thousand.
    @concurrent private nonisolated static func filter(_ all: [Hit], _ q: String) async -> [Hit] {
        sorted(all.filter { $0.key.contains(q) })
    }

    private static func load(_ wordbook: Wordbook) -> [Hit] { sorted(hits(wordbook.id)) }

    nonisolated private static func hits(_ shelf: String) -> [Hit] {
        // WordProvider hands an empty Bookmarks list a placeholder so its
        // non-empty precondition holds (the widget shows it). A list wants the
        // empty state instead of a row reading "\u{2014}", so drop it here.
        WordProvider(resource: shelf).allWords
            .filter { $0.term != SavedWords.placeholder.term }
            .map { Hit(word: $0, shelf: shelf, key: fold($0.term)) }
    }

    nonisolated private static func sorted(_ hits: [Hit]) -> [Hit] {
        hits.sorted { $0.word.term.localizedCaseInsensitiveCompare($1.word.term) == .orderedAscending }
    }

    nonisolated private static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
