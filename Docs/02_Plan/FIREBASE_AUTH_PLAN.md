# Firebase Auth — Google Sign-In (macOS)

Plan for adding optional Google sign-in to One Word via Firebase Auth. Scoped to
**Google only**, matching what is already enabled in the Firebase console.

---

## 1. Scope

**In**

- `FirebaseApp.configure()` at launch.
- Sign in with Google, sign out, and silent restore of the previous session.
- Signed-in identity (name, email, photo URL) surfaced in the **Profile** pane.

**Out — deliberately, not deferred by accident**

| Skipped | Add when |
|---|---|
| A login wall in front of the app | Never. The app is offline-first over bundled JSON; a wall would make it *worse* for a user who never signs in. |
| Email/password, Sign in with Apple | A second provider is actually wanted. Apple also needs a `Sign in with Apple` capability + a service ID. |
| Firestore sync of bookmarks / learned / history | There is a real cross-device sync feature. Auth alone doesn't need it. |
| `FirebaseStorage` | Something uploads a file. |
| An `AuthProviding` protocol / DI seam | There is a second implementation. One concrete `@Observable` class is testable enough here. |
| A user document in Firestore | Server-side data exists that isn't already on the `User` object. |
| Token-refresh / offline caching code | Never — `FirebaseAuth` already persists the session in the keychain and refreshes ID tokens itself. |

---

## 2. What is already true (verified against the repo)

- **This is a macOS app.** `SDKROOT = macosx`, `MACOSX_DEPLOYMENT_TARGET = 14.0` on
  both targets. The `GoogleService-Info.plist` was generated from an **iOS** app
  registration (`GOOGLE_APP_ID = 1:554130091393:ios:…`) — the bundle id matches
  (`com.hariom.swift.oneword`) and the iOS OAuth client type is the one
  GoogleSignIn uses on macOS too, so this is fine as-is.
- **Packages are already linked.** `firebase-ios-sdk` 12.18.0 is pinned; `FirebaseAuth`,
  `FirebaseFirestore`, `FirebaseStorage` are in the **app target's** Frameworks phase
  only. The widget links `Cocoa.framework` and nothing else. Good — keep it that way.
- **`GoogleService-Info.plist` needs no pbxproj entry.** `OneWord/` is a
  `PBXFileSystemSynchronizedRootGroup`, so the file already joins the app target's
  resources by living on disk.
- **`OneWord/Info.plist` is a partial plist** merged into the generated one
  (`GENERATE_INFOPLIST_FILE = YES` + `INFOPLIST_FILE`). It already carries `NSServices`
  — an array of dicts with no `INFOPLIST_KEY_*` equivalent. `CFBundleURLTypes` is the
  same shape and belongs in the same file.
- **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`** on both targets, so new types are
  main-actor isolated unless marked otherwise.

### The hard constraint: `OneWord/Shared/` must never import Firebase

`Shared/` is compiled into the **widget** target by explicit path in `project.pbxproj`,
and `tools/check_*.sh` compiles those same files with bare `swiftc` — no package
graph, no Firebase. A single `import FirebaseAuth` under `Shared/` breaks the widget
build *and* all four gates. **All auth code lives in `Models/` and `ViewModels/`.**

---

## 3. Four macOS blockers, each verified in the SDK source

These are the reasons this is not a five-minute copy of the iOS tutorial.

### 3.1 Firebase's own Google flow does not exist on macOS

`Auth.signIn(with provider: FederatedAuthProvider,…)` — the web-based flow that would
let us skip a second SDK — sits inside `#if os(iOS)` (`FirebaseAuth/Sources/Swift/Auth/Auth.swift:493`,
declarations at `:529` and `:583`). Same for `OAuthProvider`'s
`getCredentialWith` (`OAuthProvider.swift:226`).

`GoogleAuthProvider.credential(withIDToken:accessToken:)` is **not** gated and works
everywhere. So the shape is forced: **get the Google ID token ourselves, hand it to
Firebase.** That means adding the GoogleSignIn SDK.

`GoogleSignIn-iOS` declares `.macOS(.v10_15)` and exposes
`signInWithPresentingWindow:completion:` on `TARGET_OS_OSX`, backed by
`ASWebAuthenticationSession`. That's the supported path. (Hand-rolling
ASWebAuthenticationSession + PKCE is the only alternative and is far more code.)

### 3.2 The sandbox has no network access

`OneWord/OneWord.entitlements` has `app-sandbox` and `application-groups` — and no
`com.apple.security.network.client`. Without it every Firebase request and the
`ASWebAuthenticationSession` load fail. **Must be added.**

### 3.3 Firebase Auth's keychain writes need a keychain entitlement on macOS

`AuthKeychainServices.genericPasswordQuery` sets
`kSecUseDataProtectionKeychain = true` unconditionally
(`FirebaseAuth/Sources/Swift/Storage/AuthKeychainServices.swift:232`). On macOS the
data-protection keychain requires the app to be signed with `keychain-access-groups`,
or `SecItemAdd` returns `-34018 errSecMissingEntitlement` and the session never
persists across launches. **Add Keychain Sharing.**

### 3.4 The OAuth callback scheme must be registered

`GIDSignIn.m:750–757` builds the redirect as
`<reversed client id>:/oauth2callback`. That scheme has to appear in
`CFBundleURLTypes`.

---

## 4. The build

Six steps. Steps 1–3 are project configuration and land before any Swift is written.

### Step 1 — Entitlements

**`OneWord/OneWord.entitlements`** (app target only; the widget stays as it is)

```xml
<key>com.apple.security.network.client</key>
<true/>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.hariom.swift.oneword</string>
</array>
```

Adding `keychain-access-groups` by hand keeps it in the file we already own; doing it
through Xcode's *Signing & Capabilities ▸ Keychain Sharing* writes the same thing.
Either way the provisioning profile has to be regenerated — Xcode does this on the
next build with automatic signing.

> **Why `network.client` and not `network.server`:** we only make outbound calls.
> `ASWebAuthenticationSession` runs the browser out of process.

### Step 2 — `CFBundleURLTypes`

**`OneWord/Info.plist`** — append alongside the existing `NSServices` key, with a
comment in the same voice as the one already there:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.554130091393-qnbo6l4103q98ums563v0douva9d749h</string>
        </array>
    </dict>
</array>
```

That string is `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`, verbatim.

### Step 3 — Package changes

**Add** `GoogleSignIn` (product `GoogleSignIn`) from
`https://github.com/google/GoogleSignIn-iOS`, up-to-next-major from 9.0.0, to the
**app target only**. `GoogleSignInSwift` is a SwiftUI button component — skip it, we
draw our own button in the app's own visual language.

**Remove** `FirebaseFirestore` and `FirebaseStorage` from the app target's Frameworks
phase. Neither is used, and Firestore alone drags in gRPC, abseil, and BoringSSL —
minutes of build time and tens of MB of binary for nothing. Re-add either the day a
feature needs it; the package reference stays, so it is a two-click change.

> This one is a judgement call, not a requirement. If you would rather leave them
> linked so a sync feature can start without touching the project file, say so and
> the step drops.

### Step 4 — Configure Firebase at launch

**`OneWord/WordCapture.swift`** — `AppDelegate.applicationDidFinishLaunching` already
exists and already runs at exactly the right moment. Two lines, no new file:

```swift
func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.servicesProvider = provider
    FirebaseApp.configure()
}
```

`FirebaseApp.configure()` reads `GoogleService-Info.plist` from the bundle, and
`GIDSignIn` picks up the client id from the same plist — so no `GIDClientID` key and
no hard-coded client id anywhere.

> `AppDelegate` lives in `WordCapture.swift` today because word capture was the only
> thing that needed one. Adding a second unrelated responsibility to that file is
> mild — if it grates, move `AppDelegate` to its own `OneWord/AppDelegate.swift` as a
> separate, mechanical commit. Not part of this feature.

### Step 5 — `OneWord/ViewModels/AuthViewModel.swift` (new)

The whole feature, in one `@Observable` class. Sketch:

```swift
import Observation
import AppKit          // NSWindow for the presenting window — not SwiftUI
import FirebaseAuth
import GoogleSignIn

@Observable
final class AuthViewModel {
    private(set) var user: User?          // FirebaseAuth.User — nil = signed out
    private(set) var busy = false
    private(set) var error: String?

    /// Firebase restores the keychain session before this runs, so `currentUser`
    /// is already populated on a warm launch — no round trip needed.
    func restore() { user = Auth.auth().currentUser }

    func signIn(presenting window: NSWindow) async { … }
    func signOut() { … }
}
```

`signIn` is the only non-obvious body:

1. `let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)`
2. `guard let idToken = result.user.idToken?.tokenString else { throw … }`
3. `let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)`
4. `user = try await Auth.auth().signIn(with: credential).user`

`signOut` calls `GIDSignIn.sharedInstance.signOut()` **and** `try Auth.auth().signOut()`
— dropping only the Firebase session leaves Google's cached grant behind, and the next
sign-in silently reuses the old account with no chooser.

**Why `AppKit` in a view model is acceptable here:** `ARCHITECTURE.md` says view models
never import SwiftUI and never name a view type. `NSWindow` is a platform type the SDK
demands, not one of our views — the seam (no SwiftUI, testable without a window) holds.

**Isolation:** the target defaults to `MainActor`, which is what we want — `user` drives
a view. No `nonisolated` anywhere in this file.

**Error handling:** `GIDSignIn` reports user-cancelled as
`GIDSignInError.canceled`. Swallow that one silently; surface everything else as a
short string in `error`. A cancelled sign-in is not a failure worth a red banner.

### Step 6 — `OneWord/Views/ProfileView.swift` (edit)

The pane is already the right home: it shows *your* stuff, and it already owns a
`@State private var model = ProfileViewModel()`. Add a second `@State` for
`AuthViewModel` and one block at the top of the `ScrollView`:

- **Signed out** — a single button, `Theme`-styled like the existing "Learned" row
  (`t.surface`, `RoundedRectangle(cornerRadius: 8)`), reading *Sign in with Google*.
- **Signed in** — display name and email, an `AsyncImage` for the photo, and a
  *Sign out* button.
- **Busy** — a `ProgressView`, button disabled.

The presenting window comes from `NSApp.keyWindow`. One line, and correct for a
single-window app:

```swift
// ponytail: single-window app — keyWindow is always ours. A WindowAccessor
// NSViewRepresentable is the general answer if this ever gets a second window.
guard let window = NSApp.keyWindow else { return }
```

`.task { auth.restore() }` alongside the existing `model.refresh()`.

Nothing else in the app changes. `RootView`, the sidebar, `HomeView`, and the widget
are all untouched — a signed-out user sees exactly what they see today.

---

## 5. Open for you to decide

Both have a default already baked into the steps above; say the word if you want the
other branch.

1. **Where sign-in lives.** Planned: inside the Profile pane, optional, app fully usable
   signed out. The alternative is a launch gate. *Recommendation: Profile pane.* An
   offline word-of-the-day app that demands a login is strictly worse than one that
   doesn't.
2. **Unlinking Firestore + Storage** (Step 3). *Recommendation: unlink.* Costs build
   time and binary size today, buys nothing until there's a sync feature.

---

## 6. Verification

Both project gates, unchanged from `CLAUDE.md`:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture; do bash tools/$s.sh; done
```

The gates compile `OneWord/Shared/*.swift` with bare `swiftc`. Since no auth code goes
in `Shared/`, they should stay green untouched — **if one goes red, something leaked
into `Shared/` and that is the bug**, not the script.

Then, by hand:

| Check | Expected |
|---|---|
| Sign in | Browser sheet opens, account chooser appears, sheet closes, name + email render |
| Cancel the sheet | No error banner, still signed out |
| Quit and relaunch | Still signed in — this is the one that proves 3.3 (keychain entitlement) is right |
| Sign out, sign in again | The account chooser appears again, not a silent re-login |
| Widget | Still renders; still no Firebase symbols linked into the extension |
| Console on launch | No `-34018`, no `errSecMissingEntitlement`, no App Group warnings |

---

## 7. Notes

- **`GoogleService-Info.plist` is committed.** That is normal — it ships inside every
  distributed app bundle and is not a secret; `API_KEY` there is a client key scoped by
  the Firebase console's own restrictions, not a server credential. Worth knowing rather
  than worth fixing. What *would* matter is locking down the API key's allowed
  referrers/bundle ids in the Google Cloud console, and setting Firebase Auth's
  authorized domains.
- **Firebase console:** Google is already enabled as a provider. Nothing else to do
  there for this scope.
- **First build after Step 1** will re-provision. If Xcode complains about the
  keychain group, confirm the team (`LAP54KU2SV`) is still selected on both targets.
