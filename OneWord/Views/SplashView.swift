//
//  SplashView.swift
//  OneWord
//
//  The launch animation: the app icon's sticker "ɑ" draws its outline, fills,
//  then slaps down onto its white backing. Drawn as a path rather than the icon
//  image so the outline can be traced on.
//

import SwiftUI

struct SplashView: View {
    /// The window's own ground, so the fade-out reveals the app without a seam.
    let ground: Color
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drawn: CGFloat = 0
    @State private var filled = false
    @State private var stuck = false

    private static let side: CGFloat = 150
    private static let ink = Color(hex: 0x33277F)
    private static let fill = Color(hex: 0x9599FB)

    var body: some View {
        let k = Self.side / AlphaMark.box
        ZStack {
            // The sticker's white backing: the silhouette, counter included, grown outward.
            AlphaMark(withCounter: false)
                .stroke(.white, style: StrokeStyle(lineWidth: 110 * k, lineJoin: .round))
                .background(AlphaMark(withCounter: false).fill(.white))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                .opacity(stuck ? 1 : 0)
                .scaleEffect(stuck ? 1 : 1.12)

            AlphaMark()
                .fill(Self.fill)
                .opacity(filled ? 1 : 0)
                .scaleEffect(filled ? 1 : 0.94)

            AlphaMark()
                .trim(from: 0, to: drawn)
                .stroke(Self.ink, style: StrokeStyle(lineWidth: 30 * k, lineCap: .round, lineJoin: .round))
        }
        .frame(width: Self.side, height: Self.side)
        .scaleEffect(stuck ? 1 : 0.9)
        .rotationEffect(.degrees(stuck ? 0 : -8))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ground.ignoresSafeArea())
        .accessibilityHidden(true)
        .task { await play() }
    }

    private func play() async {
        if reduceMotion {
            drawn = 1; filled = true; stuck = true
            try? await Task.sleep(for: .milliseconds(400))
            onFinish()
            return
        }
        withAnimation(.easeInOut(duration: 0.8)) { drawn = 1 }
        try? await Task.sleep(for: .milliseconds(550))
        withAnimation(.easeOut(duration: 0.35)) { filled = true }
        try? await Task.sleep(for: .milliseconds(350))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { stuck = true }
        try? await Task.sleep(for: .milliseconds(650))
        onFinish()
    }
}

/// The icon's single-storey "ɑ": an oval bowl fused to a stem that kicks out
/// into a round foot. Coordinates trace the icon artwork on a 1024 grid, along
/// the middle of its outline.
struct AlphaMark: Shape {
    static let box: CGFloat = 1024
    var withCounter = true

    func path(in rect: CGRect) -> Path {
        let bowl = Path(ellipseIn: CGRect(x: 125, y: 105, width: 540, height: 790))
        let stem = Path(roundedRect: CGRect(x: 645, y: 80, width: 160, height: 800), cornerRadius: 80)
        let heel = Path(CGRect(x: 760, y: 733, width: 85, height: 144))
        let foot = Path(ellipseIn: CGRect(x: 773, y: 733, width: 144, height: 144))
        var mark = bowl.union(stem).union(heel).union(foot)
        if withCounter {
            mark = mark.subtracting(Path(ellipseIn: CGRect(x: 305, y: 305, width: 280, height: 400)))
        }
        let scale = min(rect.width, rect.height) / Self.box
        return mark.applying(CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: rect.minX / scale, y: rect.minY / scale))
    }
}

#Preview {
    SplashView(ground: .white) {}
}
