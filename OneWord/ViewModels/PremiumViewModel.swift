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

import CryptoKit      // SHA256 — the account's purchase token
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
    /// Whose Premium this is: the signed-in account's id, nil while signed out or before
    /// Firebase has restored the session. A purchase is stamped with it (`appAccountToken`)
    /// and only transactions carrying the same stamp count — so one Apple ID buying once
    /// doesn't unlock every account that signs in on this device.
    @ObservationIgnored private var account: String?

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

    /// Called whenever the signed-in account changes, once Firebase has reported it.
    /// Signing out locks at once; signing in re-reads StoreKit for that account's purchase.
    func bind(account: String?) {
        self.account = account
        guard account != nil else { set(false); return }
        Task { await refresh() }
    }

    /// What the purchase sheet is told, so the receipt names who bought it.
    var purchaseOptions: Set<Product.PurchaseOption> {
        account.map { [.appAccountToken(Self.token(for: $0))] } ?? []
    }

    /// The uid folded into a UUID, deterministically, so a receipt can be matched to an
    /// account on any device with no table of tokens kept anywhere.
    private static func token(for account: String) -> UUID {
        let hash = Array(SHA256.hash(data: Data(account.utf8)).prefix(16))
        return hash.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
    }

    /// What's in the way of buying, if anything — shown in place of the pitch.
    var problem: String? {
        switch phase {
        case .failed(let message): return message
        case .pending: return "Waiting for approval."
        default: return storeUnavailable ? "The App Store isn't reachable right now." : nil
        }
    }

    /// Entitlements first — they're on this Mac and work offline — then the price, which
    /// needs the network. Neither waits on the other's failure.
    func load() async {
        await refresh()
        product = try? await Product.products(for: [Premium.productID]).first
        storeUnavailable = product == nil
    }

    func refresh() async {
        // Nobody to own it yet: leave the cache alone rather than relock an owner (and walk
        // their pick back) in the moment before Firebase restores the session.
        guard let account else { return }
        let token = Self.token(for: account)
        generation += 1
        let mine = generation
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Premium.productID,
               transaction.appAccountToken == token,
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
            return "Purchases aren't allowed on this device."
        }
        return "That didn't go through. Try again."
    }
}
