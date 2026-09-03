//
//  WordDetail.swift
//  OneWord
//
//  One word, editorial layout: optional date line, serif headword + italic part
//  of speech, a Devanagari meaning with an accent rule, the definition, and a
//  "Used as" example footer. Shared by WordView (today, showDate) and the list detail.
//

import SwiftUI
import AVFoundation
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

// ponytail: one shared synth — a local would deallocate mid-utterance.
@MainActor private let speaker = AVSpeechSynthesizer()

struct WordDetail: View {
    let word: Word
    var showDate: Bool = false
    var dictionaryName: String? = nil
    /// The shelf this word came from, when the caller knows it. Without it a word
    /// re-opened from a list gets logged against whatever dictionary happens to be
    /// selected, which reads as a second sighting that never happened.
    var shelf: String? = nil
    @Environment(\.colorScheme) private var scheme
    @Environment(RelatedWordsStore.self) private var store
    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    @State private var showRelated = false
    @State private var bookmarked = false
    @State private var stretch: CGFloat = 1
    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @AppStorage("showExample", store: AppGroup.defaults) private var showExample = true

    var body: some View {
        let t = Theme.of(scheme)
        let related = store.related(to: word, in: Wordbook.named(dictionaryID).id)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                //if showDate { dateLine(t) }

                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    Text(word.term)
                        .font(.serif(64))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                    Text(word.partOfSpeech)
                        .font(.serif(16).italic())
                        .foregroundStyle(t.muted)
                }

                if showHindi, !word.hindi.isEmpty {
                    Text(word.hindi)
                        .font(.system(size: 25))
                        .foregroundStyle(t.ink.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 18)
                        .overlay(alignment: .leading) {
                            Rectangle().fill(t.rule).frame(width: 2)
                        }
                        .padding(.top, 26)
                }

                Text(word.definition)
                    .font(.serif(22))
                    .foregroundStyle(t.definition)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 26)

                if showExample { footer(t) }

                relatedBox(related, t)
            }
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 56)
            .padding(.vertical, 44)
            // The box fades in when the background build lands — without this it pops.
            .animation(.default, value: related)
            .onChange(of: word.term) { showRelated = false }
        }
        .scrollContentBackground(.hidden)
        .background(t.background)
        // Re-fires on dictionary change and on every pop back; load is idempotent.
        .task(id: dictionaryID) { store.load(Wordbook.named(dictionaryID).id) }
        // Every full-view route ends at THIS view — today's word, a peek, a search
        // result, a related word — so one call here marks them all learned rather
        // than each caller having to remember. `initial: true` catches the first
        // render; the term catches WordView swapping the word underneath us.
        .onChange(of: word.term, initial: true) {
            LearnedWords.record(word, in: learnedIn)
            bookmarked = SavedWords.contains(word)
        }
        // The Bookmarks pane can un-bookmark the word under us, and a Services
        // catch bookmarks one — either way the star has to agree with the store.
        .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
            bookmarked = SavedWords.contains(word)
        }
        // in WordDetail, not WordView, so the list's detail screen gets it too
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                // Learned is everything you've read; this is the shelf you curate.
                Button {
                    bookmarked = SavedWords.toggle(word)
                    // A ribbon being pulled: it lengthens downward, then settles.
                    withAnimation(.easeOut(duration: 0.25)) { stretch = 1.22 }
                    withAnimation(.easeInOut(duration: 0.35).delay(0.25)) { stretch = 1 }
                } label: {
                    Label(bookmarked ? "Remove Bookmark" : "Bookmark",
                          systemImage: bookmarked ? "bookmark.fill" : "bookmark")
                        .contentTransition(.symbolEffect(.replace))
                        // Green stays for as long as it's bookmarked — the colour is
                        // the state, so it lands only once the stretch has settled.
                        .foregroundStyle(bookmarked ? Color.green : Color.primary)
                        .animation(.easeInOut(duration: 0.3).delay(0.55), value: bookmarked)
                        // anchor: .top — the top edge is pinned, all the growth is
                        // downward. Applied outside the .animation above so it runs
                        // on the button's own transaction, not the delayed one.
                        .scaleEffect(y: stretch, anchor: .top)
                }
                .disabled(word.term == SavedWords.placeholder.term)
                .help(bookmarked ? "Remove \(word.term) from Bookmarks"
                                 : "Bookmark \(word.term)")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    speaker.stopSpeaking(at: .immediate)   // rapid clicks replace, don't queue
                    let utterance = AVSpeechUtterance(string: word.term)
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speaker.speak(utterance)
                } label: {
                    Label("Pronounce", systemImage: "speaker.wave.2")
                }
                .help("Pronounce \(word.term)")
            }
        }
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
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(words) { w in
                        NavigationLink {
                            // The pushed screen reads the same environment store,
                            // so it renders its own box — that is the chain.
                            WordDetail(word: w)
                        } label: {
                            relatedRow(w, t)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(accessibilitySummary(of: w))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 18)
            } label: {
                Text("In the same vein \u{00B7} Synonyms")
                    .font(.system(size: 10, weight: .bold))
                    .textCase(.uppercase).tracking(1.6)
                    .foregroundStyle(t.muted)
                    // The chevron toggles itself; the label is inert until asked.
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation { showRelated.toggle() } }
            }
            .tint(t.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
            .overlay(alignment: .top) { Rectangle().fill(t.hairline).frame(height: 1) }
            .padding(.top, 34)
        }
    }

    private func relatedRow(_ w: Word, _ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text(w.term)
                    .font(.serif(20))
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

    /// The shelf this word counts towards: the one the caller came from, or the
    /// selected one when it didn't say. A just-captured word belongs to Bookmarks
    /// wherever you happen to be reading it.
    private var learnedIn: String {
        if SavedWords.pinned?.term == word.term { return SavedWords.resource }
        return shelf ?? dictionaryID
    }

    /// One VoiceOver utterance per row, covering every field the row displays.
    private func accessibilitySummary(of w: Word) -> String {
        var parts = [w.term]
        if !w.partOfSpeech.isEmpty { parts.append(w.partOfSpeech) }
        parts.append(w.definition)
        return parts.joined(separator: ". ")
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
                    .font(.serif(20).italic())
                    .foregroundStyle(t.example)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 24)
            .overlay(alignment: .top) { Rectangle().fill(t.hairline).frame(height: 1) }
            .padding(.top, 34)
        } else {
            Label("No example on file", systemImage: "book.closed")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(t.muted)
                .padding(.top, 40)
        }
    }
}
