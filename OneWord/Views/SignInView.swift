//
//  SignInView.swift
//  OneWord
//
//  The front door. Until there's a session this is the entire window — RootView
//  shows it instead of the split view, so no pane, no search, no dictionary and no
//  saved word is reachable without signing in.
//
//  Deliberately bare: a wordmark and one button. There is nothing to configure and
//  nothing to read yet, so anything else here would be furniture.
//
//  Dumb view: the session lives in AuthViewModel.
//

import SwiftUI
import AppKit

struct SignInView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(AuthViewModel.self) private var auth

    /// The doodle theme's hand, for the display face. `.face()` hands back the
    /// editorial serif untouched when the handwriting switch is off.
    @Environment(\.doodle) private var doodle
    var body: some View {
        let t = Theme.of(scheme)
        VStack(spacing: 16) {
            // The app's own face, in the serif the headwords use. Without it the
            // window is an unlabelled button and you can't tell what you're joining.
            Spacer()
            Text("One Word")
                .font(doodle.face(34))
                .foregroundStyle(t.ink)
            Text("enrich your vocab by only one word a day")
                .font(doodle.face(12))
                .foregroundStyle(.primary.opacity(0.6))
            Spacer()
            VStack(spacing: 14) {
                signInButton(t)

                if let error = auth.error {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(t.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 280)
                }

                #if DEBUG
                // Debug builds only. A rebuild loses the keychain session, and
                // signing in again every run gets old fast.
                Button("Skip sign-in (Debug)") { auth.skipSignIn() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                #endif
            }
        }
        .padding(.all,24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(t.background)
    }

    private func signInButton(_ t: Theme) -> some View {
        // The one place hue is allowed in: Google's mark has to be Google's mark, and a
        // grey person-glyph on the only button in the window reads as unfinished. The
        // rest of the button still speaks the app's language (DESIGN_BRIEF §3).
        Button {
            // Single-window app, so the key window is always ours. A WindowAccessor
            // NSViewRepresentable is the general answer if that stops being true.
            guard let window = NSApp.keyWindow else { return }
            Task { await auth.signIn(presenting: window) }
        } label: {
            HStack(spacing: 9) {
                // No spinner here: RootView dims the whole window while the
                // browser round trip runs, so the button only changes its word.
                Image("google_icon")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 15, height: 15)
                Text(auth.busy ? "Signing in…" : "Sign in with Google")
                    .font(.system(size: 13))
            }
            .foregroundStyle(t.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(t.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(t.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(auth.busy)
    }
}

#Preview {
    SignInView()
        .environment(AuthViewModel())
        .frame(width: 1000, height: 680)
}
