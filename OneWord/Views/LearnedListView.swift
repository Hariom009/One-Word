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
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
        Group {
            if days.isEmpty {
                emptyState(t)
            } else {
                List(lines) { line in
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
                            row(entry, t)
                        }
                        .listRowBackground(t.background)
                        .listRowSeparatorTint(t.hairline)
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
        .onAppear { log = LearnedWords.log }
        // Reading a word pushed off this very list adds to it, so it has to catch
        // up on the way back — .onAppear doesn't re-run on a pop.
        .onReceive(NotificationCenter.default.publisher(for: LearnedWords.didChange)) { _ in
            log = LearnedWords.log
        }
    }

    private var results: [LearnedWord] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return log }
        return log.filter { $0.word.term.localizedCaseInsensitiveContains(q) }
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

    /// The log flattened to rows: each day's label, then that day's sightings.
    private var lines: [Line] {
        days.flatMap { [Line.day($0.day)] + $0.words.map(Line.word) }
    }

    /// Sightings bucketed by the day they happened, newest day first. `log` is
    /// already sorted, and `Dictionary(grouping:)` preserves that within a bucket.
    private var days: [(day: Date, words: [LearnedWord])] {
        Dictionary(grouping: results) { Calendar.current.startOfDay(for: $0.seenAt) }
            .map { (day: $0.key, words: $0.value) }
            .sorted { $0.day > $1.day }
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

    private func row(_ entry: LearnedWord, _ t: Theme) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.gutter) {
            Text(entry.word.term)
                .font(.serif(20))
                .foregroundStyle(t.ink)
                .lineLimit(1)
                .frame(width: Self.termWidth, alignment: .leading)
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
            Spacer(minLength: 0)
        }
        .padding(.vertical, 7)
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
            Image(systemName: query.isEmpty ? "checkmark.seal" : "hexagon")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(t.accent.opacity(0.5))
            Text(query.isEmpty ? "Nothing read yet" : "No words match")
                .font(.serif(30)).foregroundStyle(t.ink)
            Text(query.isEmpty
                 ? "Every word you read in full lands here \u{2014} today's word, a peek, a search result, a related word \u{2014} with the day and time you met it."
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
