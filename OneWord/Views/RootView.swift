//
//  RootView.swift
//  OneWord
//
//  The window shell: a sidebar of sections beside the reading pane. Each pane
//  sets its own navigationTitle and toolbar, so the unified title bar adapts to
//  whatever is showing instead of carrying every button all the time.
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

    var symbol: String {
        switch self {
        case .home: "house"
        case .history: "clock"
        case .practice: "text.bubble"
        case .bookmarks: "bookmark"
        case .profile: "person.crop.circle"
        case .search: "magnifyingglass"
        case .dictionaries: "book"
        case .settings: "gearshape"
        }
    }
}

struct RootView: View {
    @State private var pane: Pane = .home
    /// Settings can hide the Practice row; the pane itself is unreachable then.
    @AppStorage("practiceEnabled") private var practiceEnabled = true
    @Environment(\.colorScheme) private var scheme
    @Environment(AuthViewModel.self) private var auth

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            // One stack per pane: related words and list rows still push, and a
            // pane switch drops whatever was pushed on top of the old one.
            NavigationStack { detail }
        }
        // Here rather than in ProfileView: the sidebar shows who you are on launch,
        // whether or not that pane is ever opened.
        .task { auth.restore() }
    }

    @ViewBuilder private var detail: some View {
        switch pane {
        case .home:         HomeView(pane: $pane)
        case .history:      HistoryView()
        case .practice:     SentenceView()
        case .bookmarks:    WordListView(wordbook: .saved)
        case .profile:      ProfileView()
        case .search:       WordListView()
        case .dictionaries: DictionaryPicker { pane = .home }
        case .settings:     SettingsView()
        }
    }

    private var sidebar: some View {
        List(selection: $pane) {
            ForEach([Pane.home, .history, .practice, .bookmarks, .profile]
                        .filter { $0 != .practice || practiceEnabled }) { item in
                Label(item.title, systemImage: item.symbol).tag(item)
            }
            Section("Dictionaries") {
                Label(Pane.dictionaries.title, systemImage: Pane.dictionaries.symbol)
                    .tag(Pane.dictionaries)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { searchField }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Signed in, the corner is who you are and Settings moves into its menu.
            // Signed out there is no identity to show, so the row stays a plain one.
            if auth.isSignedIn { accountChip } else { pinnedRow(.settings) }
        }
        .navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 300)
    }

    /// A launcher, not a field — the real search box lives in the Search pane, so
    /// there's only ever one query to keep straight.
    private var searchField: some View {
        let t = Theme.of(scheme)
        return Button { pane = .search } label: {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass")
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

    /// Name, face, chevron. The chevron is decoration — the whole chip opens the menu,
    /// which is a bigger target than a 9pt glyph and behaves the same.
    private var accountChip: some View {
        let t = Theme.of(scheme)
        return Menu {
            Button(Pane.settings.title) { pane = .settings }
        } label: {
            HStack(spacing: 8) {
                AccountAvatar(url: auth.photoURL, size: 20, muted: t.muted)
                Text(auth.displayName ?? "Signed in")
                    .font(.system(size: 13))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(t.muted)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)     // the chevron above is ours; don't draw a second one
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    /// Sidebar row for a pane the List doesn't hold — same look, drawn by hand.
    private func pinnedRow(_ item: Pane) -> some View {
        Button { pane = item } label: {
            Label(item.title, systemImage: item.symbol)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(pane == item ? AnyShapeStyle(.selection) : AnyShapeStyle(.clear),
                            in: RoundedRectangle(cornerRadius: 6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

#Preview {
    RootView()
        .environment(RelatedWordsStore())
        .environment(AuthViewModel())
}
