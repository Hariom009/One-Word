//
//  WordViewModel.swift
//  OneWord
//
//  The app's testable seam: holds the day's word for the SELECTED dictionary.
//  "New Word" is a PEEK — it shows another word for a few seconds and then the
//  day's word comes back, so the day still has one word. The peek is deliberately
//  local: the shared WordStore offset (which the widget reads) is left alone.
//  MainActor-isolated by default isolation.
//

import Foundation
import Observation

@Observable
final class WordViewModel {
    /// How long a peeked word holds before the day's word returns.
    static let peekDuration: Duration = .seconds(5)

    private(set) var word: Word
    private(set) var wordbook: Wordbook
    /// True while showing a peeked word rather than the day's.
    private(set) var isPeeking = false

    private var provider: WordProvider
    /// Steps past the day's word while peeking. 0 = showing the day's word.
    private var peek = 0
    private var revert: Task<Void, Never>?

    init(wordbook: Wordbook = .selected) {
        let provider = WordProvider(resource: wordbook.id)
        self.wordbook = wordbook
        self.provider = provider
        self.word = provider.word(for: Date(), offset: WordStore.offset, pinned: SavedWords.pinned)
    }

    /// Switch dictionaries and show that dictionary's own word of the day (offset reset).
    func select(_ wordbook: Wordbook, for date: Date = Date()) {
        guard wordbook != self.wordbook else { return }
        self.wordbook = wordbook
        self.provider = WordProvider(resource: wordbook.id)
        WordStore.reset()
        refresh(for: date)
    }

    /// Show the day's word for `date`. Every "back to the real word" path goes
    /// through here — app became active, a new day picked, a peek expiring — so
    /// this is also where a pending peek gets cancelled. Without that, a peek
    /// started before a date change would fire later and yank the old day back.
    func refresh(for date: Date = Date()) {
        revert?.cancel()
        revert = nil
        peek = 0
        isPeeking = false
        word = provider.word(for: date, offset: WordStore.offset, pinned: SavedWords.pinned)
    }

    /// Peek at another word from this dictionary. Not persisted and not shared:
    /// it expires on its own, and the widget never sees it.
    ///
    /// `pinned: nil` on purpose — a captured word pinned to today outranks any
    /// offset, so honouring it here would make the button a no-op.
    func shuffle(for date: Date = Date()) {
        revert?.cancel()
        peek += 1
        isPeeking = true
        word = provider.word(for: date, offset: WordStore.offset + peek)
        revert = Task { [weak self] in
            try? await Task.sleep(for: Self.peekDuration)
            guard !Task.isCancelled else { return }
            self?.refresh(for: date)
        }
        // weak self, so a window closed mid-peek deallocates the model right away
        // instead of being held alive by the sleeping task.
    }
}
