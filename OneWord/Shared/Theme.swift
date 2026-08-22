//
//  Theme.swift
//  OneWord — Shared (app + widget)
//
//  Monochrome: white paper / black night, everything on it a gray between the
//  two. No hue anywhere. Resolve with Theme.of(colorScheme).
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
    let accent: Color       // emphasis — ink, not a hue
    let rule: Color         // the Hindi left border
    let hairline: Color     // dividers

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
