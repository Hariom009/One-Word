//
//  RefreshWordIntent.swift
//  OneWordWidget
//
//  Tapping the widget's refresh button runs this: advance to a new word and
//  ask WidgetKit to rebuild the timeline. Interactive widgets require macOS 14+.
//

import AppIntents
import WidgetKit

struct RefreshWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Refresh Word"

    func perform() async throws -> some IntentResult {
        WordSelectionStore.advance()
        WidgetCenter.shared.reloadTimelines(ofKind: "WordWidget")
        return .result()
    }
}
