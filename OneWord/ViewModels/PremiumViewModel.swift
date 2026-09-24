//
//  PremiumViewModel.swift
//  OneWord
//
//  The app's one StoreKit owner: whether Premium is unlocked, the product for its
//  price, and the state of a purchase in flight. Every unlock or loss is mirrored
//  into the App Group through `Premium.set`, which is what the widget reads. The
//  purchase sheet itself is SwiftUI's (`\.purchase`), so PremiumBar starts it and
//  hands the result back here — this file names no views.
//  MainActor-isolated by default isolation.
//

import Foundation
import Observation
import StoreKit

@Observable
final class PremiumViewModel {
    enum Phase: Equatable { case idle, purchasing, pending, failed(String) }

    private(set) var isUnlocked: Bool
    /// Nil until the App Store answers; the bar shows no price until then.
    private(set) var product: Product?
    private(set) var phase: Phase = .idle
    /// The product didn't load — offline, or the store isn't set up yet. The bar offers a retry.
    private(set) var storeUnavailable = false

    // ponytail: lives as long as the app (@State on OneWordApp), so the listener is never cancelled.
    @ObservationIgnored private var updates: Task<Void, Never>?
    /// Refreshes suspend while they read, so two can overlap; only the latest one applies.
    @ObservationIgnored private var generation = 0

    init() {
        // The cache first, so an owner never sees the shelf flash locked while StoreKit answers.
        isUnlocked = Premium.isUnlocked
        // Purchases from another Mac, Ask to Buy approvals, refunds, revocations — all one path.
        updates = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let transaction) = update { await transaction.finish() }
                await self?.refresh()
            }
        }
    }

    func allows(_ id: String) -> Bool { Premium.allows(id, unlocked: isUnlocked) }

    /// Entitlements first — they're on this Mac and work offline — then the price, which
    /// needs the network. Neither waits on the other's failure.
    func load() async {
        await refresh()
        product = try? await Product.products(for: [Premium.productID]).first
        storeUnavailable = product == nil
    }

    func refresh() async {
        generation += 1
        let mine = generation
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Premium.productID,
               transaction.revocationDate == nil { owned = true }
        }
        // A newer refresh started while this one read: its snapshot is the fresher one.
        guard mine == generation else { return }
        // An Ask to Buy that was declined never sends a transaction; stop waiting on it here.
        if phase == .pending { phase = .idle }
        set(owned)
    }

    func begin() { phase = .purchasing }

    func handle(_ result: Product.PurchaseResult) async {
        switch result {
        case .success(.verified(let transaction)):
            await transaction.finish()
            // Not set(true): through refresh, so a slower refresh can't land after and relock.
            await refresh()
            phase = .idle
        case .success(.unverified):
            phase = .failed("Apple couldn't verify this purchase.")
        case .pending:
            phase = .pending
        case .userCancelled:
            phase = .idle
        @unknown default:
            phase = .idle
        }
    }

    func failed(_ error: Error) { phase = .failed(Self.message(for: error)) }

    func restore() async {
        phase = .purchasing
        do {
            try await AppStore.sync()
            phase = .idle
        } catch StoreKitError.userCancelled {
            phase = .idle
        } catch {
            phase = .failed(Self.message(for: error))
        }
        await refresh()
    }

    /// Always writes through — that heals a stale cache and walks a locked pick home — but
    /// only touches the observed flag when it changes, so nothing redraws for nothing.
    private func set(_ owned: Bool) {
        Premium.set(unlocked: owned)
        if owned != isUnlocked { isUnlocked = owned }
    }

    private static func message(for error: Error) -> String {
        if let store = error as? StoreKitError, case .networkError = store {
            return "The App Store isn't reachable. Try again when you're online."
        }
        if let purchase = error as? Product.PurchaseError, case .purchaseNotAllowed = purchase {
            return "Purchases aren't allowed on this Mac."
        }
        return "That didn't go through. Try again."
    }
}
