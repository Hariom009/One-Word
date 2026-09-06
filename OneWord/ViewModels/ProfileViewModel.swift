//
//  ProfileViewModel.swift
//  OneWord
//
//  The Profile pane's seam: how many words you've bookmarked and read. Trivial now, but
//  it keeps the view off the persistence layer and stays testable without
//  SwiftUI. MainActor-isolated by default isolation.
//

import Foundation
import Observation

@Observable
final class ProfileViewModel {
    /// Bookmarks you keep by hand.
    private(set) var bookmarks = 0
    /// Every word you've read, across every shelf — a word met in two books counts twice.
    private(set) var learned = 0
    /// The German shelf alone: the only count the fluency goal is measured against.
    private(set) var learnedGerman = 0

    /// Cheap: both stores are already in memory. Safe to call on every change.
    func refresh() {
        bookmarks = SavedWords.all.count
        learned = LearnedWords.total
        learnedGerman = LearnedWords.count(in: Wordbook.german.id)
    }
}
