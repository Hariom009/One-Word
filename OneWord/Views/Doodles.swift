//
//  Doodles.swift
//  OneWord
//
//  The app's small chrome: one symbol (`GlyphIcon`), asked for by meaning —
//  "home" — and the wait (`BusyOverlay`).
//
//  Dumb views: they hold no preference of their own.
//

import SwiftUI

// MARK: - A symbol

/// One SF Symbol, centred in a box a little bigger than its font size, so rows
/// that lay out around it keep the spacing they were built with.
struct GlyphIcon: View {
    let glyph: Glyph
    var size: CGFloat = 13
    var weight: Font.Weight = .regular

    init(_ glyph: Glyph, size: CGFloat = 13, weight: Font.Weight = .regular) {
        self.glyph = glyph
        self.size = size
        self.weight = weight
    }

    private var box: CGFloat { size * 1.32 }

    var body: some View {
        Image(systemName: glyph.symbol)
            .font(.system(size: size, weight: weight))
            .frame(width: box, height: box)
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
