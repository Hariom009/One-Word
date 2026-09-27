# Sign in with Apple — Resolved Plan

> A revision of [`../APPLE_SIGN_IN_PLAN.md`](../APPLE_SIGN_IN_PLAN.md) that answers every
> finding in [`../Audit/APPLE_SIGN_IN_PLAN_AUDIT.md`](../Audit/APPLE_SIGN_IN_PLAN_AUDIT.md).
> The audit's verdict was **Ready to build**: no blockers, no majors, 8 minor findings,
> 4 coverage gaps and 3 questions for you. The original plan and its audit are left
> untouched. **This is the version to build from, and it stands alone.**

## 0. Resolution

### Summary

| Resolved by | Count |
|---|---|
| Self (code-dictated, re-grounded) | 12: all 8 minor findings and all 4 coverage gaps |
| You (asked live, recommended option first) | 3, and you took the recommended option each time |
| Not a defect | 0 |
| Deferred | 0 new. F2 and F3 stay deferred as before (§8). |

**Build readiness:** unchanged, ready to build. What remains uncertain is outside the repo:
Firebase console behaviour and App Review. Each item is tagged, and the first real sign-in
(§7, row 1) settles it.

### Log

| Finding | Resolution | What changed | Grounding |
|---|---|---|---|
| **m1**: nonce hex case unspecified | Self | Step 2 now says the hash is **lowercase** hex, `String(format: "%02x", $0)`. | Firebase compares against the hash of `rawNonce`; its documented sample uses lowercase. `[Inference]`: not verified server-side. |
| **m2**: optional delegate methods can fail silently | Self | Step 2's verify adds "no *nearly matches optional requirement* warning". §9 names this as the likely cause of a stuck overlay. | `@optional` at `ASAuthorizationController.h:22`. `BusyOverlay` blocks every click (`Doodles.swift:111`). |
| **m3**: `apple.logo` availability wrong | Self | "macOS 11+" is now "macOS 13+" in Step 3 and §6. The conclusion is unchanged: no `@available` is needed at 14.0. | `CoreGlyphs.bundle/…/name_availability.plist`: `apple.logo` maps to `"2022"`, which is macOS 13.0 |
| **m4**: Step 4's done-when miscounted | Self | `FeedbackViewModel.swift:142` is added to the sweep. The done-when now expects only three files. | The `:142` comment says "not the Google one". The Firestore URL is lowercase `googleapis` and never matched. |
| **m5**: collision catch doesn't check the domain | Self, **with a correction to the audit** | The catch now checks `e.domain == AuthErrors.domain`. The audit's suggested `AuthErrorDomain` doesn't exist in this SDK's Swift surface. | `AuthErrors.domain = "FIRAuthErrorDomain"` (`AuthErrors.swift:20`). Errors are built as `NSError(domain: AuthErrors.domain, code: publicCode.rawValue)` (`AuthErrorUtils.swift:54-56`). |
| **m6**: F2 names the wrong source for the authorization code | Self | F2 now says: a fresh authorization code from running the Apple sheet again at delete time. | `revokeToken(withAuthorizationCode:)` is at `Auth.swift:1445`, at `#if` depth 0. The short life of the code is `[Inference]` from Apple's docs. |
| **m7**: citation nits | Self | All citations re-pointed (see §1). The pbxproj lines now cite the **app** target. `Profile.swift:35`, `SignInView.swift:42-49`, the scrim at `Doodles.swift:105`. | Reopened this session. |
| **m8**: "No `Sendable` crossings" overstated | Self | §4 now says: none diagnosed under Swift 5 with minimal checking; the continuation's `sending` hand-off needs a revisit on a Swift 6 migration. | `SWIFT_VERSION = 5.0` and no `SWIFT_STRICT_CONCURRENCY` key (`project.pbxproj:557`, `:594`) |
| **Gap**: reverse collision not tested | Self | Matrix row 8 added. | The Google path shows Firebase's own `localizedDescription` (`AuthViewModel.swift`, `signIn(presenting:)` catch-all). |
| **Gap**: Mac with no Apple Account | Self | Matrix row 9 added. | None needed. |
| **Gap**: token audience not in §9 | Self | §9 row added. The risk is rated low because the bundle ids match. | `GoogleService-Info.plist` `BUNDLE_ID` = `com.hariom.swift.oneword`, the same as `PRODUCT_BUNDLE_IDENTIFIER` (`project.pbxproj:550`) |
| **Gap**: no automated nonce check | Self | Recorded in §7 as a deliberate choice, with the reason. | `tools/check_*.sh` compile with bare `swiftc` and can't link Firebase (`tools/check_premium.sh:97`). |
| **Q1**: `apple_icon.imageset` | **You: delete it** | Step 3 deletes it. The App Review fallback is Apple Design Resources artwork, not this file. | Unused: no Swift reference. Added in `9519581`. |
| **Q2**: button order | **You: Apple first** | Step 3 keeps Apple above Google, at the same size. | HIG requires "at least as prominent"; putting Apple first leaves no room for argument. |
| **Q3**: per-button "Signing in…" label | **You: drop it** | Step 3 no longer has `@State tapped`. Both titles are static, and the window-wide `BusyOverlay` (dim plus spinner) is the only busy signal. Google's button loses its label change. | Scrim `opacity(0.7)` at `Doodles.swift:105`, applied over the whole gate at `RootView.swift:107` |

---

## 1. Header

**Change.** Add Sign in with Apple as a second way through the existing Firebase sign-in
gate, next to Google.
- It uses the same Firebase account system with a second provider.
- There are no new screens, and no new types outside `AuthViewModel`.
- `[Assumption]` The driver is App Store Guideline 4.8: an app that offers Google login has
  to offer an equivalent privacy-focused login, and Sign in with Apple counts.

**Stack (re-grounded):**

| Area | What's there |
|---|---|
| Platform | macOS app. Deployment target 14.0 at project level (`project.pbxproj:458`, `:516`), inherited by the app target. Bundle id `com.hariom.swift.oneword` (`:550`). |
| App target settings | `SWIFT_VERSION = 5.0` (`:557`, `:594`). `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (`:554`, `:591`). `SWIFT_APPROACHABLE_CONCURRENCY = YES` (`:553`, `:590`). `MEMBER_IMPORT_VISIBILITY = YES` (`:556`, `:593`), so every module whose members a file uses must be imported by that file. No `SWIFT_STRICT_CONCURRENCY` key, so strict concurrency is at the Swift 5 default ("minimal"). `CODE_SIGN_STYLE = Automatic` (`:532`, `:569`). |
| Architecture | MVVM. The whole auth feature is one `@Observable` class, `AuthViewModel`, injected through `@Environment` (`OneWordApp.swift:26`). Views are dumb. |
| Packages | Firebase Auth + Core 12.18.0 and GoogleSignIn 9.2.0, app target only. The widget links none of them. |
| Tests | No XCTest target. `tools/check_*.sh` compile specific files with bare `swiftc`. |
| Localization | No `.xcstrings` or `.strings` files in `OneWord/` or `OneWordWidget/`. |

**Files opened:**
- `AuthViewModel.swift` (all)
- `SignInView.swift` (all)
- `RootView.swift:80-110`
- `Doodles.swift:95-126`
- `ProfileView.swift:460-506`, plus the lines cited below
- `Profile.swift:1-40`
- `FeedbackViewModel.swift:140-145`
- `WordCapture.swift:20-47`
- `OneWord.entitlements`, `Info.plist`, `GoogleService-Info.plist` (`BUNDLE_ID`)
- The build-setting lines of `project.pbxproj`
- Firebase 12.18.0: `OAuthProvider.swift:322-340`, `VerifyAssertionRequest.swift:155-180`,
  `AuthErrors.swift:15-22`, `:51`, `:83`, `AuthErrorUtils.swift:42-56`, `:499-510`,
  `Auth.swift` (`#if` nesting at `:1445`)
- macOS SDK `ASAuthorizationController.h:15-63`
- The CoreGlyphs `name_availability.plist`

**Facts this plan rests on, each verified at source:**

1. **Firebase's Apple credential works on macOS.**
   `OAuthProvider.appleCredential(withIDToken:rawNonce:fullName:)` (`OAuthProvider.swift:332`)
   sits at `#if` depth 0, outside the iOS-only block at `:226-320`. This differs from
   Google, where Firebase's own flow is iOS-only. Here no extra SDK is needed:
   AuthenticationServices (system) gets the token, and Firebase takes it directly.
2. **The name is forwarded to Firebase.** `fullName` is sent to `verifyAssertion` as a
   `user` query item, `{"name":{"firstName","lastName"}}`
   (`VerifyAssertionRequest.swift:163-176`). `[Inference]` The backend sets `displayName`
   from it on a new account.
3. **Both AuthenticationServices delegate protocols are `NS_SWIFT_UI_ACTOR`**
   (`ASAuthorizationController.h:19`, `:31`), and their methods are `@optional` (`:22`).
4. **`delegate` and `presentationContextProvider` are `weak`**
   (`ASAuthorizationController.h:59`, `:63`).
5. **The error shape.** `AuthErrorCode` is `@objc enum: Int, Error` (`AuthErrors.swift:51`),
   with `accountExistsWithDifferentCredential = 17012` (`:83`). Errors reach callers as
   `NSError(domain: AuthErrors.domain, …)` (`AuthErrorUtils.swift:54-56`), where
   `AuthErrors.domain` is `"FIRAuthErrorDomain"` (`AuthErrors.swift:20`).
6. **What's already provider-agnostic:**
   - The gate reads `isSignedIn` (`RootView.swift:91-100`).
   - Profile and the sidebar read `displayName`, `email` and `photoURL`.
   - The join date comes from `user.metadata` plus `users/{uid}`.
   - Feedback files under `user.uid`.
   - An empty photo URL renders the generic head: `AsyncImage(url: nil)` shows the
     `person.crop.circle` placeholder (`ProfileView.swift:478-484`). Apple provides no
     photo, so this path is used.
7. **Sign-out needs no change.** `GIDSignIn.sharedInstance.signOut()` does nothing for an
   Apple user, and `Auth.auth().signOut()` drops the session.
8. **Local data isn't keyed by uid.** Premium is StoreKit (`PremiumViewModel.swift:15`), and
   the app's other data is local. Two Firebase accounts for one person (Google plus Apple
   with Hide My Email) only split the `users/{uid}` join date and the feedback uid.
9. **The busy overlay can't cover the Apple sheet.** `.busy` is a SwiftUI `overlay` inside
   the window's content (`Doodles.swift:120-125`). The AppKit sheet presented on that
   window sits above the content.

## 2. Scope and outcome

**Done when:**
- The sign-in screen shows **Sign in with Apple** above **Sign in with Google**, drawn the
  same way.
- Signing in with Apple opens the shell. The sidebar and Profile show the Apple name (or
  the "Signed in" fallback), the email (possibly a relay address) and the generic head.
- The session survives a relaunch.
- Google sign-in behaves as before, except that its button title no longer changes to
  "Signing in…".

**In scope:**
- The entitlement
- `signInWithApple(presenting:)` and its delegate bridge
- The second button, and deleting the unused `apple_icon` asset
- A comment sweep
- A one-line debug leftover in `restore()`

**Out of scope:**
- Account linking (F1)
- Account deletion and token revocation (F2)
- A launch-time revocation check (F3)
- The widget and `Shared/`

**Shape:** a single change, one PR.

## 3. Architecture fit

| Change | Where | Mirrors |
|---|---|---|
| `signInWithApple(presenting:)` and the two nonce helpers | `AuthViewModel` (MODIFIED, app target) | `signIn(presenting:)` in the same file: the same `busy`/`error` handling, and the same "Firebase credential → `user` → `recordJoinDate()`" tail |
| `AppleAuthorization`: a `private final class` that turns the delegate API into one `await` | Bottom of `AuthViewModel.swift` | New pattern, because the SDK only offers a delegate API. File-private. |
| One button function drawing both buttons | `SignInView` (MODIFIED) | The existing `signInButton(_:)` (`SignInView.swift:66`), with its icon, title and action passed in |
| `com.apple.developer.applesignin` | `OneWord/OneWord.entitlements` (MODIFIED, app target only) | The `keychain-access-groups` block and its comment style in the same file |
| `apple_icon.imageset` | `Assets.xcassets` (DELETED) | — |

## 4. Steps

### Step 0: Console and portal (you, outside the repo)

- **Firebase console ▸ Authentication ▸ Sign-in method ▸ Add ▸ Apple ▸ Enable.**
  `[Unverified]` The Services ID, team ID and key fields can be left blank for use on Apple
  platforms only. They are needed for web or Android, and for F2's token revocation.
- **Apple Developer ▸ App ID `com.hariom.swift.oneword` ▸ Sign in with Apple.** Automatic
  signing should enable this and regenerate the profile when Step 1 lands. If it doesn't,
  turn it on by hand.

**Verify:** the provider shows as Enabled in the Firebase console.

### Step 1: Entitlement

**`OneWord/OneWord.entitlements`:** append this after `keychain-access-groups`:

```xml
<!-- Sign in with Apple. App target only: the widget never signs in. Without it
     the Apple flow fails on tap with no sheet. -->
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

Going through *Signing & Capabilities ▸ + Sign in with Apple* writes the same key. The
comment no longer claims a specific error code. The audit tagged that claim `[Unverified]`,
so the code shouldn't state it as fact.

**Verify:**
- The build signs cleanly.
- `codesign -d --entitlements - <built .app>` lists the key.

### Step 2: `AuthViewModel`, the Apple flow

**`OneWord/ViewModels/AuthViewModel.swift`** (MODIFIED)

- **Imports.** Add `import AuthenticationServices` and `import CryptoKit`, named explicitly
  because `MEMBER_IMPORT_VISIBILITY` requires it.
- **Header comment.** Change "Google sign-in, the whole feature" to cover both providers.
  Add one line: Apple needs no extra SDK because `appleCredential` isn't iOS-gated.
- **New method,** next to `signIn(presenting:)`:

```swift
/// Runs Sign in with Apple, then trades Apple's identity token for a Firebase session.
/// Same shape as the Google flow above; `window` anchors the system sheet.
func signInWithApple(presenting window: NSWindow) async
```

  The body in order:
  1. Guard `busy`, then set `busy = true` and `error = nil`, with `defer { busy = false }`.
  2. Build the request:
     - `let nonce = Self.randomNonce()`
     - `let request = ASAuthorizationAppleIDProvider().createRequest()`
     - `request.requestedScopes = [.fullName, .email]`
     - `request.nonce = Self.sha256(nonce)`
  3. `let credential = try await AppleAuthorization(window: window).perform(request)`
  4. Get the token:
     `guard let data = credential.identityToken, let idToken = String(data: data, encoding: .utf8)`.
     If either is missing, set `error = "Apple didn't return an identity token."` and
     return.
  5. `user = try await Auth.auth().signIn(with: OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: credential.fullName)).user`
  6. `recordJoinDate()`
  7. Errors, caught **in this order:**
     - `catch let e as ASAuthorizationError where e.code == .canceled`: return silently,
       the same policy as `GIDSignInError.canceled`.
     - `catch let e as NSError where e.domain == AuthErrors.domain && e.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue`:
       set `error = "That email already signs in with Google. Use Google instead."`
       (fact 5).
     - `catch`: set `self.error = error.localizedDescription`.

- **Nonce helpers** (`private static`):
  - `randomNonce() -> String`: 32 bytes of `UInt8.random(in: .min ... .max)` (the system
    CSPRNG), then `.map { String(format: "%02x", $0) }.joined()`.
  - `sha256(_ s: String) -> String`:
    `SHA256.hash(data: Data(s.utf8)).map { String(format: "%02x", $0) }.joined()`.
    **Lowercase** hex.
  - The request carries the hash and Firebase gets the raw value, so a replayed token
    fails.
- **`AppleAuthorization`,** at the bottom of the file:

```swift
/// ASAuthorizationController only speaks delegate. This turns one run into one await.
/// Main-actor by the target default, which is also what both protocols require
/// (NS_SWIFT_UI_ACTOR).
private final class AppleAuthorization: NSObject,
    ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let window: NSWindow
    private var controller: ASAuthorizationController?   // held here: it holds us weakly
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    init(window: NSWindow)
    func perform(_ request: ASAuthorizationAppleIDRequest) async throws -> ASAuthorizationAppleIDCredential
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithAuthorization authorization: ASAuthorization)
    func authorizationController(controller: ASAuthorizationController,
                                 didCompleteWithError error: Error)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor
}
```

  - Both callbacks do `continuation?.resume(…); continuation = nil`.
  - `didCompleteWithAuthorization` throws if the credential isn't an
    `ASAuthorizationAppleIDCredential`.
  - These two method names must match the protocol exactly, because the protocol methods
    are `@optional` (fact 3). A near-miss compiles, is never called, and leaves the window
    dimmed for good.

- **Drive-by:** delete the two `dbg` / `photodebug.txt` lines in `restore()`. They are a
  leftover debug write of provider data into Caches that runs in release builds too. This
  is unrelated to Apple; drop it from this change if you want the diff pure.

**Verify:**
- The app builds.
- The build log has **no** "nearly matches optional requirement" warning for
  `AppleAuthorization`.

### Step 3: `SignInView`, the second button

**`OneWord/Views/SignInView.swift`** (MODIFIED)

- **Generalise the button.** `signInButton(_ t:)` becomes
  `signInButton(_ t: Theme, icon: Image, title: String, action: @escaping (NSWindow) async -> Void)`.
  - It keeps the same label layout, surface, hairline and radius.
  - It keeps `guard let window = NSApp.keyWindow` and runs `Task { await action(window) }`.
  - The icon gets `.resizable().scaledToFit().frame(width: 15, height: 15)` and
    `.accessibilityHidden(true)`, because the title carries the label.
- **Static titles** (your decision, Q3). The label is just `Text(title)`, and
  `auth.busy ? "Signing in…" : …` goes away. Both buttons stay `.disabled(auth.busy)`.
  Update the in-label comment ("…so the button only changes its word") to say the button
  doesn't change: the window-wide overlay is the busy signal.
- **Order** (your decision, Q2). Apple goes above Google, same size.
  - Apple: `Image(systemName: "apple.logo")`, tinted by the existing
    `.foregroundStyle(t.ink)`, calling `auth.signInWithApple(presenting:)`. It needs
    macOS 13 and the target is 14, so no `@available` is needed.
  - Google: `Image("google_icon")`, calling `auth.signIn(presenting:)`. It is unchanged
    and keeps its colours because it isn't a template image.
- **Comments.** The header "a wordmark and one button" becomes "…and a button per
  provider". The hue comment (`:67-69`) gains a clause: Apple's mark is monochrome by rule,
  so it takes `t.ink` like the text.
- **Delete `OneWord/Assets.xcassets/apple_icon.imageset/`** (your decision, Q1). It is
  unused, and it's an icons8 redraw of Apple's mark. `[Unverified]` that `apple.logo` meets
  HIG for a custom button. If App Review objects, use the logo from Apple Design Resources
  as a template image.

**Verify:** §7 rows 1-3 and 10.

### Step 4: Stale "Google" comments (no behaviour change)

Reword each of these to "the account" or "the provider":

| File | Line | Current text |
|---|---|---|
| `Profile.swift` | `:5` | "…that Google doesn't hand us" |
| `ProfileView.swift` | `:33` | "Google owns the email…" |
| `ProfileView.swift` | `:48` | "…the one Google gave" |
| `ProfileView.swift` | `:149` | "…following the Google account" |
| `RootView.swift` | `:70` | "…following the Google account" |
| `FeedbackViewModel.swift` | `:142` | "…not the Google one", which becomes "not the provider's one" |

`Avatar`'s doc (`Profile.swift:35`) already set this rule: "Never named after the
provider."

**Verify:** `grep -rn "Google" OneWord --include='*.swift'` hits only
`AuthViewModel.swift`, `SignInView.swift` and `WordCapture.swift`.

## 5. Data and identity edge

- **Name and email arrive only on the first authorization** for this Apple ID and app.
  They are passed straight into `appleCredential(…fullName:)` (fact 2).
  - If that first attempt fails after consent but before Firebase answers, the name is
    lost for that account.
  - The fallback already exists: `displayName ?? "Signed in"` (`ProfileView.swift:50`),
    plus the Profile pane's own name field.
  - Accepted. There is no local stash of the name for a retry.
- **Email may be a `…@privaterelay.appleid.com` relay address.** It is shown as-is in
  Profile details (`ProfileView.swift:312`).
- **Photo.** `photoURL` is nil, so the generic head is shown (fact 6).
- **Firestore.** `recordJoinDate()` and feedback use uid and the Firebase ID token only.

## 6. Concurrency, state and memory

- **Isolation.** Everything is on the main actor, by the target default
  (`project.pbxproj:554`): `AuthViewModel`, `AppleAuthorization`, and both delegate
  protocols (fact 3).
  - No `nonisolated`, no `Task.detached`.
  - `await Auth.auth().signIn(with:)` is the same hop the Google path makes today.
- **`Sendable`.** Nothing is diagnosed under this target's Swift 5 mode with minimal
  checking. `[Inference]` `continuation.resume(returning:)` hands a non-`Sendable`
  `ASAuthorizationAppleIDCredential` across as `sending`. A move to Swift 6 language mode
  may flag it; revisit then.
- **Continuation.** The `withCheckedThrowingContinuation` closure runs synchronously and
  starts `performRequests()`.
  - `[Inference]` Exactly one delegate callback follows. `continuation = nil` after resuming
    makes a second callback harmless.
  - The risk of a continuation that never resumes is a misspelled `@optional` method name.
    It's covered by Step 2's verify.
- **Lifetime, no retain cycle.**
  - The caller's `try await AppleAuthorization(window:).perform(request)` keeps the bridge
    alive across the suspension.
  - The bridge holds `controller` strongly; the controller holds the bridge weakly
    (fact 4).
  - Both objects are freed when `perform` returns. There are no escaping closures, so no
    capture lists.
- **View state.** None added (Q3). `SignInView` stays a pure function of `auth`.
- **Cancellation.** The sheet's own Cancel arrives as `.canceled`. There is no `Task`
  cancellation to wire.

## 7. Tests and verification

**No automated test is added, deliberately.** `AuthViewModel` imports Firebase, and the
`tools/check_*.sh` gates compile with bare `swiftc` and no package graph
(`tools/check_premium.sh:97`). The nonce helpers are a few lines of CryptoKit, and a wrong
hash fails loudly on row 1. This is the same position as the Google path.

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture check_premium; do bash tools/$s.sh; done
```

Both must be green. A red gate would mean something leaked into `Shared/`.

Then by hand, in a team-signed build with the `-debugSkipAuth` bypass **off**:

| # | Do | Expect |
|---|---|---|
| 1 | Sign in with Apple ▸ Continue | The sheet shows over the dimmed window. The shell appears. The sidebar chip shows the Apple name. Profile shows the name, the email (maybe a relay address), the generic head and today's join date. |
| 2 | Sign in with Apple ▸ Cancel | No error text. Still on the sign-in screen, with the buttons enabled. |
| 3 | Sign in with Google | Works as today. The title stays "Sign in with Google" while busy. |
| 4 | Quit and relaunch after row 1 | Still signed in. |
| 5 | Sign out, then Sign in with Apple | The sheet skips the name and email step. The name is still shown. |
| 6 | System Settings ▸ Apple Account ▸ Sign in with Apple ▸ One Word ▸ Stop Using, then sign in | The sheet asks for name and email again. Same Firebase uid. |
| 7 | Apple ID sharing the same email as an existing Google account | The "use Google instead" message under the buttons, no crash. |
| 8 | Reverse of row 7: an Apple account exists (real email shared), then Sign in with Google with the same address | `[Unverified]` Either Firebase's own collision sentence under the button, or a silent link. Either outcome is acceptable. Record which one happens. |
| 9 | A Mac user account not signed in to an Apple Account | The system's sign-in prompt, or a legible error under the button. No hang. |
| 10 | VoiceOver on the sign-in screen | Reads "Sign in with Apple, button" and "Sign in with Google, button". The icons are silent. |
| 11 | Widget | Builds and runs. No AuthenticationServices or Firebase in the extension (`otool -L`). |

## 8. Mechanics

| Item | Note |
|---|---|
| Entitlement | Step 1. App target only; `OneWordWidget.entitlements` untouched. |
| Info.plist | Nothing. Apple needs no URL scheme and no usage string. |
| Packages | Nothing. AuthenticationServices and CryptoKit are system frameworks. |
| Target membership | No new files. The two modified files are already in the synchronized `OneWord/` group. |
| Assets | `apple_icon.imageset` is deleted, and nothing references it. |
| `@available` | None. `ASAuthorizationAppleIDProvider` needs 10.15+, `apple.logo` needs 13+, and the target is 14. |
| Localization | No string catalog in the project. New strings match the existing hard-coded ones. |
| a11y | The title carries the label and the icon is hidden. The error text renders under the buttons (`SignInView.swift:42-49`). |

## 9. Decision forks (deferred, unchanged from the original plan except F2's wording)

- **F1: Same email, two providers.**
  - Applied: the "use Google instead" message.
  - Alternative: account linking via `user.link(with:)` after a Google sign-in.
  - That's worth doing only if something server-side starts hanging off the uid (fact 8).
- **F2: Account deletion.**
  - This gap already exists for Google too. App Store Guideline 5.1.1(v) requires in-app
    deletion. For Apple accounts, deletion must also revoke the token:
    `Auth.auth().revokeToken(withAuthorizationCode:)` (`Auth.swift:1445`, not gated).
  - It needs the Step 0 key fields filled in, and **a fresh authorization code from running
    the Apple sheet again at delete time**. Codes are short-lived (`[Inference]`), so one
    kept from sign-in won't do.
  - A separate plan, before App Store submission.
- **F3: Launch-time revocation check.**
  - Skipped: `getCredentialState(forUserID:)`.
  - The limit: a user who does "Stop Using" stays signed in on this Mac until they sign
    out.

## 10. Risks and exits

| Risk | Sev / conf | Leading indicator | Exit |
|---|---|---|---|
| Profile lacks the capability | High / medium | Signing error at build, or an immediate `ASAuthorizationError` on tap with no sheet | *Signing & Capabilities ▸ + Sign in with Apple*, or enable it on the App ID and re-provision |
| Provider not enabled in Firebase | High / high if Step 0 is skipped | "operation not allowed" (17006) after the sheet succeeded | Step 0 |
| A delegate method name misspelled | High / low | Window stays dimmed after the sheet closes; the build log has a "nearly matches optional requirement" warning | Match the names exactly (Step 2). The warning is the tell. |
| Nonce mismatch | Medium / low | Firebase "invalid credential" / nonce error after the sheet | Request gets lowercase `sha256(nonce)`; Firebase gets raw `nonce`. Check for swaps or uppercase hex. |
| Token audience rejected | Medium / low | "invalid audience" after the sheet | `[Unverified]` The Firebase project's registered bundle id already matches (`GoogleService-Info.plist` `BUNDLE_ID`). If it's still rejected, add a Services ID in the Apple provider's console settings. |
| Name never shows | Low / medium | "Signed in" instead of a name after row 1 | Row 6 re-runs the first-time path. If it's still blank, fact 2's `[Inference]` is wrong: add `user.createProfileChangeRequest()` with `credential.fullName` right after sign-in. |

## 11. Sequence

1. Step 0: console and portal. Nothing in the repo; fully reversible.
2. Step 1: entitlement. Build green.
3. Step 2: `AuthViewModel`. Build green, with no optional-requirement warning.
4. Step 3: `SignInView` and the asset delete. Build green, then rows 1-3 and 10.
5. Step 4: comment sweep. The grep in Step 4 comes out clean.
6. Both gates green, then the full matrix.

One commit per step works. Steps 2 and 3 can squash if you'd rather not land a method
nothing calls.

## 12. Open questions

- `[Unverified]` Firebase accepts Apple with the Services ID and key blank for native-only
  use. Settled by Step 0 plus row 1.
- `[Unverified]` `apple.logo` passes App Review on a custom button. Settled at review; the
  exit is in Step 3.
- `[Inference]` The backend sets `displayName` from the forwarded name. Settled by row 1;
  the exit is in §10.
- `[Unverified]` What happens on a reverse collision. Settled by row 8.

## Your review queue

All three of these were asked live and you picked the recommended option each time. They're
listed so nothing is decided silently.

| Decision | Applied | Alternative, and when it wins |
|---|---|---|
| Q1: `apple_icon.imageset` | Delete it | Keep it as a fallback, if you'd rather have the file on hand than fetch Apple Design Resources when App Review objects. |
| Q2: button order | Apple first | Google first, same size, if keeping returning Google users' button in place matters more than the unarguable prominence reading. |
| Q3: busy label | Static titles | Put back `@State tapped` (2 lines) if the per-button "Signing in…" turns out to be missed under the dimmed window. |
