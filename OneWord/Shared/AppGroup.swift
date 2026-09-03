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
    //
    // TEAM ID prefixed. Un-prefixed (`group.com.hariom.swift.oneword`) it never
    // got provisioned: Xcode fell back to the wildcard "Mac Team Provisioning
    // Profile: *", which carries no application-groups entitlement at all, so the
    // sandbox never granted the container and every open fell through to TCC's
    // app-data check — the "would like to access data from other apps" prompt,
    // once per UserDefaults(suiteName:). Changing this id migrates nothing; the
    // old container's contents were moved across by hand.
    static let id = "LAP54KU2SV.group.com.hariom.swift.oneword"

    /// `let`, not `var`: UserDefaults(suiteName:) builds a NEW instance — and a
    /// fresh container open — on every call, and @AppStorage re-runs its
    /// initialiser on every view init. As a computed property this was dozens of
    /// opens per interaction; as a `let` it's one for the life of the process.
    ///
    /// Falls back to standard defaults if the App Group isn't provisioned yet
    /// (then the app + widget won't share — build once in Xcode to provision it).
    static let defaults = UserDefaults(suiteName: id) ?? .standard

    static let dictionaryKey = "dictionaryID"

    /// The selected dictionary id (defaults to Everyday English's `words`).
    static var dictionaryID: String {
        defaults.string(forKey: dictionaryKey) ?? "words"
    }

    /// Entry fields the reader can switch off in Settings. Absent key = shown,
    /// so `bool(forKey:)`'s false-when-missing would hide them on a fresh install.
    static var showHindi: Bool { defaults.object(forKey: "showHindi") as? Bool ?? true }
    static var showExample: Bool { defaults.object(forKey: "showExample") as? Bool ?? true }
}
