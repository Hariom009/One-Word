//
//  WordStore.swift
//  OneWord — Shared (app + widget)
//
//  The manual "New Word / refresh" offset, added on top of the day's word. Lives
//  in the App Group so the app and the widget always show the SAME word — either
//  one's refresh advances it, and switching dictionaries resets it.
//  nonisolated because the widget's timeline provider reads it off the main actor.
//

import Foundation

enum WordStore {
    // ponytail: bumped from "refreshOffset" to abandon stale test values (starts at 0 = today's word).
    nonisolated private static let key = "wordOffset"

    nonisolated private static let pinKey = "pinnedTerm"

    nonisolated static var offset: Int {
        get { AppGroup.defaults.integer(forKey: key) }
        set { AppGroup.defaults.set(newValue, forKey: key) }
    }

    /// A word you just captured, holding the day until you move off it. Cleared by
    /// advance/reset so "New Word" isn't a no-op right after a catch; SavedWords
    /// also expires it at midnight.
    nonisolated static var pinnedTerm: String? {
        get { AppGroup.defaults.string(forKey: pinKey) }
        set { AppGroup.defaults.set(newValue, forKey: pinKey) }
    }

    nonisolated static func advance() { pinnedTerm = nil; offset += 1 }
    nonisolated static func reset() { pinnedTerm = nil; offset = 0 }
}
