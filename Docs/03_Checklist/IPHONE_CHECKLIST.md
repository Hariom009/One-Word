# iPhone: Leaf 1 build checklist (the iOS build compiles)

> Written 2026-10-03 by `/checklist --report` (the `checklist-writer` subagent) from the resolved plan [IPHONE_PLAN_RESOLVED.md](../02_Plan/Resolved/IPHONE_PLAN_RESOLVED.md). Read-only: nothing was built or run.

## Header

- **Source plan:** [`Docs/02_Plan/Resolved/IPHONE_PLAN_RESOLVED.md`](../02_Plan/Resolved/IPHONE_PLAN_RESOLVED.md) (written 2026-10-03 by `/plan-resolver --report`). It resolves [`Docs/02_Plan/Audit/IPHONE_PLAN_AUDIT.md`](../02_Plan/Audit/IPHONE_PLAN_AUDIT.md) against [`Docs/02_Plan/IPHONE_PLAN.md`](../02_Plan/IPHONE_PLAN.md).
- **Status: audited and resolved.** The path was `/plan` → `/plan-audit` (verdict: fix blockers first) → `/plan-resolver`. All 20 fixable findings are folded into the steps below: B1 is in 1.3 and B2 is in 1.7. Four operator defaults are already applied (Q1, Q2, Q3, M3). The citations were re-grounded on `main` at `1a53942`.
- **Stack:** Xcode 27.0. SDKs iphoneos27.0, iphonesimulator27.0 and macosx27.0. One `OneWord.xcodeproj` with the `OneWord` app and the `OneWordWidget` appex. Swift 5 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and member import visibility on. SPM: firebase-ios-sdk 12.18 and GoogleSignIn-iOS 9.2.0 (resolved). SwiftUI with `@Observable` MVVM. `OneWord/` is a synchronized group; the widget uses explicit file references. There is no test target, so the checks are the six `tools/check_*.sh` gates.
- **Scope:** Leaf 1 in full (steps 1.0–1.10). Leaves 2–5 get a pointer only.
- **Files peeked:** none. The plan gives exact lines for every edit, so no extra reads were needed to size the items. All `file:line` references below are the plan's own and were not re-checked here.
- **Line drift:** steps 1.1 and 1.2 both edit `project.pbxproj`, so its line numbers shift after the first edit. Find blocks by name or ID rather than by the cited line numbers.

## How to use

- `- [ ]` = to do · `- [x]` = done · `blocked-by: <id>` = finish that item first · `DECIDE:` = an operator decision (default already applied) · `⏸` = deferred, deliberately left unchecked.
- **Rule:** don't tick an item until its **done-when** holds.
- **Shorthand.** "Mac build green", "iOS build green" and "gates green" mean these commands, copied from the plan:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
for s in check_words check_related check_learned check_capture check_premium check_sentences; do bash tools/$s.sh; done
```

- Per the plan, **every step must leave the Mac build and the gates green on its own.**
- **Undo point:** until step 1.3 starts, `git checkout -- OneWord.xcodeproj` undoes everything.

---

## Open operator decisions (DECIDE): defaults applied, none blocks Leaf 1

- [ ] **DECIDE: Q1 (how L2 picks the phone shell).**
  - **Default applied:** L2 picks the TabView when `UIDevice.current.userInterfaceIdiom == .phone`, not by size class. A Pro Max in landscape keeps the tabs; iPad Split View keeps the split view.
  - **Alternative:** `horizontalSizeClass == .compact` alone.
  - **Flips if** you want iPad Split View / Slide Over to show the iPhone tabs.
  - **Done-when:** accepted or overridden in the plan's §5 queue before the L2 `/plan` run. It has no Leaf 1 code.
- [ ] **DECIDE: Q2 (audio session category).**
  - **Default applied (in step 1.4c):** `.ambient` for the shelf flip, the roll and pronunciation alike. All three respect the silent switch and mix with the user's music.
  - **Alternative:** `.playback` (or `.playback` + `.spokenAudio`) for pronunciation only, switching the category around `speaker.speak` (`WordDetail.swift:326`).
  - **Flips if** muted iPhones should still say the word aloud.
  - **Done-when:** accepted, or step 1.4c changed to the alternative.
- [ ] **DECIDE: Q3 (Designed-for-iPad on Mac and Vision).**
  - **Default applied (in step 1.1c):** `SUPPORTS_MACCATALYST`, `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD` and `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD` are all `NO`.
  - **Alternative:** leave them on (Xcode's default).
  - **Flips if** you want Vision Pro users to get the iPad build.
  - **Done-when:** accepted, or the three lines removed from step 1.1c.
- [ ] **DECIDE: M3 (copy wording).**
  - **Default applied (in step 1.9):** one platform-neutral string per site ("device", "widget"), shown on both platforms. This is the one stated exception to invariant 4.
  - **Alternative:** per-platform strings under `#if os(macOS)` that keep the Mac wording exactly.
  - **Flips if** you want zero visible change on the Mac.
  - **Done-when:** accepted, or step 1.9 rewritten as `#if os` strings.

Locked by the operator and not reopened: **F1** the iPhone shell is a TabView; **F2** capture is deferred. Defaults the operator may still flip: **F3** iPad is in, with the Mac layout; **F4** lock-screen families are not in L5; **F5** Dynamic Type comes after L3. None of these is an open item for Leaf 1.

---

## 1.0 Prerequisite: the simulator runtime (m7). Unblocks the iOS check in 1.1.

- [ ] **1.0** Install the **iOS 27** simulator runtime (Xcode ▸ Settings ▸ Components).
  - **Done-when:** `xcrun simctl list runtimes` lists iOS 27.
  - Whether a generic simulator build needs the runtime at all is `[Unverified]`; installing it first makes the question moot.

## 1.1 Platforms, deployment targets, widget link (project file only). Unblocks 1.2.

Files: `OneWord.xcodeproj/project.pbxproj`. Isolation: not applicable.

- [ ] **1.1a** In the **project-level** Debug (`:404-467`) and Release (`:468-524`) blocks, not the app target (R2):
  - change `SDKROOT = macosx` (`:462`, `:519`) to `SDKROOT = auto;`
  - add `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";`
  - add `IPHONEOS_DEPLOYMENT_TARGET = 17.0;` and keep `MACOSX_DEPLOYMENT_TARGET = 14.0` (`:458`, `:516`)
  - **Done-when:** both project blocks show the three values, and `grep -n 'SDKROOT = macosx' OneWord.xcodeproj/project.pbxproj` shows no project-level hits.
- [ ] **1.1b** In the widget Release (`:350-376`) and Debug (`:377-403`) blocks:
  - delete `SDKROOT = macosx;` (`:369`, `:396`)
  - keep `MACOSX_DEPLOYMENT_TARGET = 14.0` and the unconditional runpath
  - add `TARGETED_DEVICE_FAMILY = "1,2";`
  - add `"LD_RUNPATH_SEARCH_PATHS[sdk=iphone*]" = ("$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks");`
  - **Done-when:** `grep -n 'SDKROOT = macosx' OneWord.xcodeproj/project.pbxproj` returns nothing at all, and both widget blocks carry the device family and the `[sdk=iphone*]` runpath.
- [ ] **1.1c** In the app Debug (`:525-561`) and Release (`:562-598`) blocks, add:
  - `REGISTER_APP_GROUPS = YES;` (m2)
  - `SUPPORTS_MACCATALYST = NO;` (Q3 default)
  - `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;` (Q3 default)
  - `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;` (Q3 default)
  - **Leave the app runpath alone** (R1).
  - **Done-when:** both app blocks carry all four lines, and the app's `LD_RUNPATH_SEARCH_PATHS` is unchanged in `git diff`.
- [ ] **1.1d** Remove the dangling `Cocoa.framework` link (m1). Delete:
  - the PBXBuildFile at `:13`
  - the PBXFileReference at `:67`
  - the Frameworks-phase entry at `:113`, which leaves the widget phase `7E730264…` as `files = ( );`
  - the "OS X" group at `:130-137`
  - the "Frameworks" group at `:160-167`
  - the root-group child at `:185`
  - **Done-when:** `grep -n 'Cocoa' OneWord.xcodeproj/project.pbxproj` returns nothing.
- [ ] **1.1e** Verify the step.
  - **Done-when:** all of these hold:
    - Mac build green.
    - Opening the project in Xcode shows no "damaged project" alert.
    - The iOS build fails **only on Swift errors** in the inventory files, not on project, SDK or runtime errors. If it fails on signing or the SDK, stop and fix that here.
  - blocked-by: 1.0, 1.1a–d

## 1.2 Entitlements split. Unblocks iOS signing.

- [ ] **1.2a** NEW `OneWord/OneWord-iOS.entitlements`. It sits in the synchronized group, is not compiled or copied, and is referenced by build setting only. Keys:
  - `com.apple.security.application-groups` = `group.com.hariom.swift.oneword`
  - `keychain-access-groups` = `$(AppIdentifierPrefix)com.hariom.swift.oneword`
  - `com.apple.developer.applesignin` = `Default`
  - **No** `app-sandbox` and **no** `network.client`.
  - **Done-when:** the file exists with exactly those three keys, and `grep -c 'app-sandbox\|network.client' OneWord/OneWord-iOS.entitlements` prints 0.
- [ ] **1.2b** NEW `OneWordWidget/OneWordWidget-iOS.entitlements` with only the App Group `group.com.hariom.swift.oneword`. It needs no file reference.
  - **Done-when:** the file exists with that single key.
- [ ] **1.2c** In the app blocks (`:525-561`, `:562-598`), add:
  - `"CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]" = OneWord/OneWord-iOS.entitlements;`
  - `"CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]" = OneWord/OneWord-iOS.entitlements;`
  - Keep the unconditional lines (`:531`, `:568`) as the macOS values.
  - **Done-when:** both conditional lines appear in both app blocks.
- [ ] **1.2d** In the widget blocks (`:350-376`, `:377-403`), add the same two conditional lines pointing at `OneWordWidget/OneWordWidget-iOS.entitlements`. Keep the unconditional lines (`:353`, `:380`).
  - **Done-when:** both conditional lines appear in both widget blocks.
- [ ] **1.2e** Verify the step.
  - **Done-when:** the iOS build no longer reports an entitlement the profile lacks, and the Mac build is green.
  - **Exit (per the plan):** if automatic signing still complains about `app-sandbox`, condition the macOS path as `[sdk=macosx*]` and leave the unconditional value empty.
  - blocked-by: 1.2a–d

## 1.3 Shared/ compiles for iOS: App Group id and SavedWords (B1). Unblocks 1.4.

Isolation stays unchanged: `AppGroup` is a `nonisolated enum` that imports Foundation only, and SavedWords' statics are `nonisolated static`.

- [ ] **1.3a** `OneWord/Shared/AppGroup.swift:26`:
  - `#if os(iOS)` → `static let id = "group.com.hariom.swift.oneword"`; `#else` → `"LAP54KU2SV.group.com.hariom.swift.oneword"`.
  - Keep the comment at `:15-25`. Add two lines: iOS requires the `group.` prefix, and the two containers never meet (there is no sync).
  - **Done-when:** `bash tools/check_words.sh` and `bash tools/check_related.sh` are green. These are the two gates that compile the real `AppGroup.swift`.
- [ ] **1.3b** `OneWord/Shared/SavedWords.swift`:
  - change both `#if canImport(CoreServices)` guards (`:13` around the import, `:139` around `DCSCopyTextDefinition`) to `#if os(macOS)`
  - update the doc comment at `:132-135`: the system dictionary is macOS-only, and `systemDefinition` returns nil on iOS
  - **Done-when:** `grep -n 'canImport(CoreServices)' OneWord/Shared/SavedWords.swift` returns nothing, and `bash tools/check_capture.sh` is green.
- [ ] **1.3c** Verify the step.
  - **Done-when:** the Mac build and all six gates are green.
  - blocked-by: 1.3a, 1.3b

## 1.4 App entry, capture gate, audio session (M1, Q2). Unblocks 1.5.

Isolation: `OneWordApp.init` is `@MainActor` by target default and runs once, before any scene, in this order: Firebase configure, then GoogleSignIn configuration, then the iOS session category. Firebase is first used in `restore()` from `RootView.task` (`RootView.swift:104`), so the ordering that `WordCapture.swift:26-29` protects still holds.

- [ ] **1.4a** `OneWord/OneWordApp.swift`, imports: add `import FirebaseCore` and `import GoogleSignIn`, plus `#if os(iOS)` / `import AVFoundation` / `#endif`.
  - **Done-when:** the imports are present and the Mac build is green.
- [ ] **1.4b** `OneWordApp.swift`: move `AppDelegate.configureFirebase()` here from `WordCapture.swift:46-53`, verbatim, as `private static func configureFirebase()`. Bring its doc comment (`:39-45`) and the "why in init" comment (`:26-29`) with it.
  - **Done-when:** `configureFirebase` is defined in `OneWordApp.swift` and nowhere else (`grep -rn 'func configureFirebase' OneWord` shows one hit).
- [ ] **1.4c** `OneWordApp.swift`: add `init()` that calls `Self.configureFirebase()`, then, under `#if os(iOS)`, `try? AVAudioSession.sharedInstance().setCategory(.ambient)` with the plan's comment. This is the Q2 default.
  - **Done-when:** `init()` exists in this shape and the Mac build is green.
- [ ] **1.4d** `OneWordApp.swift`: put `#if os(macOS)` around the `@NSApplicationDelegateAdaptor` line, comment included (`:13-14`).
  - **Done-when:** that line sits inside the guard.
- [ ] **1.4e** `OneWordApp.swift`: put a postfix `#if os(macOS)` around `.defaultSize(width: 1000, height: 680)` and `.windowStyle(.hiddenTitleBar)`, with their comment (`:49-52`).
  - **Done-when:** both modifiers are gated and the Mac build is green.
  - **Exit:** if the compiler rejects postfix `#if` in the Scene chain (`[Inference]` SE-0308), move the `WindowGroup` into a computed `some Scene` and apply the two modifiers in a macOS-only branch.
- [ ] **1.4f** `OneWord/WordCapture.swift`:
  - `#if os(macOS)` as the first line after the header comment (before `import AppKit`, `:17`), and `#endif` as the last line
  - delete `override init()` (`:30-33`) and `configureFirebase()` (`:39-53`); `AppDelegate` keeps only `applicationDidFinishLaunching` (`:35-37`)
  - drop `import FirebaseCore` and `import GoogleSignIn` if nothing left in the file uses them
  - add one header sentence: iPhone has no Services menu, and a Share Extension is deferred
  - **Done-when:** the whole file is wrapped in `#if os(macOS)` … `#endif`, and `grep -n 'override init\|configureFirebase' OneWord/WordCapture.swift` returns nothing.
  - blocked-by: 1.4b
- [ ] **1.4g** Verify the step.
  - **Done-when:** all of these hold:
    - Mac build green.
    - **Manual (Mac):** relaunch while signed in; the app opens straight to the shell because the keychain session is restored.
    - **Manual (Mac):** "Save to One Word" from TextEdit still works.
  - blocked-by: 1.4a–f

## 1.5 Sign-in presentation seam (m6). Unblocks 1.6.

Isolation: `AuthViewModel` and `AppleAuthorization` are `@MainActor` by default. The anchor is read on main and passed into `@MainActor` methods. The existing `Task { await action(window) }` inherits main; **never** move it to `Task.detached`.

- [ ] **1.5a** `OneWord/ViewModels/AuthViewModel.swift`:
  - replace `import AppKit` (`:27`) with `#if os(macOS)` `import AppKit` `#else` `import UIKit` `#endif` (still no SwiftUI import in this view model)
  - add the file-scope `typealias PresentationAnchor`: `NSWindow` on macOS, `UIWindow` otherwise
  - **Done-when:** both are present, and `grep -n 'import SwiftUI' OneWord/ViewModels/AuthViewModel.swift` returns nothing.
- [ ] **1.5b** `AuthViewModel.swift`: change the signatures to `signIn(presenting window: PresentationAnchor)` (`:169`) and `signInWithApple(presenting window: PresentationAnchor)` (`:201`). Change `AppleAuthorization`'s `private let window` (`:360`) and `init(window:)` (`:367`) to take `PresentationAnchor`. Leave `presentationAnchor(for:)` (`:399-400`) unchanged.
  - **Done-when:** `grep -n 'NSWindow' OneWord/ViewModels/AuthViewModel.swift` hits only the typealias.
- [ ] **1.5c** `AuthViewModel.swift:176`: split the `GIDSignIn` call by platform.
  - macOS: `signIn(withPresenting: window)`
  - iOS: `guard let root = window.rootViewController else { error = "No window to present from."; return }`, then `signIn(withPresenting: root)`
  - **Done-when:** both branches are present and the Mac build is green.
  - `[Unverified]`: the iOS signature for GoogleSignIn 9.2.0. Open `GIDSignIn.h` in the resolved 9.2.0 checkout and adjust if it changed.
- [ ] **1.5d** `AuthViewModel.swift`, the debug avatar (`:94-95`, inside `#if DEBUG` at `:57-100`). macOS keeps the TIFF → PNG path. `#else` uses `UIImage(named: "male_profile_icon")?.pngData()` with the same `guard … else { return nil }` shape.
  - **Done-when:** both branches are present, and the Mac Debug build is green.
- [ ] **1.5e** `OneWord/Views/SignInView.swift`:
  - per-platform `AppKit` / `UIKit` import in place of `:16`
  - `signInButton(…, action: @escaping (PresentationAnchor) async -> Void)` (`:77`)
  - `guard let window = Self.anchor() else { return }` in place of `NSApp.keyWindow` (`:85`)
  - add `private static func anchor() -> PresentationAnchor?`. macOS returns `NSApp.keyWindow`. iOS returns the `.keyWindow` of the `.foregroundActive` `UIWindowScene` from `connectedScenes`.
  - update the comment at `:83-84` (iPad multi-window means picking the foreground-active scene)
  - **Done-when:** `grep -n 'NSApp\b\|NSWindow' OneWord/Views/SignInView.swift` hits only inside `#if os(macOS)` branches.
  - blocked-by: 1.5a
- [ ] **1.5f** `SignInView.swift` `#Preview` (`:115-119`): put `.frame(width: 1000, height: 680)` (`:118`) under `#if os(macOS)` (m8, from the plan's test plan §4.7). Don't add `.previewDevice`.
  - **Done-when:** the frame is gated, and the canvas renders the preview on an iPhone device.
- [ ] **1.5g** Verify the step.
  - **Done-when:** all of these hold:
    - Mac build green.
    - **Manual (Mac):** a real Google sign-in works.
    - **Manual (Mac):** a real Apple sign-in works.
  - iOS sign-in behaviour belongs to L4.
  - blocked-by: 1.5a–f

## 1.6 Cross-platform swaps (m3). Unblocks 1.7.

Isolation: these are all main-actor views. The players are `@MainActor` file-scope `let`s with the same lifetime as before, and they have no delegate, so no retain cycle. The cover cache stays a main-actor `static var`. These four files are independent of each other: **1.6a–d can be done in parallel**, then 1.6e.

- [ ] **1.6a** `OneWord/Views/SettingsView.swift`:
  - drop `import AppKit` (`:17`) and its comment (`:15-16`)
  - add `@Environment(\.openURL) private var openURL`
  - `openMail()` (`:243-249`) becomes `guard let url = FeedbackViewModel.mailtoURL else { mailFailed = true; return }` followed by `openURL(url) { accepted in mailFailed = !accepted }`
  - edit the doc comment at `:240-242` to match
  - **Done-when:** `grep -n 'AppKit\|NSWorkspace' OneWord/Views/SettingsView.swift` returns nothing, and the Mac build is green.
  - `[Unverified]`: whether the macOS completion reports `false` when no mail handler is registered. **Exit:** keep `NSWorkspace.shared.open` under `#if os(macOS)` inside `openMail()`.
- [ ] **1.6b** `OneWord/Views/DictionaryPicker.swift`:
  - replace `import AppKit` (`:11`) with `import AVFoundation`, plus `#if os(macOS)` `import AppKit` `#endif`
  - `flipSound` (`:16-18`) becomes the `@MainActor private let … AVAudioPlayer?` with `prepareToPlay()`, per the plan; the play site (`:180-181`) stays unchanged
  - add `@State private var refusals = 0` beside `shakes` (`:45`)
  - in `refuse(_:)` (`:191-195`): macOS keeps `NSHapticFeedbackManager…perform(.generic, …)`; iOS does `refusals += 1`. Both come **before** `guard !reduceMotion`.
  - attach `.sensoryFeedback(.error, trigger: refusals)` to the shelf's `GeometryReader` (`:92`)
  - **Done-when:** `grep -n 'NSSound' OneWord/Views/DictionaryPicker.swift` returns nothing, the `refusals += 1` line sits above the Reduce Motion guard, and the Mac build is green.
- [ ] **1.6c** `OneWord/Views/SentenceView.swift`:
  - drop `import AppKit` (`:11`); `AVFoundation` is already imported at `:12`
  - `shuffleSound` (`:17-19`) gets the same `AVAudioPlayer` + `prepareToPlay()` shape
  - update the comment at `:14-16`
  - the call sites at `:204-205` and `:211` stay unchanged
  - **Done-when:** `grep -n 'NSSound\|import AppKit' OneWord/Views/SentenceView.swift` returns nothing, and `bash tools/check_sentences.sh` and the Mac build are green.
- [ ] **1.6d** `OneWord/Views/PremiumView.swift`:
  - per-platform `AppKit` / `UIKit` import in place of `:17`
  - `private static var covers: [String: Image] = [:]` (`:128`)
  - `cover(_:height:scale:) -> Image` (`:130-147`): load the source via `NSImage(named:)?.cgImage(forProposedRect:context:hints:)` on macOS or `UIImage(named:)?.cgImage` on iOS; keep the same `CGContext` draw; return `Image(decorative: drawn, scale: scale)`; both fallbacks return `Image(name)`
  - the call site (`:110`) becomes `Self.cover(book.image, height: 100, scale: displayScale)`
  - update the comment at `:122-127`
  - **Done-when:** `grep -n 'Image(nsImage:' OneWord/Views/PremiumView.swift` returns nothing, and the Mac build is green.
- [ ] **1.6e** Verify the step.
  - **Done-when:** the Mac build and the gates are green, and a Mac pass by eye confirms:
    - [ ] the shelf flip still clicks
    - [ ] a locked book still buzzes on a Force Touch trackpad, **including with Reduce Motion on**
    - [ ] Practice's roll still shuffles
    - [ ] Premium covers draw crisp at 1× and 2× (move the window between displays)
    - [ ] Settings ▸ Email still opens Mail
  - blocked-by: 1.6a–d

## 1.7 View-layer gates: PaneHeader and RootView (B2). Unblocks the iOS compile.

- [ ] **1.7a** `OneWord/Views/PaneHeader.swift`, `WindowDragArea.body` (`:116-120`): wrap the existing `if #available(macOS 15, *) { … }` in `#if os(macOS)` … `#endif`. Leave the call site (`:89`) unchanged (R6).
  - **Done-when:** the `WindowDragGesture` use sits inside `#if os(macOS)`.
- [ ] **1.7b** `PaneHeader.swift`: put `#if os(macOS)` around `.onExitCommand { text = "" }` (`:151`). Change nothing else: `:29`, `:86`, `:149` and `:104` belong to L2.
  - **Done-when:** `.onExitCommand` is gated, and `git diff` on the file shows only 1.7a and 1.7b.
- [ ] **1.7c** `OneWord/Views/RootView.swift`:
  - `:152-153` becomes `Binding<Pane?>`, whose setter ignores nil and routes a locked `.practice` to `.premium`
  - `:156` becomes `.tag(Optional(item))`
  - `:159` becomes `.tag(Optional(Pane.dictionaries))`
  - **Done-when:** the binding type and both tags are `Pane?`, and the Mac build is green.
- [ ] **1.7d** Verify the step.
  - **Done-when:** all of these hold:
    - Mac build green.
    - Mac by eye: the sidebar selects and highlights.
    - Mac by eye: a locked Practice row goes to Premium.
    - Mac by eye: clicking the sidebar's empty area leaves the current pane selected.
    - **iOS build green.** If it isn't, another iOS-unavailable API has surfaced: gate it in place with `#if os(macOS)` (invariant 3) and note it in the PR.
  - blocked-by: 1.7a–c, 1.2e

## 1.8 Info.plist fonts, iOS icon, privacy manifests (M2, icon gap). Unblocks the iOS launch.

**1.8a, 1.8b–d and 1.8e–f are independent and can be done in parallel.**

- [ ] **1.8a** `OneWord/Info.plist`:
  - add `UIAppFonts` with the bare filenames `PulpenSnowman-Regular.otf`, `PulpenSnowman-Light.otf`, `PlusJakartaSans-Variable.ttf` and `PlusJakartaSans-Italic-Variable.ttf`
  - extend the header comment: macOS reads `ATSApplicationFontsPath`, iOS reads `UIAppFonts`
  - keep `ATSApplicationFontsPath`, `NSServices` and `CFBundleURLTypes`
  - **Done-when:** `plutil -lint OneWord/Info.plist` passes, and `UIAppFonts` lists all four files.
- [ ] **1.8b** Generate `OneWord/Assets.xcassets/AppIcon.appiconset/icon-ios-1024.png` with the plan's one-off `python3 -c …` (it reuses `gen_appicon.lift_artwork()` on `tools/appicon_source.png`). **Do not run `python3 tools/gen_appicon.py`** (R3).
  - **Done-when:** the PNG exists at 1024×1024 with no alpha (`sips -g pixelWidth -g hasAlpha` reports 1024 and `no`), and `git status` shows no changed `icon-mac-*.png`.
- [ ] **1.8c** `AppIcon.appiconset/Contents.json`: add `{ "filename" : "icon-ios-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }`.
  - **Done-when:** the entry is present, the existing Mac entries are unchanged in `git diff`, and the Mac build is green.
  - blocked-by: 1.8b
- [ ] **1.8d** `tools/gen_appicon.py`: give `main()` the same iOS PNG and `Contents.json` entry, plus a `# ponytail:` note that the Mac filenames on disk predate the script.
  - **Done-when:** `git diff tools/gen_appicon.py` shows the iOS entry and the note. **Do not run the script to check it.**
- [ ] **1.8e** NEW `OneWord/PrivacyInfo.xcprivacy` (joins the app through the synchronized group):
  - `NSPrivacyTracking = false`; `NSPrivacyTrackingDomains = []`
  - `NSPrivacyAccessedAPITypes`: `NSPrivacyAccessedAPICategoryUserDefaults` with `CA92.1` and `1C8F.1`
  - `NSPrivacyCollectedDataTypes` per `APP_STORE_READINESS_AUDIT.md` F5:
    - Name, Email Address and User ID: linked, App Functionality
    - Other User Content (feedback text): linked, App Functionality
    - Other Diagnostic Data: not linked, Analytics
    - No tracking
  - **Done-when:** `plutil -lint OneWord/PrivacyInfo.xcprivacy` passes, the contents match the list above, and the built `.app` contains `PrivacyInfo.xcprivacy`.
- [ ] **1.8f** NEW `OneWordWidget/PrivacyInfo.xcprivacy`, created via Xcode File ▸ New ▸ App Privacy, saved in `OneWordWidget/`, target membership **OneWordWidget only**:
  - `NSPrivacyTracking = false`
  - `NSPrivacyAccessedAPICategoryUserDefaults` with `1C8F.1` and `CA92.1`
  - no collected data
  - **Done-when:** `plutil -lint` passes, and `git diff OneWord.xcodeproj/project.pbxproj` gained **exactly** these, checked by eye:
    - one `PBXFileReference`
    - one `PBXBuildFile`
    - one entry in the widget Resources phase `B456E8B2…`
    - one entry in the widget group
- [ ] **1.8g** Verify the step.
  - **Done-when:** all three verification commands are green, and on an iPhone simulator:
    - the app launches to `SignInView` without crashing
    - Firebase is configured
    - the sign-in title shows the doodle face, and Plus Jakarta shows
    - the icon appears on the Home Screen
  - `[Assumption]` The full-bleed crop reads well under the iOS mask. **Exit:** hand-export a designed 1024.
  - blocked-by: 1.7d, 1.8a–f

## 1.9 Platform-neutral copy (M3, operator default)

Edit literal strings only; there is no `.xcstrings` file.

- [ ] **1.9a** `OneWord/Views/PremiumView.swift`:
  - `:88-89` and `:90-92`: "every Mac" → "every device"
  - `:159`: "on your desktop widget" → "on your widget"
  - `:162`: "already on your Mac" → "already on your device"
  - **Done-when:** all four strings read per the plan's §1.9 table.
- [ ] **1.9b** `OneWord/ViewModels/PremiumViewModel.swift:127`: "Purchases aren't allowed on this Mac." → "…on this device."
  - **Done-when:** the string is updated.
- [ ] **1.9c** `OneWord/Views/SettingsView.swift`:
  - `:70` → "The app only — the widget follows the system's own light or dark."
  - `:116` → "Applies to the widget too."
  - `:221` → "No mail app is set up on this device. Write to …"
  - **Done-when:** all three strings are updated.
- [ ] **1.9d** Verify the step.
  - **Done-when:** the Mac build is green, and `grep -rn '\bMac\b\|desktop' OneWord --include='*.swift'` returns only comments and `#if os(macOS)` code.
  - `[Inference]`: "every device" relies on universal purchase sharing the non-consumable; the L4 restore confirms it.
  - blocked-by: 1.9a–c

## 1.10 Docs and gate list (m9, version lockstep)

These three doc edits are independent of each other and of the code; they can be done in parallel.

- [ ] **1.10a** `CLAUDE.md` ("Verify before saying it's done"): add the iOS Simulator build line, and add `check_sentences` to the gate loop (`:54`).
  - **Done-when:** `grep -n 'generic/platform=iOS Simulator\|check_sentences' CLAUDE.md` hits both.
- [ ] **1.10b** `Docs/00_Context/PROJECT_CONTEXT.md`: the platform row (`:15`) gains iOS/iPadOS 17, and "Not doing (yet)" (`:65`) drops "iOS/iPadOS support".
  - **Done-when:** `grep -n 'iOS/iPadOS support' Docs/00_Context/PROJECT_CONTEXT.md` returns nothing, and the platform row names iOS/iPadOS 17.
- [ ] **1.10c** `Docs/00_Context/REPO_MAP.md`: add rows for both `-iOS.entitlements` files and both `PrivacyInfo.xcprivacy` files.
  - **Done-when:** `grep -c 'iOS.entitlements\|PrivacyInfo.xcprivacy' Docs/00_Context/REPO_MAP.md` is at least 4.
- [ ] **1.10d** Version check.
  - **Done-when:** `grep -n 'MARKETING_VERSION\|CURRENT_PROJECT_VERSION' OneWord.xcodeproj/project.pbxproj` shows 1.0 / 1 in all four target blocks.
  - From now on, bump them together: iOS validation rejects an extension whose version differs from its host's.

---

## iOS rigor gates (Leaf 1, check before merge)

- [ ] **G1: platform gating uses `#if os`, never `canImport`, in `Shared/` and `Models/`** (invariant 2).
  - **Done-when:** `grep -rn 'canImport' OneWord/Shared OneWord/Models` returns nothing, and the gates are green under bare `swiftc` on macOS.
- [ ] **G2: member import visibility** (invariant 7). Every file that calls a UIKit, AppKit or AVFoundation member imports it directly under the matching `#if os`. Files to check: `AuthViewModel`, `SignInView`, `DictionaryPicker`, `SentenceView`, `PremiumView`, `OneWordApp`.
  - **Done-when:** both builds are green with no "member … not imported" diagnostics.
- [ ] **G3: macOS-only code stays macOS-only** (invariant 3).
  - **Done-when:** NSServices/HUD (`WordCapture.swift`), window style and size, `WindowDragGesture`, `.onExitCommand`, `@NSApplicationDelegateAdaptor` and the Force Touch haptic each sit under `#if os(macOS)`, and the iOS build is green.
- [ ] **G4: no new `@available`.**
  - **Done-when:** `git diff` adds no `@available` or `#available`. The existing `#available(macOS 15, *)` now sits inside `#if os(macOS)`, and the iOS 17 / macOS 14 floors are in place (1.1a).
- [ ] **G5: entitlements per SDK.**
  - **Done-when:** all of these hold:
    - App and widget each carry `[sdk=iphoneos*]` and `[sdk=iphonesimulator*]` `CODE_SIGN_ENTITLEMENTS` pointing at their `-iOS` file.
    - The unconditional (macOS) values are unchanged.
    - The iOS files carry no `app-sandbox` or `network.client`.
    - Both iOS files use `group.com.hariom.swift.oneword`.
  - **Caveat (per the plan):** Signing & Capabilities edits reach only the macOS files, so edit the `-iOS` files by hand.
- [ ] **G6: App Group id split.**
  - **Done-when:** `AppGroup.id` is `group.…` on iOS and `LAP54KU2SV.group.…` otherwise, and `REGISTER_APP_GROUPS = YES` is on both targets.
  - `[Unverified]` whether automatic registration happens. **Exit:** register the group in the developer portal by hand if the first signed iOS build names `application-groups`.
- [ ] **G7: target membership for the new non-source files.**
  - **Done-when:** all of these hold:
    - The `-iOS.entitlements` files are referenced only by build setting: `grep -n 'iOS.entitlements' OneWord.xcodeproj/project.pbxproj` hits only `CODE_SIGN_ENTITLEMENTS` lines.
    - The app's `PrivacyInfo.xcprivacy` arrives via the synchronized group and appears in the built `.app`.
    - The widget's `PrivacyInfo.xcprivacy` is in the widget Resources phase `B456E8B2…` and in no other target.
    - The icon PNG is in the asset catalog.
    - Nothing moved into or out of `Shared/`, so the widget's explicit references and the gate paths are untouched.
- [ ] **G8: isolation map unchanged.**
  - **Done-when:** `git diff` adds no `actor`, no `Task.detached` and no `nonisolated`.
    - `SignInView` still uses `Task { await action(window) }`, which inherits main.
    - The players and the cover cache stay main-actor file-scope or static.
    - `refusals` is view-local `@State` that only drives `.sensoryFeedback`.
- [ ] **G9: Mac behaviour unchanged except the 1.9 copy** (invariant 4).
  - **Done-when:** the by-eye passes in 1.4g, 1.5g, 1.6e and 1.7d are all ticked.
- [ ] **G10: version lockstep.**
  - **Done-when:** item 1.10d holds.

---

## Next leaves (each gets its own `/plan` before it is built; touchpoints shift once Leaf 1 lands)

- [ ] **L2: the iPhone shell.** A `RootView` phone `TabView` chosen by idiom (DECIDE Q1), `PaneHeader` on iOS, and Profile rows for Practice and Plan.
  - blocked-by: Leaf 1 green on both platforms.
  - **Done-when:** the `/plan` run for L2 has landed in `Docs/02_Plan/`.
- [ ] **L3: compact layouts.** History, the two list rows, the Feedback sheet, the Settings popover, the Premium columns, a shelf check, and the MonthCalendar touch targets.
  - blocked-by: L2 shows every pane on a 390pt screen.
  - **Done-when:** the `/plan` run for L3 has landed.
- [ ] **L4: sign-in and purchase live, plus ship.** `onOpenURL`, the GoogleSignIn 9.2 header re-check, the Firebase/Apple console checks, StoreKit on the simulator, and the App Store Connect iOS work (iOS platform, 6.9" and 13" screenshots, the privacy label, Q3 toggles, ITMS-91053 watch).
  - blocked-by: L1, L2.
  - **Done-when:** the `/plan` run for L4 has landed.
- [ ] **L5: the widget on iPhone.** Gallery in all three sizes, the `group.` container, Follow App Settings, reload on pick. Can run in parallel after L1.
  - blocked-by: L1.
  - **Done-when:** the `/plan` run for L5 has landed.

## Deferred / evidence-gated (⏸, not now)

- ⏸ **Word capture / Share Extension (F2, locked).** `WordCapture.swift` stays macOS-only. **Activates when** iPhone users ask for "save from Safari".
- ⏸ **Lock-screen and StandBy widget families (F4).** `.accessoryRectangular` and `.accessoryInline`. **Activates when** iPhone users exist (after L5).
- ⏸ **Dynamic Type (F5).** Text uses fixed `.system(size:)` and `Font.serif(size)`. **Activates** as the first follow-up after L3, or inside L3 if accessibility becomes a release gate.
- ⏸ **Test target.** **Activates** as a follow-up, per plan §9. Until then the gates and the by-eye passes are the coverage.
- ⏸ **iPad-specific layouts.** iPad is "the Mac layout, unchanged". **Activates** only if F3 is revisited.
- ⏸ **Onboarding.** Re-plan after L3 (`[Assumption]` per the plan).
- ⏸ **Open facts the plan expects to settle in passing (not tasks):**
  - App Group prefix and auto-registration: settled by the first signed iOS build.
  - Whether conditional entitlements are honoured: settled by the first signed iOS build.
  - GoogleSignIn 9.2 iOS signature and `handle(url)`: settled by the resolved header.
  - Firebase plist coverage on iOS: settled by the first iOS `configure()` log.
  - The macOS `openURL` failure branch: settled by a Mac with no mail client.
  - Whether `.ambient` covers `AVSpeechSynthesizer` (`[Inference]`): settled by tapping Pronounce with the silent switch on.
  - Icon appearance: settled by eye.

---

## Leaf 1 definition of done

- [ ] Steps 1.0–1.10 are all ticked, and gates G1–G10 are all ticked.
- [ ] **Mac build green:**
  ```bash
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
  ```
- [ ] **iOS Simulator build green:**
  ```bash
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
  ```
- [ ] **All six gates green:**
  ```bash
  for s in check_words check_related check_learned check_capture check_premium check_sentences; do bash tools/$s.sh; done
  ```
- [ ] **One Mac pass by eye** through the checks in 1.4–1.7. That covers the sign-in restore, Services capture, Google and Apple sign-in, flip, buzz (including with Reduce Motion), roll, covers at 1× and 2×, Mail, and sidebar selection. The only visible change is the 1.9 copy.
- [ ] **On an iPhone simulator**, the app launches to `SignInView` without crashing:
  - Firebase is configured.
  - The sign-in title shows the doodle face, and Plus Jakarta shows.
  - The icon appears on the Home Screen.
- [ ] Both audit blockers are cleared: B1 (`#if os(macOS)` in `SavedWords.swift`, step 1.3) and B2 (optional `List` selection, step 1.7).
- [ ] The four DECIDE items (Q1, Q2, Q3, M3) are accepted or overridden in the plan's §5 queue. They don't block the build, but settle them before the L2 `/plan` run.
- [ ] **Merge gate:** with every box above ticked, Leaf 1 is complete per the plan, and L2 and L5 are unblocked.
