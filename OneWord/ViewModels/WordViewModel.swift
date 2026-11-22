//
//  WordViewModel.swift
//  OneWord
//
//  The app's testable seam: holds the day's word for the SELECTED dictionary.
//  Pulling Home's page up is a PEEK — a random word from the book. It stays until Home
//  refreshes (a pane switch, the app reopening, a new day), so the day still has one word.
//  The peek is deliberately local: the shared WordSelectionStore offset (which the
//  widget reads) is left alone.
//  MainActor-isolated by default isolation.
//

import Foundation
import Observation

@Observable
final class WordViewModel {
    private(set) var word: Word
    /// The random word the next pull brings in — drawn ahead so Home can rank its
    /// neighbours off the main thread before it shows.
    private(set) var upcoming: Word
    private(set) var wordbook: Wordbook
    /// True while showing a peeked word rather than the day's.
    private(set) var isPeeking = false
    /// Pulls since the day's word last showed — Home's "Flip 3". Zero on the day's word.
    private(set) var flips = 0
    /// The phone feed's pages: the day's word first, then the words drawn in behind
    /// it. Append-only, so scrolling back shows the same words in the same order
    /// rather than drawing fresh ones — which is what let a good word be lost to a
    /// flick. Reset by every path that ends a peek.
    private(set) var deck: [Word] = []
    /// How far one day's feed runs. One Word is one word a day: the feed is a short
    /// detour from it, not a reel with no floor, so it has an end to reach.
    static let deckLimit = 15
    /// The day's cap, held down by the book — a one-word Bookmarks is one page, not
    /// fifteen copies of it.
    var deckCap: Int { min(Self.deckLimit, provider.allWords.count) }

    private var provider: WordProvider

    init(wordbook: Wordbook = .selected) {
        let provider = WordProvider(resource: wordbook.id)
        let word = provider.word(for: Date(), offset: WordSelectionStore.offset, pinned: SavedWords.pinned)
        self.wordbook = wordbook
        self.provider = provider
        self.word = word
        self.upcoming = Self.draw(provider, besides: word)
        resetDeck()
    }

    /// Switch dictionaries and show that dictionary's own word of the day (offset reset).
    func select(_ wordbook: Wordbook, for date: Date = Date()) {
        guard wordbook != self.wordbook else { return }
        self.wordbook = wordbook
        self.provider = WordProvider(resource: wordbook.id)
        WordSelectionStore.reset()
        refresh(for: date)
        upcoming = Self.draw(provider, besides: word)
    }

    /// Show the day's word for `date`. Every "back to the real word" path goes
    /// through here — app became active, a new day picked, Home reappearing — so
    /// this is also where a peek ends.
    func refresh(for date: Date = Date()) {
        let peeked = isPeeking
        isPeeking = false
        flips = 0
        word = provider.word(for: date, offset: WordSelectionStore.offset, pinned: SavedWords.pinned)
        // Kept through a plain app-active refresh, so the card peeking in doesn't change under you.
        if peeked || upcoming.term == word.term { upcoming = Self.draw(provider, besides: word) }
        resetDeck()
    }

    /// History: a past day's word from ANY book, without touching anything shared.
    /// The refresh offset and a fresh capture's pin both belong to TODAY, so a past
    /// day ignores them — and picking a book to read old days in must not reset
    /// what Home and the widget are showing, which is what `select` would do.
    func show(_ wordbook: Wordbook, on date: Date) {
        if wordbook != self.wordbook {
            self.wordbook = wordbook
            self.provider = WordProvider(resource: wordbook.id)
        }
        word = provider.word(for: date)
        upcoming = Self.draw(provider, besides: word)
        resetDeck()
    }

    /// Home's double tap. Only ever adds: taking a word back out stays with the
    /// ribbon, so a stray double tap can never lose a bookmark. True once the word
    /// is kept — false only for the Bookmarks placeholder, which can't be.
    @discardableResult
    func bookmark(_ pick: Word? = nil) -> Bool {
        let target = pick ?? word
        return SavedWords.contains(target) || SavedWords.toggle(target)
    }

    /// A pull: the word drawn ahead comes in, a fresh one is drawn behind it. Not
    /// persisted and not shared: the next refresh ends it, and the widget never sees it.
    func shuffle() {
        word = upcoming
        upcoming = Self.draw(provider, besides: word)
        flips += 1
        isPeeking = true
    }

    /// The feed settled on `page`. Moves `word` with it — the header's buttons and
    /// the double tap both read `word` — and tops the deck up, so the page behind the
    /// one you are on is already drawn when the drag that brings it in starts.
    func land(on page: Int) {
        guard deck.indices.contains(page) else { return }
        word = deck[page]
        flips = page
        isPeeking = page > 0
        extend()
    }

    /// Two pages of lookahead, within the day's cap.
    private func extend() {
        while deck.count < min(flips + 3, deckCap) {
            deck.append(Self.draw(provider, besides: deck.last ?? word))
        }
    }

    /// Back to one page — the word now showing — plus its lookahead.
    private func resetDeck() {
        deck = [word]
        extend()
    }

    /// A random word from the book other than the one showing. Random, not the next
    /// step of the day's order: that order IS the coming days, so walking it would
    /// spoil tomorrow's word, and the day after's, swipe by swipe.
    private static func draw(_ provider: WordProvider, besides shown: Word) -> Word {
        let pool = provider.allWords
        let fresh = { (w: Word) in w.term != shown.term }
        // ponytail: a few rolls before a scan, so a 12k book never walks itself per swipe.
        // A one-word book (a small Bookmarks) runs out and repeats the word it shows.
        for _ in 0..<8 { if let w = pool.randomElement(), fresh(w) { return w } }
        return pool.first(where: fresh) ?? pool[0]
    }
}
