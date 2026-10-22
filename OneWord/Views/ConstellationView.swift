//
//  ConstellationView.swift
//  OneWord
//
//  The "same vein" box drawn as a graph: the word in a pill at the centre, its
//  nearest words on one even ring around it, a spoke to each. Every label sits on
//  the far side of its dot from the centre, so no spoke ever crosses text. A star
//  doesn't open a page: rest the cursor on it, or click it, for a card with its
//  meaning; double-click to copy the word for Search.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct ConstellationView: View {
    let word: Word
    /// The neighbours, nearest first — the list's ranking, so its three lead here.
    let ring: [Word]
    let t: Theme
    @Environment(\.doodle) private var doodle

    /// The star whose card is up. `pinned` when a click put it there — then moving
    /// the cursor off doesn't take it down; a second click does.
    @State private var active: Word?
    @State private var pinned = false
    @State private var dwell: Task<Void, Never>?
    /// The word just copied, for the toast; cleared by the toast's own timer.
    @State private var copied: String?
    @State private var toastTimer: Task<Void, Never>?
    /// The centre pill's drawn size, so each spoke can start at its outline.
    @State private var pill: CGSize = .zero

    // ponytail: one ring, not two — a second ring of phrase-length terms can't fit a
    // 700pt column without labels colliding. Room for a label beside a side star:
    private let labelWidth: CGFloat = 170
    private let height: CGFloat = 360

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            // A circle, as wide as the side labels allow and as tall as the box does.
            let radius = min(size.width / 2 - labelWidth - 24, size.height / 2 - 40)
            let points = ring.indices.map { i in
                CGPoint(x: centre.x + radius * cos(angle(i)), y: centre.y + radius * sin(angle(i)))
            }
            ZStack {
                Canvas { context, _ in
                    for (i, p) in points.enumerated() {
                        let lit = active == ring[i] || active == word
                        var path = Path()
                        // From the pill's outline, not its middle: the line meets the
                        // word's edge instead of running in behind it.
                        path.move(to: edge(toward: p, from: centre, size: pill))
                        path.addLine(to: p)
                        context.stroke(path, with: .color(lit ? t.accent.opacity(0.8) : t.muted.opacity(0.3)),
                                       lineWidth: lit ? 1.5 : 1)
                    }
                }
                .accessibilityHidden(true)

                ForEach(Array(ring.enumerated()), id: \.element.id) { i, w in
                    star(w, at: points[i], angle: angle(i))
                }
                // On top of the spokes: the pill is solid, so they start at its edge.
                centrePill.position(centre)

                // Last in the stack, so the card sits over every star and line.
                if let active {
                    let at = ring.firstIndex(of: active).map { points[$0] } ?? centre
                    card(active)
                        .frame(width: 240)
                        .position(x: min(max(at.x, 124), size.width - 124), y: at.y)
                        // Above the star when there's room, below it near the top edge.
                        .offset(y: at.y > 110 ? -64 : 64)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.15), value: active)
        }
        .frame(height: height)
        .overlay(alignment: .bottom) {
            if let copied {
                Text("Copied \u{201C}\(copied)\u{201D} \u{2014} paste it into Search")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(t.background)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(t.ink.opacity(0.9), in: Capsule())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .animation(.spring(duration: 0.3), value: copied)
        // A new word under the graph (New Word, a day step) takes any card down with
        // it. No entrance animation of our own: it hung visibility on `.onAppear`, which
        // a macOS DisclosureGroup doesn't reliably send when it expands — the graph sat
        // at opacity 0 until the next word. WordDetail already cross-fades a new word.
        .onChange(of: word.term) { active = nil; pinned = false }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Words connected to \(word.term)")
    }

    /// Where the line from `c` toward `p` leaves a capsule of `size` centred on `c`:
    /// the flat top or bottom if it gets there first, else the round end.
    private func edge(toward p: CGPoint, from c: CGPoint, size: CGSize) -> CGPoint {
        let dx = p.x - c.x, dy = p.y - c.y, len = hypot(dx, dy)
        guard len > 0, size.height > 0 else { return c }
        let ux = dx / len, uy = dy / len
        let r = size.height / 2, a = max(size.width / 2 - r, 0)
        var d = abs(uy) > 0 ? r / abs(uy) : .infinity
        if abs(d * ux) > a {
            // The round end: a circle of radius r centred `a` out along the axis.
            let cx = ux >= 0 ? a : -a
            let b = ux * cx
            d = b + sqrt(max(b * b - cx * cx + r * r, 0))
        }
        return CGPoint(x: c.x + ux * min(d, len), y: c.y + uy * min(d, len))
    }

    /// Evenly round the circle, the nearest word at twelve o'clock.
    private func angle(_ i: Int) -> Double {
        -.pi / 2 + 2 * .pi * Double(i) / Double(max(ring.count, 1))
    }

    /// The word itself: its term in a solid pill sized to the text, ringed in accent.
    private var centrePill: some View {
        gestures(word, on: Text(word.term)
            .font(doodle.face(19))
            .foregroundStyle(t.ink)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background {
                Capsule().fill(t.background)
                Capsule().fill(t.accent.opacity(0.14))
            }
            .overlay(Capsule().strokeBorder(t.accent.opacity(0.7), lineWidth: 1.2))
            .contentShape(Capsule())
            .onGeometryChange(for: CGSize.self, of: \.size) { pill = $0 })
    }

    /// A dot on the ring with its label on the outward side: right of the dot on the
    /// right half, left of it on the left, above or below at the top and bottom.
    private func star(_ w: Word, at p: CGPoint, angle: Double) -> some View {
        let on = active == w
        let dx = cos(angle), dy = sin(angle)
        let side = abs(dx) > 0.35   // beside the dot, rather than above or below it
        let label = Text(w.term)
            .font(.system(size: 13, weight: on ? .semibold : .regular))
            .foregroundStyle(on ? t.ink : t.ink.opacity(0.75))
            .lineLimit(1)
            .truncationMode(.tail)
            // The text's own box answers the cursor, not the empty width beside it.
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .frame(width: side ? labelWidth : labelWidth * 1.4,
                   alignment: side ? (dx > 0 ? .leading : .trailing) : .center)
        let offset = side
            ? CGSize(width: (dx > 0 ? 1 : -1) * (labelWidth / 2 + 12), height: 0)
            : CGSize(width: 0, height: dy > 0 ? 18 : -18)
        return gestures(w, on: ZStack {
            Circle()
                .fill(on ? t.accent : t.ink.opacity(0.6))
                .frame(width: on ? 10 : 8, height: on ? 10 : 8)
                .frame(width: 24, height: 24)
                .contentShape(Circle())
            label.offset(offset)
        }
        .frame(width: 24, height: 24))
        .position(p)
    }

    /// One set of gestures for every star. Double first: SwiftUI holds the single
    /// click until a double is ruled out.
    private func gestures(_ w: Word, on view: some View) -> some View {
        view
            .onTapGesture(count: 2) { copy(w) }
            .onTapGesture {
                dwell?.cancel()
                if pinned && active == w { active = nil; pinned = false } else { active = w; pinned = true }
            }
            .onHover { inside in
                dwell?.cancel()
                if inside {
                    // ponytail: 0.45s dwell is a feel knob — shorter fires on every pass.
                    dwell = Task {
                        try? await Task.sleep(for: .milliseconds(450))
                        guard !Task.isCancelled else { return }
                        active = w; pinned = false
                    }
                } else if active == w && !pinned {
                    active = nil
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(w.spokenSummary)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double-tap to copy the word")
            .accessibilityAction(named: "Copy") { copy(w) }
    }

    /// The meaning, short: the term and two lines of its definition.
    /// A solid grey-white card with dark ink in every appearance — `t.surface` is
    /// see-through in Midnight, and the stars and lines behind bled into the text.
    private func card(_ w: Word) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(w.term)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(white: 0.1))
            if !w.definition.isEmpty {
                Text(w.definition)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.22))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.95), in: RoundedRectangle(cornerRadius: t.radius(10)))
        .overlay(RoundedRectangle(cornerRadius: t.radius(10)).strokeBorder(Color.black.opacity(0.08)))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }

    private func copy(_ w: Word) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(w.term, forType: .string)
        #else
        UIPasteboard.general.string = w.term
        #endif
        active = nil; pinned = false
        copied = w.term
        toastTimer?.cancel()
        toastTimer = Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            copied = nil
        }
    }
}

extension Word {
    /// One VoiceOver utterance covering everything a related-word row shows.
    var spokenSummary: String {
        [term, partOfSpeech, definition].filter { !$0.isEmpty }.joined(separator: ". ")
    }
}
