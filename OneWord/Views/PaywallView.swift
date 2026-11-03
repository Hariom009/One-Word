//
//  PaywallView.swift
//  OneWord
//
//  The plans, and the welcome once one is bought. Monthly and Yearly share one card
//  with a toggle in its corner; Lifetime has its own, with the cat asleep on it. No
//  sign-in: StoreKit's Apple ID is the identity, as everywhere else Premium is sold.
//  Drawn from the "Pencil Cat Mascot" canvas (MacPremium, PhonePremium and their
//  Thanks boards). It wears the app's own palette — Midnight, Umber, or System's dark —
//  and the canvas's Cat paper only when the reader picked System and the system is light.
//
//  On the Mac this is its own window (OneWordApp), and the welcome is a modal over
//  the plans inside it; on iPhone and iPad it's a sheet that swaps to the welcome.
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

    /// MOCK — the one list of what Premium gives; Profile's gold card reads it too.
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
    @State private var yearly = true

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
            .background { PaneGround(t: t) }
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
            .presentationDetents(premium.isUnlocked ? [.height(584)] : [.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(t.background)
    }

    /// The platform split: a modal over the plans on the Mac, a swap in the sheet elsewhere.
    @ViewBuilder private var content: some View {
        #if os(macOS)
        ZStack {
            offers.accessibilityHidden(premium.isUnlocked)
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

    /// Neither card can say anything until the App Store has answered, one way or the other.
    private var answered: Bool { premium.product != nil || premium.storeUnavailable }
    private var yearlyProduct: Product? { premium.products[Premium.yearlyID] }
    private var monthlyProduct: Product? { premium.products[Premium.monthlyID] }
    private var showsSubscription: Bool { !answered || (yearlyProduct != nil && monthlyProduct != nil) }
    private var showsLifetime: Bool { !answered || premium.product != nil }

    private var offers: some View {
        ScrollView {
            VStack(spacing: isPhone ? 18 : 22) {
                PremiumView.fan(Self.shelf, height: isPhone ? 72 : 100, scale: displayScale)
                    .padding(.top, isPhone ? 8 : 18)
                    // The outer covers settle below the fan's frame; keep them off the title.
                    .padding(.bottom, 10)
                VStack(spacing: 8) {
                    Text("The whole shelf")
                        .font(doodle.face(isPhone ? 30 : 36, .medium))
                        .foregroundStyle(t.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Premium, on every device signed in to your Apple ID. No account needed.")
                        .font(.system(size: 14))
                        .foregroundStyle(t.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Self.perks, id: \.self) { perk($0) }
                }
                .frame(maxWidth: 520, alignment: .leading)
                cards
                below
            }
            .padding(.horizontal, isPhone ? 20 : 44)
            .padding(.vertical, isPhone ? 16 : 28)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.muted)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .accessibilityLabel("Close")
            .padding(10)
        }
    }

    /// Side by side on the Mac, one under the other on iPhone and iPad.
    @ViewBuilder private var cards: some View {
        let showSubscription = showsSubscription
        let showLifetime = showsLifetime
        if showSubscription || showLifetime {
            #if os(macOS)
            HStack(alignment: .top, spacing: 20) {
                if showSubscription { subscriptionCard }
                if showLifetime { lifetimeCard }
            }
            .fixedSize(horizontal: false, vertical: true)
            // Room for the cushion cat's overhang before Restore.
            .padding(.bottom, 26)
            #else
            VStack(spacing: 14) {
                if showSubscription { subscriptionCard }
                if showLifetime { lifetimeCard }
            }
            .padding(.bottom, 14)
            #endif
        } else {
            VStack(spacing: 12) {
                Text(premium.problem ?? "The App Store isn't reachable right now.")
                    .font(.system(size: 14))
                    .foregroundStyle(t.muted)
                    .multilineTextAlignment(.center)
                Button("Try Again") { Task { await premium.load() } }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(t.accent)
            }
            .padding(.vertical, 20)
        }
    }

    private var subscriptionCard: some View {
        let shown = yearly ? yearlyProduct : monthlyProduct
        return card(emphasized: false) {
            HStack(alignment: .center) {
                Text("Premium")
                    .font(doodle.face(24, .medium))
                    .foregroundStyle(t.ink)
                Spacer(minLength: 8)
                periodToggle
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(shown?.displayPrice ?? "\u{2014}")
                    .font(doodle.face(40, .medium))
                    .foregroundStyle(t.ink)
                    .contentTransition(.numericText())
                Text(yearly ? "/ year" : "/ month")
                    .font(.system(size: 15))
                    .foregroundStyle(t.muted)
            }
            if yearly, let y = yearlyProduct, let m = monthlyProduct,
               let saved = Premium.savings(yearly: y.price, monthly: m.price) {
                Text("Save \(saved)%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(t.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(t.accent.opacity(0.12), in: Capsule())
            }
            if let shown {
                // What App Review wants beside a subscription: price, period, how to cancel.
                Text("Renews every \(yearly ? "year" : "month") at \(shown.displayPrice) until you cancel. "
                     + "Cancel anytime in your App Store account settings.")
                    .font(.system(size: 12))
                    .foregroundStyle(t.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            buyButton(yearly ? Premium.yearlyID : Premium.monthlyID, "Subscribe",
                      yearly ? "Premium Yearly" : "Premium Monthly")
        }
    }

    /// One capsule, the current period filled. One button: there are only two.
    private var periodToggle: some View {
        Button {
            withAnimation(.snappy) { yearly.toggle() }
        } label: {
            HStack(spacing: 0) {
                segment("Monthly", on: !yearly)
                segment("Yearly", on: yearly)
            }
            .padding(3)
            .background(t.hairline.opacity(0.6), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Billing period")
        .accessibilityValue(yearly ? "Yearly" : "Monthly")
        .accessibilityHint("Switches between monthly and yearly")
    }

    private func segment(_ text: String, on: Bool) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(on ? t.background : t.muted)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(on ? t.accent : .clear, in: Capsule())
    }

    private var lifetimeCard: some View {
        card(emphasized: true) {
            Text("Lifetime")
                .font(doodle.face(24, .medium))
                .foregroundStyle(t.ink)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(premium.product?.displayPrice ?? "\u{2014}")
                    .font(doodle.face(40, .medium))
                    .foregroundStyle(t.ink)
                Text("once")
                    .font(.system(size: 15))
                    .foregroundStyle(t.muted)
            }
            Text("Pay once. Yours for good. Nothing renews.")
                .font(.system(size: 14))
                .foregroundStyle(t.example)
                .frame(maxWidth: isPhone ? .infinity : 190, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            buyButton(Premium.productID, "Buy", "Premium Lifetime")
        }
        // The cat never covers Buy: on a phone the button is full width, so the card makes
        // room under it; elsewhere the button is leading and the cat sits off to the right.
        .padding(.bottom, isPhone ? 96 : 0)
        .overlay(alignment: .bottomTrailing) {
            Image(.catCushion)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: isPhone ? 118 : 168)
                .modifier(Breathe())
                .modifier(CatLight(on: scheme == .dark))
                .offset(x: isPhone ? 8 : 30, y: isPhone ? 20 : 34)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    /// The action for one product: the price on a violet button, a spinner while the
    /// App Store answers or a purchase is up, nothing if the store has no such product.
    @ViewBuilder private func buyButton(_ id: String, _ label: String, _ name: String) -> some View {
        if premium.phase == .purchasing || (!answered && premium.products[id] == nil) {
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: isPhone ? .infinity : nil, minHeight: isPhone ? 50 : 40)
                .frame(minWidth: 160, alignment: .leading)
        } else if let product = premium.products[id] {
            Button { UnlockButton.buy(product, with: purchase, premium) } label: {
                Text("\(label), \(product.displayPrice)")
                    .font(.system(size: isPhone ? 16 : 15, weight: .semibold))
                    .foregroundStyle(t.background)
                    .padding(.horizontal, 22)
                    .frame(maxWidth: isPhone ? .infinity : nil, minHeight: isPhone ? 50 : 40)
                    .frame(minWidth: 160)
                    .background(t.accent, in: RoundedRectangle(cornerRadius: isPhone ? 14 : 12))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label) \(name), \(product.displayPrice)")
        }
    }

    /// Restore, whatever's in the way of buying, and the two links App Review asks for.
    private var below: some View {
        VStack(spacing: 10) {
            Button("Restore Purchase") { Task { await premium.restore() } }
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(t.accent)
                .frame(minHeight: 34)
                .disabled(premium.phase == .purchasing)
            // With no card to show, the problem already stands in their place.
            if let problem = premium.problem, answered, showsSubscription || showsLifetime {
                Text(problem)
                    .font(.system(size: 12))
                    .foregroundStyle(t.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 6) {
                Link("Terms of Use", destination: Self.terms)
                Text("\u{00B7}").accessibilityHidden(true)
                Link("Privacy Policy", destination: Self.privacy)
            }
            .font(.system(size: 12))
            .foregroundStyle(t.muted)
        }
    }

    /// Apple's standard EULA — the app has no terms of its own.
    private static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// ponytail: duplicates FeedbackViewModel.privacyPolicy once feat/website merges — point at it then.
    private static let privacy = URL(string: "https://one-word-a2f3a.web.app/privacy")!

    private func perk(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(t.background)
                .frame(width: 20, height: 20)
                .background(t.accent, in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(t.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
        }
    }

    /// The canvas's card: white, a hairline, 18pt corners; the lifted one gets the violet
    /// border and a shadow under the shape only.
    private func card<C: View>(emphasized: Bool, @ViewBuilder _ content: () -> C) -> some View {
        let shape = RoundedRectangle(cornerRadius: t.radius(12))
        return VStack(alignment: .leading, spacing: 12) { content() }
            .padding(isPhone ? 18 : 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                shape.fill(t.surface)
                    .shadow(color: .black.opacity(emphasized ? 0.14 : 0), radius: 20, y: 10)
            }
            .overlay(shape.strokeBorder(emphasized ? t.accent : t.hairline, lineWidth: emphasized ? 2 : 1))
    }

    // MARK: - The welcome

    @ViewBuilder private var thanks: some View {
        #if os(macOS)
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                kicker
                WelcomeHeadline(size: 36, alignment: .leading, ink: t.ink)
                note(alignment: .leading)
                doneButton.padding(.top, 8)
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
        .frame(width: 680, height: 420)
        .background { PaneGround(t: t).clipShape(RoundedRectangle(cornerRadius: 20)) }
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(t.hairline))
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
            WelcomeHeadline(size: 30, alignment: .center, ink: t.ink)
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
            .foregroundStyle(t.accent)
    }

    private func note(alignment: TextAlignment) -> some View {
        Text("Thank you for backing One Word. Premium is yours on every device signed in to this Apple ID.")
            .font(.system(size: 15))
            .foregroundStyle(t.muted)
            .multilineTextAlignment(alignment)
            .lineSpacing(2)
            .frame(maxWidth: 320)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// No "Pick a book": nothing is gated yet, so there's nothing new to pick (F8).
    private var doneButton: some View {
        Button { dismiss() } label: {
            Text("Done")
                .font(.system(size: isPhone ? 16 : 15, weight: .semibold))
                .foregroundStyle(t.background)
                .frame(maxWidth: isPhone ? .infinity : nil, minHeight: isPhone ? 50 : 40)
                .padding(.horizontal, 26)
                .background(t.accent, in: RoundedRectangle(cornerRadius: isPhone ? 14 : 12))
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
        let colors: [Color] = [Color(hex: 0x5B3FD6), Color(hex: 0xE9B949), Color(hex: 0xF07167),
                               Color(hex: 0x2BB3A3), Color(hex: 0x6CA8F0), Color(hex: 0x9B7BFF)]
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
