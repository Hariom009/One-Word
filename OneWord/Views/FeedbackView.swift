//
//  FeedbackView.swift
//  OneWord
//
//  The notepad: write a complaint and send it from here, no mail client involved.
//  Reached from Settings' Feedback section; the other row there opens an email
//  instead and never touches this file.
//
//  Two states, one sheet — compose, then the thank-you. Staying put to confirm the
//  send is a few lines and removes all doubt; dismissing straight back to Settings
//  would show nothing at all.
//
//  Dumb view: the draft, the ceilings and the POST are all FeedbackViewModel's.
//

import SwiftUI

struct FeedbackView: View {
    /// Handed in, never read from the environment. The appearance override is
    /// applied once at the window root (OneWordApp) and a sheet is its own window —
    /// the same reason InfoButton takes `theme` and HistoryView hands `t` to its
    /// picker. `\.doodle` below is a plain environment value and does travel.
    let theme: Theme
    /// Owned by SettingsView, so an unsent draft outlives a dismissed sheet.
    @Bindable var model: FeedbackViewModel

    @Environment(\.doodle) private var doodle
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if model.sent { thanks } else { compose }
        }
        .frame(width: 520, height: 430)
        .background(theme.background)
    }

    // MARK: - Compose

    private var compose: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Write to us")
                        .font(doodle.face(19))
                        .foregroundStyle(theme.ink)
                    // Say plainly what gets sent. It is their name and address.
                    Text("It reaches Hari with your name and email attached.")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            rule

            // .scrollContentBackground(.hidden) or TextEditor paints its own
            // background and ignores the theme entirely.
            TextEditor(text: $model.text)
                .font(.system(size: 13))
                .foregroundStyle(theme.ink)
                .scrollContentBackground(.hidden)
                .background(theme.background)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .accessibilityLabel("Your message")

            rule
            footer
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if let error = model.error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("\(model.trimmed.count)/\(FeedbackViewModel.limit)")
                    .font(.system(size: 11))
                    .foregroundStyle(model.overLimit ? .red : theme.muted)
                    .monospacedDigit()
            }
            Spacer(minLength: 8)
            if model.sending {
                DoodleLoader(size: 17, road: false)
            }
            Button("Send") {
                // Unstructured and deliberately not cancelled: if the sheet closes
                // mid-flight, finishing the write is the outcome we want. The model
                // outlives the sheet, so the result lands somewhere real.
                Task { await model.send(as: auth) }
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!model.canSend)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: - Sent

    private var thanks: some View {
        VStack(spacing: 12) {
            // Combined so VoiceOver reads the outcome as one thing — but only the
            // two lines, so Done stays its own operable element.
            VStack(spacing: 6) {
                Text("Thanks \u{2014} that's on its way.")
                    .font(doodle.face(19))
                    .foregroundStyle(theme.ink)
                Text("I read every one.")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.muted)
            }
            .accessibilityElement(children: .combine)

            Button("Done") { dismiss() }
                .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var rule: some View {
        Rectangle().fill(theme.hairline).frame(height: 1)
    }
}

#Preview {
    FeedbackView(theme: .light, model: FeedbackViewModel())
        .environment(AuthViewModel())
}
