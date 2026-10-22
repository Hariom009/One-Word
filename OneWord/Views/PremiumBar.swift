//
//  PremiumBar.swift
//  OneWord
//
//  Where Premium is sold inline: pinned under the shelf, first in Settings, and in
//  place of a locked word's entry. Drawn as a Settings card — surface, hairline, the
//  palette's corners — because the covers are the only colour in the app. The price
//  is always Apple's, never typed: it arrives in the reader's own currency.
//  Callers decide when to show it; it always draws. The plans themselves, side by
//  side, are PremiumView.
//

import SwiftUI
import StoreKit

struct PremiumBar: View {
    /// The book that brought you here, when there is one — a locked word's shelf.
    var book: Wordbook? = nil

    @Environment(PremiumViewModel.self) private var premium
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    /// Everything Premium opens, counted rather than written down.
    private static let lockedCount = Wordbook.all.filter { !Premium.free.contains($0.id) }.count

    private var title: String {
        book.map { "Unlock \($0.shortName)" } ?? "Unlock every dictionary"
    }

    private var pitch: String {
        book == nil
            ? "\(Self.lockedCount) dictionaries, one payment, yours for good."
            : "And \(Self.lockedCount - 1) more \u{2014} one payment, yours for good."
    }

    var body: some View {
        let t = Theme.of(scheme, doodle)
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundStyle(t.muted)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.ink)
                Text(premium.problem ?? pitch)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button("Restore Purchase") { Task { await premium.restore() } }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(t.muted)
                .disabled(premium.phase == .purchasing)
            UnlockButton(name: title)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(t.surface, in: RoundedRectangle(cornerRadius: t.radius(10)))
        .overlay(RoundedRectangle(cornerRadius: t.radius(10)).strokeBorder(t.hairline))
    }
}

/// The purchase control, wherever Premium is sold: the price as Apple states it, a
/// spinner while the sheet is up or the price is on its way, Try Again when the store
/// didn't answer. The sheet is SwiftUI's; its result goes back to PremiumViewModel.
struct UnlockButton: View {
    /// What VoiceOver hears before the price — "Unlock Urdu", say.
    var name = "Unlock every dictionary"
    /// The plans pane's version: full width, taller, and it says what it unlocks.
    var large = false

    @Environment(PremiumViewModel.self) private var premium
    @Environment(\.purchase) private var purchase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    var body: some View {
        let t = Theme.of(scheme, doodle)
        if premium.phase == .purchasing {
            spinner
        } else if let product = premium.product {
            pill(large ? "Unlock Premium \u{2014} \(product.displayPrice)" : "Unlock \u{2014} \(product.displayPrice)", t) { buy(product) }
                .accessibilityLabel("\(name), \(product.displayPrice)")
        } else if premium.storeUnavailable {
            pill("Try Again", t) { Task { await premium.load() } }
        } else {
            // Still asking the App Store for the price.
            spinner
        }
    }

    private var spinner: some View {
        ProgressView().controlSize(.small)
            .frame(maxWidth: large ? .infinity : 90, minHeight: large ? 44 : nil)
    }

    /// Ink on paper, reversed: the one filled control in the app, so it reads as the
    /// action on every palette. Its corners follow the palette's, so Midnight gets a pill.
    private func pill(_ label: String, _ t: Theme, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: large ? 14 : 12, weight: .semibold))
                .foregroundStyle(t.background)
                .frame(maxWidth: large ? .infinity : nil)
                .padding(.horizontal, large ? 20 : 12)
                .padding(.vertical, large ? 13 : 6)
                .background(t.ink, in: RoundedRectangle(cornerRadius: t.radius(large ? 10 : 6)))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func buy(_ product: Product) {
        Task {
            premium.begin()
            do {
                let result = try await purchase(product)
                await premium.handle(result)
            } catch {
                premium.failed(error)
            }
        }
    }
}
