# Sign in with Apple — Plan Audit

This audits [`../APPLE_SIGN_IN_PLAN.md`](../APPLE_SIGN_IN_PLAN.md) before it's built. Every
citation in the plan was treated as a claim and reopened. The plan was written in the same
session as this audit, so the bias to watch for is going easy on it. The checks below
include two suspicions I raised myself: one was refuted by the compiler, and one turned up
a wrong fact.

## 1. Grounding

**The stack, re-checked:**

- **Platform.** macOS app. The deployment target is 14.0, set at project level
  (`project.pbxproj:458`, `:516`) and inherited by the app target.
- **Swift settings on the app target:**
  - `SWIFT_VERSION = 5.0` (`:557`, `:594`)
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (`:554`, `:591`)
  - `SWIFT_APPROACHABLE_CONCURRENCY = YES` (`:553`, `:590`)
  - `MEMBER_IMPORT_VISIBILITY = YES` (`:556`, `:593`)
  - No `SWIFT_STRICT_CONCURRENCY` key, so strict concurrency is at the Swift 5 default
    ("minimal").
- **Signing.** `CODE_SIGN_STYLE = Automatic` (`:532`, `:569`).
- **Architecture and packages.** MVVM with `@Observable` injected through `@Environment`.
  Firebase Auth 12.18.0 and GoogleSignIn 9.2.0 are linked to the app target only.
- **Tests.** No XCTest target. The `tools/check_*.sh` gates compile specific files with
  bare `swiftc`.
- **No String Catalog.** No `.xcstrings` or `.strings` files anywhere in `OneWord/` or
  `OneWordWidget/`.
- **Discrepancy with the plan.** The plan's stack table cites `:364`, `:371` and `:373`.
  Those lines are in the **widget's** build configuration. The values are the same for the
  app target, so this is a citation nit (m7), not a stack mismatch.

**Files opened:**

| File | Lines | What was checked |
|---|---|---|
| `AuthViewModel.swift` | all | |
| `SignInView.swift` | 1-101 | `signInButton` at `:66`, hue comment `:67-69`, error text `:42-49` |
| `RootView.swift` | 80-110 | gate `:91-100`, busy overlay `:107` |
| `Doodles.swift` | 95-126 | `BusyOverlay` and `.busy` |
| `ProfileView.swift` | 460-506 | `AvatarFace`, `AccountAvatar`; plus the grep hits at `:33`, `:48`, `:50`, `:149`, `:312` |
| `Profile.swift` | 1-40 | |
| `WordCapture.swift` | 20-47 | |
| `OneWord.entitlements`, `Info.plist` | all | |
| `project.pbxproj` | every build-setting line | |
| Firebase `OAuthProvider.swift` | `#if` nesting at `:333` | depth 0, so not iOS-gated |
| Firebase `VerifyAssertionRequest.swift` | 155-180 | |
| Firebase `AuthErrors.swift` | `:51`, `:83` | |
| Firebase `AuthErrorUtils.swift` | 499-510 | |
| Firebase `Auth.swift` | `#if` nesting at `:1445`, `:1464` | depth 0 |
| macOS SDK `ASAuthorizationController.h` | 15-63 | |
| CoreGlyphs `name_availability.plist` | `apple.logo` entry | |

**Compiler check:** a scratch `swiftc -typecheck` of the plan's `catch where …` spelling.

## 2. Verdict

**Ready to build.** Confidence: medium-high.

**Why:**
- Every load-bearing fact in the plan checks out against the source:
  - Firebase's `appleCredential` is not iOS-gated.
  - The name is forwarded as a `user` JSON query item.
  - Both AuthenticationServices delegate protocols are main-actor, and their delegate
    references are `weak`.
  - `AuthErrorCode` has the shape the plan assumes.
  - `revokeToken` is not gated.
  - An empty photo URL really does fall back to the generic head.
- The concurrency and lifetime design is sound under this target's settings.
- I found no blockers and no majors. What's left is eight minor corrections to the plan's
  text, each a line or two, plus three calls that belong to you.

**What's still uncertain** sits outside the repo: how Firebase's console and backend behave,
and how App Review reads the custom button. The plan already tags those `[Unverified]` and
gives each an exit.

## 3. Blocking findings

None.

**Raised and withdrawn:** I suspected that `catch where (error as NSError).code == …`
(Step 2) would not compile, because Swift's published grammar attaches `where` to a pattern.
`swiftc -typecheck` on a scratch file accepts it. Pattern-less `catch where`, with the
implicit `error` binding, is valid. Withdrawn.

## 4. Major findings

None.

## 5. Minor findings and nits

**m1. Nonce hashing: the hex case is unspecified** (Plan Step 2, "Nonce helpers")
- **Problem:** The plan says `sha256` is "hex-encoded" but never says lowercase. The value
  on `request.nonce` has to equal what Firebase computes from `rawNonce`, and Firebase's
  reference implementation uses lowercase hex (`%02x`). An implementer who picks `%02X`
  gets Firebase's "invalid credential" / nonce error after a successful Apple sheet.
  `[Inference]` I didn't open Firebase's server-side comparison. The case convention comes
  from Firebase's documented sample.
- **Fix:** In the plan, write "lowercase hex (`String(format: "%02x", $0)`)".
- **Why minor:** Matrix row 1 catches it on the first tap, and §9 already names the symptom.

**m2. Optional delegate methods can fail silently** (Plan Step 2, `AppleAuthorization`, and §9)
- **Problem:** Both delegate methods are `@optional` (`ASAuthorizationController.h:22`). A
  misspelled `authorizationController(controller:didComplete…)` still compiles, with only a
  "nearly matches optional requirement" warning. The callback is then never delivered, the
  continuation never resumes, and `busy` stays true. Because `BusyOverlay` swallows every
  click (`Doodles.swift:108-111`), the gate becomes unusable until the app quits. §9 lists
  the symptom ("window stays dimmed") but not this cause.
- **Fix:** Add to Step 2's verify: "the build log shows no *nearly matches optional
  requirement* warning for `AppleAuthorization`."

**m3. `apple.logo` availability is stated wrongly** (Plan Step 3 and §6)
- **Problem:** The plan says `apple.logo` "needs macOS 11". The system's own table says
  macOS 13.0: `name_availability.plist` maps `apple.logo` to release `"2022"`, which is
  `macOS 13.0`. The deployment target is 14.0, so the conclusion (no `@available` needed)
  still holds. Only the stated fact is wrong.
- **Fix:** Change "11+" to "13+" in both places.

**m4. Step 4's done-when is miscounted** (Plan Step 4)
- **Problem:** The plan expects the remaining `Google` hits to include "the Firestore URL in
  `FeedbackViewModel.swift`". That URL is `firestore.googleapis.com`, lowercase, so a
  case-sensitive `Google` grep never matches it. The actual hit is the **comment** at
  `FeedbackViewModel.swift:142`: "The Firebase ID token, not the Google one". That comment
  also goes stale for Apple users, and the sweep's list missed it.
- **Fix:** Add `FeedbackViewModel.swift:142` to Step 4's list (for example, "not the
  provider's one"). Change the done-when to: only `AuthViewModel.swift`, `SignInView.swift`
  and `WordCapture.swift` remain.

**m5. The collision error needs a domain check** (Plan Step 2)
- **Problem:** Comparing only `(error as NSError).code == 17012` would match an error from
  any domain that happens to use code 17012. Firebase builds these errors through
  `AuthErrorUtils.error(code:…)` (`AuthErrorUtils.swift:509`).
- **Fix:** Also check `error.domain == AuthErrorDomain`.
- **Why a nit:** It's unlikely to matter in practice, but the correct version costs one
  clause.

**m6. F2 names the wrong way to get the authorization code** (Plan §8 F2)
- **Problem:** F2 says account deletion needs "the authorization code captured at sign-in".
  Apple's authorization codes are short-lived and single-use. `[Inference]` from Apple's
  documented five-minute validity; not verified in this repo. The deletion flow would
  normally run Sign in with Apple again at delete time to get a fresh code, and pass that to
  `revokeToken(withAuthorizationCode:)` (`Auth.swift:1445`, verified not gated).
- **Fix:** Change F2's wording to "a fresh authorization code, from re-running the Apple
  sheet at delete time".
- **Why minor:** It's an out-of-scope fork, but the wrong wording would mislead the
  follow-up plan.

**m7. Citation nits**
- The stack table's pbxproj lines point at the widget's configuration (see §1). The app
  target's are `:553-557` and `:590-594`; the deployment target is at `:458` / `:516`.
- `Profile.swift:34` ("Never named after the provider") is at `:35`.
- `SignInView.swift:42-50` is `:42-49`.

**m8. Swift 6 note in §4 is slightly overstated** (Plan §4, "No `Sendable` crossings")
- **Problem:** Handing the non-`Sendable` `ASAuthorizationAppleIDCredential` through
  `continuation.resume(returning:)` is a `sending` hand-off. Under this target's Swift 5
  mode with minimal checking it compiles quietly. `[Inference]` A later move to Swift 6
  language mode may diagnose it.
- **Fix:** Soften the §4 line to "none diagnosed under Swift 5 / minimal; revisit on a
  Swift 6 migration".
- **Why a nit:** It's a note for later, not a defect today.

## 6. Coverage gaps

- **Reverse collision isn't tested.** Matrix row 7 checks Apple after Google with the same
  email. The opposite order (an Apple account exists, then Google sign-in with the same
  address) isn't covered. `[Unverified]` Google is a trusted provider for `@gmail.com`, so
  Firebase may link or replace instead of throwing 17012. Add a row. The Google path's
  generic `localizedDescription` handling (`AuthViewModel.swift`, `signIn(presenting:)`)
  would show Firebase's own sentence either way.
- **No Mac without an Apple Account.** Nothing in the matrix covers a Mac that isn't signed
  in to an Apple Account. Add a row: tap *Sign in with Apple* and expect the system's
  sign-in prompt or a legible error under the button.
- **Token audience isn't in §9.** Firebase checks the Apple identity token's audience,
  which is the bundle id. The project's Firebase app registration is an iOS app with the
  same bundle id (`com.hariom.swift.oneword`, per the resolved Firebase plan §2), so this
  should pass. `[Unverified]` The symptom if it doesn't: an "invalid audience" error after
  the sheet. The exit: add the bundle id or a Services ID in the Firebase console's Apple
  provider.
- **No automated check on the nonce hash.** This is accepted, and the plan says why: the
  gates can't link Firebase, and a wrong hash fails loudly on row 1. Noted so it's a
  choice on record, not an oversight.

## 7. What the plan got right

- **Each fact it leans on holds at source.** Firebase's `appleCredential` is at
  `#if`-depth 0. `fullName` is sent as the `user` query item
  (`VerifyAssertionRequest.swift:163-176`). The delegate protocols are `NS_SWIFT_UI_ACTOR`,
  and the delegate references are `weak`.
- **The lifetime design is correct:**
  - The caller holds the bridge across the `await`.
  - The bridge holds the controller strongly, and the controller holds the bridge weakly.
  - There is no cycle and no leak.
  - Setting `continuation = nil` after resuming guards against a double resume.
- **The busy overlay can't block the sheet.** This is my own check; the plan doesn't state
  it. `.busy` is a SwiftUI `overlay` inside the window's content (`Doodles.swift:120-125`),
  so the AppKit sheet presented on that window sits above it.
- **The empty-photo claim is true in the rendering code,** not just the doc comment:
  `AsyncImage(url: nil)` shows the `person.crop.circle` placeholder
  (`ProfileView.swift:478-484`), and both the sidebar and Profile use it.
- **Scope is right-sized.** There are no new files, no protocol with one implementation,
  no package, no Info.plist change, and the widget and `Shared/` are untouched.
- **The deferrals are honest.** Account deletion, account linking and the revocation check
  are surfaced as forks with limits named, not silently dropped.

## 8. Questions for you

1. **Deleting `apple_icon.imageset`.** The plan decides to delete it. You added it in
   `9519581` ("Put a face on the app"), probably staged for exactly this button.
   - The plan's reason still stands: it's an icons8 redraw, and Apple's HIG asks for
     Apple's own artwork.
   - The call is yours: delete it, or keep it as the fallback if App Review objects to the
     SF Symbol.
2. **Apple above Google.** The plan puts Apple first, citing HIG prominence. The HIG only
   requires *at least as prominent*, so side by side or Google first at the same size would
   also comply. Keep Apple first?
3. **The per-button "Signing in…" label** (Step 3's `tapped` state). It keeps today's
   behaviour, but it sits under a 70% scrim (`Doodles.swift:109`). Dropping it (static
   titles, with the overlay as the only busy signal) is two fewer lines. Keep or drop?

## 9. What would change the verdict

- **To Fix blockers first:**
  - Firebase turns out to need the Services ID and key even for native-only use. Step 0
    then gains required fields, which is still not a code change.
  - Or App Review rejects the custom button outright. Step 3's exit (Apple Design Resources
    artwork) covers the logo, not a rejected layout.
- **To Needs rework:** Firebase's backend turns out *not* to set `displayName` from the
  forwarded name, **and** you consider an unnamed Apple account unacceptable. The plan's
  exit (`createProfileChangeRequest` after sign-in) is then no longer optional, and Step 2
  gains a write.
- **None of these can be settled from the repo.** All three are settled by Step 0 plus
  matrix row 1, on the first real sign-in.
