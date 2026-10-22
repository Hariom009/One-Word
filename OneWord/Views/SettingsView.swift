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
    /// SwiftUI's own URL opener: LaunchServices on the Mac, UIApplication on iOS.
    @Environment(\.openURL) private var openURL
    @AppStorage("appearance") private var appearance = Appearance.initial.rawValue
    // Two switches, not one: the drawings and the handwriting are separate tastes.
    // App-only — the widget's bundle carries neither the art nor the face.
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
    /// The doodle switches and Midnight, as the app root resolved them.
    @Environment(\.doodle) private var doodle
    /// Premium's section, and the fluency goal, which only the German shelf feeds.
    @Environment(PremiumViewModel.self) private var premium

    /// The written-complaint half of Feedback. Owned here so an unsent draft
    /// survives closing the sheet — it does not survive leaving the pane, which
    /// is the same bargain every other unsaved field in the app makes.
    @State private var feedback = FeedbackViewModel()
    @State private var writing = false
    /// No mail client answered. A dead button is worse than an address to copy.
    @State private var mailFailed = false

    var body: some View {
        let t = Theme.of(scheme, doodle)
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // First, because it's the one thing here that isn't a preference. The bar
                // carries Restore Purchase, which App Review needs reachable.
                if Features.premium { section("Premium", t) {
                    if premium.isUnlocked {
                        card(t) {
                            row("All dictionaries unlocked", "Every shelf is yours, for good.", t) {
                                Image(systemName: "checkmark.seal")
                                    .font(.system(size: 14))
                                    .foregroundStyle(t.muted)
                            }
                        }
                    } else {
                        PremiumBar()
                    }
                } }

                section("Appearance", t,
                        note: "The app only \u{2014} the widget follows the system's own light or dark.") {
                    // A grid, not a row: a further tile — or a narrow window — wraps
                    // instead of clipping a name.
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)],
                              spacing: 10) {
                        ForEach(Appearance.allCases) { mode in
                            Button { appearance = mode.rawValue } label: {
                                AppearanceTile(mode: mode,
                                               selected: mode == .stored(appearance),
                                               theme: t)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(mode == .stored(appearance) ? .isSelected : [])
                        }
                    }
                }

                section("Doodle", t,
                        note: "The app only. The widget keeps its serif \u{2014} "
                            + "the face doesn't ship inside it.") {
                    card(t) {
                        row("Handwritten type",
                            "Sets the headwords and titles in Pulpen Snowman.",
                            t,
                            info: """
                            Pulpen Snowman draws Latin letters, digits and \
                            quotation marks. It has no Devanagari and no em-dash, \
                            so the Hindi meaning \u{2014} and the odd long dash \u{2014} \
                            keep the system face underneath.
                            """,
                            sample: true) {
                            Toggle("Handwritten type", isOn: $doodleFont).labelsHidden()
                        }
                    }
                    .toggleStyle(.switch)
                    .tint(t.accent)
                }

                section("The entry", t, note: "Applies to the widget too.") {
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

                if Features.practice { section("Practice", t) {
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
                } }

                // Only the German shelf counts toward the goal, so it waits for German to
                // unlock. The switch keeps its value, and comes back as you left it.
                if premium.allows(Wordbook.german.id) {
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

                if Features.feedback { section("Feedback", t,
                        note: "Bugs, a wrong meaning, a word you'd like added \u{2014} "
                            + "all of it helps.") {
                    card(t) {
                        Button { openMail() } label: {
                            row("Email", "Opens a draft in your mail app.", t) {
                                Image(systemName: "envelope")
                                    .font(.system(size: 14))
                                    .foregroundStyle(t.muted)
                            }
                            // `row` ends at .padding with no contentShape of its
                            // own, so a bare Button would be hittable on the
                            // glyphs only. This makes the whole row the target.
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens a new message to \(FeedbackViewModel.address)")
                        if Features.accounts {
                            rule(t)
                            Button { feedback.reset(); writing = true } label: {
                                row("Write a message",
                                    "Send it from here \u{2014} no mail app needed.", t) {
                                    Image(systemName: "square.and.pencil")
                                        .font(.system(size: 14))
                                        .foregroundStyle(t.muted)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if mailFailed {
                        // Renders above the section's note. A transient error
                        // outranking a static footnote is the right way round.
                        Text("No mail app is set up on this device. Write to \(FeedbackViewModel.address).")
                            .font(.system(size: 11))
                            .foregroundStyle(t.muted)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                }
            }
            .frame(maxWidth: 520, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .paneBackground(t)
        .paneHeader("Settings")
        // `t`, not the sheet's own scheme read: a sheet is its own window, so it
        // is handed the theme this pane is painted with.
        .sheet(isPresented: $writing) { FeedbackView(theme: t, model: feedback) }
    }

    /// Hands a pre-addressed draft to whatever the mail client is. The opener reports
    /// `.discarded`/`.systemAction(false)` when nothing is registered for mailto: — that
    /// is the only failure worth showing, and it shows as an address rather than an alert.
    private func openMail() {
        guard let url = FeedbackViewModel.mailtoURL else { mailFailed = true; return }
        openURL(url) { accepted in mailFailed = !accepted }
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
            .background(t.surface, in: RoundedRectangle(cornerRadius: t.radius(10)))
            .overlay(RoundedRectangle(cornerRadius: t.radius(10)).strokeBorder(t.hairline))
    }

    /// Inset so the rule reads as a row separator, not a card divider.
    private func rule(_ t: Theme) -> some View {
        Divider().overlay(t.hairline).padding(.leading, 14)
    }

    private func row<C: View>(_ title: String,
                              _ caption: String,
                              _ t: Theme,
                              info: String? = nil,
                              sample: Bool = false,
                              @ViewBuilder control: () -> C) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundStyle(t.ink)
                    if let info { InfoButton(text: info, theme: t, sample: sample) }
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
    /// Leads with the doodle sample, for the handwriting row.
    var sample = false
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
            // The ground goes under it because a surface may be see-through: Midnight's
            // is 7% white, and on a Mac in Light mode that alone lands on a light
            // popover and leaves near-white ink on near-white.
            // On iPhone the popover adapts to a sheet; the detent keeps it a bottom sheet.
            VStack(alignment: .leading, spacing: 14) {
                if sample { DoodleSample(theme: theme) }
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.ink)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            #if os(iOS)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(20)
            #else
            .frame(width: 250, alignment: .leading)
            .padding(14)
            #endif
            .background(theme.surface)
            .background(theme.background)
            .presentationDetents([.medium])
        }
    }
}

/// The doodle hand in a strip the size of a row: a word in the face the headwords
/// would take. It reads `\.doodle` rather than the switch, so it shows what the
/// app is actually about to look like and not what Settings thinks it asked for.
private struct DoodleSample: View {
    let theme: Theme
    @Environment(\.doodle) private var doodle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        .background(theme.surface, in: RoundedRectangle(cornerRadius: theme.radius(10)))
        .overlay(RoundedRectangle(cornerRadius: theme.radius(10)).strokeBorder(theme.hairline))
        .animation(.easeInOut(duration: 0.18), value: doodle)
        .accessibilityHidden(true)   // the row under it says what it shows
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
                .clipShape(RoundedRectangle(cornerRadius: theme.radius(7)))
                .overlay(RoundedRectangle(cornerRadius: theme.radius(7)).strokeBorder(theme.hairline))
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
                    in: RoundedRectangle(cornerRadius: theme.radius(11)))
        .overlay(RoundedRectangle(cornerRadius: theme.radius(11))
            .strokeBorder(selected ? theme.ink.opacity(0.3) : .clear))
        .contentShape(Rectangle())
    }

    @ViewBuilder private var preview: some View {
        switch mode {
        case .system:   HStack(spacing: 0) { page(.light, as: .system); page(.dark, as: .system) }
        case .midnight: page(.midnight, as: .midnight)
        case .umber:    page(.umber, as: .umber)
        }
    }

    /// Each page in the face it would really get: Midnight's in the sans, the rest
    /// in the serif or the marker — not all four in whichever face is on right now.
    private func page(_ t: Theme, as mode: Appearance) -> some View {
        var look = doodle
        look.appearance = mode
        return VStack(alignment: .leading, spacing: 5) {
            Text("Aa")
                .font(look.face(15))
                .foregroundStyle(t.ink)
            Capsule().fill(t.muted).frame(width: 26, height: 2)
            Capsule().fill(t.rule).frame(width: 17, height: 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(8)
        .background {
            // A miniature of the ground, not the ground itself: the real band is
            // taller than this whole tile and would fill it with flat blue.
            ZStack {
                t.background
                if t.glow != .clear {
                    LinearGradient(colors: [t.glow, t.glow.opacity(0)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(PremiumViewModel())
}
