//
//  WordTimelineProvider.swift
//  OneWordWidget
//
//  The widget's "view model": WidgetKit asks it what to show and when to refresh.
//  The dictionary comes from the widget's own configuration (SelectDictionaryIntent,
//  editable per widget) — no App Group needed. The manual refresh offset is the
//  widget-local WordStore.
//

import WidgetKit
import Foundation

struct WordTimelineProvider: AppIntentTimelineProvider {
    private let calendar = Calendar.current

    // Loads the configured dictionary's JSON from the WIDGET bundle — every dictionary
    // json must be a member of the widget target too, or this traps on launch.
    private func provider(for configuration: SelectDictionaryIntent) -> WordProvider {
        WordProvider(resource: configuration.dictionary.resource)
    }

    func placeholder(in context: Context) -> WordEntry {
        let words = WordProvider(resource: WidgetDictionary.words.resource)
        return WordEntry(date: Date(), word: words.word(for: Date(), offset: WordStore.offset, pinned: SavedWords.pinned))
    }

    func snapshot(for configuration: SelectDictionaryIntent, in context: Context) async -> WordEntry {
        let words = provider(for: configuration)
        return WordEntry(date: Date(), word: words.word(for: Date(), offset: WordStore.offset, pinned: SavedWords.pinned))
    }

    func timeline(for configuration: SelectDictionaryIntent, in context: Context) async -> Timeline<WordEntry> {
        let words = provider(for: configuration)
        let today = calendar.startOfDay(for: Date())
        let shift = WordStore.offset
        let entries = (0..<7).compactMap { dayOffset -> WordEntry? in
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return nil }
            // The pin is today's only — the rest of the week is the normal sequence.
            return WordEntry(date: day, word: words.word(for: day, offset: shift,
                                                         pinned: dayOffset == 0 ? SavedWords.pinned : nil))
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}
