//
//  HistoryView.swift
//  OneWord
//
//  The History pane: any past day's word, with the month grid beside it. This is
//  where date browsing lives — Home is only ever today.
//

import SwiftUI

struct HistoryView: View {
    /// So the dictionary chip can send you to the Dictionaries pane, same as Home.
    @Binding var pane: Pane
    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    @State private var model = WordViewModel()
    @State private var date = Date()
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
        HStack(alignment: .top, spacing: 0) {
            MonthCalendar(selection: $date) { picked in
                date = picked
                model.refresh(for: picked)
            }
            .padding(.vertical, 16)
            .frame(width: 262)
            Divider().overlay(t.hairline)
            WordDetail(word: model.word, dictionaryName: model.wordbook.name)
        }
        .background(t.background)
        .navigationTitle(date.formatted(.dateTime.month(.wide).day().year()))
        // Every dictionary has its own word of the day, so the date alone doesn't
        // say which history you're reading.
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button { pane = .dictionaries } label: {
                    Text(model.wordbook.name)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                }
                .fixedSize()
            }
        }
        .onAppear { load() }
        .onChange(of: dictionaryID) { _, _ in load() }
    }

    private func load() {
        model.select(Wordbook.named(dictionaryID), for: date)
        model.refresh(for: date)   // select() no-ops when the book is unchanged
    }
}
