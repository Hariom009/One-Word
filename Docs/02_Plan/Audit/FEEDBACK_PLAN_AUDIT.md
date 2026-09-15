# Feedback Plan — Audit

Adversarial pass over [FEEDBACK_PLAN.md](../FEEDBACK_PLAN.md), re-grounded against the code
at `feat/firebase-auth` HEAD `83b076d`. Every citation in the plan was re-opened; nothing
below is taken from the plan's own word.

---

## 0. Grounding — what was actually opened

| Opened | Why |
|---|---|
| `OneWord.xcodeproj/project.pbxproj` (lines 360–620) | Re-detect the stack the plan assumed. |
| `OneWord/ViewModels/AuthViewModel.swift` (whole) | The REST template the plan copies. |
| `OneWord/Views/SettingsView.swift` (whole) | The helpers the plan calls and the section it appends to. |
| `OneWord/Views/HistoryView.swift:40–182` | The sheet idiom the plan claims to follow. |
| `OneWord/Views/ProfileView.swift:1–80, 340–420` | The `import Combine` precedent, the row idiom, a11y density. |
| `OneWord/Shared/Theme.swift:14–62` | Every `t.*` property and `Font.serif` the plan names. |
| `OneWord/OneWord.entitlements`, `OneWord/GoogleService-Info.plist` | Sandbox + `PROJECT_ID`. |
| `tools/check_learned.sh`, all `tools/check_*.sh` inputs | Whether any gate names a file the plan touches. |
| `OneWord/OneWordApp.swift` | Where `preferredColorScheme` is applied. |

**Stack as re-verified.** macOS 14.0 min · SwiftUI · MVVM · `SWIFT_VERSION = 5.0` ·
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (both targets) ·
`SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` (**app target only** — configs at
`project.pbxproj:568,605`) · Firebase Auth + GoogleSignIn, **no** Firestore SDK ·
no test target; verification is `tools/check_*.sh` compiling sources by explicit path.

**No discrepancy with the stack the plan claimed.** The plan's stack assumptions all hold.

---

## 1. Verdict

> **Fix blockers first** — one blocker, four majors. *Confidence: high on the blocker and on
> B/M1–M3; medium on M2's exact mechanism (tagged inline).*

The approach is sound and the grounding is unusually good for a first-pass plan — the REST
reuse, the `documentId=` delta, the DEBUG-bypass hazard and the `import AppKit` requirement
are all real and all verified. What it gets wrong is *sequencing* (a phase it calls
shippable does not compile) and a set of boundary conditions it names but does not close:
the rule ceiling versus the client cap, the sheet's appearance, and — most importantly — the
fact that the pattern it copies **fails silently by design**, so "it works today" was never
established.

None of this is a rework. All five are small, local corrections to the plan text.

---

## 2. Blocking finding

### B1 — Phase 1 does not compile standalone, contradicting its own claim

**Where:** §5, "Ships on its own", and the code block in §5.2.

**What's wrong.** §5.2's Settings section — presented as the whole of Phase 1 — contains:

```swift
Button { feedback.reset(); writing = true } label: { … }
```

`reset()` is not defined until **§6 (Phase 2)**. `FeedbackView` and the `.sheet` modifier
that consumes `writing` do not exist until **§7 (Phase 3)**. §5.1 creates
`FeedbackViewModel.swift` with only the two statics — no `reset()`, no `text`, no `sent`.

**Evidence:** the plan's own §5.1 (statics only) versus §6 (`func reset()` introduced there).
Self-contradiction inside the plan; no code file needed to see it.

**Why it's a blocker.** The audit protocol's sequencing test is "does each step compile
standalone." Phase 1 does not — it references a method that does not exist yet and sets a
`@State` flag nothing reads. Someone building strictly by phase hits a compile error on the
step the plan advertised as independently shippable.

**Fix (minimal, pick one):**

- **(a) Preferred.** Phase 1's Settings section contains the **Email row only** — drop the
  "Write a message" `Button` and the `writing`/`feedback` state from §5.2 and move them into
  Phase 3, where the sheet that consumes them lands. Phase 1 then genuinely ships alone: one
  row, one `openMail()`, no view model state at all.
- **(b)** Move the full `FeedbackViewModel` skeleton (`text`, `sending`, `error`, `sent`,
  `limit`, `trimmed`, `canSend`, `reset()`) into §5.1 and have Phase 1's second row present
  a placeholder sheet.

(a) is smaller and keeps Phase 1 honestly one file's worth of change.

---

## 3. Major findings

### M1 — The pattern the plan calls proven fails silently, so it was never proven

**Where:** §1 ("the pattern is already proven in this codebase"), §6.

**What's wrong.** `publishJoinDate` is explicitly designed to swallow every failure:

> *"Failure is deliberately silent. Signing in worked; a bookkeeping write that didn't is not
> something to put under the sign-in button"* — [AuthViewModel.swift:242–256](../../OneWord/ViewModels/AuthViewModel.swift)

and its only success signal is a private `UserDefaults` key (`profileJoinedSynced.<uid>`).
The app therefore looks and behaves **identically** whether that `POST` has ever returned
200 or has been returning `403 PERMISSION_DENIED` on every launch since the feature landed.

**Evidence:** `AuthViewModel.swift:264–283` — the `catch` is empty by design, and the
non-200/409 path writes nothing anywhere the user or the developer would see.

**Why it matters.** The plan's central reuse argument, and its §3 rules block ("leave
whatever `match /users/{uid}` block you already have alone"), both assume a working
`users/{uid}` write. If the project is still on default-deny rules, or on an expired
test-mode rule, then Phase 2 fails for a reason the plan has already told the builder to
rule out — and the debugging goes to Swift instead of to the console.

**Fix.** Add a one-line **precondition to Phase 0**, before the rules edit:

> Open Firestore → Data. Confirm a `users/{your-uid}` document with a `joined` timestamp
> actually exists. If it does not, the REST+token pattern has never succeeded in this
> project and the `users` rule must be fixed as part of Phase 0 — not assumed.

Cheap, and it converts the plan's largest unstated assumption into a two-minute check.

---

### M2 — The client cap and the rule ceiling are adjacent, on a field that will hold Devanagari

**Where:** §3 (`message.size() < 5000`) and §6 (`static let limit = 4000`,
`trimmed.count <= Self.limit`).

**What's wrong.** The two ceilings measure different things and sit only 25% apart.
Swift's `String.count` counts **grapheme clusters**; Firestore rules' `String.size()` does
not use Swift's definition. For Latin text they agree closely. For Devanagari they do not:
`क्ष` is one Swift `Character` but several Unicode scalars, so a message the client counts
as 4,000 can exceed the rule's 5,000 and be rejected server-side.

*[Unverified]* — the exact unit `rules.String.size()` returns (characters vs. scalars vs.
UTF-8 bytes) was not confirmed against Firebase's documentation in this pass. **But the fix
below is correct under every reading**, which is why this is filed as a defect rather than
an open question.

**Why it matters.** This is the app's own bilingual case — the design brief makes Devanagari
first-class — and the failure mode is the worst one available: the user's long, careful
complaint is refused with the plan's generic *"Couldn't send that. Try again"*, and trying
again fails identically, forever.

**Fix.** Two lines. Make the ceilings non-adjacent and measure the same thing:

- Rule: `request.resource.data.message.size() < 20000` — it exists to stop a pasted crash
  log reaching a 1 MiB document, not to enforce a UI limit. It does not need to be tight.
- Client: keep `limit = 4000` for the counter, but gate on
  `trimmed.utf8.count <= 16000` as well, so the client can never build a payload the rule
  will refuse.

---

### M3 — `FeedbackView` reads `@Environment(\.colorScheme)`, against this codebase's own documented rule

**Where:** §7, `@Environment(\.colorScheme) private var scheme` inside `FeedbackView`.

**What's wrong.** The appearance override is applied once, at the window root:

```swift
.preferredColorScheme((Appearance(rawValue: appearance) ?? .system).colorScheme)
```
— [OneWordApp.swift:27](../../OneWord/OneWordApp.swift)

Every separately-presented surface in this app deliberately **does not** re-read the scheme;
it receives a `Theme` from its presenter:

- `InfoButton(text:theme:)` takes `theme` as a stored property, with the reason spelled out:
  *"A popover is its own window and doesn't inherit the app's appearance override, so the
  surface is painted here rather than left to the system."* —
  [SettingsView.swift:180–200](../../OneWord/Views/SettingsView.swift)
- `HistoryView.picker(_ t: Theme)` is handed `t` computed in `HistoryView.body`, and paints
  `.background(t.background)` explicitly —
  [HistoryView.swift:157–182](../../OneWord/Views/HistoryView.swift)

The plan does the opposite, and §9 step 7 asserts the reason it is safe — *"The sheet
inherits `preferredColorScheme` from the root (unlike a popover)"* — which is an assertion
the plan makes without evidence, about the exact behaviour the codebase already has a
comment contradicting for a sibling presentation type.

*[Inference]* On macOS a `.sheet` is a separate `NSWindow`, so it is the same class of
surface as the popover; I did not run the app to confirm which way it resolves.

**Why it matters.** If it resolves the way the popover does, a user in forced-Dark sees a
light sheet — and `TextEditor` in particular paints its own background unless told not to.

**Fix.** Follow the house pattern instead of arguing with it — it costs nothing and is
correct either way:

```swift
struct FeedbackView: View {
    let theme: Theme                     // handed in, like InfoButton and picker(t)
    @Bindable var model: FeedbackViewModel
    …
}
```

and at the call site: `.sheet(isPresented: $writing) { FeedbackView(theme: t, model: feedback) }`.
Keep the explicit `.background(theme.background)` the plan already has, and add
`.scrollContentBackground(.hidden)` on the `TextEditor` (the plan has this — keep it).

---

### M4 — Accessibility is absent, and this codebase does not skip it

**Where:** the whole plan. §9 verifies appearance but never VoiceOver.

**What's wrong.** Nothing in §5, §6 or §7 carries an accessibility label, trait or
announcement. That is out of step with the surrounding code, which is consistently
annotated — 18 accessibility modifiers across the view layer, including in the very file
being edited:

- `SettingsView.swift:43` — `.accessibilityAddTraits(… .isSelected …)`
- `SettingsView.swift:198` — `.accessibilityLabel("About this setting")`
- `SentenceView.swift:99–101` — element collapse + label + hint
- `ProfileView.swift:229–230, 342–343` — combined elements with composed labels

**Why it matters.** The design brief lists VoiceOver labels as a requirement, and this is a
*form*: an unlabelled `TextEditor` and a send-result that changes silently are the two
things screen-reader users lose first.

**Fix.** Three lines, added to §7:

- `TextEditor` → `.accessibilityLabel("Your message")`.
- The send result → make the error/thank-you swap announce itself, e.g.
  `.accessibilityAddTraits(.isSummaryElement)` on the thank-you text, or the simplest
  version: give the thank-you view `.accessibilityFocused` on appear.
- The two Settings rows already read as buttons; add nothing there.

---

## 4. Minor findings & nits

- **§5.2 — the `import AppKit` rationale is right, the mechanism is imprecise.** The plan
  says *"`NSWorkspace` will not resolve through `import SwiftUI` alone."* Under
  `MEMBER_IMPORT_VISIBILITY` (verified `= YES` on both app configs) it is the **members** —
  `.shared`, `.open(_:)` — that require the direct import; the *type* name may still resolve
  transitively. Same mechanism as `ProfileView.swift:20`'s `import Combine` for
  `NotificationCenter.publisher`. The instruction stands; only the sentence needs fixing.
- **§6 — one `guard` reports three different failures as "Sign in with your account."**
  A nil `FirebaseApp` (SwiftUI previews, per `AuthViewModel.restore()`'s own note) and a
  malformed URL both produce sign-in copy. Split the `user` guard from the other two and
  give the rest a neutral string.
- **§6 — `Task { await model.send(as: auth) }` is unstructured and uncancelled.** Harmless
  here (finishing the write after a dismissal is the outcome you want), but the project has
  a documented preference against bare `Task` — worth one comment saying the non-cancellation
  is deliberate, so the next reader doesn't "fix" it.
- **§5.2 — the `mailFailed` line renders above the section's `note:`.** `section()` emits
  `content()` then `note` ([SettingsView.swift:124–142](../../OneWord/Views/SettingsView.swift)),
  so the error appears above the caption. Cosmetic; move the error out of `content` if it
  reads oddly.
- **§7 — the draft survives a dismissed sheet but not a pane switch.** `@State private var
  feedback` dies when `RootView`'s `detail` switch rebuilds `SettingsView`. Fine as designed;
  worth one line in the plan so it isn't discovered as a bug.
- **§9 — the network entitlement is never mentioned.** `com.apple.security.network.client`
  is already present (`OneWord.entitlements`), so there is nothing to do — but the plan
  should say so, since it explicitly clears mailto's entitlement question and leaves the
  `POST`'s unasked.

---

## 5. Coverage gaps

Whole dimensions the plan omitted, distinct from things it got wrong:

| Gap | Note |
|---|---|
| **Accessibility** | See M4. The only gap serious enough to be a finding as well. |
| **Concurrency analysis** | The plan never states the isolation. It happens to be fine — `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` makes `FeedbackViewModel` MainActor-isolated, `URLSession` does its work off-main, `AuthViewModel` is passed MainActor-to-MainActor with no `Sendable` crossing — but that was verified here, not there. One sentence in §6 would close it. |
| **What happens to a signed-out user's draft** | Not addressed. The DEBUG guard returns an error and keeps the text; there is no signed-out state in release (`RootView` gates the shell), so this is genuinely a non-issue — but it should be *stated*, not silent. |
| **Rules Playground is in §9 but no negative test for `message` size** | Step 6 simulates a foreign `userID`. Add the oversize-message case, which M2 shows is the likelier real-world denial. |

---

## 6. What the plan got right

Stated plainly, because it changes how the findings above should be weighted — this is a
well-grounded plan with local defects, not a plausible-sounding fiction.

- **The REST reuse is real and correctly cited.** `publishJoinDate` at
  `AuthViewModel.swift:242` does exactly what the plan says, and its own header already
  argues the SDK trade-off the plan repeats. Verified.
- **The `documentId=` delta is the correct — and the only — structural change.** Verified
  against the existing URL construction at `AuthViewModel.swift:258–262`.
- **The DEBUG-bypass hazard is real and easy to miss.** `AuthViewModel.isSignedIn` returns
  `true` for a `DemoUser` with no uid and no token (`AuthViewModel.swift:41–47, 55–75`).
  A plan that skipped this would ship a debug-only failure with an unactionable Firebase
  error string.
- **`.contentShape(Rectangle())` is genuinely required.** `SettingsView.row` (line 148)
  ends at `.padding` with no `contentShape` — unlike `ProfileView.row`, which has one. A
  bare `Button` around it would be hittable only on the glyphs. Verified.
- **`sentAt`'s justification is correct.** Firestore's `createTime` is server-set but is not
  an orderable field in a query; a written timestamp is the right call for an inbox.
- **Rules-first sequencing is right**, and for the right reason.
- **"Nothing in `Shared/`" is right.** `tools/check_*.sh` compile with bare `swiftc` and the
  widget links no Firebase — both confirmed. `Shared/` would break both.
- **"No `project.pbxproj` work" is right.** `fileSystemSynchronizedGroups` is set on the
  `OneWord` target (`project.pbxproj:243–245`), and no `check_*.sh` names any file the plan
  touches — verified across all five scripts.
- **Every API and property the plan names exists.** `t.background/surface/ink/muted/accent/
  rule/hairline` (`Theme.swift:14–22`), `Font.serif(_:_:)` (`Theme.swift:62`), and every
  macOS availability is inside the 14.0 floor (`TextEditor`, `.scrollContentBackground`
  13.0; `.textSelection` 12.0; `@Environment(\.dismiss)` 12.0). No hallucinated API found.
- **Keeping the draft on failure** is the right call and correctly reasoned as the one place
  `publishJoinDate`'s silent-retry policy must *not* be copied.
- **The percent-encoding note is correct**, including the caveat that `.urlQueryAllowed`
  leaves `&` and `=` unescaped.

---

## 7. Operator questions

Not defects — calls only you can make.

1. **The version/OS trailer in the mailto body** (§5.1) is scope the plan invented; you asked
   for "open email to write to me." Three lines, genuinely useful for triage. Keep or cut?
2. **The collection name.** `complaints` is what you asked for, and the audit kept it — but
   it will be baked into the rules and into any future Cloud Function. Confirm now rather
   than renaming later.
3. **Phase 4's gate.** The plan makes it optional. Note that `tools/check_*.sh` *do* compile
   `OneWord/Models/*.swift` (`check_learned.sh` compiles `LearnedWords.swift`, `Wordbook.swift`),
   so the `Complaint`-struct route the plan describes would work as claimed. Build it, or
   accept the payload as untested?
4. **Should the "Write a message" row be visible at all under the DEBUG bypass?** The plan
   lets you open the sheet, type, and fail at Send. Disabling the row with a "sign in to
   send" caption is fewer keystrokes wasted — but it is debug-only either way.

---

## 8. What would change the verdict

- **→ Ready to build:** fix B1's phase boundary (§5.2 loses the second row), add M1's
  two-minute console precondition, widen M2's rule ceiling, hand `Theme` into `FeedbackView`,
  and add M4's three accessibility lines. All five are edits to the plan text, not redesigns.
- **→ Needs rework:** only if M1's check comes back negative *and* the `users/{uid}` write
  turns out to be failing for a reason the REST approach cannot fix (e.g. the project has no
  Firestore database provisioned at all). In that case the write path — not the feature —
  needs re-deciding, and that is a `/strategize` question, not a plan edit.
- **Would resolve M3 either way:** running the app in forced-Dark with any sheet open. The
  fix is cheap enough that it is not worth blocking on the answer.
