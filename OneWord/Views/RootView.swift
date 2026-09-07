//
//  RootView.swift
//  OneWord
//
//  The window shell: a sidebar of sections beside the reading pane. Each pane
//  sets its own navigationTitle and toolbar, so the unified title bar adapts to
//  whatever is showing instead of carrying every button all the time.
//
//  It is also the gate. Signed out, the whole shell is replaced by SignInView —
//  no pane, no search, no dictionary is reachable without a session. The widget
//  is outside this: it reads the same bundled JSON and cannot run an OAuth flow.
//

import SwiftUI

/// The window's sections. Search and Settings sit outside the list (pinned to the
/// top and bottom of the sidebar); the rest are list rows.
enum Pane: Hashable, Identifiable {
    case home, history, practice, bookmarks, profile, search, dictionaries, settings

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "Home"
        case .history: "History"
        case .practice: "Practice"
        case .bookmarks: "Bookmarks"
        case .profile: "Profile"
        case .search: "Search"
        case .dictionaries: "Dictionaries"
        case .settings: "Settings"
        }
    }

    /// What the pane's icon MEANS. The theme picks the drawing — an SF Symbol or
    /// a doodle — so this table names neither.
    var glyph: Glyph {
        switch self {
        case .home: .home
        case .history: .history
        case .practice: .practice
        case .bookmarks: .bookmarks
        case .profile: .profile
        case .search: .search
        case .dictionaries: .dictionaries
        case .settings: .settings
        }
    }
}

struct RootView: View {
    @State private var pane: Pane = .home
    /// Settings can hide the Practice row; the pane itself is unreachable then.
    @AppStorage("practiceEnabled") private var practiceEnabled = true
    /// Set in Profile. Empty means "keep following the Google account".
    /// The picture is `AccountAvatar`'s own business, so only the name is read here.
    @AppStorage("profileName") private var profileName = ""
    @Environment(\.colorScheme) private var scheme
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        Group {
            if !auth.restored {
                // At most one frame: restore() is a keychain read, not a round trip.
                // Painting the window's own background rather than a spinner means a
                // returning user sees no flicker between launch and the shell.
                Theme.of(scheme).background.ignoresSafeArea()
            } else if auth.isSignedIn {
                shell
            } else {
                SignInView()
            }
        }
        // Here rather than in ProfileView: the gate needs the answer before anything
        // renders, and the sidebar shows who you are whether or not Profile is opened.
        .task { auth.restore() }
    }

    /// Everything behind the gate.
    private var shell: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            // One stack per pane: related words and list rows still push, and a
            // pane switch drops whatever was pushed on top of the old one.
            NavigationStack { detail }
        }
    }

    @ViewBuilder private var detail: some View {
        switch pane {
        case .home:         HomeView(pane: $pane)
        case .history:      HistoryView()
        case .practice:     SentenceView()
        case .bookmarks:    WordListView(wordbook: .saved)
        case .profile:      ProfileView(pane: $pane)
        case .search:       WordListView()
        case .dictionaries: DictionaryPicker()
        case .settings:     SettingsView()
        }
    }

    private var sidebar: some View {
        List(selection: $pane) {
            ForEach([Pane.home, .history, .practice, .bookmarks]
                        .filter { $0 != .practice || practiceEnabled }) { item in
                row(item).tag(item)
            }
            Section("Dictionaries") {
                row(.dictionaries).tag(Pane.dictionaries)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { searchField }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // The sidebar only exists behind the gate, so there is always a user to
            // show here — the corner is who you are, and the way in to Profile.
            accountChip
        }
        .navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 300)
    }

    /// A sidebar row. `Label`'s systemImage form can only take an SF Symbol, so
    /// the icon is built by hand and the theme decides what goes in it.
    private func row(_ item: Pane) -> some View {
        Label { Text(item.title) } icon: { GlyphIcon(item.glyph) }
    }

    /// A launcher, not a field — the real search box lives in the Search pane, so
    /// there's only ever one query to keep straight.
    private var searchField: some View {
        let t = Theme.of(scheme)
        return Button { pane = .search } label: {
            HStack(spacing: 7) {
                GlyphIcon(.search)
                Text("Search")
                Spacer(minLength: 6)
                Text("\u{2318}K")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(t.background.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
            }
            .font(.system(size: 13))
            .foregroundStyle(t.muted)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(t.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("k")
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    /// Name and face, and that's the whole target: tapping the corner goes to
    /// Profile. Settings moved into Profile, so there's nothing left to unfold here.
    private var accountChip: some View {
        let t = Theme.of(scheme)
        return Button { pane = .profile } label: {
            HStack(spacing: 8) {
                AccountAvatar(url: auth.photoURL, size: 20, muted: t.muted)
                Text(profileName.isEmpty ? (auth.displayName ?? "Signed in") : profileName)
                    .font(.system(size: 13))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Show your profile")
        .padding(.horizontal, 12)
        .padding(.vertical, 13)
    }
}

#Preview {
    RootView()
        .environment(RelatedWordsStore())
        .environment(AuthViewModel())
}
