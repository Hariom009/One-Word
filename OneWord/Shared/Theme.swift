//
//  Theme.swift
//  OneWord — Shared (app + widget)
//
//  Light and Dark are monochrome: white paper / black night, everything on it a
//  gray between the two. Midnight is the one palette with a hue in it — a near-black
//  ground under a band of deep blue, frosted tiles, a light-blue accent — and only
//  the app paints with it (DoodleTheme.swift's `Theme.of(_:_:)`). The widget reads
//  no Theme at all: it paints black or white by the scheme, and is in this file's
//  audience only for `Font.serif`. So nothing app-only may be named here. Umber is
//  the other painted palette: warm, flat and opaque, with no glow at all.
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
    let accent: Color       // emphasis — ink, not a hue (Midnight's is a light blue)
    let rule: Color         // the Hindi left border
    let hairline: Color     // dividers
    /// Corner multiplier. 1 draws every radius exactly as its call site wrote it;
    /// Midnight's big tiles and pill controls are those same call sites, scaled.
    var roundness: CGFloat = 1
    /// A light across the top of each pane, painted under its content by
    /// `paneBackground(_:)`. This is the band's peak colour, drawn opaque at the top
    /// edge and faded out below it. Clear draws none.
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
    /// A neutral near-black ground with a band of deep blue across its top edge.
    /// Surfaces are white laid over that ground rather than greys of their own, which
    /// is what keeps a tile reading as frosted glass instead of a grey box — over the
    /// band a tile picks the blue up. The price of a see-through surface: anything
    /// outside the app's own windows (a popover) must paint `background` under it.
    static let midnight = Theme(
        background: Color(hex: 0x0F0F0F),
        surface:    Color.white.opacity(0.07),
        ink:        Color(hex: 0xFBFBFC),
        muted:      Color.white.opacity(0.55),
        definition: Color.white.opacity(0.86),
        example:    Color.white.opacity(0.7),
        accent:     Color(hex: 0xA8C7FA),
        rule:       Color(hex: 0xA8C7FA).opacity(0.6),
        hairline:   Color.white.opacity(0.08),
        roundness:  2.2,
        glow:       Color(hex: 0x15204E),
        tiles:      true
    )

    /// Dark-only, and Midnight's opposite on every axis: where that one gets its depth
    /// from light — a band, glass over it — this one gets it from temperature, and
    /// nothing glows or floats. A warm charcoal lifted just off black so it reads as
    /// stock rather than void, parchment ink, and one hue, brass, spent on the Hindi
    /// rule. It keeps the serif, the hairlines and the corners as drawn, so roundness,
    /// glow and tiles are left at their defaults on purpose. Surfaces are opaque.
    static let umber = Theme(
        background: Color(hex: 0x161412),
        surface:    Color(hex: 0x1F1C19),
        ink:        Color(hex: 0xEDE6DA),
        muted:      Color(hex: 0x9C9284),
        definition: Color(hex: 0xDDD5C8),
        example:    Color(hex: 0xB9AFA0),
        accent:     Color(hex: 0xD0A667),
        rule:       Color(hex: 0xD0A667).opacity(0.55),
        hairline:   Color(hex: 0xEDE6DA).opacity(0.10)
    )

    static func of(_ scheme: ColorScheme) -> Theme { scheme == .dark ? .dark : .light }
}

/// A pane's ground: the palette's background and, where the palette has a glow, a
/// band of it across the top edge. A view of its own so the sidebar can paint the
/// same ground the panes do.
struct PaneGround: View {
    let t: Theme

    /// In points, never a share of the bounds. `PaneHeader` paints this same ground
    /// again in a 52pt strip over the pane, and the two only meet without a seam if
    /// the band is the same size in both. There is no x in it either, so the
    /// sidebar's copy meets the pane's at any column width — and nothing re-centres
    /// while the sidebar folds.
    private static let bandHeight: CGFloat = 330

    var body: some View {
        t.background
            .overlay(alignment: .top) {
                if t.glow != .clear {
                    // Plain alpha, no blend mode. Full at the edge, half by 45% of
                    // the band, gone at its foot — and faded to the glow at zero
                    // opacity rather than to `.clear`, which drags the ramp
                    // through grey on the way down.
                    LinearGradient(stops: [.init(color: t.glow, location: 0),
                                           .init(color: t.glow.opacity(0.5), location: 0.45),
                                           .init(color: t.glow.opacity(0), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: Self.bandHeight)
                }
            }
            // The band is taller than the header strip. Unclipped, the header's copy
            // would spill down over the content scrolling beneath it.
            .clipped()
            .ignoresSafeArea()
            // `.clipped()` clips what is drawn, not what is hit: the header's copy of
            // the band still took every click in the 278pt below its strip, so in
            // Midnight nothing near the top of a pane could be pressed. A ground never
            // needs a click; the header's drag area is a separate view.
            .allowsHitTesting(false)
    }
}

extension View {
    /// Paints `PaneGround` under this pane. Under the content on purpose — the glow
    /// was first a blend-mode overlay across the whole detail pane, and that
    /// re-composites everything beneath it on every frame that moves: scrolls,
    /// pushes, pane switches.
    func paneBackground(_ t: Theme) -> some View {
        background { PaneGround(t: t) }
    }
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
