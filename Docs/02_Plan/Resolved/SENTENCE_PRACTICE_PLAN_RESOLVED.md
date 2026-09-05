# Sentence Practice — Resolved Plan

A Practice pane: a random English sentence rolls up like a slot reel and lands, space reveals
its German, space again rolls the next one.

> **Provenance.** The first-pass plan and its audit were worked through in session on
> 2026-09-03/04 and were never filed as `02_Plan/SENTENCE_PRACTICE_PLAN.md` /
> `Audit/SENTENCE_PRACTICE_PLAN_AUDIT.md`. §1 therefore carries the audit's findings in full
> rather than linking them, so this document stands alone. Nothing else in the trail is missing.
>
> **Every code shape below was type-checked under the project's real build flags** — Swift 5
> *and* Swift 6 language modes, `-target arm64-apple-macos14.0`, `-default-isolation MainActor`,
> `MemberImportVisibility`, `NonisolatedNonsendingByDefault` — and the check script in §7 was
> compiled with `-O` and **run**, including a deliberately injected off-by-one to confirm it
> goes red (exit 133) rather than silently passing. The one exception is stated in §5.4: the
> reel's `.push` transition type-checks but has **not** been looked at on screen.

---

## 1. Resolution log

Fourteen findings came out of the audit. Nine changed the design; five downgraded a claim.

### Blockers — would have cost a debugging session

| # | Finding | Resolution |
|---|---|---|
| **B1** | `.animation(_:value:)` on the same `Text` whose `.id()` changes cannot reliably drive the transition — the modifier belongs to the view being *removed*. | Dropped. The roll now calls **`withAnimation` at the mutation site** (§5.4). Fewer modifiers, unambiguous semantics. |
| **B2** | A constant animation duration is wrong for a decelerating roll: ~5 overlapping transitions at the start, a stalled reel at the end. | Each step animates for **exactly its own sleep duration** (`withAnimation(.linear(duration: d))` then `sleep(for: .seconds(d))`), so exactly one transition is ever in flight. Shorter than the original *and* correct. |
| **B3** | `random(excluding:)` written as reject-and-retry never terminates on a one-entry corpus. | Rewritten as **index arithmetic** — draw in `0..<count-1`, shift past the excluded index. O(1), no loop, provably terminates. The check in §7 verifies both the exclusion *and* that the shift introduces no bias. |

### Medium — would have bitten

| # | Finding | Resolution |
|---|---|---|
| **M4** | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (verified on all four build configs) means `enum Sentences` is MainActor-isolated in the app but *nonisolated* under the plain-`swiftc` check script — one source, two meanings. | Both `Sentence` and `Sentences` are declared **`nonisolated`**, matching `WordProvider` and `AppGroup`, with the same explanatory comment. |
| **M5** | The sidebar at `RootView.swift:79` is a `List`; on macOS a List takes key focus and treats space as page-scroll. Most likely reason the feature does nothing on first run. | `.focusable()` + `.focusEffectDisabled()` + `@FocusState` claimed in `.task`, and `.onKeyPress` returns `.handled` to stop propagation. **Flagged in §9 as run-to-confirm** — this one cannot be settled by reading. |
| **M6** | The roll was a bare `Task` with no cancellation. `WordViewModel.shuffle()` already documents this exact hazard for its peek timer. | Replaced with **`.task(id: rollToken)`**. SwiftUI cancels the running roll when the token changes or the pane goes away, so a double-start is impossible *by construction* and teardown is free — no stored `Task`, no `[weak self]`. |
| **M7** | Plan put the files in `OneWord/Shared/`, whose headers all declare "member of app + widget targets". `check_related.sh` carries a NOTE about exactly this for app-only `RelatedWords.swift`. | Both files go in **`OneWord/`**. See the correction below — this finding got *bigger*. |

### Accessibility the first pass claimed and did not deliver

| # | Finding | Resolution |
|---|---|---|
| **A8** | No Reduce Motion path, on a feature whose entire premise is a spinning animation. | `@Environment(\.accessibilityReduceMotion)` short-circuits `performRoll()` to land directly on the next sentence. |
| **A9** | 12 identity changes per roll = up to 12 VoiceOver announcements. | `.accessibilityElement(children: .ignore)` collapses the pane to one element, and its label is the constant `"Rolling"` while rolling — so the value does not change mid-roll at all. |

### Scope

| # | Finding | Resolution |
|---|---|---|
| **S10** | The German pronunciation button was **scope creep the plan invented** — not requested. It also needs a guard: this Mac has exactly one `de_DE` voice, and `AVSpeechSynthesisVoice(language:)` returns nil when absent, leaving the utterance to read German aloud in an English voice. | **Cut from v1.** Noted in §9. `speaker` in `WordDetail.swift:15` stays `private`. |

### Claims downgraded

- **D11 — the reel is weaker than it was sold.** `.push(from:)` moves a view by *its own* frame
  height, not the clip window's, so a one-line sentence in a three-line window slides one line,
  not three. It compiles (`push(from:)` is macOS 13.0+), it just isn't Vegas. §5.4, §9.
- **D12 — `Task.sleep` jitter** is 10–20ms; the original 25ms first step was >50% slop.
  Floored at **30ms**, named as a constant with the reason.
- **D13 — first-appear state was undefined.** `.task(id:)` fires on appear, so the pane rolls
  once on arrival. No other pane opens empty.
- **D14 — missing house conventions:** `navigationTitle`, `.background(t.background)`,
  `#Preview` (8 of 8 view files have one). All present in §5.
- **A correction the audit itself got wrong.** The audit said both files need adding to the app
  target and `sentences.json` to a Resources phase. **False.** The app target `OneWord` carries
  `fileSystemSynchronizedGroups = /* OneWord */` and its Resources phase is **empty**; the
  populated Resources phase (all ten dictionary JSONs) belongs to **`OneWordWidget`**, which has
  no sync group. So anything under `OneWord/` — `.swift` and `.json` alike — is compiled and
  bundled into the app automatically. Combined with **M7**: there is **zero project-file work**
  in this change. `ARCHITECTURE.md` and `RELATED_WORDS_PLAN.md §1` both already say this; the
  audit failed to read them.

### Verified and unchanged

macOS 14.0 on all four configs · `.onKeyPress` + `KeyEquivalent.space` at macOS 14.0 ·
`AnyTransition.push(from:)` at macOS 13.0 · `focusEffectDisabled` at macOS 14.0 ·
no `Sentence`/`Sentences` name collision · the two-file split (the check script must compile the
data layer without SwiftUI) · `tools/check_words.sh` is green at baseline.

One claim got **stronger**: this SDK ships `Translation.framework` with a **Mac Catalyst
interface only** (`arm64e-apple-ios-macabi.swiftinterface`) — there is no native macOS
`translationTask` here at all. Bundling the German is not a deployment-target workaround, it is
the only option.

---

## 2. Grounding

**Files read:** `RootView.swift`, `WordView.swift`, `WordDetail.swift`, `WordViewModel.swift`,
`Wordbook.swift`, `DictionaryPicker.swift`, `SettingsView.swift`, `OneWordApp.swift`,
`Shared/Word.swift`, `Shared/WordProvider.swift`, `Shared/Theme.swift`, `Shared/AppGroup.swift`,
`LearnedWords.swift`, `tools/WordProviderCheck.swift`, `tools/check_words.sh`,
`tools/check_related.sh`, `tools/gen_words/README.md`, `docs/00_Context/ARCHITECTURE.md`,
`docs/README.md`, `OneWord.xcodeproj/project.pbxproj`.

| | Detected | Evidence |
|---|---|---|
| Platform | **macOS, min 14.0** | `SDKROOT = macosx`; `MACOSX_DEPLOYMENT_TARGET = 14.0` × 4 configs |
| Default isolation | **`MainActor`** | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` × 4 |
| Language mode | **Swift 5** | `SWIFT_VERSION = 5.0` |
| App target membership | **automatic** — synchronized root group | `OneWord` target: `fileSystemSynchronizedGroups`; Resources phase **empty** |
| Widget target membership | **explicit** — hand-listed | `OneWordWidget`: no sync group; Resources phase holds all 10 JSONs |
| Translation at runtime | **unavailable** | `Translation.framework` ships only `arm64e-apple-ios-macabi.swiftinterface` |
| Testing | **no test target** — standalone `swiftc` checks | `tools/check_*.sh`; `-O` strips `assert()`, so `precondition` |

**Consequence that shapes the change:** app-only is free, and `Shared/` is a lie for app-only
files. Two new files under `OneWord/`, five lines in `RootView.swift`, nothing else.

---

## 3. Scope & outcome

**Done when:** a **Practice** row sits in the sidebar between *Learned* and *Bookmarks*. Opening
it rolls a sentence and lands on one. Pressing space (or clicking anywhere in the pane) reveals
the German beneath it with an accent rule, matching how `WordDetail` treats the Hindi. Pressing
space again rolls the next. With Reduce Motion on, sentences change without the roll. VoiceOver
reads one element, once per landing.

**Not in scope:** progress/streak tracking, a language picker, pronunciation, the widget.

---

## 4. Data layer — `OneWord/Sentences.swift` (new)

`sentences.json` sits beside it at `OneWord/sentences.json`: a flat array of `{"en", "de"}`.
Deliberately **not** reusing `Word` — three of its five fields would be empty and the names
would lie.

```swift
import Foundation

/// One practice pair. Plain value type: no UI, no platform imports.
nonisolated struct Sentence: Codable, Hashable, Identifiable {
    let en: String
    let de: String

    /// Stable id — the English sentence is unique in `sentences.json` (checked).
    var id: String { en }
}

// nonisolated for the same reason as WordProvider: the target defaults to
// MainActor isolation, but tools/check_sentences.sh compiles this file with
// plain swiftc, which does not. Marking the type gives both builds one meaning.
nonisolated enum Sentences {
    /// Decoded once — a `static let` initializer runs exactly once, lazily, so
    /// this needs none of WordProvider's NSCache machinery.
    static let all: [Sentence] = {
        guard let url = Bundle.main.url(forResource: "sentences", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            fatalError("sentences.json is missing from the bundle — check target membership")
        }
        let list = decode(data)
        precondition(!list.isEmpty, "sentences.json is empty")
        return list
    }()

    /// The seam the check script uses: it has a file path, not a bundle.
    static func decode(_ data: Data) -> [Sentence] {
        do { return try JSONDecoder().decode([Sentence].self, from: data) }
        catch { fatalError("sentences.json failed to decode: \(error)") }
    }

    /// A random pair that is never `excluding`.
    ///
    /// Index arithmetic, not reject-and-retry: retry never terminates on a
    /// one-entry corpus, and "not the same twice" is impossible there anyway —
    /// so a lone entry is returned rather than looped on.
    /// `corpus` is injectable for the same reason WordProvider's init is: the
    /// check script has no bundle to read `all` from.
    static func random(excluding: Sentence? = nil, in corpus: [Sentence] = all) -> Sentence {
        guard let excluding, corpus.count > 1,
              let skip = corpus.firstIndex(of: excluding) else {
            return corpus.randomElement()!
        }
        let i = Int.random(in: 0..<(corpus.count - 1))
        return corpus[i < skip ? i : i + 1]
    }
}
```

---

## 5. View — `OneWord/SentenceView.swift` (new)

### 5.1 State machine

One key, three states. `advance()` is the whole of it:

| state | space does |
|---|---|
| rolling | ignored |
| landed, English only | reveal the German |
| revealed | bump `rollToken` → roll the next |

### 5.2 Why `.task(id: rollToken)` and not a stored `Task`

Bumping the token *is* the cancel-and-restart, so two rolls can never overlap and leaving the
pane tears the roll down without an `onDisappear`. The cancelled roll returns from its `sleep`
**without clearing `rolling`** — the task that replaced it owns that flag — which closes the
last-writer race a `defer` would have opened.

### 5.3 Why the `ZStack` in the reel

Load-bearing: old and new sentence must coexist for the push to read as motion. A `VStack` would
reflow instead. `.clipped()` on the fixed-height frame is what makes it a slot *window*.

### 5.4 The code

```swift
import SwiftUI

struct SentenceView: View {
    /// Reel shape. The roll eases out — steps get longer — so it lands rather
    /// than stops. `firstStep` is floored well above `Task.sleep`'s 10–20ms of
    /// scheduling slop; below that the roll is jitter, not designed motion.
    private static let steps = 12
    private static let firstStep = 0.03
    private static let lastStep = 0.16
    /// Three lines at the reel's type size. Fixed, because the window has to be
    /// a window — a reel that resizes per sentence isn't a reel.
    private static let reelHeight: CGFloat = 150

    @State private var shown = Sentences.random()
    @State private var revealed = false
    @State private var rolling = false
    /// Bumping this is how a new roll starts: `.task(id:)` cancels the running
    /// one and begins again, so a second roll can never overlap the first and
    /// leaving the pane tears the roll down for free.
    @State private var rollToken = 0
    @FocusState private var focused: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let t = Theme.of(scheme)
        VStack(alignment: .leading, spacing: 0) {
            reel(t)
            if revealed { german(t) }
            Spacer(minLength: 0)
            hint(t)
        }
        .frame(maxWidth: 720, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 56)
        .padding(.vertical, 44)
        .background(t.background)
        .contentShape(Rectangle())
        // Space is the primary control, but a keyboard-only feature is
        // undiscoverable and unreachable — the whole pane is also a click target.
        .onTapGesture { advance() }
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress(.space) { advance(); return .handled }
        // The sidebar is a List, and on macOS a List takes key focus and treats
        // space as page-scroll. Without claiming focus here the spacebar does nothing.
        .task { focused = true }
        .task(id: rollToken) { await performRoll() }
        .navigationTitle("Practice")
        // One element, one label: the reel changes identity 12 times a roll, and
        // without this VoiceOver announces every step of it.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(announcement)
        .accessibilityHint(revealed ? "Press space for a new sentence"
                                    : "Press space for the translation")
    }

    // MARK: - Pieces

    /// The reel window. The ZStack is load-bearing: old and new have to coexist
    /// for the push to read as motion, and a VStack would reflow instead.
    /// `.clipped()` on the fixed frame is what makes it a slot window.
    private func reel(_ t: Theme) -> some View {
        ZStack(alignment: .topLeading) {
            Text(shown.en)
                .font(.serif(38))
                .foregroundStyle(t.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .id(shown.en)
                .transition(.push(from: .bottom))
        }
        .frame(height: Self.reelHeight, alignment: .topLeading)
        .clipped()
    }

    /// The German, treated like WordDetail's Hindi: an accent rule down the left.
    private func german(_ t: Theme) -> some View {
        Text(shown.de)
            .font(.serif(28))
            .foregroundStyle(t.definition)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.leading, 18)
            .overlay(alignment: .leading) { Rectangle().fill(t.rule).frame(width: 2) }
            .padding(.top, 26)
            .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func hint(_ t: Theme) -> some View {
        Text(revealed ? "Space · next sentence" : "Space · show German")
            .font(.system(size: 10, weight: .bold))
            .textCase(.uppercase).tracking(1.6)
            .foregroundStyle(t.muted)
            .opacity(rolling ? 0 : 1)
            .animation(.easeOut(duration: 0.15), value: rolling)
            .padding(.top, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .top) { Rectangle().fill(t.hairline).frame(height: 1) }
            .padding(.top, 34)
    }

    // MARK: - Behaviour

    /// One key, three states: rolling ignores, unrevealed reveals, revealed rolls.
    private func advance() {
        guard !rolling else { return }
        if revealed { rollToken += 1 } else { withAnimation { revealed = true } }
    }

    private func performRoll() async {
        revealed = false
        guard !reduceMotion else {
            // A spinning reel is exactly what this setting turns off. Land directly.
            shown = Sentences.random(excluding: shown)
            return
        }
        rolling = true
        for step in 0..<Self.steps {
            let d = Self.firstStep + (Self.lastStep - Self.firstStep)
                * pow(Double(step) / Double(Self.steps - 1), 2)
            // Animate for exactly this step's length, so one transition is ever
            // in flight. A constant duration would overlap five at the start and
            // stall the reel at the end.
            withAnimation(.linear(duration: d)) {
                shown = Sentences.random(excluding: shown)
            }
            // Cancelled (pane left, or a new roll started): return WITHOUT
            // clearing `rolling` — the task that replaced us owns that flag now.
            do { try await Task.sleep(for: .seconds(d)) } catch { return }
        }
        rolling = false
    }

    private var announcement: String {
        if rolling { return "Rolling" }
        return revealed ? "\(shown.en). German: \(shown.de)" : shown.en
    }
}

#Preview {
    NavigationStack { SentenceView() }
}
```

**The one unverified shape.** Everything above type-checks in Swift 5 and Swift 6, but whether
`.id` + `.transition(.push)` + per-step `withAnimation` *looks* like a reel has not been seen on
screen. Per **D11** the push travels the text's own height, so expect a shorter throw than a real
slot machine. `steps`, `firstStep`, `lastStep` and `reelHeight` are the four knobs; tune them
against the running app, not against this document.

---

## 6. Wiring — `OneWord/RootView.swift` (5 lines)

```swift
// 1. enum Pane
case home, history, learned, practice, bookmarks, profile, search, dictionaries, settings

// 2. var title
case .practice: "Practice"

// 3. var symbol          (idioms already owns quote.bubble.fill)
case .practice: "text.bubble"

// 4. var detail
case .practice: SentenceView()

// 5. sidebar ForEach
ForEach([Pane.home, .history, .learned, .practice, .bookmarks, .profile]) { item in
```

**No `.xcodeproj` change.** See the correction in §1.

---

## 7. Verification — `tools/check_sentences.sh` + `tools/SentencesCheck.swift`

Follows `check_related.sh` exactly, NOTE comment included. **`precondition`, not `assert`** —
the script compiles with `-O`, which strips `assert()` outright, the trap
`WordProviderCheck.swift` already documents.

```sh
#!/bin/sh
# Self-check for the practice corpus and the reel's draw.
# NOTE: Sentences.swift lives in OneWord/, not OneWord/Shared/ (app-only file).
set -e
cd "$(dirname "$0")/.."
out=$(mktemp -d)/sentencecheck
swiftc -O -o "$out" OneWord/Sentences.swift tools/SentencesCheck.swift
"$out"
```

The check asserts five things — corpus non-empty and both halves present; no duplicate English
(a duplicate reads on screen as a stuck reel); no row where `en == de` (an untranslated row that
slipped the corpus build); `random(excluding:)` never returns the excluded entry over 200 draws
per entry **and terminates on a one-entry corpus**; and — the one that catches the off-by-one —
that excluding an entry leaves the draw **uniform** over the rest.

**Actually run**, against the 20-pair seed corpus, on 2026-09-04:

```
20 sentences · draw 925–1070 per entry · all checks passed
```

**And run red on purpose.** Replacing `corpus[i < skip ? i : i + 1]` with `corpus[i]` — the
classic off-by-one — makes it exit **133**. Restoring it returns exit **0**. The gate is real,
not decorative.

---

## 8. The corpus — the open fork, and the actual long pole

**The code above is about a day. ~300 verified German pairs is the project.** The first pass
filed this as a footnote; it is the larger half of the work.

- **Recommended — author ~300 A1–B1 everyday pairs**, agent-written the way the dictionaries are
  (`.claude/commands/add-dictionary.md`), then human spot-checked. A practice feature with wrong
  German is worse than no feature.
- **Fallback that ships today** — run the existing `tools/gen_words` Argos pipeline with an
  `en→de` model over the `example` fields already in the dictionaries. Free, offline,
  reproducible, matches precedent. But those are showcase sentences for rare words
  ("She breathed in the petrichor…") — poor practice material, and machine German nobody proofs.

**This decision does not block the build.** A 20-pair seed corpus already exists and passes the
check (§7); the view does not care how large the corpus is. Build §4–§7 against the seed, settle
the corpus in parallel.

---

## 9. Deferred, and what must be confirmed by running

**Deferred (YAGNI, with the trigger for each):**

- **Language picker.** German is the only language; the field is `de`. When a second lands:
  `sentences.<lang>.json` + one `@AppStorage("practiceLanguage")`.
- **Pronunciation** (S10). Needs a nil-voice guard — `AVSpeechSynthesisVoice(language: "de-DE")`
  returns nil when no German voice is installed, and the utterance then reads German in an
  English voice. Add with the guard, if ever.
- **Progress / streaks.** `LearnedWords` is the pattern to copy if practice should be tracked.
- **Widget.** Out of scope by design; keeping the files out of `Shared/` is what keeps it that way.

**Must be confirmed by running, not reading:**

1. **The spacebar actually reaches the pane** (M5). The sidebar `List` competes for key focus.
   This is the single most likely way the feature ships broken.
2. **The reel looks like a reel** (D11, §5.4). Four knobs; tune on screen.
3. **Reduce Motion** — toggle it in System Settings › Accessibility › Display and confirm
   sentences change without the roll.
