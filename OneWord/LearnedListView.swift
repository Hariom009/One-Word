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
    /// Width of the trailing "when · where" column. Fixed so it reads as a column
    /// instead of a ragged edge that moves with every shelf name's length.
    private static let metaWidth: CGFloat = 168

    @State private var log: [LearnedWord] = []
    @State private var query = ""
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
        Group {
            if days.isEmpty {
                emptyState(t)
            } else {
                List {
                    ForEach(days, id: \.day) { group in
                        Section {
                            ForEach(group.words) { entry in
                                NavigationLink {
                                    // The shelf travels with the entry, so re-opening
                                    // a word from the log doesn't log it again under
                                    // whatever dictionary happens to be selected.
                                    WordDetail(word: entry.word, shelf: entry.shelf)
                                } label: {
                                    row(entry, t)
                                }
                                .listRowBackground(t.background)
                                .listRowSeparatorTint(t.hairline)
                            }
                        } header: {
                            header(group.day, t)
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

    /// Sightings bucketed by the day they happened, newest day first. `log` is
    /// already sorted, and `Dictionary(grouping:)` preserves that within a bucket.
    private var days: [(day: Date, words: [LearnedWord])] {
        Dictionary(grouping: results) { Calendar.current.startOfDay(for: $0.seenAt) }
            .map { (day: $0.key, words: $0.value) }
            .sorted { $0.day > $1.day }
    }

    /// Two-part day header: a short label on the left, the date on the right over
    /// the meta column. The date used to ride inside the label, which made every
    /// section a full line of tracked capitals.
    private func header(_ day: Date, _ t: Theme) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label(for: day))
                .font(.system(size: 10, weight: .bold))
                .textCase(.uppercase).tracking(1.6)
                .foregroundStyle(t.muted)
            Spacer(minLength: 12)
            if day >= LearnedWord.epoch {
                Text(day.formatted(.dateTime.day().month(.wide).year()))
                    .font(.system(size: 10))
                    .foregroundStyle(t.muted.opacity(0.75))
                    .lineLimit(1)
                    .frame(width: Self.metaWidth, alignment: .leading)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 2)
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
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(entry.word.term)
                .font(.serif(20))
                .foregroundStyle(t.ink)
                .lineLimit(1)
            Text(entry.word.partOfSpeech)
                .font(.system(size: 11).italic())
                .foregroundStyle(t.muted)
                .lineLimit(1)
            Spacer(minLength: 12)
            // One line, always — a two-line stack here gave timestamped and
            // migrated rows different heights, which is what made the log look ragged.
            Text(meta(of: entry))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(t.muted)
                .lineLimit(1)
                .frame(width: Self.metaWidth, alignment: .leading)
        }
        .padding(.vertical, 6)
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
