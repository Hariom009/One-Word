//
//  PremiumBar.swift
//  OneWord
//
//  The one place Premium is sold: pinned under the shelf, first in Settings, and in
//  place of a locked word's entry. Drawn as a Settings card — surface, hairline, the
//  palette's corners — because the covers are the only colour in the app. The price
//  is always Apple's, never typed: it arrives in the reader's own currency.
//  Callers decide when to show it; it always draws.
//

import SwiftUI
import StoreKit

struct PremiumBar: View {
    /// The book that brought you here, when there is one — a locked word's shelf.
    var book: Wordbook? = nil

    @Environment(PremiumViewModel.self) private var premium
    @Environment(\.purchase) private var purchase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    /// Everything Premium opens, counted rather than written down.
    private static let lockedCount = Wordbook.all.filter { !Premium.free.contains($0.id) }.count

    private var busy: Bool { premium.phase == .purchasing }

    private var title: String {
        book.map { "Unlock \($0.shortName)" } ?? "Unlock every dictionary"
    }

    private var status: String {
        switch premium.phase {
        case .failed(let message): return message
        case .pending: return "Waiting for approval."
        default: break
        }
        if premium.storeUnavailable { return "The App Store isn't reachable right now." }
        return book == nil
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
                Text(status)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button("Restore Purchase") { Task { await premium.restore() } }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(t.muted)
                .disabled(busy)
            primary(t)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(t.surface, in: RoundedRectangle(cornerRadius: t.radius(10)))
        .overlay(RoundedRectangle(cornerRadius: t.radius(10)).strokeBorder(t.hairline))
    }

    @ViewBuilder
    private func primary(_ t: Theme) -> some View {
        if busy {
            ProgressView().controlSize(.small).frame(width: 90)
        } else if let product = premium.product {
            pill("Unlock \u{2014} \(product.displayPrice)", t) { buy(product) }
                .accessibilityLabel("\(title), \(product.displayPrice)")
        } else if premium.storeUnavailable {
            pill("Try Again", t) { Task { await premium.load() } }
        } else {
            // Still asking the App Store for the price.
            ProgressView().controlSize(.small).frame(width: 90)
        }
    }

    /// Ink on paper, reversed: the one filled control in the app, so it reads as the action
    /// on every palette. Its corners follow the palette's, so Midnight gets its pill.
    private func pill(_ label: String, _ t: Theme, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(t.background)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(t.ink, in: RoundedRectangle(cornerRadius: t.radius(6)))
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
