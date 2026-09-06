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
    // Two switches, not one: the drawings and the handwriting are separate tastes.
    // App-only — the widget's bundle carries neither the art nor the face.
    @AppStorage(DoodleTheme.iconsKey) private var doodleIcons = false
    @AppStorage(DoodleTheme.handwritingKey) private var doodleFont = false
    // App Group, like the dictionary: one switch drives the app and the widget.
    @AppStorage("showHindi", store: AppGroup.defaults) private var showHindi = true
    @AppStorage("showExample", store: AppGroup.defaults) private var showExample = true
    // App-only: the widget shows a word, never a sentence — so these stay in the
    // standard defaults, same as `appearance`.
    @AppStorage("practiceEnabled") private var practiceEnabled = true
    @AppStorage("practiceLanguage") private var practiceLanguage = "de"
    @AppStorage("practiceAutoSpeak") private var practiceAutoSpeak = false
    /// App-only: the profile shows the goal, the widget never does.
    @AppStorage("fluencyGoal") private var fluencyGoal = false
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

                section("Doodle", t,
                        note: "The app only. The widget keeps its symbols and its serif \u{2014} "
                            + "neither the drawings nor the face ships inside it.") {
                    VStack(spacing: 10) {
                        DoodleSample(theme: t)
                        card(t) {
                            row("Hand-drawn icons",
                                "Swaps the app's symbols for the doodle set \u{2014} and the spinner for a camper.",
                                t) {
                                Toggle("Hand-drawn icons", isOn: $doodleIcons).labelsHidden()
                            }
                            rule(t)
                            row("Handwritten type",
                                "Sets the headwords and titles in Pulpen Snowman.",
                                t,
                                info: """
                                Pulpen Snowman draws Latin letters, digits and \
                                quotation marks. It has no Devanagari and no em-dash, \
                                so the Hindi meaning \u{2014} and the odd long dash \u{2014} \
                                keep the system face underneath.
                                """) {
                                Toggle("Handwritten type", isOn: $doodleFont).labelsHidden()
                            }
                        }
                        .toggleStyle(.switch)
                        .tint(t.accent)
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
                        row("Speak the answer", "Reads it aloud the moment it appears, without tapping Pronounce.", t) {
                            Toggle("Speak the answer", isOn: $practiceAutoSpeak)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .tint(t.accent)
                        }
                        .disabled(!practiceEnabled)
                        .opacity(practiceEnabled ? 1 : 0.45)
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

                section("Progress", t) {
                    card(t) {
                        row("Fluency goal",
                            "Shows how far through 3,000 German words you are, on your profile.",
                            t,
                            info: """
                            Experts put fluency at around 3,000 words \u{2014} learn that \
                            many in German and you follow roughly 95% of everyday speech.

                            Turn this on and your profile tracks how far through those \
                            3,000 you are. Only the Dictionary of German counts toward \
                            it, and every German word you've already read in full is \
                            counted, so you don't start from zero.
                            """) {
                            Toggle("Fluency goal", isOn: $fluencyGoal)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .tint(t.accent)
                        }
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
                              info: String? = nil,
                              @ViewBuilder control: () -> C) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundStyle(t.ink)
                    if let info { InfoButton(text: info, theme: t) }
                }
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

/// The (i) beside a setting: why you'd want it, one popover away, so the row keeps
/// its one-line caption instead of growing a paragraph nobody reads twice.
private struct InfoButton: View {
    let text: String
    let theme: Theme
    @State private var showing = false

    var body: some View {
        Button { showing = true } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 12))
                .foregroundStyle(theme.muted)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("About this setting")
        .popover(isPresented: $showing, arrowEdge: .bottom) {
            // A popover is its own window and doesn't inherit the app's appearance
            // override, so the surface is painted here rather than left to the system.
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(theme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: 250, alignment: .leading)
                .padding(14)
                .background(theme.surface)
        }
    }
}

/// Both halves of the doodle theme at once, in a strip the size of a row: the
/// drawings the sidebar would wear, and a word in the face the headwords would
/// take. It reads `\.doodle` rather than the two switches, so it shows what the
/// app is actually about to look like and not what Settings thinks it asked for.
private struct DoodleSample: View {
    let theme: Theme
    @Environment(\.doodle) private var doodle

    private let glyphs: [Glyph] = [.home, .history, .practice, .bookmarks,
                                   .dictionaries, .learned]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ForEach(Array(glyphs.enumerated()), id: \.offset) { _, g in
                    GlyphIcon(g, size: 15)
                        .foregroundStyle(theme.ink)
                }
                Spacer(minLength: 0)
                DoodleLoader(size: 22, road: false)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("ephemeral")
                    .font(doodle.face(30))
                    .foregroundStyle(theme.ink)
                Text("lasting a very short time")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(theme.hairline))
        .animation(.easeInOut(duration: 0.18), value: doodle)
        .accessibilityHidden(true)   // the two rows under it say what it shows
    }
}

/// A miniature page in the mode it names — paper, night, or both — so the choice
/// is shown rather than spelled. System is the two halves side by side.
private struct AppearanceTile: View {
    let mode: Appearance
    let selected: Bool
    let theme: Theme

    /// The doodle theme's hand, for the display face. `.face()` hands back the
    /// editorial serif untouched when the handwriting switch is off.
    @Environment(\.doodle) private var doodle
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
                .font(doodle.face(15))
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
