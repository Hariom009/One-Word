//
//  PaneHeader.swift
//  OneWord
//
//  The top strip of every pane, drawn in the pane instead of the window's toolbar.
//  The window has no toolbar at all: in full screen macOS moves a toolbar into a
//  window of its own and paints it a grey no theme reaches, so owning the strip was
//  the one way to keep every appearance edge to edge. Left: the sidebar toggle, back
//  when something was pushed, the app's name and the pane's title. Right: whatever
//  the pane hands in.
//

import SwiftUI

extension EnvironmentValues {
    /// The split view's columns, so a pane's header can fold the sidebar away.
    /// Inert by default: a preview with no split view has nothing to fold.
    @Entry var sidebar: Binding<NavigationSplitViewVisibility> = .constant(.all)
}

extension View {
    /// Pins a `PaneHeader` over this pane. Content scrolls up under it and the
    /// header hides it by painting the pane's own ground — same top, same width, so
    /// Midnight's glow runs through the seam instead of starting again below it.
    func paneHeader<Trailing: View>(_ title: String? = nil, back: Bool = false,
                                    @ViewBuilder trailing: () -> Trailing) -> some View {
        safeAreaInset(edge: .top, spacing: 0) { PaneHeader(title: title, back: back, trailing: trailing()) }
            // The hidden title bar still reserves its height; the header takes it.
            .ignoresSafeArea(.container, edges: .top)
            // Nothing draws it any more, but the Window menu and VoiceOver read it.
            .navigationTitle(title ?? "One Word")
    }

    func paneHeader(_ title: String? = nil, back: Bool = false) -> some View {
        paneHeader(title, back: back) { EmptyView() }
    }
}

struct PaneHeader<Trailing: View>: View {
    let title: String?
    /// Passed by the screens that are only ever pushed. Not `\.isPresented`: that
    /// reads true on a pane's own root inside the split view, so every pane grew a Back.
    let back: Bool
    let trailing: Trailing
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle
    @Environment(\.sidebar) private var sidebar
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let t = Theme.of(scheme, doodle)
        let folded = sidebar.wrappedValue == .detailOnly
        HStack(spacing: 6) {
            Button {
                withAnimation { sidebar.wrappedValue = folded ? .all : .detailOnly }
            } label: {
                Label(folded ? "Show Sidebar" : "Hide Sidebar", systemImage: "sidebar.left")
            }
            .help(folded ? "Show the sidebar" : "Hide the sidebar")

            if back {
                Button { dismiss() } label: { Label("Back", systemImage: "chevron.left") }
                    .help("Back")
            }

            Text("One Word")
                .font(doodle.face(18))
                .tracking(doodle.tracking(18))
                .foregroundStyle(t.ink)
                .lineLimit(1)
                .padding(.leading, 8)
            if let title {
                Rectangle().fill(t.hairline).frame(width: 1, height: 14).padding(.horizontal, 4)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(t.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)
            HStack(spacing: 6) { trailing }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(HeaderButtonStyle(theme: t))
        // Folded, the window's traffic lights sit over this corner instead of the sidebar.
        .padding(.leading, folded ? 84 : 16)
        .padding(.trailing, 16)
        .frame(height: 52)
        .background { WindowDragArea() }
        .paneBackground(t)
    }
}

/// One look for every button in the strip: a soft tile under an icon or a short
/// label, rounded by the palette — Midnight's radius turns it into a pill.
private struct HeaderButtonStyle: ButtonStyle {
    let theme: Theme
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(theme.ink)
            .frame(minWidth: 30, minHeight: 28)
            .background(theme.ink.opacity(configuration.isPressed ? 0.14 : 0.07),
                        in: RoundedRectangle(cornerRadius: theme.radius(8)))
            .contentShape(RoundedRectangle(cornerRadius: theme.radius(8)))
            .opacity(enabled ? 1 : 0.4)
    }
}

/// The strip moves the window, the way a title bar would.
/// ponytail: macOS 14 has no gesture for it, so there the window only drags from
/// the traffic-light strip over the sidebar. Raise the target to 15 to drop this.
private struct WindowDragArea: View {
    var body: some View {
        if #available(macOS 15, *) {
            Color.clear.contentShape(Rectangle()).gesture(WindowDragGesture())
        }
    }
}

/// A pane's search box, in the header where `.searchable` used to put it in the
/// toolbar. `focusOnAppear` is Search's: ⌘K from the sidebar should land typing.
struct HeaderSearchField: View {
    let prompt: String
    @Binding var text: String
    var focusOnAppear = false
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    var body: some View {
        let t = Theme.of(scheme, doodle)
        HStack(spacing: 6) {
            GlyphIcon(.search).foregroundStyle(t.muted)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(t.ink)
                .focused($focused)
            if !text.isEmpty {
                Button { text = "" } label: { Label("Clear", systemImage: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(t.muted)
            }
        }
        .padding(.horizontal, 9)
        .frame(width: 240, height: 28)
        .background(t.ink.opacity(0.07), in: RoundedRectangle(cornerRadius: t.radius(8)))
        .onExitCommand { text = "" }
        .task { if focusOnAppear { focused = true } }
    }
}
