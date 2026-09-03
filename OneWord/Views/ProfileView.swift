//
//  ProfileView.swift
//  OneWord
//
//  How many words you've met, shelf by shelf. A word counts once you've read it
//  in full — today's word, a peek, a search result, a related word — which is
//  exactly what LearnedWords records from WordDetail.
//
//  Dumb view: the counting and the JSON decode live in ProfileViewModel.
//

import SwiftUI
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct ProfileView: View {
    @Environment(\.colorScheme) private var scheme

    @State private var model = ProfileViewModel()

    var body: some View {
        let t = Theme.of(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                headline(t)
                VStack(alignment: .leading, spacing: 10) {
                    Text("By dictionary")
                        .font(.headline).foregroundStyle(t.muted)
                    VStack(spacing: 16) {
                        ForEach(Wordbook.all) { book in
                            row(book, t)
                        }
                    }
                }
            }
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(t.background)
        .navigationTitle("Profile")
        .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
            model.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: LearnedWords.didChange)) { _ in
            model.refresh()
        }
        .task {
            model.refresh()
            await model.loadSizes()
        }
    }

    /// The two numbers side by side: what reading racked up, and what you chose
    /// to keep. They answer different questions, so neither subsumes the other.
    private func headline(_ t: Theme) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 40) {
            stat(model.total, model.total == 1 ? "word learned" : "words learned", t)
            stat(model.bookmarks, model.bookmarks == 1 ? "bookmark" : "bookmarks", t)
        }
    }

    private func stat(_ value: Int, _ caption: String, _ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.serif(64))
                .foregroundStyle(t.ink)
                .contentTransition(.numericText())
            Text(caption)
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase).tracking(2)
                .foregroundStyle(t.muted)
        }
        .accessibilityElement(children: .combine)
    }

    private func row(_ book: Wordbook, _ t: Theme) -> some View {
        let (seen, size) = model.progress(for: book)
        return HStack(spacing: 14) {
            // A chip of the shelf's cover, so a row is recognisable at a glance.
            Image(systemName: book.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(book.coverColor, in: RoundedRectangle(cornerRadius: 7))
                .opacity(seen == 0 ? 0.45 : 1)

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(book.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(seen == 0 ? t.muted : t.ink)
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    // Sizes land a beat after the counts — show the bare number
                    // until they do rather than a placeholder "of 0".
                    Text(size > 0 ? "\(seen) of \(size)" : "\(seen)")
                        .font(.system(size: 12).monospacedDigit())
                        .foregroundStyle(t.muted)
                }
                ProgressView(value: Double(min(seen, size)), total: Double(max(size, 1)))
                    .progressViewStyle(.linear)
                    .tint(book.coverColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(size > 0
            ? "\(book.name): \(seen) of \(size) words learned"
            : "\(book.name): \(seen) words learned")
    }
}

#Preview {
    ProfileView()
}
