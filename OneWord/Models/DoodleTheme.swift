//
//  DoodleTheme.swift
//  OneWord
//
//  The doodle theme — two switches, not one. Hand-drawn glyphs and hand-drawn
//  lettering are separate tastes: some readers want the drawings next to the
//  editorial serif, some want the marker face next to the app's own symbols, and
//  some want the lot. So `icons` and `handwriting` are stored apart and read apart.
//
//  App-only, in the standard defaults (like `appearance`, unlike `showHindi`):
//  neither the doodle art nor the Pulpen face is in the widget's bundle, so an App
//  Group switch would promise the widget something it cannot draw.
//
//  Resolved once at the app root and handed down the environment, the way
//  `Theme.of(scheme)` is resolved at the top of every body. A static UserDefaults
//  read can't invalidate a view, so without the environment every pane would keep
//  whichever face it launched with until it happened to redraw for another reason.
//

import SwiftUI

// MARK: - What a symbol means

/// Every symbol the app draws through the theme, named for what it *means*
/// rather than for the glyph it happens to use — so the SF Symbol set and the
/// doodle set are two answers to one question and neither can drift from the other.
///
/// `doodle` is nil where the set has no drawing for that meaning: there is no
/// hand-drawn magnifier, gear or head. Those keep their symbol in both modes,
/// which is the reason this is one table rather than two parallel enums — the art
/// arriving later is a single string, here, and nothing else moves.
enum Glyph {
    case home, history, practice, bookmarks, dictionaries
    case search, settings, profile, feedback
    case learned, selected, bookmarked

    /// The SF Symbol. Always present — it is what the app has always drawn.
    var symbol: String { art.symbol }

    /// The asset in `Assets.xcassets`, or nil when the set has no drawing for this.
    var doodle: String? { art.doodle }

    /// One table rather than two switches: a new meaning is a case above and a row
    /// here, and the drawing can never end up labelled with the wrong symbol.
    private var art: (symbol: String, doodle: String?) {
        switch self {
        case .home:         ("house", "house_doodle")
        case .history:      ("clock", "calender_doodle")       // the typo is the asset's
        case .practice:     ("text.bubble", "write_doodle")
        case .bookmarks:    ("bookmark", "bookmark_doodle")
        case .dictionaries: ("book", "dictionary_doodle")
        case .search:       ("magnifyingglass", nil)
        case .settings:     ("gearshape", nil)
        case .profile:      ("person.crop.circle", nil)
        case .feedback:     ("bubble.left", nil)
        case .learned:      ("checkmark.seal", "check_doodle")
        case .selected:     ("checkmark.circle.fill", "check_doodle")
        case .bookmarked:   ("bookmark.fill", "bookmark_doodle")
        }
    }
}

// MARK: - The theme

/// Which half of the doodle theme is on. A value, not a store: `OneWordApp` reads
/// the two defaults and puts one of these in the environment.
nonisolated struct DoodleTheme: Equatable {
    /// Hand-drawn drawings in place of SF Symbols.
    var icons = false
    /// Pulpen Snowman in place of the editorial serif.
    var handwriting = false

    /// The app as it has always looked, and the right default for a `#Preview`
    /// that doesn't say otherwise.
    static let off = DoodleTheme()

    /// Named once so the Settings switches, the app root and the capture HUD
    /// cannot disagree about which key they are reading.
    static let iconsKey = "doodleIcons"
    static let handwritingKey = "doodleFont"

    /// For the one place that is outside the SwiftUI environment: the capture HUD,
    /// which AppKit puts on screen in a window of its own.
    static var current: DoodleTheme {
        DoodleTheme(icons: UserDefaults.standard.bool(forKey: iconsKey),
                    handwriting: UserDefaults.standard.bool(forKey: handwritingKey))
    }

    // MARK: The face

    /// Pulpen Snowman's PostScript names — not the family name, which resolves to
    /// Regular for both weights and would silently ignore the light request.
    private static let regularFace = "PulpenSnowmanRegular"
    private static let lightFace = "PulpenSnowmanLight"

    /// Measured, not guessed: at the same point size Pulpen's caps stand 0.795em
    /// against New York's 0.705em, so asking for 22 would draw 13% larger than
    /// every layout on the page was spaced for. 0.92 lands the two cap heights on
    /// each other and leaves the marker face a hair of the generosity it wants.
    private static let opticalScale: CGFloat = 0.92

    /// The app's display face at `size` — the one seam, so a headword, an
    /// empty-state headline and the wordmark can never end up in different faces.
    ///
    /// `fixedSize:`, not `size:`, to match what it replaces: `Font.serif` is
    /// `.system(size:)`, which does not scale with Dynamic Type. `.custom(_:size:)`
    /// does, and flipping the switch would quietly change more than the face.
    ///
    /// Pulpen carries Latin, digits and curly quotes but no Devanagari and no
    /// em-dash; CoreText falls those back to the system face on its own, so the
    /// Hindi line stays readable rather than turning into a row of boxes.
    func face(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        guard handwriting else { return .serif(size, weight) }
        let light = weight == .light || weight == .ultraLight || weight == .thin
        return .custom(light ? Self.lightFace : Self.regularFace,
                       fixedSize: size * Self.opticalScale)
    }
}

// MARK: - Environment

private struct DoodleThemeKey: EnvironmentKey {
    nonisolated static let defaultValue = DoodleTheme.off
}

extension EnvironmentValues {
    /// Which half of the doodle theme is on. Read it at the top of a body beside
    /// `Theme.of(scheme)` — the two answer the same kind of question.
    var doodle: DoodleTheme {
        get { self[DoodleThemeKey.self] }
        set { self[DoodleThemeKey.self] = newValue }
    }
}
