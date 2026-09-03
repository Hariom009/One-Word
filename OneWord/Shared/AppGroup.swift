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
    // The TEAM ID prefix is required on macOS. Without it the group can't be
    // provisioned, so the signed entitlement isn't profile-backed, the sandbox
    // never grants the container, and EVERY open falls through to TCC's app-data
    // check — that's the "would like to access data from other apps" prompt.
    static let id = "LAP54KU2SV.group.com.hariom.swift.oneword"

    /// Where everything lived before the prefix. Read once, then never again.
    private static let legacyID = "group.com.hariom.swift.oneword"

    /// `let`, not `var`: UserDefaults(suiteName:) builds a NEW instance — and a
    /// fresh container open — on every call, and @AppStorage re-runs its
    /// initialiser on every view init. As a computed property this was dozens of
    /// opens per interaction; as a `let` it's one for the life of the process.
    ///
    /// Falls back to standard defaults if the App Group isn't provisioned yet
    /// (then the app + widget won't share — build once in Xcode to provision it).
    static let defaults: UserDefaults = {
        let defaults = UserDefaults(suiteName: id) ?? .standard
        migrateFromLegacyGroup(into: defaults)
        return defaults
    }()

    private static let migratedKey = "migratedFromLegacyGroup"

    /// Carry bookmarks, the learned log, the selected shelf and the field toggles
    /// out of the un-prefixed group. Best effort and exactly once: the app is no
    /// longer entitled to the old container, so this read may come back empty (or
    /// cost one last prompt) — the flag goes down either way rather than making
    /// every launch knock again.
    private static func migrateFromLegacyGroup(into defaults: UserDefaults) {
        guard !defaults.bool(forKey: migratedKey) else { return }
        defaults.set(true, forKey: migratedKey)
        guard let old = UserDefaults.standard.persistentDomain(forName: legacyID)
        else { return }
        // Never clobber: a key already written under the new group wins.
        for (key, value) in old where defaults.object(forKey: key) == nil {
            defaults.set(value, forKey: key)
        }
    }

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
