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
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    var body: some View {
        let t = Theme.of(scheme, doodle)
        // Embedded: Home paints the ground and owns the header, so the word's own
        // buttons join the chip and New Word in one strip rather than a second.
        Group {
            if isPhone {
                // A phone strip can't seat the date, the chip and three buttons. The
                // strip says "Today"; the date and the dictionary sit over the word as
                // one quiet line, the way a dictionary page carries its running head.
                VStack(spacing: 0) {
                    dateline(t)
                    WordDetail(word: model.word, embedded: true)
                }
            } else {
                WordDetail(word: model.word, showDate: true, dictionaryName: model.wordbook.shortName,
                           embedded: true)
            }
        }
            .paneBackground(t)
            .paneHeader(isPhone ? "Today" : Date.now.formatted(.dateTime.month(.wide).day().year())) {
                if !isPhone {
                    Button {
                        pane = .dictionaries
                    } label: {
                        Text(model.wordbook.shortName)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                    }
                    // Long names ("Corporate Slang") would truncate in a squeezed strip.
                    // Ask for the ideal width instead and the chip sizes to its text.
                    .fixedSize()
                    .help("Choose a dictionary")
                }
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
                WordActions(word: model.word)
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

    /// Phone only: the day on the left, the dictionary on the right, no rule under
    /// it. Tapping the book goes to the Dictionaries pane, as the Mac's chip does.
    private func dateline(_ t: Theme) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase).tracking(1.8)
                .foregroundStyle(t.muted)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button { pane = .dictionaries } label: {
                HStack(spacing: 6) {
                    BookChip(book: model.wordbook, height: 18)
                    Text(model.wordbook.shortName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(t.muted)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dictionary: \(model.wordbook.shortName)")
            .accessibilityHint("Chooses a dictionary")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }
}

#Preview {
    NavigationStack { HomeView(pane: .constant(.home)) }
        .environment(RelatedWordsStore())
        .environment(PremiumViewModel())
}
