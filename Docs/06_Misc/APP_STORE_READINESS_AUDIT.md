# App Store readiness audit — One Word (macOS)

*2026-09-27 · read-only pre-submission audit of `main` @ `675065b` · Mac App Store.*
*Filed under `06_Misc/` — the routing table has audit rows for plans and checklists only, and this audits the repo.*

## 1. Verdict

**Not ready.** Nothing blocks the upload, but three App Review blockers are in the code: the whole app sits behind a mandatory sign-in, there is no privacy-policy link, and there is no account deletion.

## 2. Build + gates

| Check | Result |
|---|---|
| `xcodebuild … -scheme OneWord -destination 'platform=macOS' build` | **green** — `** BUILD SUCCEEDED **` |
| `check_words` `check_related` `check_learned` `check_capture` `check_premium` | **green** — all five exit 0 |
| `xcodebuild archive -scheme OneWord -destination 'generic/platform=macOS'` | **green** — `** ARCHIVE SUCCEEDED **`, universal (x86_64 + arm64), signed with the team's development identity and "Mac Team Provisioning Profile: com.hariom.swift.oneword"; all seven entitlements land in the signed binary |

No red output. The archive's only non-green lines are four warnings, none of which affect validation:

```
OneWord/Models/DoodleTheme.swift:150:17: warning: call to main actor-isolated static method 'serif' in a synchronous nonisolated context
OneWord/ViewModels/AuthViewModel.swift:157:21: warning: result of call to 'addStateDidChangeListener' is unused
OneWord/ViewModels/WordListViewModel.swift:40:34: warning: call to main actor-isolated static method 'load' in a synchronous nonisolated context
OneWord/ViewModels/WordListViewModel.swift:44:41: warning: call to main actor-isolated static method 'load' in a synchronous nonisolated context
```

Archive contents verified: `GoogleService-Info.plist`, all four fonts flat in `Resources/` (matches `ATSApplicationFontsPath = .`), both audio files, all 8 dictionary JSONs in the app **and** in `OneWordWidget.appex` (so `WordProvider`'s `fatalError` at `WordProvider.swift:80` cannot fire), widget version/build match the app (1.0 / 1), `LSMinimumSystemVersion` 14.0.

## 3. Findings

Effort: **S** under an hour · **M** half a day · **L** more.

### 3a. Blocks upload

| # | what | file:line | guideline | smallest fix | effort |
|---|---|---|---|---|---|
| — | **Nothing found.** Every check in this column passed — see the pass notes below the tables. | | | | |

### 3b. Blocks review

| # | what | file:line | guideline | smallest fix | effort |
|---|---|---|---|---|---|
| R1 | **Mandatory login.** Until Firebase reports a user the entire window is `SignInView`; the daily word, search, bookmarks, dictionaries, settings and the paywall are all unreachable. The only account-backed features are the Profile header (name/email/join date) and attaching identity to feedback — nothing syncs. The widget already works signed-out. Review also has no way to sign in: both providers are OAuth, so there is no demo password to put in the review notes. | [RootView.swift:96-99](../../OneWord/Views/RootView.swift#L96), [SignInView.swift:5-7](../../OneWord/Views/SignInView.swift#L5), [AuthViewModel.swift:5-8](../../OneWord/ViewModels/AuthViewModel.swift#L5) | 5.1.1(v) "If your app doesn't include significant account-based features, let people use it without a login … Apps may not require users to enter personal information to function" · 2.1 (reviewer must be able to reach the app) | In `RootView.body`, show `shell` whenever `auth.restored` and drop the `isSignedIn` branch. Make the account chip read "Sign in" when `auth.user == nil` and route to `.profile`; in `ProfileView`, render `SignInView`'s two buttons in place of the header when signed out. `FeedbackViewModel.send` already refuses without a user ([FeedbackViewModel.swift:102-105](../../OneWord/ViewModels/FeedbackViewModel.swift#L102)), and every `auth.*` accessor is already optional, so nothing else changes. | M |
| R2 | **No privacy-policy link anywhere in the app.** `grep -ri privacy OneWord/` finds nothing. The app sends name, email, uid, feedback text and join date to Firebase, so the policy is not optional, and App Store Connect will not accept the record without a policy URL either. The page itself is planned in `WEBSITE_PLAN.md` and not built. | [SettingsView.swift:189-227](../../OneWord/Views/SettingsView.swift#L189) (where it goes), [SignInView.swift:39-69](../../OneWord/Views/SignInView.swift#L39) (must be reachable before sign-in while R1 stands) | 5.1.1(i) "All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app in an easily accessible manner" | Publish the privacy page. Add one `Link("Privacy Policy", destination:)` row to the Feedback card in Settings (SwiftUI `Link` goes through LaunchServices, sandbox-safe, same as the mailto row at line 244) and one small `Link` under the sign-in buttons. The policy text must name Google/Firebase as a processor and say how to request deletion (5.1.1(i) bullets). | S code · page must exist |
| R3 | **No account deletion.** The app creates accounts (Apple + Google via Firebase) and writes `users/{uid}` and `complaints` docs, but the only account control is Sign out. `grep -rn "delete(" OneWord/` finds no `User.delete`. | [ProfileView.swift:400](../../OneWord/Views/ProfileView.swift#L400) (only Sign out), [AuthViewModel.swift:252-274](../../OneWord/ViewModels/AuthViewModel.swift#L252), [AuthViewModel.swift:320-348](../../OneWord/ViewModels/AuthViewModel.swift#L320) (the record that must go) | 5.1.1(v) "If your app supports account creation, you must also offer account deletion within the app." Apple's account-deletion page adds: delete the whole record and associated data; Sign in with Apple apps must revoke the user's tokens. | `AuthViewModel.deleteAccount()`: (1) if the provider is `apple.com`, run the Apple sheet again to get `authorizationCode`, then `Auth.auth().revokeToken(withAuthorizationCode:)`; (2) `try await user.delete()`, on `requiresRecentLogin` re-authenticate with the same provider and retry; (3) `GIDSignIn.sharedInstance.disconnect()`; (4) `signOut()` and `removeObject` the two `profileJoined*` keys. Server side, the laziest route is the Firebase **Delete User Data** extension configured with path `users/{UID}` and search field `userID` on `complaints`, which needs no client Firestore code and no rule change. A red "Delete account" row goes under Sign out in `ProfileView.footer`, behind a confirmation `.alert`. | M |

### 3c. Fix before submit

| # | what | file:line | guideline | smallest fix | effort |
|---|---|---|---|---|---|
| F1 | **Export-compliance prompt on every build.** `ITSAppUsesNonExemptEncryption` is not set (not in either plist, not in `project.pbxproj`). All network traffic is HTTPS (Firebase Auth, two Firestore REST POSTs, the account photo), which is exempt. Without the key App Store Connect asks the encryption questions on every upload. | [OneWord/Info.plist:4](../../OneWord/Info.plist#L4) | ASC export compliance | Add `<key>ITSAppUsesNonExemptEncryption</key><false/>` to the hand-written `OneWord/Info.plist` (it is merged with the generated one; verified no key collisions in the archived plist). | S |
| F2 | **No `PrivacyInfo.xcprivacy` in the app target.** The app itself calls `UserDefaults` (a required-reason API) in [AppGroup.swift:35](../../OneWord/Shared/AppGroup.swift#L35) and via `@AppStorage` throughout. Every SDK in the bundle ships its own manifest (18 found in the archive, incl. FirebaseAuth 12.18.0, FirebaseCore, GoogleSignIn 9.2.0, GoogleUtilities-UserDefaults, all matching `Package.resolved`). **This is not an upload blocker on macOS:** Apple's required-reason enforcement (ITMS-91053, since 2024-05-01) covers iOS/iPadOS/tvOS/visionOS/watchOS uploads, not Mac App Store uploads — see sources at the end. The brief's ground truth is wrong on this one point. It is still five minutes of insurance against Apple widening the scope. | app target (file absent) | Privacy manifest policy | Add `OneWord/PrivacyInfo.xcprivacy` (it joins the target automatically) declaring `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`, `NSPrivacyTracking = false`, and the collected types from F5. | S |
| F3 | **Firestore POSTs have no explicit timeout.** Both use `URLSession.shared` (60 s request timeout). Error handling is correct: the feedback sheet keeps the draft and offers the email address, the join-date write is silently retried next launch. But on a connected-yet-unreachable network the Send button spins for up to a minute. | [FeedbackViewModel.swift:126-146](../../OneWord/ViewModels/FeedbackViewModel.swift#L126), [AuthViewModel.swift:326-338](../../OneWord/ViewModels/AuthViewModel.swift#L326) | 2.1 | One line in each: `request.timeoutInterval = 15`. | S |
| F4 | **Firestore security rules are not in the repo.** Both POSTs do send the Firebase ID token as `Bearer` ([AuthViewModel.swift:336-337](../../OneWord/ViewModels/AuthViewModel.swift#L336), [FeedbackViewModel.swift:144-145](../../OneWord/ViewModels/FeedbackViewModel.swift#L144)), so the rules **can** require `request.auth != null` — but whether they do is invisible from here. If the project is still on test-mode rules, `users` and `complaints` are world-readable/writable. | Firebase console | 5.1.2 | Rules: `users/{uid}`: create/read/delete only when `request.auth.uid == uid`; `complaints/{id}`: create only when `request.auth.uid == request.resource.data.userID`, no client read. Commit a `firestore.rules` file so the next audit can see it. | S |
| F5 | **App Privacy label.** Fill it as: **Name**, **Email Address**, **User ID** (all linked to identity, App Functionality), **Other User Content** = the feedback text (linked, App Functionality), and **Other Diagnostic Data** (not linked, Analytics) because FirebaseAuth's own manifest declares it. Join date and `sentAt` ride under User ID / User Content. No tracking, no third-party advertising. Purchase state stays on-device (StoreKit), so not collected. GoogleSignIn's manifest also declares Phone Number — the app never requests it; declare only what reaches your Firestore. | [FeedbackViewModel.swift:129-139](../../OneWord/ViewModels/FeedbackViewModel.swift#L129), [AuthViewModel.swift:329-331](../../OneWord/ViewModels/AuthViewModel.swift#L329) | 5.1.2, ASC App Privacy | Enter the above in App Store Connect. | S |
| F6 | **Google API key ships in the bundle.** Normal for Firebase, but unrestricted it can be lifted from `Contents/Resources/GoogleService-Info.plist` and used against your quota. | `OneWord/GoogleService-Info.plist` (`API_KEY`) | hygiene | In Google Cloud → Credentials, restrict the key to application `com.hariom.swift.oneword` (Firebase sends the bundle id as `X-Ios-Bundle-Identifier` on macOS too) and to the Identity Toolkit + Token Service APIs. | S |
| F7 | **Stale docs.** `00_Context/` is the kept-current set and it still describes a no-network, no-account, four-dictionary app. Lines to update: [CLAUDE.md:3](../../CLAUDE.md#L3) "no dependencies, no network"; [PROJECT_CONTEXT.md:19](../00_Context/PROJECT_CONTEXT.md#L19) bundle id `MacBee`; [:20](../00_Context/PROJECT_CONTEXT.md#L20) "Min version TBD" (it is 14.0); [:31-33](../00_Context/PROJECT_CONTEXT.md#L31) four dictionaries incl. a Medical book that no longer exists (there are eight + Bookmarks); [:41](../00_Context/PROJECT_CONTEXT.md#L41) widget bundle id `…MacBee.MacBeeWidget`; [:64-65](../00_Context/PROJECT_CONTEXT.md#L64) "Not doing: Accounts"; [ARCHITECTURE.md:12-27](../00_Context/ARCHITECTURE.md#L12) layer diagram (no Auth/Premium/Feedback); [:37-41](../00_Context/ARCHITECTURE.md#L37) view-model list; [:155-156](../00_Context/ARCHITECTURE.md#L155) layout omits `AuthViewModel`, `FeedbackViewModel`, and the rule that Firebase-importing view models are app-only; [REPO_MAP.md:21-27](../00_Context/REPO_MAP.md#L21) table has no row for `Info.plist`, `GoogleService-Info.plist`, `OneWord.entitlements`, `Fonts/`, the two audio files. Also [Docs/README.md:90](../README.md#L90) and [:110](../README.md#L110) say Firebase auth and Feedback are "planned, not built" — both are shipped. | as listed | — | Edit those lines. Leave `01`–`06` alone per the README rule. | S |

### Checks that passed (one line each)

- **App icon set** — all 10 files match their declared pixel size; `icon-mac-512x512 1.png` is 512×512, which is exactly what 256×256@2x needs. 1024 present.
- **Info.plist** — `CFBundleURLSchemes[0]` equals `REVERSED_CLIENT_ID` verbatim; `GoogleService-Info.plist` `BUNDLE_ID` = `com.hariom.swift.oneword`; `LSApplicationCategoryType` = education; `NSPortName` "One Word" = `CFBundleExecutable`; hand-written keys (`ATSApplicationFontsPath`, `NSServices`, `CFBundleURLTypes`) do not collide with generated ones. The generated plist carries inert iOS keys (`UILaunchScreen`, orientations) from `INFOPLIST_KEY_UI*` in `project.pbxproj:540-544` — harmless on macOS.
- **Sandbox** — everything stays inside the container or goes through LaunchServices/system APIs: `NSWorkspace.open(mailto)` ([SettingsView.swift:244](../../OneWord/Views/SettingsView.swift#L244)), Services provider ([WordCapture.swift:59-81](../../OneWord/WordCapture.swift#L59)), `NSSound` from the bundle ([DictionaryPicker.swift:17](../../OneWord/Views/DictionaryPicker.swift#L17), [SentenceView.swift:18](../../OneWord/Views/SentenceView.swift#L18)), `AVSpeechSynthesizer` ([WordDetail.swift:17](../../OneWord/Views/WordDetail.swift#L17)), `DCSCopyTextDefinition` ([SavedWords.swift:141](../../OneWord/Shared/SavedWords.swift#L141)), fonts via `ATSApplicationFontsPath`, `AsyncImage` for the account photo (covered by `network.client`). No `NSOpenPanel`, no paths outside the container. The `URL.cachesDirectory` write is `#if DEBUG` only.
- **Widget entitlements** — it reads the App Group and its own bundle, writes one integer/string to the group on refresh ([RefreshWordIntent.swift:16](../../OneWordWidget/RefreshWordIntent.swift#L16)); no network, no keychain, no Apple sign-in. Sandbox + app group is all it needs.
- **Entitlements in the archive** — app: sandbox, app group `LAP54KU2SV.group…`, `network.client`, keychain group `LAP54KU2SV.com.hariom.swift.oneword`, `applesignin`; widget: sandbox + app group. A successful automatic-signing archive means the App ID already carries App Groups, Keychain Sharing and Sign in with Apple.
- **3.1.1 / 3.1.2** — `OneWord.storekit:26-28` is one **NonConsumable** at 9.99, so no subscription disclosures apply. Price is always Apple's `displayPrice` ([PremiumBar.swift:87](../../OneWord/Views/PremiumBar.swift#L87), [PremiumView.swift:202](../../OneWord/Views/PremiumView.swift#L202)). "Restore Purchase" is reachable from Settings → Premium → `PremiumBar` ([SettingsView.swift:65](../../OneWord/Views/SettingsView.swift#L65) → [PremiumBar.swift:54](../../OneWord/Views/PremiumBar.swift#L54)) and on the plans pane ([PremiumView.swift:223](../../OneWord/Views/PremiumView.swift#L223)); it calls `AppStore.sync()` then re-reads entitlements. Entitlement is re-checked on every launch ([OneWordApp.swift:45](../../OneWord/OneWordApp.swift#L45) → `load()` → `refresh()` over `Transaction.currentEntitlements`) and on every `Transaction.updates` event ([PremiumViewModel.swift:37-42](../../OneWord/ViewModels/PremiumViewModel.swift#L37)). A refund/revocation (`revocationDate != nil`, line 71) flips the flag and, at most, moves a locked dictionary pick back to Everyday English and clears the refresh offset/pin ([Premium.swift:41-48](../../OneWord/Shared/Premium.swift#L41)); `savedWords` and `learnedWords` in the App Group are never touched. `.pending` (Ask to Buy) and `.userCancelled` are handled; unverified transactions are not finished.
- **4.8** — Sign in with Apple is offered first and at the same size as Google ([SignInView.swift:40-48](../../OneWord/Views/SignInView.swift#L40)). The custom button uses the Apple logo and the approved title. Profile has no second sign-in surface.
- **2.1 offline** — launch never waits on the network: `restore()` is a keychain listener ([AuthViewModel.swift:151-162](../../OneWord/ViewModels/AuthViewModel.swift#L151)), `Product.products` failure becomes `storeUnavailable` with a Try Again button. Google and Apple sign-in errors are caught and shown; cancels are swallowed ([AuthViewModel.swift:191-196](../../OneWord/ViewModels/AuthViewModel.swift#L191), [226-237](../../OneWord/ViewModels/AuthViewModel.swift#L226)). No hang, no crash; only the timeout in F3.
- **First-launch crash risks** — `FirebaseApp.configure()` finds its plist in the archive; `CLIENT_ID` present so `GIDConfiguration` is set ([WordCapture.swift:46-53](../../OneWord/WordCapture.swift#L46)); URL scheme registered so `GIDSignIn` will not throw; fonts are found; the widget with empty defaults resolves `dictionaryID` to `"words"` ([AppGroup.swift:40-42](../../OneWord/Shared/AppGroup.swift#L40)), an empty saved list to the placeholder ([WordProvider.swift:66-71](../../OneWord/Shared/WordProvider.swift#L66)), and `premiumUnlocked` to locked. Debug bypass (`-debugSkipAuth`, "Skip sign-in") is compiled out of Release.
- **Data loss** — `SavedWords.all` and `LearnedWords` setters refuse to write on a failed encode rather than wiping the key; sign-out clears only the Firebase/Google sessions.

## 4. Confirm outside the repo

**Developer portal**
- [ ] App ID `com.hariom.swift.oneword` (macOS): App Groups, Sign in with Apple, In-App Purchase enabled; Keychain Sharing follows automatically. The archive proves the first two.
- [ ] App ID `com.hariom.swift.oneword.OneWordWidget`: App Groups.
- [ ] App Group `LAP54KU2SV.group.com.hariom.swift.oneword` registered (it is, or the archive would have failed).
- [ ] "Mac App Distribution" **and** "Mac Installer Distribution" certificates exist for team `LAP54KU2SV` — the archive was signed with an Apple Development identity; App Store export needs both.
- [ ] A Sign in with Apple **key** (.p8) created — needed by Firebase for token revocation (R3). A Services ID is **not** needed for native macOS sign-in.

**App Store Connect**
- [ ] App record exists as **"One Word: Daily Vocabulary"** (plain "One Word" is taken; bundle name stays "One Word").
- [ ] **Paid Apps agreement** signed and banking/tax complete — otherwise `Product.products` returns nothing in review and the reviewer sees "The App Store isn't reachable", a 2.1 rejection.
- [ ] IAP `com.hariom.swift.oneword.premium` created as **Non-Consumable**, price set, localized name/description, review screenshot, status "Ready to Submit", and **attached to the 1.0 version**.
- [ ] Privacy policy URL (live page) and Support URL.
- [ ] App Privacy label per F5. Age rating. Export compliance (F1 makes it automatic).
- [ ] macOS screenshots at an accepted size (1280×800, 1440×900, 2560×1600 or 2880×1800).
- [ ] Review notes: how to reach the widget (Edit Widgets ▸ "Word of the Day"), the Services shortcut, and — while R1 stands — a Google test account with a password, since neither provider offers one otherwise.
- [ ] Sandbox test: purchase, restore, refund via a Sandbox Apple Account on a clean user.

**Firebase / Google Cloud**
- [ ] Auth providers: Apple (enabled per README) with Team ID + Key ID + private key filled in for revocation; Google.
- [ ] Firestore rules per F4; `firestore.rules` committed.
- [ ] Delete User Data extension (or equivalent) if R3 takes that route.
- [ ] API key restrictions per F6.

## 5. Suggested fix order

1. **R1 — drop the login wall.** Largest review risk, and it removes the demo-account problem in review notes. Half a day.
2. **R2 — publish the privacy page and link it** in Settings and (until R1 lands) under the sign-in buttons. The URL is also a hard metadata requirement, so the record cannot be submitted without it.
3. **R3 — account deletion** with Apple token revocation; configure the Firebase Apple provider's key at the same time.
4. **F1 + F2 + F3** — three small file edits, one sitting.
5. **App Store Connect**: Paid Apps agreement, IAP product attached to the version, App Privacy (F5), screenshots, review notes.
6. **F4, F6, F7** — rules, key restriction, docs. None gate the upload; all gate the next audit being short.

Then archive → Distribute → App Store Connect → Upload, and run the sandbox purchase/restore/refund pass on the TestFlight build.

---

*Sources for F2 (macOS scope of required-reason enforcement): [avanderlee.com — ITMS-91053](https://www.avanderlee.com/xcode/missing-api-declaration-required-reason-itms-91053/), [apps4world — ITMS-91053](https://apps4world.com/privacy-details-ITMS-91053-tutorial.html), [Apple Developer Forums thread 751216](https://developer.apple.com/forums/thread/751216). Guideline quotes from [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) and [Offering account deletion in your app](https://developer.apple.com/support/offering-account-deletion-in-your-app/).*
