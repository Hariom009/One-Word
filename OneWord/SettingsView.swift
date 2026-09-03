//
//  SettingsView.swift
//  OneWord
//
//  The Settings pane. Appearance and what an entry shows — picking a dictionary
//  is its own sidebar section, so it isn't duplicated here. Settings live in the
//  App Group, so they drive both the app and the widget.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    // App Group, like the dictionary: one switch drives the app and the widget.
    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @AppStorage("showExample", store: AppGroup.defaults) private var showExample = true
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
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
            }
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(t.background)
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
}
