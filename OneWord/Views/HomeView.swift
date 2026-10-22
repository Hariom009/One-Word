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
    @Environment(AuthViewModel.self) private var auth
    /// Phone only: the day picked from the title's calendar. nil = today, and stays
    /// today across midnight rather than freezing on the day it was opened.
    @State private var day: Date?
    @State private var picking = false
    /// The floor when there's no account to read a join date off (accounts off).
    /// ponytail: stamped on first sight of Home, so pre-existing installs start today.
    @AppStorage("firstOpened") private var firstOpened: Double = 0
    private let calendar = Calendar.current

    var body: some View {
        let t = Theme.of(scheme, doodle)
        // Embedded: Home paints the ground and owns the header, so the word's own
        // buttons join the chip and New Word in one strip rather than a second.
        Group {
            if isPhone {
                // A phone strip can't seat the date, the chip and three buttons. The
                // strip says "Today" and opens a calendar; the dictionary sits over the
                // word as one quiet line, the way a dictionary page carries its running head.
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
            .paneHeader(isPhone ? dayTitle : Date.now.formatted(.dateTime.month(.wide).day().year()),
                        titleAction: isPhone ? { picking = true } : nil) {
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
                // A past day has no peek — its offset and pin belong to today.
                if day == nil {
                    Button {
                        model.shuffle()
                    } label: {
                        Label("New Word", systemImage: "arrow.clockwise")
                    }
                    .help(model.isPeeking
                          ? "Just a look \u{2014} today's word comes back in a moment"
                          : "Show another word")
                }
                WordActions(word: model.word)
            }
            .sheet(isPresented: $picking) { dayPicker(t) }
            .onAppear {
                if firstOpened == 0 { firstOpened = Date.now.timeIntervalSince1970 }
                model.select(Wordbook.named(dictionaryID))
                show()
            }
            .onChange(of: dictionaryID) { _, id in
                model.select(Wordbook.named(id))
                show()
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onChange(of: day) { show() }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                show()
            }
            // A catch can land while this window is already open and visible.
            .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
                show()
            }
    }

    /// Today's word through the shared offset and pin; a past day's plain, as History reads it.
    private func show() {
        if let day { model.show(model.wordbook, on: day) } else { model.refresh() }
    }

    /// "Today", or the picked day — "October 3", with the year only once it isn't this one.
    private var dayTitle: String {
        guard let day else { return "Today" }
        return calendar.isDate(day, equalTo: .now, toGranularity: .year)
            ? day.formatted(.dateTime.month(.wide).day())
            : day.formatted(.dateTime.month(.wide).day().year())
    }

    /// Phone only: any day from the one you joined up to today. A pick closes it.
    private func dayPicker(_ t: Theme) -> some View {
        let joined = auth.joined ?? Date(timeIntervalSince1970: firstOpened)
        let selection = Binding(get: { day ?? .now },
                                set: { day = calendar.isDateInToday($0) ? nil : $0 })
        let earliest = min(joined, .now)
        let info = "You can pick any day from \(earliest.formatted(date: .long, time: .omitted)), "
            + "the day you joined One Word, up to today. Your words started the day you did, "
            + "and tomorrow's word isn't out yet."
        return MonthCalendar(selection: selection, earliest: earliest, info: info) { _ in picking = false }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 20)
            .presentationDetents([.height(430)])
            .presentationDragIndicator(.visible)
            .presentationBackground(t.background)
    }

    /// Phone only: the dictionary over the word, no rule under it. Tapping the book
    /// goes to the Dictionaries pane, as the Mac's chip does.
    private func dateline(_ t: Theme) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Spacer(minLength: 8)
            Button { pane = .dictionaries } label: {
                HStack(spacing: 6) {
                    BookChip(book: model.wordbook, height: 18)
                    Text(model.wordbook.shortName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
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
        .environment(AuthViewModel())
}
