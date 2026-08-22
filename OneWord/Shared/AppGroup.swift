//
//  AppGroup.swift
//  OneWord — Shared (app + widget)
//
//  Storage shared between the app and the widget extension (an App Group). The
//  selected dictionary lives here so ONE setting drives both the app and the widget.
//

import Foundation

// nonisolated: the target defaults to MainActor isolation, but the widget's timeline
// provider reads this off the main actor. Marking the type is one place; the
// alternative is a `nonisolated` on every caller in WordStore and SavedWords.
nonisolated enum AppGroup {
    // Must match BOTH targets' .entitlements exactly — a mismatch isn't an error,
    // UserDefaults(suiteName:) just falls back to .standard and the app and widget
    // silently stop sharing. Renamed with the app (was ...swift.MacBee).
    static let id = "group.com.hariom.swift.oneword"

    /// Falls back to standard defaults if the App Group isn't provisioned yet
    /// (then the app + widget won't share — build once in Xcode to provision it).
    static var defaults: UserDefaults { UserDefaults(suiteName: id) ?? .standard }

    static let dictionaryKey = "dictionaryID"

    /// The selected dictionary id (defaults to Everyday English's `words`).
    static var dictionaryID: String {
        defaults.string(forKey: dictionaryKey) ?? "words"
    }
}
