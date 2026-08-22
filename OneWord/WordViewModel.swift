//
//  WordViewModel.swift
//  OneWord
//
//  The app's testable seam: holds the day's word for the SELECTED dictionary.
//  The "New Word" offset lives in the shared WordStore (App Group), so the app
//  and the widget stay on the same word. MainActor-isolated by default isolation.
//

import Foundation
import Observation

@Observable
final class WordViewModel {
    private(set) var word: Word
    private(set) var wordbook: Wordbook
    private var provider: WordProvider

    init(wordbook: Wordbook = .everydayEnglish) {
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
        word = provider.word(for: date, offset: WordStore.offset, pinned: SavedWords.pinned)
    }

    /// Re-pick for the given day (app became active) — reflects the shared offset.
    func refresh(for date: Date = Date()) {
        word = provider.word(for: date, offset: WordStore.offset, pinned: SavedWords.pinned)
    }

    /// Advance to the next word — shared with the widget, sequential not random.
    func shuffle(for date: Date = Date()) {
        WordStore.advance()
        word = provider.word(for: date, offset: WordStore.offset, pinned: SavedWords.pinned)
    }
}
