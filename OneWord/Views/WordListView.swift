//
//  WordListView.swift
//  OneWord
//
//  A word list. Two panes use it: Search, which is dictionary-agnostic — it
//  belongs to no book, searches every one of them at once, and tags each result
//  with the book it came from — and Bookmarks, pinned to the saved list and
//  browsing itself alphabetically. Editorial styling; empty state when nothing
//  matches.
//

import SwiftUI
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct WordListView: View {
    // Fixed columns, packed against the leading edge — same grid as the Learned
    // pane. A Spacer between term and meaning drifts them to opposite ends of a
    // wide window, where they stop reading as one line.
    private static let termWidth: CGFloat = 240
    private static let posWidth: CGFloat = 96
    private static let hindiWidth: CGFloat = 420

    /// nil = the Search pane: no book of its own, every book searched. Set to pin
    /// the list to one book.
    let wordbook: Wordbook?

    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @State private var model: WordListViewModel
    @State private var query = ""
    @State private var hovered: String?
    @Environment(\.colorScheme) private var scheme

    init(wordbook: Wordbook? = nil) {
        self.wordbook = wordbook
        _model = State(initialValue: WordListViewModel(wordbook: wordbook))
    }

    /// The Search pane searches across books; a pinned pane (Bookmarks) searches
    /// itself. Nothing you pick elsewhere changes what either one can find.
    private var everywhere: Bool { wordbook == nil }

    /// The doodle theme's hand, for the display face. `.face()` hands back the
    /// editorial serif untouched when the handwriting switch is off.
    @Environment(\.doodle) private var doodle
    var body: some View {
        let t = Theme.of(scheme, doodle)
        let results = model.results(for: query)
        // Matches can come from anywhere, so each one has to say where from.
        // A pinned pane needs no tag — every row is the book in the title.
        let mark = everywhere
        Group {
            if results.isEmpty {
                emptyState(t)
            } else {
                List(results) { hit in
                    // The shelf travels with the hit: a word found in Medicine
                    // while Everyday English is open must not be logged — or
                    // opened — against Everyday English.
                    NavigationLink { WordDetail(word: hit.word, shelf: hit.shelf) } label: {
                        row(hit, t, mark: mark, scale: hit.id == hovered ? 1.85 : 1)
                    }
                        // Same swell as the Learned pane. A fast pointer can deliver
                        // the exit after the next row's enter; only clear if we're
                        // still the hovered one.
                        .onHover { inside in
                            hovered = inside ? hit.id : (hovered == hit.id ? nil : hovered)
                        }
                        // Clear, so the pane's ground — Midnight's glow included —
                        // shows through the rows instead of stopping at them.
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(t.hairline)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .tint(t.accent)
            }
        }
        .paneBackground(t)
        // The field rides in the header strip — no row of its own above the list,
        // which a Bookmarks pane holding three words never needed.
        .paneHeader(wordbook?.shortName ?? "Search") {
            // How many you've kept. Only Bookmarks — every other pane's total is
            // already in the search prompt, and it never changes while you look at it.
            if wordbook?.id == SavedWords.resource {
                HStack(spacing: 6) {
                    BookmarkRibbon(size: 18)
                    Text("\(model.count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(t.muted)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 6)
                .help("\(model.count) bookmarked words")
                .accessibilityLabel("\(model.count) bookmarked words")
            }
            // ⌘K from the sidebar should land in the field, so only Search takes
            // focus; Bookmarks waits to be clicked.
            HeaderSearchField(prompt: everywhere ? "Search every dictionary" : "Search \(model.count) words",
                              text: $query, focusOnAppear: everywhere)
        }
        // Bookmarks isn't a bundled file — a catch or a bookmark while this pane is
        // open changes it.
        .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
            if wordbook?.id == SavedWords.resource { model.reload() }
        }
    }

    private func row(_ hit: WordListViewModel.Hit, _ t: Theme, mark: Bool, scale: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 64) {
            // Size only, never layout — see SwellingTerm. The vertical padding
            // below leaves room for the biggest step.
            SwellingTerm(term: hit.word.term, scale: scale, width: Self.termWidth)
                .foregroundStyle(t.ink)
                .animation(.easeOut(duration: 0.14), value: scale)
            // Out of the way while the word is at full size, so a long term
            // doesn't land on top of them.
            Group {
                Text(hit.word.partOfSpeech)
                    .font(.system(size: 11).italic())
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
                    .frame(width: Self.posWidth, alignment: .leading)
                if showHindi {
                    Text(hit.word.hindi)
                        .font(.system(size: 14))
                        .foregroundStyle(t.muted)
                        .lineLimit(1)
                        .frame(maxWidth: Self.hindiWidth, alignment: .leading)
                }
            }
            .opacity(scale > 1.3 ? 0 : 1)
            .animation(.easeOut(duration: 0.14), value: scale)
            Spacer(minLength: 0)
            if mark { shelfMark(hit.shelf, t) }
        }
        .padding(.vertical, 10)
        .padding(.horizontal,12)
    }

    /// Which book a match came from. Quiet, at the end of the row, behind the
    /// three columns that are the point — the same symbol stamped on that book's
    /// cover in the Dictionaries pane, with its short name so it reads without
    /// hovering.
    private func shelfMark(_ shelf: String, _ t: Theme) -> some View {
        let shelfBook = Wordbook.named(shelf)
        return HStack(spacing: 4) {
            Image(systemName: shelfBook.symbol).font(.system(size: 9))
            Text(shelfBook.shortName).font(.system(size: 11))
        }
        .foregroundStyle(t.muted)
        .lineLimit(1)
        .help(shelfBook.name)
        .accessibilityLabel(shelfBook.name)
    }

    private func emptyState(_ t: Theme) -> some View {
        VStack(spacing: 14) {
            emptyMark(t)
            VStack(spacing: 2) {
                Text(headline)
                    .font(doodle.face(30)).tracking(doodle.tracking(30)).foregroundStyle(t.ink)
                if !query.isEmpty {
                    Text("\u{201C}\(query)\u{201D}")
                        .font(doodle.face(30).italic()).foregroundStyle(t.ink)
                }
            }
            Text(footnote)
                .font(.system(size: 13))
                .foregroundStyle(t.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    /// The mark over an empty pane. Classic mode stamps the BOOK's own symbol —
    /// the one on its cover — which the doodle set has no per-dictionary answer
    /// for. It gives the nearest thing it does have: the shelf, or the ribbon when
    /// the empty pane is Bookmarks.
    @ViewBuilder
    private func emptyMark(_ t: Theme) -> some View {
        if query.isEmpty {
            GlyphIcon(wordbook?.id == SavedWords.resource ? .bookmarks : .dictionaries,
                      size: 52, weight: .thin)
                .foregroundStyle(t.accent.opacity(0.5))
        } else {
            // No drawing for "nothing matched" in either set — the hexagon stands.
            Image(systemName: "hexagon")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(t.accent.opacity(0.5))
        }
    }

    private var headline: String {
        if !query.isEmpty { return "No words match" }
        return everywhere ? "Look in every book" : "Nothing here yet"
    }

    private var footnote: String {
        if everywhere {
            return "\(WordListViewModel.everywhereCount.formatted()) words across \(WordListViewModel.everywhereBooks.count) dictionaries,searched together each result says which one it came from."
        }
        if query.isEmpty {
            return "Bookmark a word from its page, or select one in any app and choose Services \u{25B8} Save to One Word. Either way it lands here."
        }
        return "You're searching \(wordbook?.shortName ?? "") \u{2014} \(model.count) words."
    }
}

#Preview {
    NavigationStack { WordListView() }
        .environment(RelatedWordsStore())
}
