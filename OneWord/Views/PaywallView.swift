//
//  PaywallView.swift
//  OneWord
//
//  The plans, and the welcome once one is bought. "Quiet sky": three radio rows —
//  Yearly picked — and one sky button whose label follows the pick. No sign-in:
//  StoreKit's Apple ID is the identity, as everywhere else Premium is sold. The
//  welcome is from the "Pencil Cat Mascot" canvas. It wears the app's own palette —
//  Midnight, Umber, or System's dark — and the canvas's Cat paper only when the reader
//  picked System and the system is light. Premium's own colour is `Theme.sky`.
//
//  On the Mac this is its own two-column window (OneWordApp), and the welcome is a
//  modal over the plans inside it; on iPhone and iPad it's a full-height sheet with
//  the button pinned, and it swaps to the welcome.
//  Confetti, the haptic and the announcement hang off the root, keyed on
//  `premium.celebrations`: the welcome is inserted in the same update the counter
//  changes in, so a trigger inside it would take the new value as its first.
//
//  Dumb view: products, purchase state and the celebration live in PremiumViewModel.
//

import SwiftUI
import StoreKit   // Product.displayPrice/price, \.purchase — MEMBER_IMPORT_VISIBILITY needs it named

struct PaywallView: View {
    /// The Mac's Premium window (OneWordApp); Profile's Buy pill opens it by this id.
    static let windowID = "premium"

    /// MOCK — the one list of what Premium gives; Profile's plan row reads it too.
    /// ponytail: placeholder copy; true statements replace it before submission (F10, R1).
    static let perks: [String] = [
        "Every dictionary on the shelf, and each new one as it lands",
        "Practice \u{2014} English sentences to put into German",
        "Any book as your word of the day, on any widget",
        "No ads, ever \u{2014} and you keep an independent app going",
    ]

    @Environment(PremiumViewModel.self) private var premium
    @Environment(\.purchase) private var purchase
    /// iOS: the sheet. Mac: the window — called outside a presented modal, it closes it.
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    /// Opens on Yearly, so the savings chip shows. Resets each time the plans open.
    @State private var pick = Premium.yearlyID
    /// Mac: the window takes the arrow keys as soon as it opens.
    @FocusState private var keys: Bool

    /// The app's palette; System's light half is the canvas's Cat paper rather than plain white.
    private var t: Theme {
        doodle.appearance == .system && scheme == .light ? .cat : Theme.of(scheme, doodle)
    }

    /// Every dictionary on the shelf — what the fan shows.
    private static let shelf = Wordbook.all.filter { $0.id != SavedWords.resource }

    #if os(macOS)
    /// One API for both platforms; `.levelChange` is the one SwiftUI plays on a Mac
    /// (Force Touch trackpad only), `.success` the one it plays on a phone.
    private static let feel = SensoryFeedback.levelChange
    #else
    private static let feel = SensoryFeedback.success
    #endif

    var body: some View {
        content
            .animation(.spring(duration: 0.5, bounce: 0.25), value: premium.isUnlocked)
            #if os(macOS)
            // The window's size under `.contentSize`. A knob.
            .frame(width: 760, height: 600)
            #endif
            // Presented from a flat pane, so it asks for the band back.
            .background { PaneGround(t: t).environment(\.paneGlow, true) }
            .overlay {
                if !reduceMotion {
                    Confetti(trigger: premium.celebrations)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .sensoryFeedback(Self.feel, trigger: premium.celebrations)
            .onChange(of: premium.celebrations) {
                AccessibilityNotification.Announcement("Welcome to the Premium Club").post()
            }
            // The palette's own accent on links and spinners, not the system blue.
            .tint(t.accent)
            .presentationDetents(premium.isUnlocked ? [.height(578)] : [.large])
            .presentationDragIndicator(.visible)
            .presentationBackground(t.background)
    }

    /// The platform split: a modal over the plans on the Mac, a swap in the sheet elsewhere.
    @ViewBuilder private var content: some View {
        #if os(macOS)
        ZStack {
            // Gone, not just dimmed, under the welcome: the selected plan row otherwise
            // peeks out above the card.
            offers
                .opacity(premium.isUnlocked ? 0 : 1)
                .accessibilityHidden(premium.isUnlocked)
            if premium.isUnlocked {
                // The dim takes the clicks meant for the plans beneath it.
                Color.black.opacity(scheme == .dark ? 0.55 : 0.34)
                    .ignoresSafeArea()
                    .transition(.opacity)
                thanks
            }
        }
        #else
        if premium.isUnlocked { thanks } else { offers }
        #endif
    }

    // MARK: - The plans

    /// Nothing can be listed until the App Store has answered, one way or the other.
    private var answered: Bool { premium.product != nil || premium.storeUnavailable }

    /// What's on offer, in list order. Yearly leads, and is the one picked on open.
    private var plans: [Product] {
        [Premium.yearlyID, Premium.monthlyID, Premium.productID].compactMap { premium.products[$0] }
    }

    /// The pick, or the first plan listed if the picked one didn't load.
    private var chosen: Product? { premium.products[pick] ?? plans.first }

    /// Premium's sky as a line on this page: pale on dark, deeper on the Cat paper.
    private var sky: Color { Theme.skyMark(scheme) }

    private var offers: some View {
        #if os(macOS)
        // Two columns: the pitch, then the pick. Keyboard first — arrows pick, Return buys, Esc closes.
        HStack(alignment: .top, spacing: 0) {
            pitch(.leading)
                .padding(EdgeInsets(top: 56, leading: 36, bottom: 32, trailing: 24))
                .frame(width: 380, alignment: .leading)
            VStack(spacing: 9) {
                choices
                Spacer(minLength: 12)
                buyButton
                Text("\u{2191} \u{2193} to choose \u{00B7} Return to buy \u{00B7} Esc to close")
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .accessibilityHidden(true)
                legal
            }
            .padding(EdgeInsets(top: 52, leading: 8, bottom: 26, trailing: 32))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable()
        .focusEffectDisabled()
        .focused($keys)
        .onAppear { keys = true }
        .onKeyPress(.upArrow) { step(-1) }
        .onKeyPress(.downArrow) { step(1) }
        .overlay(alignment: .topTrailing) { closeButton }
        #else
        // Full height, so the price and the button are on screen from the first frame.
        ScrollView {
            VStack(spacing: 18) {
                pitch(.center)
                choices
            }
            .padding(.horizontal, 18)
            .padding(.top, 32)
            .padding(.bottom, 16)
        }
        .scrollContentBackground(.hidden)
        // The one button, pinned: it never scrolls away, and its label follows the pick.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 9) {
                buyButton
                legal
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 6)
            .background(t.background.opacity(0.94))
            .overlay(alignment: .top) { t.hairline.frame(height: 1) }
        }
        // No X on a phone: the sheet's grabber and a swipe down close it.
        #endif
    }

    #if os(macOS)
    /// The window's way out; Esc too.
    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(t.muted)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.cancelAction)
        .accessibilityLabel("Close")
        .padding(8)
    }
    #endif

    /// The fan, the headline, what's in it.
    private func pitch(_ alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 14) {
            PremiumView.fan(Self.shelf, height: isPhone ? 62 : 70, scale: displayScale)
                // The outer covers settle below the fan's frame; keep them off the title.
                .padding(.bottom, 10)
            VStack(alignment: alignment, spacing: 4) {
                Text("The whole shelf")
                    .font(doodle.face(isPhone ? 28 : 34, .medium))
                    .foregroundStyle(t.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(isPhone ? "On every device with your Apple ID"
                             : "On every device with your Apple ID. No account needed.")
                    .font(.system(size: 13))
                    .foregroundStyle(t.muted)
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 9) {
                ForEach(Self.perks, id: \.self) { perk($0) }
            }
            .padding(.top, 2)
        }
    }

    /// One row per plan, a radio each. A spinner until the store answers, a retry if it can't.
    @ViewBuilder private var choices: some View {
        if !answered {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, minHeight: 170)
        } else if plans.isEmpty {
            VStack(spacing: 12) {
                Text(premium.problem ?? "The App Store isn't reachable right now.")
                    .font(.system(size: 14))
                    .foregroundStyle(t.muted)
                    .multilineTextAlignment(.center)
                Button("Try Again") { Task { await premium.load() } }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(t.accent)
                    .frame(minHeight: 44)
            }
            .frame(maxWidth: .infinity, minHeight: 170)
        } else {
            VStack(spacing: 8) {
                ForEach(plans, id: \.id) { row($0) }
                if let problem = premium.problem {
                    Text(problem)
                        .font(.system(size: 12))
                        .foregroundStyle(t.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
        }
    }

    private func row(_ product: Product) -> some View {
        let on = product.id == chosen?.id
        let shape = RoundedRectangle(cornerRadius: t.radius(9))
        return Button {
            withAnimation(.snappy(duration: 0.2)) { pick = product.id }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .strokeBorder(on ? sky : t.muted.opacity(0.7), lineWidth: on ? 6 : 1.5)
                    .frame(width: 20, height: 20)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(Self.name(product.id))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(t.ink)
                        if product.id == Premium.yearlyID, let saved {
                            Text("Save \(saved)%")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.skyInk)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Theme.sky, in: Capsule())
                        }
                    }
                    if let note = note(product) {
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(t.muted)
                    }
                }
                Spacer(minLength: 8)
                Text(product.displayPrice)
                    .font(.system(size: 15, weight: on ? .semibold : .regular))
                    .foregroundStyle(t.ink)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: isPhone ? 58 : 52)
            .background(on ? sky.opacity(0.10) : t.surface, in: shape)
            .overlay(shape.strokeBorder(on ? sky : t.hairline, lineWidth: on ? 2 : 1))
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    /// What Yearly saves against twelve months of Monthly, when both loaded.
    private var saved: Int? {
        guard let y = premium.products[Premium.yearlyID], let m = premium.products[Premium.monthlyID] else { return nil }
        return Premium.savings(yearly: y.price, monthly: m.price)
    }

    private func note(_ product: Product) -> String? {
        switch product.id {
        case Premium.yearlyID: "\(Self.perMonth(product)) a month"
        case Premium.productID: "Pay once, nothing renews"
        default: nil
        }
    }

    /// A plan's name, for the list here and Profile's plan row.
    static func name(_ id: String) -> String {
        switch id {
        case Premium.yearlyID: "Yearly"
        case Premium.monthlyID: "Monthly"
        default: "Lifetime"
        }
    }

    /// A year's price as a month's — "$12.50" — in the store's own currency style.
    static func perMonth(_ yearly: Product) -> String {
        (yearly.price / 12).formatted(yearly.priceFormatStyle)
    }

    /// The one sky button. Its label is the pick and its price; a spinner while a purchase is up.
    private var buyButton: some View {
        let product = chosen
        let busy = premium.phase == .purchasing
        return Button {
            if let product { UnlockButton.buy(product, with: purchase, premium) }
        } label: {
            ZStack {
                if busy {
                    ProgressView().controlSize(.small).tint(Theme.skyInk)
                } else {
                    Text(product.map(buyLabel) ?? "Subscribe")
                }
            }
            .font(.system(size: isPhone ? 16 : 15, weight: .bold))
            .foregroundStyle(Theme.skyInk)
            .frame(maxWidth: .infinity, minHeight: isPhone ? 52 : 44)
            .background(Theme.sky, in: RoundedRectangle(cornerRadius: t.radius(14)))
            .shadow(color: Theme.sky.opacity(scheme == .dark ? 0.3 : 0), radius: 14, y: 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(product == nil || busy)
        .opacity(product == nil ? 0.5 : 1)
        // The welcome's Done takes Return once it's up.
        .keyboardShortcut(premium.isUnlocked ? nil : .defaultAction)
    }

    private func buyLabel(_ product: Product) -> String {
        switch product.id {
        case Premium.yearlyID: "Subscribe \u{00B7} \(product.displayPrice) a year"
        case Premium.monthlyID: "Subscribe \u{00B7} \(product.displayPrice) a month"
        default: "Buy once \u{00B7} \(product.displayPrice)"
        }
    }

    /// What App Review wants under a subscription's button — price, period, how to cancel —
    /// then Restore and the two links.
    private var legal: some View {
        VStack(spacing: 4) {
            if let product = chosen {
                Text(product.id == Premium.productID
                     ? "Pay once. Yours for good."
                     : "Renews \(product.id == Premium.yearlyID ? "yearly" : "monthly") at \(product.displayPrice) "
                       + "until you cancel in your App Store account settings.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 6) {
                Button("Restore") { Task { await premium.restore() } }
                    .buttonStyle(.plain)
                    .foregroundStyle(t.accent)
                    .disabled(premium.phase == .purchasing)
                Text("\u{00B7}").accessibilityHidden(true)
                Link("Terms", destination: Self.terms)
                Text("\u{00B7}").accessibilityHidden(true)
                Link("Privacy", destination: FeedbackViewModel.privacyPolicy)
            }
            .frame(minHeight: 28)
        }
        .font(.system(size: 11))
        .foregroundStyle(t.muted)
        .multilineTextAlignment(.center)
    }

    #if os(macOS)
    private func step(_ by: Int) -> KeyPress.Result {
        let ids = plans.map(\.id)
        guard let i = ids.firstIndex(of: chosen?.id ?? "") else { return .ignored }
        let next = ids[min(max(i + by, 0), ids.count - 1)]
        withAnimation(.snappy(duration: 0.2)) { pick = next }
        return .handled
    }
    #endif

    /// Apple's standard EULA — the app has no terms of its own.
    private static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    private func perk(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(Theme.skyInk)
                .frame(width: 20, height: 20)
                .background(Theme.sky, in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(t.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
        }
    }

    // MARK: - The welcome

    @ViewBuilder private var thanks: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                kicker
                WelcomeHeadline(size: 34, alignment: .leading, ink: t.ink)
                note(alignment: .leading)
            }
            .padding(.leading, 44)
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(.catCafe)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 280)
                .modifier(Breathe())
                .modifier(CatLight(on: scheme == .dark))
                .padding(.trailing, 30)
                .accessibilityHidden(true)
        }
        .frame(width: 690, height: 396)
        .background { PaneGround(t: t).clipShape(RoundedRectangle(cornerRadius: 20)).environment(\.paneGlow, true) }
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(t.hairline))
        // The one way out: closes the window, Esc and Return too.
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(t.muted)
                    .frame(width: 28, height: 28)
                    .background(t.ink.opacity(0.08), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Close")
            .padding(14)
        }
        .background {
            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
                .opacity(0)
                .accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.3), radius: 32, y: 12)
        .transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
        #else
        VStack(spacing: 0) {
            Image(.catCafe)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 220)
                .modifier(Breathe())
                .modifier(CatLight(on: scheme == .dark))
                .padding(.top, 26)
                .accessibilityHidden(true)
            kicker.padding(.top, 14)
            WelcomeHeadline(size: 21, alignment: .center, ink: t.ink)
                .padding(.top, 6)
            note(alignment: .center)
                .padding(.top, 8)
            Spacer(minLength: 16)
            doneButton
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))
        #endif
    }

    private var kicker: some View {
        Text("Premium")
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(sky)
    }

    private func note(alignment: TextAlignment) -> some View {
        Text("Thank you for backing One Word. Premium is yours on every device signed in to this Apple ID.")
            .font(.system(size: isPhone ? 10 : 12, design: .serif))
            .foregroundStyle(t.muted)
            .multilineTextAlignment(alignment)
            .lineSpacing(2)
            .frame(maxWidth: 320)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// iPhone's way out of the welcome; the Mac card closes from its corner.
    /// No "Pick a book": nothing is gated yet, so there's nothing new to pick (F8).
    private var doneButton: some View {
        Button { dismiss() } label: {
            Text("Done")
                .font(.system(size: isPhone ? 16 : 15, weight: .semibold))
                .foregroundStyle(Theme.skyInk)
                .frame(maxWidth: isPhone ? .infinity : nil, minHeight: isPhone ? 50 : 40)
                .padding(.horizontal, 26)
                .background(Theme.sky, in: RoundedRectangle(cornerRadius: t.radius(14)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.defaultAction)
    }
}

/// "Welcome to the Premium Club", rising into place as the welcome appears. Its own view
/// so the entrance replays every time the welcome is inserted. Still under Reduce Motion.
private struct WelcomeHeadline: View {
    let size: CGFloat
    let alignment: TextAlignment
    let ink: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.doodle) private var doodle
    @State private var shown = false

    var body: some View {
        Text("Welcome to the Premium Club")
            .font(doodle.face(size, .medium))
            .foregroundStyle(ink)
            .multilineTextAlignment(alignment)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .scaleEffect(shown || reduceMotion ? 1 : 0.8, anchor: alignment == .center ? .center : .leading)
            .offset(y: shown || reduceMotion ? 0 : 14)
            .opacity(shown || reduceMotion ? 1 : 0)
            .onAppear {
                withAnimation(.spring(duration: 0.6, bounce: 0.45).delay(0.2)) { shown = true }
            }
    }
}

// MARK: - The cats' idle

/// Breathing: 2% taller from the feet and back, 3.6s each way. Still under Reduce Motion.
private struct Breathe: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.phaseAnimator([false, true]) { view, up in
                view.scaleEffect(x: up ? 1.006 : 1, y: up ? 1.02 : 1, anchor: .bottom)
            } animation: { _ in .easeInOut(duration: 3.6) }
        }
    }
}

/// On a dark page the drawings' pencil outlines sink into the ground; a soft light
/// behind each cat lifts it off, the way a lamp would.
private struct CatLight: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        content.shadow(color: on ? .white.opacity(0.22) : .clear, radius: 18)
    }
}

// MARK: - Confetti

/// A burst of paper falling through the whole surface for 2.8s, replayed each time
/// `trigger` changes. One Canvas, one keyframed progress value — no particle views.
private struct Confetti: View {
    let trigger: Int

    var body: some View {
        // Captured here, not read inside the Canvas closure (R5).
        let pieces = Piece.all
        KeyframeAnimator(initialValue: 0.0, trigger: trigger) { p in
            Canvas { context, size in
                guard p > 0, p < 1 else { return }
                let time = p * Piece.duration
                let fade = min(1, (1 - p) / 0.25)
                for piece in pieces {
                    let y = (piece.y0 + piece.speed * time + 0.5 * Piece.gravity * time * time) * size.height
                    let x = (piece.x0 + piece.drift * time) * size.width
                        + sin(time * piece.wobble + piece.phase) * 14
                    var c = context
                    c.translateBy(x: x, y: y)
                    c.rotate(by: .radians(piece.spin * time))
                    // A flat card turning over: its width swings through zero.
                    c.scaleBy(x: cos(time * piece.flip), y: 1)
                    c.opacity = fade
                    c.fill(Path(CGRect(x: -piece.w / 2, y: -piece.h / 2, width: piece.w, height: piece.h)),
                           with: .color(piece.color))
                }
            }
        } keyframes: { _ in
            MoveKeyframe(0.0)
            LinearKeyframe(1.0, duration: Piece.duration)
        }
    }
}

/// One scrap of confetti, as numbers: where it starts, how it falls and turns.
// ponytail: ~90 random pieces built once per launch; seeded or per-burst if repeat bursts look too alike.
private nonisolated struct Piece {
    static let duration = 2.8
    /// In surface heights per second², so a burst crosses a phone sheet and a Mac window alike.
    static let gravity = 0.24

    let x0, y0, drift, speed, wobble, phase, spin, flip: Double
    let w, h: CGFloat
    let color: Color

    static let all: [Piece] = {
        // Premium's sky, from paper-pale to a deep blue that still shows on the Cat page.
        let colors: [Color] = [Color(hex: 0xCFE2FF), Color(hex: 0xA8C7FA), Color(hex: 0x6CA8F0),
                               Color(hex: 0x2F5FA8), Color(hex: 0xE3EEFF), Color(hex: 0xBCD6FF)]
        return (0..<90).map { i in
            Piece(x0: .random(in: 0.02...0.98),
                  y0: .random(in: -0.35 ... -0.02),
                  drift: .random(in: -0.05...0.05),
                  speed: .random(in: 0.05...0.22),
                  wobble: .random(in: 2...5),
                  phase: .random(in: 0...(2 * .pi)),
                  spin: .random(in: -6...6),
                  flip: .random(in: 3...9),
                  w: .random(in: 6...10),
                  h: .random(in: 9...15),
                  color: colors[i % colors.count])
        }
    }()
}

// MARK: - The Cat page

extension Theme {
    /// The canvas's light Cat page (CAT_UI_PLAN §4): the paywall's palette under System, light.
    /// ponytail: CAT_UI Phase 1 adds this to Shared/Theme.swift; this copy then won't compile
    /// (redeclaration), so delete it there.
    static let cat = Theme(
        background: Color(hex: 0xFEFBF7),
        surface:    Color(hex: 0xFFFFFF),
        ink:        Color(hex: 0x1E1B26),
        muted:      Color(hex: 0x625D6E),
        definition: Color(hex: 0x2A2633),
        example:    Color(hex: 0x4B4658),
        accent:     Color(hex: 0x5B3FD6),
        rule:       Color(hex: 0xE9792B),
        hairline:   Color(hex: 0xE9E2D6),
        roundness:  1.5
    )
}

#Preview {
    PaywallView()
        .environment(PremiumViewModel())
}
