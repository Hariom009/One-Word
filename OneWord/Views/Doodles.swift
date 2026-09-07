//
//  Doodles.swift
//  OneWord
//
//  How the doodle theme draws: one symbol (`GlyphIcon`) and one wait
//  (`DoodleLoader`). Both read `\.doodle` themselves, so a call site asks for the
//  meaning — "home", "the loader" — and never for a set. Turning the switch off is
//  then a property change inside these two views rather than an `if` at every
//  place the app happens to draw a glyph.
//
//  Dumb views: they hold no preference of their own, only the animation state the
//  camper needs to keep rolling.
//

import SwiftUI

// MARK: - A symbol

/// One symbol, in whichever set is on.
///
/// `size` is the SF Symbol's font size — the number the call site used before the
/// theme existed, so classic mode still draws exactly what it always drew. Both
/// sets are then centred in the same box, so flipping the switch swaps the picture
/// without re-laying out the row around it.
struct GlyphIcon: View {
    let glyph: Glyph
    var size: CGFloat = 13
    /// SF Symbol weight only. The drawings come in one weight — their own.
    var weight: Font.Weight = .regular
    /// Forces the paper chip on for a drawing that sits on something dark in BOTH
    /// themes — a book cover. nil lets `Doodle` read the scheme, which is right
    /// everywhere the background is the page.
    var plated: Bool?
    @Environment(\.doodle) private var doodle

    init(_ glyph: Glyph, size: CGFloat = 13,
         weight: Font.Weight = .regular, plated: Bool? = nil) {
        self.glyph = glyph
        self.size = size
        self.weight = weight
        self.plated = plated
    }

    /// A drawing fills its canvas; an SF Symbol sits well inside its font size. The
    /// ratio is what makes the two read as the same size rather than measure as it.
    private var box: CGFloat { size * 1.32 }

    var body: some View {
        Group {
            if doodle.icons, let asset = glyph.doodle {
                Doodle(asset, size: box, plated: plated)
            } else {
                Image(systemName: glyph.symbol)
                    .font(.system(size: size, weight: weight))
            }
        }
        .frame(width: box, height: box)
    }
}

/// A drawing at a given box size.
///
/// The doodles are black line art with flat colour inside, so on night black the
/// outlines — and anything black *within* them, like the tick inside the check's
/// green ring — disappear into the page. They get a thin light halo there: a
/// blurred copy of the drawing's own silhouette, so every stroke picks up a pale
/// rim and nothing else changes. No chip — a paper square behind a stamp read as
/// a white box on the dark page.
struct Doodle: View {
    let asset: String
    let size: CGFloat
    /// nil = decide from the scheme. Pass true where the drawing sits on something
    /// dark in both themes, false where it never needs the halo.
    var plated: Bool?
    @Environment(\.colorScheme) private var scheme

    init(_ asset: String, size: CGFloat, plated: Bool? = nil) {
        self.asset = asset
        self.size = size
        self.plated = plated
    }

    var body: some View {
        Image(asset)
            .resizable()
            .interpolation(.high)   // 96pt source, drawn small — never let it alias
            .scaledToFit()
            .padding(size * 0.07)
            .frame(width: size, height: size)
            .shadow(color: .white.opacity(plated ?? (scheme == .dark) ? 0.85 : 0),
                    radius: max(0.6, size * 0.035))
    }
}

// MARK: - A wait

/// The wait, in the doodle theme's language: the camper rolling, with the road
/// running out from under it. Falls back to the system spinner when the drawings
/// are off, so a caller only ever asks for "the loader" and gets whichever one the
/// reader chose.
///
/// The app waits in exactly two places — the sign-in round trip and the ~2.4s
/// related-words index build — and both are short, so this never runs for long.
struct DoodleLoader: View {
    /// The camper's height. The road sizes itself from it.
    var size: CGFloat = 30
    /// The road only earns its space at pane size; inside a button there is none.
    var road = true
    @Environment(\.doodle) private var doodle
    @State private var bobbing = false
    @State private var rolling = false

    var body: some View {
        if doodle.icons {
            camper
                .accessibilityElement()
                .accessibilityLabel("Loading")
        } else {
            ProgressView()
                .controlSize(road ? .regular : .small)
        }
    }

    private var camper: some View {
        VStack(spacing: size * 0.1) {
            Doodle("camper_doodle", size: size)
                // A small forth-and-back sway, centred over the road, reads as the
                // camper travelling; a vertical bob just looks like it's hopping.
                .offset(x: bobbing ? size * 0.06 : -size * 0.06)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                           value: bobbing)
            if road { roadway }
        }
        .onAppear {
            bobbing = true
            rolling = true
        }
    }

    /// Dashes sliding left by exactly one dash-and-gap, forever — so the loop point
    /// lands on an identical frame and the road never appears to jump back.
    private var roadway: some View {
        let pitch = size * 0.36
        let thickness = max(1.5, size * 0.055)
        return HStack(spacing: pitch * 0.55) {
            ForEach(0..<8, id: \.self) { _ in
                Capsule().frame(width: pitch * 0.45, height: thickness)
            }
        }
        .foregroundStyle(.secondary)
        .fixedSize()
        .offset(x: rolling ? -pitch : 0)
        .animation(.linear(duration: 0.5).repeatForever(autoreverses: false), value: rolling)
        .frame(width: size, height: thickness, alignment: .center)
        .clipped()
    }
}

private let previewGlyphs: [Glyph] = [.home, .history, .practice, .bookmarks,
                                      .dictionaries, .learned, .selected,
                                      .bookmarked, .search, .settings]

#Preview("Glyphs") {
    VStack(alignment: .leading, spacing: 22) {
        ForEach([false, true], id: \.self) { on in
            HStack(spacing: 14) {
                ForEach(Array(previewGlyphs.enumerated()), id: \.offset) { _, g in
                    GlyphIcon(g, size: 15)
                }
                DoodleLoader(size: 26)
            }
            .environment(\.doodle, DoodleTheme(icons: on, handwriting: on))
        }
    }
    .padding(30)
}
