//
//  Features.swift
//  OneWord
//
//  What this build ships. Flip a flag, not a branch: the code for a held-back
//  feature stays on main and compiles, so turning it on later is one line.
//  App-only — the widget sees Premium's rules through Premium.free instead.
//

enum Features {
    /// StoreKit, the paywall, the plan tag. Off: every shelf in Wordbook.all is free.
    static let premium = false
    /// The Practice pane and its Settings section.
    static let practice = false
}
