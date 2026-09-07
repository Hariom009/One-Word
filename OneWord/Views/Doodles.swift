//
//  Doodles.swift
//  OneWord
//
//  How the doodle theme draws: one symbol (`GlyphIcon`), which reads `\.doodle`
//  itself, so a call site asks for the meaning — "home" — and never for a set.
//  Turning the switch off is then a property change inside this view rather than
//  an `if` at every place the app happens to draw a glyph. The wait
//  (`BusyOverlay`) lives here too, next to the only other chrome the app draws.
//
//  Dumb views: they hold no preference of their own.
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

/// The whole-window wait: the screen dims and a system spinner sits over it,
/// swallowing clicks until the work lands. Only for the round trips the reader
/// must not interrupt — sign-in and a feedback send. Short in-place waits (the
/// related-words index) use a small `ProgressView` inline instead.
struct BusyOverlay: View {
    let theme: Theme

    var body: some View {
        ZStack {
            theme.background.opacity(0.7)
            ProgressView()
        }
        .ignoresSafeArea()
        // Rectangle, not the default shape: the tint alone doesn't take hits, and
        // the point is that nothing underneath does either.
        .contentShape(Rectangle())
        .transition(.opacity)
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }
}

extension View {
    /// Dims and blocks the view while `busy` is true.
    func busy(_ busy: Bool, theme: Theme) -> some View {
        overlay {
            if busy { BusyOverlay(theme: theme) }
        }
        .animation(.easeInOut(duration: 0.15), value: busy)
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
            }
            .environment(\.doodle, DoodleTheme(icons: on, handwriting: on))
        }
    }
    .padding(30)
}
