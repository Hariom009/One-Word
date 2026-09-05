//
//  ProfileView.swift
//  OneWord
//
//  Two states. Signed out it is one centred button and nothing else — there is no
//  profile to show yet, so the pane doesn't invent one. Signed in it is the number
//  of words you've kept, the way in to the Learned log (which lives here rather
//  than in the sidebar), and who you are.
//
//  Signing in stays optional on purpose: the words are bundled and every OTHER pane
//  reads them offline whether or not you have an account. This is the only pane that
//  changes, and an account buys identity, not access.
//
//  Dumb view: the count lives in ProfileViewModel, the session in AuthViewModel.
//

import SwiftUI
import AppKit
import Combine   // NotificationCenter.publisher — MEMBER_IMPORT_VISIBILITY needs it named

struct ProfileView: View {
    @Environment(\.colorScheme) private var scheme

    @State private var model = ProfileViewModel()
    @State private var auth = AuthViewModel()

    var body: some View {
        let t = Theme.of(scheme)
        Group {
            // Signed out, the pane holds one thing. Nothing here is gated — the words
            // stay readable in every other pane — so this is the Profile pane having
            // nothing to say yet, not a wall.
            if auth.isSignedIn { signedInPane(t) } else { signedOutPane(t) }
        }
        .background(t.background)
        .navigationTitle("Profile")
        .onReceive(NotificationCenter.default.publisher(for: SavedWords.didChange)) { _ in
            model.refresh()
        }
        .task {
            model.refresh()
            auth.restore()
        }
    }

    // MARK: - Signed out

    private func signedOutPane(_ t: Theme) -> some View {
        VStack(spacing: 14) {
            signInButton(t)
            if let error = auth.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Signed in

    private func signedInPane(_ t: Theme) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(model.bookmarks)")
                    .font(.serif(64))
                    .foregroundStyle(t.ink)
                    .contentTransition(.numericText())
                Text(model.bookmarks == 1 ? "bookmark" : "bookmarks")
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase).tracking(2)
                    .foregroundStyle(t.muted)
            }
            .accessibilityElement(children: .combine)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)

            NavigationLink {
                LearnedListView()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal")
                    Text("Learned")
                        .font(.system(size: 13))
                    Spacer(minLength: 6)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(t.muted)
                }
                .foregroundStyle(t.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(t.surface, in: RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)

            account(t)
                .padding(.horizontal, 24)
                .padding(.top, 10)
        }
    }

    // MARK: - Account

    /// Only reachable while signed in — the signed-out pane is the button alone.
    @ViewBuilder private func account(_ t: Theme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            accountRow(t)
            if let error = auth.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(t.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func accountRow(_ t: Theme) -> some View {
        HStack(spacing: 10) {
            avatar(auth.photoURL, t)
            VStack(alignment: .leading, spacing: 1) {
                Text(auth.displayName ?? "Signed in")
                    .font(.system(size: 13))
                    .foregroundStyle(t.ink)
                if let email = auth.email {
                    Text(email)
                        .font(.system(size: 11))
                        .foregroundStyle(t.muted)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 6)
            Button("Sign out") { auth.signOut() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .bold))
                .textCase(.uppercase)
                .tracking(1.5)
                .foregroundStyle(t.muted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(t.surface, in: RoundedRectangle(cornerRadius: 8))
    }

    private func signInButton(_ t: Theme) -> some View {
        // ponytail: Google's own button styling is a colored, branded asset; the app is
        // strictly monochrome (DESIGN_BRIEF §3 — "no hue anywhere"), so it wears the
        // app's own language instead. Revisit if this ever ships to the App Store and
        // Google's branding terms come up.
        Button {
            // Single-window app, so the key window is always ours. A WindowAccessor
            // NSViewRepresentable is the general answer if that stops being true.
            guard let window = NSApp.keyWindow else { return }
            Task { await auth.signIn(presenting: window) }
        } label: {
            HStack(spacing: 9) {
                // The spinner replaces the glyph rather than sitting beside it, so the
                // button keeps its width and nothing shifts while the browser opens.
                if auth.busy {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 14))
                }
                Text(auth.busy ? "Signing in…" : "Sign in with Google")
                    .font(.system(size: 13))
            }
            .foregroundStyle(t.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(t.surface, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(t.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(auth.busy)
    }

    private func avatar(_ url: URL?, _ t: Theme) -> some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 22))
                .foregroundStyle(t.muted)
        }
        .frame(width: 28, height: 28)
        .clipShape(Circle())
        .accessibilityHidden(true)   // the name beside it already says who this is
    }
}

#Preview {
    NavigationStack { ProfileView() }
}
