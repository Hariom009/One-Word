//
//  Premium.swift
//  OneWord — Shared (app + widget)
//
//  What a free reader gets, and whether they've bought the rest. The rules live
//  here, once, because two processes enforce them: the app (shelf, search, the
//  word page) and the widget, whose own Edit menu can pick any dictionary. StoreKit
//  is the truth; this is its mirror in the App Group, which the widget can read off
//  the main actor. Only PremiumViewModel writes it, through `set(unlocked:)`.
//  ponytail: the flag is a plist a determined user could edit. The ceiling is the
//  widget asking StoreKit itself — add that only if the unlock ever attracts it.
//

import Foundation

// nonisolated: the widget's timeline provider reads this off the main actor, as it does AppGroup.
nonisolated enum Premium {
    /// App Store Connect's product id. Forever once shipped — Apple never lets an id be reused.
    static let productID = "com.hariom.swift.oneword.premium"

    /// Everyday English, and Bookmarks — the reader's own words, never sold back to them.
    /// "words" is spelled out the way AppGroup.dictionaryID spells it: Wordbook is app-only.
    static let free: Set<String> = ["words", SavedWords.resource]

    private static let key = "premiumUnlocked"

    /// Absent reads as locked — here that's the right default, unlike showHindi's.
    static var isUnlocked: Bool { AppGroup.defaults.bool(forKey: key) }

    /// The rule. PremiumViewModel passes its own observed flag, so the two can't disagree.
    static func allows(_ id: String, unlocked: Bool = isUnlocked) -> Bool {
        unlocked || free.contains(id)
    }

    /// The dictionary to actually show for `id`: itself, or Everyday English while it's locked.
    static func resolve(_ id: String) -> String { allows(id) ? id : "words" }

    /// The only writer. Losing Premium also walks a locked pick back to Everyday English —
    /// offset and pin with it — so every raw `@AppStorage("dictionaryID")` reader agrees
    /// without being touched. Unlocking never moves the pick.
    static func set(unlocked: Bool) {
        AppGroup.defaults.set(unlocked, forKey: key)
        guard !unlocked,
              let picked = AppGroup.defaults.string(forKey: AppGroup.dictionaryKey),
              !free.contains(picked) else { return }
        AppGroup.defaults.set("words", forKey: AppGroup.dictionaryKey)
        WordSelectionStore.reset()
    }
}
