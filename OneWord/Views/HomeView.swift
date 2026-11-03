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
    /// Phone only: the day picked from the title's calendar. nil = today, and stays
    /// today across midnight rather than freezing on the day it was opened.
    @State private var day: Date?
    @State private var picking = false
    /// The page is pulled far enough past its end that letting go brings the next word.
    @State private var armed = false
    /// Bumped by every pull that brings a word; the phone's landing tap fires off it.
    @State private var peeks = 0
    /// Bumped by every double tap that keeps a word; the ribbon drops in off it.
    @State private var kept = 0
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
                VStack(spacing: 0) {
                    dateline(t)
                    page
                }
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
            .paneHeader(isPhone ? dayTitle : Date.now.formatted(.dateTime.month(.wide).day().year()),
                        titleAction: isPhone ? { picking = true } : nil) {
                if !isPhone {
                    Button {
                        pane = .dictionaries
                    } label: {
                        Text(model.wordbook.shortName)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                    }
                    // Long names ("Corporate Slang") would truncate in a squeezed strip.
                    // Ask for the ideal width instead and the chip sizes to its text.
                    .fixedSize()
                    .help("Choose a dictionary")
                }
                WordActions(word: model.word)
            }
            // Over the header too, so the whole screen frosts behind the ribbon.
            .overlay { ribbonDrop }
            .sheet(isPresented: $picking) { dayPicker(t) }
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
                show()
            }
            // A catch can land while this window is already open and visible.
            // Not mid-peek: bookmarking the peeked word would yank today's back
            // under your finger. The peek's own refresh picks any catch up.
            .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
                if !model.isPeeking { show() }
            }
    }

    /// The word. Pull the page up past its end and let go for a random word from the
    /// book; the day's word comes back 5s after the page is let be. A past day stays put.
    private var page: some View {
        ZStack {
            WordDetail(word: model.word, showDate: !isPhone,
                       dictionaryName: isPhone ? nil : model.wordbook.shortName, embedded: true)
                // A double tap on bare page keeps the word; the page's own controls still
                // take their taps first. contentShape so the blank paper answers too.
                .contentShape(Rectangle())
                .onTapGesture(count: 2) { if model.bookmark() { kept += 1 } }
                .modifier(PullForNext(armed: $armed) { $0 ? model.hold() : model.letGo() } next: {
                    nextWord()
                })
                // Keyed on the word, so every change of word pushes a new page up from below.
                .id(model.word.term)
                .transition(reduceMotion ? .opacity : .push(from: .bottom))
        }
        .animation(.spring(duration: 0.5, bounce: 0.15), value: model.word.term)
        // The next word gets its neighbours ranked off the main thread now, so the pull
        // that brings it in doesn't rank them on its first frame.
        .onChange(of: model.upcoming.term, initial: true) { store.prefetch(model.upcoming, in: dictionaryID) }
        // A tick as the pull passes the point where letting go brings the next word, a tap as it lands.
        .sensoryFeedback(.selection, trigger: armed) { _, armed in armed && day == nil }
        .sensoryFeedback(.impact(weight: .light), trigger: peeks)
        .sensoryFeedback(.success, trigger: kept)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Another word") { nextWord() }
    }

    /// Pulling on iPhone and double-space on Mac share the same temporary preview.
    private func nextWord() {
        guard day == nil else { return }
        model.shuffle()
        peeks += 1
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
    }

    /// "Today", or the picked day — "October 3", with the year only once it isn't this one.
    private var dayTitle: String {
        guard let day else { return "Today" }
        return calendar.isDate(day, equalTo: .now, toGranularity: .year)
            ? day.formatted(.dateTime.month(.wide).day())
            : day.formatted(.dateTime.month(.wide).day().year())
    }

    /// Phone only: any day from the one you joined up to today. A pick closes it.
    private func dayPicker(_ t: Theme) -> some View {
        let joined = auth.joined ?? Date(timeIntervalSince1970: firstOpened)
        let selection = Binding(get: { day ?? .now },
                                set: { day = calendar.isDateInToday($0) ? nil : $0 })
        let earliest = min(joined, .now)
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

    /// Phone only: the dictionary over the word, no rule under it. Tapping the book
    /// goes to the Dictionaries pane, as the Mac's chip does.
    private func dateline(_ t: Theme) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Spacer(minLength: 8)
            Button { pane = .dictionaries } label: {
                HStack(spacing: 6) {
                    BookChip(book: model.wordbook, height: 18)
                    Text(model.wordbook.shortName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dictionary: \(model.wordbook.shortName)")
            .accessibilityHint("Chooses a dictionary")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
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

/// Pulling Home's page up past its end, then letting go, asks for the next word. The
/// stretch is the page's own rubber band, so it reads as scrolling on, not a new gesture;
/// any scroll at all holds the day's word off. The scroll APIs are iOS 18 / macOS 15:
/// before those the page only scrolls, and "Another word" stays in the rotor.
private struct PullForNext: ViewModifier {
    /// How far past its end the page has to be pulled — about twice that under the finger.
    static let pull: CGFloat = 60
    @Binding var armed: Bool
    let scrolling: (Bool) -> Void
    let next: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18, macOS 15, *) {
            content
                // A page shorter than the screen has no end to pull past unless it bounces.
                .scrollBounceBehavior(.always, axes: .vertical)
                .onScrollGeometryChange(for: Bool.self, of: Self.past) { armed = $1 }
                // Read off the release, not `armed`: the page leaving keeps reporting as it goes.
                .onScrollPhaseChange { old, new, context in
                    if new == .interacting {
                        scrolling(true)
                    } else if old == .interacting {
                        scrolling(false)
                        if Self.past(context.geometry) { next() }
                    }
                }
        } else {
            content
        }
    }

    @available(iOS 18, macOS 15, *)
    private static func past(_ g: ScrollGeometry) -> Bool {
        // Where the page rests scrolled to its end; one shorter than the screen rests at its top.
        let end = max(g.contentSize.height + g.contentInsets.bottom - g.containerSize.height,
                      -g.contentInsets.top)
        return g.contentOffset.y - end > pull
    }
}

#Preview {
    NavigationStack { HomeView(pane: .constant(.home)) }
        .environment(RelatedWordsStore())
        .environment(PremiumViewModel())
        .environment(AuthViewModel())
}
