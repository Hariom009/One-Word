//
//  WordViewModel.swift
//  OneWord
//
//  The app's testable seam: holds the day's word for the SELECTED dictionary.
//  A swipe on Home is a PEEK — Home's cover flow steps through random words, and a
//  few seconds after the last step the day's word comes back, so the day still has one word. The peek is deliberately
//  local: the shared WordSelectionStore offset (which the widget reads) is left alone.
//  MainActor-isolated by default isolation.
//

import Foundation
import Observation

@Observable
final class WordViewModel {
    /// How long a peeked word holds before the day's word returns.
    static let peekDuration: Duration = .seconds(5)

    private(set) var word: Word
    /// The random word waiting on the right of Home's cover flow — drawn ahead so it
    /// can peek in before you swipe to it.
    private(set) var upcoming: Word
    private(set) var wordbook: Wordbook
    /// True while showing a peeked word rather than the day's.
    private(set) var isPeeking = false

    private var provider: WordProvider
    /// The words stepped past while peeking, oldest first: the day's word, then each
    /// swipe. Its last is the card on the left, where a swipe right goes back to.
    private var trail: [Word] = []
    private var revert: Task<Void, Never>?

    var previous: Word? { trail.last }

    init(wordbook: Wordbook = .selected) {
        let provider = WordProvider(resource: wordbook.id)
        let word = provider.word(for: Date(), offset: WordSelectionStore.offset, pinned: SavedWords.pinned)
        self.wordbook = wordbook
        self.provider = provider
        self.word = word
        self.upcoming = Self.draw(provider, besides: [word])
    }

    /// Switch dictionaries and show that dictionary's own word of the day (offset reset).
    func select(_ wordbook: Wordbook, for date: Date = Date()) {
        guard wordbook != self.wordbook else { return }
        self.wordbook = wordbook
        self.provider = WordProvider(resource: wordbook.id)
        WordSelectionStore.reset()
        refresh(for: date)
        upcoming = Self.draw(provider, besides: [word])
    }

    /// Show the day's word for `date`. Every "back to the real word" path goes
    /// through here — app became active, a new day picked, a peek expiring — so
    /// this is also where a pending peek gets cancelled. Without that, a peek
    /// started before a date change would fire later and yank the old day back.
    func refresh(for date: Date = Date()) {
        let peeked = isPeeking
        revert?.cancel()
        revert = nil
        isPeeking = false
        trail = []
        word = provider.word(for: date, offset: WordSelectionStore.offset, pinned: SavedWords.pinned)
        // Kept through a plain app-active refresh, so the card peeking in doesn't change under you.
        if peeked || upcoming.term == word.term { upcoming = Self.draw(provider, besides: [word]) }
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
        upcoming = Self.draw(provider, besides: [word])
    }

    /// Home's double tap. Only ever adds: taking a word back out stays with the
    /// ribbon, so a stray double tap can never lose a bookmark. True once the word
    /// is kept — false only for the Bookmarks placeholder, which can't be.
    @discardableResult
    func bookmark() -> Bool {
        SavedWords.contains(word) || SavedWords.toggle(word)
    }

    /// Swipe left: the waiting word comes in, a fresh one is drawn behind it. Not
    /// persisted and not shared: it expires on its own, and the widget never sees it.
    func shuffle(for date: Date = Date()) {
        trail.append(word)
        word = upcoming
        upcoming = Self.draw(provider, besides: [word, previous])
        peek(for: date)
    }

    /// Swipe right: back one word, the one you left now waiting on the right.
    /// Back at the day's word there's nothing left to return from.
    func back(for date: Date = Date()) {
        guard let last = trail.popLast() else { return }
        upcoming = word
        word = last
        if trail.isEmpty {
            revert?.cancel()
            isPeeking = false
        } else {
            peek(for: date)
        }
    }

    /// A finger on the cards holds the day's word off; letting go restarts the wait.
    func hold() { revert?.cancel() }
    func letGo(for date: Date = Date()) { if isPeeking { peek(for: date) } }

    private func peek(for date: Date) {
        revert?.cancel()
        isPeeking = true
        revert = Task { [weak self] in
            try? await Task.sleep(for: Self.peekDuration)
            guard !Task.isCancelled else { return }
            self?.refresh(for: date)
        }
        // weak self, so a window closed mid-peek deallocates the model right away
        // instead of being held alive by the sleeping task.
    }

    /// A random word from the book that isn't already on a card. Random, not the next
    /// step of the day's order: that order IS the coming days, so walking it would
    /// spoil tomorrow's word, and the day after's, swipe by swipe.
    private static func draw(_ provider: WordProvider, besides shown: [Word?]) -> Word {
        let pool = provider.allWords
        let fresh = { (w: Word) in !shown.contains { $0?.term == w.term } }
        // ponytail: a few rolls before a scan, so a 12k book never walks itself per swipe.
        // A one- or two-word book (a small Bookmarks) runs out and repeats; Home hides that card.
        for _ in 0..<8 { if let w = pool.randomElement(), fresh(w) { return w } }
        return pool.first(where: fresh) ?? pool[0]
    }
}
