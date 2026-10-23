//
//  CloudSync.swift
//  OneWord
//
//  Bookmarks and learned words follow the reader between Mac and iPhone through
//  iCloud key-value storage — the device's iCloud account is the identity, so
//  there is nothing to sign in to. The App Group stays the source of truth (the
//  widget reads it); iCloud is a mirror, the way Premium mirrors StoreKit.
//
//  One move for every trigger — launch, a change here, a change from iCloud:
//  merge both sides, write whichever side differs from the result. A write that
//  changed nothing writes nothing, so the didChange it posts settles in one hop.
//
//  App target only: the widget reads what this writes into the App Group.
//
//  ponytail: NSUbiquitousKeyValueStore holds 1 MB in total, and a fully-read 12k
//  shelf is ~300KB of learned terms — over quota, iCloud stops taking writes
//  and the devices drift. The upgrade is CKSyncEngine (macOS 14 / iOS 17, both
//  already the deployment targets). Also merge-only: switching iCloud accounts
//  blends the two accounts' lists rather than swapping them.
//

import Foundation

enum CloudSync {
    /// What one device knows about bookmarks: what's saved, and what was un-saved when.
    struct Bookmarks: Codable, Equatable {
        var saved: [SavedWord]
        var removed: [String: Date]
    }

    // MARK: - Merge rules (pure; tools/check_sync.sh)

    /// Grow-only: every sighting either side has, and the EARLIEST time per term.
    static func merge(_ a: [String: [String: Date]], _ b: [String: [String: Date]]) -> [String: [String: Date]] {
        a.merging(b) { $0.merging($1, uniquingKeysWith: min) }
    }

    /// Per term, the latest event wins: a save, or the tombstone of an un-save. A
    /// tombstone a newer save beat is dropped — that save outranks everything it would.
    static func merge(_ a: Bookmarks, _ b: Bookmarks) -> Bookmarks {
        let newest = Dictionary((a.saved + b.saved).map { ($0.word.term, $0) }) {
            $0.savedAt >= $1.savedAt ? $0 : $1
        }
        let removed = a.removed.merging(b.removed, uniquingKeysWith: max)
        let kept = newest.values.filter { save in
            removed[save.word.term].map { save.savedAt > $0 } ?? true
        }
        let keptTerms = Set(kept.map(\.word.term))
        return Bookmarks(
            // Oldest first, as SavedWords keeps it; the term breaks ties so equal
            // inputs always produce an equal list.
            saved: kept.sorted { ($0.savedAt, $0.word.term) < ($1.savedAt, $1.word.term) },
            removed: removed.filter { !keptTerms.contains($0.key) })
    }

    // MARK: - Wiring

    /// Posted when a sync pulls in what the other device changed — SyncToast's cue.
    static let didSync = Notification.Name("CloudSyncDidSync")
    /// Syncs that pulled anything, this launch. The launch sync runs in the App's init,
    /// before any view is listening, so the toast seeds itself from this.
    private(set) static var pulls = 0

    private static let store = NSUbiquitousKeyValueStore.default
    private static let bookmarksKey = "bookmarks"
    private static let learnedKey = "learned"

    /// Once, from the App's init.
    static func start() {
        for name in [NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                     SavedWords.didChange, LearnedWords.didChange] {
            // iCloud posts off-main; queue: .main hops back.
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { sync() }
            }
        }
        store.synchronize()
        sync()
    }

    static func sync() {
        let localBookmarks = Bookmarks(saved: SavedWords.all, removed: SavedWords.removed)
        let cloudBookmarks: Bookmarks? = read(bookmarksKey)
        let bookmarks = merge(localBookmarks, cloudBookmarks ?? Bookmarks(saved: [], removed: [:]))

        let localLearned = LearnedWords.all
        let cloudLearned: [String: [String: Date]]? = read(learnedKey)
        let learned = merge(localLearned, cloudLearned ?? [:])

        if bookmarks != localBookmarks {
            SavedWords.all = bookmarks.saved
            SavedWords.removed = bookmarks.removed
        }
        if bookmarks != cloudBookmarks { write(bookmarks, bookmarksKey) }
        if learned != localLearned { LearnedWords.all = learned }
        if learned != cloudLearned { write(learned, learnedKey) }

        // Last, so the views — and this file's own observer — re-read both sides agreeing.
        let pulledBookmarks = bookmarks.saved != localBookmarks.saved
        let pulledLearned = learned != localLearned
        if pulledBookmarks {
            NotificationCenter.default.post(name: SavedWords.didChange, object: nil)
        }
        if pulledLearned {
            NotificationCenter.default.post(name: LearnedWords.didChange, object: nil)
        }
        // Only what came DOWN is announced: a push follows every bookmark and every
        // new word read, and a toast on each would be noise.
        if pulledBookmarks || pulledLearned {
            pulls += 1
            NotificationCenter.default.post(name: didSync, object: nil)
        }
    }

    private static func read<T: Decodable>(_ key: String) -> T? {
        store.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    private static func write(_ value: some Encodable, _ key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        store.set(data, forKey: key)
    }
}
