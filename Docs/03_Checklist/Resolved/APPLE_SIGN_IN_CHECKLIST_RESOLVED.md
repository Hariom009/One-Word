# Sign in with Apple — Checklist (Resolved)

The build checklist for
[`../../02_Plan/Resolved/APPLE_SIGN_IN_PLAN_RESOLVED.md`](../../02_Plan/Resolved/APPLE_SIGN_IN_PLAN_RESOLVED.md).

> A revision of [`../APPLE_SIGN_IN_CHECKLIST.md`](../APPLE_SIGN_IN_CHECKLIST.md) that answers
> [`../Audit/APPLE_SIGN_IN_CHECKLIST_AUDIT.md`](../Audit/APPLE_SIGN_IN_CHECKLIST_AUDIT.md).
> **Tick this one; it stands alone.** The changes:
> - **M1:** every git-based gate now diffs against `$B`, the fork point, and is scoped to
>   the plan's files. That's 1c, G1, G4, G5 and G6.
> - **M2:** the token-audience exit is added to `⏸`.
> - **m1:** 4a carries the quoted text, and its line numbers are re-pointed at `main`.
> - **m2:** 2b checks the new line was added, not just the old one removed.
> - **m3:** M6 says where to look for the uid.
> - **m4:** 1b gives the command that finds the built app.
> - **n1-n4:** marked where the checklist, not the plan, made the call.

**About the plan it comes from:**
- It has been **audited and resolved**:
  [plan](../../02_Plan/APPLE_SIGN_IN_PLAN.md) →
  [audit](../../02_Plan/Audit/APPLE_SIGN_IN_PLAN_AUDIT.md) (ready to build, no blockers) →
  resolved plan.
- It is a single change: one PR, one ordered list.
- This checklist transforms that plan and nothing more. It does not re-audit it. The plan's
  `[Unverified]` tags are carried onto the items they touch.

**Stack:** macOS 14 app, SwiftUI with MVVM (`@Observable` via `@Environment`), Swift 5
mode, default actor isolation `MainActor`, `MEMBER_IMPORT_VISIBILITY` on, Firebase Auth
12.18 and GoogleSignIn 9.2 linked to the app target only, no XCTest target.

**Files checked to size the items:**
- `AuthViewModel.swift:150-151`: the `dbg` / `photodebug.txt` lines
- `SignInView.swift:9`, `:78`, `:83`: the header, the in-label comment, the busy title
- `project.pbxproj:551`: `PRODUCT_NAME = "One Word"`

## How to use

| Mark | Meaning |
|---|---|
| `- [ ]` | to do |
| `- [x]` | done |
| `blocked-by:` | must wait for that item |
| `⏸` | deferred on purpose; leave unchecked |
| `DECIDE:` | a call that's yours to make |

**Rule:** don't tick an item until its **done-when** holds.

These two commands come up in many done-whens. They are the project's gates from
`CLAUDE.md`:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture check_premium; do bash tools/$s.sh; done
```

If Xcode has a debug run of One Word open, add
`-derivedDataPath /tmp/oneword-apple-build` to the build command. That way the build
doesn't overwrite the running app's products.

**The fork point.** The git-based done-whens diff against where this branch split from
`main`. That keeps them working after a step is committed, and blind to changes outside
the plan:

```bash
B=$(git merge-base main HEAD)
```

**Commits.** The plan suggests one commit per step (plan §11), and Steps 2 and 3 can be
squashed together.

**No automated test,** deliberately (plan §7). `AuthViewModel` imports Firebase, and
`tools/check_*.sh` compile with bare `swiftc`, so they can't link it. The build, the gates
and the manual matrix below are the verification.

---

## Setup (outside the repo)

- [x] **S1** Turn on Apple as a sign-in provider: Firebase console ▸ Authentication ▸
  Sign-in method ▸ Add ▸ Apple ▸ Enable. `[Unverified]` The plan says the Services ID,
  team ID and key fields can stay blank for use on Apple platforms only.
  - **done-when:** Apple shows as **Enabled** in the provider list.
- [x] **S2** Confirm the App ID `com.hariom.swift.oneword` has the **Sign in with Apple**
  capability. Automatic signing should add it when 1b builds. Turn it on by hand only if
  1b fails with a provisioning error. `blocked-by: 1a`
  - **done-when:** 1b's `codesign` output lists `com.apple.developer.applesignin`, or the
    Apple Developer portal shows the capability checked on the App ID.

## Step 1: Entitlement

- [x] **1a** Add `com.apple.developer.applesignin` = `[Default]` to the entitlements file,
  after `keychain-access-groups`, with the plan's comment. The comment must not claim a
  specific error code.
  - files: `OneWord/OneWord.entitlements` (MODIFIED, app target)
  - **done-when:**
    - `plutil -lint OneWord/OneWord.entitlements` prints OK.
    - `/usr/libexec/PlistBuddy -c "Print :com.apple.developer.applesignin:0" OneWord/OneWord.entitlements`
      prints `Default`.
- [x] **1b** Build and confirm the signature carries the key. `blocked-by: 1a`
  - **done-when:**
    - The build command succeeds.
    - `codesign -d --entitlements - "$P/One Word.app"` lists
      `com.apple.developer.applesignin`, where `P` is the built-products folder. Find it
      with the same flags as the build:
      `P=$(xcodebuild -project OneWord.xcodeproj -scheme OneWord -showBuildSettings | awk '/ BUILT_PRODUCTS_DIR /{print $3}')`.
- [x] **1c** Leave the widget's entitlements alone.
  - **done-when:** `git diff --quiet $B -- OneWordWidget/` exits 0.

## Step 2: `AuthViewModel`, the Apple flow

All of these are in `OneWord/ViewModels/AuthViewModel.swift` (MODIFIED, app target), with
isolation `MainActor` by the target default.

- [x] **2a** Add `import AuthenticationServices` and `import CryptoKit`.
  - **done-when:** both lines are present, and the build is green.
- [x] **2b** Update the header comment to cover both providers. Add the line saying Apple
  needs no extra SDK because `appleCredential` isn't iOS-gated.
  - **done-when:**
    - `grep -n "Google sign-in, the whole feature" OneWord/ViewModels/AuthViewModel.swift`
      prints nothing.
    - `sed -n '1,/^import/p' OneWord/ViewModels/AuthViewModel.swift | grep -n "appleCredential"`
      prints a hit, which shows the new line is in the header comment.
- [x] **2c** Add the two `private static` nonce helpers:
  - `randomNonce()`: 32 × `UInt8.random(in: .min ... .max)`, lowercase hex.
  - `sha256(_:)`: `SHA256.hash(data: Data(s.utf8))`, lowercase hex.
  - Both use `String(format: "%02x", $0)`.
  - **done-when:**
    - The build is green.
    - `grep -n '%02X' OneWord/ViewModels/AuthViewModel.swift` prints nothing (no
      uppercase).
- [x] **2d** Add `private final class AppleAuthorization` at the bottom of the file, per
  the plan's sketch. `blocked-by: 2a`
  - [x] **2d-i** It subclasses `NSObject` and conforms to `ASAuthorizationControllerDelegate`
    and `ASAuthorizationControllerPresentationContextProviding`. It stores `window`,
    `controller` (strong) and `continuation`.
    - **done-when:** the build is green.
  - [x] **2d-ii** `perform(_:)` wraps `withCheckedThrowingContinuation`. Inside, it builds
    the controller, stores it in `self.controller`, sets `delegate` and
    `presentationContextProvider` to `self`, and calls `performRequests()`.
    - **done-when:** reading it shows the controller is assigned to the stored property,
      not left as a local only.
  - [x] **2d-iii** Write both delegate callbacks. The names must match the protocol exactly:
    `authorizationController(controller:didCompleteWithAuthorization:)` and
    `authorizationController(controller:didCompleteWithError:)`. Each ends with
    `continuation = nil`. The authorization callback throws if the credential isn't an
    `ASAuthorizationAppleIDCredential`.
    - **done-when:**
      - The build log has no "nearly matches optional requirement" warning:
        `<build command> 2>&1 | grep -i "nearly matches"` prints nothing.
      - Both bodies end with `continuation = nil`.
  - [x] **2d-iv** `presentationAnchor(for:)` returns `window`.
    - **done-when:** the build is green.
- [x] **2e** Add `signInWithApple(presenting:)` next to `signIn(presenting:)`, per plan
  Step 2, sub-steps 1-6: the busy guard, then the request with scopes and hashed nonce,
  then `perform`, the identity-token guard, `appleCredential(…rawNonce: nonce, fullName:)`,
  `user =`, and `recordJoinDate()`. `blocked-by: 2c, 2d`
  - **done-when:**
    - The build is green.
    - The request is given `Self.sha256(nonce)` and Firebase is given the raw `nonce`, not
      the other way round.
- [x] **2f** Catch errors in this order. `blocked-by: 2e`
  1. `catch let e as ASAuthorizationError where e.code == .canceled`: return silently.
  2. `catch let e as NSError where e.domain == AuthErrors.domain && e.code == AuthErrorCode.accountExistsWithDifferentCredential.rawValue`:
     set `error = "That email already signs in with Google. Use Google instead."`
  3. `catch`: set `self.error = error.localizedDescription`.
  - **done-when:** the build is green, and the three `catch` clauses appear in that order.
- [x] **2g** Drive-by: delete the `dbg` / `photodebug.txt` lines in `restore()` (currently
  `:150-151`). Optional: skip it if you want the diff pure.
  - **done-when:** `grep -rn "photodebug" OneWord` prints nothing, and the build is green.

## Step 3: `SignInView`, the second button

All of these are in `OneWord/Views/SignInView.swift` (MODIFIED, app target), except 3e.
`blocked-by: 2e` (the Apple button calls `signInWithApple`).

- [x] **3a** Change `signInButton(_ t:)` to
  `signInButton(_ t: Theme, icon: Image, title: String, action: @escaping (NSWindow) async -> Void)`.
  - It keeps the `NSApp.keyWindow` guard and `Task { await action(window) }`.
  - It keeps the same surface, hairline and radius.
  - **done-when:** the build is green.
- [x] **3b** The icon gets `.resizable().scaledToFit().frame(width: 15, height: 15)` and
  `.accessibilityHidden(true)`.
  - **done-when:** both modifiers are on the shared icon path, so they apply to both
    buttons.
- [x] **3c** Make the titles static: the label is `Text(title)`. Keep `.disabled(auth.busy)`
  on both buttons. This was your decision, Q3.
  - **done-when:** `grep -n "Signing in" OneWord/Views/SignInView.swift` prints nothing.
- [ ] **3d** Stack Apple above Google, the same size. This was your decision, Q2.
  - Apple: `Image(systemName: "apple.logo")` with `auth.signInWithApple(presenting:)`.
  - Google: `Image("google_icon")` with `auth.signIn(presenting:)`.
  - **done-when:** the build is green, and on the sign-in screen Apple is on top and both
    buttons are the same width and height (M1).
- [x] **3e** Delete `OneWord/Assets.xcassets/apple_icon.imageset/`. This was your decision,
  Q1.
  - **done-when:**
    - `test ! -e OneWord/Assets.xcassets/apple_icon.imageset` passes.
    - `grep -rn "apple_icon" OneWord` prints nothing.
    - The build is green.
- [x] **3f** Update three comments:
  - The header `:9`: "a wordmark and one button" becomes "…and a button per provider".
  - The in-label comment `:78`: the button no longer changes; the window-wide overlay is
    the busy signal.
  - The hue comment `:67-69`: add that Apple's mark is monochrome by rule and takes `t.ink`.
  - **done-when:** `grep -nE "one button|only changes its word" OneWord/Views/SignInView.swift`
    prints nothing.
- [ ] **3g** `[Unverified]` `apple.logo` meets HIG for a custom button. Carry this to App
  Review; nothing to do now.
  - **done-when:** it's noted in the PR description as a review risk, with its fallback
    (the logo from Apple Design Resources as a template image). The PR description is the
    checklist's choice of where to record it; the plan names no place.

## Step 4: Stale "Google" comments

No behaviour changes. Parallel with Steps 2-3.

- [x] **4a** Reword each of these to "the account" or "the provider". Line numbers are as
  of `main` `0f0bf03`; the quoted text is what to look for if they drift.
  - [x] `OneWord/Models/Profile.swift:5`: "…that Google doesn't hand us"
  - [x] `OneWord/Views/ProfileView.swift:33`: "Google owns the email…"
  - [x] `OneWord/Views/ProfileView.swift:47`: "…the one Google gave"
  - [x] `OneWord/Views/ProfileView.swift:148`: "…following the Google account"
  - [x] `OneWord/Views/RootView.swift:70`: "…following the Google account"
  - [x] `OneWord/ViewModels/FeedbackViewModel.swift:142`: "not the Google one" becomes
    "not the provider's one"
  - **done-when:** `grep -rln "Google" OneWord --include='*.swift'` lists exactly
    `AuthViewModel.swift`, `SignInView.swift` and `WordCapture.swift`.

---

## iOS gates (all before merge)

- [x] **G1: Isolation.** Everything stays on the default `MainActor`. `blocked-by: 2d, 2e`
  - **done-when:** `git diff $B -- OneWord/ViewModels/AuthViewModel.swift | grep -nE "^\+.*(nonisolated|Task\.detached|@preconcurrency)"`
    prints nothing.
- [ ] **G2: Bridge lifetime.** The caller holds `AppleAuthorization` across the `await`.
  The bridge holds `controller` strongly. The controller's `delegate` and
  `presentationContextProvider` are weak, so there's no cycle. Nothing stores an escaping
  closure.
  - **done-when:** 2d-ii holds, and M2 run twice in a row leaves the app responsive.
    Running it twice is the checklist's stricter check; the plan doesn't ask for it.
- [ ] **G3: Continuation resumes at most once.**
  - **done-when:** 2d-iii holds (`continuation = nil` in both callbacks), and after M1
    and M2 the busy overlay lifts.
- [x] **G4: Nothing leaks into `Shared/`.**
  - **done-when:** `git diff --name-only $B | grep "OneWord/Shared/"` prints nothing, and
    the gates command is green.
- [x] **G5: Target membership.** No new source files. The modified Swift files are already
  in the synchronized `OneWord/` group.
  - **done-when:**
    - `{ git diff --name-status $B; git status --porcelain | grep '^??'; } | grep '\.swift$' | grep -v '^M'`
      prints nothing. That means no added or untracked `.swift` file.
    - `git diff $B -- OneWord.xcodeproj/project.pbxproj` is empty, or only has changes
      Xcode made for the capability if 1a went through the Signing & Capabilities UI.
- [x] **G6: Nothing needs `@available`.**
  - **done-when:** `git diff $B -- OneWord/ViewModels/AuthViewModel.swift OneWord/Views/SignInView.swift | grep -nE "^\+.*(@available|#available)"`
    prints nothing. The plan's minimums are 10.15 for `ASAuthorizationAppleIDProvider` and
    13 for `apple.logo`, both below the 14.0 target.
- [ ] **G7: Accessibility.**
  - **done-when:** 3b holds, and M10 passes.
- [ ] **G8: The widget is untouched.**
  - **done-when:** 1c holds, and M11 passes.

## Manual matrix

Run these in a team-signed build with the `-debugSkipAuth` bypass **off** (plan §7).
`blocked-by: S1, 1b, 3d`

- [ ] **M1** Sign in with Apple ▸ Continue.
  - **done-when:** the sheet shows over the dimmed window, then the shell appears. The
    sidebar chip shows the Apple name. Profile shows the name, the email (maybe a relay
    address), the generic head and today's join date.
- [ ] **M2** Sign in with Apple ▸ Cancel.
  - **done-when:** no error text appears. You're still on the sign-in screen with the
    buttons enabled.
- [ ] **M3** Sign in with Google.
  - **done-when:** it works as today, and the title stays "Sign in with Google" while busy.
- [ ] **M4** Quit and relaunch after M1.
  - **done-when:** still signed in.
- [ ] **M5** Sign out, then Sign in with Apple.
  - **done-when:** the sheet skips the name and email step, and the name is still shown.
- [ ] **M6** System Settings ▸ Apple Account ▸ Sign in with Apple ▸ One Word ▸ Stop Using,
  then sign in with Apple.
  - **done-when:** the sheet asks for name and email again. Firebase console ▸
    Authentication ▸ Users still lists **one** Apple user, not two; the app never shows the
    uid, so check it there.
- [ ] **M7** Sign in with an Apple ID that shares the same email as an existing Google
  account.
  - **done-when:** "That email already signs in with Google…" appears under the buttons.
    No crash.
- [ ] **M8** The reverse: an Apple account exists with the real email shared, then Sign in
  with Google using the same address. `[Unverified]`
  - **done-when:** either Firebase's own collision sentence appears, or the accounts link
    silently. Write down which one happened in the PR description.
- [ ] **M9** Use a Mac user account that isn't signed in to an Apple Account.
  - **done-when:** the system's sign-in prompt appears, or a legible error under the
    button. No hang.
- [ ] **M10** VoiceOver on the sign-in screen.
  - **done-when:** it reads "Sign in with Apple, button" and "Sign in with Google, button",
    and the icons are silent.
- [ ] **M11** The widget.
  - **done-when:** it builds and renders, and `otool -L` on the extension binary shows no
    AuthenticationServices or Firebase.

## Open decisions (DECIDE)

None open. Q1-Q3 were settled when the plan was resolved: delete `apple_icon`, Apple
first, static titles. F1-F3 are deferred with their defaults (below).

## ⏸ Deferred / evidence-gated (not now)

- ⏸ **F1: Account linking.** Link Apple and Google accounts that share an email, via
  `user.link(with:)`.
  - **Gate:** something server-side starts being keyed by uid (synced bookmarks, an
    entitlement on the account).
- ⏸ **F2: Account deletion and Apple token revocation.** Uses
  `revokeToken(withAuthorizationCode:)` with a **fresh** code from running the Apple sheet
  again, and needs the key fields from S1 filled in.
  - **Gate:** before App Store submission (Guideline 5.1.1(v)). It gets its own plan.
- ⏸ **F3: Launch-time revocation check** (`getCredentialState(forUserID:)`).
  - **Gate:** it starts to matter that a user who does "Stop Using" stays signed in on
    this Mac.
- ⏸ **Name fallback.** Call `user.createProfileChangeRequest()` with `credential.fullName`
  after sign-in.
  - **Gate:** M1 shows "Signed in" instead of a name, and it's still blank after the M6
    re-run.
- ⏸ **Swift 6 `sending` check** on `continuation.resume(returning:)`.
  - **Gate:** a move to Swift 6 language mode.
- ⏸ **App Review fallback logo.** Swap in Apple Design Resources artwork.
  - **Gate:** Review rejects `apple.logo` (see 3g).
- ⏸ **Token audience.** Add a Services ID in Firebase ▸ Authentication ▸ Apple provider.
  - **Gate:** M1 fails with "invalid audience" after a successful Apple sheet.
  - `[Unverified]` The plan rates this low: `GoogleService-Info.plist`'s `BUNDLE_ID`
    already matches the app's bundle id.

## Definition of done

- [ ] **D1** Every item in S, 1-4, G and M is ticked.
  - **done-when:** no unticked box above this section, apart from the `⏸` items and 2g
    if you skipped it.
- [ ] **D2** The build command is green.
  - **done-when:** the command exits 0 on the final tree.
- [ ] **D3** All five gate scripts are green.
  - **done-when:** the gates command reports every script passing on the final tree.
- [ ] **D4** The plan's outcome holds:
  - Sign in with Apple sits above Sign in with Google, drawn the same way.
  - An Apple sign-in opens the shell and survives a relaunch.
  - Google behaves as before, apart from its static title.
  - **done-when:** M1, M3 and M4 are ticked on the final build.
- [ ] **D5** The PR description records the result of M8 and the review risk from 3g.
  - **done-when:** both are present in the PR body.
