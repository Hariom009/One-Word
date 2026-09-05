//
//  ProfileViewModel.swift
//  OneWord
//
//  The Profile pane's seam: how many words you've bookmarked. Trivial now, but
//  it keeps the view off the persistence layer and stays testable without
//  SwiftUI. MainActor-isolated by default isolation.
//

import Foundation
import Observation

@Observable
final class ProfileViewModel {
    /// Bookmarks you keep by hand — the only number the pane shows.
    private(set) var bookmarks = 0

    /// Cheap: the store is already in memory. Safe to call on every change.
    func refresh() {
        bookmarks = SavedWords.all.count
    }
}
