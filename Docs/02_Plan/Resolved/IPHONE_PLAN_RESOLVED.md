# iPhone: the resolved implementation plan

> Written 2026-10-03 by `/plan-resolver --report` (the `plan-resolver` subagent). It resolves the audit [IPHONE_PLAN_AUDIT.md](../Audit/IPHONE_PLAN_AUDIT.md) against the plan [IPHONE_PLAN.md](../IPHONE_PLAN.md). Every cited line was re-checked on `main` at `1a53942` with Xcode 27.0 and the iOS 27 / macOS 27 SDK interfaces. I worked read-only: nothing was edited, built or run.

## 1. Header

**What was resolved.** The audit's verdict was **Fix blockers first**, not Needs rework, so this revises the plan in place. The two decisions the operator locked in the planning session stay as they were: the **TabView shell on iPhone** (Home, History, Bookmarks, Search, Profile) and **word capture deferred** (`WordCapture.swift` stays macOS-only, no Share Extension).

**Stack, re-checked on disk (with evidence)**

| | Detected | Evidence |
|---|---|---|
| Toolchain | Xcode 27.0 (27A266a). SDKs: iphoneos27.0, iphonesimulator27.0, macosx27.0. No simulator runtimes are installed. | brief; audit §1 |
| Targets | One `OneWord.xcodeproj`. `OneWord` app (Debug `:525-561`, Release `:562-598`) and `OneWordWidget` appex (Release `:350-376`, Debug `:377-403`). | `project.pbxproj` |
| Where `SDKROOT` lives | The **project-level** blocks set `SDKROOT = macosx` (`:462`, `:519`) next to `MACOSX_DEPLOYMENT_TARGET = 14.0` (`:458`, `:516`). The widget overrides it in its own blocks (`:369`, `:396`). The app target does **not** set `SDKROOT`; it inherits it. | `project.pbxproj:404-524`, `:350-403`, `:525-598` |
| Runpaths | App: `@executable_path/Frameworks` unconditionally (`:545-548`, `:582-585`). That is already the iOS value, left over from the iOS template. Widget: `@executable_path/../../../../Frameworks` (`:360-363`, `:387-390`). | `project.pbxproj` |
| Device family / iOS keys | The app has `TARGETED_DEVICE_FAMILY = "1,2"` (`:558`, `:595`) and the `INFOPLIST_KEY_UI*` keys (`:540-544`). The widget has neither. | `project.pbxproj` |
| App Groups | `REGISTER_APP_GROUPS = YES` is set on the widget only (`:368`, `:395`). Both entitlements use `LAP54KU2SV.group.com.hariom.swift.oneword`. | `project.pbxproj`; both `.entitlements` |
| Versions | 1.0 / 1 in all four target blocks (`:355,:365,:382,:392,:533,:549,:570,:586`). | `project.pbxproj` |
| Language and concurrency | Swift 5. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on both targets (`:371`, `:398`, `:554`, `:591`). The app adds `SWIFT_APPROACHABLE_CONCURRENCY` and `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` (`:553`, `:556`). Because of member import visibility, **any file that calls a UIKit or AppKit member must import that framework directly**; the comment at `SettingsView.swift:15-16` explains this. | `project.pbxproj` |
| File membership | `OneWord/` is a synchronized root group; only `Info.plist` is excepted (`:87-106`). The widget lists its 5 sources (`:168-179`) and the `Shared/` files (`SharedRefs`, `:138-159`) by explicit reference. The widget's Resources phase is `B456E8B2…` (`:286-299`). | `project.pbxproj` |
| Widget link | `Cocoa.framework` from `MacOSX15.0.sdk`, which no longer exists (it already dangles). Its entries: PBXBuildFile `:13`, file reference `:67`, Frameworks-phase entry `:113`, "OS X" group `:130-137`, "Frameworks" group `:160-167` (child `:163`), root-group child `:185`. | `project.pbxproj` |
| Dependencies | SPM: firebase-ios-sdk ≥ 12.18.0, GoogleSignIn-iOS ≥ 9.2.0. **`Package.resolved` pins GoogleSignIn 9.2.0.** The 8.0.0 checkout the audit read sits in a separate DerivedData (`~/Library/Application Support/Claude/simulator-builds/…`). | `project.pbxproj:625-669`; `Package.resolved` |
| UI / architecture | SwiftUI only. `@Observable` MVVM. One `WindowGroup` with `.defaultSize` and `.windowStyle` (`OneWordApp.swift:49-52`). `NavigationSplitView` shell (`RootView.swift:112-133`). | sources |
| Testing | No test target. Six gates compile with bare `swiftc` on macOS. Only `check_words.sh:6-8` and `check_related.sh:7-10` compile the real `AppGroup.swift`. `check_capture`, `check_premium` and `check_learned` use a shim `AppGroup`. `check_sentences` doesn't touch it. `CLAUDE.md:54` lists five gates and leaves out `check_sentences`. | `tools/check_*.sh`; `CLAUDE.md` |

**Files and symbols opened for this resolution**
- `project.pbxproj`: 1-190, 285-302, 340-600, 625-669. Also `Package.resolved` (GoogleSignIn entry).
- `OneWordApp.swift`: all of it. `WordCapture.swift`: 17-60, plus the tail and line count (165).
- `Shared/AppGroup.swift`: all of it. `Shared/SavedWords.swift`: 8-20, 118-160.
- `AuthViewModel.swift`: 20-100, 138-215, 350-402, plus the `#if DEBUG` map. `PremiumViewModel.swift`: 120-130. `FeedbackViewModel.swift`: imports and 25-60.
- `RootView.swift`: 1-215. `PaneHeader.swift`: 1-154. `SignInView.swift`: 10-20, 70-118. `SettingsView.swift`: 10-20, 66-72, 186-256, 320-330.
- `DictionaryPicker.swift`: 8-30, 34-45 (state), 170-200. `SentenceView.swift`: 8-22, 198-211. `PremiumView.swift`: 14-20, 84-165. `WordDetail.swift` (speech lines 11-17 and 320-326). `MonthCalendar.swift`: 76-82. `ProfileView.swift`: 179, 360-372. `HomeView.swift`: 31.
- `Info.plist` for the app and the widget, both `.entitlements`, `AppIcon.appiconset/Contents.json`, `OneWord/Fonts/`.
- `tools/gen_appicon.py` (all of it), the compile lines of all six gates, `CLAUDE.md`, `PROJECT_CONTEXT.md:12-15, 64-65`, `APP_STORE_READINESS_AUDIT.md` F2/F5.
- SDK ground truth from the iOS 27 SwiftUI interface:
  - `List` initializers: `:8156-8166`
  - `toolbar(removing:)`: `:22274`; `ToolbarDefaultItemKind.sidebarToggle`: `:21913-21915`
  - `windowStyle` is iOS-unavailable: `:4636-4640`
  - `onExitCommand` is iOS-unavailable: `:16574-16577`; `WindowDragGesture` is iOS-unavailable: `:30742-30746`
  - `sensoryFeedback`: `:2545-2547`; `SensoryFeedback.error`: `:921`
  - `BorderlessButtonMenuStyle`: `:21462-21467`; `presentationCompactAdaptation`: `:28191`
- Other SDK ground truth:
  - The iOS `CoreServices.framework/Headers` contains only `CoreServices.h`, `UTCoreTypes.h` and `UTType.h`, and `DCSCopyTextDefinition` appears nowhere in the iOS frameworks.
  - macOS `AVAudioSession.h:38,46` is `API_UNAVAILABLE(macos)`.
  - iOS `AVSpeechSynthesis.h:263` (`usesApplicationAudioSession`).
  - iOS `ASFoundation.h:39` (`ASPresentationAnchor = UIWindow`).
  - `GIDSignIn.h` 8.0.0: `:136-150` (iOS), `:199-245` (OSX).
- A sweep of every `.swift` file under `OneWord/` and `OneWordWidget/` against all 218 symbols the iOS SwiftUI interfaces mark `@available(iOS, unavailable)`. It found nothing beyond the items listed in §3.

## 2. Resolution summary

| Resolution type | Count | Findings |
|---|---|---|
| Fixed by me | **20** | B1, B2, M1, M2, m1–m10, and all six coverage gaps |
| Operator decision (recommended default applied) | **4** | M3 (copy wording), Q1, Q2, Q3 |
| Not a defect | **1** | m11 |
| Deferred | **0** | |

**Net build-readiness.** Both blockers are folded into Leaf 1:
- B1 is in step 1.3.
- B2 is in step 1.7.

The audio-session fix and both privacy manifests are in Leaf 1 too. 4 operator decisions are waiting for an accept/override pass (§ Operator review queue). None of them blocks building Leaf 1: each is either a one-line setting or a string edit.

I also found six things the audit didn't name. Each is fixed in the plan and grounded:
- **R1.** The app's runpath is already the iOS value, so the plan's conditional app runpath is redundant and has been dropped.
- **R2.** `SDKROOT` is set at the project level, not on the app target, so step 1.1 edits the project blocks and deletes the widget's override.
- **R3.** `gen_appicon.py` deletes every PNG in the icon set and rewrites `Contents.json`. Re-running it would rename and redraw the Mac icons, so Leaf 1 must not re-run it.
- **R4.** Two more "desktop"/"Mac" strings need the copy pass: `SettingsView.swift:116` and `PremiumView.swift:159`.
- **R5.** The project resolves GoogleSignIn **9.2.0**. The green Mac build already compiles `signIn(withPresenting: NSWindow)` against it, so only the iOS signature is still `[Unverified]` for 9.2.
- **R6.** A `#if os(macOS)` inside `WindowDragArea.body` is a smaller change than gating both the struct and its call site.

## 3. Resolution log

| ID · severity | Resolution | What changed in the plan | Grounding / decision |
|---|---|---|---|
| **B1** · blocker | **Fixed** | Step 1.3 now changes both guards in `SavedWords.swift` from `#if canImport(CoreServices)` to `#if os(macOS)`. The old §3 sentence ("compiles either way") is deleted. | `SavedWords.swift:13-15` and `:139-147`. iOS `CoreServices.framework/Headers` holds only UT* headers; `DCSCopyTextDefinition` has 0 matches in the iOS SDK frameworks. The file compiles into the widget (`pbxproj:29`, `:155`). The gates compile on macOS (`check_words.sh:7`, `check_related.sh:8`, `check_capture.sh:117`), so they keep the same branch. On iOS, `lookUp` (`:122-131`) loses the system-dictionary fallback; its only caller is capture (`:75`), which is deferred. |
| **B2** · blocker | **Fixed** | Step 1.7 makes the sidebar selection `Binding<Pane?>` and tags the rows `Optional(…)`. The inventory row for RootView is corrected. | `RootView.swift:152-153` (non-optional binding into `List(selection:)`), tags at `:156`, `:159`. In the iOS interface, `:8164-8166` (non-optional overload) is `@available(iOS, unavailable)`; `:8160` (`Binding<SelectionValue?>?`) is available on both platforms. |
| **M1** · major | **Fixed** (the category itself is Q2) | Step 1.4 adds `AVAudioSession.sharedInstance().setCategory(.ambient)` in `OneWordApp.init()` under `#if os(iOS)`, with `import AVFoundation` under the same guard. | macOS `AVAudioSession.h:38,46` is `API_UNAVAILABLE(macos)`, so the guard is required. Affected sounds: the shelf flip (`DictionaryPicker.swift:180-181`), the roll (`SentenceView.swift:204-205`) and speech (`WordDetail.swift:17, :320-326`). iOS `AVSpeechSynthesis.h:263`: speech uses the app session by default, so `.ambient` should cover pronunciation too `[Inference]`. |
| **M2** · major | **Fixed** | Step 1.8: the app manifest declares `CA92.1` **and** `1C8F.1`. A new `OneWordWidget/PrivacyInfo.xcprivacy` declares `1C8F.1` + `CA92.1` and `NSPrivacyTracking = false`, added to the widget target's Resources phase. | The App Group suite is read at `AppGroup.swift:35`. The widget reaches defaults only through that `let`; `.standard` is its fallback when the group isn't provisioned, hence `CA92.1` too. The widget Resources phase is at `pbxproj:286-299`. Whether an `.appex` gets flagged on its own stays `[Unverified]`; the cost of declaring it is one file. |
| **M3** · major | **Operator decision** (recommended default applied) | New step 1.9: platform-neutral wording for all **eight** strings. The audit listed five; I found three more (R4). Invariant 4 now says that copy may become platform-neutral. | Strings: `PremiumView.swift:88-89`, `:90-92`, `:159`, `:162`; `PremiumViewModel.swift:127`; `SettingsView.swift:70`, `:116`, `:221`. **Default:** one neutral string per site ("device", "widget") that is still true on the Mac. **Alternative:** `#if os` per-platform strings, which keep the Mac copy exactly as it is. **Flips if** you want the Mac copy untouched word for word. |
| **m1** · minor | **Fixed** | Step 1.1 now also deletes the "Frameworks" group (`:160-167`) and its root-group child (`:185`), along with the "OS X" group (`:130-137`). | `pbxproj:130-137`, `:160-167`, `:185` |
| **m2** · minor | **Fixed** | Step 1.1 adds `REGISTER_APP_GROUPS = YES` to the app's two blocks. | Currently only the widget has it, at `:368`, `:395`. Whether automatic registration happens is `[Unverified]`; the manual-portal exit still applies. |
| **m3** · minor | **Fixed** | Step 1.6: the Mac keeps `NSHapticFeedbackManager` under `#if os(macOS)`. iOS bumps a `refusals` counter **before** the Reduce Motion guard, and that counter drives `.sensoryFeedback(.error, trigger:)`. The Mac's haptic behaviour is unchanged. | `DictionaryPicker.swift:189-195`: `shakes` changes only after the `reduceMotion` guard at `:193`, so triggering on `shakes` would have lost the buzz for Reduce Motion users. |
| **m4** · minor | **Fixed** | The false claims are removed: that `horizontalSizeClass` is macOS-unavailable (old §3 text and §10 risk row), that `.defaultSize` is iOS-unavailable, and the "four gates" count (now two). Q1's idiom switch means L2 doesn't need size class at all. | Audit Q-table rows 2 and 3. Gate compile lines as cited in §1. |
| **m5** · minor | **Fixed** | All citations are corrected throughout this plan, e.g. `AppGroup.swift:26`, `WordCapture.swift:30-33/:46-53/:26-29`, `PaneHeader.swift:29/:89/:115-121`, `HomeView.swift:31`, `RootView.swift:152`, `ProfileView.swift:367`. | All re-opened. |
| **m6** · minor | **Fixed** | Step 1.5: the iOS anchor picks the **foreground-active** `UIWindowScene`. | Scene manifest generation is on (`pbxproj:540`, `:577`). |
| **m7** · minor | **Fixed** | New step 1.0 installs the iOS 27 simulator runtime **before** step 1.1's iOS check. | `xcrun simctl list runtimes` is empty (brief). Whether a generic simulator build needs the runtime is `[Unverified]`; installing it first makes the question moot. |
| **m8** · minor | **Fixed** | §7: `.previewDevice` is dropped. The `SignInView` preview's `.frame(width: 1000, height: 680)` (`:118`) goes under `#if os(macOS)` so the canvas can show an iPhone. | `SignInView.swift:115-119` |
| **m9** · minor | **Fixed** | Step 1.10: the `CLAUDE.md` gate loop gains `check_sentences`, and a new line adds the iOS build. | `CLAUDE.md:54` |
| **m10** · minor | **Fixed** | The L2 note now keeps `.toolbar(.hidden, for: .navigationBar)` inside `#if os(iOS)`. | macOS interface `:31785` (per the audit; L2 re-grounds this) |
| **m11** · nit | **Not a defect** | No step. | `.menuStyle(.borderlessButton)` (`MonthCalendar.swift:80`) is `@available(iOS, introduced: 14.0, deprecated: 100000.0)` (iOS interface `:21462`). `100000` is Apple's "to be deprecated" marker. It is available on iOS, and current Swift appears not to warn on it `[Inference]`. It compiles on both platforms as-is. |
| **Gap: audio session** | **Fixed** | Same fix as M1. | |
| **Gap: widget privacy manifest** | **Fixed** | Same fix as M2. | |
| **Gap: platform-copy pass** | **Fixed** (step added; wording is M3) | Step 1.9. | |
| **Gap: App Store Connect iOS work** | **Fixed** (listed; availability is Q3) | §5 now has a "Ship" list: add the iOS platform to the record "One Word: Daily Vocabulary", iPhone 6.9" and iPad 13" screenshots, the iOS App Privacy label (same answers as F5), and Designed-for-iPad / Vision availability (Q3). | Outside the repo. |
| **Gap: icon source unused** | **Fixed** | Step 1.8 derives the iOS 1024 from `tools/appicon_source.png`, using `gen_appicon.py`'s `lift_artwork()` in a one-off, and adds the iOS path to the script so a future regen keeps the entry. Leaf 1 must **not** re-run the script's `main()` (R3). | `gen_appicon.py:28-56` (`lift_artwork`), `:83-104` (`main` deletes `*.png` and rewrites `Contents.json`). The current set's filenames (`icon-mac-*.png`) are not what the script writes (`icon_*.png`), so a re-run would change the Mac set. |
| **Gap: version lockstep** | **Fixed** | §8 has a note, and step 1.10's check confirms the 4 blocks still read 1.0 / 1. | `pbxproj:355,365,382,392,533,549,570,586` |
| **Q1** · operator | **Operator decision** (recommended default applied) | L2 picks the TabView by `UIDevice.current.userInterfaceIdiom == .phone`, not by size class. | **Default:** idiom. A Pro Max in landscape keeps the tabs, and an iPad in Split View keeps the split view (which collapses on its own). **Alternative:** size class alone. **Flips if** you want iPad Split View / Slide Over to get the iPhone tabs. |
| **Q2** · operator | **Operator decision** (recommended default applied) | `.ambient` for everything (step 1.4). | **Default:** the flip, the roll and pronunciation all respect the silent switch and mix with music. **Alternative:** `.playback` for pronunciation only, which means switching the category around `speaker.speak` (`WordDetail.swift:326`). **Flips if** muted iPhones should still pronounce. |
| **Q3** · operator | **Operator decision** (recommended default applied) | Step 1.1 sets `SUPPORTS_MACCATALYST = NO`, `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO` and `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO` on the app target. | **Default:** off; the native Mac app exists. **Alternative:** leave them on (Xcode's default). **Flips if** you want Vision Pro users to get the iPad build. |

## 4. The resolved plan

### 4.1 Scope and outcome

**The change.** One Word, the macOS app and its WidgetKit widget, also builds, runs and ships on iPhone, and on iPad with the Mac layout. It uses the same two targets, the same bundle id and the same App Store record.

**Done when:**
- `xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build` is green, alongside the existing macOS build and all six gates.
- On an iPhone simulator, the app signs in, shows today's word, browses, searches, bookmarks, switches dictionaries, and buys Premium through the local StoreKit file.
- The widget appears in the iPhone widget gallery in all three system sizes and follows the app's dictionary pick.
- The Mac app's behaviour is unchanged. The only intended Mac-visible difference is step 1.9's platform-neutral copy.

**In scope:** every pane the Mac has, the widget, sign-in, Premium, themes, the doodle fonts, and the sounds. iPad is in scope only as "the Mac layout, unchanged", with no iPad-specific work.

**Out of scope (deferred, §9):**
- Word capture from other apps (locked decision F2).
- Lock-screen and StandBy widget families.
- iPad-specific layouts.
- Onboarding (re-plan after L3).
- A test target.
- Dynamic Type (after L3).

**Scope shape: program.** This document is the spine. It holds the invariants, the platform inventory, the dependency order, and a fully grounded **Leaf 1**. Each of Leaves 2–5 gets its own `/plan` run just before it is built, because Leaf 1 shifts the lines those leaves would cite.

| Leaf | Owns | Depends on | Next to build when |
|---|---|---|---|
| **L1: the iOS build compiles** | Project settings, entitlements split, App Group id, `#if os` gating, cross-platform swaps, audio session, Info.plist fonts, iOS icon, both privacy manifests, widget link fix, platform copy | nothing | now |
| **L2: the iPhone shell** | `RootView` phone `TabView` (by idiom), `PaneHeader` on iOS, Profile rows for Practice and Plan | L1 | L1 is green on both platforms |
| **L3: compact layouts** | History, the two list rows, the Feedback sheet, the Settings popover, the Premium columns, a shelf check | L2 | L2 shows every pane on a 390pt screen |
| **L4: sign-in and purchase live, plus ship** | Firebase/Google/Apple presentation on iOS, `onOpenURL`, console checks, StoreKit on the simulator, App Store Connect iOS work | L1, L2 | a simulator or device runs the app |
| **L5: the widget on iPhone** | Gallery check, App Group sharing through the `group.` id, Follow App Settings, reload on pick | L1 | L1 is green |

**Invariants (stated once, here):**
1. **No new target.** The same `OneWord` and `OneWordWidget` targets build for `macosx`, `iphoneos` and `iphonesimulator`.
2. **`Shared/` and `Models/` stay free of AppKit and UIKit.** Any platform branch there must use `#if os(…)`, never `#if canImport(…)` (B1 showed `canImport` can be true on iOS without the symbol), and must still compile under bare `swiftc` on macOS. The gates are the check.
3. **Prefer the cross-platform SwiftUI or Foundation API** over a pair of `#if` branches (`openURL`, `AVAudioPlayer`, `CGImage`, `Image(decorative:scale:)`). Reserve `#if os(macOS)` for things with no iOS meaning: NSServices, the HUD, window style and size, the window drag, `.onExitCommand`, and the Force Touch haptic.
4. **The Mac app does not change behaviour.** Every edit is either additive on iOS or a like-for-like swap whose Mac result is checked by eye. The one stated exception is user-facing copy, which step 1.9 makes platform-neutral.
5. **Platform-conditional build settings** use `[sdk=…]` conditions or project-level values on the existing configurations. No duplicated configuration, no xcconfig.
6. **The bundle id stays `com.hariom.swift.oneword`**, so iOS joins the existing App Store record as a universal purchase, and the one `GoogleService-Info.plist` serves both platforms `[Unverified for iOS; L4 confirms]`.
7. **Member import visibility is on.** Every file that calls a UIKit, AppKit or AVFoundation member imports that framework directly, under the matching `#if os`.

### 4.2 Architecture fit

Nothing new becomes a layer. iOS work lands in the files that already own each behaviour:
- **New source files:** none in Leaf 1. The L2 phone shell stays inside `RootView.swift`.
- **New non-source files:** two `-iOS.entitlements` files (referenced by build setting only), `OneWord/PrivacyInfo.xcprivacy` (joins the app through the synchronized group), `OneWordWidget/PrivacyInfo.xcprivacy` (explicit reference), and one icon PNG.

`PresentationAnchor` is a file-scope typealias in `AuthViewModel.swift`: `NSWindow` on macOS, `UIWindow` on iOS. It mirrors how AuthenticationServices defines `ASPresentationAnchor` (iOS `ASFoundation.h:39`), so `AppleAuthorization.presentationAnchor(for:)` (`AuthViewModel.swift:399-400`) can keep returning `window` unchanged.

**The complete macOS-only inventory, and what each item becomes**

| File:line | macOS-only thing | Becomes | Step |
|---|---|---|---|
| `OneWordApp.swift:14` | `@NSApplicationDelegateAdaptor(AppDelegate.self)` | wrapped in `#if os(macOS)`; Firebase configuration moves to `OneWordApp.init()` | 1.4 |
| `OneWordApp.swift:49-52` | `.defaultSize`, `.windowStyle(.hiddenTitleBar)` | postfix `#if os(macOS)` around both. Only `.windowStyle` is iOS-unavailable (iOS interface `:4636-4640`); `.defaultSize` is gated too so the iPad keeps its system default | 1.4 |
| `WordCapture.swift` (whole file, 165 lines) | NSServices provider, `NSPanel` HUD, `NSHostingView` | the whole file goes under `#if os(macOS)`; `AppDelegate.init` (`:30-33`) and `configureFirebase` (`:46-53`) move out | 1.4 |
| `AuthViewModel.swift:27, :94-95, :169, :176, :201, :360, :367` | `import AppKit`, the `NSImage` debug avatar, the `NSWindow` anchor | per-platform import, the `PresentationAnchor` typealias, a per-platform `GIDSignIn` call, and the debug avatar per platform | 1.5 |
| `SignInView.swift:16, :77, :85` | `import AppKit`, `NSWindow`, `NSApp.keyWindow` | per-platform import, `(PresentationAnchor) async -> Void`, `Self.anchor()` | 1.5 |
| `SettingsView.swift:15-17, :244` | `NSWorkspace.shared.open(url)` | `@Environment(\.openURL)` with a completion handler | 1.6 |
| `DictionaryPicker.swift:11, :16-18, :192` | `NSSound`, `NSHapticFeedbackManager` | `AVAudioPlayer` on both; the haptic stays on the Mac and iOS gets `.sensoryFeedback(.error, trigger: refusals)` | 1.6 |
| `SentenceView.swift:11, :17-19` | `NSSound` | `AVAudioPlayer` | 1.6 |
| `PremiumView.swift:17, :110, :128-147` | `NSImage` cover cache and downsample | a cache of `[String: Image]` built from a `CGImage`, with one `#if` for the source load | 1.6 |
| `Shared/AppGroup.swift:26` | team-prefixed App Group id | `#if os(iOS)` → `"group.com.hariom.swift.oneword"` | 1.3 |
| `Shared/SavedWords.swift:13, :139` | `#if canImport(CoreServices)` around `DCSCopyTextDefinition` | `#if os(macOS)` (B1) | 1.3 |
| `PaneHeader.swift:115-121, :151` | `WindowDragGesture` (its `#available(macOS 15, *)` check is true on iOS too, so it doesn't protect the iOS build), `.onExitCommand` | `#if os(macOS)` inside `WindowDragArea.body`; `#if os(macOS)` around `.onExitCommand` | 1.7 |
| `RootView.swift:152-159` | non-optional `List(selection:)` | `Binding<Pane?>` with `Optional` tags (B2) | 1.7 |
| `RootView.swift:190` | `.toolbar(removing: .sidebarToggle)` | no change: available on iOS 17 (iOS interface `:22273-22274`, `:21913-21915`) | none |
| `MonthCalendar.swift:80` | `.menuStyle(.borderlessButton)` | no change: available on iOS 14, soft-deprecated only (m11) | none |

### 4.3 Implementation steps: Leaf 1, fully grounded

Every step keeps the macOS build and the gates green on its own. The iOS destination should compile at the end of step 1.7 and launch to `SignInView` after step 1.8 `[Inference: the iOS-unavailable sweep found nothing beyond this inventory, but nothing has been compiled]`. The order is reversible-first: until step 1.3, `git checkout -- OneWord.xcodeproj` undoes everything.

#### 1.0 Prerequisite: the simulator runtime (m7)

In Xcode ▸ Settings ▸ Components, install the **iOS 27** simulator runtime. **Verify:** `xcrun simctl list runtimes` lists iOS 27. Do this before step 1.1's iOS check, so a missing runtime can't be mistaken for a project error.

#### 1.1 Platforms, deployment targets, widget link (project file only)

MODIFIED `OneWord.xcodeproj/project.pbxproj`:

**a. Project-level Debug (`:404-467`) and Release (`:468-524`) blocks.** Here, not in the app target (R2):
```
SDKROOT = auto;                                   // replaces SDKROOT = macosx (:462, :519)
SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx";
IPHONEOS_DEPLOYMENT_TARGET = 17.0;                // beside MACOSX_DEPLOYMENT_TARGET = 14.0 (:458, :516), which stays
```
iOS 17 is the floor because of `@Observable` and `.sensoryFeedback` (iOS interface `:2545`). It is comparable in age to the macOS 14 floor.

**b. Widget Release (`:350-376`) and Debug (`:377-403`) blocks.**
- **Delete** `SDKROOT = macosx;` (`:369`, `:396`), so the widget inherits `auto`.
- Keep `MACOSX_DEPLOYMENT_TARGET = 14.0` and the unconditional runpath; both are the macOS values.
- Add:
```
TARGETED_DEVICE_FAMILY = "1,2";
"LD_RUNPATH_SEARCH_PATHS[sdk=iphone*]" = (
    "$(inherited)",
    "@executable_path/Frameworks",
    "@executable_path/../../Frameworks",
);
```

**c. App Debug (`:525-561`) and Release (`:562-598`) blocks.** Add:
```
REGISTER_APP_GROUPS = YES;                         // m2: widget-only today (:368, :395)
SUPPORTS_MACCATALYST = NO;                         // Q3 default
SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = NO;        // Q3 default
SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD = NO;         // Q3 default
```
**No runpath change for the app.** Its unconditional `@executable_path/Frameworks` (`:545-548`, `:582-585`) is already the iOS value (R1). Don't touch it for macOS either: that would change the Mac build.

**d. Remove the dangling Cocoa link (m1).** Delete all of these:
- the PBXBuildFile at `:13`
- the PBXFileReference at `:67`
- the Frameworks-phase entry at `:113`, leaving the widget's phase `7E730264…` with an empty `files = ( );`
- the "OS X" group at `:130-137`
- the "Frameworks" group at `:160-167`
- its child entry in the root group at `:185`

WidgetKit and SwiftUI bring in everything the widget needs on both platforms.

- **Isolation:** not applicable (project settings only).
- **Verify:** `xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build` is green. Opening the project in Xcode shows no "damaged project" alert. `… -destination 'generic/platform=iOS Simulator' build` now fails on **Swift** errors in the inventory files, not on project, SDK or runtime errors. If it fails on signing or the SDK, stop and fix that here.

#### 1.2 Entitlements split

NEW `OneWord/OneWord-iOS.entitlements`. It sits in the synchronized group like the existing `OneWord.entitlements`, which is not compiled or copied either. Contents:
```xml
<key>com.apple.security.application-groups</key>
<array><string>group.com.hariom.swift.oneword</string></array>
<key>keychain-access-groups</key>
<array><string>$(AppIdentifierPrefix)com.hariom.swift.oneword</string></array>
<key>com.apple.developer.applesignin</key>
<array><string>Default</string></array>
```
It has no `app-sandbox` and no `network.client`, because both are macOS sandbox keys.

NEW `OneWordWidget/OneWordWidget-iOS.entitlements` holds only the App Group (`group.com.hariom.swift.oneword`). It needs no file reference, only the build setting below.

MODIFIED `project.pbxproj`:
- App blocks (`:525-561`, `:562-598`):
  ```
  "CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]" = OneWord/OneWord-iOS.entitlements;
  "CODE_SIGN_ENTITLEMENTS[sdk=iphonesimulator*]" = OneWord/OneWord-iOS.entitlements;
  ```
- Widget blocks (`:350-376`, `:377-403`): the same two lines, pointing at `OneWordWidget/OneWordWidget-iOS.entitlements`.
- The existing unconditional `CODE_SIGN_ENTITLEMENTS` lines (`:353`, `:380`, `:531`, `:568`) stay as the macOS values.
- Note: the Signing & Capabilities editor shows and edits only the unconditional value. **Future capability changes made through that UI will not reach the `-iOS` files**, so edit those by hand.

**Verify:** the iOS build no longer reports an entitlement the profile lacks. **Exit (§10):** if automatic signing still complains about `app-sandbox`, condition the macOS path as `[sdk=macosx*]` and leave the unconditional value empty.

#### 1.3 Shared/ compiles for iOS: App Group id and SavedWords (B1)

MODIFIED `OneWord/Shared/AppGroup.swift:26`:
```swift
#if os(iOS)
static let id = "group.com.hariom.swift.oneword"
#else
static let id = "LAP54KU2SV.group.com.hariom.swift.oneword"
#endif
```
- Keep the comment at `:15-25`. Add two lines: iOS requires the `group.` prefix, and the two containers never meet (there is no cross-device sync).
- The type stays a `nonisolated enum` that imports only Foundation, so invariant 2 holds.
- The `group.com.hariom.swift.oneword` App Group must be registered on the App ID. `REGISTER_APP_GROUPS = YES` (step 1.1c) should do this on the first signed iOS build `[Unverified]`. If it doesn't, add it in the developer portal.

MODIFIED `OneWord/Shared/SavedWords.swift`: change both `#if canImport(CoreServices)` guards, at `:13` (around the import) and at `:139` (around `DCSCopyTextDefinition`), to `#if os(macOS)`. Update the doc comment at `:132-135` to say the system dictionary is macOS-only, and that `systemDefinition` returns nil on iOS. Nothing on iOS reaches it today: `lookUp`'s only caller is capture (`:75`), which is macOS-only.

- **Isolation:** unchanged. Both types are `nonisolated` (`AppGroup.swift:14`; SavedWords' statics are `nonisolated static`).
- **Verify:** `bash tools/check_words.sh` and `bash tools/check_related.sh` (the two gates that compile the real `AppGroup.swift`), plus `check_capture.sh` (which compiles `SavedWords.swift`). All stay green: `swiftc` on macOS takes the macOS branch. Mac build green.

#### 1.4 App entry, capture gate, audio session (M1, Q2)

MODIFIED `OneWord/OneWordApp.swift`:
- Imports: add `import FirebaseCore` and `import GoogleSignIn`, plus `#if os(iOS)` / `import AVFoundation` / `#endif`.
- Add the initializer:
  ```swift
  init() {
      Self.configureFirebase()
      #if os(iOS)
      // .ambient: the shelf flip, the roll and pronunciation respect the silent
      // switch and mix with the user's music (default .soloAmbient would stop it).
      try? AVAudioSession.sharedInstance().setCategory(.ambient)
      #endif
  }
  ```
- Move the body of `AppDelegate.configureFirebase()` (`WordCapture.swift:46-53`) here verbatim as `private static func configureFirebase()`, along with its doc comment (`:39-45`) and the "why in init" comment (`:26-29`).
- `#if os(macOS)` around the `@NSApplicationDelegateAdaptor` line (`:13-14`, comment included).
- Postfix `#if os(macOS)` around `.defaultSize(width: 1000, height: 680)` and `.windowStyle(.hiddenTitleBar)`, with their comment (`:49-52`). SE-0308 allows this in a `Scene` chain (audit Q-table row 2). **Exit:** if the compiler objects, put the `WindowGroup` in a computed `some Scene` and apply the two modifiers in a macOS-only branch.

MODIFIED `OneWord/WordCapture.swift`:
- `#if os(macOS)` as the first line after the header comment (before `import AppKit`, `:17`), and `#endif` as the last line.
- Delete `override init()` (`:30-33`) and `configureFirebase()` (`:39-53`); both moved. `AppDelegate` keeps only `applicationDidFinishLaunching` (`:35-37`).
- Drop `import FirebaseCore` and `import GoogleSignIn` if nothing left in the file uses them.
- Add one header sentence: iPhone has no Services menu; capture there would be a Share Extension, which is deferred.

- **Isolation:** `OneWordApp.init` is `@MainActor` by target default. `FirebaseApp.configure()` and the session call both run on main before any scene. The `@State` initializers (`AuthViewModel()`, `PremiumViewModel()`, `RelatedWordsStore()`) run before the init body, but none of them touch Firebase. Firebase is first used in `restore()`, from `RootView.task` (`RootView.swift:104`), so the ordering `WordCapture.swift:26-29` protects is kept.
- **Verify:** Mac build green. On the Mac, relaunch while signed in and confirm it opens straight to the shell (the keychain session is restored). "Save to One Word" from TextEdit still works.

#### 1.5 Sign-in presentation seam (m6)

MODIFIED `OneWord/ViewModels/AuthViewModel.swift`:
- Replace `import AppKit` (`:27`) with `#if os(macOS)` / `import AppKit` / `#else` / `import UIKit` / `#endif`. A view model may import UIKit or AppKit, just not SwiftUI (the `CLAUDE.md` rule), and that still holds.
- At file scope: `#if os(macOS)` / `typealias PresentationAnchor = NSWindow` / `#else` / `typealias PresentationAnchor = UIWindow` / `#endif`.
- `signIn(presenting window: PresentationAnchor)` (`:169`). Inside the `do`, the call at `:176` becomes:
  ```swift
  #if os(macOS)
  let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
  #else
  guard let root = window.rootViewController else { error = "No window to present from."; return }
  let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
  #endif
  ```
  In GoogleSignIn 8.0.0 these signatures are `GIDSignIn.h:136-150` (iOS, `UIViewController`) and `:199-245` (OSX, `NSWindow`). On 9.2.0 the macOS one is confirmed by today's green Mac build (R5); the iOS one is `[Unverified]`. Open `GIDSignIn.h` in the project's resolved 9.2.0 checkout after the first package resolve, and adjust if it changed.
- `signInWithApple(presenting window: PresentationAnchor)` (`:201`).
- `AppleAuthorization`: `private let window: PresentationAnchor` (`:360`) and `init(window: PresentationAnchor)` (`:367`). `presentationAnchor(for:)` (`:399-400`) is unchanged, because `PresentationAnchor` and `ASPresentationAnchor` resolve to the same class on each platform.
- Debug avatar (`:94-95`, inside `#if DEBUG` `:57-100`): `#if os(macOS)` keeps the existing TIFF → PNG path; `#else` uses `let png = UIImage(named: "male_profile_icon")?.pngData()`, keeping the same `guard … else { return nil }` shape.

MODIFIED `OneWord/Views/SignInView.swift`:
- Replace `import AppKit` (`:16`) with the per-platform `AppKit` / `UIKit` import (member import visibility applies to `UIApplication.shared`).
- `signInButton(…, action: @escaping (PresentationAnchor) async -> Void)` (`:77`).
- `guard let window = Self.anchor() else { return }` replaces `NSApp.keyWindow` (`:85`). Add:
  ```swift
  private static func anchor() -> PresentationAnchor? {
      #if os(macOS)
      NSApp.keyWindow
      #else
      UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .first { $0.activationState == .foregroundActive }?
          .keyWindow
      #endif
  }
  ```
  Update the comment at `:83-84`: on iPad, multi-window is possible, so the method picks the foreground-active scene.

- **Isolation:** the class is `@MainActor` by default, and so is `AppleAuthorization` (comment `:350-352`). The anchor is read on main in the button action and passed into a `@MainActor` method. It never crosses an actor boundary. Don't capture it in a `Task.detached`. The existing `Task { await action(window) }` inherits main.
- **Verify:** Mac build green. A real Google sign-in and a real Apple sign-in still work on the Mac. iOS behaviour is L4.

#### 1.6 Cross-platform swaps (m3)

MODIFIED `OneWord/Views/SettingsView.swift`:
- Drop `import AppKit` (`:17`) and its comment (`:15-16`).
- Add `@Environment(\.openURL) private var openURL`.
- `openMail()` (`:243-249`) becomes:
  ```swift
  guard let url = FeedbackViewModel.mailtoURL else { mailFailed = true; return }
  openURL(url) { accepted in mailFailed = !accepted }
  ```
- Edit the doc comment at `:240-242` to match.
- Whether the macOS completion reports `false` when no mailto handler is registered (as `NSWorkspace.open` did) is `[Unverified]`. See §10.

MODIFIED `OneWord/Views/DictionaryPicker.swift`:
- Replace `import AppKit` (`:11`) with `import AVFoundation`, plus `#if os(macOS)` / `import AppKit` / `#endif` for the haptic.
- `flipSound` (`:16-18`):
  ```swift
  @MainActor private let flipSound: AVAudioPlayer? = Bundle.main
      .url(forResource: "book_pull", withExtension: "mp3")
      .flatMap { try? AVAudioPlayer(contentsOf: $0) }
      .map { $0.prepareToPlay(); return $0 }
  ```
  The play site (`:180-181`, `currentTime = 0; play()`) compiles unchanged.
- Add `@State private var refusals = 0` beside `shakes` (`:45`).
- `refuse(_:)` (`:191-195`):
  ```swift
  #if os(macOS)
  NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
  #else
  refusals += 1   // before the Reduce Motion guard, like the Mac buzz
  #endif
  guard !reduceMotion else { return }
  ```
- Attach `.sensoryFeedback(.error, trigger: refusals)` to the shelf's `GeometryReader` (`:92`). On macOS `refusals` never changes, so it never fires, and the Mac haptic is exactly as it is today.

MODIFIED `OneWord/Views/SentenceView.swift`:
- Drop `import AppKit` (`:11`); `AVFoundation` is already imported at `:12`.
- `shuffleSound` (`:17-19`) gets the same `AVAudioPlayer` + `prepareToPlay()` shape. `prepareToPlay` stands in for the "first roll is instant" property that `byReference:` gave it.
- Update the comment at `:14-16`. `currentTime = 0`, `play()` and `stop()` (`:204-205`, `:211`) compile unchanged. `AVAudioPlayer.stop()` also leaves the playhead where it stopped, and the existing rewind handles that.

MODIFIED `OneWord/Views/PremiumView.swift`:
- Replace `import AppKit` (`:17`) with the per-platform `AppKit` / `UIKit` import (needed only for the source load).
- `private static var covers: [String: Image] = [:]` (`:128`).
- `cover(_:height:scale:) -> Image` (`:130-147`):
  - The source load: `#if os(macOS)` / `NSImage(named: name)?.cgImage(forProposedRect: nil, context: nil, hints: nil)` / `#else` / `UIImage(named: name)?.cgImage` / `#endif`.
  - Same `CGContext` draw.
  - Success returns `Image(decorative: drawn, scale: scale)`. The point size works out to `width/scale × height`, matching today's `NSImage` size.
  - Both fallbacks return `Image(name)`.
- The call site (`:110`) becomes `Self.cover(book.image, height: 100, scale: displayScale)` with no `Image(nsImage:)` wrapper.
- Update the comment at `:122-127`.

- **Isolation:** all of these are main-actor views. The players are `@MainActor` file-scope `let`s with the same lifetime as before. `AVAudioPlayer` is not `Sendable` and doesn't need to be. The cover cache is a main-actor `static var`, as it is today.
- **Verify:** Mac build green. By eye on the Mac:
  - the shelf flip still clicks;
  - a locked book still buzzes on a Force Touch trackpad, including with Reduce Motion on;
  - Practice's roll still shuffles;
  - Premium covers still draw crisp at 1× and 2× (move the window between displays);
  - Settings ▸ Email still opens Mail.

#### 1.7 View-layer gates: PaneHeader and RootView (B2)

MODIFIED `OneWord/Views/PaneHeader.swift`:
- Inside `WindowDragArea.body` (`:116-120`), wrap the existing `if #available(macOS 15, *) { … }` in `#if os(macOS)` … `#endif`. On iOS the builder is empty. The `.background { WindowDragArea() }` call site (`:89`) stays as it is (R6). On iOS, `#available(macOS 15, *)` evaluates true through `*`, which is why it doesn't protect the iOS build here.
- `#if os(macOS)` around `.onExitCommand { text = "" }` (`:151`). It is iOS-unavailable (iOS interface `:16574-16577`).
- Nothing else changes. `.ignoresSafeArea` (`:29`), the folded 84pt padding (`:86`) and the fixed search width (`:149`) belong to L2.

MODIFIED `OneWord/Views/RootView.swift` (B2):
- `:152-153`:
  ```swift
  let selection = Binding<Pane?> { pane } set: {
      if let p = $0 { pane = p == .practice && !premium.isUnlocked ? .premium : p }
  }
  ```
- `:156` becomes `row(item).tag(Optional(item))`; `:159` becomes `row(.dictionaries).tag(Optional(Pane.dictionaries))`. The tags must be `Pane?` to match the selection type.
- The `Binding<SelectionValue?>?` overload exists on macOS 10.15+ and on iOS (iOS interface `:8160`), so one body serves both platforms.
- **Isolation:** unchanged; view-local state.
- **Verify:**
  - Mac build green. By eye on the Mac: the sidebar still selects and highlights; a locked Practice row still goes to Premium; clicking the sidebar's empty area leaves the current pane selected (the setter ignores nil).
  - **The iOS Simulator build should be green from here.** If it isn't, another iOS-unavailable API has turned up. Gate it in place with `#if os(macOS)` per invariant 3 and note it in the PR.

#### 1.8 Info.plist fonts, iOS icon, privacy manifests (M2, icon gap)

MODIFIED `OneWord/Info.plist`:
- Add `UIAppFonts` with the four files in `OneWord/Fonts/`: `PulpenSnowman-Regular.otf`, `PulpenSnowman-Light.otf`, `PlusJakartaSans-Variable.ttf`, `PlusJakartaSans-Italic-Variable.ttf`. These are bare filenames, because the synchronized group copies fonts flat into the bundle root (see the plist comment).
- Extend the plist's header comment to say macOS reads `ATSApplicationFontsPath` and iOS reads `UIAppFonts`.
- `ATSApplicationFontsPath` stays. `NSServices` is inert on iOS. `CFBundleURLTypes` is needed on iOS too and is already present.

NEW iOS icon (from the existing source, R3):
- Generate `OneWord/Assets.xcassets/AppIcon.appiconset/icon-ios-1024.png` with a one-off that reuses the script's `lift_artwork()`:
  ```bash
  python3 -c "import sys; sys.path.insert(0,'tools'); import gen_appicon as g; from PIL import Image
  art = g.lift_artwork(Image.open('tools/appicon_source.png'))
  bg = art.getpixel((art.width//2, 8))[:3]                     # the squircle's own body colour
  side = max(art.size); sq = Image.new('RGB', (side, side), bg)
  sq.paste(art, ((side-art.width)//2, (side-art.height)//2), art)
  sq.resize((1024, 1024), Image.LANCZOS).save('OneWord/Assets.xcassets/AppIcon.appiconset/icon-ios-1024.png')"
  ```
  This gives an opaque, square, full-bleed image with no alpha; iOS applies its own mask.
- **Do not run `python3 tools/gen_appicon.py`.** Its `main()` deletes every PNG in the set and rewrites `Contents.json` with different filenames (`:87-104`), which would change the Mac icon.
- MODIFIED `AppIcon.appiconset/Contents.json`: add `{ "filename" : "icon-ios-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }`.
- MODIFIED `tools/gen_appicon.py`: give `main()` the same iOS PNG and `Contents.json` entry, so a future regen keeps the iOS icon. Add a `# ponytail:` note that the Mac filenames on disk predate the script.
- `[Assumption]` A full-bleed crop of the cream squircle reads well under the iOS mask. Check by eye on the simulator Home Screen. **Exit:** hand-export a designed 1024 from the artwork source.

NEW `OneWord/PrivacyInfo.xcprivacy` (joins the app through the synchronized group):
- `NSPrivacyTracking = false`; `NSPrivacyTrackingDomains = []`.
- `NSPrivacyAccessedAPITypes`: one entry, `NSPrivacyAccessedAPICategoryUserDefaults`, with reasons `CA92.1` (app-private `@AppStorage` / standard defaults) and `1C8F.1` (the App Group suite, `AppGroup.swift:35`).
- `NSPrivacyCollectedDataTypes` per `APP_STORE_READINESS_AUDIT.md` F5:
  - Name, Email Address, User ID: linked, App Functionality.
  - Other User Content (feedback text): linked, App Functionality.
  - Other Diagnostic Data: not linked, Analytics.
  - No tracking.

NEW `OneWordWidget/PrivacyInfo.xcprivacy`: `NSPrivacyTracking = false`, plus `NSPrivacyAccessedAPICategoryUserDefaults` with `1C8F.1` and `CA92.1` (`.standard` is the fallback when the group isn't provisioned, `AppGroup.swift:35`). It collects no data. The widget folder isn't synchronized, so add the file through Xcode (File ▸ New ▸ App Privacy, saved in `OneWordWidget/`, target membership **OneWordWidget only**). Xcode writes three entries:
- a `PBXFileReference`
- a `PBXBuildFile`
- an entry in the widget's Resources phase `B456E8B2…` (`:286-299`) and its group (`:168-179`)

Check by eye that `project.pbxproj` gained exactly those.

**Verify (Leaf 1 done-when, together with 1.9 and 1.10):**
```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
for s in check_words check_related check_learned check_capture check_premium check_sentences; do bash tools/$s.sh; done
```
All three should be green. Then:
- One Mac pass by eye through the checks in 1.4–1.7.
- On an iPhone simulator, the app launches to `SignInView` without crashing: Firebase is configured, and the doodle face and Plus Jakarta show (Settings' handwriting switch isn't reachable yet, so check the sign-in title face).
- The icon appears on the Home Screen.

#### 1.9 Platform-neutral copy (M3, operator default)

The default wording is true on both platforms (see the review queue):

| Site | Today | Becomes |
|---|---|---|
| `PremiumView.swift:88-89` | "…on every Mac signed in to your Apple Account." | "…on every device signed in to your Apple Account." |
| `PremiumView.swift:90-92` | "…stay unlocked, on every Mac signed in to your Apple Account." | "…stay unlocked, on every device signed in to your Apple Account." |
| `PremiumView.swift:159` | "A new word every day, on your desktop widget" | "A new word every day, on your widget" |
| `PremiumView.swift:162` | "Works offline — every word is already on your Mac" | "Works offline — every word is already on your device" |
| `PremiumViewModel.swift:127` | "Purchases aren't allowed on this Mac." | "Purchases aren't allowed on this device." |
| `SettingsView.swift:70` | "The app only — the desktop widget follows the Mac's own light or dark." | "The app only — the widget follows the system's own light or dark." |
| `SettingsView.swift:116` | "Applies to the desktop widget too." | "Applies to the widget too." |
| `SettingsView.swift:221` | "No mail app is set up on this Mac. Write to …" | "No mail app is set up on this device. Write to …" |

"Every device signed in to your Apple Account" assumes the non-consumable is shared under universal purchase, which is the expected behaviour for one App Store record `[Inference]`. L4 confirms it with a restore on the simulator.
- **Verify:** Mac build green. `grep -rn '\bMac\b\|desktop' OneWord --include='*.swift'` returns only comments and `#if os(macOS)` code.

#### 1.10 Docs and gate list (m9, version lockstep)

- MODIFIED `CLAUDE.md` ("Verify before saying it's done"): add the iOS Simulator build line, and change the gate loop (`:54`) to include `check_sentences`.
- MODIFIED `Docs/00_Context/PROJECT_CONTEXT.md`: the platform row (`:15`) gains iOS/iPadOS 17; "Not doing (yet)" (`:65`) drops "iOS/iPadOS support".
- MODIFIED `Docs/00_Context/REPO_MAP.md`: add rows for the two `-iOS.entitlements` files and both `PrivacyInfo.xcprivacy` files.
- **Check:** `grep -n 'MARKETING_VERSION\|CURRENT_PROJECT_VERSION' OneWord.xcodeproj/project.pbxproj` shows 1.0 / 1 in all four target blocks. Bump them together from now on, because iOS validation rejects an extension whose version differs from its host's.

### 4.4 Leaves 2–5 (known touchpoints; ground each with its own `/plan` before building)

**L2: the iPhone shell** (locked decision: TabView; Q1: chosen by idiom).
- **The switch.** In `RootView.swift`, under `#if os(iOS)` (with `import UIKit` for `UIDevice.current`, invariant 7): when `UIDevice.current.userInterfaceIdiom == .phone`, `shell` returns a `TabView(selection:)` over `Pane.home, .history, .bookmarks, .search, .profile`. Each tab is a `NavigationStack(path:)` wrapping `detail` for that pane, with `.navigationDestination(for: Pane.self)` so the non-tab panes push. iPad keeps the split view, including in Split View, where `NavigationSplitView` collapses by itself.
- **Non-tab panes.** `HomeView` sets `pane = .dictionaries` (`HomeView.swift:31`) and `ProfileView` sets `pane = .settings` (`ProfileView.swift:367`). The phone shell's selection binding catches a non-tab value and appends it to the active tab's path instead.
- **The sidebar's bottom strip** (account chip, `PlanTag`, feedback button, suggestion card) has no phone home. Profile already has a Settings row (`ProfileView.swift:367`), and Settings already has both feedback buttons (`SettingsView.swift:193`, `:207`). Add two Profile rows in the same idiom:
  - "Practice", gated like the sidebar binding (`RootView.swift:152`);
  - "Plan" → `.premium`.
- **`PaneHeader.swift` on phone:**
  - hide the sidebar toggle;
  - drop `.ignoresSafeArea(.container, edges: .top)` (`:29`) so the strip sits below the status bar;
  - add `.toolbar(.hidden, for: .navigationBar)` **inside `#if os(iOS)`**, since it is macOS-unavailable (m10);
  - the 84pt folded padding (`:86`) is Mac-only;
  - `HeaderSearchField`'s fixed `width: 240` (`:149`) becomes `maxWidth` on phone;
  - raise `HeaderButtonStyle`'s 30×28 minimum (`:104`) to 44×44 on iOS.
- `Pane.launchPane` keeps working for screenshot automation.

**L3: compact layouts.**
- `HistoryView.swift:75` (the 268pt rail beside `WordDetail`) becomes a stacked `ScrollView` on compact width. The month sheet's `frame(560×520)` (`:186`) becomes macOS-only, and iOS gets `.presentationDetents([.medium, .large])`.
- `WordListView` and `LearnedListView` fixed columns (e.g. `LearnedListView.swift:134`, `:173`) become a two-line row on compact width.
- `FeedbackView.swift:35`: `frame(520×430)` becomes macOS-only.
- `SettingsView.swift:326`: the `InfoButton` popover needs `.presentationCompactAdaptation(.popover)` (iOS interface `:28191`).
- `PremiumView`: the `HStack { free; lifetime }` becomes a `VStack` on compact width, through an `AnyLayout` switch.
- `DictionaryPicker` sizes come from the available width; check by eye at 390pt.
- `MonthCalendar` 34×30 cells: raise the touch target on iOS.
- `horizontalSizeClass` is available on macOS too, so no `#if` is needed to compile. L3 decides whether to guard it anyway to keep the Mac path untouched; what macOS returns for it is `[Unverified]`.

**L4: sign-in and purchase live, plus ship.**
- `OneWordApp.swift`: `.onOpenURL { GIDSignIn.sharedInstance.handle($0) }` on iOS `[Unverified for 9.2]`. The URL scheme is already in `Info.plist`.
- Re-check `GIDSignIn.h` in the resolved 9.2.0 checkout (§4.3 step 1.5).
- Outside the repo:
  - the Firebase Apple-app record for `com.hariom.swift.oneword` serves iOS `[Unverified]`;
  - Sign in with Apple is on the App ID (same App ID as the Mac);
  - `StoreKit/OneWord.storekit` is attached to the scheme's Run action.
- Manual matrix: Google, Apple, cancel, sign out, relaunch restores, buy, restore (this confirms universal purchase for the 1.9 copy), losing Premium walks the pick back (`Premium.set(unlocked:)`).
- **Ship (App Store Connect, coverage gap):**
  - add the iOS platform to "One Word: Daily Vocabulary";
  - iPhone 6.9" and iPad 13" screenshots;
  - the iOS App Privacy label (F5 answers);
  - availability: "Designed for iPad" on Mac and Vision is **off** per Q3; confirm the ASC toggles match;
  - review notes: how to add the widget on iPhone;
  - the archive upload, watching for an ITMS-91053 email that names either binary.

**L5: the widget on iPhone.** Expected to need no code: `AppIntentConfiguration`, `Button(intent:)` and the three system families are all iOS 17 APIs. The widget `Info.plist`'s `NSExtensionPointIdentifier` is the same on iOS. Check:
- it appears in the gallery in all three sizes;
- Follow App Settings tracks the app's pick through the `group.` container;
- `RefreshWordIntent` advances;
- the app's `reloadAllTimelines()` calls (`HomeView.swift:56`, `OneWordApp.swift:47`, `DictionaryPicker.swift:220`, `SettingsView.swift:128-129`) reach it.

### 4.5 Data, persistence and API

No model, schema or endpoint changes. On iOS the App Group container is `group.com.hariom.swift.oneword`, a fresh, empty container. Nothing migrates between Mac and iPhone, and no sync exists. Firestore POSTs (`AuthViewModel`, `FeedbackViewModel`) are unchanged and need no iOS entitlement.

### 4.6 Concurrency, state and memory

- **Isolation map: unchanged.** Both targets keep `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Every touched type is main-actor except `AppGroup` and `SavedWords`'s statics, which are `nonisolated` and gain only compile-time `#if`s. No new `actor` and no new `Task`.
- **`OneWordApp.init`** runs on main: Firebase configure, GoogleSignIn configuration, then the iOS audio-session category. It runs once, before any scene.
- **`PresentationAnchor`** (`NSWindow` or `UIWindow`, both main-actor-bound) is read on main and passed into `@MainActor` methods, so no `Sendable` question arises. The existing `Task { await action(window) }` in `SignInView` inherits main. Never move it to `Task.detached`.
- **`AVAudioPlayer`** replaces `NSSound` as a `@MainActor private let` at file scope with the same lifetime. It has no delegate, so no retain cycle.
- **`refusals`** is new view-local `@State` that only drives `.sensoryFeedback`. `shakes` is unchanged.
- **The `openURL` completion** captures nothing that escapes. SwiftUI calls it once, on main.
- **The `PremiumView` cover cache** stays a main-actor `static var`, now holding `Image` instead of `NSImage`.
- **Retain cycles:** none introduced.

### 4.7 Test plan

There is no test target, and this plan doesn't add one (follow-up, §9). Coverage:
- **Gates:** two (`check_words`, `check_related`) compile the real `AppGroup.swift` on its macOS branch. `check_capture`, `check_words` and `check_related` compile `SavedWords.swift` on its macOS branch. All six run in every step's check.
- **Builds:** macOS and iOS Simulator, at the end of Leaf 1.
- **By hand:** the Mac pass in steps 1.4–1.7 and 1.9, the iOS launch in step 1.8, then each leaf's own matrix.
- **Cheap preview (m8):** in `SignInView`'s `#Preview` (`:115-119`), put `.frame(width: 1000, height: 680)` under `#if os(macOS)`, then pick an iPhone device in the canvas. `#Preview` has no `.previewDevice`.
- **Hard to test:** the anchor and sound swaps are view code with no seam. The by-eye passes are the check.

### 4.8 Accessibility, localisation and project mechanics

- **Dynamic Type:** text uses fixed `.system(size:)` and `Font.serif(size)`. Not a Leaf 1 blocker; it is the first follow-up after L3 (F5).
- **Touch targets:** `HeaderButtonStyle` 30×28 (`PaneHeader.swift:104`) in L2; `MonthCalendar` cells in L3.
- **VoiceOver:** new Profile rows and tab items need `.accessibilityLabel`s matching `Pane.title`. Existing labels on the shelf, plan tag and feedback button carry over.
- **`.help()`, `.keyboardShortcut`, `.onHover`, `.textSelection`** all compile on iOS and are harmless. They work on iPad with a pointer or keyboard.
- **Localisation:** no `.xcstrings` exists. Step 1.9 edits literal strings only.
- **Target membership:**
  - the two `-iOS.entitlements` are referenced by build setting only;
  - the app `PrivacyInfo.xcprivacy` joins through the synchronized group;
  - the widget `PrivacyInfo.xcprivacy` needs an explicit reference plus a Resources-phase entry (step 1.8);
  - the icon PNG lives in the asset catalog.
  Nothing moves into or out of `Shared/`, so the widget's explicit references and the gates' paths are untouched.
- **`@available`:** none new. iOS 17 and macOS 14 cover every named API. The existing `#available(macOS 15, *)` for `WindowDragGesture` now sits inside `#if os(macOS)`.
- **Versions:** keep app and widget `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in lockstep (1.0 / 1 today).
- **Signing UI caveat:** capability edits through Xcode's Signing & Capabilities change only the macOS (unconditional) entitlements files.

### 4.9 Decision forks

**Locked by the operator (not reopened):**
- **F1 iPhone shell: `TabView`** (Home, History, Bookmarks, Search, Profile).
- **F2 Capture: deferred.** `WordCapture.swift` is macOS-only. It comes forward when iPhone users ask for "save from Safari".

**Defaulted, the operator may flip (see the review queue for M3/Q1–Q3):**
- **F3 iPad: in, with the Mac layout** (`TARGETED_DEVICE_FAMILY = "1,2"`). Flip to iPhone-only (`= 1`) if iPad screenshots or iPad bugs aren't worth the time before the first iOS release.
- **F4 Lock-screen families: not in L5.** Add `.accessoryRectangular` / `.accessoryInline` once iPhone users exist.
- **F5 Dynamic Type: after L3.** Flip to "inside L3" if accessibility is a release gate.
- **Q1:** pick the phone shell by idiom. **Q2:** `.ambient`. **Q3:** Designed-for-iPad off. **M3:** neutral copy.

### 4.10 Risks and exits

| Risk | Severity / confidence | Leading indicator | Exit |
|---|---|---|---|
| iOS rejects the team-prefixed App Group, or the `group.` id isn't provisioned automatically | High / high that the rule exists | a signing error naming `application-groups` on the first signed iOS build | step 1.3 already splits the id; register `group.com.hariom.swift.oneword` in the portal by hand |
| Conditional `CODE_SIGN_ENTITLEMENTS` ignored by automatic signing | Medium / medium | the iOS build complains about `app-sandbox` or `network.client` | condition the macOS path with `[sdk=macosx*]` and leave the unconditional value empty |
| Another iOS-unavailable API surfaces at step 1.7 | Medium / low (the sweep found none beyond this inventory) | a compile error naming `unavailable in iOS` | gate it `#if os(macOS)` in place; note it in the PR |
| No simulator runtime stops the iOS build | Medium / medium | `xcodebuild` reports iOS 27 not installed | step 1.0 installs it first |
| GoogleSignIn 9.2 changed the iOS presenting signature | Low / low | a compile error at `AuthViewModel.swift:176` on iOS | match the 9.2 header; the seam is one `#if` |
| Google sign-in on iOS needs `onOpenURL` | Medium / medium | tap Google, the browser returns, nothing happens | L4 adds the handler |
| Firebase Apple-app record doesn't cover iOS | Medium / low | `FirebaseApp.configure()` logs a bundle mismatch on iOS | add an iOS app with the same bundle id and regenerate the plist |
| A like-for-like swap regresses the Mac (sound, covers, mail) | Medium / low | the by-eye pass in step 1.6 | each swap is one file; revert that file |
| `openURL`'s completion on macOS doesn't report `false` with no mail handler | Low / medium `[Unverified]` | "No mail app…" never shows on a Mac with no mail client | keep `NSWorkspace.shared.open` under `#if os(macOS)` in `openMail()` |
| iOS icon crop looks off under the mask | Low / medium | by eye on the Home Screen | hand-export a designed 1024 |
| ITMS-91053 on upload (app or appex) | Low / medium | the email after upload names a binary | add the named reason code to that binary's manifest |

### 4.11 Sequencing summary and verification

1. **1.0** Install the iOS 27 runtime. Unblocks the iOS check.
2. **1.1** Project platforms, Q3 settings, `REGISTER_APP_GROUPS`, Cocoa removal. Mac green; iOS fails only on Swift errors.
3. **1.2** Entitlements split. iOS signing passes.
4. **1.3** `AppGroup` id and `SavedWords` `#if os(macOS)` (B1). Gates green.
5. **1.4** App entry, capture gate, `.ambient` session (M1). Mac sign-in restore and Services still work.
6. **1.5** Sign-in anchor (m6). Mac Google and Apple sign-in unchanged.
7. **1.6** Swaps, with the haptic kept on the Mac (m3). Mac by-eye pass.
8. **1.7** `PaneHeader` gates and the optional `List` selection (B2). **iOS compiles.**
9. **1.8** Fonts, iOS icon, both privacy manifests (M2). iOS launches to `SignInView`.
10. **1.9** Platform-neutral copy (M3).
11. **1.10** `CLAUDE.md` (iOS line, `check_sentences`), `00_Context` docs, version check.
12. Then **L2 → L3 → L4**, with **L5** in parallel after L1, each through its own `/plan`.

**First reversible move:** step 1.1 (project file only; `git checkout -- OneWord.xcodeproj` undoes it).

**End-to-end confirmation for the program:**
- Both `xcodebuild` lines and the six gates are green.
- On an iPhone simulator: sign in with Google; see today's word; switch to Emotions from Home's chip; search "stab" and bookmark it; buy Premium from the local StoreKit file, then restore; open Practice from Profile; confirm the flip doesn't stop music playing in the background; add the medium widget and see it follow the pick.
- On the Mac: the same pass, plus "Save to One Word" from TextEdit.

### 4.12 Open questions and assumptions

- `[Unverified]` iOS App Groups must start with `group.`. Resolved by the first signed iOS build.
- `[Unverified]` `REGISTER_APP_GROUPS = YES` registers the `group.` id automatically. Resolved by the first signed iOS build.
- `[Unverified]` GoogleSignIn 9.2.0 keeps `signIn(withPresenting: UIViewController)` on iOS and still needs `handle(url)`. Resolved by opening `GIDSignIn.h` in the resolved 9.2.0 checkout.
- `[Unverified]` One `GoogleService-Info.plist` serves iOS for the same bundle id. Resolved by the first iOS `FirebaseApp.configure()` log.
- `[Unverified]` An embedded `.appex` is checked for its own privacy manifest. It's moot either way, since step 1.8 ships one.
- `[Unverified]` The macOS `openURL` completion reports `false` with no mailto handler. Resolved by a Mac with no default mail client.
- `[Inference]` `.ambient` also governs `AVSpeechSynthesizer`, because `usesApplicationAudioSession` defaults to true (iOS `AVSpeechSynthesis.h:263`). Resolved by tapping Pronounce with the silent switch on.
- `[Inference]` SE-0308 postfix `#if` compiles in the `Scene` chain (the audit's reading). The exit is in step 1.4.
- `[Inference]` Universal purchase shares the non-consumable across platforms, which makes the 1.9 copy true. Resolved by the L4 restore on the simulator.
- `[Assumption]` The full-bleed crop of `appicon_source.png` reads well as an iOS icon. Resolved by eye.
- `[Assumption]` The onboarding plan (built for 1000×680) gets re-planned after L3 rather than built on compact width as it stands.

## 5. Operator review queue

These four decisions use the recommended default. Accept or override each one.

| # | Decision applied | Why it's recommended | Alternative | Flips if |
|---|---|---|---|---|
| **Q1** | L2 picks the iPhone TabView by `UIDevice.current.userInterfaceIdiom == .phone` | A Pro Max in landscape reports regular width and would otherwise get the Mac split view. An iPad in Split View keeps the split view, which collapses on its own. | key on `horizontalSizeClass == .compact` alone | you want iPad Split View / Slide Over to show the iPhone tabs |
| **Q2** | `AVAudioSession` category `.ambient` for everything (step 1.4) | One line. The flip and roll don't stop the user's music, and everything respects the silent switch, which suits a quiet vocabulary app. | `.playback` (or `.playback` + `.spokenAudio`) for pronunciation only, switching category around `speaker.speak` (`WordDetail.swift:326`) | muted iPhones should still say the word aloud |
| **Q3** | `SUPPORTS_MACCATALYST`, `SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD` and `SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD` all `NO` on the app target (step 1.1) | The native Mac app already exists. An iPad build on Mac would duplicate it, and Vision isn't tested. | leave them on (Xcode's default) | you want Vision Pro users to get the iPad build |
| **M3** | One platform-neutral string per site ("device", "widget"), shown on both platforms (step 1.9, 8 strings) | One body per site, no `#if`, and the wording stays true on the Mac once purchase is universal. | `#if os(macOS)` per-platform strings that keep the Mac wording exactly as it is | you want zero visible change on the Mac, invariant 4 read literally |

## 6. Remaining / deferred

Nothing from the audit is deferred. These items stay open by nature, and each closes on the fact named in §4.12:
- **Signing behaviour** (App Group provisioning, conditional entitlements): settled by the first signed iOS build.
- **GoogleSignIn 9.2 on iOS:** settled by the resolved header (step 1.5 / L4).
- **Firebase iOS coverage:** settled by the first iOS launch.
- **The macOS `openURL` failure branch:** settled by a Mac with no mail client.
- **Icon appearance:** settled by eye.

Leaves 2–5 still need their own `/plan` runs. Their touchpoints above reflect the code before Leaf 1 and will shift once it lands.
