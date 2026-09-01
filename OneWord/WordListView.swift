//
//  WordListView.swift
//  OneWord
//
//  Browse the selected dictionary alphabetically. Top bar: search field with the
//  dictionary picker beside it. Editorial styling; empty state when nothing matches.
//

import SwiftUI

struct WordListView: View {
    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @State private var model = WordListViewModel()
    @State private var query = ""
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
        let results = model.results(for: query)
        VStack(spacing: 0) {
            topBar(t)
            Divider().overlay(t.hairline)
            if results.isEmpty {
                emptyState(t)
            } else {
                List(results) { word in
                    NavigationLink { WordDetail(word: word) } label: { row(word, t) }
                        .listRowBackground(t.background)
                        .listRowSeparatorTint(t.hairline)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .tint(t.accent)
            }
        }
        .background(t.background)
        .navigationTitle("All Words")
        .onAppear { model.select(Wordbook.named(dictionaryID)) }
        .onChange(of: dictionaryID) { _, id in model.select(Wordbook.named(id)) }
    }

    private func row(_ word: Word, _ t: Theme) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(word.term)
                .font(.serif(22))
                .foregroundStyle(t.ink)
            Text(word.partOfSpeech)
                .font(.system(size: 11).italic())
                .foregroundStyle(t.muted)
            Spacer(minLength: 12)
            if showHindi, !word.hindi.isEmpty {
                Text(word.hindi)
                    .font(.system(size: 15))
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private func topBar(_ t: Theme) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "magnifyingglass").foregroundStyle(t.accent)
                TextField("Search \(model.count) words", text: $query)
                    .textFieldStyle(.plain)
                    .foregroundStyle(t.ink)
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain)
                        .foregroundStyle(t.muted)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(t.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(t.hairline, lineWidth: 1))

            Menu {
                Picker("Dictionary", selection: $dictionaryID) {
                    ForEach(Wordbook.all) { book in Text(book.name).tag(book.id) }
                }
            } label: {
                Label(Wordbook.named(dictionaryID).name, systemImage: "books.vertical")
                    .font(.system(size: 12.5, weight: .medium))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .tint(t.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func emptyState(_ t: Theme) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "hexagon")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(t.accent.opacity(0.5))
            VStack(spacing: 2) {
                Text("No words match")
                    .font(.serif(30)).foregroundStyle(t.ink)
                Text("\u{201C}\(query)\u{201D}")
                    .font(.serif(30).italic()).foregroundStyle(t.ink)
            }
            Text("You're searching \(Wordbook.named(dictionaryID).name) — \(model.count) words.")
                .font(.system(size: 13))
                .foregroundStyle(t.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

#Preview {
    NavigationStack { WordListView() }
        .environment(RelatedWordsStore())
}
