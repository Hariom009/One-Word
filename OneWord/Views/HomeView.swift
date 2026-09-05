//
//  HomeView.swift
//  OneWord
//
//  Today's word — the Home pane. Dumb view: binds to WordViewModel, does no data
//  loading. Past days live in HistoryView; the sidebar owns search and settings.
//

import SwiftUI
import WidgetKit
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct HomeView: View {
    /// So the dictionary chip can send you to the Dictionaries pane rather than
    /// opening a second, sheet-shaped way to pick one.
    @Binding var pane: Pane
    @State private var model = WordViewModel()
    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        WordDetail(word: model.word, showDate: true, dictionaryName: model.wordbook.name)
            .navigationTitle(Date.now.formatted(.dateTime.month(.wide).day().year()))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        pane = .dictionaries
                    } label: {
                        Text(model.wordbook.name)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            //.padding(.vertical, 8)
                    }
                   // .buttonStyle(.plain)
                    // The principal slot squeezes to whatever the toolbar leaves it, so
                    // long names ("Dictionary of Corporate Slang") truncate. Ask for the
                    // ideal width instead and the chip sizes to its text.
                    .fixedSize()
                }
                ToolbarItem(placement: .primaryAction) {
                    // A peek, not a new day: the model puts today's word back on
                    // its own, and nothing shared changes, so the widget stays put.
                    Button {
                        model.shuffle()
                    } label: {
                        Label("New Word", systemImage: "arrow.clockwise")
                    }
                    .help(model.isPeeking
                          ? "Just a look \u{2014} today's word comes back in a moment"
                          : "Show another word")
                }
            }
            .onAppear { model.select(Wordbook.named(dictionaryID)) }
            .onChange(of: dictionaryID) { _, id in
                model.select(Wordbook.named(id))
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                model.refresh()
            }
            // A catch can land while this window is already open and visible.
            .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
                model.refresh()
            }
    }
}

#Preview {
    NavigationStack { HomeView(pane: .constant(.home)) }
        .environment(RelatedWordsStore())
}
