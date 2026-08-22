//
//  WordCapture.swift
//  OneWord
//
//  Catching a word from any other app. macOS does the hard part: the NSServices
//  entry in Info.plist puts "Save to One Word" in every app's Services menu, and
//  the user binds their own shortcut to it in System Settings ▸ Keyboard ▸
//  Keyboard Shortcuts ▸ Services. No global hotkey code, no accessibility
//  permission — the system hands us the selection on a pasteboard.
//
//  NOTE: after changing NSServices, macOS caches the old list. Run
//        /System/Library/CoreServices/pbs -flush   (or log out) or the menu
//        item won't appear no matter how correct the plist is.
//

import SwiftUI
import AppKit
import WidgetKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let provider = ServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = provider
    }
}

/// Vends the Services entry. The selector must match Info.plist's NSMessage.
/// MainActor because the system delivers service messages on the main thread and
/// this touches AppKit — explicit so it holds whatever the target's default is.
@MainActor
final class ServiceProvider: NSObject {
    @objc func saveWord(_ pasteboard: NSPasteboard,
                        userData: String?,
                        error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let selection = pasteboard.string(forType: .string) else {
            error.pointee = "Nothing to save." as NSString
            return
        }
        guard let word = SavedWords.capture(selection) else {
            error.pointee = "Select a single word to save it." as NSString
            CaptureHUD.show(title: "Select a single word", subtitle: nil)
            return
        }
        // The widget bakes a 7-day timeline — without this the catch wouldn't
        // surface for up to a week.
        WidgetCenter.shared.reloadAllTimelines()
        CaptureHUD.show(title: word.term,
                        subtitle: word.definition.isEmpty
                            ? "Saved \u{2014} no definition on file"
                            : "Saved to One Word")
    }
}

/// A borderless panel that fades in, sits for a beat, and goes away. Without it
/// there's no sign the shortcut did anything and people press it twice.
enum CaptureHUD {
    @MainActor private static var panel: NSPanel?

    @MainActor static func show(title: String, subtitle: String?) {
        panel?.close()

        let hud = NSPanel(contentRect: .zero,
                          styleMask: [.borderless, .nonactivatingPanel],
                          backing: .buffered,
                          defer: false)
        hud.isFloatingPanel = true
        hud.level = .floating
        hud.isOpaque = false
        hud.backgroundColor = .clear
        hud.hasShadow = true
        hud.ignoresMouseEvents = true
        hud.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        hud.contentView = NSHostingView(rootView: CaptureHUDView(title: title, subtitle: subtitle))
        hud.setContentSize(hud.contentView?.fittingSize ?? NSSize(width: 260, height: 90))

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            let size = hud.frame.size
            hud.setFrameOrigin(NSPoint(x: frame.midX - size.width / 2,
                                       y: frame.minY + frame.height * 0.18))
        }
        // Not makeKeyAndOrderFront — the HUD must never steal focus from whatever
        // the user is reading.
        hud.orderFrontRegardless()
        panel = hud

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            guard panel === hud else { return }   // a newer catch replaced it
            hud.animator().alphaValue = 0
            try? await Task.sleep(for: .milliseconds(250))
            hud.close()
            if panel === hud { panel = nil }
        }
    }
}

private struct CaptureHUDView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 22))
                .foregroundStyle(.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.serif(24))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: 420)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.primary.opacity(0.10), lineWidth: 1)
        )
        .fixedSize()
    }
}
