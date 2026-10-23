//
//  SyncToast.swift
//  OneWord
//
//  A pill along the bottom of the window when iCloud brings in what the other
//  device changed: "Syncing with iCloud…", then "Synced with iCloud", then gone.
//  Only pulls are announced (CloudSync.didSync) — pushes stay quiet.
//
//  ponytail: key-value storage merges in one synchronous step, so there is no real
//  "in progress" to wait on — the syncing beat is a fixed 0.8s so the hand-off
//  reads. CKSyncEngine, the upgrade CloudSync names, has real start/finish events.
//

import SwiftUI

extension View {
    /// The iCloud toast over this view's bottom edge. `paused` holds it back while
    /// something covers the window; a sync meanwhile shows once it lifts.
    func syncToast(paused: Bool) -> some View { modifier(SyncToast(paused: paused)) }
}

private struct SyncToast: ViewModifier {
    let paused: Bool

    private enum Phase { case syncing, synced }
    @State private var phase: Phase?
    /// Seeded from the count: the launch sync ran before this was listening.
    @State private var syncs = CloudSync.pulls
    @State private var shown = 0
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let phase { pill(phase).transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
            .animation(.easeInOut(duration: 0.25), value: phase)
            .onReceive(NotificationCenter.default.publisher(for: CloudSync.didSync)) { _ in
                syncs = CloudSync.pulls
            }
            // A sync landing mid-toast restarts it rather than stacking a second.
            .task(id: paused ? -1 : syncs) {
                guard !paused, syncs > shown else { return }
                shown = syncs
                do {
                    phase = .syncing
                    try await Task.sleep(for: .milliseconds(800))
                    phase = .synced
                    AccessibilityNotification.Announcement("Synced with iCloud").post()
                    try await Task.sleep(for: .seconds(2))
                    phase = nil
                } catch {}  // cancelled: the newer run owns the pill now
            }
    }

    private func pill(_ phase: Phase) -> some View {
        let t = Theme.of(scheme, doodle)
        let shape = RoundedRectangle(cornerRadius: t.radius(10))
        let synced = phase == .synced
        return Label(synced ? "Synced with iCloud" : "Syncing with iCloud…",
                     systemImage: synced ? "checkmark.icloud" : "arrow.triangle.2.circlepath.icloud")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(t.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            // Midnight's surface is see-through; the ground under it keeps the pill
            // readable over whatever text it lands on.
            .background(t.surface, in: shape)
            .background(t.background, in: shape)
            .overlay(shape.strokeBorder(t.ink.opacity(0.1)))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 3)
            // A phone's tab bar is drawn over this edge, not inset from it.
            .padding(.bottom, isPhone ? 64 : 18)
    }
}
