//
//  WordListView.swift
//  OneWord
//
//  A word list. Two panes use it: Search, which is dictionary-agnostic — it
//  belongs to no book, searches every one of them at once, and tags each result
//  with the book it came from — and Bookmarks, pinned to the saved list and
//  browsing itself alphabetically. A bundled book gets the same pinned list,
//  pushed when its cover is double-clicked on the shelf. Editorial styling;
//  empty state when nothing matches.
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
    /// The Search pane's matches, delivered by the background search below.
    @State private var found: [WordListViewModel.Hit] = []
    /// How many words that search covers; 0 until the books have been decoded.
    @State private var total = 0
    /// How far off the top of the list, 0…1 — on a phone the header blurs away with it.
    @State private var fade: CGFloat = 0
    @Environment(\.colorScheme) private var scheme
    /// Search spans locked books too: their words are listed as a teaser, meaning withheld.
    @Environment(PremiumViewModel.self) private var premium

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
        // Bookmarks filters its few rows in place; Search is answered off main.
        let results = everywhere ? found : model.results(for: query)
        // Matches can come from anywhere, so each one has to say where from.
        // A pinned pane needs no tag — every row is the book in the title.
        let mark = everywhere
        // A ZStack, not a Group: a Group hands its modifiers to each branch, so the header
        // (and its search field) was rebuilt whenever list and empty state traded places —
        // dropping focus mid-word, or refocusing with the typed text all selected.
        ZStack {
            if results.isEmpty {
                emptyState(t)
            } else {
                List(results) { hit in
                    // Same swell as the Learned pane, hover held by the row — see HoverSwell.
                    HoverSwell { scale in
                        // The shelf travels with the hit: a word found in Medicine
                        // while Everyday English is open must not be logged — or
                        // opened — against Everyday English.
                        NavigationLink { WordDetail(word: hit.word, shelf: hit.shelf) } label: {
                            row(hit, t, mark: mark, scale: scale)
                        }
                    }
                        // Clear, so the pane's ground — Midnight's glow included —
                        // shows through the rows instead of stopping at them.
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(t.hairline)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .tint(t.accent)
                .tracksScrollFade($fade)
            }
        }
        .paneBackground(t)
        // The field rides in the header strip — no row of its own above the list,
        // which a Bookmarks pane holding three words never needed.
        // A bundled book's list is only ever pushed, from the shelf; Bookmarks and Search are panes.
        .paneHeader(wordbook?.shortName ?? "Search", back: wordbook != nil && wordbook != .saved,
                    ribbon: isPhone && wordbook?.id == SavedWords.resource,
                    fade: isPhone && !results.isEmpty ? fade : 0) {
            // How many you've kept. Only Bookmarks — every other pane's total is
            // already in the search prompt, and it never changes while you look at it.
            // A phone has no room for it; the ribbon leads the title there instead.
            if !isPhone && wordbook?.id == SavedWords.resource {
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
        // Re-runs per keystroke and cancels the one before it. The cancelled search
        // can still resume after the newer one landed, so it checks before writing.
        .task(id: query) {
            guard everywhere else { return }
            let hits = await WordListViewModel.search(query)
            guard !Task.isCancelled else { return }
            found = hits
        }
        .task { if everywhere { total = await WordListViewModel.everywhereCount() } }
    }

    @ViewBuilder
    private func row(_ hit: WordListViewModel.Hit, _ t: Theme, mark: Bool, scale: CGFloat) -> some View {
        if isPhone { phoneRow(hit, t, mark: mark) } else { wideRow(hit, t, mark: mark, scale: scale) }
    }

    /// The Mac's three columns are 760pt wide; a phone has 390. Two lines instead:
    /// the word with its part of speech, the Hindi gloss beneath, the book at the
    /// end. No swell — there is no pointer to swell for.
    private func phoneRow(_ hit: WordListViewModel.Hit, _ t: Theme, mark: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(hit.word.term)
                        .font(doodle.face(19))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(hit.word.partOfSpeech)
                        .font(.system(size: 11).italic())
                        .foregroundStyle(t.muted)
                        .lineLimit(1)
                }
                if showHindi && premium.allows(hit.shelf) && !hit.word.hindi.isEmpty {
                    Text(hit.word.hindi)
                        .font(.system(size: 13))
                        .foregroundStyle(t.muted)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            if mark { shelfMark(hit.shelf, t) }
        }
        .padding(.vertical, 6)
    }

    private func wideRow(_ hit: WordListViewModel.Hit, _ t: Theme, mark: Bool, scale: CGFloat) -> some View {
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
                // The gloss IS the meaning for a Hindi reader — a locked word keeps it.
                if showHindi && premium.allows(hit.shelf) {
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
        let locked = !premium.allows(shelf)
        return HStack(spacing: 4) {
            Image(systemName: shelfBook.symbol).font(.system(size: 9))
            Text(shelfBook.shortName).font(.system(size: 11))
            if locked { Image(systemName: "lock.fill").font(.system(size: 8)) }
        }
        .foregroundStyle(t.muted)
        .lineLimit(1)
        .help(shelfBook.name)
        .accessibilityLabel(locked ? "\(shelfBook.name), Premium" : shelfBook.name)
    }

    private func emptyState(_ t: Theme) -> some View {
        VStack(spacing: 14) {
            emptyMark(t)
            VStack(spacing: 2) {
                Text(headline)
                    .font(doodle.face(isPhone ? 24 : 30)).tracking(doodle.tracking(isPhone ? 24 : 30))
                    .foregroundStyle(t.ink)
                    .multilineTextAlignment(.center)
                if !query.isEmpty {
                    Text("\u{201C}\(query)\u{201D}")
                        .font(doodle.face(isPhone ? 24 : 30).italic()).foregroundStyle(t.ink)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
            Text(footnote)
                .font(.system(size: 13))
                .foregroundStyle(t.muted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 340)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(isPhone ? 24 : 40)
    }

    /// The mark over an empty pane: the shelf, or the ribbon when the empty pane
    /// is Bookmarks.
    @ViewBuilder
    private func emptyMark(_ t: Theme) -> some View {
        if query.isEmpty {
            GlyphIcon(wordbook?.id == SavedWords.resource ? .bookmarks : .dictionaries,
                      size: 52, weight: .thin)
                .foregroundStyle(t.accent.opacity(0.5))
        } else {
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
            let scope = total > 0 ? "\(total.formatted()) words across \(WordListViewModel.everywhereBooks.count) dictionaries"
                                  : "Every dictionary"
            return "\(scope), searched together. Each result says which one it came from."
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
        .environment(PremiumViewModel())
}
