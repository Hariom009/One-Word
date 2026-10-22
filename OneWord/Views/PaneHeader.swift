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
#if os(iOS)
import UIKit
#endif

/// The one phone switch, by idiom (plan Q1): a Pro Max in landscape keeps the
/// tabs, an iPad keeps the Mac split view. Views read it for the compact numbers.
#if os(iOS)
@MainActor let isPhone = UIDevice.current.userInterfaceIdiom == .phone
#else
let isPhone = false
#endif

#if os(iOS)
/// The edge swipe back, on every pushed screen. UIKit only lets it begin while the
/// stack shows its own Back, and the strip hides the bar to draw its own — so every
/// pane lost it. Re-armed for any stack deeper than its root.
/// ponytail: app-wide, which is the point — every stack here hides its bar.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
#endif

extension EnvironmentValues {
    /// The split view's columns, so a pane's header can fold the sidebar away.
    /// Inert by default: a preview with no split view has nothing to fold.
    @Entry var sidebar: Binding<NavigationSplitViewVisibility> = .constant(.all)
}

extension View {
    /// Pins a `PaneHeader` over this pane. Content scrolls up under it and the
    /// header hides it by painting the pane's own ground — same top, same width, so
    /// Midnight's glow runs through the seam instead of starting again below it.
    func paneHeader<Trailing: View>(_ title: String? = nil, back: Bool = false, ribbon: Bool = false,
                                    fade: CGFloat = 0, titleAction: (() -> Void)? = nil,
                                    @ViewBuilder trailing: () -> Trailing) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            // Scrolled down on a phone the strip blurs away; its space stays, so the
            // list shows through rather than jumping up — which would re-fire the scroll.
            // `fade` follows the finger (0 at the top, 1 a header's height down), so
            // there's no timed animation to fight the scroll.
            PaneHeader(title: title, back: back, ribbon: ribbon, titleAction: titleAction,
                       trailing: trailing())
                .blur(radius: fade * 12)
                .opacity(1 - fade)
                .scaleEffect(1 - fade * 0.04, anchor: .top)
                .offset(y: -fade * 10)
                .allowsHitTesting(fade < 0.5)
        }
            // The hidden title bar still reserves its height; the header takes it.
            // On a phone that space is the status bar, so the strip stays below it.
            .ignoresSafeArea(.container, edges: isPhone ? [] : .top)
            // Nothing draws it any more, but the Window menu and VoiceOver read it.
            .navigationTitle(title ?? "One Word")
            // A push adds the stack's own Back to the window toolbar, which brings the
            // toolbar back — a black strip over this header in full screen. Ours replaces it.
            .navigationBarBackButtonHidden(back)
            #if os(iOS)
            // The strip IS the bar: a stock one on top would double the title and the back.
            .toolbar(.hidden, for: .navigationBar)
            #endif
    }

    func paneHeader(_ title: String? = nil, back: Bool = false) -> some View {
        paneHeader(title, back: back) { EmptyView() }
    }

    /// How far this scroll view has left its top, 0…1 over one header's height —
    /// what `paneHeader(fade:)` reads.
    /// ponytail: iOS 18 / macOS 15 only; on 17 the header just stays put.
    @ViewBuilder
    func tracksScrollFade(_ fade: Binding<CGFloat>) -> some View {
        if #available(iOS 18, macOS 15, *) {
            onScrollGeometryChange(for: CGFloat.self) { g in
                let p = min(max((g.contentOffset.y + g.contentInsets.top) / 52, 0), 1)
                return (p * 50).rounded() / 50   // 2% steps: no redraw per sub-point
            } action: { fade.wrappedValue = $1 }
        } else {
            self
        }
    }
}

struct PaneHeader<Trailing: View>: View {
    let title: String?
    /// Passed by the screens that are only ever pushed. Not `\.isPresented` on the
    /// Mac: that reads true on a pane's own root inside the split view, so every pane
    /// grew a Back. A phone's tab roots read false, so there it decides on its own —
    /// Settings, Dictionaries and Premium are panes on the Mac but pushes on a phone.
    let back: Bool
    /// Bookmarks on a phone: the ribbon leads the title instead of a count trailing it.
    var ribbon = false
    /// Phone only: makes the title a button — Home's day picker.
    var titleAction: (() -> Void)?
    let trailing: Trailing
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle
    @Environment(\.sidebar) private var sidebar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var presented

    private var showsBack: Bool { back || (isPhone && presented) }

    var body: some View {
        let t = Theme.of(scheme, doodle)
        let folded = sidebar.wrappedValue == .detailOnly
        HStack(spacing: 6) {
            // No sidebar to fold on a phone: the tab bar is the sidebar.
            if !isPhone {
                Button {
                    withAnimation { sidebar.wrappedValue = folded ? .all : .detailOnly }
                } label: {
                    Label(folded ? "Show Sidebar" : "Hide Sidebar", systemImage: "sidebar.left")
                }
                .help(folded ? "Show the sidebar" : "Hide the sidebar")
            }

            if showsBack {
                Button { dismiss() } label: { Label("Back", systemImage: "chevron.left") }
                    .help("Back")
            }

            if isPhone {
                if ribbon { BookmarkRibbon(size: 18) }
                // One name per strip. The tab bar already says which section this
                // is, so the pane's title takes the wordmark's place and its face;
                // a pane with no title of its own keeps the app's name.
                let name = Text(title ?? "One Word")
                    .font(doodle.face(20))
                    .tracking(doodle.tracking(20))
                    .foregroundStyle(t.ink)
                    .lineLimit(1)
                if let titleAction {
                    Button(action: titleAction) {
                        name.contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, showsBack ? 2 : 0)
                } else {
                    name.padding(.leading, showsBack ? 2 : 0)
                }
            } else {
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
            }

            Spacer(minLength: 12)
            HStack(spacing: 6) { trailing }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(HeaderButtonStyle(theme: t))
        // Folded, the window's traffic lights sit over this corner instead of the sidebar.
        .padding(.leading, folded && !isPhone ? 84 : 16)
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
            // A thumb needs 44pt; a pointer is happy with less.
            .frame(minWidth: isPhone ? 40 : 30, minHeight: isPhone ? 40 : 28)
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
        #if os(macOS)
        if #available(macOS 15, *) {
            Color.clear.contentShape(Rectangle()).gesture(WindowDragGesture())
        }
        #endif
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
        // Fixed beside the wordmark on the Mac; on a phone it takes what the strip has left.
        .frame(width: isPhone ? nil : 240, height: isPhone ? 36 : 28)
        .frame(maxWidth: isPhone ? .infinity : nil)
        .background(t.ink.opacity(0.07), in: RoundedRectangle(cornerRadius: t.radius(8)))
        #if os(macOS)
        .onExitCommand { text = "" }
        #endif
        .task { if focusOnAppear { focused = true } }
    }
}
