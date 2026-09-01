//
//  WordView.swift
//  OneWord
//
//  Today's word. Dumb view — binds to WordViewModel, does no data loading.
//

import SwiftUI
import WidgetKit
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct WordView: View {
    @State private var model = WordViewModel()
    @State private var showingSettings = false
    @State private var showingDictionary = false
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        WordDetail(word: model.word, showDate: true, dictionaryName: model.wordbook.name)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Button {
                            showingDatePicker = true
                        } label: {
                            Text(selectedDate.formatted(.dateTime.month(.wide).day().year()))
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showingDatePicker) {
                            datePicker
                        }
                        Button {
                            showingDictionary = true
                        } label: {
                            Text(model.wordbook.name)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal,8)
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        model.shuffle(for: selectedDate)
                        WidgetCenter.shared.reloadAllTimelines()
                    } label: {
                        Label("New Word", systemImage: "arrow.clockwise")
                    }
                    .help("Show another word")
                    NavigationLink {
                        WordListView()
                    } label: {
                        Label("Search Words", systemImage: "magnifyingglass")
                    }
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .help("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingDictionary) {
                DictionaryPicker()
            }
            .onAppear { model.select(Wordbook.named(dictionaryID), for: selectedDate) }
            .onChange(of: dictionaryID) { _, id in
                model.select(Wordbook.named(id), for: selectedDate)
                WidgetCenter.shared.reloadAllTimelines()
            }
            .onChange(of: scenePhase) { _, phase in
                // Only auto-advance to "now" if the user hadn't picked a different day to browse.
                guard phase == .active, Calendar.current.isDateInToday(selectedDate) else { return }
                selectedDate = Date()
                model.refresh(for: selectedDate)
            }
            // A catch can land while this window is already open and visible.
            .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
                model.refresh(for: selectedDate)
            }
    }

    private var datePicker: some View {
        MonthCalendar(selection: $selectedDate) { date in
            model.refresh(for: date)
            showingDatePicker = false
        }
    }
}

#Preview {
    WordView()
        .environment(RelatedWordsStore())
}
