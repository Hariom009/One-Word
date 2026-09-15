//
//  Theme.swift
//  OneWord — Shared (app + widget)
//
//  Light and Dark are monochrome: white paper / black night, everything on it a
//  gray between the two. Midnight is the one palette with a hue in it — a navy
//  ground, frosted tiles, a periwinkle accent — and only the app paints with it
//  (DoodleTheme.swift's `Theme.of(_:_:)`). The widget resolves Theme.of(colorScheme).
//  ponytail: uses the system serif (New York) for headwords; bundle Newsreader +
//  Tiro Devanagari fonts later for pixel-exact type.
//

import SwiftUI

struct Theme {
    let background: Color   // paper / night
    let surface: Color      // fields, pickers
    let ink: Color          // primary text / headword
    let muted: Color        // part of speech, labels
    let definition: Color
    let example: Color
    let accent: Color       // emphasis — ink, not a hue (Midnight's is periwinkle)
    let rule: Color         // the Hindi left border
    let hairline: Color     // dividers
    /// Corner multiplier. 1 draws every radius exactly as its call site wrote it;
    /// Midnight's big tiles and pill controls are those same call sites, scaled.
    var roundness: CGFloat = 1
    /// A light at the top of the reading pane. Clear draws none.
    var glow: Color = .clear
    /// Entry sections as filled tiles rather than blocks under a hairline.
    var tiles = false

    /// A corner radius as this palette rounds it. SwiftUI clamps a radius to half
    /// the shape's short side, so past that a small control simply becomes a pill.
    func radius(_ r: CGFloat) -> CGFloat { r * roundness }

    static let light = Theme(
        background: .white,
        surface:    Color(hex: 0xF4F4F4),
        ink:        .black,
        muted:      Color(hex: 0x757575),
        definition: Color(hex: 0x1C1C1C),
        example:    Color(hex: 0x4A4A4A),
        accent:     .black,
        rule:       Color(hex: 0xBDBDBD),
        hairline:   Color.black.opacity(0.11)
    )

    static let dark = Theme(
        background: .black,
        surface:    Color(hex: 0x1A1A1A),
        ink:        .white,
        muted:      Color(hex: 0x9A9A9A),
        definition: Color(hex: 0xE4E4E4),
        example:    Color(hex: 0xBDBDBD),
        accent:     .white,
        rule:       Color(hex: 0x5E5E5E),
        hairline:   Color.white.opacity(0.11)
    )

    /// Dark-only: choosing Midnight forces the dark scheme, so it has no paper half.
    /// Surfaces are white laid over the navy rather than greys of their own, which
    /// is what keeps a tile reading as frosted glass instead of a grey box.
    static let midnight = Theme(
        background: Color(hex: 0x080F1B),
        surface:    Color.white.opacity(0.09),
        ink:        Color(hex: 0xFBFBFC),
        muted:      Color.white.opacity(0.55),
        definition: Color.white.opacity(0.86),
        example:    Color.white.opacity(0.7),
        accent:     Color(hex: 0xA5B4FC),
        rule:       Color(hex: 0xA5B4FC).opacity(0.6),
        hairline:   Color.white.opacity(0.08),
        roundness:  2.2,
        glow:       Color(hex: 0x3B5BDB),
        tiles:      true
    )

    static func of(_ scheme: ColorScheme) -> Theme { scheme == .dark ? .dark : .light }
}

extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue:  Double(hex & 0xFF) / 255)
    }
}

extension Font {
    /// Editorial serif headword face (New York stands in for Newsreader).
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}
