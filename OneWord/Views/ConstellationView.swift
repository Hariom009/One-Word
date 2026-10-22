//
//  ConstellationView.swift
//  OneWord
//
//  The "same vein" box drawn as a graph: the word in the middle, its neighbours on
//  an inner ring, theirs on an outer one, joined by hairlines. Premium's view of the
//  same ranking the list shows. A star doesn't open a page: rest the cursor on it, or
//  click it, for a card with its meaning; double-click to copy the word for Search.
//

import SwiftUI
import AppKit

struct ConstellationView: View {
    let word: Word
    let graph: Constellation
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

    // ponytail: fixed rings, not a force layout — 6 + 12 stars never need one.
    // Labels can brush on a long-phrase book; nudge the ring radii if they grate.
    private let height: CGFloat = 400
    /// The graph grows out of its centre when it opens and when the word changes.
    @State private var shown = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let centre = CGPoint(x: size.width / 2, y: size.height / 2)
            let inner = graph.inner.indices.map { innerPoint($0, size) }
            let outer = graph.outer.indices.map { outerPoint($0, size) }
            ZStack {
                // Lines first and end to end, centre to centre: the pills above are
                // solid, so each line seems to start at a pill's edge, never inside text.
                Canvas { context, _ in
                    for (i, p) in outer.enumerated() {
                        let lit = active == graph.outer[i] || active == graph.inner[graph.parents[i]]
                        context.stroke(line(inner[graph.parents[i]], p),
                                       with: .color(lit ? t.accent.opacity(0.8) : t.muted.opacity(0.28)),
                                       lineWidth: lit ? 1.4 : 1)
                    }
                    for (i, p) in inner.enumerated() {
                        let lit = active == graph.inner[i] || active == word
                        context.stroke(line(centre, p),
                                       with: .color(t.accent.opacity(lit ? 0.85 : 0.4)),
                                       lineWidth: lit ? 1.6 : 1.2)
                    }
                }
                .accessibilityHidden(true)

                ForEach(Array(graph.outer.enumerated()), id: \.element.id) { i, w in
                    outerStar(w, above: outer[i].y < centre.y)
                        // The dot, not the stack, lands on the point: label 15 + gap 6.
                        .position(x: outer[i].x, y: outer[i].y + (outer[i].y < centre.y ? -10.5 : 10.5))
                }
                ForEach(Array(graph.inner.enumerated()), id: \.element.id) { i, w in
                    pill(w, font: doodle.face(15), lit: false)
                        .position(inner[i])
                }
                pill(word, font: doodle.face(21), lit: true)
                    .position(centre)

                // Last in the stack, so the card sits over every star and line.
                if let active, let at = point(of: active, centre, inner, outer) {
                    card(active)
                        .frame(width: 240)
                        .position(x: min(max(at.x, 124), size.width - 124), y: at.y)
                        // Above the star when there's room, below it at the top edge.
                        .offset(y: at.y > 110 ? -70 : 70)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.15), value: active)
        }
        .frame(height: height)
        .scaleEffect(shown ? 1 : 0.92)
        .opacity(shown ? 1 : 0)
        .onAppear { withAnimation(.spring(duration: 0.5, bounce: 0.2)) { shown = true } }
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
        // it, and the new neighbourhood grows in rather than snapping.
        .onChange(of: word.term) {
            active = nil; pinned = false
            shown = false
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) { shown = true }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Words connected to \(word.term)")
    }

    /// The centre and the inner ring: the term in a solid pill. Solid on purpose —
    /// the lines run underneath and stop at its edge. `lit` is the centre's: the
    /// accent ring and its glow say which word all this hangs from.
    private func pill(_ w: Word, font: Font, lit: Bool) -> some View {
        let on = lit || active == w
        return gestures(w, on: Text(w.term)
            .font(font)
            .tracking(doodle.tracking(lit ? 21 : 15))
            .foregroundStyle(t.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: lit ? 220 : 150)
            .padding(.horizontal, lit ? 18 : 13)
            .padding(.vertical, lit ? 9 : 6)
            .background {
                Capsule().fill(t.background)
                Capsule().fill((lit ? t.accent : t.ink).opacity(lit ? 0.16 : 0.06))
            }
            .overlay(Capsule().strokeBorder(on ? t.accent.opacity(0.8) : t.ink.opacity(0.16),
                                            lineWidth: lit ? 1.4 : 1))
            .shadow(color: lit ? t.accent.opacity(0.35) : .clear, radius: 14)
            .scaleEffect(active == w && !lit ? 1.06 : 1)
            .contentShape(Capsule()))
    }

    /// The outer ring: a small dot, its label on the side away from the centre so
    /// the line coming in from its parent never crosses the text.
    private func outerStar(_ w: Word, above: Bool) -> some View {
        let on = active == w
        let label = Text(w.term)
            .font(.system(size: 12, weight: on ? .semibold : .regular))
            .foregroundStyle(on ? t.ink : t.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: 130)
            .frame(height: 15)
        return gestures(w, on: VStack(spacing: 6) {
            if above { label }
            Circle()
                .fill(on ? t.accent : t.muted.opacity(0.8))
                .frame(width: 6, height: 6)
            if !above { label }
        }
        .padding(4)
        .contentShape(Rectangle()))
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
            .animation(.easeOut(duration: 0.15), value: active)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(w.spokenSummary)
            .accessibilityAddTraits(.isButton)
            .accessibilityHint("Double-tap to copy the word")
            .accessibilityAction(named: "Copy") { copy(w) }
    }

    /// The meaning, short: two lines of the English definition.
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
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(w.term, forType: .string)
        active = nil; pinned = false
        copied = w.term
        toastTimer?.cancel()
        toastTimer = Task {
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            copied = nil
        }
    }

    /// Where a star sits, for its card. Looked up by term: the centre, then the rings.
    private func point(of w: Word, _ centre: CGPoint, _ inner: [CGPoint], _ outer: [CGPoint]) -> CGPoint? {
        if w == word { return centre }
        if let i = graph.inner.firstIndex(of: w) { return inner[i] }
        return graph.outer.firstIndex(of: w).map { outer[$0] }
    }

    private func line(_ a: CGPoint, _ b: CGPoint) -> Path {
        Path { $0.move(to: a); $0.addLine(to: b) }
    }

    /// Inner ring: evenly round an ellipse, the first star at twelve o'clock.
    private func innerAngle(_ i: Int) -> Double {
        -.pi / 2 + 2 * .pi * Double(i) / Double(max(graph.inner.count, 1))
    }

    private func innerPoint(_ i: Int, _ size: CGSize) -> CGPoint {
        clamp(point(innerAngle(i), rx: size.width * 0.27, ry: size.height * 0.25, size), size, x: 85, y: 24)
    }

    /// Outer ring: a parent's children fan either side of the parent's own bearing.
    private func outerPoint(_ i: Int, _ size: CGSize) -> CGPoint {
        let parent = graph.parents[i]
        let siblings = graph.parents.indices.filter { graph.parents[$0] == parent }
        let k = Double(siblings.firstIndex(of: i)!) - Double(siblings.count - 1) / 2
        let p = point(innerAngle(parent) + k * 0.5, rx: size.width * 0.43, ry: size.height * 0.4, size)
        return clamp(p, size, x: 65, y: 28)
    }

    private func point(_ angle: Double, rx: CGFloat, ry: CGFloat, _ size: CGSize) -> CGPoint {
        CGPoint(x: size.width / 2 + rx * cos(angle), y: size.height / 2 + ry * sin(angle))
    }

    /// Keeps a star's label whole inside the box: `x` is half the widest label.
    private func clamp(_ p: CGPoint, _ size: CGSize, x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: min(max(p.x, x), size.width - x), y: min(max(p.y, y), size.height - y))
    }
}
extension Word {
    /// One VoiceOver utterance covering everything a related-word row shows.
    var spokenSummary: String {
        [term, partOfSpeech, definition].filter { !$0.isEmpty }.joined(separator: ". ")
    }
}
