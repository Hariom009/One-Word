//
//  WelcomeView.swift
//  OneWord
//
//  The front door when Features.accounts is off: the wordmark, one field for
//  your name, and Get Started. The name goes to the local profile and nowhere
//  else — there is no account to attach it to. Shown once; RootView keeps the
//  "onboarded" flag so clearing the name later in Profile doesn't bring it back.
//

import SwiftUI
import WidgetKit

struct WelcomeView: View {
    static let onboardedKey = "onboarded"

    @AppStorage("profileName") private var profileName = ""
    @AppStorage(Self.onboardedKey) private var onboarded = false
    @State private var draft = ""
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.doodle) private var doodle

    private var name: String { draft.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        let t = Theme.of(scheme, doodle)
        VStack(spacing: 16) {
            Spacer()
            Text("One Word")
                .font(doodle.face(34))
                .tracking(doodle.tracking(34))
                .foregroundStyle(t.ink)
            Text("enrich your vocab by only one word a day")
                .font(doodle.face(12))
                .foregroundStyle(.primary.opacity(0.6))
            Spacer()
            VStack(spacing: 10) {
                TextField("Your name", text: $draft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(t.ink)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(t.surface, in: RoundedRectangle(cornerRadius: t.radius(16)))
                    .overlay(RoundedRectangle(cornerRadius: t.radius(16)).strokeBorder(t.hairline))
                    .focused($focused)
                    .onSubmit(start)
                Button(action: start) {
                    Text("Get Started")
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(t.background)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(t.ink, in: RoundedRectangle(cornerRadius: t.radius(16)))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(name.isEmpty)
                .opacity(name.isEmpty ? 0.5 : 1)
                Text("Stays on this Mac. No account, nothing is sent anywhere.")
                    .font(.system(size: 10))
                    .foregroundStyle(t.muted)
                    .padding(.top, 4)
                    .padding(.horizontal,8)
                    .lineLimit(1)
            }
            .frame(width: 300)
        }
        .padding(.all, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paneBackground(t)
        .onAppear { focused = true }
    }

    private func start() {
        guard !name.isEmpty else { return }
        profileName = name
        // ponytail: off for new users only. Written here, not as the @AppStorage
        // default, so readers who onboarded earlier (key absent = shown) keep it on.
        AppGroup.defaults.set(false, forKey: "showExample")
        WidgetCenter.shared.reloadAllTimelines()
        onboarded = true
    }
}

#Preview {
    WelcomeView()
        .frame(width: 1000, height: 680)
}
