//
//  LearnedListView.swift
//  OneWord
//
//  The Learned pane: a log of every word you've read, newest first, in sections
//  by day. Not WordListView — that browses a dictionary alphabetically, which is
//  the opposite of what a log wants.
//

import SwiftUI
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct LearnedListView: View {
    // Fixed columns, packed against the leading edge. A Spacer between the word
    // and its "when · where" looked fine in a small window and fell apart in a
    // wide one — the two halves of a row drift a thousand points apart.
    private static let termWidth: CGFloat = 240
    private static let posWidth: CGFloat = 96
    private static let gutter: CGFloat = 64

    @State private var log: [LearnedWord] = []
    @State private var query = ""
    @State private var hovered: Int?
    // Cached, not computed. Hovering re-runs `body` on every pointer move, and
    // re-grouping the whole log each time is what made the magnification stutter.
    @State private var lines: [Line] = []
    @Environment(\.colorScheme) private var scheme

    /// The doodle theme's hand, for the display face. `.face()` hands back the
    /// editorial serif untouched when the handwriting switch is off.
    @Environment(\.doodle) private var doodle
    var body: some View {
        let t = Theme.of(scheme, doodle)
        Group {
            if lines.isEmpty {
                emptyState(t)
            } else {
                List {
                    ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                        switch line {
                        case .day(let day):
                            header(day, t)
                                .listRowBackground(t.background)
                                .listRowSeparator(.hidden)
                        case .word(let entry):
                            NavigationLink {
                                // The shelf travels with the entry, so re-opening a word
                                // from the log doesn't log it again under whatever
                                // dictionary happens to be selected.
                                WordDetail(word: entry.word, shelf: entry.shelf)
                            } label: {
                                row(entry, t, magnification(index))
                            }
                            .onHover { inside in
                                // A fast pointer can deliver the exit after the next
                                // row's enter; only clear if we're still the hovered one.
                                hovered = inside ? index : (hovered == index ? nil : hovered)
                            }
                            .listRowBackground(t.background)
                            .listRowSeparatorTint(t.hairline)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .tint(t.accent)
            }
        }
        .background(t.background)
        .navigationTitle("Learned")
        // ponytail: the native search field, not a hand-rolled top bar.
        .searchable(text: $query, prompt: "Search \(log.count) words")
        .onAppear { log = LearnedWords.log; rebuild() }
        // Reading a word pushed off this very list adds to it, so it has to catch
        // up on the way back — .onAppear doesn't re-run on a pop.
        .onReceive(NotificationCenter.default.publisher(for: LearnedWords.didChange)) { _ in
            log = LearnedWords.log
            rebuild()
        }
        .onChange(of: query) { _, _ in rebuild() }
    }

    /// Only the row under the pointer swells. The neighbours used to swell too and
    /// everything past them shrank, Dock-style — which meant one pointer move
    /// resized every word on screen at once, and read as a glitch rather than a
    /// focus.
    private func magnification(_ index: Int) -> CGFloat {
        index == hovered ? 1.85 : 1
    }

    /// One line of the list. A `Section` header pins itself to the top of a plain
    /// List, which leaves a half-clipped row wedged underneath it — so the days
    /// ride as ordinary rows and scroll away like everything else.
    private enum Line: Identifiable {
        case day(Date)
        case word(LearnedWord)

        var id: String {
            switch self {
            case .day(let day): "\u{0}day\(day.timeIntervalSinceReferenceDate)"
            case .word(let entry): entry.id
            }
        }
    }

    /// The log, filtered and flattened to rows: each day's label, then that day's
    /// sightings, newest day first. `log` is already sorted and
    /// `Dictionary(grouping:)` preserves that within a bucket.
    private func rebuild() {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let results = q.isEmpty ? log : log.filter { $0.word.term.localizedCaseInsensitiveContains(q) }
        lines = Dictionary(grouping: results) { Calendar.current.startOfDay(for: $0.seenAt) }
            .map { (day: $0.key, words: $0.value) }
            .sorted { $0.day > $1.day }
            .flatMap { [Line.day($0.day)] + $0.words.map(Line.word) }
        hovered = nil   // the rows just moved out from under the pointer
    }

    /// Two-part day header on the same columns as the rows: the short label over
    /// the words, the date over the part of speech. The date used to ride inside
    /// the label, which made every section a full line of tracked capitals.
    private func header(_ day: Date, _ t: Theme) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.gutter) {
            Text(label(for: day))
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase).tracking(1.6)
                .foregroundStyle(t.ink.opacity(0.8))
                .frame(width: Self.termWidth, alignment: .leading)
            if day >= LearnedWord.epoch {
                Text(day.formatted(.dateTime.day().month(.wide).year()))
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 22)
        .padding(.bottom, 6)
        .padding(.horizontal, 12)
    }

    /// What the day is called. "Today"/"Yesterday" when they apply, otherwise the
    /// weekday — the full date sits beside it in the header, not inside the label.
    private func label(for day: Date) -> String {
        guard day >= LearnedWord.epoch else { return "Earlier" }
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide))
    }

    private func row(_ entry: LearnedWord, _ t: Theme, _ scale: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.gutter) {
            Text(entry.word.term)
                .font(doodle.face(20))
                .foregroundStyle(t.ink)
                .lineLimit(1)
                // Scale only, never layout: a `List` re-lays-out on any height
                // change and jumps rather than tweens, and the moving rows then
                // fire fresh hover events at the pointer. The vertical padding
                // below leaves room for the biggest step, so nothing collides.
                .scaleEffect(scale, anchor: .leading)
                .animation(.easeOut(duration: 0.14), value: scale)
                .frame(width: Self.termWidth, alignment: .leading)
            // Out of the way while the word is at full size: a long term (the
            // idioms run to thirty characters) overruns its column at 1.85x and
            // would otherwise land on top of these.
            Group {
                Text(entry.word.partOfSpeech)
                    .font(.system(size: 11).italic())
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
                    .frame(width: Self.posWidth, alignment: .leading)
                // One line, always — a two-line stack here gave timestamped and
                // migrated rows different heights, which is what made the log look ragged.
                Text(meta(of: entry))
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
            }
            .opacity(scale > 1.3 ? 0 : 1)
            .animation(.easeOut(duration: 0.14), value: scale)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(summary(of: entry))
    }

    /// When it was read and out of which shelf. The time is blank for a migrated
    /// sighting, which only ever knew the day it landed in ("Earlier").
    private func meta(of entry: LearnedWord) -> String {
        let shelf = Wordbook.named(entry.shelf).shortName
        guard entry.isTimestamped else { return shelf }
        return "\(entry.seenAt.formatted(date: .omitted, time: .shortened)) \u{00B7} \(shelf)"
    }

    /// One VoiceOver utterance per row — the row's columns read as gibberish split up.
    private func summary(of entry: LearnedWord) -> String {
        var parts = [entry.word.term]
        if !entry.word.partOfSpeech.isEmpty { parts.append(entry.word.partOfSpeech) }
        parts.append(Wordbook.named(entry.shelf).name)
        parts.append(entry.isTimestamped
            ? "Read \(entry.seenAt.formatted(date: .complete, time: .shortened))"
            : "Read earlier")
        return parts.joined(separator: ". ")
    }

    private func emptyState(_ t: Theme) -> some View {
        VStack(spacing: 14) {
            Group {
                if query.isEmpty {
                    GlyphIcon(.learned, size: 52, weight: .thin)
                } else {
                    // No drawing for "nothing matched" in either set.
                    Image(systemName: "hexagon").font(.system(size: 52, weight: .thin))
                }
            }
            .foregroundStyle(t.accent.opacity(0.5))
            Text(query.isEmpty ? "Nothing read yet" : "No words match")
                .font(doodle.face(30)).tracking(doodle.tracking(30)).foregroundStyle(t.ink)
            Text(query.isEmpty
                 ? "Every word you read in full lands here — today's word, a peek, a search result, a related word — with the day and time you met it."
                 : "Nothing in your log matches \u{201C}\(query)\u{201D}.")
                .font(.system(size: 13))
                .foregroundStyle(t.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    NavigationStack { LearnedListView() }
        .environment(RelatedWordsStore())
}
