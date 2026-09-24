//
//  RootView.swift
//  OneWord
//
//  The window shell: a sidebar of sections beside the reading pane. The window
//  has no toolbar — each pane draws its own header (PaneHeader.swift) with just
//  the buttons it needs, so the strip adapts to whatever is showing.
//
//  It is also the gate. Signed out, the whole shell is replaced by SignInView —
//  no pane, no search, no dictionary is reachable without a session. The widget
//  is outside this: it reads the same bundled JSON and cannot run an OAuth flow.
//

import SwiftUI

/// The window's sections. Search and Settings sit outside the list (pinned to the
/// top and bottom of the sidebar); the rest are list rows. Premium is reached from
/// the plan tag in the sidebar's corner, so it has no row either.
enum Pane: Hashable, Identifiable {
    case home, history, practice, bookmarks, profile, search, dictionaries, settings, premium

    var id: Self { self }

    /// Screenshot automation: `open --env ONEWORD_PANE=history "One Word.app"`
    /// launches straight into that pane. Nil for anything but a pane title.
    static var launchPane: Pane? {
        guard let name = ProcessInfo.processInfo.environment["ONEWORD_PANE"] else { return nil }
        return [Pane.home, .history, .practice, .bookmarks, .profile, .search, .dictionaries, .settings, .premium]
            .first { $0.title.lowercased() == name.lowercased() }
    }

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
        case .premium: "Premium"
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
        case .premium: .premium
        }
    }
}

struct RootView: View {
    @State private var pane: Pane = Pane.launchPane ?? .home
    /// Bound so a pane's header can fold the sidebar: with no toolbar there is no
    /// stock toggle to do it.
    @State private var columns: NavigationSplitViewVisibility = .all
    /// Settings can hide the Practice row; the pane itself is unreachable then.
    @AppStorage("practiceEnabled") private var practiceEnabled = true
    /// Set in Profile. Empty means "keep following the Google account".
    /// The picture is `AccountAvatar`'s own business, so only the name is read here.
    @AppStorage("profileName") private var profileName = ""
    /// The one-time "have a suggestion?" card. Flipped by its own close or Write
    /// button and never consulted again. An inline card rather than a popover: a
    /// macOS popover dismisses on any focus loss, so it closed itself at launch.
    @AppStorage("suggestionCalloutSeen") private var calloutSeen = false
    /// Owned here, like SettingsView owns its copy, so an unsent draft outlives
    /// the dismissed sheet.
    @State private var feedback = FeedbackViewModel()
    @State private var writing = false
    @Environment(\.colorScheme) private var scheme
    @Environment(AuthViewModel.self) private var auth
    /// For the plan tag in the corner.
    @Environment(PremiumViewModel.self) private var premium
    /// Midnight rides in with the doodle switches, so every palette read in the
    /// shell goes through it.
    @Environment(\.doodle) private var doodle

    var body: some View {
        Group {
            if !auth.restored {
                // At most one frame: restore() is a keychain read, not a round trip.
                // Painting the window's own background rather than a spinner means a
                // returning user sees no flicker between launch and the shell.
                Theme.of(scheme, doodle).background.ignoresSafeArea()
            } else if auth.isSignedIn {
                shell
            } else {
                SignInView()
            }
        }
        // Here rather than in ProfileView: the gate needs the answer before anything
        // renders, and the sidebar shows who you are whether or not Profile is opened.
        .task { auth.restore() }
        // Over the whole window, not the button: the browser round trip owns the
        // screen until it resolves, and nothing behind it should take a click.
        .busy(auth.busy, theme: Theme.of(scheme, doodle))
    }

    /// Everything behind the gate.
    private var shell: some View {
        let t = Theme.of(scheme, doodle)
        return NavigationSplitView(columnVisibility: $columns) {
            sidebar
        } detail: {
            // One stack per pane: related words and list rows still push, and a
            // pane switch drops whatever was pushed on top of the old one.
            NavigationStack { detail }
        }
        .environment(\.sidebar, $columns)
        // A painted appearance's own accent on the sidebar selection and every stock
        // control; nil leaves Light and Dark on the system accent they've always had.
        .tint(doodle.appearance.paintsPalette ? t.accent : nil)
    }

    @ViewBuilder private var detail: some View {
        switch pane {
        case .home:         HomeView(pane: $pane)
        case .history:      HistoryView()
        // The gate itself, so a launch pane or a lapsed purchase can't land on it either.
        case .practice:     if premium.isUnlocked { SentenceView() } else { PremiumView() }
        case .bookmarks:    WordListView(wordbook: .saved)
        case .profile:      ProfileView(pane: $pane)
        case .search:       WordListView()
        case .dictionaries: DictionaryPicker()
        case .settings:     SettingsView()
        case .premium:      PremiumView()
        }
    }

    private var sidebar: some View {
        let t = Theme.of(scheme, doodle)
        // A locked Practice row still takes the click — it goes to the plans instead.
        let selection = Binding { pane } set: { pane = $0 == .practice && !premium.isUnlocked ? .premium : $0 }
        return List(selection: selection) {
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
            VStack(spacing: 0) {
                if !calloutSeen { suggestionCard }
                HStack(spacing: 0) {
                    accountChip
                    planTag
                    feedbackButton
                }
            }
        }
        // The stock sidebar is a grey material. A painted appearance takes it over with
        // the panes' own ground — Midnight's band included, which has no x in it, so it
        // meets the pane's copy across the divider and the window reads as one surface.
        // Light and Dark keep the material.
        .scrollContentBackground(doodle.appearance.paintsPalette ? .hidden : .automatic)
        .background { if doodle.appearance.paintsPalette { PaneGround(t: t) } }
        .sheet(isPresented: $writing) { FeedbackView(theme: t, model: feedback) }
        // macOS 27 honours the column's max but lets the divider drag past its min —
        // down to 140pt, where "Search" wraps. The content's own min width holds it.
        .frame(minWidth: 190)
        .navigationSplitViewColumnWidth(min: 190, ideal: 215, max: 300)
        // The stock toggle is the one toolbar item a split view adds by itself, so
        // without it the window has no toolbar — which in full screen macOS would
        // paint grey in a window of its own. PaneHeader carries the toggle instead.
        // Not `.toolbar(.hidden, for: .windowToolbar)`: that hid the traffic lights too.
        .toolbar(removing: .sidebarToggle)
    }

    /// A sidebar row. `Label`'s systemImage form can only take an SF Symbol, so
    /// the icon is built by hand and the theme decides what goes in it.
    private func row(_ item: Pane) -> some View {
        let locked = item == .practice && !premium.isUnlocked
        return Label {
            HStack(spacing: 6) {
                Text(item.title)
                if locked {
                    Spacer(minLength: 0)
                    // The shelf's lock: same glyph, size and ink as a locked book's.
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.of(scheme, doodle).muted)
                        .accessibilityHidden(true)
                }
            }
        } icon: { GlyphIcon(item.glyph) }
        .accessibilityValue(locked ? "Premium" : "")
        .accessibilityHint(locked ? "Shows how to unlock" : "")
    }

    /// A launcher, not a field — the real search box lives in the Search pane, so
    /// there's only ever one query to keep straight.
    private var searchField: some View {
        let t = Theme.of(scheme, doodle)
        return Button { pane = .search } label: {
            HStack(spacing: 7) {
                GlyphIcon(.search)
                Text("Search")
                Spacer(minLength: 6)
                Text("\u{2318}K")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(t.background.opacity(0.7), in: RoundedRectangle(cornerRadius: t.radius(4)))
            }
            .font(.system(size: 13))
            .foregroundStyle(t.muted)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(t.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: t.radius(7)))
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
        let t = Theme.of(scheme, doodle)
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
        .padding(.leading, 12)
        .padding(.vertical, 13)
    }

    /// Which plan you're on, beside who you are — and the way to see what Premium
    /// holds. Its own button, so the name still goes to Profile.
    private var planTag: some View {
        let owned = premium.isUnlocked
        return Button { pane = .premium } label: {
            PlanTag(text: owned ? "Premium" : "Free", filled: owned)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(owned ? "Premium — every dictionary is yours" : "Free plan — see what Premium adds")
        .accessibilityLabel(owned ? "Premium plan" : "Free plan")
        .accessibilityHint("Shows the plans")
        .padding(.trailing, 4)
    }

    private func write() {
        calloutSeen = true
        feedback.reset()
        writing = true
    }

    /// The permanent way to the notepad, and what the one-time card sits above —
    /// so closing the card never hides the way back.
    private var feedbackButton: some View {
        let t = Theme.of(scheme, doodle)
        return Button(action: write) {
            GlyphIcon(.feedback)
                .foregroundStyle(t.muted)
                .padding(6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Send a suggestion")
        .accessibilityLabel("Send a suggestion")
        .padding(.trailing, 6)
    }

    /// Shown once, on the first launch after it shipped. Close or Write hides it
    /// for good; nothing else can.
    private var suggestionCard: some View {
        let t = Theme.of(scheme, doodle)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text("Have a suggestion?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.ink)
                Spacer(minLength: 8)
                Button { calloutSeen = true } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(t.muted)
                        .padding(3)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            Text("One line is enough. It goes straight to us.")
                .font(.system(size: 12))
                .foregroundStyle(t.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button("Write a line", action: write)
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(t.ink)
                .padding(.top, 6)
        }
        .padding(12)
        .background(t.surface, in: RoundedRectangle(cornerRadius: t.radius(8)))
        .overlay(RoundedRectangle(cornerRadius: t.radius(8)).strokeBorder(t.ink.opacity(0.1)))
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .transition(.opacity)
    }
}

#Preview {
    RootView()
        .environment(RelatedWordsStore())
        .environment(AuthViewModel())
        .environment(PremiumViewModel())
}
