# iPhone: implementation plan

> Written 2026-10-03 by `/plan` (interactive), against `main` at `1a53942`. No upstream brainstorm or strategy doc exists for this change; it was planned from the request and the code, which is weaker than planning from a committed strategy. Two operator decisions were made live in the session and are recorded in §9.

## 1. Header

**The change.** One Word, the macOS app and its WidgetKit widget, also builds, runs and ships on iPhone (and, because it costs nothing extra, iPad) from the same two targets, the same bundle id and the same App Store record.

**Files read for this plan** (line ranges where partial):
- Project: `OneWord.xcodeproj/project.pbxproj` (build settings `:350-600`, frameworks phase `:108-125`, packages `:631-666`, synchronized group `:89-106`), both `.entitlements`, both `Info.plist`, both `.xcscheme` names, `OneWord/Assets.xcassets/AppIcon.appiconset/Contents.json`, `OneWord/Fonts/`.
- App root: `OneWordApp.swift` 1-54 · `WordCapture.swift` 1-165.
- Views: `RootView.swift` 1-350 · `PaneHeader.swift` 1-154 · `HomeView.swift` 20-66 · `HistoryView.swift` 25-80 · `WordListView.swift` 1-60, 110-150 · `LearnedListView.swift` 120-180 (grep) · `SettingsView.swift` 185-215, 313-345 · `SignInView.swift` 60-118 · `FeedbackView.swift` 25-40 · `DictionaryPicker.swift` 10-30, 85-160, 185-196 · `SentenceView.swift` 10-30 · `PremiumView.swift` 120-150 (+ structure grep) · `ProfileView.swift` 1-40, 330-410 (grep) · `MonthCalendar.swift` :26 · `WordDetail.swift` (grep).
- View models: `AuthViewModel.swift` 1-120, 160-200, 350-400 (grep) · `PremiumViewModel.swift` (imports) · `FeedbackViewModel.swift` 25-60.
- Shared and Models: `AppGroup.swift` 1-48 · `Premium.swift` 1-49 · `Theme.swift` 1-172 · `DoodleTheme.swift` 1-60, :107-119 · `SavedWords.swift` :12-14 · import lines of every other file.
- Widget: all five files in full.
- Tools and docs: `tools/check_words.sh`, the `swiftc` lines of the other five gates, `CLAUDE.md`, `Docs/00_Context/*`, `Docs/README.md`, `Docs/06_Misc/APP_STORE_READINESS_AUDIT.md` (F2).

**Detected stack**

| | Detected | Evidence |
|---|---|---|
| Build | One `OneWord.xcodeproj`, two native targets: `OneWord` (application) and `OneWordWidget` (app-extension). Both `SDKROOT = macosx`, `MACOSX_DEPLOYMENT_TARGET = 14.0`. The app already has `TARGETED_DEVICE_FAMILY = "1,2"` and the `INFOPLIST_KEY_UI*` iOS keys, left over from the original iOS template. | `project.pbxproj:369,462,519,540-544,558` |
| File membership | `OneWord/` is a file-system-synchronized group (new files join the app target by path). The widget target lists its five files and the seven `Shared/` files by explicit `PBXFileReference`. | `project.pbxproj:97-106`, `:80-86` |
| Widget linking | The widget's Frameworks phase links `Cocoa.framework` from `MacOSX15.0.sdk` by path. | `project.pbxproj:67,113` |
| Toolchain | Xcode 27.0 (27A266a); iOS SDK 27.0 present. | `xcodebuild -version`, `xcrun --sdk iphoneos --show-sdk-version` |
| Language and concurrency | Swift 5 mode. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on both targets; the app adds `SWIFT_APPROACHABLE_CONCURRENCY` and `MEMBER_IMPORT_VISIBILITY`. Types the widget reads off-main are marked `nonisolated` by hand. | `project.pbxproj:371,553-556`; `AppGroup.swift:14`, `Premium.swift:17` |
| UI | SwiftUI only. One `WindowGroup` with `.defaultSize(1000×680)` and `.windowStyle(.hiddenTitleBar)`; `NavigationSplitView` shell; every pane draws its own `PaneHeader` in a top `safeAreaInset` and ignores the container's top safe area. | `OneWordApp.swift:35-52`, `RootView.swift:113-130`, `PaneHeader.swift:25-32` |
| Architecture | MVVM. `@Observable` view models import `Observation` only, except `AuthViewModel` (AppKit, AuthenticationServices, Firebase, GoogleSignIn) and `PremiumViewModel` (StoreKit). | `WordViewModel.swift`, `AuthViewModel.swift:24-32`, `PremiumViewModel.swift:13-15` |
| AppKit surface | Eleven files name AppKit or a macOS-only SwiftUI API. Listed in full in §3. Nothing in `Shared/` or `Models/` does. | `grep -rn 'import AppKit\|NS[A-Z]'` |
| Dependencies | SPM: `firebase-ios-sdk` 12.18 (FirebaseCore, FirebaseAuth) and `GoogleSignIn-iOS` 9.2. Both ship iOS first; macOS is their secondary platform. | `project.pbxproj:632-645` |
| Persistence | `UserDefaults` (standard and the App Group suite), bundled JSON, a cache file for the demo avatar. No database. | `AppGroup.swift:35`, `AuthViewModel.swift:88-98` |
| Testing | No test target. Verification is `xcodebuild` plus six `tools/check_*.sh` gates that compile `Shared/`, `Models/` and one view model with bare `swiftc`, never a `Views/` file and never AppKit. | `tools/check_*.sh` compile lines; `CLAUDE.md` |
| Entitlements | App: sandbox, App Group `LAP54KU2SV.group.com.hariom.swift.oneword`, network client, keychain group, Sign in with Apple. Widget: sandbox + App Group. The App Group id is team-prefixed on purpose (see `AppGroup.swift:19-27`). | both `.entitlements` |

## 2. Scope and outcome

**Done when:** `xcodebuild -scheme OneWord -destination 'generic/platform=iOS Simulator' build` is green alongside the existing macOS build and all six gates; the app launches on an iPhone simulator, signs in, shows today's word, browses, searches, bookmarks, switches dictionaries, buys Premium through the local StoreKit file, and the widget appears in the iPhone widget gallery in all three sizes and follows the app's dictionary pick. The Mac app's behaviour is unchanged.

**In scope:** every pane the Mac has, the widget, sign-in, Premium, themes, the doodle fonts, the sounds. iPad is in scope only as "the Mac layout, unchanged, on a regular-width iPad", with no iPad-specific work.

**Out of scope (deferred, see §9):** word capture from other apps (the Mac's NSServices entry and HUD), lock-screen and StandBy widget families, iPad-specific layouts, onboarding (its own plan assumes the 1000×680 window and should be re-planned after this lands), a test target.

**Scope shape: program.** Five independently mergeable units. This document is the spine: it holds the invariants, the file-by-file platform audit, the dependency order, and fully grounds **Leaf 1**. Leaves 2 to 5 are listed with their touchpoints as known today; each gets its own `/plan` run right before it is built, because Leaf 1 changes the files they would otherwise cite.

| Leaf | Owns | Depends on | Next-to-build when |
|---|---|---|---|
| **L1 — the iOS build compiles** | project settings, entitlements split, App Group id, `#if os` gating of the eleven files, cross-platform replacements, Info.plist fonts, icon, privacy manifest, widget link fix | nothing | now |
| **L2 — the iPhone shell** | `RootView` compact `TabView`, `PaneHeader` on iOS, Profile rows for Practice and Plan | L1 | L1 is green on both platforms |
| **L3 — compact layouts** | History, the two list rows, the Feedback sheet, the Settings popover, the Premium columns, a shelf check | L2 | L2 shows every pane on a 390pt screen |
| **L4 — sign-in and purchase live on device** | Firebase/Google/Apple presentation on iOS, `onOpenURL`, console-side checks, StoreKit on the simulator | L1 (compiles there), L2 (to reach the screens) | a device or simulator can run the app |
| **L5 — the widget on iPhone** | gallery check, App Group sharing with the `group.` id, `Follow App Settings`, reload on pick | L1 | L1 is green |

**Invariants (stated once, here):**
1. **No new target** for the app or widget. The same `OneWord` and `OneWordWidget` targets build for `macosx`, `iphoneos` and `iphonesimulator`.
2. **`Shared/` and `Models/` stay AppKit- and UIKit-free**, because the widget compiles them and the gates compile them with bare `swiftc` on the Mac SDK. Any `#if os(iOS)` branch added there must still compile under `swiftc` on macOS with no extra flags (the gates are the check).
3. **Prefer the cross-platform SwiftUI or Foundation API over a pair of `#if` branches.** `openURL`, `.sensoryFeedback`, `AVAudioPlayer`, `CGImage`, `Image(decorative:)` each replace an AppKit call and its would-be UIKit twin. `#if os(macOS)` is reserved for things with no iOS meaning: NSServices, the HUD, the window style, the window drag, the sidebar toggle's folded padding.
4. **The Mac app does not change behaviour.** Every edit is either additive on iOS or a like-for-like replacement whose Mac result is checked by eye.
5. **Platform-conditional build settings use `[sdk=…]` conditions on the existing targets**, never a duplicated configuration or xcconfig.
6. **Bundle id stays `com.hariom.swift.oneword`**, so iOS joins the existing App Store record "One Word: Daily Vocabulary" as a universal purchase and the one `GoogleService-Info.plist` keeps serving both platforms.

## 3. Architecture fit

Nothing new is a layer. iOS work lands in the files that already own the behaviour; the one new view (`RootView`'s compact shell) stays inside `RootView.swift`, and the one new file is a privacy manifest. Where a view picks a layout by width, it reads `horizontalSizeClass` under `#if os(iOS)` (the environment key is not available on native macOS), so the Mac path is untouched by construction.

**The complete macOS-only inventory, and what each becomes:**

| File | macOS-only thing | Becomes | Rung |
|---|---|---|---|
| `OneWordApp.swift:14` | `@NSApplicationDelegateAdaptor(AppDelegate.self)` | wrapped in `#if os(macOS)`; Firebase configuration moves to `OneWordApp.init()` so both platforms configure before any scene (today it lives in `AppDelegate.init`, `WordCapture.swift:30-33`) | gate + move |
| `OneWordApp.swift:49-52` | `.defaultSize`, `.windowStyle(.hiddenTitleBar)` | `#if os(macOS)` around the two scene modifiers (postfix `#if` in result builders, SE-0308) | gate |
| `WordCapture.swift` (whole file) | NSServices provider, `NSPanel` HUD, `NSHostingView` | whole file under `#if os(macOS)`; `AppDelegate` keeps only `applicationDidFinishLaunching` | gate (capture deferred, §9) |
| `AuthViewModel.swift:27,169,201,360-400` | `NSWindow` as presenting anchor; `NSImage`/`NSBitmapImageRep` for the debug avatar | a `PresentationAnchor` typealias (`NSWindow` / `UIWindow`), `GIDSignIn.signIn(withPresenting:)` takes the window on macOS and the window's `rootViewController` on iOS; debug avatar PNG via `UIImage(named:)?.pngData()` under `#else` | typealias + 2 gates |
| `SignInView.swift:16,77,85` | `NSApp.keyWindow` | an `@Environment`-free window read per platform: `NSApp.keyWindow` on macOS, the first `UIWindowScene`'s key window on iOS, behind one `private static func anchor() -> PresentationAnchor?` in `SignInView` | gate |
| `SettingsView.swift:17,244` | `NSWorkspace.shared.open(url)` | `@Environment(\.openURL) private var openURL`; `openURL(url) { accepted in … }` keeps the failure branch | cross-platform |
| `DictionaryPicker.swift:11,18,192` | `NSSound`, `NSHapticFeedbackManager` | `AVAudioPlayer(contentsOf:)` (import AVFoundation, drop AppKit); `.sensoryFeedback(.error, trigger: shakes)` on the shelf replaces the haptic call (macOS 14 / iOS 17, both in range) | cross-platform |
| `SentenceView.swift:11,19` | `NSSound` | `AVAudioPlayer(contentsOf:)`; `prepareToPlay()` once at load keeps the "first roll is instant" property `byReference:` gave it | cross-platform |
| `PremiumView.swift:17,128-146` | `NSImage` cover cache and downsample | cache `[String: CGImage]`; load the source `CGImage` with one `#if` (`NSImage(named:)?.cgImage(forProposedRect:…)` / `UIImage(named:)?.cgImage`), draw into the same `CGContext`, show with `Image(decorative: cgImage, scale: scale)` | cross-platform + 1 gate |
| `PaneHeader.swift:28,53-59,85,113-118,151` | `.ignoresSafeArea(.container, edges: .top)`, sidebar toggle's folded padding (84pt for traffic lights), `WindowDragGesture`, `.onExitCommand` | see Leaf 2; the drag area and `.onExitCommand` are `#if os(macOS)` in Leaf 1 so it compiles | gate |
| `RootView.swift:190` | `.toolbar(removing: .sidebarToggle)` | available on iOS 17; no change | none |
| `AppGroup.swift:28` | team-prefixed App Group id | `#if os(iOS)` → `"group.com.hariom.swift.oneword"`; iOS rejects an App Group that does not start with `group.` **[Unverified against a provisioning run; this is Apple's documented rule]** | gate |

`SavedWords.swift:13-15` already guards its `CoreServices` import and use (`:139`) with `#if canImport(CoreServices)`, so it compiles either way on iOS.

## 4. Implementation steps — Leaf 1, fully grounded

Each step compiles on its own against the macOS destination; the iOS destination turns green at step 1.8. Order is reversible-first: every project edit before step 1.8 can be reverted with `git checkout -- OneWord.xcodeproj` and nothing else moves.

### 1.1 Platforms and deployment targets (project file)

MODIFIED `OneWord.xcodeproj/project.pbxproj`, all four target configuration blocks (widget Debug `:377`, widget Release `:350`, app Debug `:525`, app Release `:562`):

```
SDKROOT = auto;
SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";
IPHONEOS_DEPLOYMENT_TARGET = 17.0;
TARGETED_DEVICE_FAMILY = "1,2";          // add to the widget blocks; app already has it
"LD_RUNPATH_SEARCH_PATHS[sdk=iphone*]" = "$(inherited) @executable_path/Frameworks";                       // app
"LD_RUNPATH_SEARCH_PATHS[sdk=iphone*]" = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";  // widget
```

Keep the existing `MACOSX_DEPLOYMENT_TARGET = 14.0` and the existing unconditional `LD_RUNPATH_SEARCH_PATHS` as the macOS values. iOS 17 is forced by `@Observable` (`WordViewModel.swift`) and `.sensoryFeedback`; it matches the macOS 14 floor in age.

Remove the widget's `Cocoa.framework` link: delete the `PBXBuildFile` at `:13`, the `PBXFileReference` at `:67`, its entry in the Frameworks phase at `:113`, and the "OS X" group at `:131-135`. WidgetKit and SwiftUI pull in what the widget needs on both platforms.

**Verify:** `xcodebuild -scheme OneWord -destination 'platform=macOS' build` still green (nothing above changes the Mac build). `xcodebuild -scheme OneWord -destination 'generic/platform=iOS Simulator' build` now fails on Swift errors in the eleven files, not on project errors. If it fails on signing or SDK, stop and fix here.

### 1.2 Entitlements split

NEW `OneWord/OneWord-iOS.entitlements` (joins the target by the synchronized group; it is referenced by setting, not compiled):

```xml
com.apple.security.application-groups = [ group.com.hariom.swift.oneword ]
keychain-access-groups = [ $(AppIdentifierPrefix)com.hariom.swift.oneword ]
com.apple.developer.applesignin = [ Default ]
```

No sandbox key (macOS-only), no `network.client` (macOS sandbox only). NEW `OneWordWidget/OneWordWidget-iOS.entitlements` with the App Group only. The widget folder is not synchronized, but an entitlements file needs no target membership, only the path below.

MODIFIED `project.pbxproj`, same four blocks:

```
"CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]" = OneWord/OneWord-iOS.entitlements;
"CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]" = OneWord/OneWord-iOS.entitlements;
```

(and the widget's two paths). The existing unconditional `CODE_SIGN_ENTITLEMENTS` stays as the macOS value.

**Verify:** the iOS build no longer reports an entitlement the profile lacks. **Risk, see §10:** if automatic signing still complains about `app-sandbox`, the conditional setting is not being honoured; fall back to one entitlements file per platform via `[sdk=macosx*]` on the Mac path too.

### 1.3 App Group id per platform

MODIFIED `OneWord/Shared/AppGroup.swift:28`:

```swift
#if os(iOS)
static let id = "group.com.hariom.swift.oneword"
#else
static let id = "LAP54KU2SV.group.com.hariom.swift.oneword"
#endif
```

Keep the existing comment; add two lines saying iOS requires the `group.` prefix and that the two containers never meet (no cross-device sync exists). `nonisolated enum`, Foundation only, so invariant 2 holds. Register the `group.com.hariom.swift.oneword` App Group on the App ID in the developer portal; with `REGISTER_APP_GROUPS = YES` (`:368`) Xcode should do this on the first iOS build **[Unverified]**.

**Verify:** `bash tools/check_words.sh` and `check_capture.sh`, `check_premium.sh`, `check_learned.sh` (all compile `AppGroup.swift`) stay green: `swiftc` on the Mac takes the `#else` branch.

### 1.4 App entry and capture

MODIFIED `OneWord/OneWordApp.swift`:
- `import FirebaseCore` and `import GoogleSignIn`; add `init() { Self.configureFirebase() }` with the body of `AppDelegate.configureFirebase()` (`WordCapture.swift:44-51`) moved here verbatim. `@MainActor` by target default; `FirebaseApp.configure()` is main-thread safe and is called before any scene on both platforms.
- `#if os(macOS)` around the `@NSApplicationDelegateAdaptor` property (`:14`).
- `#if os(macOS)` around `.defaultSize` and `.windowStyle` (`:49-52`).

MODIFIED `OneWord/WordCapture.swift`: `#if os(macOS)` as the first line after the header comment and `#endif` at the end. Delete `AppDelegate.init` and `configureFirebase` (moved). The file header already explains it is AppKit glue; add one sentence that iPhone has no Services menu and capture there is a Share Extension someday.

**Verify:** Mac build green; sign-in still restores the keychain session on launch (the reason `configureFirebase` ran in `init`, `WordCapture.swift:26-29`, is preserved because `App.init` runs before any scene too).

### 1.5 Sign-in presentation seam

MODIFIED `OneWord/ViewModels/AuthViewModel.swift`:
- Imports: `#if canImport(AppKit) import AppKit #else import UIKit #endif`.
- Add at file scope: `#if os(macOS) typealias PresentationAnchor = NSWindow #else typealias PresentationAnchor = UIWindow #endif`. `ASPresentationAnchor` is already this typealias in AuthenticationServices; naming our own keeps `AppleAuthorization.presentationAnchor(for:)` (`:399`) returning `window` unchanged.
- `signIn(presenting:)` and `signInWithApple(presenting:)` take `PresentationAnchor`. In `signIn`, the GoogleSignIn call becomes `#if os(macOS) signIn(withPresenting: window) #else signIn(withPresenting: window.rootViewController!) #endif` — guard the optional instead of forcing it, surfacing "No window to present from" through the existing `error` string.
- `AppleAuthorization` stores `PresentationAnchor`.
- Debug avatar (`:94-95`): `#if os(macOS)` existing TIFF→PNG; `#else let png = UIImage(named: "male_profile_icon")?.pngData()`.
- Isolation: unchanged. The class is `@MainActor` by target default; `AppleAuthorization` is `@MainActor` too (its comment at `:352-353` says why). `PresentationAnchor` never crosses an actor boundary.

MODIFIED `OneWord/Views/SignInView.swift`:
- `import AppKit` → `#if canImport(AppKit) … #else import UIKit #endif`.
- `signInButton` action type becomes `(PresentationAnchor) async -> Void`.
- Replace `NSApp.keyWindow` (`:85`) with `Self.anchor()`: on macOS `NSApp.keyWindow`; on iOS `UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.keyWindow`. Single-window on both, as the comment at `:83-84` already relies on.

**Verify:** Mac build green and a real Google and Apple sign-in still work on the Mac (the typealias is `NSWindow` there, so behaviour is identical). iOS behaviour is Leaf 4.

### 1.6 Cross-platform replacements

- MODIFIED `OneWord/Views/SettingsView.swift`: drop `import AppKit` (`:17`) and its comment (`:15-16`); add `@Environment(\.openURL) private var openURL`; `openMail()` (`:244`) becomes `openURL(url) { accepted in if !accepted { /* existing failure branch */ } }`. `OpenURLAction` runs on the main actor; the view is already there.
- MODIFIED `OneWord/Views/DictionaryPicker.swift`: `import AppKit` → `import AVFoundation`; `flipSound` becomes `try? AVAudioPlayer(contentsOf:)` with `prepareToPlay()`; the play site calls `currentTime = 0; play()`. Delete the `NSHapticFeedbackManager` line in `refuse` (`:192`) and add `.sensoryFeedback(.error, trigger: shakes)` on the shelf's `GeometryReader` (any change to the `shakes` dictionary fires it; on a Mac without Force Touch it is silent, as today).
- MODIFIED `OneWord/Views/SentenceView.swift`: same `AVAudioPlayer` swap for `shuffleSound` (`:17-19`); `stop()` keeps the same name.
- MODIFIED `OneWord/Views/PremiumView.swift`: `covers: [String: CGImage]`; `cover(…) -> CGImage?`; the loading guard gets the one `#if`; the call site wraps in `Image(decorative: cg, scale: scale)` (the existing fallback `NSImage(named:)` becomes `Image(name)` on the view side). `import AppKit` (`:17`) becomes the `canImport` pair, needed only for that guard.

**Verify:** Mac build green; by eye on the Mac: the shelf flip still clicks, Practice's roll still shuffles, Premium covers still draw crisp at 1× and 2× (move the window between displays), Settings ▸ Email still opens Mail.

### 1.7 PaneHeader compiles on iOS (behaviour is Leaf 2)

MODIFIED `OneWord/Views/PaneHeader.swift`: `#if os(macOS)` around `WindowDragArea` (`:113-118`) and its `.background { WindowDragArea() }` use (`:85`) — on iOS the background is `EmptyView()`; `#if os(macOS)` around `.onExitCommand` (`:151`). Nothing else yet.

### 1.8 Info.plist, icon, privacy manifest

- MODIFIED `OneWord/Info.plist`: add `UIAppFonts` with the four files in `OneWord/Fonts/` (`PulpenSnowman-Regular.otf`, `PulpenSnowman-Light.otf`, `PlusJakartaSans-Variable.ttf`, `PlusJakartaSans-Italic-Variable.ttf`). `ATSApplicationFontsPath` stays for macOS; iOS ignores it, macOS ignores `UIAppFonts`. The PostScript names `DoodleTheme.swift:107-119` uses are unchanged. `NSServices` is inert on iOS.
- MODIFIED `OneWord/Assets.xcassets/AppIcon.appiconset/Contents.json`: add `{ "idiom": "universal", "platform": "ios", "size": "1024x1024", "filename": "<new>.png" }`. **Asset work:** iOS icons must be opaque and square-cornered; the Mac 1024 has the rounded transparent mask, so export a flattened 1024 from the same source.
- NEW `OneWord/PrivacyInfo.xcprivacy`: `NSPrivacyAccessedAPITypes` = `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`; `NSPrivacyTracking = false`; collected data types per the App Store audit's F5. The audit (`APP_STORE_READINESS_AUDIT.md` F2) established this is optional for a Mac upload and **required for an iOS upload** (ITMS-91053). The widget also reads `UserDefaults`; whether an embedded extension needs its own manifest is **[Unverified]** — if the first iOS upload flags it, add the same file to the widget via an explicit `PBXFileReference` + Resources build phase (the widget folder is not synchronized).

**Verify (Leaf 1 done-when):**

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
for s in check_words check_related check_learned check_capture check_premium check_sentences; do bash tools/$s.sh; done
```

All green. Then one Mac run by eye through the items in 1.4–1.6. The app does not need to be usable on iPhone yet; it needs to launch to `SignInView` without crashing (Firebase configured, fonts registered).

Also MODIFIED `CLAUDE.md` "Verify before saying it's done": add the iOS build line. And `Docs/00_Context/PROJECT_CONTEXT.md` ("Not doing (yet)" loses iOS; platform row gains it) and `REPO_MAP.md` (the two new entitlements files, the privacy manifest) in the same PR, since `00_Context/` is kept current.

## 5. Leaves 2–5 (touchpoints as known today; ground each with its own `/plan` before building)

**L2 — the iPhone shell.** `RootView.swift`: under `#if os(iOS)`, read `@Environment(\.horizontalSizeClass)`; when `.compact`, `shell` returns a `TabView(selection:)` over `Pane.home, .history, .bookmarks, .search, .profile`, each tab a `NavigationStack(path:)` wrapping `detail` for that pane with `.navigationDestination(for: Pane.self)` so the non-tab panes push. `HomeView` sets `pane = .dictionaries` (`HomeView.swift:28`) and `ProfileView` sets `pane = .settings` (`ProfileView.swift:~368`); the compact shell's selection binding intercepts a non-tab value and appends it to the active tab's path instead. The sidebar's bottom strip (account chip, `PlanTag`, feedback button, suggestion card) has no compact home: Profile already has a Settings row (`ProfileView.swift:~365-380`) and Settings already has both feedback buttons (`SettingsView.swift:193-207`); add two rows to Profile in the same idiom, "Practice" (gated like the sidebar's `selection` binding at `RootView.swift:140`) and "Plan" → `.premium`. `PaneHeader.swift`: on compact hide the sidebar toggle, drop the `ignoresSafeArea(.container, edges: .top)` so the strip sits below the status bar, and add `.toolbar(.hidden, for: .navigationBar)` so the stack's own bar does not double it; `HeaderSearchField`'s fixed `width: 240` (`:149`) becomes `maxWidth` on compact. `Pane.launchPane` keeps working for screenshot automation.

**L3 — compact layouts.** `HistoryView.swift:35-40,75`: the 268pt rail beside `WordDetail` becomes a `VStack` in a `ScrollView` on compact; the month picker sheet's `frame(560×520)` (`:186`) is macOS-only, iOS gets `.presentationDetents([.medium, .large])`. `WordListView.swift:19-21,113-145` and `LearnedListView.swift:17-18`: the fixed 240/96/420 columns with 64pt gaps become a two-line row on compact (term + part of speech, then the Hindi line); `SwellingTerm`'s width is the row's. `FeedbackView.swift:35`: `frame(520×430)` macOS-only; `TextEditor` already fills. `SettingsView.swift:326`: the `InfoButton` popover needs `.presentationCompactAdaptation(.popover)` or it becomes a full sheet on iPhone. `PremiumView.swift:48`: `HStack { free; lifetime }` → `VStack` on compact (an `AnyLayout` switch keeps one body). `DictionaryPicker.swift:92-105` already derives every size from the available width; check by eye at 390pt that eight spines plus the front cover still read, and raise `padding` default if not. `MonthCalendar` (7 × 34pt) fits. `WordDetail`, `ProfileView`, `SentenceView`, `SignInView` cap at `maxWidth` and need nothing.

**L4 — sign-in and purchase live.** `OneWordApp.swift`: `.onOpenURL { GIDSignIn.sharedInstance.handle($0) }` on iOS, which GoogleSignIn's iOS flow still documents **[Unverified for 9.2]**; the URL scheme is already in `Info.plist`. Outside the repo: confirm the Firebase "Apple app" record for `com.hariom.swift.oneword` serves iOS (one `GoogleService-Info.plist` covers both since Firebase unified the Apple platforms **[Unverified]**), Sign in with Apple is enabled on the App ID (it is, for the Mac; same App ID), and `StoreKit/OneWord.storekit` is attached to the scheme's Run action for the simulator (it is; the scheme is shared across destinations). Manual matrix: Google, Apple, cancel, sign out, relaunch restores, buy, restore, lose Premium walks the pick back (`Premium.set(unlocked:)`).

**L5 — the widget on iPhone.** Expected to need no code: `WidgetDictionary`, the `AppIntentConfiguration`, `Button(intent:)` and the three system families are all iOS 17 APIs. Check: appears in the gallery; `Follow App Settings` tracks the app's pick through the `group.` container; `RefreshWordIntent` advances; the app's `WidgetCenter.reloadAllTimelines()` calls (`HomeView.swift:56`, `OneWordApp.swift:47`) reach it. Lock-screen families (`.accessoryRectangular`, `.accessoryInline`) are a product call, §9.

## 6. Concurrency, state and memory

- **Isolation map is unchanged.** Both targets keep `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`; every type touched is on the main actor except the `nonisolated` `AppGroup` and `Premium`, which gain only a compile-time `#if`. No new `actor`, no new `Task`.
- **`PresentationAnchor`** (`NSWindow`/`UIWindow`) is read on the main actor in the button action and passed into a `@MainActor` method; it never crosses an isolation boundary, so no `Sendable` question arises. `UIWindow` and `NSWindow` are both main-actor-bound classes; keep it that way (do not stash the anchor in a `Task.detached`).
- **`AVAudioPlayer`** replaces `NSSound` as a `@MainActor private let` at file scope, same lifetime; `AVAudioPlayer` is not `Sendable` and does not need to be.
- **Firebase configure in `App.init`** runs once on the main thread before any `@State` view model is created, preserving the ordering `WordCapture.swift:26-29` fought for. `AuthViewModel.restore()`'s preview guard (`:141-150`) still applies.
- **`.sensoryFeedback(trigger:)`** observes the `shakes` dictionary already in `@State`; no new state.
- **Retain cycles:** none introduced. The `openURL` completion is non-escaping in effect (called synchronously by SwiftUI); the `AVAudioPlayer` has no delegate.
- **`CGImage` cache** in `PremiumView` is a `static var` on the main actor, as the `NSImage` one is today.

## 7. Test plan

No test target exists and this plan does not add one (out of scope; note it as a follow-up). The seams this change touches are mostly untestable view code anyway. What the gates cover: `AppGroup.swift`'s `#if` is compiled by four gates on the macOS branch. What is checked by hand: the Leaf 1 done-when (two builds, six gates, one Mac pass), then per-leaf manual matrices named in §5. One cheap addition worth making in Leaf 1: a `#Preview` for `SignInView` with `.previewDevice("iPhone 16")` is free and shows the first iOS screen without a simulator run.

## 8. Accessibility, localisation and project mechanics

- **Dynamic Type:** every text in the app uses `.system(size:)` or `Font.serif(size)` with fixed points (`Theme.swift:168`, everywhere). On the Mac that was fine; on iPhone it means no Dynamic Type. Not a Leaf 1 blocker. Record it as the first follow-up after L3: swap `.system(size:)` for `.system(size:relativeTo:)` or text styles, one pane at a time.
- **Touch targets:** `HeaderButtonStyle` is 30×28 (`PaneHeader.swift:104`); on iOS raise the minimum to 44×44 under `#if os(iOS)` in L2. `MonthCalendar` cells are 34×30 (`:26`), the same note for L3.
- **VoiceOver:** labels already exist on the shelf, the plan tag, the feedback button and the locked rows; the new Profile rows and tab items need `.accessibilityLabel`s matching `Pane.title`.
- **`.help()` and `.keyboardShortcut`:** compile and are harmless on iPhone; they work on iPad with a pointer or keyboard.
- **Localisation:** no `.xcstrings` exists; nothing changes.
- **Target membership:** the two `-iOS.entitlements` files and `PrivacyInfo.xcprivacy` are the only new files. The manifest joins the app target through the synchronized group; the entitlements files are referenced by build setting only. Nothing moves in `Shared/`, so the widget's explicit references and the gates' paths are untouched.
- **`@available`:** none needed; iOS 17 and macOS 14 cover every API named. The existing `#available(macOS 15)` for `WindowDragGesture` sits inside the new `#if os(macOS)`.
- **Simulator runtime:** `xcrun simctl list runtimes` lists no runtimes on this machine (confirmed at planning time). Install the iOS 27 simulator runtime in Xcode ▸ Settings ▸ Components before Leaf 1's iOS build; `generic/platform=iOS Simulator` needs the SDK only, but Leaf 2 onward needs a booted device.

## 9. Decision forks

Resolved in session (operator):
- **F1 iPhone shell → `TabView` on compact** (Home, History, Bookmarks, Search, Profile). Alternatives rejected: letting `NavigationSplitView` collapse (zero code, but the first screen is a menu, not the word), a Home-first stack with a menu sheet.
- **F2 Capture → deferred.** `WordCapture.swift` is macOS-only. A Share Extension is its own leaf later; the condition that brings it forward is iPhone users asking for "save from Safari".

Defaulted by the plan (operator may flip):
- **F3 iPad: in, with the Mac layout.** Default because `TARGETED_DEVICE_FAMILY = "1,2"` already includes it and the split view works on a regular-width iPad with no work. Flip to iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) if iPad review screenshots or iPad-specific bugs are not worth the time before the first iOS release.
- **F4 Lock-screen widget families: not in L5.** Add `.accessoryRectangular`/`.accessoryInline` when the first iPhone users exist; it is a fourth `switch` case in `WordWidgetView` plus a monochrome treatment.
- **F5 Dynamic Type: after L3, not inside it.** Flip to "inside L3" if App Review or accessibility is a release gate for you.

## 10. Risks and exits

| Risk | Severity / confidence | Leading indicator | Exit |
|---|---|---|---|
| iOS rejects the team-prefixed App Group, or the `group.` id is not provisioned automatically | High / high that the rule exists | signing error naming `application-groups` on the first iOS build | 1.3 already splits the id; if `REGISTER_APP_GROUPS` does not create it, add it by hand in the developer portal |
| `[sdk=…]` conditional `CODE_SIGN_ENTITLEMENTS` ignored by automatic signing | Medium / medium | iOS build complains about `app-sandbox` or `network.client` | condition the macOS path too (`[sdk=macosx*]`) and leave the unconditional setting empty |
| Google sign-in on iOS needs `onOpenURL` or a different presenting type | Medium / medium | tap Google, browser returns, nothing happens | L4 adds the handler; GoogleSignIn 9.x docs are the reference |
| Firebase Apple-app record does not cover iOS | Medium / low | `FirebaseApp.configure()` logs a bundle-id mismatch on iOS | add an iOS app to the Firebase project with the same bundle id and regenerate the plist (the macOS values are the same) |
| The Mac app regresses from a like-for-like swap (sound, haptic, covers, mail) | Medium / low | by-eye pass in 1.6 | each swap is one file; revert the file |
| Privacy manifest incomplete for iOS upload | Low / medium | ITMS-91053 email after upload | add the missing reason code; the widget gets its own manifest if named |
| `horizontalSizeClass` read outside `#if os(iOS)` breaks the Mac build | Low / high | compile error on macOS | the key is iOS-only; keep every read under the guard |

## 11. Sequencing summary and verification

1. 1.1 project platforms + widget Cocoa removal → both builds attempt iOS
2. 1.2 entitlements split → signing passes on iOS
3. 1.3 App Group id → gates still green
4. 1.4 app entry + capture gate → Firebase configures on both; Mac Services still work
5. 1.5 sign-in anchor typealias → Mac sign-in unchanged
6. 1.6 cross-platform swaps → Mac by-eye pass
7. 1.7 PaneHeader gates → iOS compiles
8. 1.8 plist, icon, manifest → iOS launches to SignInView; `00_Context` docs and `CLAUDE.md` updated
9. Then L2 → L3 → L4 and L5 in parallel, each via its own `/plan`.

First reversible move: step 1.1 (project file only). End-to-end confirmation for the program: both `xcodebuild` lines and the six gates green; on an iPhone simulator, sign in with Google, see today's word, switch to Emotions from Home's chip, search "stab", bookmark it, buy Premium from the local StoreKit file, open Practice from Profile, add the medium widget and see it follow the pick; on the Mac, the same pass plus "Save to One Word" from TextEdit.

## 12. Open questions and assumptions

- `[Unverified]` iOS App Groups must begin with `group.` — Apple's rule as documented; the first iOS signing run confirms.
- `[Unverified]` GoogleSignIn 9.2 still needs `handle(url)` on iOS; its README is the source.
- `[Unverified]` One `GoogleService-Info.plist` serves macOS and iOS for the same bundle id in the current Firebase console.
- `[Unverified]` An embedded widget extension is covered by the app's privacy manifest.
- `[Assumption]` The Mac's 1024pt icon source exists in a layered form that can be exported flat for iOS.
- `[Inference]` SE-0308 postfix `#if` works for `Scene` modifiers in `OneWordApp.body` as it does for `View` modifiers; if the compiler objects, wrap the whole `WindowGroup` expression in a computed `Scene` property per platform.
- `[Assumption]` The onboarding plan (`ONBOARDING_PLAN_RESOLVED.md`), designed for 1000×680, is re-planned after L3 rather than built on compact as-is.
