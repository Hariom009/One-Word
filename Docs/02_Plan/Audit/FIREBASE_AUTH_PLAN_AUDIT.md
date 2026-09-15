# Firebase Auth Plan — Audit

Adversarial pass over [`FIREBASE_AUTH_PLAN.md`](../FIREBASE_AUTH_PLAN.md), re-grounded against
the actual SDK sources and repo. Every claim in the plan was treated as a hypothesis to
falsify, including the ones the plan presented as already verified.

---

## Stack, as re-verified

| | Verified value | Source |
|---|---|---|
| Platform | **macOS**, not iOS | `SDKROOT = macosx`, `MACOSX_DEPLOYMENT_TARGET = 14.0`, both targets |
| UI | SwiftUI + AppKit (`NSApplicationDelegateAdaptor`) | `OneWordApp.swift:13`, `WordCapture.swift:21` |
| Architecture | MVVM, `@Observable` (Observation, not Combine `ObservableObject`) | `ProfileViewModel.swift:13` |
| Concurrency | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_VERSION = 5.0` (Swift 5 language mode, **not** Swift 6 strict concurrency) | `project.pbxproj` build settings |
| Persistence | `UserDefaults` via App Group; JSON blobs | `AppGroup.swift:35`, `SavedWords.swift:33` |
| Testing | **No XCTest target.** Four `swiftc`-compiled self-check scripts | `tools/check_*.sh` |
| Sandbox | On. App groups only — no network, no keychain | `OneWord/OneWord.entitlements` |
| Firebase | `firebase-ios-sdk` 12.18.0; Auth + Firestore + Storage on the **app target only** | `project.pbxproj` Frameworks phase `BFCC5B53…` |

**No discrepancy with the stack the plan claimed.** The plan correctly identified this as a
macOS target and correctly noted the Swift-5-mode / MainActor-default isolation.

### Files and symbols actually opened

- `OneWord.xcodeproj/project.pbxproj` — build configs, Frameworks phases, synchronized groups
- `OneWord/OneWord.entitlements`, `OneWordWidget/OneWordWidget.entitlements`
- `OneWord/Info.plist`, `OneWord/GoogleService-Info.plist`
- `OneWord/OneWordApp.swift`, `OneWord/WordCapture.swift:1-35`
- `OneWord/Views/ProfileView.swift:1-70`, `OneWord/ViewModels/ProfileViewModel.swift`
- `OneWord/Shared/AppGroup.swift`, `OneWord/Shared/SavedWords.swift:1-50`
- `tools/check_words.sh`
- FirebaseAuth 12.18.0: `Auth/Auth.swift:150-182`, `:493`, `:529`, `:583`, `:630-680`, `:1630-1690`;
  `AuthProvider/OAuthProvider.swift:226`; `AuthProvider/GoogleAuthProvider.swift:18-35`;
  `Storage/AuthKeychainServices.swift:220-245`; `Auth/AuthGlobalWorkQueue.swift:17`
- GoogleSignIn 8.0.0 + 9.2.0: `Public/GoogleSignIn/GIDSignIn.h:36-52`, `:199-250`;
  `Sources/GIDSignIn.m:149-152`, `:460-470`, `:505-560`, `:565-600`, `:745-760`, `:1155-1195` (8.0.0)
  / `:669`, `:723`, `:1351-1370` (9.2.0)

---

## Verdict

> ### Fix blockers first — high confidence

Two blockers, both in **§4 Step 4 / Step 6**, both cheap to fix (a handful of lines each).
The plan's central thesis — that this is a macOS app where the iOS Google-sign-in recipe
does not apply, for four specific reasons — **survived re-grounding intact**, and one of
those four turned out to be worse than the plan described. The architecture, the file
placement, and the `Shared/`-isolation constraint are all correct.

What failed is narrower and more embarrassing: the plan asserted a convenient
integration detail (that `GIDSignIn` self-configures from `GoogleService-Info.plist`)
without opening the file that would have refuted it, and it broke existing working code
while claiming it changed nothing.

---

## Blocking findings

### B1 — `GIDSignIn` never reads `GoogleService-Info.plist`; the flow raises an NSException

**Where:** §4 Step 4 — *"`FirebaseApp.configure()` reads `GoogleService-Info.plist` from the
bundle, and `GIDSignIn` picks up the client id from the same plist — so no `GIDClientID`
key and no hard-coded client id anywhere."*

**Evidence.** The second half of that sentence is contradicted by the source:

- `GIDSignIn.m:1351` `+configurationFromBundle:` builds `GIDConfiguration` from
  `configValueFromBundle:forKey:`, which is `[bundle objectForInfoDictionaryKey:key]` —
  **`Info.plist` only.** The keys it looks for are `GIDClientID`, `GIDServerClientID`,
  `GIDHostedDomain`, `GIDOpenIDRealm` (`:152` and below). `GoogleService-Info.plist` is
  never consulted.
- `:669` is the only site that populates `_configuration` at init, and it calls exactly that.
- When `_configuration` is nil and the flow is interactive, `:723` does
  `[NSException raise:NSInvalidArgumentException format:@"No active configuration. Make
  sure GIDClientID is set in Info.plist."]` — **an uncaught ObjC exception, i.e. a crash**,
  not an `NSError` delivered to the completion handler. `try`/`catch` will not save it.

Confirmed identical in 8.0.0 (`:576`, `:1162-1190`) and 9.2.0 (`:723`, `:1351`).

**Fix (recommended — keeps one source of truth for the client id):**

```swift
// WordCapture.swift, applicationDidFinishLaunching
FirebaseApp.configure()
// GIDSignIn only self-configures from Info.plist's GIDClientID (GIDSignIn.m:1351).
// Reading it off FirebaseApp instead keeps GoogleService-Info.plist the only place
// the client id lives.
if let clientID = FirebaseApp.app()?.options.clientID {
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
}
```

The alternative — adding `GIDClientID` to `OneWord/Info.plist` — works and needs no code,
but duplicates the client id into a second file that must be kept in sync by hand.
**Operator call; see Q1.**

**Why blocker:** without it, the first sign-in attempt terminates the app.

---

### B2 — the plan crashes `ProfileView`'s existing SwiftUI preview

**Where:** §4 Step 6 (`.task { auth.restore() }`) and §4 Step 5 (`restore()`), combined with
the closing claim *"Nothing else in the app changes."*

**Evidence.**

- `Auth.swift:150-155`: `Auth.auth()` does `guard let defaultApp = FirebaseApp.app() else {
  fatalError("The default FirebaseApp instance must be configured before the default Auth
  instance can be initialized…") }`.
- The plan puts `FirebaseApp.configure()` in `AppDelegate.applicationDidFinishLaunching`
  (`WordCapture.swift:24`). SwiftUI previews instantiate the view directly — they do not
  construct the `App`, so `@NSApplicationDelegateAdaptor` (`OneWordApp.swift:13`) never
  runs and `configure()` never fires.
- [`ProfileView.swift:68-70`](../../../OneWord/Views/ProfileView.swift) is an existing,
  currently-working `#Preview`. Adding `.task { auth.restore() }` to the body makes it
  `fatalError` on render.

**Fix:** make `restore()` a no-op when Firebase is unconfigured — one line, and it is
honest about why:

```swift
/// No-op in SwiftUI previews: they never run the AppDelegate, and Auth.auth()
/// fatalErrors without a configured FirebaseApp (Auth.swift:150).
func restore() {
    guard FirebaseApp.app() != nil else { return }
    …
}
```

Moving `configure()` into `OneWordApp.init()` also fixes it, but previews of *other* views
would then still not configure it, so the guard is the more general answer.

**Why blocker:** it breaks code that works today, in a way the plan explicitly denied.

---

## Major findings

### M1 — `currentUser` blocks the calling thread, and the plan's stated reason is wrong

**Where:** §4 Step 5 — *"Firebase restores the keychain session before this runs, so
`currentUser` is already populated on a warm launch — no round trip needed."*

**Evidence.**

- `Auth.swift:170-173`: `currentUser` is `kAuthGlobalWorkQueue.sync { _currentUser }`.
- `Auth.swift:1667-1680`: the keychain load runs in `protectedDataInitialization()` as
  `kAuthGlobalWorkQueue.async { … }`.
- `AuthGlobalWorkQueue.swift:17`: `let kAuthGlobalWorkQueue = DispatchQueue(label:
  "com.google.firebase.auth.globalWorkQueue")` — no `.concurrent` attribute, so **serial**.

The value you read is therefore correct, but *not* for the reason the plan gives. It is
correct because the `.sync` read is FIFO-queued **behind** the async keychain load and
waits for it. Since `restore()` is `MainActor`-isolated by the target default, that wait
happens on the main thread.

**Fix:** replace the polled read with the listener, which is also more correct — it keeps
`user` accurate if the session is revoked server-side or refreshed mid-run:

```swift
private var handle: AuthStateDidChangeListenerHandle?

func observe() {
    guard FirebaseApp.app() != nil else { return }   // see B2
    handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
        self?.user = user
    }
}
deinit { handle.map(Auth.auth().removeStateDidChangeListener) }
```

`[weak self]` matters — `Auth.auth()` is a long-lived singleton holding the closure, so a
strong capture would outlive the view. The plan's §4 Step 5 sketch had no listener and so
never raised this.

**Severity:** major. **Confidence:** high on the mechanism; moderate on the practical cost
— a keychain read is fast, so this is a hitch rather than a hang.

### M2 — `FirebaseCore` is neither linked nor imported

**Where:** §4 Step 4 shows `FirebaseApp.configure()` with no `import` line, and §4 Step 3
removes two of the three linked products.

**Evidence.** `FirebaseApp` is declared in `FirebaseCore`, not `FirebaseAuth`. The app
target's Frameworks phase (`project.pbxproj`, phase `BFCC5B533011545500C0FE1F`) lists
`FirebaseAuth`, `FirebaseFirestore`, `FirebaseStorage` — no `FirebaseCore`. Under Xcode
SPM, `import FirebaseCore` generally resolves through FirebaseAuth's transitive
dependency, so this may well just work — but it is implicit, and Step 3 is actively
pruning that phase.

**Fix:** add `FirebaseCore` as an explicit package product on the app target, and name
both imports in Step 4 (`import FirebaseCore`, `import GoogleSignIn`).

**Severity:** major (build risk). **Confidence:** moderate — transitive import usually
succeeds; making it explicit costs one click.

---

## Minor findings & nits

- **Version grounding.** The plan's macOS API claims were verified against a locally
  cached GoogleSignIn **8.0.0** checkout while the plan pins **9.0.0+**. Re-checked
  against 9.2.0 during this audit: `.macOS(.v10_15)` unchanged, `signInWithPresentingWindow:`
  still present, `GIDClientID`-from-Info.plist still the only config path. The
  recommendation holds — but the plan should name the version it was verified against and
  pin `from: "9.2.0"` (the current latest; available tags run 6.2.4 → 9.2.0).
- **`Package.resolved` is untracked.** `OneWord.xcodeproj/project.xcworkspace/xcshareddata/`
  is `??` in git status and is not covered by `.gitignore`. The plan adds a dependency but
  never says to commit the lockfile. Add a step.
- **`GIDSignInError.canceled` spelling.** `GIDSignIn.h:36` declares
  `NS_ERROR_ENUM(kGIDSignInErrorDomain, GIDSignInErrorCode)` with
  `kGIDSignInErrorCodeCanceled = -5`. In Swift that bridges to a `_BridgedStoredNSError`
  struct, so the check is `if let e = error as? GIDSignInError, e.code == .canceled`, not
  the bare `GIDSignInError.canceled` the plan wrote.
- **Widget-linkage check has no command.** §6's *"still no Firebase symbols linked into the
  extension"* is checkable — `otool -L` on the built `.appex` — but the plan gives no way
  to run it.
- **The sign-out test is optimistic.** §6 expects *"the account chooser appears again, not a
  silent re-login."* Whether the chooser appears is decided by Google's cookies inside
  `ASWebAuthenticationSession`, not by local state that `signOut()` clears. A signed-in
  browser session may auto-select. Either soften the expectation or set
  `prefersEphemeralWebBrowserSession`.

---

## Coverage gaps

Whole dimensions the plan did not address, as distinct from things it got wrong:

- **No test, and no acknowledgement that there is nowhere to put one.** The plan calls
  `AuthViewModel` "testable enough" but the project has **no XCTest target** — only
  `tools/check_*.sh`, which compile `Shared/` with bare `swiftc` and cannot link Firebase.
  So `AuthViewModel` is, in practice, untestable in this repo without new infrastructure.
  That is defensible (it is thin glue over an SDK), but the plan should say so rather than
  imply coverage exists.
- **No accessibility note** for the new Profile UI, in a file that already does
  `.accessibilityElement(children: .combine)` ([ProfileView.swift:32](../../../OneWord/Views/ProfileView.swift)).
  The signed-in block (avatar + name + email) wants the same treatment, and the sign-in
  button needs a label.
- **No `Sendable` / isolation analysis** of the callback boundary. `GIDSignIn`'s completion
  is documented to fire "on the main queue" (`GIDSignIn.h:210`) and `addStateDidChangeListener`
  is not — under Swift 5 mode this compiles either way, so it is latent rather than
  breaking, but it is unexamined.
- **No rollback note.** Every step is additive and reversible except the entitlements
  change, which re-provisions. Worth one line.

---

## What the plan got right

Stated so the negatives above can be weighted honestly — this list is not padding, each
item was independently re-verified during this audit:

- **The macOS/iOS distinction, which is the plan's whole reason for existing.** All four
  §3 blockers hold:
  - §3.1 — `Auth.signIn(with: FederatedAuthProvider)` really is inside `#if os(iOS)`
    (`Auth.swift:493`, decls at `:529`/`:583`), as is `OAuthProvider.getCredentialWith`
    (`OAuthProvider.swift:226`), while `GoogleAuthProvider.credential(withIDToken:accessToken:)`
    (`GoogleAuthProvider.swift:26`) is ungated. The forced architecture is correctly derived.
  - §3.2 — `network.client` genuinely absent from `OneWord.entitlements`.
  - §3.3 — `kSecUseDataProtectionKeychain = true` is set unconditionally at
    `AuthKeychainServices.swift:232`, with no access group. The `-34018` diagnosis is right.
  - §3.4 — the redirect really is `<reversed client id>:/oauth2callback`
    (`GIDSignIn.m:750-757`). **Stronger than the plan states:** unsupported schemes also
    raise `NSInvalidArgumentException` (`:588-596`), so this is a crash, not a soft failure.
- **The `Shared/` constraint is correct and load-bearing.** `Shared/` is compiled into the
  widget by explicit path *and* by `tools/check_*.sh` with bare `swiftc`. Routing auth into
  `ViewModels/` is the right call, and the plan's instruction to treat a red gate as "auth
  leaked into Shared/" rather than a script problem is exactly right.
- **Scope discipline.** The skip table is honest, and each row names a real re-entry
  condition rather than hand-waving "later." Declining the login wall for an offline-first
  app is the correct product instinct, not laziness.
- **Reusing the existing `AppDelegate`** instead of adding a file, and flagging the
  file-hygiene concern separately rather than smuggling a refactor into the feature.
- **The `AppKit`-in-a-viewmodel justification** correctly distinguishes "imports a platform
  type the SDK demands" from "names one of our views," which is what `ARCHITECTURE.md`
  actually prohibits.

One nuance in the plan's favour that it did not claim: GoogleSignIn constructs its keychain
store as `[[GTMKeychainStore alloc] initWithItemName:]` with **no** data-protection
attribute (`GIDSignIn.m:465-466`), so §3.3 appears to be a FirebaseAuth-only problem —
GoogleSignIn's own keychain likely does not need the entitlement. `[Unverified]` under an
active sandbox.

---

## Operator questions

1. **`GIDClientID` in Info.plist, or `GIDConfiguration` in code?** (B1) The code path keeps
   `GoogleService-Info.plist` as the single source of the client id; the plist path needs no
   Swift but duplicates the id into a file you must hand-sync. *Recommendation: code.*
2. **Still unanswered from the plan's own §5** — sign-in in the Profile pane vs. a launch
   gate, and whether to unlink Firestore + Storage. Neither is a defect; both are yours.

---

## What would change the verdict

| Change | Moves verdict to |
|---|---|
| B1 + B2 fixed in the plan text (≈8 lines total) | **Ready to build** — M1/M2 are safe to fix during implementation |
| Evidence that `GIDSignIn` reads `GoogleService-Info.plist` in some path I did not open | B1 withdrawn → **Ready to build** |
| A decision to gate the whole app behind login (plan §5 Q1 flipped) | **Needs rework** — that inverts `RootView`'s structure and invalidates §4 Step 6 entirely |
| Adopting Swift 6 language mode before building | **Needs rework** — the isolation analysis this plan never did (see Coverage gaps) becomes mandatory |
