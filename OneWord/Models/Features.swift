//
//  Features.swift
//  OneWord
//
//  What this build ships. Flip a flag, not a branch: the code for a held-back
//  feature stays on main and compiles, so turning it on later is one line.
//  App-only — the widget sees Premium's rules through Premium.free instead.
//

enum Features {
    /// The paywall, the gates, the sidebar plan tag. Off: every shelf in Wordbook.all is free
    /// and Premium is a tag only — sold in Profile (ProfileView.plans), it unlocks nothing.
    static let premium = false
    /// The Practice pane and its Settings section.
    static let practice = false
    /// The History pane's sidebar row. Off: past days aren't browsable; Home still shows today.
    static let history = false
    /// Sign-in (Apple + Google via Firebase), the Profile account rows, the in-app
    /// feedback sheet. Off: Firebase is never configured, so the app touches no
    /// network; the shell shows without a session and feedback goes by mail.
    static let accounts = false
    /// The "Send a suggestion" button, its one-time callout card, and the Feedback
    /// section in Settings. Off: no way to write to us from inside the app.
    static let feedback = false
}
