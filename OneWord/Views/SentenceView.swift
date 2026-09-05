//
//  SentenceView.swift
//  OneWord
//
//  The Practice pane. A sentence rolls up like a slot reel and lands; space
//  reveals the German; space again rolls the next one. Dumb view — the corpus
//  is a value type, so there is no view model to hold.
//

import SwiftUI
import AppKit

/// The roll's sound, loaded once — same shape as WordDetail's file-scope speaker.
/// `byReference: true` keeps the 15s file on disk instead of in memory: the roll
/// only ever uses its first couple of seconds, and `stop()` cuts it there.
@MainActor private let shuffleSound = Bundle.main
    .url(forResource: "practice_sentence_shuffle", withExtension: "wav")
    .flatMap { NSSound(contentsOf: $0, byReference: true) }

struct SentenceView: View {
    /// Roll shape. Every letter flickers, then locks in left to right on an
    /// ease-out, so the sentence lands rather than stops. `tick` is floored well
    /// above `Task.sleep`'s 10–20ms of scheduling slop; below that the flicker is
    /// jitter, not designed motion.
    private static let tick = 0.055
    private static let rollDuration = 2.1
    /// Letters only. Spaces and punctuation are never scrambled — keeping the word
    /// shapes means you read a sentence settling, not a block of noise.
    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
    /// Three lines at the reel's type size. Fixed, because the window has to be
    /// a window — a reel that resizes per sentence isn't a reel.
    private static let reelHeight: CGFloat = 150

    @State private var shown = Sentences.random()
    @State private var revealed = false
    @State private var rolling = false
    /// What the reel shows mid-roll. Non-nil only while rolling; `shown` does not
    /// change until the letters land, so a cancelled roll leaves the sentence be.
    @State private var scrambled: String?
    /// Bumping this is how a new roll starts: `.task(id:)` cancels the running
    /// one and begins again, so a second roll can never overlap the first and
    /// leaving the pane tears the roll down for free.
    @State private var rollToken = 0
    /// The last token actually rolled. `.task(id:)` fires on every *re-appear* too
    /// — window occluded, Space switched, app hidden — and without this the pane
    /// silently replaces the sentence you were reading and drops your reveal.
    @State private var rolledToken = -1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let t = Theme.of(scheme)
        ScrollView {
            VStack(spacing: 0) {
                reel(t)
                german(t)
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 56)
            .padding(.vertical, 44)
            // Centred in the pane rather than hugging the top. Measured against the
            // ScrollView, which is already sized — `maxHeight: .infinity` here has
            // no ideal height, and the window grew 835 -> 3296pt every visit.
            .containerRelativeFrame(.vertical)
        }
        // Same shape as WordDetail: the ScrollView fills the pane, so the paint
        // reaches the edges without anything claiming infinite height.
        .scrollContentBackground(.hidden)
        .background(t.background)
        .overlay(alignment: .topTrailing) { hint(t) }
        .contentShape(Rectangle())
        // Space is the primary control, but a keyboard-only feature is
        // undiscoverable and unreachable — the whole pane is also a click target.
        .onTapGesture { advance() }
        .task(id: rollToken) {
            guard rolledToken != rollToken else { return }
            rolledToken = rollToken
            await performRoll()
        }
        .navigationTitle("Practice")
        // One element, one label: the reel changes identity 12 times a roll, and
        // without this VoiceOver announces every step of it.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(announcement)
        .accessibilityHint(revealed ? "Press space for a new sentence"
                                    : "Press space for the translation")
        // VoiceOver never sees .onTapGesture, and its focus is not key focus, so
        // without this the pane is unusable with the screen reader on.
        .accessibilityAction(.default) { advance() }
        // Space via a key equivalent, not .focusable()/.onKeyPress. The sidebar is
        // a List and owns first responder in a NavigationSplitView, so claiming
        // focus from here is a fight this pane loses and the spacebar does nothing.
        // A key equivalent is consulted before the responder chain, so it needs no
        // focus at all. Attached AFTER the accessibility element: inside it, the
        // button folds into the collapsed pane and VoiceOver fires advance twice.
        .background {
            Button("", action: advance)
                .keyboardShortcut(.space, modifiers: [])
                .opacity(0)
                .accessibilityHidden(true)
        }
    }

    // MARK: - Pieces

    /// The reel window. No transition and no `.id()`: the letters are the motion,
    /// so this is a plain Text whose string changes every tick. `.clipped()` on the
    /// fixed frame is what keeps it a window when a sentence runs long.
    private func reel(_ t: Theme) -> some View {
        Text(scrambled ?? shown.en)
            .font(.serif(56))
            .foregroundStyle(t.ink)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .top)
            .frame(height: Self.reelHeight, alignment: .top)
            .clipped()
            .opacity(revealed ? 0.6 : 1)
    }

    /// The answer. WordDetail's Hindi carries an accent rule down its left, but a
    /// left rule fights a centred block — colour and size carry the distinction here.
    private func german(_ t: Theme) -> some View {
        Text(shown.de)
            .font(.serif(48))
            .foregroundStyle(t.definition)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 24)
            // Always in the layout, only faded. If it were inserted on reveal the
            // whole centred block would jump every time you pressed space — the
            // reel above is fixed-height for the same reason.
            .opacity(revealed ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: revealed)
    }

    /// The pane has to teach its own method — a sentence sitting on screen
    /// explains neither what to do with it nor that space is the control. Parked
    /// in the corner so the sentence stays the only thing in the middle.
    private func hint(_ t: Theme) -> some View {
        Text("Tap space to see answer and go to next question")
            .font(.system(size: 11))
            .foregroundStyle(t.muted)
            //.opacity(rolling ? 0 : 1)
            //.animation(.easeOut(duration: 0.15), value: rolling)
            .padding(.top, 22)
            .padding(.trailing, 28)
            // A hint is not a target: the click belongs to the pane behind it.
            .allowsHitTesting(false)
    }

    // MARK: - Behaviour

    /// One key, three states: rolling ignores, unrevealed reveals, revealed rolls.
    private func advance() {
        guard !rolling else { return }
        if revealed { rollToken += 1 } else { revealed = true }
    }

    private func performRoll() async {
        revealed = false
        let target = Sentences.random(excluding: shown)
        guard !reduceMotion else {
            // Flickering letters are exactly what this setting turns off. Land directly.
            shown = target
            return
        }
        rolling = true
        // Rewound rather than resumed: `stop()` leaves the playhead where it cut.
        shuffleSound?.currentTime = 0
        shuffleSound?.play()
        // All three undone on every exit, cancellation included — so leaving the
        // pane mid-roll kills the sound too, and the file never plays past the
        // animation. `advance()` refuses to bump the token while rolling, so no
        // live roll is ever cancelled by a new one; a leaked `rolling` here would
        // freeze the pane for good.
        defer { rolling = false; scrambled = nil; shuffleSound?.stop() }

        let letters = Array(target.en)
        let frames = max(1, Int(Self.rollDuration / Self.tick))
        for frame in 1...frames {
            let p = Double(frame) / Double(frames)
            // Ease-out on the lock front: most letters settle early, the last few
            // take the longest, which is what reads as landing instead of stopping.
            let locked = Int((1 - pow(1 - p, 2)) * Double(letters.count))
            scrambled = String(letters.indices.map { i in
                guard i >= locked, letters[i].isLetter else { return letters[i] }
                let r = Self.alphabet.randomElement()!
                return letters[i].isUppercase ? Character(r.uppercased()) : r
            })
            do { try await Task.sleep(for: .seconds(Self.tick)) } catch { return }
        }
        shown = target
    }

    private var announcement: String {
        if rolling { return "Rolling" }
        return revealed ? "\(shown.en). German: \(shown.de)" : shown.en
    }
}

#Preview {
    NavigationStack { SentenceView() }
}
