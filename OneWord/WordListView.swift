//
//  WordListView.swift
//  OneWord
//
//  Browse/search a dictionary alphabetically. Two panes use it: Search (follows
//  the selected dictionary, with the picker in the toolbar) and Bookmarks (pinned
//  to the saved list, no picker). Editorial styling; empty state when nothing matches.
//

import SwiftUI
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct WordListView: View {
    /// Width of the trailing Hindi column. Fixed so the meanings line up instead
    /// of each starting wherever its own length happens to put it.
    private static let hindiWidth: CGFloat = 200

    /// nil = follow the selected dictionary. Set to pin the list to one book.
    var wordbook: Wordbook? = nil

    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @State private var model = WordListViewModel()
    @State private var query = ""
    @State private var searching = false
    @Environment(\.colorScheme) private var scheme

    private var book: Wordbook { wordbook ?? Wordbook.named(dictionaryID) }

    var body: some View {
        let t = Theme.of(scheme)
        let results = model.results(for: query)
        Group {
            if results.isEmpty {
                emptyState(t)
            } else {
                List(results) { word in
                    NavigationLink { WordDetail(word: word, shelf: book.id) } label: { row(word, t) }
                        .listRowBackground(t.background)
                        .listRowSeparatorTint(t.hairline)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .tint(t.accent)
            }
        }
        .background(t.background)
        .navigationTitle(book.shortName)
        // ponytail: the native search field, same as the Learned pane. The
        // hand-rolled top bar this replaces put a boxed field and a rule above
        // every list, including a Bookmarks pane holding three words.
        .searchable(text: $query, isPresented: $searching, prompt: "Search \(model.count) words")
        .toolbar {
            if wordbook == nil {
                ToolbarItem {
                    Picker("Dictionary", selection: $dictionaryID) {
                        ForEach(Wordbook.all) { book in Text(book.shortName).tag(book.id) }
                    }
                    .tint(t.accent)
                }
            }
        }
        .onAppear {
            model.select(book)
            // ⌘K from the sidebar should land in the field. Only in Search —
            // Bookmarks keeps the field collapsed to its toolbar button, which is
            // the whole point of dropping the old always-on top bar.
            if wordbook == nil { searching = true }
        }
        .onChange(of: dictionaryID) { _, _ in model.select(book) }
        // Bookmarks isn't a bundled file — a catch or a bookmark while this pane is
        // open changes it.
        .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
            if book.id == SavedWords.resource { model.reload() }
        }
    }

    private func row(_ word: Word, _ t: Theme) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(word.term)
                .font(.serif(20))
                .foregroundStyle(t.ink)
                .lineLimit(1)
            Text(word.partOfSpeech)
                .font(.system(size: 11).italic())
                .foregroundStyle(t.muted)
                .lineLimit(1)
            Spacer(minLength: 12)
            if showHindi {
                Text(word.hindi)
                    .font(.system(size: 14))
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
                    .frame(width: Self.hindiWidth, alignment: .leading)
            }
        }
        .padding(.vertical, 6)
    }

    private func emptyState(_ t: Theme) -> some View {
        VStack(spacing: 14) {
            Image(systemName: query.isEmpty ? book.symbol : "hexagon")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(t.accent.opacity(0.5))
            VStack(spacing: 2) {
                Text(query.isEmpty ? "Nothing here yet" : "No words match")
                    .font(.serif(30)).foregroundStyle(t.ink)
                if !query.isEmpty {
                    Text("\u{201C}\(query)\u{201D}")
                        .font(.serif(30).italic()).foregroundStyle(t.ink)
                }
            }
            Text(query.isEmpty
                 ? "Bookmark a word from its page, or select one in any app and choose Services \u{25B8} Save to One Word. Either way it lands here."
                 : "You're searching \(book.shortName) \u{2014} \(model.count) words.")
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
    NavigationStack { WordListView() }
        .environment(RelatedWordsStore())
}
