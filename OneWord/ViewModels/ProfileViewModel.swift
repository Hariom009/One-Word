//
//  ProfileViewModel.swift
//  OneWord
//
//  The Profile pane's seam: how far you've got through each shelf. Pulled out of
//  ProfileView because counting a shelf means DECODING its JSON — one book is 12k
//  entries — and a view has no business doing that. Testable without SwiftUI.
//  MainActor-isolated by default isolation.
//

import Foundation
import Observation

@Observable
final class ProfileViewModel {
    /// Dictionary id → term → when you first read it. Mirrors LearnedWords.all.
    private(set) var learned: [String: [String: Date]] = [:]
    /// Bookmarks you keep by hand, as opposed to the words reading racked up.
    private(set) var bookmarks = 0
    /// Each dictionary's size, for the "42 of 512". Lands a beat after the counts.
    private(set) var sizes: [String: Int] = [:]

    var total: Int { learned.values.reduce(0) { $0 + $1.count } }

    /// Words read in `book`, and how many it holds. `size == 0` means the sizes
    /// haven't landed yet — the view shows the bare count until they do.
    func progress(for book: Wordbook) -> (seen: Int, size: Int) {
        (learned[book.id]?.count ?? 0, sizes[book.id] ?? 0)
    }

    /// Cheap: both stores are already in memory. Safe to call on every change.
    func refresh() {
        learned = LearnedWords.all
        bookmarks = SavedWords.all.count
    }

    /// Expensive: decodes every bundled book, so it runs off the main actor and
    /// only once per pane appearance. Sizes are fixed at build time — nothing
    /// invalidates them, so there's no reload path.
    func loadSizes() async {
        guard sizes.isEmpty else { return }
        let ids = Wordbook.all.map(\.id)
        sizes = await Task.detached(priority: .utility) {
            Dictionary(uniqueKeysWithValues: ids.map {
                ($0, WordProvider(resource: $0).allWords.count)
            })
        }.value
    }
}
