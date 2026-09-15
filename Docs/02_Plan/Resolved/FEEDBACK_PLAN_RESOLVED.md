# Feedback — Resolved Plan

Two ways to complain, one Settings section. **Email** hands a pre-addressed draft to the
Mac's mail client; **Write a message** opens a notepad sheet and files the text into a
Firestore `complaints` collection under the signed-in account.

> **Provenance.** Resolves every finding in
> [FEEDBACK_PLAN_AUDIT.md](../Audit/FEEDBACK_PLAN_AUDIT.md) against
> [FEEDBACK_PLAN.md](../FEEDBACK_PLAN.md) (audit verdict: *Fix blockers first* — 1 blocker,
> 4 majors, 6 minors, 4 coverage gaps). **This document is standalone**: build from it
> without reading either predecessor. §1 carries the resolution log so the trail survives.
>
> Nothing here has been compiled or run. Code shapes are written against the files they go
> in and every API named was checked for existence and for macOS 14.0 availability, but the
> plan has not been through a build.

---

## 0. Stack, as re-grounded

| | Verified at |
|---|---|
| macOS 14.0 min · SwiftUI · MVVM | `project.pbxproj:376, 403` |
| `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (both targets) | `project.pbxproj:383, 410, 566, 603` |
| `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` — **app target only** | `project.pbxproj:568, 605` |
| Firebase Auth + GoogleSignIn linked; **no Firestore SDK** | `AuthViewModel.swift:23–25` |
| `PROJECT_ID = one-word-a2f3a` | `OneWord/GoogleService-Info.plist` |
| Sandbox on; `com.apple.security.network.client` **already present** | `OneWord/OneWord.entitlements` |
| New files join the target automatically | `fileSystemSynchronizedGroups`, `project.pbxproj:243–245` |
| No test target — verification is `tools/check_*.sh` compiling by explicit path | `tools/check_learned.sh:15–40` |

Files opened to ground this plan: `AuthViewModel.swift` (whole), `SettingsView.swift`
(whole), `HistoryView.swift:40–182`, `ProfileView.swift:1–80, 340–420`, `Theme.swift:1–62`,
`OneWordApp.swift`, `OneWord.entitlements`, `GoogleService-Info.plist`, all five
`tools/check_*.sh`, `project.pbxproj:360–620`.

---

## 1. Resolution log

**11 self-resolved · 2 operator decisions (both confirmed live) · 1 settled upstream ·
1 accepted as-is · 1 deferred.** Blocker cleared; no finding left unaddressed.

### Blocker

| # | Resolution |
|---|---|
| **B1** — Phase 1 called itself shippable but referenced `reset()` (Phase 2) and a sheet (Phase 3). | **Self-resolved**, option (a). Phase 1 is now the **Email row only** — no `FeedbackViewModel` instance, no `writing` state, no `reset()`. The second row, the `@State` and the `.sheet` all move to Phase 3, where the view they drive exists. Phase 1 compiles and ships as one file plus one section. |

### Majors

| # | Resolution |
|---|---|
| **M1** — the copied pattern fails silently, so "proven" was unproven. | **Self-resolved.** Phase 0 now opens with a console **precondition**: confirm `users/{your-uid}` exists with a `joined` timestamp before touching rules. Grounding: `AuthViewModel.swift:264–283` has an empty `catch` and signals success only into the private key `profileJoinedSynced.<uid>` — the app is bit-identical whether that POST has ever returned 200. |
| **M2** — client cap (4,000 Swift `Character`s) sat adjacent to the rule ceiling (5,000 `size()`), on a Devanagari-bearing field. | **Self-resolved.** Rule ceiling widened to **20,000**; the client now also gates on `trimmed.utf8.count <= 16000` so it can never build a payload the rule refuses. Correct under every reading of `rules.String.size()` — the exact unit stays `[Unverified]` and no longer matters. |
| **M3** — `FeedbackView` read `@Environment(\.colorScheme)` inside a separately-windowed presentation. | **Self-resolved.** `Theme` is handed in as `let theme: Theme`, matching `InfoButton(text:theme:)` (`SettingsView.swift:181–183`, whose comment states the reason) and `HistoryView.picker(_ t:)` (`HistoryView.swift:157`). Grounded: `Theme` is a plain struct (`Theme.swift:13`), so it passes as a stored property. |
| **M4** — no accessibility, in a view layer carrying 18 a11y modifiers. | **Self-resolved**, using the **house idiom rather than a new one**: element-collapse + label, as at `ProfileView.swift:229–230` and `LearnedListView.swift:184–185`. Rejected `@AccessibilityFocusState` — available on macOS 14, but there is no `FocusState` precedent anywhere in this codebase and a form does not need one. |

### Minors

| # | Resolution |
|---|---|
| `import AppKit` rationale imprecise | **Self-resolved.** §4.2 now says it correctly: under `MEMBER_IMPORT_VISIBILITY` the **members** (`.shared`, `.open(_:)`) need the direct import, not the type name — same mechanism as `ProfileView.swift:20`'s `import Combine`. The instruction is unchanged; only the reason is now right. |
| One `guard` reported three failures as "Sign in" | **Self-resolved.** Split in §5.2: a nil `user` gets sign-in copy; a nil `FirebaseApp` (SwiftUI previews — `AuthViewModel.restore():130–143` documents the same case) or a nil URL gets neutral copy. |
| Bare uncancelled `Task` | **Self-resolved** as a comment, not a change. Finishing the write after a dismissal is the wanted outcome; the comment says so, so the next reader doesn't "fix" it. |
| `mailFailed` renders above the section's `note:` | **Accepted as-is.** `section()` emits content then note (`SettingsView.swift:124–142`). A transient error above a static footnote is the right precedence; no change. |
| Draft dies on a pane switch | **Self-resolved** as documentation. Stated in §6 rather than discovered later. |
| Network entitlement never mentioned | **Self-resolved.** §7 now states it is already present, so the question is closed rather than merely unasked. |

### Coverage gaps

| Gap | Resolution |
|---|---|
| Accessibility | Closed — see M4 and §6.3. |
| No concurrency analysis | **Self-resolved.** New §5.3 states the isolation map and why it is race-free. |
| Signed-out state unstated | **Self-resolved.** §5.2 notes there is no release signed-out path (`RootView` gates the shell), so the sign-in guard is reachable only under the DEBUG bypass. |
| Rules Playground had no oversize test | **Self-resolved.** Added as §7 step 7. |

### Operator decisions

| Question | Decision |
|---|---|
| Build the Phase 4 gate? | **Deferred — confirmed by the operator.** §7 steps 3 and 4 verify the payload end-to-end against the real database and the real mail client, which is stronger than a unit test over a dictionary literal. **Flip condition:** the payload grows a computed field or a second writer — then extract `Complaint` into `OneWord/Models/` and add `tools/check_feedback.sh`. That route is confirmed workable: the existing scripts do compile `OneWord/Models/*.swift` (`check_learned.sh` compiles `LearnedWords.swift`, `Wordbook.swift`). |
| Keep the version/OS trailer in the mailto body? | **Kept — confirmed by the operator.** Three lines; an email otherwise carries no build metadata at all. |
| Collection named `complaints`? | **Settled upstream** — the operator specified it in the original request. Not re-opened. Note it becomes load-bearing in the rules and in any later Cloud Function. |
| Hide the message row under the DEBUG bypass? | **Recommended default applied** *(review queue, §9)*: keep the row visible and let Send fail with the now-accurate message. Debug-only either way, and hiding it means the debug build stops exercising the row you actually ship. |

---

## 2. Scope

**In.** A Feedback section in Settings with two rows; a `mailto:` path; a notepad sheet that
writes one document per complaint to `complaints`; the Firestore rule that permits it.

**Out.** Attachments, categories, offline queueing, rate limiting, reading complaints back
in-app, email notification on write. §10 says when each earns its place.

**Done when.** The build and all five gates are green, and §7's seven manual steps pass.

---

## 3. Architecture fit

| It… | Goes | Rule it obeys |
|---|---|---|
| drives the sheet, owns the draft, makes the POST | `OneWord/ViewModels/FeedbackViewModel.swift` | `@Observable`, no SwiftUI import |
| is the sheet | `OneWord/Views/FeedbackView.swift` | no persistence, no URL building, no Firebase type named |
| is the way in | `OneWord/Views/SettingsView.swift` (edit) | reuses the existing section/card/row helpers |

**Nothing goes in `OneWord/Shared/`.** That folder compiles into the widget (which links no
Firebase) and into `tools/check_*.sh` with bare `swiftc` — the constraint `AuthViewModel`'s
own header states. **No `project.pbxproj` work**: the `OneWord` target carries
`fileSystemSynchronizedGroups`, and no gate script names any file this plan touches
(verified across all five).

**No `FirebaseFirestore`.** `publishJoinDate` already argues the trade — the SDK drags gRPC,
leveldb and abseil in to write a handful of fields. The REST POST is ~15 lines. Add the SDK
the day something needs offline queueing or live listeners; this is neither.

---

## 4. Phase 0 — Firestore

Do this before writing Swift. Skipping it produces a `403` in Phase 2 that looks like a bug
in code that is already correct.

### 4.1 Precondition — is the write path alive at all?

Open Firestore → Data and confirm a **`users/{your-uid}` document with a `joined`
timestamp** exists.

This is not busywork. `publishJoinDate` swallows every failure by design
(`AuthViewModel.swift:264–283`: empty `catch`, success recorded only into the private
defaults key `profileJoinedSynced.<uid>`). The app looks and behaves identically whether
that POST has been returning 200 since it shipped or `403` every launch. **If the document
is absent, the REST+token pattern has never succeeded in this project** — fix the `users`
rule now, as part of this phase, rather than discovering it through the complaint form.

### 4.2 Publish the rule

```
match /complaints/{id} {
  // Create-only, filed under your own uid, never readable from the app.
  allow create: if request.auth != null
                && request.resource.data.userID == request.auth.uid
                && request.resource.data.message is string
                && request.resource.data.message.size() > 0
                && request.resource.data.message.size() < 20000;
  allow read, update, delete: if false;
}
```

An addition — leave your existing `match /users/{uid}` block alone. Two things to note:

- Rules see the **decoded** document, so it is `data.userID`, not the REST
  `{"stringValue": …}` envelope the app sends.
- **20,000, deliberately loose.** This ceiling exists to keep a pasted crash log out of a
  1 MiB document, not to enforce the UI's limit. The client's own cap is 4,000 characters
  and 16,000 UTF-8 bytes (§5.1) — comfortably inside, whatever unit `size()` counts. Setting
  it tight is what would make a long Devanagari message fail server-side with no recourse.
- `allow read: if false` matters: the app never lists complaints. You read them in the
  console.

---

## 5. Phase 1 — the email path

**Ships alone.** One new file, one new section, no view-model instance, no sheet. Nothing
below this phase is needed for a user to reach you.

### 5.1 NEW — `OneWord/ViewModels/FeedbackViewModel.swift`

At this phase the type is **statics only**; Phase 2 fills in the draft and the send. It is
declared as the final `@Observable final class` from the start so Phase 2 is an addition
rather than a rewrite.

```swift
//
//  FeedbackViewModel.swift
//  OneWord
//
//  Sending a complaint. The email path needs no state — a mailto URL handed to
//  LaunchServices is the whole feature — so this type is really the notepad: the
//  draft, and the one POST that files it.
//
//  App target ONLY, same rule as AuthViewModel: it names FirebaseAuth.User to get
//  an ID token, and Shared/ compiles into the widget and into tools/check_*.sh with
//  bare swiftc, neither of which links Firebase.
//

import Foundation
import Observation

@Observable
final class FeedbackViewModel {

    /// Where complaints go when they go by mail. One place, because the sheet's
    /// failure copy names the same address.
    static let address = "hi.hariom.swift@gmail.com"

    /// A pre-addressed draft in whatever the Mac's mail client is. Version and OS
    /// ride along because the first reply to any bug report is "which build?" —
    /// and unlike the in-app path, an email carries no metadata otherwise.
    ///
    /// ponytail: NSWorkspace.open, not NSSharingService. The sandbox permits it —
    /// LaunchServices opens the URL in another process — so no entitlement changes.
    static var mailtoURL: URL? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let trailer = "\n\n\u{2014}\nOne Word \(version) (\(build))\n"
                    + ProcessInfo.processInfo.operatingSystemVersionString

        // Newlines and spaces are illegal in a URL. Without this the string fails
        // to parse, URL(string:) returns nil, and the button silently does nothing.
        let q = CharacterSet.urlQueryAllowed
        guard let subject = "One Word feedback".addingPercentEncoding(withAllowedCharacters: q),
              let body = trailer.addingPercentEncoding(withAllowedCharacters: q)
        else { return nil }
        return URL(string: "mailto:\(address)?subject=\(subject)&body=\(body)")
    }
}
```

`.urlQueryAllowed` leaves `&` and `=` unescaped — fine, because neither the subject nor the
trailer contains either. Keep it that way if you edit the copy.

### 5.2 MODIFIED — `OneWord/Views/SettingsView.swift`

**Add `import AppKit`** at the top, beside `import SwiftUI` and `import WidgetKit`. The app
target sets `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`
(`project.pbxproj:568, 605`), under which the **members** `.shared` and `.open(_:)` require
AppKit to be directly imported — the type name alone may resolve transitively. Exactly the
mechanism behind `ProfileView.swift:20`'s `import Combine` for `NotificationCenter.publisher`.

New state:

```swift
@State private var mailFailed = false
```

New section, appended after the existing `section("Progress", t)` block inside the same `VStack`:

```swift
section("Feedback", t,
        note: "Bugs, a wrong meaning, a word you'd like added \u{2014} all of it helps.") {
    card(t) {
        Button { openMail() } label: {
            row("Email", "Opens a draft in your mail app.", t) {
                Image(systemName: "envelope")
                    .font(.system(size: 14)).foregroundStyle(t.muted)
            }
            // `row` ends at .padding with no contentShape of its own (unlike
            // ProfileView's), so a bare Button would be hittable on the glyphs only.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens a new message to \(FeedbackViewModel.address)")
    }
    if mailFailed {
        // A dead button is worse than an address you can select and copy. It
        // renders above the section's note; a transient error outranking a
        // static footnote is the right way round.
        Text("No mail app is set up on this Mac. Write to \(FeedbackViewModel.address).")
            .font(.system(size: 11))
            .foregroundStyle(t.muted)
            .textSelection(.enabled)
    }
}
```

And the action:

```swift
private func openMail() {
    guard let url = FeedbackViewModel.mailtoURL, NSWorkspace.shared.open(url) else {
        mailFailed = true
        return
    }
    mailFailed = false
}
```

**Verify Phase 1:** builds; Settings shows one Feedback row; clicking it opens an addressed
draft.

---

## 6. Phase 2 — the draft and the send

Additions to `FeedbackViewModel`. Add `import FirebaseCore` and `import FirebaseAuth` to the
file's imports.

### 6.1 State and the two ceilings

```swift
/// The draft. It lives here rather than in the sheet so a failed send keeps the
/// text — the view redraws, the words don't go anywhere.
var text = ""

private(set) var sending = false
private(set) var error: String?
/// Set once the POST lands. The sheet swaps to the thank-you on this.
private(set) var sent = false

/// What the counter counts.
static let limit = 4000
/// What the rule actually enforces. Devanagari costs up to 3 UTF-8 bytes per
/// scalar and a Swift Character can be several scalars, so a message inside
/// `limit` is not automatically inside the server's ceiling. Gate on both, and
/// keep this well under the rule's 20,000 so the two can never disagree.
static let byteLimit = 16000

var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

var canSend: Bool {
    !trimmed.isEmpty
        && trimmed.count <= Self.limit
        && trimmed.utf8.count <= Self.byteLimit
        && !sending
}

/// Called as the sheet opens, so a second visit isn't greeted by the last visit's
/// thank-you or its error. `text` is deliberately untouched — an unsent draft
/// survives a dismissal.
func reset() {
    sent = false
    error = nil
}
```

### 6.2 The send

```swift
/// Files the draft as one document in `complaints`.
///
/// ponytail: a POST, not FirebaseFirestore — the same trade publishJoinDate makes
/// and for the same reason. Unlike that one there is no `documentId=`: a person
/// files more than one complaint, so Firestore assigns the id.
func send(as auth: AuthViewModel) async {
    guard canSend else { return }

    // The DEBUG bypass hands out a demo identity with no Firebase account behind
    // it — no uid to file under, no token to sign with. In release there is no
    // signed-out state at all (RootView gates the whole shell), so this guard is
    // reachable only under that bypass.
    guard let user = auth.user else {
        error = "Sign in with your account to send a message."
        return
    }
    // Separate, because neither of these is a sign-in problem: a nil FirebaseApp
    // is a SwiftUI preview (AuthViewModel.restore() documents the same case), and
    // a nil URL would be a typo in the line above.
    guard let project = FirebaseApp.app()?.options.projectID,
          let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(project)"
                        + "/databases/(default)/documents/complaints")
    else {
        error = "Couldn't reach the server. Email it to \(Self.address) instead."
        return
    }

    sending = true
    error = nil
    defer { sending = false }

    // The name you set on your profile, else the account's — the same precedence
    // the sidebar chip and the Profile header use.
    let chosen = UserDefaults.standard.string(forKey: "profileName") ?? ""
    let username = chosen.isEmpty ? (auth.displayName ?? "") : chosen

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try? JSONSerialization.data(withJSONObject: [
        "fields": [
            "userID":   ["stringValue": user.uid],
            "username": ["stringValue": username],
            "email":    ["stringValue": user.email ?? ""],
            "message":  ["stringValue": trimmed],
            // Client clock. createTime is server-set but isn't orderable in a
            // query, and sorting the inbox by date is the point of the field.
            "sentAt":   ["timestampValue": ISO8601DateFormatter().string(from: .now)],
        ]
    ])

    do {
        // The Firebase ID token, not the Google one: the rule matches on
        // request.auth.uid, which only a Firebase token carries.
        let token = try await user.getIDToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            error = "Couldn't send that. Try again, or email it to \(Self.address)."
            return
        }
        text = ""
        sent = true
    } catch {
        self.error = "Couldn't send that. Try again, or email it to \(Self.address)."
    }
}
```

Three things that are deliberate and must not be trimmed:

- **`text` is cleared only on 200.** Every other path leaves the draft alone. This is the
  one place `publishJoinDate`'s silent-retry policy would be wrong to copy — it is correct
  *there* because a bookkeeping write is not the user's words.
- **The sign-in guard is not defensive noise.** `AuthViewModel.isSignedIn` returns `true`
  for a `DemoUser` with no uid and no token (`AuthViewModel.swift:41–47, 55–75`).
- **`user.email`, not `auth.email`.** The latter falls back to the demo address in DEBUG,
  and a real `user` is already established by this point.

### 6.3 Concurrency & state model

Stated because the audit found it absent, not because it is complicated:

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (`project.pbxproj:566, 603`) makes
  `FeedbackViewModel` **and** `AuthViewModel` MainActor-isolated without annotation.
  `send(as:)` is therefore a MainActor async method receiving a MainActor object —
  **no isolation boundary is crossed and no `Sendable` conformance is needed.**
- `URLSession.shared.data(for:)` performs its work off-main and resumes on MainActor.
  No main-thread block. Identical to `publishJoinDate`, which is proven in this app.
- `sending = true` is set **synchronously**, before any `await`, and `canSend` includes
  `!sending` while the button carries `.disabled(!model.canSend)` — so a double-send is
  impossible by construction, not by timing.
- The draft survives a dismissed sheet (`@State` on `SettingsView` outlives the sheet) but
  **not** a pane switch — `RootView`'s `detail` switch rebuilds `SettingsView`. Acceptable;
  documented so it isn't later mistaken for a bug.

---

## 7. Phase 3 — the sheet

### 7.1 NEW — `OneWord/Views/FeedbackView.swift`

Dumb view: no persistence, no URL building, no Firebase type named. Two states.

```swift
struct FeedbackView: View {
    /// Handed in, never read from the environment. The appearance override is
    /// applied once at the window root (OneWordApp.swift:27) and a sheet is its
    /// own window — the same reason InfoButton takes `theme` (SettingsView.swift:181)
    /// and HistoryView hands `t` to picker(_:) (HistoryView.swift:157).
    let theme: Theme
    /// Owned by SettingsView, so the draft outlives a dismissed sheet.
    @Bindable var model: FeedbackViewModel
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if model.sent { thanks } else { compose }
        }
        .frame(width: 520, height: 430)
        .background(theme.background)
    }
}
```

`compose` is History's sheet shape exactly — serif title, muted caption, trailing button,
a hairline, then the content:

- **Header.** `Text("Write to us").font(.serif(19)).foregroundStyle(theme.ink)`; caption
  `"It reaches Hari with your name and email attached."` — say plainly what is sent;
  `Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)`.
- **Rule.** `Rectangle().fill(theme.hairline).frame(height: 1)`.
- **Editor.** `TextEditor(text: $model.text)` with `.scrollContentBackground(.hidden)`
  (without it, `TextEditor` paints its own background and ignores the theme),
  `.background(theme.background)`, `.font(.system(size: 13))`, `.padding(16)`,
  `.accessibilityLabel("Your message")`.
- **Footer.** The error in red when `model.error != nil`; a muted
  `"\(model.trimmed.count)/\(FeedbackViewModel.limit)"` counter that turns red past the
  limit; and

```swift
Button("Send") {
    // Unstructured and deliberately not cancelled: if the sheet closes mid-flight,
    // finishing the write is the outcome we want. Not an oversight.
    Task { await model.send(as: auth) }
}
.keyboardShortcut(.return, modifiers: .command)
.disabled(!model.canSend)
```

`thanks` is a centered serif "Thanks — that's on its way.", a muted second line, and
`Button("Done") { dismiss() }`, carrying

```swift
.accessibilityElement(children: .combine)
.accessibilityLabel("Sent. Thanks \u{2014} that's on its way.")
```

— the collapse-and-label idiom used at `ProfileView.swift:229–230` and
`LearnedListView.swift:184–185`. *[Unverified]* whether VoiceOver announces the swap
without explicit focus management; §8 step 6 checks it, and the fallback is three lines of
`@AccessibilityFocusState`.

Staying on the sheet to confirm the send is eight lines and removes all doubt; dismissing
straight back to Settings would show nothing.

`#Preview` needs `.environment(AuthViewModel())` and an explicit theme, like `RootView`'s.

### 7.2 MODIFIED — `OneWord/Views/SettingsView.swift`

New state:

```swift
@State private var feedback = FeedbackViewModel()
@State private var writing = false
```

The second row, added inside the Phase 1 `card(t)` after a `rule(t)`:

```swift
rule(t)
Button { feedback.reset(); writing = true } label: {
    row("Write a message", "Send it from here \u{2014} no mail app needed.", t) {
        Image(systemName: "square.and.pencil")
            .font(.system(size: 14)).foregroundStyle(t.muted)
    }
    .contentShape(Rectangle())
}
.buttonStyle(.plain)
```

And the presentation, beside the existing modifiers on the `ScrollView`. `t` is the
`let t = Theme.of(scheme)` already at the top of `body`, so the sheet gets the same theme
the pane is painted with:

```swift
.sheet(isPresented: $writing) { FeedbackView(theme: t, model: feedback) }
```

`FeedbackView` reads `AuthViewModel` from the environment, which `OneWordApp` injects at the
root and a sheet inherits from its presenter.

---

## 8. Verify

Both green before this is done, per `CLAUDE.md`:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture check_sentences; do bash tools/$s.sh; done
```

The gates should be untouched — nothing in `Shared/` moves and no script names a new file
(verified across all five). A red gate here means something unrelated broke.

Manual, in order. Steps 3 and 4 are what stands in for the deferred gate, so do not skip them.

1. **Precondition.** Firestore → Data → `users/{your-uid}` exists with `joined` (§4.1).
2. **Rules.** Publish §4.2.
3. **Email.** Settings → Feedback → Email opens a draft to `hi.hariom.swift@gmail.com`,
   subject filled, version + OS in the body, **no `%20` or `%0A` visible in the composed
   draft** — that is the escaping check. Then unset the default mail client and confirm the
   fallback line appears instead of nothing happening.
4. **Send.** Write a message, Send, see the thank-you. Firestore → `complaints` shows one
   document carrying `userID`, `username`, `email`, `message`, `sentAt` — **that is the
   payload check**, against the real database rather than a mock.
5. **Failure keeps the draft.** Wi-Fi off, Send: the error appears **and the text is still
   in the editor**. Wi-Fi on, Send again: it goes.
6. **Accessibility.** VoiceOver on: the editor announces as "Your message"; after Send, the
   thank-you is announced. If it is not, add `@AccessibilityFocusState` to the thank-you.
7. **Rules hold — both denials.** In the Rules Playground simulate a `create` on
   `/complaints/x` (a) with `userID` set to another uid, and (b) with a `message` of 25,000
   characters. Both must deny.
8. **Debug bypass.** Launch with `-debugSkipAuth YES`, open the sheet, Send — expect
   "Sign in with your account to send a message.", not a Firebase error.
9. **Dark mode.** Open the sheet with Appearance forced to Dark. The sheet background, the
   editor and the text must all be dark — this is what M3's fix exists for.

---

## 9. Operator review queue

One decision applied by recommended default; accept or override.

| Decision | Applied | Alternative | Flips when |
|---|---|---|---|
| The "Write a message" row stays visible under the DEBUG bypass and fails at Send with an accurate message. | §7.2 as written. | Disable the row with a "sign in to send" caption when `auth.user == nil`. | You find yourself hitting the dead Send often enough in debug runs to be worth two lines. |

Already confirmed live, recorded so the trail is complete: the Phase 4 gate is **deferred**
(flip: the payload grows a computed field or a second writer); the mailto version/OS trailer
is **kept**.

---

## 10. Risks & exits

| Risk | Leading indicator | Cheapest exit |
|---|---|---|
| The `users` precondition (§4.1) comes back empty — the REST pattern never worked here | No `users/{uid}` document despite signing in repeatedly | Fix the `users` rule first. If REST turns out to be blocked for a structural reason (no database provisioned), the write path — not the feature — needs re-deciding; that is a `/strategize` question, not a plan edit. |
| The sheet still renders light in forced-Dark despite M3's fix | §8 step 9 | Add `.preferredColorScheme(...)` to `FeedbackView`'s root as well; the theme is already threaded so the copy is one line. |
| `rules.String.size()` counts a unit that makes even 16,000 bytes too many *[Unverified]* | §8 step 7(b) denies a message that should pass | Raise the rule ceiling; it is loose on purpose and has no reason to be tight. |
| VoiceOver does not announce the compose→thanks swap *[Unverified]* | §8 step 6 | Three lines of `@AccessibilityFocusState` on the thank-you. |

---

## 11. Deliberately not in v1

| Skipped | Add when |
|---|---|
| The Phase 4 gate (`Complaint` struct + `check_feedback.sh`) | The payload grows a computed field or a second writer. Route confirmed workable — the gate scripts already compile `OneWord/Models/*.swift`. |
| Attaching logs, screenshots, or the current word | Someone's report is unactionable without it. |
| A category picker (bug / word / other) | Volume makes an unsorted inbox painful. |
| Reading your own past complaints in-app | Probably never — that is a support inbox, not a feature. |
| Offline queueing / retry | The draft survives a failure and the error says to try again. A queue means the Firestore SDK. |
| Rate limiting | A rule on `request.time` versus a `lastComplaint` doc — only if someone actually floods it. |
| Email notification when one lands | A Cloud Function on `complaints/{id}` create. Entirely separable. |
