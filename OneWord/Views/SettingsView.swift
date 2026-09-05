//
//  SettingsView.swift
//  OneWord
//
//  The Settings pane. Appearance and what an entry shows — picking a dictionary
//  is its own sidebar section, so it isn't duplicated here. Settings live in the
//  App Group, so they drive both the app and the widget.
//
//  Laid out the way the rest of the app is: uppercase section labels, rows in a
//  t.surface card split by hairlines, every switch explained by the line under it.
//

import SwiftUI
import WidgetKit

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = Appearance.system.rawValue
    // App Group, like the dictionary: one switch drives the app and the widget.
    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @AppStorage("showExample", store: AppGroup.defaults) private var showExample = true
    // App-only: the widget shows a word, never a sentence — so these stay in the
    // standard defaults, same as `appearance`.
    @AppStorage("practiceEnabled") private var practiceEnabled = true
    @AppStorage("practiceLanguage") private var practiceLanguage = "de"
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                section("Appearance", t) {
                    HStack(spacing: 10) {
                        ForEach(Appearance.allCases) { mode in
                            Button { appearance = mode.rawValue } label: {
                                AppearanceTile(mode: mode,
                                               selected: mode.rawValue == appearance,
                                               theme: t)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(mode.rawValue == appearance ? .isSelected : [])
                        }
                    }
                }

                section("The entry", t, note: "Applies to the desktop widget too.") {
                    card(t) {
                        row("Hindi meaning", "The Devanagari line under the word.", t) {
                            Toggle("Hindi meaning", isOn: $showHindi).labelsHidden()
                        }
                        rule(t)
                        row("Example sentence", "The quoted line showing the word in use.", t) {
                            Toggle("Example sentence", isOn: $showExample).labelsHidden()
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(t.accent)
                    .onChange(of: showHindi) { WidgetCenter.shared.reloadAllTimelines() }
                    .onChange(of: showExample) { WidgetCenter.shared.reloadAllTimelines() }
                }

                section("Practice", t) {
                    card(t) {
                        row("Practice mode", "Adds the Practice pane to the sidebar.", t) {
                            Toggle("Practice mode", isOn: $practiceEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .tint(t.accent)
                        }
                        rule(t)
                        row("Language", "The corpus the sentences come from.", t) {
                            // German is the only corpus that ships, so it is the only row.
                            Picker("Language", selection: $practiceLanguage) {
                                Text("German").tag("de")
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }
                        .disabled(!practiceEnabled)
                        .opacity(practiceEnabled ? 1 : 0.45)
                    }
                }
            }
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .background(t.background)
        .navigationTitle("Settings")
    }

    // MARK: - Pieces

    /// Uppercase label, the content, and an optional footnote — the section shape
    /// used across the app (ProfileView's "bookmarks" caption is the same type).
    @ViewBuilder
    private func section<C: View>(_ title: String,
                                  _ t: Theme,
                                  note: String? = nil,
                                  @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase).tracking(2)
                .foregroundStyle(t.muted)
            content()
            if let note {
                Text(note)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
            }
        }
    }

    private func card<C: View>(_ t: Theme, @ViewBuilder content: () -> C) -> some View {
        VStack(spacing: 0) { content() }
            .background(t.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(t.hairline))
    }

    /// Inset so the rule reads as a row separator, not a card divider.
    private func rule(_ t: Theme) -> some View {
        Divider().overlay(t.hairline).padding(.leading, 14)
    }

    private func row<C: View>(_ title: String,
                              _ caption: String,
                              _ t: Theme,
                              @ViewBuilder control: () -> C) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(t.ink)
                Text(caption)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

/// A miniature page in the mode it names — paper, night, or both — so the choice
/// is shown rather than spelled. System is the two halves side by side.
private struct AppearanceTile: View {
    let mode: Appearance
    let selected: Bool
    let theme: Theme

    var body: some View {
        VStack(spacing: 8) {
            preview
                .frame(height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(theme.hairline))
            HStack(spacing: 5) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 11))
                Text(mode.name)
                    .font(.system(size: 12))
            }
            .foregroundStyle(selected ? theme.ink : theme.muted)
        }
        .padding(7)
        .background(selected ? theme.ink.opacity(0.06) : .clear,
                    in: RoundedRectangle(cornerRadius: 11))
        .overlay(RoundedRectangle(cornerRadius: 11)
            .strokeBorder(selected ? theme.ink.opacity(0.3) : .clear))
        .contentShape(Rectangle())
    }

    @ViewBuilder private var preview: some View {
        switch mode {
        case .light:  page(.light)
        case .dark:   page(.dark)
        case .system: HStack(spacing: 0) { page(.light); page(.dark) }
        }
    }

    private func page(_ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Aa")
                .font(.serif(15))
                .foregroundStyle(t.ink)
            Capsule().fill(t.muted).frame(width: 26, height: 2)
            Capsule().fill(t.rule).frame(width: 17, height: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(8)
        .background(t.background)
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
