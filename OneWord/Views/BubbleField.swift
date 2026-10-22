//
//  BubbleField.swift
//  OneWord
//
//  The "same vein" graph: the word and its nearest words as a honeycomb
//  of bubbles you drag around. A bubble swells as it passes the middle and shrinks
//  toward the rim, so the field reads as a dome under the glass, and whichever sits
//  in the middle has its meaning spelled out beneath. The word itself is the
//  scalloped one, in ink. A tick under the finger each time a new bubble takes the
//  middle; three quiet seconds and the field drifts home — unless a tap is holding
//  a bubble there.
//
//  Nearest sits nearest: the first ring is the six closest words, the second the
//  next twelve, each ring starting at twelve o'clock. Colour says the same thing —
//  warm close in, cooler further out.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct BubbleField: View {
    let word: Word
    /// Nearest first. Up to 18 fill both rings; fewer leave the outer one open.
    let neighbours: [Word]
    let t: Theme
    @Environment(\.doodle) private var doodle
    @Environment(\.colorScheme) private var scheme

    /// Where the field rests (always on a bubble), and the finger's drag on top.
    @State private var pan: CGSize = .zero
    @State private var drag: CGSize = .zero
    /// A tap holds the middle bubble there; going home waits until it lets go.
    @State private var held = false
    @State private var homing: Task<Void, Never>?

    /// Centre to centre at rest, and a bubble's size at full swell.
    private static let pitch: CGFloat = 100
    private static let diameter: CGFloat = 92
    private let height: CGFloat = 380

    private var words: [Word] { [word] + neighbours }

    var body: some View {
        let spots = Self.honeycomb(words.count)
        let shift = CGSize(width: pan.width + drag.width, height: pan.height + drag.height)
        let focus = nearest(spots, to: shift)
        VStack(alignment: .leading, spacing: 14) {
            GeometryReader { geo in
                let c = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                ZStack {
                    ForEach(Array(words.enumerated()), id: \.element.id) { i, w in
                        let v = CGPoint(x: spots[i].x + shift.width, y: spots[i].y + shift.height)
                        let k = Self.swell(v)
                        // Shrunk bubbles are drawn in toward the middle too, so the
                        // rim packs as tight as the centre instead of opening gaps.
                        let pull = 0.72 + 0.28 * k
                        bubble(w, index: i, focused: i == focus)
                            .scaleEffect(k)
                            .position(x: c.x + v.x * pull, y: c.y + v.y * pull)
                            .zIndex(k)
                    }
                }
            }
            .frame(height: height)
            .contentShape(Rectangle())
            .gesture(field(spots))
            .mask(edgeFade)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Words connected to \(word.term)")

            meaning(words[focus])
        }
        .sensoryFeedback(.selection, trigger: focus)
        .sensoryFeedback(.impact(weight: .light), trigger: held)
        .onChange(of: word.term) { homing?.cancel(); pan = .zero; held = false }
    }

    // MARK: - Moving

    /// Drag the field; let go and it carries on by the gesture's own prediction,
    /// then settles with a bubble dead centre.
    private func field(_ spots: [CGPoint]) -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                homing?.cancel()
                held = false
                drag = value.translation
            }
            .onEnded { value in
                let aim = CGSize(width: pan.width + value.predictedEndTranslation.width,
                                 height: pan.height + value.predictedEndTranslation.height)
                let landing = spots[nearest(spots, to: aim)]
                withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                    pan = CGSize(width: -landing.x, height: -landing.y)
                    drag = .zero
                }
                goHomeSoon()
            }
    }

    /// A tap on another bubble brings it to the middle and holds it there; a tap on
    /// the held one lets go. The word itself just comes home.
    private func tap(_ i: Int, _ spots: [CGPoint]) {
        homing?.cancel()
        let focused = nearest(spots, to: pan) == i
        if focused && i != 0 {
            held.toggle()
            if !held { goHomeSoon() }
            return
        }
        withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
            pan = CGSize(width: -spots[i].x, height: -spots[i].y)
        }
        held = i != 0
    }

    /// Home to the word after three quiet seconds, never while a bubble is held.
    private func goHomeSoon() {
        homing?.cancel()
        guard !held, pan != .zero else { return }
        homing = Task {
            // ponytail: 3s is the user's number; a feel knob, not a rule.
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, !held else { return }
            withAnimation(.spring(duration: 0.9, bounce: 0.15)) { pan = .zero }
        }
    }

    /// The bubble closest to the middle of the box when the field is shifted by `shift`.
    private func nearest(_ spots: [CGPoint], to shift: CGSize) -> Int {
        spots.indices.min { a, b in
            hypot(spots[a].x + shift.width, spots[a].y + shift.height)
                < hypot(spots[b].x + shift.width, spots[b].y + shift.height)
        } ?? 0
    }

    // MARK: - Drawing

    private func bubble(_ w: Word, index i: Int, focused: Bool) -> some View {
        let main = i == 0
        return ZStack {
            if main {
                Scallop().fill(t.ink)
            } else {
                Circle().fill(Self.ramp(i - 1, of: neighbours.count, doodle.appearance, scheme))
            }
            VStack(spacing: 3) {
                if main { Image(systemName: "sparkle").font(.system(size: 11, weight: .semibold)) }
                Text(w.term)
                    .font(doodle.face(main ? 17 : 15))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
            }
            // Every ramp is light, so the neighbours all take dark ink; the word is ink
            // itself and takes the page.
            .foregroundStyle(main ? t.background : Color.black.opacity(0.82))
            .padding(.horizontal, 12)
        }
        .frame(width: Self.diameter, height: Self.diameter)
        .overlay {
            if focused && held {
                Circle().strokeBorder(t.ink.opacity(0.55), lineWidth: 2).padding(-5)
            }
        }
        .contentShape(Circle())
        .onTapGesture { tap(i, Self.honeycomb(words.count)) }
        .contextMenu {
            Button("Copy \u{201C}\(w.term)\u{201D}", systemImage: "doc.on.doc") { copy(w) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(w.spokenSummary)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(main ? "The word itself" : "Brings it to the middle and holds it")
    }

    /// The middle bubble's meaning. Fixed height, so the page under it doesn't jump
    /// as one-line and three-line definitions pass through.
    private func meaning(_ w: Word) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(w.term)
                        .font(doodle.face(20))
                        .tracking(doodle.tracking(20))
                        .foregroundStyle(t.ink)
                        .lineLimit(1)
                    Text(w.partOfSpeech)
                        .font(.system(size: 12).italic())
                        .foregroundStyle(t.muted)
                    Spacer(minLength: 0)
                    if held {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(t.muted)
                            .accessibilityLabel("Held")
                    }
                }
                Text(w.definition)
                    .font(.system(size: 14))
                    .foregroundStyle(t.definition)
                    .lineLimit(3)
            }
            .id(w.term)
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .topLeading)
        .animation(.easeOut(duration: 0.18), value: w.term)
    }

    /// Soft edges on all four sides, so the field runs off under the glass.
    private var edgeFade: some View {
        let stops = Gradient(stops: [.init(color: .clear, location: 0),
                                     .init(color: .black, location: 0.12),
                                     .init(color: .black, location: 0.88),
                                     .init(color: .clear, location: 1)])
        return LinearGradient(gradient: stops, startPoint: .top, endPoint: .bottom)
            .mask(LinearGradient(gradient: stops, startPoint: .leading, endPoint: .trailing))
    }

    private func copy(_ w: Word) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(w.term, forType: .string)
        #else
        UIPasteboard.general.string = w.term
        #endif
    }

    // MARK: - Geometry

    /// Full size in the middle, easing down to 40% past the rim.
    private static func swell(_ v: CGPoint) -> CGFloat {
        let far = min(hypot(v.x, v.y) / 170, 1.5)
        return max(0.4, 1 - 0.42 * pow(far, 1.4))
    }

    /// `n` cells of a pointy-top hex grid, spiralling out from the middle: ring by
    /// ring, each ring clockwise from twelve o'clock.
    static func honeycomb(_ n: Int) -> [CGPoint] {
        let steps = [(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)]
        var cells: [CGPoint] = [.zero]
        var ring = 1
        while cells.count < n {
            var (q, r) = (-ring, ring)   // steps[4] × ring: any corner will do, sorted below
            var round: [CGPoint] = []
            for (dq, dr) in steps {
                for _ in 0..<ring {
                    round.append(CGPoint(x: pitch * (CGFloat(q) + CGFloat(r) / 2),
                                         y: pitch * sqrt(3) / 2 * CGFloat(r)))
                    q += dq; r += dr
                }
            }
            func clock(_ p: CGPoint) -> Double {
                let a = atan2(p.y, p.x) + .pi / 2   // twelve o'clock is 0
                return a < -1e-9 ? a + 2 * .pi : a
            }
            cells += round.sorted { clock($0) < clock($1) }
            ring += 1
        }
        return Array(cells.prefix(n))
    }

    /// The neighbours' colour by rank, near to far. A ramp per appearance so the
    /// field belongs to the page it sits on: amber to mint on paper and night,
    /// Midnight's own blue, Umber's brass going to stone.
    private static func ramp(_ rank: Int, of n: Int, _ look: Appearance,
                             _ scheme: ColorScheme) -> Color {
        let (near, far): (SIMD3<Double>, SIMD3<Double>) = switch look {
        case .midnight: ([168, 199, 250], [126, 156, 236])
        case .umber:    ([226, 186, 120], [168, 148, 116])
        case .system:
            scheme == .dark ? ([255, 204, 77], [64, 214, 140])
                            : ([255, 222, 120], [146, 226, 182])
        }
        let f = n > 1 ? Double(rank) / Double(n - 1) : 0
        let m = near + (far - near) * f
        return Color(red: m.x / 255, green: m.y / 255, blue: m.z / 255)
    }
}

/// A round badge with soft scalloped edges — the word's own shape, so it never
/// reads as one more bubble.
private struct Scallop: Shape {
    var lobes = 9

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let R = min(rect.width, rect.height) / 2
        var path = Path()
        let samples = 180
        for s in 0...samples {
            let a = 2 * .pi * Double(s) / Double(samples)
            let r = R * (0.92 + 0.08 * cos(Double(lobes) * a))
            let p = CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a))
            s == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }
}

extension Word {
    /// One VoiceOver utterance covering everything a related-word row shows.
    var spokenSummary: String {
        [term, partOfSpeech, definition].filter { !$0.isEmpty }.joined(separator: ". ")
    }
}
