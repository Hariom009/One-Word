//
//  WordRefreshShortcut.swift
//  OneWord
//
//  Window-local double-space for Home. A local event monitor works even when the
//  sidebar owns keyboard focus, without taking focus from the page's controls.
//

#if os(macOS)
import AppKit
import SwiftUI

struct WordRefreshShortcut: NSViewRepresentable {
    let enabled: Bool
    let next: () -> Void

    func makeNSView(context: Context) -> ShortcutView { ShortcutView() }

    func updateNSView(_ view: ShortcutView, context: Context) {
        view.enabled = enabled
        view.next = next
    }

    static func dismantleNSView(_ view: ShortcutView, coordinator: ()) {
        view.stop()
    }

    final class ShortcutView: NSView {
        var enabled = false {
            didSet { if !enabled { lastSpace = nil } }
        }
        var next: (() -> Void)?
        private var monitor: Any?
        private var lastSpace: TimeInterval?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stop()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
                guard let self else { return event }
                return self.handle(event)
            }
        }

        func stop() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            lastSpace = nil
        }

        private func handle(_ event: NSEvent) -> NSEvent? {
            guard enabled, let window, event.window === window, window.isKeyWindow,
                  window.attachedSheet == nil, NSApp.modalWindow == nil,
                  !isHiddenOrHasHiddenAncestor else {
                lastSpace = nil
                return event
            }
            // Text entry and focused controls keep their normal spacebar behavior.
            // The sidebar's table is allowed: selecting Home often leaves focus there.
            if let control = window.firstResponder as? NSControl, !(control is NSTableView) {
                lastSpace = nil
                return event
            }
            guard !(window.firstResponder is NSTextView),
                  event.type == .keyDown, event.keyCode == 49,
                  event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty else {
                lastSpace = nil
                return event
            }
            // Holding space is never a double press, and mustn't scroll the page.
            guard !event.isARepeat else {
                lastSpace = nil
                return nil
            }
            if let previous = lastSpace, event.timestamp - previous <= NSEvent.doubleClickInterval {
                lastSpace = nil
                next?()
            } else {
                lastSpace = event.timestamp
            }
            return nil
        }
    }
}
#endif
