# Plan audit: iPhone implementation plan

> Audited 2026-10-03 by `/plan-audit --report` (the `plan-auditor` subagent) against [IPHONE_PLAN.md](../IPHONE_PLAN.md), re-grounded on `main` at `1a53942` with Xcode 27.0 and the iOS 27 / macOS 27 SDK interfaces. Read-only: nothing was built or run.

## 1. Header

**Plan audited:** `Docs/02_Plan/IPHONE_PLAN.md`. Leaf 1 is the part grounded in full. Leaves 2–5 were only spot-checked, because the plan says each gets its own `/plan` before it is built.

**Stack as re-verified.** It matches what the plan claims, with two corrections:
- Xcode 27.0 (27A266a). Installed SDKs: iphoneos27.0, iphonesimulator27.0, macosx27.0. `xcrun simctl list runtimes` is empty, as the plan says.
- Two native targets. App target settings `project.pbxproj:525-598`, widget `:350-403`. Both have `SDKROOT = macosx` (`:369, :396, :462, :519`) and `MACOSX_DEPLOYMENT_TARGET = 14.0`. The app has `TARGETED_DEVICE_FAMILY = "1,2"` (`:558, :595`). Swift 5.0 with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on both targets. The app also sets `SWIFT_APPROACHABLE_CONCURRENCY` and `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY`.
- SPM pins firebase-ios-sdk ≥12.18 and GoogleSignIn-iOS ≥9.2. `OneWord/` is a synchronized root group (`:97-106`). The widget lists its sources and `Shared/` files by explicit reference (`:62-84`, `:312-330`).
- **Correction 1:** the widget's Cocoa reference points at `MacOSX15.0.sdk` (`:67`), which no longer exists in this Xcode. It is already dangling, so removing it is right.
- **Correction 2:** `REGISTER_APP_GROUPS = YES` is set only on the **widget** (`:368, :395`). The app target doesn't have it, although plan §1.3 relies on it.

**Files opened:**
- Project and config: `project.pbxproj` (all 669 lines), both `.xcscheme` files, both `.entitlements`, both `Info.plist`, `AppIcon.appiconset/Contents.json`, `GoogleService-Info.plist` (BUNDLE_ID only).
- App and view models: `OneWordApp.swift` (full), `WordCapture.swift` 1-60 plus the type list, `AuthViewModel.swift` (full), `PremiumViewModel.swift` 30-40 and 120-130, `FeedbackViewModel.swift` 25-60.
- Shared: `AppGroup.swift` (full), `SavedWords.swift` 8-20 and 108-160, `Premium.swift` 1-40, `DoodleTheme.swift` 100-147.
- Views: `RootView.swift` 1-215, `PaneHeader.swift` (full), `SignInView.swift` (full), `DictionaryPicker.swift` 1-30 and 175-200, `SentenceView.swift` 1-30, `PremiumView.swift` 10-20, 100-150, 432-445, `SettingsView.swift` 10-20, 236-256, 320-330, plus the frame and preview lines of HistoryView, FeedbackView, ProfileView, WordListView, LearnedListView and MonthCalendar.
- Widget: `WordWidget.swift` (full) and the other widget files' imports.
- Tools and docs: compile lines of all six `tools/check_*.sh`, `tools/gen_appicon.py` header, `APP_STORE_READINESS_AUDIT.md` F2/F5.
- SDK ground truth: SwiftUI and SwiftUICore `.swiftinterface` for iOS 27 and macOS 27, the iOS `CoreServices.framework` modulemap and headers, and `GIDSignIn.h` (GoogleSignIn **8.0.0** checkout; 9.2 is not on disk).
- Nothing was built and nothing that compiles was run.

**The planner's nine questions, answered:**

| # | Claim | Result |
|---|---|---|
| 1 | `#if os(iOS)` in `AppGroup.swift` keeps the gates green | **Yes.** `swiftc` on macOS takes the `#else` branch. Only `check_words.sh:6-8` and `check_related.sh:7-10` compile the real `AppGroup.swift`. `check_capture`, `check_premium` and `check_learned` compile a shim `AppGroup` instead (`check_capture.sh:17-23`, `check_premium.sh:17-24`, `check_learned.sh:20-26`). So the plan's "four gates" claim (§1.3, §7) is wrong, but this has no build impact. |
| 2 | Postfix `#if` around scene modifiers (SE-0308) | **Compiles.** SE-0308 works on any postfix member chain, scene builders included. Also: `.defaultSize` is *available* on iOS 17 (`@available(iOS 17.0, macOS 13.0, visionOS 1.0, *)`). Only `.windowStyle` is iOS-unavailable (iOS interface line 4636). |
| 3 | `horizontalSizeClass` unavailable on macOS | **False.** It is `@available(iOS 13.0, macOS 10.15, …) @backDeployed(before: macOS 14.0 …)` (macOS SwiftUICore interface :21735-21737). The guard is harmless but not required, and the §10 risk row is invented. |
| 4 | Firebase configure in `App.init` keeps the ordering | **Yes.** The `@State` initialisers (`AuthViewModel()`, `PremiumViewModel()`, `RelatedWordsStore()`) run before the init body, but none of them touch Firebase. Firebase is first used in `restore()`, called from `RootView.task` (`RootView.swift:104`), well after `App.init`. Setting `GIDSignIn.sharedInstance.configuration` there is fine. |
| 5 | `.sensoryFeedback(.error, trigger:)` and `Image(decorative:scale:)` exist on both | **Both exist.** `sensoryFeedback` is `iOS 17.0, macOS 14.0`; `Image(decorative:scale:orientation:)` is in SwiftUICore on both. Whether `.error` actually *plays* on macOS is a separate question (see m3). |
| 6 | `signIn(withPresenting:)`: `UIViewController` on iOS, `NSWindow` on macOS | **Confirmed for 8.0.0**: `GIDSignIn.h:136-150` (iOS) and `:199-211` (OSX). `[Unverified]` for 9.2, though very likely unchanged. |
| 7 | `[sdk=…]`-conditional `CODE_SIGN_ENTITLEMENTS` and runpaths | **Standard and sound.** Caveat: the Signing & Capabilities editor shows and edits only the unconditional value, so capability edits made through the UI will not reach the iOS file. |
| 8 | Anything the eleven-file inventory missed | **Two compile errors were missed** (B1, B2). Also: user-facing "Mac" copy in five places (M3), and `.menuStyle(.borderlessButton)` at `MonthCalendar.swift:80` (deprecated on iOS, warning only). The other fixed frames (`ProfileView:544`, `PremiumView:441`, `SignInView:118`) are inside `#Preview`. |
| 9 | Does the widget need anything more on iOS? | The `NSExtensionPointIdentifier = com.apple.widgetkit-extension` plist is the same on iOS. No `NSExtensionPrincipalClass` is needed with a `@main WidgetBundle`. All APIs used are iOS 17. Missing: a privacy manifest for the widget (M2). Also keep the app's and widget's `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` in lockstep; they are 1.0/1 in both today. |

## 2. Verdict

**Fix blockers first.** Confidence: medium-high.

The plan's structure is sound: platform split by build setting, entitlements split, App Group split, cross-platform replacements, and a reversible-first order. Most of its citations hold. But the inventory claims to be complete, and two files the plan says compile unchanged on iOS will not: `SavedWords.swift` and `RootView.swift`. The first breaks **both** targets. Both fixes are one-line, platform-local changes inside Leaf 1, so this is not a rework. Fold them, plus the audio-session and privacy-manifest fixes, into Leaf 1 and it should be ready to build.

## 3. Blocking findings

### B1. `SavedWords.swift` does not compile for iOS; this breaks both the app and the widget

- **Where in the plan:** §3, last paragraph ("already guards its `CoreServices` import … so it compiles either way on iOS").
- **What's wrong:** `canImport(CoreServices)` is **true** on iOS. The iOS SDK ships `CoreServices.framework` with a modulemap (`iPhoneOS27.0.sdk/System/Library/Frameworks/CoreServices.framework/Modules/module.modulemap`), but its headers are only `UTType.h` and `UTCoreTypes.h`. `DCSCopyTextDefinition` appears **nowhere** in the iOS SDK frameworks (grep: zero matches). So `SavedWords.swift:139-145` takes the `canImport` branch and fails with "cannot find 'DCSCopyTextDefinition' in scope".
- **Why it hits both targets:** the file is compiled into the widget too (`pbxproj:29, :327`).
- **Fix:** change both guards (`:13` and `:139`) from `#if canImport(CoreServices)` to `#if os(macOS)`. The gates compile on macOS, so they keep taking the same branch. Invariant 2 holds.
- **Side effect:** on iOS, `lookUp` (`:122-131`) loses the system-dictionary fallback. Its only caller is capture (`:75`), which is deferred, so the impact today is nil.
- **Why blocker:** the iOS build fails for both targets. Confidence: high.

### B2. `RootView.swift:152-153` uses an iOS-unavailable `List` initializer

- **Where in the plan:** §3 inventory says RootView needs "none" beyond `.toolbar(removing:)`.
- **What's wrong:** `let selection = Binding { pane } set: { … }` is a non-optional `Binding<Pane>`, passed to `List(selection: selection)`. That overload is `@available(macOS 13.0, *) @available(iOS, unavailable)` (iOS SwiftUI interface :8161-8166). On iOS only `Binding<SelectionValue?>?` and `Binding<Set<…>>?` exist (:8158-8160).
- **Fix:** make the binding `Binding<Pane?>`: get `{ pane }`, set `{ if let p = $0 { pane = p == .practice && !premium.isUnlocked ? .premium : p } }`. Tag rows as `Optional(item)` at `:156` and `:159`. The optional overload exists on macOS 10.15+, so one body serves both platforms. Check by eye on the Mac that clicking the sidebar's empty area no longer deselects (the setter ignores nil).
- **Why blocker:** the iOS build fails. L2 replaces this shell only on compact width, so this code path still compiles on iOS. Confidence: high.

## 4. Major findings

### M1. Moving to `AVAudioPlayer` on iOS without an `AVAudioSession` category ships an audio bug

- **Where in the plan:** §1.6 (DictionaryPicker, SentenceView) and §6 ("`AVAudioPlayer` replaces `NSSound` … same lifetime").
- **What's wrong:** on iOS the default session category is `.soloAmbient`. Every shelf flip (`DictionaryPicker.swift:180-181`) and Practice roll (`SentenceView.swift:204-205`) would **stop the user's background music**. The existing `AVSpeechSynthesizer` pronunciation (`WordDetail.swift:17, :321-325`) is silenced by the ring/silent switch.
- **Fix:** in `OneWordApp.init()`, under `#if os(iOS)`, call `try? AVAudioSession.sharedInstance().setCategory(.ambient)`. AVAudioSession is unavailable on macOS, so the guard is needed. Whether pronunciation should override the silent switch (`.playback`, `.spokenAudio`) is an operator call (Q2).
- Severity major; confidence high on the default-category behaviour.

### M2. The privacy manifest is under-specified

- **Where in the plan:** §1.8.
- **What's wrong:**
  1. The app reads the App Group suite (`AppGroup.swift:35`; `Premium.swift` via `AppGroup.defaults`). Apple's reason `CA92.1` covers only app-private defaults; shared App Group access is `1C8F.1`. The app manifest should declare both.
  2. The widget is a separate binary that reads the same suite. ITMS-91053 notices name the offending binary, and they appear to flag `.appex` binaries too (`[Unverified]`).
- **Why do it now:** the widget folder is not synchronized, so adding its manifest later means another pbxproj edit (a `PBXFileReference` plus the widget Resources phase at `:287-301`). Cheaper to do in Leaf 1.
- **Fix:** add `1C8F.1` to the app manifest. Add `OneWordWidget/PrivacyInfo.xcprivacy` with `1C8F.1` and `NSPrivacyTracking = false` in L1.
- Severity major for ship; confidence medium-high on the reason codes, medium on the extension being flagged.

### M3. User-facing "Mac" copy is wrong on iPhone, and no leaf owns it

- **Where:** `PremiumView.swift:89-91` ("on every Mac signed in to your Apple Account"), `PremiumView.swift:162` ("already on your Mac"), `PremiumViewModel.swift:127` ("Purchases aren't allowed on this Mac."), `SettingsView.swift:70` ("the desktop widget follows the Mac's own light or dark"), `SettingsView.swift:221` ("No mail app is set up on this Mac").
- **Why it matters:** the Premium line becomes factually wrong once universal purchase covers iPhone, and that is the kind of thing App Review queries.
- **Fix:** add platform-neutral wording ("device", "every device signed in…") to L3 or L4, or `#if os` the strings. Confidence: high that the strings exist; the review risk is `[Inference]`.

## 5. Minor findings and nits

- **m1. Cocoa removal is incomplete (§1.1).** Deleting the "OS X" group object (`:130-137`) leaves its id in the `Frameworks` group's children (`:163`), and that group (`:160-167`, referenced at `:185`) is then empty. Delete `:163` as well, ideally the whole `Frameworks` group and its `:185` entry. A dangling child id usually just gets logged, but can trip the "project damaged" check (`[Unverified]`).
- **m2. `REGISTER_APP_GROUPS` (§1.3).** The plan cites `:368`, which is the widget's Release block. Add `REGISTER_APP_GROUPS = YES` to the app's two blocks too, or automatic registration of `group.com.hariom.swift.oneword` may not happen for the app (`[Unverified]`). The plan's exit (register by hand) still applies.
- **m3. Haptic swap changes Mac behaviour (§1.6, invariant 4).**
  - `refuse()` returns before touching `shakes` when Reduce Motion is on (`DictionaryPicker.swift:191-194`). Today's haptic fires before that guard, so Reduce-Motion users with a Force Touch trackpad would lose it.
  - `[Unverified]` `.error` may not play on macOS at all; today's call uses `.generic`.
  - Fix: keep `NSHapticFeedbackManager` under `#if os(macOS)` and attach `.sensoryFeedback(.error, trigger:)` iOS-only, or trigger it from a counter bumped before the guard.
- **m4. Factual errors with no build impact.** `horizontalSizeClass` is available on macOS (§3, §10 risk row); `.defaultSize` is available on iOS 17; only two gates compile `AppGroup.swift` (§1.3, §7).
- **m5. Citation drift.** `AppGroup.swift:28` is actually `:26`. `WordCapture.swift:44-51` is `:46-53`. `PaneHeader.swift:28 / :85 / :113-118` are `:29 / :89 / :115-121`. `HomeView.swift:28` is `:31`. `RootView.swift:140` is `:152`. All are easy to find; L2 re-grounds its own.
- **m6. `SignInView.anchor()` (§1.5).** "First `UIWindowScene`" can pick a background scene on a multi-window iPad (scene-manifest generation is on, `:540`). Prefer `.first { $0.activationState == .foregroundActive }`.
- **m7. Simulator build without a runtime.** "`generic/platform=iOS Simulator` needs the SDK only" (§8) is `[Unverified]`. Recent Xcode versions often refuse iOS builds until the platform runtime is installed. Install it before step 1.1's verify, not 1.8's.
- **m8. Preview suggestion (§7).** `.previewDevice` is a `PreviewProvider` idiom; `#Preview` picks its device in the canvas. The existing preview's `.frame(width: 1000, height: 680)` (`SignInView.swift:118`) also needs `#if os(macOS)` to show iPhone layout.
- **m9. CLAUDE.md gate list.** It names five gates; the plan (correctly) runs six. When adding the iOS build line, add `check_sentences` too.
- **m10. L2 note.** `.toolbar(.hidden, for: .navigationBar)` is `@available(macOS, unavailable)` (macOS interface :31785), so it must stay inside `#if os(iOS)`.
- **m11. Deprecation warning.** `.menuStyle(.borderlessButton)` (`MonthCalendar.swift:80`) gives an iOS deprecation warning only.

## 6. Coverage gaps

- **No audio-session step** anywhere in L1–L5 (M1).
- **No widget privacy manifest in L1** (M2).
- **No platform-copy pass** (M3).
- **No App Store Connect iOS work listed.** That means: adding the iOS platform to the record, iPhone/iPad screenshots, and deciding iOS-on-Apple-silicon-Mac / visionOS "Designed for iPad" availability (the build defaults leave these on). Outside the repo, but part of "ships".
- **Icon source exists but isn't used.** The §12 assumption about a layered icon source misses `tools/appicon_source.png` (2048², has alpha) and `tools/gen_appicon.py`, which already builds the Mac set from it. An iOS variant (opaque, full-bleed 1024) could come from the same script. Note it rather than leaving it as an assumption.
- **No version-lockstep note.** The widget's version must match the app's for iOS validation.

## 7. What the plan got right

- The overall approach is right: one target per product, `SDKROOT = auto` plus `SUPPORTED_PLATFORMS`, conditional entitlements and runpaths, the same bundle id for universal purchase.
- The App Group split is right, and the reason for it (team-prefixed on macOS, `group.` on iOS) matches `AppGroup.swift:19-25`.
- Removing the widget's Cocoa link is right and necessary; it already points at a non-existent SDK.
- Nine of the eleven inventory rows are accurate, and the proposed replacements all exist on both SDKs: `openURL`, `Image(decorative:scale:)`, `sensoryFeedback`, `AVAudioPlayer`, and the GoogleSignIn presenting types.
- Moving Firebase configuration to `App.init` was reasoned correctly, including the preview guard.
- The isolation map is correct for Swift 5 with MainActor default. No new tasks or actors, and the anchor never crosses actors.
- The sequencing is genuinely reversible-first, and the plan is honest about what is `[Unverified]`. Decomposing the work into a program spine plus re-planned leaves is a sound choice for a change this size.

## 8. Operator questions

- **Q1.** Pro Max iPhones in landscape report **regular** width, so the L2 compact switch would show the Mac split layout on a phone. iPads in Split View go compact and get the TabView. Is that the intended behaviour, or should the switch key on idiom plus size class?
- **Q2.** On iPhone, should the pronunciation button play when the silent switch is on (`.playback`), while the shelf and roll sounds respect it (`.ambient`)? Or should everything respect the switch?
- **Q3.** Should the iOS build be offered on Apple-silicon Macs and Vision Pro as "Designed for iPad"? The native Mac app already exists, so you probably want it off.

## 9. What would change the verdict

- **To Ready to build:** fold B1 (`#if os(macOS)` in `SavedWords.swift`) and B2 (optional `List` selection in `RootView.swift`) into Leaf 1. Ideally also M1's session line and M2's manifest codes.
- **To Needs rework:** only if the first iOS signing run shows that the conditional `CODE_SIGN_ENTITLEMENTS` approach is ignored by automatic signing *and* the plan's `[sdk=macosx*]` fallback also fails. That would undercut the single-target approach. No evidence of that was found.
- **A lower-confidence item to verify:** if GoogleSignIn 9.2 changed its macOS or iOS presenting signatures, §1.5's seam would need adjusting. Open `GIDSignIn.h` in the resolved 9.2 checkout after the first package resolve.
