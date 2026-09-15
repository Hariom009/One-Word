# Feedback — Plan

Two ways to complain, one Settings section. **Email** hands a pre-addressed draft to the
Mac's mail client; **Write a message** opens a notepad sheet and files the text into a
Firestore `complaints` collection under the signed-in account.

> **Scope.** Everything below is grounded in the code as it stands on `feat/firebase-auth`
> (HEAD `83b076d`). Nothing here has been built or compiled yet — the code shapes are
> written to match the file they go in, not run.

---

## 1. What we're reusing (and what we're not adding)

The whole feature is a re-run of machinery already in this repo. Named up front so the
build is copy-shaped rather than invention-shaped.

| Need | Already here | File |
|---|---|---|
| Write a document to Firestore | `publishJoinDate()` — REST `POST`, Firebase ID token in `Authorization` | [AuthViewModel.swift:242](../../OneWord/ViewModels/AuthViewModel.swift) |
| Who the user is | `auth.user` (uid, email), `auth.displayName`, `profileName` in defaults | `AuthViewModel`, `Profile.swift` |
| Section / card / hairline / row layout | `section()`, `card()`, `rule()`, `row()` | [SettingsView.swift:124](../../OneWord/Views/SettingsView.swift) |
| A fixed-size themed sheet | `.sheet(isPresented:)` → `.frame(width:height:).background(t.background)` | [HistoryView.swift:157](../../OneWord/Views/HistoryView.swift) |
| Opening a mail draft | — | native: `NSWorkspace.open(mailto:)` |
| A multi-line editor | — | native: `TextEditor` |

**Not added:** `FirebaseFirestore`. `AuthViewModel` already documents why — the SDK drags
gRPC, leveldb and abseil in to write a handful of fields. The REST `POST` is ~15 lines and
the pattern is already proven in this codebase. Add the SDK the day something needs offline
queueing or live listeners; a fire-and-report complaint form is neither.

**Not added:** a `.feedback` sidebar pane. The sidebar is reading panes. Settings already
owns every "about the app, not about the words" control, and it already has the layout
helpers — so the section costs no new layout code.

---

## 2. Decisions

| Decision | Choice | Why |
|---|---|---|
| Where it lives | A **Feedback section at the bottom of Settings**, two rows | Reuses `section`/`card`/`row`/`rule` verbatim. No new pane, no new `Pane` case, no sidebar change. |
| Email path | `NSWorkspace.shared.open(mailto:…)` | One line. Sandbox-safe (LaunchServices opens it out of process — **no entitlement change**). |
| Message path | A sheet, not a pushed view | Settings is a leaf pane with no `NavigationStack` of its own. Same idiom as History's dictionary sheet. |
| Document id | **Auto-assigned** — no `documentId=` in the URL | Unlike `users/{uid}`, a person files more than one complaint. Dropping the parameter is the only structural change from the `publishJoinDate` template. |
| Timestamp | A written `sentAt` field | Firestore's own `createTime` exists but **is not orderable in a query**. An inbox you can't sort by date is not an inbox. One line. |
| Collection name | `complaints` (as asked); UI says **Feedback** | Someone reporting a wrong Hindi meaning isn't complaining. The wire name is yours; the copy is theirs. |
| Failure | Keep the draft, show the message, offer the email address | The one place in this app where silence loses the user's words. `publishJoinDate`'s silent-retry policy is correct *there* and wrong *here*. |

---

## 3. Firestore rules — do this first

There is no `firestore.rules` in the repo, so this is a **console change**, and it is
**Phase 0**: skip it and Phase 2 returns `403 PERMISSION_DENIED` and you spend the evening
debugging Swift that is already correct.

```
match /complaints/{id} {
  // Create-only, filed under your own uid, and never readable from the app.
  allow create: if request.auth != null
                && request.resource.data.userID == request.auth.uid
                && request.resource.data.message is string
                && request.resource.data.message.size() > 0
                && request.resource.data.message.size() < 5000;
  allow read, update, delete: if false;
}
```

Leave whatever `match /users/{uid}` block you already have alone — this is an addition.
Note that rules see the **decoded** document, so it is `data.userID`, not the REST
`{"stringValue": …}` envelope the app sends.

`allow read: if false` matters: the app never lists complaints, so nothing should be able
to read another user's report. You read them in the console.

---

## 4. Files

| File | Status | Holds |
|---|---|---|
| `OneWord/ViewModels/FeedbackViewModel.swift` | **new** | The draft, the `POST`, the mailto URL, the address. |
| `OneWord/Views/FeedbackView.swift` | **new** | The notepad sheet — dumb view. |
| `OneWord/Views/SettingsView.swift` | edit | The Feedback section + sheet presentation. |
| `OneWord/Models/Complaint.swift` | **optional** (§8) | The payload as a Foundation-only struct, so it can be gated. |

App-target only. **Nothing goes in `Shared/`** — that folder compiles into the widget
(which links no Firebase) and into `tools/check_*.sh` with bare `swiftc`. Same constraint
`AuthViewModel`'s header already states.

No `project.pbxproj` work: `OneWord/` is a file-system-synchronized group, so both new
files join the target on creation. No gate script names them, so none needs updating.

---

## 5. Phase 1 — the email path

Ships on its own. Nothing below it is needed for a user to reach you.

### 5.1 `FeedbackViewModel` — the two statics

Even in Phase 1, the address and URL live in the view model so there is exactly one
place that knows where complaints go (the sheet's failure copy names it too).

```swift
/// Where complaints go when they go by mail.
static let address = "hi.hariom.swift@gmail.com"

/// A pre-addressed draft in whatever the Mac's mail client is. Version and OS ride
/// along because the first reply to any bug report is "which build?".
///
/// ponytail: NSWorkspace.open, not NSSharingService — the sandbox permits it
/// (LaunchServices opens the URL in another process), so no entitlement changes.
static var mailtoURL: URL? {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
    let trailer = "\n\n\u{2014}\nOne Word \(version) (\(build))\n"
                + ProcessInfo.processInfo.operatingSystemVersionString

    // Newlines and spaces are illegal in a URL. Without this the string fails to
    // parse, `URL(string:)` returns nil, and the button silently does nothing.
    let q = CharacterSet.urlQueryAllowed
    guard let subject = "One Word feedback".addingPercentEncoding(withAllowedCharacters: q),
          let body = trailer.addingPercentEncoding(withAllowedCharacters: q)
    else { return nil }
    return URL(string: "mailto:\(address)?subject=\(subject)&body=\(body)")
}
```

`.urlQueryAllowed` leaves `&` and `=` unescaped — fine here, because nothing in the
subject or trailer contains either. Keep it that way if you edit the copy.

### 5.2 `SettingsView` — the section

Appended after the existing `section("Progress", t)` block, inside the same `VStack`.

```swift
section("Feedback", t,
        note: "Bugs, a wrong meaning, a word you'd like added \u{2014} all of it helps.") {
    card(t) {
        Button { openMail() } label: {
            row("Email", "Opens a draft in your mail app.", t) {
                Image(systemName: "envelope")
                    .font(.system(size: 14)).foregroundStyle(t.muted)
            }
            // `row` has no contentShape of its own, so a bare Button would only
            // be hittable on the glyphs. This makes the whole row the target.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        rule(t)
        Button { feedback.reset(); writing = true } label: {
            row("Write a message", "Send it from here \u{2014} no mail app needed.", t) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14)).foregroundStyle(t.muted)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    if mailFailed {
        // A dead button is worse than an address you can select and copy.
        Text("No mail app is set up on this Mac. Write to \(FeedbackViewModel.address).")
            .font(.system(size: 11))
            .foregroundStyle(t.muted)
            .textSelection(.enabled)
    }
}
```

New state on `SettingsView`:

```swift
@State private var feedback = FeedbackViewModel()
@State private var writing = false
@State private var mailFailed = false
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

**`import AppKit`** must be added at the top of `SettingsView.swift`. This target builds
with `MEMBER_IMPORT_VISIBILITY` — the same reason `ProfileView.swift` names `import Combine`
for `NotificationCenter.publisher`. `NSWorkspace` will not resolve through `import SwiftUI`
alone.

---

## 6. Phase 2 — the view model's send

```swift
//
//  FeedbackViewModel.swift
//  OneWord
//
//  Sending a written complaint. The email path needs no state — a mailto URL handed
//  to LaunchServices is the whole feature — so this type is really the notepad: the
//  draft, and the one POST that files it.
//
//  App target ONLY, same rule as AuthViewModel: it names FirebaseAuth.User to get an
//  ID token, and Shared/ compiles into the widget and into tools/check_*.sh with bare
//  swiftc, neither of which links Firebase.
//

import Foundation
import Observation
import FirebaseCore
import FirebaseAuth

@Observable
final class FeedbackViewModel {
    /// The draft. It lives here rather than in the sheet so a failed send keeps the
    /// text — the view redraws, the words don't go anywhere.
    var text = ""

    private(set) var sending = false
    private(set) var error: String?
    /// Set once the POST lands. The sheet swaps to the thank-you on this.
    private(set) var sent = false

    /// Firestore's document ceiling is 1 MiB. This sits far below it and exists to
    /// keep a pasted crash log out of the inbox, not to fight the limit.
    static let limit = 4000

    var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    var canSend: Bool { !trimmed.isEmpty && trimmed.count <= Self.limit && !sending }

    /// Called as the sheet opens, so a second visit isn't greeted by the last
    /// visit's thank-you or its error.
    func reset() {
        sent = false
        error = nil
    }
}
```

The send itself:

```swift
/// Files the draft as one document in `complaints`.
///
/// ponytail: a POST, not FirebaseFirestore — the same trade `publishJoinDate` makes
/// and for the same reason. Unlike that one there is no `documentId=`: a person can
/// file more than one complaint, so Firestore assigns the id.
func send(as auth: AuthViewModel) async {
    guard canSend else { return }
    // The DEBUG bypass hands out a demo identity with no Firebase account behind
    // it — no uid to file under, no token to sign with. Real state, real message.
    guard let user = auth.user,
          let project = FirebaseApp.app()?.options.projectID,
          let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(project)"
                        + "/databases/(default)/documents/complaints")
    else {
        error = "Sign in with your account to send a message."
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

Three things that are deliberate and shouldn't be trimmed:

- **`text` is only cleared on 200.** Every other path leaves the draft alone.
- **The sign-in guard is not defensive noise.** `AuthViewModel` ships a `#if DEBUG`
  bypass whose `DemoUser` has no uid and no token, and `isSignedIn` returns `true` for it.
  Without this guard a debug run's Send button fails at `getIDToken()` with a Firebase
  error string the user can't act on.
- **`auth.email` vs `user.email`.** Read `user.email` — `auth.email` falls back to the
  demo address in DEBUG, and we've already established there's a real `user` by here.

---

## 7. Phase 3 — the sheet

`OneWord/Views/FeedbackView.swift`. Dumb view: no persistence, no URL, no Firebase type
named. Two states — compose, and thanks.

```swift
struct FeedbackView: View {
    /// Owned by SettingsView so the draft outlives a dismissed sheet.
    @Bindable var model: FeedbackViewModel
    @Environment(AuthViewModel.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.of(scheme)
        VStack(spacing: 0) {
            if model.sent { thanks(t) } else { compose(t) }
        }
        .frame(width: 520, height: 430)
        .background(t.background)
    }
}
```

`compose(t)` is History's sheet shape exactly — serif title + muted caption + a trailing
button, a hairline, then the content:

- Header: `Text("Write to us").font(.serif(19))`, caption
  `"It reaches Hari with your name and email attached."` (say so plainly — the user
  should know what's sent), and a `Button("Cancel") { dismiss() }.keyboardShortcut(.cancelAction)`.
- `Rectangle().fill(t.hairline).frame(height: 1)`.
- `TextEditor(text: $model.text)` with `.scrollContentBackground(.hidden)`,
  `.background(t.background)`, `.font(.system(size: 13))`, padding 16.
- Footer bar: the error in red if `model.error != nil`; a muted
  `"\(model.trimmed.count)/\(FeedbackViewModel.limit)"` counter that turns red over the
  limit; and

```swift
Button("Send") {
    Task { await model.send(as: auth) }
}
.keyboardShortcut(.return, modifiers: .command)
.disabled(!model.canSend)
```

`thanks(t)` is a centered serif "Thanks — that's on its way." plus a muted line and a
`Button("Done") { dismiss() }`. Staying on the sheet to say it is 8 lines and removes any
doubt about whether Send worked; dismissing straight to Settings would show nothing.

Wire-up in `SettingsView`, beside the existing modifiers on the `ScrollView`:

```swift
.sheet(isPresented: $writing) { FeedbackView(model: feedback) }
```

`FeedbackView` reads `AuthViewModel` from the environment, which `OneWordApp` injects at
the root — but **a sheet is its own presentation and inherits the environment from the
presenting view**, so this resolves. The `#Preview` will not: give it
`.environment(AuthViewModel())` like `RootView`'s does.

---

## 8. Phase 4 — optional: a gate

Skippable. Phase 3 ships without it.

The only logic here with a real failure mode is the payload shape and the mailto
escaping. Neither can be gated as written, because `tools/check_*.sh` compiles Swift by
explicit path with bare `swiftc` and `FeedbackViewModel.swift` imports Firebase.

If you want it gated, the payload has to move first:

- `OneWord/Models/Complaint.swift` — a Foundation-only struct
  (`userID/username/email/message/sentAt`) with `var firestoreFields: [String: Any]`,
  plus `static func mailtoURL(address:version:build:os:)` taking its inputs rather than
  reading `Bundle`.
- `tools/ComplaintCheck.swift` + `tools/check_feedback.sh` on the existing pattern:
  assert every field is present and `stringValue`-wrapped, that `sentAt` parses back as
  ISO8601, and that a body containing a newline and an em-dash produces a non-nil URL.
- The VM then builds a `Complaint` and POSTs `firestoreFields`.

That is one extra small file for one runnable check. Worth it if the payload ever grows a
second field; not worth blocking Phase 3 on.

---

## 9. Verify

Both green before this is done, per `CLAUDE.md`:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture check_sentences; do bash tools/$s.sh; done
```

The gates should be unaffected — no file in `Shared/` moves and no script names a new
file — so a red gate here means something unrelated broke.

Manual, in order:

1. **Rules first.** Firestore console → Rules → publish §3.
2. **Email.** Settings → Feedback → Email opens a draft addressed to
   `hi.hariom.swift@gmail.com`, subject filled, version + OS in the body, no `%20`
   visible in the composed draft. Then with no default mail client set, confirm the
   fallback line appears instead of nothing happening.
3. **Send.** Write a message, Send, see the thank-you. Firebase console → Firestore →
   `complaints` shows one document with your uid, name, email, text and `sentAt`.
4. **Failure keeps the draft.** Turn Wi-Fi off, Send, confirm the error appears **and the
   text is still in the editor**. Turn Wi-Fi on, Send again, it goes.
5. **Debug bypass.** Launch with `-debugSkipAuth YES`, open the sheet, Send — expect
   "Sign in with your account to send a message.", not a Firebase error.
6. **Rules hold.** In the console's Rules Playground, simulate a `create` on
   `/complaints/x` with `userID` set to someone else's uid — it must deny.
7. **Both appearances.** The sheet inherits `preferredColorScheme` from the root
   (unlike a popover — see `SettingsView`'s `InfoButton` comment), but look at it in dark
   mode anyway; `TextEditor` needs `.scrollContentBackground(.hidden)` or it paints its
   own white.

---

## 10. Deliberately not in v1

| Skipped | Add when |
|---|---|
| Attaching logs, screenshots, or the current word | Someone's report is unactionable without it. |
| A category picker (bug / word / other) | Volume makes an unsorted inbox painful. |
| Reading your own past complaints back in-app | Never, probably — that's a support inbox, not a feature. |
| Offline queueing / retry | The draft survives a failure and the error says to try again. A queue means the Firestore SDK. |
| Rate limiting | A rule with `request.time` vs a `lastComplaint` doc — only if someone actually floods it. |
| Email notification when one lands | A Cloud Function on `complaints/{id}` create. Nice, and entirely separable. |
