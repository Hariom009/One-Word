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
    /// The page's sideways drag. Springs home when let go short of a swipe.
    @GestureState(resetTransaction: Transaction(animation: .bouncy)) private var drag: CGFloat = 0
    /// Bumped by every swipe, either way; the phone's landing tap fires off it.
    @State private var peeks = 0
    /// Bumped by every double tap that keeps a word; the ribbon drops in off it.
    @State private var kept = 0
    /// Cards on: the word sits on a card with its neighbours peeking in, and swipes
    /// browse. Off, Home is the plain page. A long press on the page flips it.
    @State private var flowing = false
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
                    coverFlow(t)
                }
            } else {
                coverFlow(t)
            }
        }
            .paneBackground(t)
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

    /// The word, as the plain page or — after a long press — as a cover flow: the word on
    /// a card, the last one peeking in on the left and a random one waiting on the right.
    /// A swipe left brings that one in, a swipe right goes back. Sideways only — up and
    /// down is reading the card in front. One view tree for both, so the flip morphs.
    private func coverFlow(_ t: Theme) -> some View {
        GeometryReader { geo in
            let width = geo.size.width * (flowing ? (isPhone ? 0.82 : 0.78) : 1)
            // Nothing left of the day's word: pulling right there only gives a little.
            let shift = drag / width * (drag > 0 && model.previous == nil ? 0.25 : 1)
            ZStack {
                ForEach(cards) { card($0, at: $0.slot + shift, width: width, t) }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        // Every change of word slides the cards: a swipe, back, and the day's word returning.
        .animation(.spring(duration: 0.5, bounce: 0.15), value: model.word.term)
        .contentShape(Rectangle())
        .simultaneousGesture(DragGesture(minimumDistance: 20)
            .updating($drag) { value, drag, _ in
                let t = value.translation
                drag = abs(t.width) > abs(t.height) ? t.width : 0
            }
            .onEnded { value in
                // The predicted end, so a quick flick swipes as surely as a long drag.
                let t = value.translation, end = value.predictedEndTranslation.width
                guard abs(t.width) > abs(t.height), abs(end) > Self.swipe else { return }
                if end < 0 { model.shuffle() } else if model.previous != nil { model.back() } else { return }
                peeks += 1
            }, including: flowing && day == nil ? .all : .subviews)
        .onChange(of: drag != 0) { _, dragging in dragging ? model.hold() : model.letGo() }
        // The card waiting on the right gets its neighbours ranked off the main thread
        // now, so the swipe that brings it in doesn't rank them on its first frame.
        .onChange(of: flowing ? model.upcoming.term : nil, initial: true) {
            if flowing { store.prefetch(model.upcoming, in: dictionaryID) }
        }
        // A tick as the drag passes the point where letting go swipes, a tap as the card lands.
        .sensoryFeedback(.selection, trigger: armed) { _, armed in armed }
        .sensoryFeedback(.impact(weight: .light), trigger: peeks)
        .sensoryFeedback(.success, trigger: kept)
        .sensoryFeedback(.impact(weight: .medium), trigger: flowing)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: flowing ? "Show as a page" : "Show as cards") { toggleFlow() }
        .accessibilityAction(named: "Another word") { model.shuffle() }
        .accessibilityAction(named: "Previous word") { model.back() }
    }

    /// The long press: cards on, or back to the plain page. Back on the page, the day's
    /// word returns at once, since the page has no neighbours to browse from.
    private func toggleFlow() {
        withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
            flowing.toggle()
            if !flowing, model.isPeeking { model.refresh() }
        }
    }

    /// How far a drag (or the fling it predicts) has to go to swipe.
    private static let swipe: CGFloat = 110

    /// Letting go now would swipe — not rightwards off the day's word, which has nothing before it.
    private var armed: Bool {
        drag < -Self.swipe || (drag > Self.swipe && model.previous != nil)
    }

    /// The front word plus its neighbours. A past day has no peek, so it gets its one
    /// card; in a tiny book a neighbour can repeat a card on screen, and is left out.
    private var cards: [FlowCard] {
        var cards = [FlowCard(word: model.word, slot: 0)]
        guard flowing, day == nil else { return cards }
        if let p = model.previous, p.term != model.word.term { cards.append(FlowCard(word: p, slot: -1)) }
        if !cards.contains(where: { $0.id == model.upcoming.term }) {
            cards.append(FlowCard(word: model.upcoming, slot: 1))
        }
        return cards
    }

    /// One card at position `p` — its slot plus the drag. Keyed on the word, so a swipe
    /// moves each card to its new slot rather than swapping words under still cards.
    private func card(_ card: FlowCard, at p: CGFloat, width: CGFloat, _ t: Theme) -> some View {
        let far = min(abs(p), 1.6)
        let front = card.slot == 0
        // Cards off, the front card IS the plain page: no corners, edge or paper of its
        // own, so the pane's ground (Midnight's glow) shows through as it always has.
        let chrome: Double = flowing ? 1 : 0
        let shape = RoundedRectangle(cornerRadius: flowing ? t.radius(22) : 0, style: .continuous)
        return WordDetail(word: card.word, showDate: !isPhone,
                          dictionaryName: isPhone ? nil : model.wordbook.shortName,
                          embedded: true, learns: front)
            // Paper and shadow on the shape alone. A shadow, opacity or clip over the whole
            // page re-renders it offscreen every frame of a swipe — that was the lag. The
            // ScrollView's own rect clip is enough: the page's margins keep text off the corners.
            .background {
                shape.fill(t.background.opacity(chrome))
                    .shadow(color: .black.opacity(0.12 * chrome), radius: 10, y: 3)
            }
            .overlay {
                // A card turning away dims under the ground's colour, not its own opacity.
                shape.fill(t.background.opacity(far * 0.45)).allowsHitTesting(false)
                shape.strokeBorder(t.hairline.opacity(chrome))
            }
            .overlay { if front { ribbonDrop } }
            // A double tap on bare page keeps the word; the page's own controls still
            // take their taps first. contentShape so the blank paper answers too.
            .contentShape(shape)
            .onTapGesture(count: 2) { if model.bookmark() { kept += 1 } }
            .onLongPressGesture(minimumDuration: 0.4) { toggleFlow() }
            .frame(width: width)
            .padding(.vertical, flowing ? (isPhone ? 12 : 20) : 0)
            .scaleEffect(1 - far * 0.16)
            .rotation3DEffect(.degrees(reduceMotion ? 0 : -p * 42), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .offset(x: p * width * 0.86)
            .zIndex(10 - far * 4)
            .allowsHitTesting(front)
            .accessibilityHidden(!front)
    }

    /// The double tap's answer, since no button was pressed: a ribbon drops onto the
    /// card, pulls long as the toolbar's does, then fades. Plays even on a word already
    /// kept — the tap still asked "is it saved?". Reduce Motion keeps only the fade.
    private var ribbonDrop: some View {
        BookmarkRibbon(size: 72)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
            .keyframeAnimator(initialValue: RibbonDrop(), trigger: kept) { ribbon, v in
                ribbon
                    .scaleEffect(y: reduceMotion ? 1 : v.stretch, anchor: .top)
                    .offset(y: reduceMotion ? 0 : v.drop)
                    .opacity(v.opacity)
            } keyframes: { _ in
                // MoveKeyframe first, so a second double tap mid-drop starts it over.
                KeyframeTrack(\.drop) {
                    MoveKeyframe(-40)
                    SpringKeyframe(0, duration: 0.4, spring: .bouncy)
                    LinearKeyframe(0, duration: 0.45)
                    CubicKeyframe(16, duration: 0.3)
                }
                KeyframeTrack(\.stretch) {
                    MoveKeyframe(1)
                    CubicKeyframe(1.22, duration: 0.25)
                    CubicKeyframe(1, duration: 0.35)
                }
                KeyframeTrack(\.opacity) {
                    MoveKeyframe(0)
                    LinearKeyframe(1, duration: 0.12)
                    LinearKeyframe(1, duration: 0.73)
                    LinearKeyframe(0, duration: 0.3)
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
}

/// A card on Home's cover flow: −1 the word before, 0 the one in front, 1 the one waiting.
private struct FlowCard: Identifiable {
    let word: Word
    let slot: CGFloat
    var id: String { word.term }
}

#Preview {
    NavigationStack { HomeView(pane: .constant(.home)) }
        .environment(RelatedWordsStore())
        .environment(PremiumViewModel())
        .environment(AuthViewModel())
}
