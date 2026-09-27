# Sign in with Apple — Plan

Add **Sign in with Apple** as a second way through the sign-in gate, next to the existing
Google sign-in. It is the same Firebase account system with a second provider. No new
screens, no new types outside `AuthViewModel`.

- **Upstream:** no strategy doc. This builds on the shipped Google flow. The resolved
  Firebase plan listed Apple as "add when a second provider is actually wanted"
  ([`Resolved/FIREBASE_AUTH_PLAN_RESOLVED.md`](Resolved/FIREBASE_AUTH_PLAN_RESOLVED.md) §1).
  `[Assumption]` The driver is App Store Guideline 4.8: an app that offers Google login has
  to offer an equivalent privacy-focused login, and Sign in with Apple counts.
- **Scope shape:** single change, one PR.
- **Operator decision already made:** the Apple button **matches the Google button**
  (same surface, hairline and type, with Apple's logo in ink). It is not the system
  `SignInWithAppleButton`.

## 1. Grounding

**Files read:**
- `OneWord/ViewModels/AuthViewModel.swift` (all)
- `OneWord/Views/SignInView.swift` (all)
- `OneWord/Views/RootView.swift:80-110`
- `OneWord/Views/ProfileView.swift` (auth call sites)
- `OneWord/Models/Profile.swift`
- `OneWord/WordCapture.swift:20-47`
- `OneWord/OneWord.entitlements`, `OneWord/Info.plist`
- `project.pbxproj` build settings
- The firebase-ios-sdk 12.18.0 checkout in DerivedData
- The macOS SDK's `ASAuthorizationController.h`

**Detected stack:**

| Area | What's there |
|---|---|
| Platform | macOS app, `MACOSX_DEPLOYMENT_TARGET = 14.0` (pbxproj:364). Swift 5 mode (`:373`) with `SWIFT_APPROACHABLE_CONCURRENCY` (`:553`). `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (`:371`). `MEMBER_IMPORT_VISIBILITY = YES` (`:556`), so every module whose members a file uses must be imported by that file. |
| Architecture | MVVM. The whole auth feature is one `@Observable` class, `AuthViewModel`, injected through `@Environment` (`OneWordApp.swift:26`). Views are dumb. |
| Packages | `FirebaseAuth` + `FirebaseCore` 12.18.0 and `GoogleSignIn` 9.2.0, app target only. The widget links none of them. |
| Tests | No XCTest target. The gates in `tools/check_*.sh` compile `Shared/` with bare `swiftc` and cannot link Firebase, so auth code is verified by build plus a manual run. This is the same as the Google path. |

**Facts this plan rests on, each verified at source:**

1. **Firebase's Apple credential works on macOS.**
   `OAuthProvider.appleCredential(withIDToken:rawNonce:fullName:)` (`OAuthProvider.swift:332`)
   sits outside the `#if os(iOS)` block (`:226-320`). This differs from Google, where
   Firebase's own flow is iOS-only. Here we need no extra SDK: AuthenticationServices
   (system) gets the token, and Firebase takes it directly.
2. **The name is forwarded to Firebase.** The `fullName` argument is sent to Firebase's
   `verifyAssertion` call (`VerifyAssertionRequest.swift:163-170`). `[Inference]` The
   backend sets `displayName` from it on a new account.
3. **Both AuthenticationServices delegate protocols are `NS_SWIFT_UI_ACTOR`**
   (`ASAuthorizationController.h:19`, `:31`). A main-actor class conforms to them cleanly
   under this target's default isolation.
4. **`delegate` and `presentationContextProvider` are `weak`**
   (`ASAuthorizationController.h:59`, `:63`). Whoever implements them has to be kept
   alive by something else for the whole flow.
5. **`AuthErrorCode` is `@objc enum: Int, Error`** (`AuthErrors.swift:51`).
   `accountExistsWithDifferentCredential = 17012` (`:83`).
6. **What's already provider-agnostic:**
   - The gate (`RootView.swift:91-100`) reads `isSignedIn`.
   - The Profile and sidebar identity read `displayName`, `email` and `photoURL`.
   - The join date comes from `user.metadata` plus `users/{uid}`.
   - Feedback files under `user.uid`.
   - An empty photo is already a designed state: `Avatar.account` falls back to the
     generic head (`Profile.swift:34-37`). Apple provides no photo, so this path is used.
   - None of these need changes.
7. **Sign-out needs no change.** `GIDSignIn.sharedInstance.signOut()` does nothing for an
   Apple user, and `Auth.auth().signOut()` drops the session. Apple keeps no local SDK
   session to clear.
8. **Local data isn't keyed by uid.** Premium is StoreKit (`PremiumViewModel.swift:15`).
   Bookmarks, learned words and history are local. A user who signs in once with Google
   and once with Apple under **Hide My Email** gets two Firebase accounts. That only splits
   the `users/{uid}` join date and the feedback uid. Linking the two accounts is low-value;
   see fork F1.

## 2. Architecture fit

| Change | Where | Mirrors |
|---|---|---|
| `signInWithApple(presenting:)` and the nonce helpers | `AuthViewModel` (MODIFIED, app target) | `signIn(presenting:)` in the same file: same `busy`/`error` handling, same "Firebase credential → `user` → `recordJoinDate()`" tail |
| `AppleAuthorization`: a `private final class` that turns `ASAuthorizationController`'s delegate callbacks into one `await` | Bottom of `AuthViewModel.swift`, file-private | New pattern (the SDK only offers a delegate API). Kept file-private so it isn't reachable as a general utility. |
| A second button, sharing the Google button's drawing code | `SignInView` (MODIFIED) | The existing `signInButton(_:)` (`SignInView.swift:66-95`), with its icon, title and action passed in |
| `com.apple.developer.applesignin` entitlement | `OneWord/OneWord.entitlements` (MODIFIED, app target only) | The `keychain-access-groups` block in the same file, including its comment style |

Nothing lands in `Shared/`. The widget is untouched.

## 3. Steps

### Step 0: Console and portal (operator, outside the repo)

- **Firebase console ▸ Authentication ▸ Sign-in method ▸ Add ▸ Apple ▸ Enable.**
  `[Unverified]` Firebase's docs say the Services ID, team ID and private key fields can be
  left blank when Apple sign-in is only used on Apple platforms. Those fields are needed
  for web or Android, and for token revocation (see F2).
- **Apple Developer ▸ the `com.hariom.swift.oneword` App ID ▸ Sign in with Apple.**
  Automatic signing (team `LAP54KU2SV`) should enable this and regenerate the profile when
  Step 1's entitlement appears. If it doesn't, turn it on by hand.

**Verify:** the provider shows "Enabled" in the Firebase console.

### Step 1: Entitlement

**`OneWord/OneWord.entitlements`:** append this after `keychain-access-groups`, with a
comment in the file's existing voice:

```xml
<!-- Sign in with Apple. Without it ASAuthorizationController fails at once with
     ASAuthorizationError 1000 (.unknown) and no sheet. App target only: the widget
     never signs in. -->
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

Going through *Signing & Capabilities ▸ + Sign in with Apple* writes the same key.

**Verify:**
- `xcodebuild … build` signs cleanly.
- `codesign -d --entitlements - <built .app>` lists the key.

### Step 2: `AuthViewModel`, the Apple flow

**`OneWord/ViewModels/AuthViewModel.swift`** (MODIFIED)

- **Imports.** Add `import AuthenticationServices` and `import CryptoKit`. Both are named
  explicitly because `MEMBER_IMPORT_VISIBILITY` requires it.
- **Header comment.** Change "Google sign-in, the whole feature" to cover both providers.
  Add one line: Apple needs no extra SDK because Firebase's `appleCredential` isn't
  iOS-gated, which is the opposite of the Google note below it.
- **New method,** next to `signIn(presenting:)`:

```swift
/// Runs Sign in with Apple, then trades Apple's identity token for a Firebase session.
/// Same shape as the Google flow above; `window` anchors the system sheet.
func signInWithApple(presenting window: NSWindow) async
```

  The body in order:
  1. Guard `busy`, then set `busy = true` and `error = nil`, with
     `defer { busy = false }`. This is copied from `signIn(presenting:)`.
  2. Build the request:
     - `let nonce = Self.randomNonce()`
     - `let request = ASAuthorizationAppleIDProvider().createRequest()`
     - `request.requestedScopes = [.fullName, .email]`
     - `request.nonce = Self.sha256(nonce)`
  3. `let credential = try await AppleAuthorization(window: window).perform(request)`
  4. Get the token:
     `guard let data = credential.identityToken, let idToken = String(data: data, encoding: .utf8)`.
     If either is missing, set `error = "Apple didn't return an identity token."` and
     return. This mirrors Google's missing-ID-token branch.
  5. `user = try await Auth.auth().signIn(with: OAuthProvider.appleCredential(withIDToken: idToken, rawNonce: nonce, fullName: credential.fullName)).user`
  6. `recordJoinDate()`
  7. Error handling:
     - `catch let e as ASAuthorizationError where e.code == .canceled`: return silently,
       the same policy as `GIDSignInError.canceled`.
     - `catch where (error as NSError).code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue`:
       set `error = "That email already signs in with Google. Use Google instead."`
       (fork F1). The `NSError` code comparison is used on purpose. `[Unverified]` A typed
       `catch AuthErrorCode.x` may not bridge, because Firebase builds its errors in the
       `FIRAuthErrorDomain` domain.
     - `catch`: set `self.error = error.localizedDescription`.

- **Nonce helpers** (`private static`, 3 lines each):
  - `randomNonce() -> String`: 32 bytes from `SystemRandomNumberGenerator` (a CSPRNG on
    Apple platforms), hex-encoded.
  - `sha256(_:) -> String`: `SHA256.hash(data: Data(s.utf8))`, hex-encoded.
  - The request carries the hash and Firebase gets the raw value. Firebase checks that the
    token's `nonce` claim equals `sha256(rawNonce)`, which stops a replayed token.
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
    func authorizationController(controller:didCompleteWithAuthorization:)   // resume(returning:), or throw if not an AppleID credential
    func authorizationController(controller:didCompleteWithError:)           // resume(throwing:)
    func presentationAnchor(for:) -> ASPresentationAnchor                    // window
}
```

  Both delegate callbacks do `continuation?.resume(…); continuation = nil`, so a second
  callback can't resume the continuation twice and crash.

- **Drive-by:** delete the two `dbg` / `photodebug.txt` lines in `restore()`. They are a
  leftover debug write of provider data into Caches that runs in release builds too. This
  is unrelated to Apple; drop it from this change if you want the diff pure.

**Verify:** the app builds. Tapping the button isn't possible until Step 3.

### Step 3: `SignInView`, the second button

**`OneWord/Views/SignInView.swift`** (MODIFIED)

- **Generalise the button.** `signInButton(_ t:)` becomes
  `signInButton(_ t: Theme, icon: Image, title: String, action: @escaping (NSWindow) async -> Void)`.
  It keeps the same label layout, surface, hairline and radius.
  - The icon gets `.resizable().scaledToFit().frame(width: 15, height: 15)`, which sizes a
    bitmap and an SF Symbol the same way.
  - The icon also gets `.accessibilityHidden(true)`. It is decorative, and VoiceOver reads
    the title. The Google icon gets this too, which fixes a small existing gap.
- **Order.** Apple goes above Google, same size. Apple's HIG asks that the Apple button be
  at least as prominent as the other sign-in options.
  - Apple: `Image(systemName: "apple.logo")`, tinted by the existing
    `.foregroundStyle(t.ink)`. `apple.logo` needs macOS 11 and the target is 14, so no
    `@available` is needed.
  - Google: `Image("google_icon")`, unchanged. It keeps its colours because it isn't a
    template image.
- **"Signing in…" label.** Today `auth.busy` changes the only button's title. With two
  buttons, a view-local `@State private var tapped: String?` records which title was
  pressed. Only that button reads "Signing in…". Both are `.disabled(auth.busy)`. This is
  view state, not session state, so the view stays dumb.
- **Comments.** The header comment "a wordmark and one button" becomes "…and a button per
  provider". The hue comment (`:67-69`) stays accurate for Google. Add a clause saying
  Apple's mark is monochrome by rule, so it takes `t.ink` like the text.
- **Delete `Assets.xcassets/apple_icon.imageset`.** It is unused (no Swift reference) and
  is an icons8 redraw of Apple's mark. Apple's HIG asks for Apple's own artwork, and the
  SF Symbol is Apple's. `[Unverified]` that `apple.logo` meets HIG for a custom button. If
  App Review objects, swap in the logo from Apple Design Resources as a template image.

**Verify:** the manual matrix in §7, rows 1-3.

### Step 4: Stale "Google" comments (no behaviour change)

These comments say "Google" where they now mean "the account":

- `Profile.swift:5`
- `ProfileView.swift:33`, `:48`, `:149`
- `RootView.swift:70`

Reword them. `Avatar`'s doc (`Profile.swift:34`) already set this rule: "Never named after
the provider."

**Verify:** `grep -rn "Google" OneWord --include='*.swift'` only hits
`AuthViewModel.swift`, `SignInView.swift`, `WordCapture.swift` and the Firestore URL in
`FeedbackViewModel.swift`.

## 4. Concurrency, state and memory

- **Isolation.** Everything is on the main actor, by the target default (pbxproj:371):
  `AuthViewModel`, `AppleAuthorization`, and both delegate protocols (fact 3).
  - No `nonisolated`, no `Task.detached`, no `Sendable` crossings.
  - `await Auth.auth().signIn(with:)` is the same hop the Google path already makes, and
    it compiles today under these settings.
- **Continuation.** `withCheckedThrowingContinuation`'s closure runs synchronously and
  starts `performRequests()`.
  - `[Inference]` Exactly one delegate callback follows. The `continuation = nil` after
    resuming makes a second callback harmless instead of a crash.
  - A continuation that is never resumed would leave `busy` stuck at true and the window
    dimmed. The leading indicator is the overlay never lifting after the sheet closes.
- **Lifetime, no retain cycle.**
  - The caller's `try await AppleAuthorization(window:).perform(request)` keeps the bridge
    alive across the suspension, because a method's `self` is retained for the call.
  - The bridge holds `controller` strongly; the controller holds the bridge weakly
    (fact 4).
  - When `perform` returns, the local is released and both objects are freed. There are no
    escaping closures, so no capture lists.
- **Cancellation.** The sheet's own Cancel button is the only cancel path, and it arrives
  as `.canceled`. There is no `Task` cancellation to wire: the gate is single-window and
  modal while `busy`.

## 5. Data and identity edge

- **Name and email arrive only on the first authorization** for this Apple ID and app.
  They are passed straight into `appleCredential(…fullName:)` (fact 2).
  - If that first attempt fails after Apple's consent but before Firebase answers (for
    example, offline), the name is lost for that account.
  - The fallback already exists: `displayName ?? "Signed in"` (`ProfileView.swift:50`),
    plus the Profile pane's own name field.
  - Accepted. There is no local stash of the name for a retry (YAGNI).
- **Email may be a `…@privaterelay.appleid.com` relay address.** It is shown as-is in
  Profile details (`ProfileView.swift:312`). It's accurate, and it's the user's choice.
- **Photo.** `photoURL` is nil, so the generic head is shown (fact 6).
- **Firestore.** `recordJoinDate()` and feedback use uid and the Firebase ID token only,
  so they are provider-agnostic.

## 6. Mechanics

| Item | Note |
|---|---|
| Entitlement | Step 1. App target only; `OneWordWidget.entitlements` untouched. |
| Info.plist | Nothing. Apple needs no URL scheme and no usage string. |
| Packages | Nothing. AuthenticationServices and CryptoKit are system frameworks, autolinked by import. |
| Target membership | No new files. `AuthViewModel.swift` and `SignInView.swift` are already in the synchronized `OneWord/` group. |
| `@available` | None. `ASAuthorizationAppleIDProvider` needs 10.15+, `apple.logo` needs 11+, and the target is 14. |
| Localization | No `.xcstrings` in the project. New strings match the existing hard-coded ones. |
| a11y | The title carries the label and the icon is hidden (Step 3). The error text already renders under the buttons (`SignInView.swift:42-50`). |
| Gates | No `tools/check_*.sh` names either file. Run them anyway: a red gate would mean something leaked into `Shared/`. |

## 7. Verification

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture check_premium; do bash tools/$s.sh; done
```

Then by hand, in a build signed with the team profile. The `-debugSkipAuth` bypass must be
**off**.

| # | Do | Expect |
|---|---|---|
| 1 | Sign in with Apple ▸ Continue | The system sheet shows. The window dims; only the Apple button reads "Signing in…". The shell appears. The sidebar chip shows the Apple name. Profile shows the name, the email (maybe a relay address), the generic head and today's join date. |
| 2 | Sign in with Apple ▸ Cancel | No error text. Still on the sign-in screen, buttons enabled. |
| 3 | Sign in with Google | Unchanged from today. Only the Google button reads "Signing in…". |
| 4 | Quit and relaunch after row 1 | Still signed in. This is the keychain entitlement, which already exists. |
| 5 | Sign out, then Sign in with Apple | The sheet skips the name and email step (returning user). The name is still shown because Firebase kept it. |
| 6 | System Settings ▸ Apple Account ▸ Sign in with Apple ▸ One Word ▸ Stop Using, then sign in | The sheet asks for name and email again (the first-time path). Same Firebase uid. |
| 7 | Apple ID that shares the same email as an existing Google account | The F1 message under the buttons, no crash. |
| 8 | VoiceOver on the sign-in screen | Reads "Sign in with Apple, button" and "Sign in with Google, button". The icons are silent. |
| 9 | Build log / `otool -L` on the widget | No AuthenticationServices or Firebase in the extension. |

## 8. Decision forks (yours; defaults already applied above)

- **F1: Same email, two providers.**
  - Default: show the "use Google instead" message and nothing more.
  - The alternative is account linking: sign in with Google, then
    `user.link(with: appleCredential)`. That needs a second flow and UI.
  - It's worth doing only if something server-side starts hanging off the uid (synced
    bookmarks, an entitlement on the account). Today everything that matters is local or
    StoreKit (fact 8).
- **F2: Account deletion.**
  - This is a gap that already exists for Google too. App Store Guideline 5.1.1(v) requires
    in-app account deletion for apps that create accounts. For Apple accounts, deletion
    must also revoke the token: `Auth.auth().revokeToken(withAuthorizationCode:)`
    (`Auth.swift:1445`, not iOS-gated). That needs the Step 0 private key filled in, and
    the authorization code captured at sign-in.
  - Default: out of scope here, and a separate plan **before App Store submission**.
    Review will likely ask for it once Apple sign-in ships.
- **F3: Launch-time revocation check.**
  - Default: skip `ASAuthorizationAppleIDProvider().getCredentialState(forUserID:)`.
  - The limit: a user who does "Stop Using" in Settings stays signed in on this Mac until
    they sign out.
  - Add it next to `restore()` if that matters. Apple recommends it; Firebase doesn't
    require it.

## 9. Risks and exits

| Risk | Sev / conf | Leading indicator | Exit |
|---|---|---|---|
| Profile lacks the capability | High / medium | Signing error at build, or `ASAuthorizationError` 1000 on tap with no sheet | *Signing & Capabilities ▸ + Sign in with Apple*, or enable it on the App ID and let Xcode re-provision |
| Provider not enabled in Firebase | High / high if Step 0 is skipped | "operation not allowed" (17006) under the button, after the Apple sheet succeeded | Step 0 |
| Nonce mismatch | Medium / low | Firebase "invalid credential" / nonce error after the sheet | The request gets `sha256(nonce)`; Firebase gets the raw `nonce`. Check they aren't swapped. |
| Name never shows | Low / medium | "Signed in" instead of a name after row 1 | Do row 6 to re-run the first-time path. If it's still blank, `[Inference]` in fact 2 is wrong: set it with `user.createProfileChangeRequest()` from `credential.fullName` right after sign-in. |
| Continuation leak | Medium / low | Window stays dimmed after the sheet closes | Log both delegate callbacks. The bridge's retention (§4) is the first suspect. |

## 10. Sequence

1. Step 0: console and portal. Nothing in the repo; fully reversible.
2. Step 1: entitlement. Build green.
3. Step 2: `AuthViewModel`. Build green.
4. Step 3: `SignInView` and the asset delete. Build green, then matrix rows 1-3.
5. Step 4: comment sweep. The grep in Step 4 comes out clean.
6. Both gates green, then the full matrix.

One commit per step works. Steps 2 and 3 can squash if you'd rather not land a method
nothing calls.

## 11. Open questions

- `[Unverified]` Firebase accepts Apple as a provider with the Services ID and key fields
  blank for native-only use. Settled by Step 0 plus row 1.
- `[Unverified]` `apple.logo` passes App Review as the logo on a custom button. Settled
  at review; the exit is in Step 3.
- `[Inference]` The backend sets `displayName` from the forwarded `fullName`. Settled by
  row 1, with the exit in §9.
- `[Unverified]` A typed `catch` on `AuthErrorCode` bridges from Firebase's NSError.
  Irrelevant if the `NSError` code comparison in Step 2 is used.
