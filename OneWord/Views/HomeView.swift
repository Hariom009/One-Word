//
//  HomeView.swift
//  OneWord
//
//  Today's word — the Home pane. Dumb view: binds to WordViewModel, does no data
//  loading. Past days live in HistoryView; the sidebar owns search and settings.
//

import SwiftUI
import WidgetKit
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct HomeView: View {
    /// So the dictionary chip can send you to the Dictionaries pane rather than
    /// opening a second, sheet-shaped way to pick one.
    @Binding var pane: Pane
    @State private var model = WordViewModel()
    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle
    @Environment(AuthViewModel.self) private var auth
    /// Owning Premium shows as one sky spark after "Today"; Home sells nothing either way.
    @Environment(PremiumViewModel.self) private var premium
    /// Phone only: the day picked from the title's calendar. nil = today, and stays
    /// today across midnight rather than freezing on the day it was opened.
    @State private var day: Date?
    @State private var picking = false
    /// The day the feed was last built around, so returning to the app can tell a new
    /// day (take its new top) from the same day (leave the scroll where it was).
    @State private var shownDay = Calendar.current.startOfDay(for: .now)
    /// The end the page is pulled far enough past that letting go brings the next word.
    @State private var armed: Edge?
    /// Where the next word comes in from: the end the page was pulled past.
    @State private var pushFrom: Edge = .bottom
    /// Bumped by every double tap that keeps a word; the ribbon drops in off it.
    @State private var kept = 0
    /// Which page of the phone feed is showing — the deck slot, or `endSlot` for the
    /// page that says the day's feed is done. Written by the scroll view itself.
    @State private var feedPage: Int? = 0
    /// The word whose full entry is open over the feed, the same sheet a list row opens.
    @State private var opened: Word?
    /// Not a deck slot: the end page's id.
    private static let endSlot = -1
    #if os(macOS)
    @State private var shortcutEnabled = false
    #endif
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(RelatedWordsStore.self) private var store
    /// The floor when there's no account to read a join date off (accounts off).
    /// ponytail: stamped on first sight of Home, so pre-existing installs start today.
    @AppStorage("firstOpened") private var firstOpened: Double = 0
    private let calendar = Calendar.current

    var body: some View {
        let t = Theme.of(scheme, doodle)
        // Embedded: Home paints the ground and owns the header, so the word's own
        // buttons join the chip in one strip rather than a second.
        Group {
            if isPhone {
                // A phone strip can't seat the date, the chip and three buttons. The
                // strip says "Today" and opens a calendar; the dictionary sits over the
                // word as one quiet line, the way a dictionary page carries its running head.
                feed(t)
            } else {
                page
            }
        }
            .paneBackground(t)
            #if os(macOS)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    Text("Double-space for another word")
                        .font(.system(size: 11))
                        .foregroundStyle(t.muted)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .overlay(alignment: .top) { t.hairline.frame(height: 1) }
            }
            .background {
                WordRefreshShortcut(enabled: shortcutEnabled && scenePhase == .active) { nextWord() }
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
            .onAppear { shortcutEnabled = true }
            .onDisappear { shortcutEnabled = false }
            #endif
            // The dateline rides in the header's own strip rather than above the feed.
            // Stacked over the scroll view its height came off the pages without coming
            // off the container, so every page was a dateline taller than the window it
            // paged to and the snap drifted further out with each swipe.
            // Clear: the word's picture runs up under the strip. Hear it is on the page.
            .paneHeader(isPhone ? dayTitle : Date.now.formatted(.dateTime.month(.wide).day().year()),
                        titleAction: isPhone ? { picking = true } : nil, spark: premium.isUnlocked,
                        clear: true) {
                // The phone's book is a button in its own cloth, off the picture; the Mac's
                // rides over the word, with Dictionaries a click away in the sidebar.
                if isPhone {
                    Button { pane = .dictionaries } label: {
                        BookChip(book: model.wordbook, height: 22)
                    }
                    .help("Choose a dictionary")
                    .accessibilityLabel("Dictionary: \(model.wordbook.shortName)")
                    .accessibilityHint("Chooses a dictionary")
                }
                WordActions(word: model.word, speaks: false)
            }
            // Over the header too, so the whole screen frosts behind the ribbon.
            .overlay { ribbonDrop }
            .sheet(isPresented: $picking) { dayPicker(t) }
            // The feed's cards are capped to fit a screen; the whole entry — same-vein
            // box, full definition, full example — opens here, as a list row's does.
            .sheet(item: $opened) { word in
                NavigationStack {
                    WordDetail(word: word, close: { opened = nil })
                }
            }
            .onAppear {
                if firstOpened == 0 { firstOpened = Date.now.timeIntervalSince1970 }
                model.select(Wordbook.named(dictionaryID))
                show()
            }
            .onChange(of: dictionaryID) { _, id in
                model.select(Wordbook.named(id))
                show()
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onChange(of: day) { show() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                // Coming back must not yank you out of the days you'd scrolled back into —
                // the same guard the catch below already uses. A new day is the exception:
                // the feed has a new top, so take it.
                guard calendar.startOfDay(for: .now) != shownDay || !model.isPeeking else { return }
                show()
            }
            // A catch can land while this window is already open and visible.
            // Not mid-peek: bookmarking the peeked word would yank today's back
            // under your finger. The peek's own refresh picks any catch up.
            .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
                if !model.isPeeking { show() }
            }
    }

    /// The word. Pull the page past either end and let go for a random word from the
    /// book; it stays until Home refreshes. A past day stays put.
    private var page: some View {
        ZStack {
            WordDetail(word: model.word, showDate: !isPhone,
                       dictionaryName: isPhone ? nil : model.wordbook.shortName, embedded: true, hero: true)
                // A double tap on bare page keeps the word; the page's own controls still
                // take their taps first. contentShape so the blank paper answers too.
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { if model.bookmark() { kept += 1 } }
                .modifier(PullForNext(armed: $armed) { nextWord(from: $0) })
                // Keyed on the word, so every change of word brings a new page in.
                .id(model.word.term)
                .transition(flip)
        }
        // Only a flip pushes up. The day's word coming back — a pane switch, the app
        // reopening — just swaps in, with the corner saying which it is.
        .animation(model.isPeeking ? .spring(duration: 0.5, bounce: 0.15) : nil, value: model.word.term)
        // The next word gets its neighbours ranked off the main thread now, so the pull
        // that brings it in doesn't rank them on its first frame.
        .onChange(of: model.upcoming.term, initial: true) { store.prefetch(model.upcoming, in: dictionaryID) }
        // ponytail: no feedback on the pull itself — only the double tap that keeps a
        // word answers back, since nothing on screen says it landed.
        .sensoryFeedback(.success, trigger: kept)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Another word") { nextWord() }
    }

    /// The phone's word feed: one word per screen, paged. The OS owns the physics —
    /// the drag tracks the finger, a flick hands its velocity to the deceleration, a
    /// half-swipe springs back, and all of it is interruptible — which is what makes it
    /// read as a feed rather than a button that plays an animation. Scrolling back
    /// shows the words already passed, in the order they came.
    private func feed(_ t: Theme) -> some View {
        // A picked day stays put, as it did when a pull was the way on: one page, no feed.
        let slots = day == nil ? Array(0..<dayCount) : [0]
        // The page height comes from a reader that ignores the safe area, NOT from
        // `containerRelativeFrame`. A scroll container is the screen minus its insets —
        // the header's and the tab bar's — so container-sized pages are about 290pt
        // short, and the next word's hero sits in the gap at the foot of the screen for
        // as long as you look at the word above it.
        return GeometryReader { screen in
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    // Keyed on the slot, never the term: a small book repeats words, and two
                    // pages carrying one id make the paging jump between them.
                    ForEach(slots, id: \.self) { slot in
                        card(slot, t)
                            .frame(height: screen.size.height)
                            .id(slot)
                    }
                    if day == nil {
                        endPage(t)
                            .frame(height: screen.size.height)
                            .id(Self.endSlot)
                    }
                }
                .scrollTargetLayout()
            }
            // `.viewAligned`, not `.paging`: paging snaps by the container, which is the
            // short measure above, so a full-height page and a container-high snap would
            // drift further apart with every swipe. View-aligned snapping follows the
            // pages themselves, so the two can never disagree.
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $feedPage)
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
            .onChange(of: feedPage, initial: true) { _, slot in
                // A picked day is one page showing THAT day; landing would pull today's back.
                guard day == nil, let slot, slot != Self.endSlot, slot < dayCount else { return }
                model.land(on: slot)
                // Logged here, not in the card: a lazy stack builds a card a page before
                // you reach it, and a word built ahead of you was never read. Honest now the
                // pages are days — every word you can reach WAS your word on the day it names.
                let shown = model.word
                LearnedWords.record(shown, in: slot == 0 && SavedWords.pinned?.term == shown.term
                                    ? SavedWords.resource : dictionaryID)
                // The day before's neighbours get ranked off the main thread now, so opening
                // its full entry doesn't rank 12k dot products on its first frame.
                if slot + 1 < dayCount { store.prefetch(model.pageWord(slot + 1), in: dictionaryID) }
            }
            // The landing is the feed's only answer to a swipe. `.selection`, not `.success`:
            // a detent under the thumb, not an achievement.
            .sensoryFeedback(.selection, trigger: feedPage)
            .sensoryFeedback(.success, trigger: kept)
            .accessibilityElement(children: .contain)
            .accessibilityAction(named: "The day before") {
                let next = (feedPage ?? 0) + 1
                if next < dayCount { withAnimation { feedPage = next } }
            }
        }
        // On the reader, so `screen.size` is the whole screen and a page covers the
        // header and the tab bar rather than stopping politely above them.
        .ignoresSafeArea(.container, edges: [.top, .bottom])
    }

    /// One page of the feed: the word, fixed to the screen, with the double tap that
    /// keeps it and the way through to its full entry. Only the page you are on counts
    /// as visible — a card built ahead of you holds its clip on the first frame.
    private func card(_ slot: Int, _ t: Theme) -> some View {
        let w = day == nil ? model.pageWord(slot) : model.word
        return WordDetail(word: w, embedded: true, card: true, visible: slot == feedPage,
                          hero: true, onFullEntry: { opened = w })
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { if model.bookmark(w) { kept += 1 } }
    }

    /// The foot of the feed: where your days start. One word a day is the whole
    /// premise, so the scroll ends where you began rather than running on into words
    /// no day has handed you yet.
    private func endPage(_ t: Theme) -> some View {
        let first = date(back: dayCount - 1).formatted(date: .long, time: .omitted)
        return VStack(spacing: 12) {
            Text(dayCount > 1 ? "Back to the start" : "Your first word")
                .font(doodle.face(30)).tracking(doodle.tracking(30))
                .foregroundStyle(t.ink)
            Text(dayCount > 1
                 ? "\(first) was your first word. Every day since is above this one, and tomorrow adds another."
                 : "You started today. Tomorrow brings your second, and this scroll grows a day at a time.")
                .font(.system(size: 14))
                .foregroundStyle(t.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            Button("Back to today") { withAnimation { feedPage = 0 } }
                .font(.system(size: 13, weight: .semibold))
                .buttonStyle(.plain)
                .foregroundStyle(t.accent)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    /// Pulling on iPhone and double-space on Mac share the same temporary preview.
    private func nextWord(from edge: Edge = .bottom) {
        guard day == nil else { return }
        pushFrom = edge
        // A turn later, so the leaving page has its direction too, not the last flip's.
        Task { @MainActor in model.shuffle() }
    }

    /// The new page rises a short way in from the end you pulled past. The old one
    /// leaves fast, drifting against its own rubber band springing back — so it holds
    /// still and fades instead of lurching the wrong way under the incoming word.
    private var flip: AnyTransition {
        if reduceMotion { return .opacity }
        let way: CGFloat = pushFrom == .bottom ? 1 : -1
        return .asymmetric(
            insertion: .offset(y: 120 * way).combined(with: .opacity),
            removal: .offset(y: -80 * way).combined(with: .opacity).animation(.easeOut(duration: 0.18)))
    }

    /// The double tap's answer, since no button was pressed: the screen frosts over and a
    /// ribbon drops into the middle, pulls long as the toolbar's does, then both clear.
    /// Plays even on a word already kept — the tap still asked "is it saved?". Reduce
    /// Motion keeps only the fades.
    private var ribbonDrop: some View {
        KeyframeAnimator(initialValue: RibbonDrop(), trigger: kept) { v in
            ZStack {
                // Only there while it shows: a material at rest still blurs every frame.
                if v.veil > 0 {
                    Rectangle().fill(.ultraThinMaterial).opacity(v.veil).ignoresSafeArea()
                }
                BookmarkRibbon(size: 96)
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                    .scaleEffect(y: reduceMotion ? 1 : v.stretch, anchor: .top)
                    .offset(y: reduceMotion ? 0 : v.drop)
                    .opacity(v.opacity)
            }
        } keyframes: { _ in
            // MoveKeyframe first, so a second double tap mid-drop starts it over.
            KeyframeTrack(\.drop) {
                MoveKeyframe(-40)
                SpringKeyframe(0, duration: 0.2, spring: .bouncy)
                LinearKeyframe(0, duration: 0.225)
                CubicKeyframe(16, duration: 0.15)
            }
            KeyframeTrack(\.stretch) {
                MoveKeyframe(1)
                CubicKeyframe(1.22, duration: 0.125)
                CubicKeyframe(1, duration: 0.175)
            }
            KeyframeTrack(\.opacity) {
                MoveKeyframe(0)
                LinearKeyframe(1, duration: 0.06)
                LinearKeyframe(1, duration: 0.365)
                LinearKeyframe(0, duration: 0.15)
            }
            // Frosts in with the drop, clears with the ribbon.
            KeyframeTrack(\.veil) {
                MoveKeyframe(0)
                CubicKeyframe(1, duration: 0.1)
                LinearKeyframe(1, duration: 0.325)
                CubicKeyframe(0, duration: 0.15)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Today's word through the shared offset and pin; a past day's plain, as History reads it.
    private func show() {
        if let day { model.show(model.wordbook, on: day) } else { model.refresh() }
        shownDay = calendar.startOfDay(for: .now)
        // The deck was just rebuilt around the word now showing; a stale slot would
        // leave the feed parked on a page that no longer exists.
        feedPage = 0
    }

    /// The day your words start: the account's join date, or the first time Home was
    /// opened when there's no account to read one off. Never later than today.
    private var joinedDay: Date {
        // `firstOpened` is stamped in onAppear, which runs AFTER the first body — so zero
        // here means "this very frame", not 1970. Unguarded it would size the feed at
        // twenty thousand days before collapsing to one.
        let stamped = firstOpened > 0 ? Date(timeIntervalSince1970: firstOpened) : .now
        return calendar.startOfDay(for: min(auth.joined ?? stamped, .now))
    }

    /// How far the feed runs: today, plus every day back to the one you joined.
    private var dayCount: Int {
        max(calendar.dateComponents([.day], from: joinedDay, to: calendar.startOfDay(for: .now)).day ?? 0, 0) + 1
    }

    /// The day `page` pages down from today.
    private func date(back page: Int) -> Date {
        calendar.date(byAdding: .day, value: -max(page, 0), to: .now) ?? .now
    }

    /// What the strip says the page is: "Today", "Yesterday", the weekday while it's
    /// still this week, then the date — with the year only once it isn't this one.
    /// It follows the scroll, so the one thing that changes on every page is the one
    /// that says which day you're reading. That's why the feed needs no dots or count.
    private var dayTitle: String {
        let page = feedPage ?? 0
        // The foot of the feed keeps the first day's name rather than falling back to today.
        let shown = day ?? date(back: page == Self.endSlot ? dayCount - 1 : page)
        if calendar.isDateInToday(shown) { return "Today" }
        if calendar.isDateInYesterday(shown) { return "Yesterday" }
        let back = calendar.dateComponents([.day], from: calendar.startOfDay(for: shown),
                                           to: calendar.startOfDay(for: .now)).day ?? 0
        if back < 7 { return shown.formatted(.dateTime.weekday(.wide)) }
        return calendar.isDate(shown, equalTo: .now, toGranularity: .year)
            ? shown.formatted(.dateTime.month(.wide).day())
            : shown.formatted(.dateTime.month(.wide).day().year())
    }

    /// Phone only: any day from the one you joined up to today. A pick closes it.
    private func dayPicker(_ t: Theme) -> some View {
        let selection = Binding(get: { day ?? .now },
                                set: { day = calendar.isDateInToday($0) ? nil : $0 })
        let earliest = joinedDay
        let info = "You can pick any day from \(earliest.formatted(date: .long, time: .omitted)), "
            + "the day you joined One Word, up to today. Your words started the day you did, "
            + "and tomorrow's word isn't out yet."
        return MonthCalendar(selection: selection, earliest: earliest, info: info) { _ in picking = false }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 20)
            .presentationDetents([.height(430)])
            .presentationDragIndicator(.visible)
            .presentationBackground(t.background)
    }

}

/// Where the double tap's ribbon is in its drop. At rest it's unseen.
private struct RibbonDrop {
    var drop: CGFloat = 0
    var stretch: CGFloat = 1
    var opacity: Double = 0
    /// The frost over the rest of the screen.
    var veil: Double = 0
}

/// Pulling Home's page past either end, then letting go, asks for the next word. The
/// stretch is the page's own rubber band, so it reads as scrolling on, not a new gesture.
/// The scroll APIs are iOS 18 / macOS 15:
/// before those the page only scrolls, and "Another word" stays in the rotor.
private struct PullForNext: ViewModifier {
    /// How far past its end the page has to be pulled — about twice that under the finger.
    static let pull: CGFloat = 20
    @Binding var armed: Edge?
    let next: (Edge) -> Void
    /// Only a finger arms it: a flick's coast overshooting the end would ask for nothing.
    @State private var dragging = false

    func body(content: Content) -> some View {
        if #available(iOS 18, macOS 15, *) {
            content
                // A page shorter than the screen has no end to pull past unless it bounces.
                .scrollBounceBehavior(.always, axes: .vertical)
                .onScrollGeometryChange(for: Edge?.self, of: Self.past) { if dragging { armed = $1 } }
                // Read off the release, not `armed`: the page leaving keeps reporting as it goes.
                .onScrollPhaseChange { old, new, context in
                    if new == .interacting {
                        dragging = true
                    } else if old == .interacting {
                        dragging = false
                        armed = nil
                        if let edge = Self.past(context.geometry) { next(edge) }
                    }
                }
        } else {
            content
        }
    }

    /// Which end the page is pulled past, far enough to count. nil while it isn't.
    @available(iOS 18, macOS 15, *)
    private static func past(_ g: ScrollGeometry) -> Edge? {
        // Where the page rests at either end; one shorter than the screen rests at its top for both.
        let top = -g.contentInsets.top
        let end = max(g.contentSize.height + g.contentInsets.bottom - g.containerSize.height, top)
        if g.contentOffset.y - end > pull { return .bottom }
        if top - g.contentOffset.y > pull { return .top }
        return nil
    }
}

#Preview {
    NavigationStack { HomeView(pane: .constant(.home)) }
        .environment(RelatedWordsStore())
        .environment(PremiumViewModel())
        .environment(AuthViewModel())
}
