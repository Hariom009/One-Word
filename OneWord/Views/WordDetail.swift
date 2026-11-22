//
//  WordDetail.swift
//  OneWord
//
//  One word, editorial layout: optional date line, serif headword + italic part
//  of speech, a Devanagari meaning with an accent rule, the definition, and a
//  "Used as" example footer. Shared by HomeView (today, showDate) and the list detail.
//

import SwiftUI
import AVFoundation
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named
#if os(macOS)
import AppKit    // NSImage — the picture book's photos
#else
import UIKit     // UIImage — same
#endif

// ponytail: one shared synth — a local would deallocate mid-utterance, and two
// synths would talk over each other when you leave a word mid-sentence for Practice.
// Module-wide on purpose: SentenceView's Pronounce button speaks through this one.
@MainActor let speaker = AVSpeechSynthesizer()
/// The word's own recording, when it has one. Held here for the same reason as
/// `speaker`: a player that goes out of scope stops mid-sound.
@MainActor var clip: AVAudioPlayer?

/// Says the headword aloud — the header's Pronounce and Home's Hear it.
@MainActor func pronounce(_ word: Word) {
    speaker.stopSpeaking(at: .immediate)   // rapid clicks replace, don't queue
    clip?.stop()
    let utterance = AVSpeechUtterance(string: word.term)
    // Urdu headwords are Devanagari — an en-US voice reads them as silence.
    // Derived from the term, not the book, so any future script lands too.
    let devanagari = word.term.unicodeScalars.contains { (0x900...0x97F).contains($0.value) }
    utterance.voice = AVSpeechSynthesisVoice(language: devanagari ? "hi-IN" : "en-US")
    speaker.speak(utterance)
}

struct WordDetail: View {
    let word: Word
    var showDate: Bool = false
    var dictionaryName: String? = nil
    /// The shelf this word came from, when the caller knows it. Without it a word
    /// re-opened from a list gets logged against whatever dictionary happens to be
    /// selected, which reads as a second sighting that never happened.
    var shelf: String? = nil
    /// Home and History host the word inside their own pane: they paint the ground
    /// and put `WordActions` in their header, so the page draws neither.
    var embedded = false
    /// One page of the phone feed: fixed to the screen, no scroll view of its own,
    /// no same-vein box. See `cardPage`.
    var card = false
    /// Whether this entry is the one actually being read. Only a feed says otherwise,
    /// for the cards it builds either side of you — a clip on one of those holds its
    /// first frame instead of running a decoder for a page nobody is looking at.
    var visible = true
    /// Home only: the word's picture or clip runs full-bleed across the top, up under the
    /// header, and the entry sits on its fade. Hear it moves out of the header onto the page.
    var hero = false
    /// Home's phone feed: the page is capped to a screen, and this opens the rest in a sheet.
    var onFullEntry: (() -> Void)? = nil
    /// The sheet's own close, passed only to the word a sheet opens on. Pushed
    /// related words leave it nil, so their Back pops back to that word.
    var close: (() -> Void)? = nil
    @Environment(\.colorScheme) private var scheme
    @Environment(RelatedWordsStore.self) private var store
    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    @State private var showRelated = false
    /// The neighbours as a graph instead of a list. The Mac flips it from the box's
    /// right-hand toggle; a phone's box has no room for it, so it lives in Settings.
    @AppStorage("relatedAsGraph") private var relatedAsGraph = false
    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @AppStorage("showExample", store: AppGroup.defaults) private var showExample = true
    @Environment(PremiumViewModel.self) private var premium

    /// The doodle theme's hand, for the display face. `.face()` hands back the
    /// editorial serif untouched when the handwriting switch is off.
    @Environment(\.doodle) private var doodle
    var body: some View {
        if card {
            cardPage
        } else if embedded {
            page
        } else {
            // A screen of its own, opened as a sheet from a list or pushed from a related
            // word: its own ground, and its buttons in a bare header (no app name).
            page
                .paneBackground(Theme.of(scheme, doodle))
                // No bookmark on a locked word: a bookmark keeps the whole entry, and
                // Bookmarks is free — it would hand the meaning over.
                // Opened as a sheet (`close` set): no Back. A swipe closes it on a phone and
                // Esc on the Mac. Pushed from a related word: Back, to return to the first.
                .paneHeader(back: true, bare: true, onBack: close, backless: close != nil) {
                    if !locked { WordActions(word: word) }
                }
                .background {
                    if let close {
                        Button("Close", action: close)
                            .keyboardShortcut(.cancelAction)
                            .opacity(0)
                            .accessibilityHidden(true)
                    }
                }
                .environment(\.paneGlow, false)
        }
    }

    /// The word itself: photo, headword, meaning, definition, example, and — unless
    /// this is a feed card — the same-vein box. Shared by the scrolling page and the
    /// phone feed's fixed card, so there is one editorial layout and not two that
    /// drift apart.
    @ViewBuilder
    private func entry(_ t: Theme, related: [Word]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            //if showDate { dateLine(t) }

            // A sound book's entry leads with the few seconds of animal the sound came
            // with: the posture behind a bark, the stretch before a trill. Silent and
            // looping — the `sound` recording is still the entry, played on demand.
            if !hero, let clip = word.clip, !locked {
                ClipLoop(clip: clip, playing: visible)
                    .frame(maxWidth: isPhone ? .infinity : 480)
                    .frame(height: isPhone ? (card ? 200 : 260) : 320)
                    .clipShape(RoundedRectangle(cornerRadius: t.radius(10)))
                    .padding(.bottom, 26)
            // A picture book's entry leads with its photo. Fit, never fill:
            // a crop would behead the giraffe and lose the lighthouse's lamp.
            } else if !hero, let photo = word.image.flatMap(Self.photo), !locked {
                photo
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: t.radius(10)))
                    .frame(maxWidth: isPhone ? .infinity : 480, maxHeight: isPhone ? (card ? 200 : 260) : 320,
                           alignment: .leading)
                    .padding(.bottom, 26)
                    .accessibilityLabel("Photo of \(word.term)")
            }

            // The Mac's book rides over the word; a phone's is a header button.
            if hero && !isPhone {
                let book = Wordbook.named(shelfID)
                HStack(spacing: 6) {
                    BookChip(book: book, height: 18)
                    Text(book.shortName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(t.ink)
                }
                .padding(.bottom, 12)
            }

            HStack(alignment: .lastTextBaseline, spacing: isPhone ? 10 : 16) {
                Text(word.term)
                    .font(doodle.face(isPhone ? 46 : 64))
                    .tracking(doodle.tracking(isPhone ? 46 : 64))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                // A sound book's entry IS the sound: the recording sits right
                // beside its name. Pronounce, up in the header, still says the word.
                if let sound = word.sound, !locked {
                    Button {
                        speaker.stopSpeaking(at: .immediate)
                        clip?.stop()   // a second click restarts, never layers
                        clip = Bundle.main.url(forResource: sound, withExtension: "m4a")
                            .flatMap { try? AVAudioPlayer(contentsOf: $0) }
                        clip?.play()
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(t.background)
                            .offset(x: 2)   // a triangle's weight sits left of its box
                            .frame(width: 46, height: 46)
                            .background(t.accent, in: Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    // Bottom on the headword's baseline, so it stands as tall as its
                    // ascenders. Left alone, the glyph's own baseline would sink it.
                    .alignmentGuide(.lastTextBaseline) { $0[.bottom] }
                    .help("Play the \(word.term)")
                    .accessibilityLabel("Play the sound: \(word.term)")
                }
                Text(word.partOfSpeech)
                    .font(doodle.face(16).italic())
                    .foregroundStyle(t.muted)
            }

            if locked {
                // A locked shelf's word: the headword is the teaser, the rest is Premium's.
                PremiumBar(book: .named(shelfID))
                    .padding(.top, 26)
            } else {
                if showHindi, !word.hindi.isEmpty {
                    if hero {
                        // A peer of the definition, not a footnote under a rule.
                        Text(word.hindi)
                            .font(.system(size: isPhone ? 17 : 19))
                            .foregroundStyle(t.ink.opacity(0.92))
                            .lineLimit(card ? 2 : nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 18)
                    } else {
                        Text(word.hindi)
                            .font(.system(size: isPhone ? 20 : 25))
                            .foregroundStyle(t.ink.opacity(0.5))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 18)
                            .overlay(alignment: .leading) {
                                Rectangle().fill(t.rule).frame(width: 2)
                            }
                            .padding(.top, 26)
                    }
                }

                Text(word.definition)
                    .font(doodle.face(hero ? (isPhone ? 17 : 18) : (isPhone ? 19 : 22)))
                    .foregroundStyle(t.definition)
                    .lineLimit(card ? (hero ? 3 : 6) : nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, hero ? 12 : 26)

                if showExample { footer(t) }

                if hero { heroActions(t) }

                // No fade on the box: inserted with one while the launch build
                // ran, it stuck at zero opacity — the box missing until the word
                // changed. A pop is the price.
                if !card {
                    relatedBox(related, t)
                        .id("vein")
                }
            }
        }
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        // A desk page has margins; a phone has a gutter.
        .padding(.horizontal, isPhone ? 20 : 56)
        .padding(.vertical, isPhone ? 20 : 44)
        // The word lands on the hero's fade, a little above its foot.
        .padding(.top, hero ? Self.heroHeight - (isPhone ? 148 : 154) : 0)
        .background(alignment: .top) {
            if hero {
                HomeHero(word: word, book: .named(shelfID), locked: locked, visible: visible, t: t)
                    .frame(height: Self.heroHeight)
            }
        }
    }

    /// How tall Home's picture runs from the very top of the screen.
    private static var heroHeight: CGFloat { isPhone ? 480 : 400 }

    /// Hear it, at thumb height, and — on the phone feed — the way to the rest of the entry.
    private func heroActions(_ t: Theme) -> some View {
        HStack(spacing: 12) {
            Button { pronounce(word) } label: {
                Label("Hear it", systemImage: "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(t.accent)
                    .padding(.horizontal, 16)
                    .frame(height: isPhone ? 40 : 32)
                    .background(t.accent.opacity(0.16), in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .help("Pronounce \(word.term)")
            Spacer(minLength: 12)
            if let onFullEntry {
                Button(action: onFullEntry) {
                    HStack(spacing: 6) {
                        Text("Full entry")
                        Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.muted)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Full entry for \(word.term)")
            }
        }
        .padding(.top, 22)
    }

    /// One word, scrolling: the full entry with its same-vein box. Every route but
    /// the phone feed shows this one.
    private var page: some View {
        let t = Theme.of(scheme, doodle)
        let related = store.related(to: word, in: shelfID)
        return ScrollViewReader { proxy in
            ScrollView {
                // ponytail: ZStack, so the outgoing word overlaps the incoming one.
                // In the ScrollView's own stack the fading copy keeps its slot and
                // shunts the new word down the page on its way out.
                ZStack(alignment: .topLeading) {
                    entry(t, related: related)
                        // A day step swaps the word out from under a view that never
                        // moves; keyed on the term it cross-dissolves instead of cutting.
                        .id(word.term)
                        .transition(.opacity)
                }
                .onChange(of: word.term) { showRelated = false }
            }
            .animation(.easeInOut(duration: 0.22), value: word.term)
            .scrollContentBackground(.hidden)
            // Home's picture starts at the window's top edge, under the clear header.
            .ignoresSafeArea(.container, edges: hero ? .top : [])
            // Re-fires on dictionary change and on every pop back; load is idempotent.
            // Keyed on the lock too, so buying while you look loads the neighbours then.
            .task(id: locked ? nil : shelfID) { if !locked { store.load(shelfID) } }
            // Every full-view route ends at THIS view — today's word, a peek, a search
            // result, a related word — so one call here marks them all learned rather
            // than each caller having to remember. `initial: true` catches the first
            // render; the term catches HomeView swapping the word underneath us.
            .onChange(of: word.term, initial: true) {
                // A teaser isn't a word read.
                guard !locked else { return }
                LearnedWords.record(word, in: learnedIn)
            }
            // Opening the box is asking to read it: bring its bottom into view,
            // or on a phone the list unfolds below the fold and nothing seems to happen.
            .onChange(of: showRelated) {
                if showRelated { withAnimation { proxy.scrollTo("vein", anchor: .bottom) } }
            }
        }
    }


    /// One screen of the phone feed. Nothing here scrolls, on purpose: a scroll view
    /// inside the feed's paging scroll view eats the drag, and the page stops tracking
    /// the finger — which is the whole point of the feed. It also records nothing,
    /// since a lazy stack builds a card a page before you reach it: Home logs the word
    /// that is actually showing.
    private var cardPage: some View {
        entry(Theme.of(scheme, doodle), related: [])
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: hero ? .top : .center)
            .clipped()
    }

//    private func dateLine(_ t: Theme) -> some View {
//        let date = Date.now.formatted(.dateTime.month(.wide).day())
//        let text = dictionaryName.map { "\($0) · Word for \(date)" } ?? "Word for \(date)"
//        return HStack(spacing: 12) {
//            Text(text)
//                .font(.system(size: 11, weight: .semibold))
//                .textCase(.uppercase)
//                .tracking(2)
//                .foregroundStyle(t.accent)
//        }
//        .padding(.bottom, 14)
//    }

    /// "In the same vein · Synonyms": the ranking returns relatedness, so the
    /// vein half leads and "Synonyms" rides along as the plainer word for it.
    /// Collapsed by default: the page is one word, the box is a detour the reader
    /// opts into. ponytail: DisclosureGroup, not a hand-rolled toggle + chevron.
    @ViewBuilder
    private func relatedBox(_ words: [Word], _ t: Theme) -> some View {
        if !words.isEmpty {
            DisclosureGroup(isExpanded: $showRelated) {
                if relatedAsGraph {
                    // Two rings of the honeycomb: the six nearest, then the next twelve.
                    BubbleField(word: word, neighbours: store.related(to: word, in: shelfID, limit: 18), t: t)
                        .padding(.top, 18)
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(words) { w in
                            NavigationLink {
                                // The pushed screen reads the same environment store,
                                // so it renders its own box — that is the chain.
                                WordDetail(word: w, shelf: shelf)
                            } label: {
                                relatedRow(w, t)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(w.spokenSummary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 18)
                }
            } label: {
                HStack(spacing: 12) {
                    Text("In the same vein \u{00B7} Synonyms")
                        .font(.system(size: 10, weight: .bold))
                        .textCase(.uppercase).tracking(1.6)
                        .foregroundStyle(t.muted)
                        // The chevron toggles itself; the label is inert until asked.
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation { showRelated.toggle() } }
                    Spacer(minLength: 0)
                    if !isPhone { viewToggle(t) }
                }
            }
            .tint(t.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .entryBlock(t) { withAnimation { showRelated.toggle() } }
        } else if store.isBuilding(shelfID) {
            buildingBox(t)
        }
    }

    /// List on the left, graph on the right. Two plain buttons rather than a segmented
    /// Picker, so the toggle takes the theme's ink and radius like the header's buttons.
    private func viewToggle(_ t: Theme) -> some View {
        HStack(spacing: 2) {
            toggleSide("list.bullet", "List", graph: false, t)
            toggleSide("point.3.connected.trianglepath.dotted", "Graph", graph: true, t)
        }
        .padding(2)
        .background(t.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: t.radius(7)))
    }

    private func toggleSide(_ symbol: String, _ name: String, graph: Bool, _ t: Theme) -> some View {
        let on = relatedAsGraph == graph
        return Button {
            relatedAsGraph = graph
            // Picking a view is asking to see it.
            withAnimation { showRelated = true }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(on ? t.ink : t.muted)
                .frame(width: 26, height: 20)
                .background(on ? t.ink.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: t.radius(5)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Show as a \(name.lowercased())")
        .accessibilityLabel(name)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    /// The box's heading with the wait beside it, held on the same rule and the
    /// same spacing, so when the index lands the heading doesn't move — the spinner
    /// is simply replaced by the disclosure arrow. Roughly 2.4s at 12,000 words,
    /// and it fades out to nothing when the book has no neighbours to offer.
    private func buildingBox(_ t: Theme) -> some View {
        HStack(spacing: 12) {
            Text("In the same vein \u{00B7} Synonyms")
                .font(.system(size: 10, weight: .bold))
                .textCase(.uppercase).tracking(1.6)
                .foregroundStyle(t.muted)
            ProgressView().controlSize(.small)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .entryBlock(t)
        .accessibilityLabel("Looking for related words")
    }

    private func relatedRow(_ w: Word, _ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(w.term)
                    .font(doodle.face(20))
                    .foregroundStyle(t.ink)
                    // 46% of Corporate Slang terms are phrases (up to 30 chars);
                    // without this they wrap and strand the part of speech.
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if !w.partOfSpeech.isEmpty {
                    Text(w.partOfSpeech)
                        .font(.system(size: 11).italic())
                        .foregroundStyle(t.muted)
                }
            }
            // A capture that resolved in no dictionary is stored with an empty
            // definition (SavedWords.swift:74) and still gets indexed, so My Words
            // can surface one — an unguarded Text renders a blank line for it.
            if !w.definition.isEmpty {
                Text(w.definition)
                    .font(.system(size: 13))
                    .foregroundStyle(t.definition)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .contentShape(Rectangle())
    }

    /// The book this word belongs to: the one the caller named, or the selected
    /// one when it didn't say. Everything book-shaped on this page reads it — the
    /// "same vein" box included, so a word opened from Medicine while Everyday
    /// English is selected draws its neighbours from Medicine.
    private var shelfID: String { shelf ?? dictionaryID }

    /// A word from a shelf Premium hasn't opened — reached from search, or a Learned row.
    private var locked: Bool { !premium.allows(shelfID) }

    /// A bundled photo, `OneWord/Pictures/<name>.jpg`. `named:` caches the decode, so
    /// a cover-flow swipe re-rendering three pages a frame doesn't decode them again.
    fileprivate static func photo(_ name: String) -> Image? {
        #if os(macOS)
        NSImage(named: "\(name).jpg").map(Image.init(nsImage:))
        #else
        UIImage(named: "\(name).jpg").map(Image.init(uiImage:))
        #endif
    }

    /// The shelf this word counts towards. A just-captured word belongs to
    /// Bookmarks wherever you happen to be reading it.
    private var learnedIn: String {
        if SavedWords.pinned?.term == word.term { return SavedWords.resource }
        return shelfID
    }


    @ViewBuilder
    private func footer(_ t: Theme) -> some View {
        if !word.example.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Used as")
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase).tracking(1.6)
                    .foregroundStyle(t.muted)
                Text("\u{201C}\(word.example)\u{201D}")
                    .font(doodle.face(isPhone ? 17 : 20).italic())
                    .foregroundStyle(t.example)
                    .lineLimit(card ? 3 : nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .entryBlock(t)
        } else {
            Label("No example on file", systemImage: "book.closed")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(t.muted)
                .padding(.top, 40)
        }
    }
}

/// A word's own buttons — keep it, hear it — for whichever header shows the word:
/// its own when pushed, Home's or History's when they host it. The bookmark state
/// lives here, beside the one button that changes it.
struct WordActions: View {
    let word: Word
    /// Off on Home, where Hear it sits on the page under the word.
    var speaks = true
    @State private var bookmarked = false
    @State private var stretch: CGFloat = 1

    var body: some View {
        HStack(spacing: 6) {
            // Learned is everything you've read; this is the shelf you curate.
            Button {
                bookmarked = SavedWords.toggle(word)
                // A ribbon being pulled: it lengthens downward, then settles.
                withAnimation(.easeOut(duration: 0.25)) { stretch = 1.22 }
                withAnimation(.easeInOut(duration: 0.35).delay(0.25)) { stretch = 1 }
            } label: {
                // The ribbon stays for as long as it's bookmarked — the glyph is
                // the state, so it lands only once the stretch has settled.
                BookmarkRibbon(filled: bookmarked)
                    .accessibilityLabel(bookmarked ? "Remove Bookmark" : "Bookmark")
                    .animation(.easeInOut(duration: 0.3).delay(0.55), value: bookmarked)
                    // anchor: .top — the top edge is pinned, all the growth is
                    // downward. Applied outside the .animation above so it runs
                    // on the button's own transaction, not the delayed one.
                    .scaleEffect(y: stretch, anchor: .top)
            }
            .disabled(word.term == SavedWords.placeholder.term)
            .help(bookmarked ? "Remove \(word.term) from Bookmarks"
                             : "Bookmark \(word.term)")

            if speaks {
                Button { pronounce(word) } label: {
                    Label("Pronounce", systemImage: "speaker.wave.2")
                }
                .help("Pronounce \(word.term)")
            }
        }
        .onChange(of: word.term, initial: true) { bookmarked = SavedWords.contains(word) }
        // The Bookmarks pane can un-bookmark the word under us, and a Services
        // catch bookmarks one — either way the ribbon has to agree with the store.
        .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
            bookmarked = SavedWords.contains(word)
        }
    }
}

/// Home's full-bleed top: the word's clip or photo; until a book's media is shot, a
/// placeholder in its own cloth; and for Everyday English, which has none, the band.
/// Two fades make it a ground: the strip's title reads at the top, the word at the foot.
private struct HomeHero: View {
    let word: Word
    let book: Wordbook
    let locked: Bool
    let visible: Bool
    let t: Theme

    var body: some View {
        ZStack {
            // Color.clear takes the size it's given; fill art overflows it and gets clipped.
            Color.clear.overlay { art }.clipped()
            LinearGradient(colors: [t.background.opacity(0.6), t.background.opacity(0)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 160)
                .frame(maxHeight: .infinity, alignment: .top)
            LinearGradient(stops: [.init(color: t.background.opacity(0), location: 0.45),
                                   .init(color: t.background.opacity(0.75), location: 0.72),
                                   .init(color: t.background, location: 1)],
                           startPoint: .top, endPoint: .bottom)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)   // the entry under it says what it shows
    }

    @ViewBuilder
    private var art: some View {
        // A locked word keeps its media for Premium, as the entry keeps its meaning.
        if !locked, let clip = word.clip {
            ClipLoop(clip: clip, playing: visible).background(book.coverColor)
        } else if !locked, let photo = word.image.flatMap(WordDetail.photo) {
            photo.resizable().scaledToFill()
        } else if book == .everydayEnglish {
            LinearGradient(colors: [t.glow == .clear ? t.ink.opacity(0.05) : t.glow, t.background.opacity(0)],
                           startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .trailing) {
                    Text("Aa")
                        .font(.system(size: isPhone ? 230 : 260, weight: .semibold))
                        .tracking(-12)
                        .foregroundStyle(t.accent.opacity(0.1))
                        .offset(x: 24)
                }
        } else {
            // ponytail: placeholder until each book's pictures and clips are shot.
            book.coverColor.overlay {
                Image(systemName: book.symbol)
                    .font(.system(size: isPhone ? 110 : 130, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.14))
            }
        }
    }
}

private extension View {
    /// How a section sits under the definition: below a hairline in Light and Dark,
    /// or in a frosted tile of its own in Midnight. One place, so "Used as", the
    /// same-vein box and its loading line can never disagree about the shape.
    /// `onTap` makes the whole tile a target, padding included — without it only
    /// what's drawn inside answers. Controls inside still win their own clicks.
    @ViewBuilder
    func entryBlock(_ t: Theme, onTap: (() -> Void)? = nil) -> some View {
        if t.tiles {
            self
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
                .background(t.surface, in: RoundedRectangle(cornerRadius: t.radius(10)))
                .contentShape(RoundedRectangle(cornerRadius: t.radius(10)))
                .onTapGesture { onTap?() }
                .padding(.top, 28)
        } else {
            self
                .padding(.top, 24)
                .overlay(alignment: .top) { Rectangle().fill(t.hairline).frame(height: 1) }
                .padding(.top, 34)
        }
    }
}

/// The bookmark state as one glyph: the ribbon asset when kept — it carries its
/// own colour, so nothing here tints it — and the outline symbol when not.
/// Shared by the toggle above, the Bookmarks pane's count and the Profile stat.
struct BookmarkRibbon: View {
    var filled = true
    /// Height, not a box. A ribbon is taller than it is wide (the asset's viewBox is
    /// cropped to the artwork, so it fills what it's given); the width follows.
    var size: CGFloat = 17

    var body: some View {
        Group {
            if filled {
                // The asset is a ribbon centred in a square canvas with a wide
                // transparent margin, so fitting the canvas to a box shrinks the
                // ribbon inside it. Draw the whole canvas oversized instead, and let
                // the frame below take the ribbon's share of it (26×38 of 48×48).
                Image("bookmark_icon").resizable().scaledToFit()
                    .frame(width: size * 1.26, height: size * 1.26)
            } else {
                Image(systemName: "bookmark").resizable().scaledToFit()
                    .foregroundStyle(Color.primary)
            }
        }
        .frame(width: size * 0.7, height: size)
    }
}
