//
//  SettingsView.swift
//  OneWord
//
//  Presented as a sheet from the gear button. Appearance, what an entry shows,
//  and the current dictionary — the shelf itself lives in DictionaryPicker,
//  which the toolbar chip opens directly. Settings live in the App Group, so
//  they drive both the app and the widget.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    @AppStorage("dictionaryID", store: AppGroup.defaults)
    private var dictionaryID = Wordbook.everydayEnglish.id
    // App Group, like the dictionary: one switch drives the app and the widget.
    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @AppStorage("showExample", store: AppGroup.defaults) private var showExample = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var showingDictionary = false

    var body: some View {
        let t = Theme.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Settings").font(.title2.weight(.semibold))
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Appearance")
                            .font(.headline).foregroundStyle(t.muted)
                        Picker("Appearance", selection: $appearance) {
                            ForEach(Appearance.allCases) { mode in
                                Text(mode.name).tag(mode.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Show")
                            .font(.headline).foregroundStyle(t.muted)
                        Toggle("Hindi meaning", isOn: $showHindi)
                        Toggle("Example sentence", isOn: $showExample)
                    }
                    .toggleStyle(.switch)
                    .tint(t.accent)
                    .onChange(of: showHindi) { WidgetCenter.shared.reloadAllTimelines() }
                    .onChange(of: showExample) { WidgetCenter.shared.reloadAllTimelines() }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Dictionary")
                            .font(.headline).foregroundStyle(t.muted)
                        HStack {
                            Label(Wordbook.named(dictionaryID).name,
                                  systemImage: Wordbook.named(dictionaryID).symbol)
                                .foregroundStyle(t.ink)
                            Spacer()
                            Button("Change\u{2026}") { showingDictionary = true }
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(t.background)
        .frame(minWidth: 520, idealWidth: 640, minHeight: 480, idealHeight: 620)
        .sheet(isPresented: $showingDictionary) { DictionaryPicker() }
    }
}

#Preview {
    SettingsView()
}
