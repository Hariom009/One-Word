//
//  PremiumView.swift
//  OneWord
//
//  The plans: what Free gives you, what Premium adds, and what it costs. Reached from
//  the plan tag in the sidebar's corner. Built like a spread, not a settings form:
//  centred in the pane, the seven premium covers fanned across the top — the covers
//  are the only colour in the app, so this is where the page spends it — then the two
//  plans as tall cards. Premium is one payment, not a subscription, and the page says
//  so plainly; it's what buyers of a word app ask for.
//

import SwiftUI
import AppKit
import StoreKit   // Product.displayPrice — MEMBER_IMPORT_VISIBILITY needs it named

struct PremiumView: View {
    @Environment(PremiumViewModel.self) private var premium
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle
    /// Pixels per point on the screen the pane is on — the fan's covers are drawn to it.
    @Environment(\.displayScale) private var displayScale

    /// Everything Premium opens, in shelf order.
    private static let books = Wordbook.all.filter { !Premium.free.contains($0.id) }
    /// Every dictionary on the shelf — what "all of them" means once Premium is yours.
    private static let shelf = Wordbook.all.filter { $0.id != SavedWords.resource }

    /// Entry counts, read off the main thread: a first decode of every book is enough
    /// JSON to hitch a pane switch. Rows show their count once it lands.
    @State private var counts: [String: Int] = [:]

    var body: some View {
        let t = Theme.of(scheme, doodle)
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 34) {
                    hero(t)
                    // Side by side, sharing the column and the taller card's height.
                    // ponytail: no stacked fallback for very narrow windows — ViewThatFits
                    // sized the pair to its ideal width, not the column's.
                    HStack(alignment: .top, spacing: 24) { free(t); lifetime(t) }
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: 1000)
                .padding(.horizontal, 44)
                .padding(.vertical, 28)
                // Centred both ways: a tall window holds the spread in its middle
                // rather than pinning it under the header with a void beneath.
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
            .scrollContentBackground(.hidden)
        }
        .paneBackground(t)
        .paneHeader("Premium")
        .task {
            let ids = Self.shelf.map(\.id)
            counts = await Task.detached(priority: .utility) {
                Dictionary(uniqueKeysWithValues: ids.map { ($0, WordProvider(resource: $0).allWords.count) })
            }.value
        }
    }

    // MARK: - The spread

    private func hero(_ t: Theme) -> some View {
        VStack(spacing: 18) {
            fan
            VStack(spacing: 10) {
                Text("One Word Premium")
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(2.5)
                    .foregroundStyle(t.muted)
                Text(premium.isUnlocked ? "Every dictionary is yours." : "One payment. Every dictionary.")
                    .font(doodle.face(44))
                    .tracking(doodle.tracking(44))
                    .foregroundStyle(t.ink)
                    .multilineTextAlignment(.center)
                Text("Premium is a single purchase, not a subscription. Pay once and all "
                     + "\(Self.shelf.count) dictionaries stay unlocked, on every Mac signed in "
                     + "to your Apple Account.")
                    .font(.system(size: 15))
                    .foregroundStyle(t.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 540)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The seven premium covers, fanned like a hand of cards: the centre one upright
    /// and on top, the rest tipping away and settling lower towards the edges.
    private var fan: some View {
        let mid = CGFloat(Self.books.count - 1) / 2
        return HStack(spacing: -20) {
            ForEach(Array(Self.books.enumerated()), id: \.element.id) { i, book in
                let away = CGFloat(i) - mid
                Image(nsImage: Self.cover(book.image, height: 100, scale: displayScale))
                    .shadow(color: .black.opacity(0.28), radius: 10, y: 6)
                    .rotationEffect(.degrees(away * 5), anchor: .bottom)
                    .offset(y: abs(away) * abs(away) * 1.8)
                    .zIndex(-abs(away))
            }
        }
        .padding(.top, 6)
        .accessibilityHidden(true)
    }

    /// A cover drawn down to the exact pixels it's shown at, once. Left to Core Animation,
    /// a ~570×828 painting shrunk 8× at draw time comes out speckled — the printed title
    /// breaks up — because its filter samples a few source pixels and skips the rest; Core
    /// Graphics' high-quality resample averages all of them. Keyed on the screen's scale,
    /// so moving the window to a Retina display draws the covers again at 2×.
    // ponytail: the shelf still lets Core Animation scale its covers; it shows them large
    // enough (~2× down) that it doesn't need this. Reuse it there if a small shelf ever does.
    private static var covers: [String: NSImage] = [:]

    private static func cover(_ name: String, height: CGFloat, scale: CGFloat) -> NSImage {
        let key = "\(name)@\(height)x\(scale)"
        if let drawn = covers[key] { return drawn }
        guard let full = NSImage(named: name)?.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: nil,
                                      width: Int((CGFloat(full.width) / CGFloat(full.height) * height * scale).rounded()),
                                      height: Int((height * scale).rounded()),
                                      bitsPerComponent: 8, bytesPerRow: 0, space: space,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return NSImage(named: name) ?? NSImage() }
        context.interpolationQuality = .high
        context.draw(full, in: CGRect(x: 0, y: 0, width: context.width, height: context.height))
        let drawn = context.makeImage().map {
            NSImage(cgImage: $0, size: NSSize(width: CGFloat(context.width) / scale, height: height))
        } ?? NSImage(named: name) ?? NSImage()
        covers[key] = drawn
        return drawn
    }

    private func free(_ t: Theme) -> some View {
        card(t) {
            heading("Free", t)
            Text("Everything a word a day needs, free always.")
                .font(.system(size: 14))
                .foregroundStyle(t.muted)
                .fixedSize(horizontal: false, vertical: true)
            rule(t)
            VStack(alignment: .leading, spacing: 14) {
                perk("A new word every day, on your desktop widget", t)
                perk("A Hindi meaning and an example with every word", t)
                perk("Search, History and Bookmarks", t)
                perk("Works offline \u{2014} every word is already on your Mac", t)
            }
            rule(t)
            label("Includes", t)
            bookRow(.everydayEnglish, t)
            // Level with Premium's action, so the pair reads as one row of choices.
            Spacer(minLength: 4)
            footer(premium.isUnlocked ? "Included in Premium" : "Your current plan", t)
        }
    }

    private func lifetime(_ t: Theme) -> some View {
        card(t, emphasized: true) {
            heading("Premium", t)
            price(t)
            rule(t)
            VStack(alignment: .leading, spacing: 14) {
                perk("Everything in Free", t, strong: true)
                perk("\(Self.books.count) more dictionaries \u{2014} on the shelf, in search and on your widget",
                     t, strong: true)
                perk("Practice \u{2014} English sentences to put into German", t, strong: true)
            }
            rule(t)
            label("Adds", t)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 18, alignment: .leading),
                                GridItem(.flexible(), alignment: .leading)],
                      alignment: .leading, spacing: 12) {
                ForEach(Self.books) { bookRow($0, t) }
            }
            // The action sits at the card's foot, level with the bottom of Free.
            Spacer(minLength: 4)
            action(t)
        }
    }

    /// Apple's price for this storefront, large, with what it buys beside it. Before the
    /// App Store answers there's no number to show, so the promise stands in for it.
    private func price(_ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(premium.product?.displayPrice ?? "Lifetime")
                    .font(doodle.face(44))
                    .tracking(doodle.tracking(44))
                    .foregroundStyle(t.ink)
                if premium.product != nil {
                    Text("once")
                        .font(.system(size: 15))
                        .foregroundStyle(t.muted)
                }
            }
            Text("Yours for good. No subscription, nothing renews.")
                .font(.system(size: 14))
                .foregroundStyle(t.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Unlocked: a thank-you. Otherwise the purchase, full width, with Restore under it
    /// and whatever is in the way under that.
    @ViewBuilder
    private func action(_ t: Theme) -> some View {
        if premium.isUnlocked {
            Label("Unlocked \u{2014} thank you for supporting One Word.", systemImage: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(t.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(t.ink.opacity(0.06), in: RoundedRectangle(cornerRadius: t.radius(10)))
        } else {
            VStack(spacing: 10) {
                UnlockButton(large: true)
                Button("Restore Purchase") { Task { await premium.restore() } }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(t.muted)
                    .disabled(premium.phase == .purchasing)
                if let problem = premium.problem {
                    Text(problem)
                        .font(.system(size: 12))
                        .foregroundStyle(t.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Where Free's card ends: a quiet bar in the same place and size as Premium's button.
    private func footer(_ text: String, _ t: Theme) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(t.muted)
            .frame(maxWidth: .infinity, minHeight: 44)
            .overlay(RoundedRectangle(cornerRadius: t.radius(10)).strokeBorder(t.hairline))
    }

    // MARK: - Pieces

    private func heading(_ name: String, _ t: Theme) -> some View {
        Text(name)
            .font(doodle.face(30))
            .tracking(doodle.tracking(30))
            .foregroundStyle(t.ink)
    }

    /// Uppercase label over a group — the section shape used across the app.
    private func label(_ text: String, _ t: Theme) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(t.muted)
    }

    private func rule(_ t: Theme) -> some View {
        t.hairline.frame(height: 1)
    }

    /// A check in a small disc — Premium's in the accent, Free's in quiet ink.
    private func perk(_ text: String, _ t: Theme, strong: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(strong ? t.background : t.ink)
                .frame(width: 20, height: 20)
                .background(strong ? t.accent : t.ink.opacity(0.08), in: Circle())
                .accessibilityHidden(true)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(t.ink)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 1)
        }
    }

    /// A book as its cover chip, its name, and how many words it holds.
    private func bookRow(_ book: Wordbook, _ t: Theme) -> some View {
        HStack(spacing: 10) {
            BookChip(book: book, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(book.shortName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                // A space until the count lands, so the rows don't jump when it does.
                Text(counts[book.id].map { "\($0.formatted()) words" } ?? " ")
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(t.muted)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// A plan as a tall card: the Settings surface at a larger scale. Premium is lifted —
    /// outlined in the accent, with a shadow under the shape only, so no text casts one.
    /// Which plan is yours is said at each card's foot, where the choice is made.
    private func card<C: View>(_ t: Theme, emphasized: Bool = false,
                               @ViewBuilder _ content: () -> C) -> some View {
        let shape = RoundedRectangle(cornerRadius: t.radius(18))
        return VStack(alignment: .leading, spacing: 18) { content() }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                shape.fill(t.surface)
                    .shadow(color: .black.opacity(emphasized ? 0.22 : 0), radius: 26, y: 14)
            }
            .overlay(shape.strokeBorder(emphasized ? t.accent.opacity(0.6) : t.hairline,
                                        lineWidth: emphasized ? 1.5 : 1))
    }
}

/// A plan's name as a small stamp in the sidebar's corner, saying which plan you're on.
/// Filled means Premium — the thing you own — outlined means Free.
struct PlanTag: View {
    let text: String
    var filled = false

    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    var body: some View {
        let t = Theme.of(scheme, doodle)
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(filled ? t.background : t.muted)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(filled ? t.ink : .clear, in: RoundedRectangle(cornerRadius: t.radius(4)))
            .overlay {
                if !filled {
                    RoundedRectangle(cornerRadius: t.radius(4)).strokeBorder(t.muted.opacity(0.5))
                }
            }
    }
}

#Preview {
    NavigationStack { PremiumView() }
        .environment(PremiumViewModel())
        .frame(width: 1100, height: 900)
}
