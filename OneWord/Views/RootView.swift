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
    case home, history, learned, practice, bookmarks, profile, search, dictionaries, settings

    var id: Self { self }

    var title: String {
        switch self {
        case .home: "Home"
        case .history: "History"
        case .learned: "Learned"
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
        case .learned: "checkmark.seal"
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
    @Environment(\.colorScheme) private var scheme

    var body: some View {
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
        case .learned:      LearnedListView()
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
            ForEach([Pane.home, .history, .learned, .practice, .bookmarks, .profile]) { item in
                Label(item.title, systemImage: item.symbol).tag(item)
            }
            Section("Dictionaries") {
                Label(Pane.dictionaries.title, systemImage: Pane.dictionaries.symbol)
                    .tag(Pane.dictionaries)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { searchField }
        .safeAreaInset(edge: .bottom, spacing: 0) { pinnedRow(.settings) }
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
}
