//
//  WordWidget.swift
//  OneWordWidget
//
//  The widget definition + the extension's @main entry point.
//  The dictionary is chosen per-widget in the Edit UI (long-press → Edit Widget)
//  via an App Intent configuration — no App Group needed, so it works without any
//  provisioning of the widget's app id.
//

import WidgetKit
import SwiftUI
import AppIntents

/// Dictionaries offered in the widget's Edit menu. `.followApp` (the default) tracks
/// the dictionary picked in the app's Settings (shared via the App Group); the rest
/// pin the widget to a specific dictionary regardless of the app.
enum WidgetDictionary: String, AppEnum {
    case followApp, words, emotions, philosophy, medical, character, eloquence, curiosities, startup

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Dictionary"
    static var caseDisplayRepresentations: [WidgetDictionary: DisplayRepresentation] = [
        .followApp:   "Follow App Settings",
        .words:       "Everyday English",
        .emotions:    "Emotions",
        .philosophy:  "Philosophy",
        .medical:     "Medicine",
        .character:   "Character",
        .eloquence:   "Eloquence",
        .curiosities: "Curiosities",
        .startup:     "Corporate Slang",
    ]

    /// Bundled JSON resource name (`<resource>.json`). `.followApp` resolves at read
    /// time from the App Group so it mirrors the app's current Settings choice.
    var resource: String {
        self == .followApp ? AppGroup.dictionaryID : rawValue
    }
}

/// The widget's configuration: which dictionary to show. Editable per widget.
struct SelectDictionaryIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Dictionary"
    static var description = IntentDescription("Choose which dictionary the widget shows.")

    @Parameter(title: "Dictionary", default: .followApp)
    var dictionary: WidgetDictionary
}

struct WordWidget: Widget {
    let kind = "WordWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectDictionaryIntent.self, provider: WordTimelineProvider()) { entry in
            WordWidgetView(entry: entry)
        }
        .configurationDisplayName("Word of the Day")
        .description("Pick a dictionary; a new word every day.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()   // the view supplies the design's own padding (16/17/26)
    }
}

// NOTE: the widget wizard generates its own `@main ...WidgetBundle` — delete that
// generated file so there is exactly ONE @main in the widget target.
@main
struct OneWordWidgetBundle: WidgetBundle {
    var body: some Widget {
        WordWidget()
    }
}

#Preview(as: .systemMedium) {
    WordWidget()
} timeline: {
    WordEntry(
        date: .now,
        word: Word(
            term: "petrichor",
            partOfSpeech: "noun",
            hindi: "बारिश के बाद सूखी ज़मीन पर पड़ने वाली सुखद मिट्टी जैसी महक",
            definition: "The pleasant, earthy smell after rain falls on dry ground.",
            example: "The first storm of autumn filled the air with petrichor."
        )
    )
}
