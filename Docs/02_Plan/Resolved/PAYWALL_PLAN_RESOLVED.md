# Paywall: Resolved Plan

## 1. Header

**What this resolves**
- **Audit:** `Docs/02_Plan/Audit/PAYWALL_PLAN_AUDIT.md` ("Plan audit: PAYWALL_PLAN"). Verdict: *Ready to build*. No blockers. Majors M1–M4, minors m1–m15, four coverage gaps, operator questions Q1–Q7.
- **Plan:** `Docs/02_Plan/PAYWALL_PLAN.md` ("Paywall: Plan"). It is 551 lines on disk, and its harness footer is already stripped. This pass did not modify it.
- **Goal brief:** `/private/tmp/claude-501/-Users-hariom-Desktop-One-Word/ad09efae-44c3-4a4e-a3a9-123bc838e427/scratchpad/plan-paywall-brief.md`. It quotes the operator verbatim.
- **Resolver brief:** `…/scratchpad/plan-resolver-paywall-brief.md`. It carries the operator's live answers to Q1, Q2 and Q7. Those answers are final.

**Paths.** All paths are relative to `/Users/hariom/Desktop/One Word`, on `release/1.1.0` @ `9c0bdf9`. The working tree has no code changes. Line numbers are as of that commit, and the symbol named beside each citation is the anchor that lasts.

**One shape change since the audit.**
- The operator answered Q1 as reading (c): on the Mac, the paywall is **its own window**.
- The audit's §9 said that answer moves Steps 4–5 toward partial rework. This resolution does that rework: Steps 4–5 are re-planned around a `Window` scene, grounded in the Xcode 27 SDK interfaces.
- Steps 1–3 and 6 keep their shape.
- I see nothing here that warrants returning to `/plan`.

### Stack, re-grounded

| Aspect | Finding | Evidence |
|---|---|---|
| Build | One `.xcodeproj` with an app target and a widget target. Synchronized groups, except `OneWord/Shared/`, which is referenced by explicit path. | `CLAUDE.md`; `REPO_MAP.md:29` |
| Platforms | iOS 17 and macOS 14 (project level, inherited by the app). Device family `1,2`. | `project.pbxproj:463,465` (Debug), `:523,525` (Release), `:578` (app) |
| Toolchain | macOS 27 SDK installed (`MacOSX27.0.sdk`). Every new API below was checked against its `.swiftinterface` / `.swiftdoc`. | `/Applications/Xcode.app/…/SDKs/` |
| Concurrency | Swift 5 mode. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, approachable concurrency, `MEMBER_IMPORT_VISIBILITY = YES`. No strict-concurrency setting. | `project.pbxproj:573-577` (app Debug) |
| Architecture | MVVM. View models are `@Observable` and never import SwiftUI. `PremiumViewModel` is the one StoreKit owner, app-owned and injected. | `PremiumViewModel.swift:5-19`; `OneWordApp.swift:35,85` |
| Scenes | One `WindowGroup`, with Mac-only `.defaultSize(1000×680)` and `.windowStyle(.hiddenTitleBar)`. There is no `Window` / `openWindow` anywhere yet (grep). | `OneWordApp.swift:80-103` |
| Persistence | UserDefaults and the App Group. `Premium.set` writes only when `Features.premium` is on. | `PremiumViewModel.swift:126-129`; `Features.swift:13` |
| Tests | No XCTest target. Headless `swiftc` harnesses: `check_premium.sh` compiles `Shared/Premium.swift` by path. | `tools/check_premium.sh:98-102` (Premium at `:101`) |
| Asset catalog | **`OneWord/Assets.xcassets`** is the only catalog. Generated symbols are on: `learned_icon` becomes `.learnedIcon`. | `find`; `project.pbxproj:414,480`; DerivedData `GeneratedAssetSymbols.swift:89` |
| Previews | Every view file ends in a `#Preview` that injects its view models | `PremiumView.swift:465-469`; `FeedbackView.swift:136-139` |

### Files and symbols opened in this pass

| File | Lines |
|---|---|
| `~/.claude/agents/plan-resolver.md`; `~/.claude/agents/ios-planner.md` | all; 28–107 |
| Both briefs, the audit, the plan | all |
| `OneWord/OneWordApp.swift` | 1–104 |
| `OneWord/ViewModels/PremiumViewModel.swift` | 1–140 |
| `OneWord/Views/PremiumBar.swift` | 1–131 |
| `OneWord/Views/ProfileView.swift` | 1–240, 440–569, 630–700 |
| `OneWord/Views/PremiumView.swift` | 20–135, 240–256, 380–446, 465–469 |
| `OneWord/Shared/Premium.swift` | 1–54 |
| `OneWord/Shared/Theme.swift` | 1–45, 90–110, 150–172 |
| `OneWord/Views/FeedbackView.swift` | 1–70, 115–139 |
| `OneWord/Views/DictionaryPicker.swift` | 185–240 |
| `OneWord/Views/HomeView.swift` | 28–34, 145–170, 226–240 |
| `OneWord/Views/RootView.swift` | 140–160, 178–218, 240–270 |
| `OneWord/Views/SyncToast.swift`, `PaneHeader.swift` | 44–54; 15–26 |
| `OneWord/WordRefreshShortcut.swift` | 1–60 |
| `OneWord/Models/Features.swift`, `Wordbook.swift`, `DoodleTheme.swift` | all; 50–58; 56–60 and 160–167 |
| `OneWord/Shared/SavedWords.swift`, `OneWord/WordCapture.swift`, `OneWord/ViewModels/FeedbackViewModel.swift` (and `feat/website`'s copy) | grep |
| `tools/check_premium.sh` | 1–30, 60–104 |
| `StoreKit/OneWord.storekit` | grep (`:16,21,92,99,114,121`) |
| `OneWord.xcodeproj/project.pbxproj` | grep, plus 534–540, 578–584 |
| `OneWord/Assets.xcassets/` | tree, plus `Dictionary_of_EverydayEnglish.imageset/Contents.json` |
| `Docs/00_Context/REPO_MAP.md`, `ARCHITECTURE.md`, `Docs/README.md` | 24–56; 118–150 and 184–196; 140–175 |
| `Docs/02_Plan/CAT_UI_PLAN.md`, `Resolved/WEBSITE_PLAN_RESOLVED.md` | 116–132 plus grep; grep |

**SDK interfaces checked (Xcode 27):**
- `SwiftUI` macOS `.swiftinterface`:
  - `SceneBuilder`, `22591-22652`: only `buildOptional` and `buildLimitedAvailability`; there is **no `buildEither`**.
  - `Window`, `32753-32774`: macOS 13, iOS-unavailable.
  - `openWindow`, `3777-3801`: iOS 16 / macOS 13.
  - `dismissWindow`, `30540-30550`: macOS 14.
  - `commandsRemoved`, `23654`: macOS 13.
  - `restorationBehavior`, `279`: macOS **15**.
  - `defaultLaunchBehavior`, `11543`: macOS 15.
  - `windowResizability` / `WindowResizability`, `600-625`: macOS 13.
  - `presentationDetents` / `presentationDragIndicator`, `28575-28581`.
  - `presentationBackground`, `31093-31095`.
- `SwiftUI` `.swiftdoc`:
  - `Window`: `openWindow` brings an open window to the front, and `dismiss` closes the window "from within the window's view hierarchy" but not from a sheet presented inside it.
  - `commandsRemoved`.
  - `.levelChange`: "Only plays feedback on macOS".
- `SwiftUICore` `.swiftdoc`:
  - `.success`: "iOS and watchOS".
  - `.alignment`: "iOS and macOS".
- `_StoreKit_SwiftUI` macOS:
  - `manageSubscriptionsSheet` is `@available(macOS, unavailable)` (`278-283`).
  - `\.purchase` is macOS 14 (`1580-1582`).
  - `PurchaseAction`'s doc says only "for a given Environment".
- `StoreKit` macOS: `Product.purchase(options:)`, `@MainActor`, macOS 12 (`2700-2702`).

---

## 2. Resolution summary

| Resolution type | Count | Findings |
|---|---|---|
| **Self-resolved** (code- or fact-dictated) | 21 | M1, M2, M3, M4 (text), m1–m6, m8–m15, G1, G2, G4 |
| **Operator decision, final** (answered live, applied) | 3 | Q1, Q2, Q7 |
| **Operator decision, recommended default applied** (review queue) | 5 | Q3, Q4, Q5, Q6, G3 (same as Q5) |
| **Not a defect** | 0 | none |
| **Deferred** | 1 | m7 (tied to Q5); one sub-item of m15 also deferred |

**Build readiness now:**
- No blockers.
- The M1–M3 plan-text fixes are applied. Q1's Mac window is planned and grounded.
- Five review-queue items await the operator, and none of them blocks the build.
- **Release** stays gated on:
  - true perk copy (F10),
  - the Step 0 App Store Connect work,
  - one sandbox/TestFlight pass.

---

## 3. Resolution log

**M1 · Major · Self-resolved.** Step 4 removed the owner's Profile branch before Step 6 replaced it.
- Re-grounded: `plans(t)` renders for everyone (`ProfileView.swift:76`), and the `owned` branches are at `:489-497`.
- Change:
  - Step 4 now touches `plans` only to pass `open:` to the existing `UnlockButton` at `:498`. `owned` stays.
  - Step 6 removes `owned` and adds the body swap in **one** commit.
  - Step 4's verify now reads "Profile flips to the old owned cards (Premium tagged Current, no pill)". That is true while `owned` survives.

**M2 · Major · Self-resolved.** Asset paths.
- Re-grounded: `find` returns only `OneWord/Assets.xcassets`.
- Change: every asset path is now `OneWord/Assets.xcassets/Cat/Poses/cat_{cushion,cafe}.imageset/`, with folder `Contents.json` at `…/Cat/` and `…/Cat/Poses/`.

**M3 · Major · Self-resolved.** Art sequencing.
- Change:
  - The PNG fetch is now a **prerequisite of Step 3**, done by the build session from the operator's artifact before Step 3. It is no longer a release-only item.
  - Step 4 states the fallback outright: without the PNGs, land Steps 4–5 without the two `Image(.cat…)` overlays and without `Breathe`, and add them with Step 3 later.
- Grounding: D8's generated symbols make a missing asset a compile error (`project.pbxproj:414,480`).

**M4 · Major · Self-resolved (text), and Q2/Q3 for the product part.**
- (a) Perks on the paywall: the operator answered Q2 with **both surfaces**, so the list stays on the paywall and the gold card. F10's release gate is kept.
- (b) R1's exit is rewritten. "Lifetime only" is no longer called "config-only". It is spelled out as a two-line `Features` flag that filters `load()`'s ids. Whether to build that flag now is Q3, recommended default "not now".
- (c) Step 0 now requires true IAP display names and descriptions. Today's copy says "Every dictionary, unlocked for good" and "…renewed each year/month" (`OneWord.storekit:21,99,121`), which is untrue while every shelf is free (`Premium.swift:28`).

**m1 · Minor · Self-resolved (verified already applied).** `PAYWALL_PLAN.md` is 551 lines, and grep finds no `agentId` or `<usage>`.

**m2 · Minor · Self-resolved.** Citations corrected:
- `check_premium.sh:98-102`, with `Premium.swift` at `:101`.
- The app's build settings are at `project.pbxproj:573-578`, and the deployment targets at `:463,465`. The old `:363` and `:371` lines were the widget's.

**m3 · Minor · Self-resolved.** Pick one Mac haptic mechanism on purpose.
- Chosen: `.sensoryFeedback`, with `.levelChange` on macOS and `.success` on iOS. Each value plays on its platform per the swiftdocs cited in §1.
- The repo precedent `NSHapticFeedbackManager … .generic` (`DictionaryPicker.swift:232-237`) exists because `.error` has no Mac rendering (`:194-195`). `.levelChange` does have one, so one modifier covers both platforms.
- Whether to keep a Mac haptic at all is Q4.

**m4 · Minor · Self-resolved.** `crown.fill` exists, per the audit's `name_availability.plist` check, so the fallback symbol is dropped.

**m5 · Minor · Self-resolved.** The celebration now bumps only `if isUnlocked` after `handle`'s `refresh()`, and §6's timing claim is softened. Grounding: the generation guard is at `PremiumViewModel.swift:81`.

**m6 · Minor · Self-resolved.** Every custom-drawn `Button` in the paywall and on the gold card uses `.buttonStyle(.plain)`, matching `PremiumBar.swift:117` and `ProfileView.swift:169,202,225`.

**m7 · Minor · Deferred.** Someone who owns both a subscription and Lifetime would be labelled "Subscription".
- That state can't be reached in-app: owners never see the paywall, and Q5's default adds no upgrade.
- It resolves together with Q5: add a `lifetime` flag beside `subscribed` and prefer it in the label.

**m8 · Minor · Self-resolved.** `UnlockButton.open` is declared after `verb`, so the memberwise order matches `UnlockButton(name:verb:open:)`. Grounding: `PremiumBar.swift:73-77`.

**m9 · Minor · Self-resolved.** The iPad layout is stated outright: a form sheet with stacked cards (`#if os(macOS)` is false) and Mac-sized controls (`isPhone` is false, `PaneHeader.swift:20-24`). It is checked by eye.

**m10 · Minor · Self-resolved.**
- `.tint(t.accent)` goes on the paywall root, because Midnight's tint (`RootView.swift:214`) reaches into an iOS sheet.
- Grabber visibility on Midnight is now an explicit Step 4 check, with an exit (R13).

**m11 · Minor · Self-resolved (superseded by Q1).** The Mac paywall is now its own fixed-size window, so it can no longer be larger than the main window.

**m12 · Minor · Self-resolved.** Step 5's check says outright that confetti falls inside the iPhone sheet, which matches the board, and across the whole Premium window on the Mac.

**m13 · Minor · Self-resolved.** The `ponytail:` comment on `Premium.savings` names the trade: the math is app-only but sits in `Shared/` so it rides `check_premium.sh:101`.

**m14 · Minor · Self-resolved.** The restore check moves to the sandbox/TestFlight pass. An existing local transaction unlocks at launch (`PremiumViewModel.swift:61`), so the free paywall never shows locally. Under Q7 the check now expects the **celebration**.

**m15 · Nits · Self-resolved, one part deferred.**
- (1) Step 7 writes the README dossier line with the state at that commit, not "planned, not built". Its verify grep now includes `Docs/README.md`, which is not under `00_Context`.
- (2) The free pill's VoiceOver label is unchanged, and the hint "Shows the plans" tells VoiceOver users that it opens plans (Q6).
- (3) The duplicated privacy URL is **deferred** until `feat/website` merges. `FeedbackViewModel.privacyPolicy` exists only there (`git show feat/website:…FeedbackViewModel.swift:31`). A `ponytail:` comment marks the swap.

**G1 · Coverage gap · Self-resolved.** One sandbox/TestFlight pass before submission is now in Step 0 and in matrix row 8. It covers:
- a purchase from the Mac Premium window (R2),
- renewal and expiry,
- the Q7 restore celebration.

**G2 · Coverage gap · Self-resolved.** IAP metadata accuracy is in Step 0 (see M4c).

**G3 · Coverage gap · Operator decision (default applied).** Subscriber-to-Lifetime upgrade is the same item as Q5.

**G4 · Coverage gap · Self-resolved.** `PaywallView` ends in a `#Preview` with `.environment(PremiumViewModel())`, mirroring `PremiumView.swift:465-469`. Step 3's symbol check now greps the generated file instead of relying on a preview.

**Q1 · Operator decision, final (answered live).** On the Mac, the paywall is **its own `Window` scene**, opened with `openWindow(id:)`. The thank-you is a modal inside that window. iPhone keeps an expandable bottom sheet, and iPad gets a sheet.

Each cost the plan named is resolved and grounded:
- **Re-injection.** Only `PremiumViewModel` is injected, because it is the only environment value the paywall reads.
  - `\.doodle` is not read, and it defaults to `.off` (`DoodleTheme.swift:160-161`).
  - The colour scheme is forced to light inside the view, so the reader's scheme is not needed.
  - `.preferredColorScheme` is avoided because it may reach beyond this window and fight `OneWordApp.swift:90` `[Inference]`.
- **Window menu.** `.commandsRemoved()` (macOS 13) removes the scene's default commands. That the Window-menu entry is among them is `[Inference]`, and it is checked in Step 4. The removal itself is review item RQ5.
- **Restoration.** `restorationBehavior` is macOS 15+, and `SceneBuilder` has no `buildEither`. So an `if #available(macOS 15, *)` block would **drop the window entirely on macOS 14**. Restoration is therefore accepted on every OS with a `ponytail:` note, and the window's content reloads products if it comes back alone.
- **Purchase from the second window.** `\.purchase` is per-environment (macOS 14). That StoreKit's confirmation presents from the Premium window is `[Unverified]` and checked in Step 4 (R2). The exit is `Product.purchase(options:)` (StoreKit, `@MainActor`, macOS 12).
- **After purchase.** The thank-you is an in-window overlay, not a `.sheet`. That way `dismiss()` on Done closes the **window**, which per the `Window` swiftdoc would not happen from a sheet.

**Q2 · Operator decision, final.** The mock perks show on both the gold card and the paywall, from one list (`PaywallView.perks`). F10's release gate is kept.

**Q3 · Operator decision (default applied).**
- Default: build no kill switch now. Replacing the mock perks with true statements remains the gate for submitting (F10).
- R1 spells out the flag as the exit.

**Q4 · Operator decision (default applied).** Keep the Mac haptic (`.levelChange`), and accept that it's felt only with a finger on a Force Touch trackpad.

**Q5 · Operator decision (default applied).** No subscriber-to-Lifetime path in this change.

**Q6 · Operator decision (default applied).** The free pill stays visually unchanged ("Buy — $169.99") and gains a VoiceOver hint.

**Q7 · Operator decision, final.** A Restore inside the paywall that flips ownership from false to true gets the **full celebration**: confetti, the Premium Club entrance, haptic and announcement.
- This is implemented in `restore()`, and the counter is renamed `celebrations`.
- Launch and `Transaction.updates` never bump it. Both run `refresh()` only (`PremiumViewModel.swift:38-43,61`).

---

## 4. The resolved plan

This plan adds three things:
- a **paywall** that sells Monthly and Yearly in one card with a corner toggle, plus a Lifetime card;
- a **golden Premium card** on Profile for owners;
- a **celebration**: confetti, "Welcome to the Premium Club", and a haptic.

The paywall is **its own window on the Mac** and an **expandable bottom sheet on iPhone**; iPad gets a form sheet. Purchases go through StoreKit 2 with no sign-in. Nothing is gated: `Features.premium` stays `false`. A free reader's Profile looks the same as today.

> **Upstream.** There is no strategy doc, so this plan is weaker than one built on a strategy. The inputs are the operator's own words and the Claude Design canvas "Pencil Cat Mascot" (boards MacPremium, PhonePremium, MacPremiumThanks, PhonePremiumThanks). The canvas is inspiration, not a pixel spec. These docs are honoured and not relitigated: `Docs/02_Plan/Resolved/PREMIUM_PLAN_RESOLVED.md`, `Docs/02_Plan/CAT_UI_PLAN.md` (§3.0, §3.6, §4, and §5's breathe spec), and `Docs/02_Plan/Resolved/ONBOARDING_PLAN_RESOLVED.md`. Its `PlanPair` is not built, and nothing here depends on it.
>
> **Scope shape.** This is a **single change**: seven ordered commits plus operator Step 0. Every step builds green on both platforms. The pieces land, get verified and revert together.

### 4.1 Scope & outcome

**Done when:**
1. **Free Profile.**
   - It looks as it does today. The only visible difference is the price inside the existing "Buy" pill: $169.99, per StoreKit.
   - Tapping the pill opens the paywall instead of buying Lifetime outright.
2. **Placement.**
   - **Mac:** a "Premium" window, 760×600, with a hidden title bar. It opens from Profile's pill, and a second tap brings it to the front.
   - **iPhone:** a bottom sheet with a grabber, `.medium` dragging to `.large`.
   - **iPad:** a form sheet.
3. **Content.**
   - A fan of covers, a serif title, and the perks list.
   - A **subscriptions card**: Monthly/Yearly via a corner toggle, the price plus its period, "Save N%" computed from the two Products, a renewal line, and Subscribe.
   - A **Lifetime card**: the price plus "once", Buy, and the cushion cat breathing in its corner.
   - Restore Purchase, Terms of Use and Privacy Policy links, and any problem line.
   - Every price is StoreKit's `displayPrice`.
4. **Celebration.** A completed purchase, or a Restore inside the paywall that unlocks (Q7), shows the thank-you:
   - "PREMIUM", **"Welcome to the Premium Club"**, body copy, Done, and the café cat breathing.
   - Confetti falls, a haptic fires, and VoiceOver announces the headline.
   - **Mac:** a centred modal over the dimmed plans, inside the Premium window. Done closes the window.
   - **iPhone:** the sheet becomes the thank-you at 584pt.
   - Launch and `Transaction.updates` never celebrate.
5. **Owner's Profile.** In place of the plan cards, a **golden Premium card**. Tapping it expands the mock perks, and a subscriber also gets "Manage Subscription".
6. **Nothing is gated.** `Features.premium` stays `false`, and `Premium.free`, `allows` and `set` are unchanged.

**In scope:**
- Loading all three products and the `.storekit` price edits.
- The two cat PNGs.
- One new view file (`PaywallView.swift`).
- Edits to `PremiumViewModel`, `Premium`, `PremiumBar`, `PremiumView`, `ProfileView` and `OneWordApp`.
- One extended gate, and the `00_Context` and README docs.

**Out of scope:**
- The Cat UI theme.
- Gating anything, sign-in, intro or offer codes.
- Redesigning `PremiumView` / `Pane.premium`, which stays dormant.
- The sidebar `PlanTag`.
- A website terms page (Apple's standard EULA applies, `WEBSITE_PLAN_RESOLVED.md:81`).
- A subscriber-to-Lifetime upgrade (Q5).

### 4.2 Architecture fit

There is one new View file plus small edits, and no new view model. `PremiumViewModel` stays the one StoreKit owner (`PremiumViewModel.swift:5-11`; `ARCHITECTURE.md:130-132`).

| Type / file | Layer, target | Responsibility | Mirrors |
|---|---|---|---|
| `PaywallView` **NEW** (`OneWord/Views/PaywallView.swift`) | Views, app | The paywall: offers, then the thank-you (a modal on the Mac, a swap on iOS). Holds `static let perks` (the one mock list) and `static let windowID`. | `FeedbackView` (two states, one surface, `FeedbackView.swift:31-38`); `PremiumView` cards and perks (`:383-398,421-435`) |
| `Confetti`, `Piece` (private, same file) | Views | A `KeyframeAnimator`-driven `Canvas` burst keyed on an `Int` | `HomeView.ribbonDrop` (`HomeView.swift:164-170`); `nonisolated struct DoodleTheme` (`DoodleTheme.swift:58`) |
| `Breathe` (private, same file) | Views | The cats' idle: `phaseAnimator`, still under Reduce Motion | `CAT_UI_PLAN.md` §5 |
| `extension Theme { static let cat }` (same file) | Views, app only | The canvas's light Cat page | `Theme.umber` (`Theme.swift:93-103`); values from `CAT_UI_PLAN.md:120-131` |
| `OneWordApp` *MODIFIED* | App root | Adds the Mac-only `Window("Premium", id:)` scene | Apple's `Window` doc example (SwiftUI swiftdoc) |
| `PremiumViewModel` *MODIFIED* | ViewModels | Adds `products`, `product` as a computed lifetime, `subscribed`, and `celebrations` | itself |
| `Premium` *MODIFIED* | Shared (app + widget) | Adds `yearlyID`, `monthlyID` and `savings(yearly:monthly:)` | itself |
| `UnlockButton` *MODIFIED* | Views | Adds `open:`; `buy` becomes `static`, shared with the paywall | itself (`PremiumBar.swift:71-131`) |
| `PremiumView.fan` *MODIFIED* | Views | Becomes `static func fan(_:height:scale:)` | itself (`:116-132`) |
| `ProfileView` *MODIFIED* | Views | The pill opens the paywall (window or sheet); owners get `premiumCard` | `plans` / `planCard` (`:483-529`) |
| Assets **NEW** | `OneWord/Assets.xcassets/Cat/Poses/cat_{cushion,cafe}.imageset` | Two cat drawings in the 1x slot | `Dictionary_of_EverydayEnglish.imageset/Contents.json` |

**Native option considered.** StoreKit's `SubscriptionStoreView` was rejected:
- The locked layout (one card toggling two subscriptions, plus a Lifetime card, plus the cat) doesn't map onto its styles.
- It can't hold the non-consumable.

It stays R1's fallback.

#### Decisions the code made

| # | Decision | Forced by |
|---|---|---|
| D1 | Extend `PremiumViewModel`; add no `PaywallViewModel`. | "The app's one StoreKit owner" (`PremiumViewModel.swift:5`) |
| D2 | `products: [String: Product]`. `product` stays as a **computed** lifetime. | `PremiumBar.swift:88`, `PremiumView.swift:222,226` read `premium.product` and then compile untouched |
| D3 | The celebration signal is `celebrations: Int`. It is bumped in `handle`'s `.success(.verified)` arm when `isUnlocked` after its refresh, and in `restore()` when ownership went from false to true (Q7). | `refresh()` is shared by launch (`:61`), `Transaction.updates` (`:38-43`) and restore (`:119`), so it can't tell them apart. `handle` has one caller (`PremiumBar.swift:125`). It is an Int because of trigger semantics, as with `kept` (`HomeView.swift:32,149`). |
| D4 | Confetti, haptic and announcement go on the paywall's **root**. | The thank-you is inserted in the same update in which the counter changes, so a trigger inside it would read the new value as its initial one. `KeyframeAnimator(trigger:)`, `.sensoryFeedback(_:trigger:)` and `onChange` without `initial:` all skip their initial value. |
| D5 | Buying stays on `@Environment(\.purchase)` → `premium.handle`. `UnlockButton.buy` becomes `static`. | The VM must not import SwiftUI (`PremiumViewModel.swift:8-9`). |
| D6 | `storeUnavailable` keeps meaning "lifetime didn't load". The paywall derives each card's availability itself. | The free Profile's note and pill read it (`ProfileView.swift:490`, `PremiumBar.swift:91`). |
| D7 | `plans(t)` renders only for non-owners **from Step 6**, which is when `owned` goes (M1). | `ProfileView.swift:76,489-497` |
| D8 | The cats are referenced through generated symbols (`Image(.catCushion)`). | Symbols are on (`project.pbxproj:414,480`). A missing asset fails the build. |
| D9 | The cats live under `OneWord/Assets.xcassets/Cat/Poses/`. | `CAT_UI_PLAN.md:327` names `cat_cushion` there. |
| D10 | Manage Subscription: iOS uses `.manageSubscriptionsSheet`; the Mac uses `openURL`. | The sheet is `@available(macOS, unavailable)` (`_StoreKit_SwiftUI` macOS `278-283`). |
| D11 | `savings` lives in `Shared/Premium.swift`. | `check_premium.sh:101` compiles it already. It is pure Foundation. |
| D12 | `PremiumView` / `Pane.premium` stay dormant; only `fan` is made reusable. | They are unreachable while `Features.premium` / `practice` are off (`RootView.swift:240-247`; `Features.swift:13,15`). |
| D13 | Cards sit side by side on the Mac (`#if os(macOS)`) and stack on iOS. iPad stacks with Mac-sized controls (m9). | An iPad form sheet is narrow `[Inference]`. `PremiumView.swift:55-56` notes `ViewThatFits` mis-sizing. |
| D14 | **Mac: a `Window("Premium", id: PaywallView.windowID)` scene** (Q1), with `.windowStyle(.hiddenTitleBar)`, `.windowResizability(.contentSize)` and `.commandsRemoved()`. Only `premium` is injected, and restoration is accepted. | `Window` is macOS 13+ and iOS-unavailable. `openWindow` brings an open window forward. `restorationBehavior` is macOS 15, and `SceneBuilder` has no `buildEither` (swiftinterface `22591-22652`). |
| D15 | The Mac thank-you is an **overlay modal** inside the window, not a `.sheet`. | `dismiss` closes the window only when it is called outside a presented modal (`Window` swiftdoc). An overlay also keeps D4's root triggers over it. |

### 4.3 Implementation steps

#### Step 0: App Store Connect and release prerequisites *(operator; runs in parallel; gates release, not the build)*

**Prices** (USD base, other storefronts equalized):

| Product | id | Price |
|---|---|---|
| Lifetime | `com.hariom.swift.oneword.premium` | 169.99 |
| Yearly | `com.hariom.swift.oneword.premium.yearly` | 149.99 |
| Monthly | `com.hariom.swift.oneword.premium.monthly` | 14.99 |

**Before submission:**
- Set each subscription's price before its first approval (R8).
- Subscription group "Premium": add a display-name localization.
- Add an App Review screenshot of the paywall for each IAP.
- Attach all three IAPs to the version.
- **Make the IAP display names and descriptions true for this release.** The current copy, "Every dictionary, unlocked…", is untrue while every shelf is free (`Premium.swift:28`). Mirror the final strings into `StoreKit/OneWord.storekit:21,99,121`.
- **Replace `PaywallView.perks` with true statements** (F10 / R1). The operator owns this, and it gates submitting the subscriptions.
- **One sandbox/TestFlight pass** (§4.7, matrix row 8).

**Metadata:**
- Privacy Policy URL: `https://one-word-a2f3a.web.app/privacy` (`WEBSITE_PLAN_RESOLVED.md:93,311`).
- Terms of Use: Apple's standard EULA, linked in the App Description.
- `site/` exists only on the unmerged `feat/website` branch. Before submission, `curl -sI https://one-word-a2f3a.web.app/privacy` should print 200 (R9).

#### Step 1: Prices, ids and savings math *(the first reversible move; nothing calls it yet)*

| File | Change |
|---|---|
| `StoreKit/OneWord.storekit:16,92,114` MODIFIED | `displayPrice` becomes `"169.99"`, `"149.99"` and `"14.99"`. |
| `OneWord/Shared/Premium.swift:20-23` MODIFIED (Shared) | `static let yearlyID = "com.hariom.swift.oneword.premium.yearly"`, `monthlyID = "…premium.monthly"`; `productIDs = [productID, yearlyID, monthlyID]`. Same strings. |
| `OneWord/Shared/Premium.swift` MODIFIED | `static func savings(yearly: Decimal, monthly: Decimal) -> Int?` |
| `tools/check_premium.sh` heredoc MODIFIED | A "yearly savings" block of four checks (§4.7) |

How `savings` works:
- It computes `(1 − yearly / (monthly × 12)) × 100` in `Decimal`, rounded with `NSDecimalRound(…, 0, .down)`.
- It returns `nil` when `monthly ≤ 0` or the result is ≤ 0.
- Its comment: `// ponytail: rounds down so the chip never overstates. App-only math in a Shared file (the widget compiles it unused) because check_premium.sh:101 already compiles this file; its own file would need its own gate wiring.`

- **Isolation:** `nonisolated enum`, unchanged. Pure.
- **Verify:** `bash tools/check_premium.sh` passes, including the new block, and both `xcodebuild` builds pass.

#### Step 2: StoreKit plumbing *(no UI change)*

**`OneWord/ViewModels/PremiumViewModel.swift` MODIFIED:**

```swift
private(set) var products: [String: Product] = [:]          // replaces stored `product` (:24)
var product: Product? { products[Premium.productID] }       // lifetime — every existing caller unchanged (D2)
private(set) var subscribed = false                          // a renewing subscription is among what's owned
/// The paywall's celebration trigger: a purchase that completed, or a Restore that
/// unlocked (Q7). Launch and Transaction.updates only refresh, so they never bump it.
private(set) var celebrations = 0
```

- **`load()` (`:60-64`):**
  - `await refresh()`, then `let found = (try? await Product.products(for: Premium.productIDs)) ?? []`.
  - `products = Dictionary(found.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })`.
  - `storeUnavailable = product == nil`, unchanged (D6).
- **`refresh()` (`:71-85`):**
  - `var renews = false`.
  - Inside the existing verified/unrevoked branch (`:76-78`), beside `owned = true`: `if transaction.productType == .autoRenewable { renews = true }`.
  - After `set(owned)`: `if renews != subscribed { subscribed = renews }`. This writes only on change, like `set` at `:128`.
- **`handle(_:)` (`:91-95`):**
  - After `phase = .idle`: `if isUnlocked { celebrations += 1 }`.
  - Comment: `// ponytail: if this refresh lost the generation race (:81) the flag may still be false here; the newer refresh then shows the thank-you without confetti. Harmless.`
- **`restore()` (`:109-120`):**
  - First line: `let was = isUnlocked`.
  - After the final `await refresh()`: `if !was && isUnlocked { celebrations += 1 }` with `// Q7: a Restore that unlocks is celebrated like a purchase.`
  - Restores started from Profile's or PremiumBar's button bump the counter too. Nothing listens there, so only a showing paywall celebrates.
- **Header comment (`:5-11`):** the VM loads all three products, and `celebrations` is the paywall's trigger.

**`OneWord/Views/PremiumBar.swift` MODIFIED (`UnlockButton`, `:71-131`):**
- After `var verb` (`:77`), add `var open: (() -> Void)? = nil  // Profile's: the pill opens the plans rather than buying Lifetime outright`. Declaring it last keeps `UnlockButton(name:verb:open:)` in memberwise order (m8).
- `:89`:
  - The action becomes `{ if let open { open() } else { Self.buy(product, with: purchase, premium) } }`.
  - Add `.accessibilityHint(open == nil ? "" : "Shows the plans")` (Q6). The label at `:90` is unchanged.
- `:120`: `private func buy(_:)` becomes `static func buy(_ product: Product, with purchase: PurchaseAction, _ premium: PremiumViewModel)`. The body is unchanged.

- **Isolation:** everything is MainActor by default. `Product.products(for:)` and the entitlement iteration hop off main and back, and `Product` / `Transaction` are `Sendable`. The static `buy`'s `Task {}` inherits MainActor.
- **Verify:**
  - Both builds pass.
  - Xcode Run with the StoreKit config: the free pill reads **"Buy — $169.99"** and still buys Lifetime directly (nothing passes `open` yet).
  - Delete the transaction in Transaction Manager and relaunch: the Profile is free again.
  - Take the **baseline screenshots** of the free Profile now (Mac at 1000×680, iPhone) for R3.

#### Step 3: Import the two cats

**Prerequisite (build session, before this step).** Fetch the two PNGs from the operator's artifact, `https://claude.ai/artifact/7av5v7AY5UwCtik4DQyEvv`. No code names an asset id.
- `50c675b315b299354651463e5565870b` → `cat_cushion` (sprawled on the cushion)
- `143a622eb1a84b228c2e7124932b2b85` → `cat_cafe` (beret, scarf, coffee, croissant)

| File | Change |
|---|---|
| `OneWord/Assets.xcassets/Cat/Contents.json`, `OneWord/Assets.xcassets/Cat/Poses/Contents.json` NEW | `{"info":{"author":"xcode","version":1}}`, with **no** `provides-namespace`, so names stay flat |
| `OneWord/Assets.xcassets/Cat/Poses/cat_cushion.imageset/` NEW | `Contents.json` exactly like `Dictionary_of_EverydayEnglish.imageset/Contents.json` (PNG in the 1x slot; 2x and 3x present but empty), plus `cat_cushion.png` |
| `OneWord/Assets.xcassets/Cat/Poses/cat_cafe.imageset/` NEW | Same, with `cat_cafe.png` |

- **Verify:**
  - Both builds pass.
  - `grep -rn "catCushion\|catCafe" ~/Library/Developer/Xcode/DerivedData/OneWord-*/Build/Intermediates.noindex/OneWord.build/*/OneWord.build/DerivedSources/GeneratedAssetSymbols.swift` finds both symbols.
  - `sips -g pixelWidth` reports cushion ≥ 336px and café ≥ 600px, which is 2× their largest draw widths. Smaller art looks soft (R7).
- **If the PNGs aren't in hand when Step 4 starts:** skip this step. Land Steps 4–5 without the two `Image(.cat…)` overlays and without `Breathe`, then add this step and the overlays in a follow-up commit.

#### Step 4: The paywall's offers, the Mac window and the Profile entry *(the thin end-to-end slice)*

**`OneWord/Views/PremiumView.swift` MODIFIED (`:84-132`):**
- `private var fan` becomes `static func fan(_ books: [Wordbook], height: CGFloat, scale: CGFloat) -> some View`.
  - The body is the same, with `Self.books` → `books` and `displayScale` → `scale`.
  - `cover` stays `private static`.
- `hero` (`:86`) calls `Self.fan(Self.books, height: isPhone ? 72 : 100, scale: displayScale)`.

**`OneWord/Views/PaywallView.swift` NEW (app target, auto-included):**

```swift
import SwiftUI
import StoreKit   // Product.displayPrice/price, \.purchase — MEMBER_IMPORT_VISIBILITY needs it named

struct PaywallView: View {
    /// The Mac's Premium window (OneWordApp); Profile's Buy pill opens it by this id.
    static let windowID = "premium"
    /// MOCK — the one list of what Premium gives; Profile's gold card reads it too.
    /// ponytail: placeholder copy; true statements replace it before submission (F10, R1).
    static let perks: [String] = [ /* four mock lines */ ]
    @Environment(PremiumViewModel.self) private var premium
    @Environment(\.purchase) private var purchase
    @Environment(\.dismiss) private var dismiss              // iOS: the sheet. Mac: the window (D15).
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var yearly = true                         // F4
    private let t = Theme.cat                                // F2
    var body: some View
    @ViewBuilder private var content: some View              // the platform split (D15)
    private var offers: some View
    private var thanks: some View                            // Step 4: headline + Done; Step 5 fills it
    private var subscriptionCard: some View
    private var lifetimeCard: some View
    private var periodToggle: some View
    private func buyButton(_ id: String, _ label: String, _ name: String) -> some View
    private func card<C: View>(emphasized: Bool, @ViewBuilder _ content: () -> C) -> some View
    private static let terms: URL     // https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ [Unverified]
    /// ponytail: duplicates FeedbackViewModel.privacyPolicy once feat/website merges — point at it then.
    private static let privacy: URL   // https://one-word-a2f3a.web.app/privacy
}
private struct Breathe: ViewModifier                          // lands with the cats (Step 3)
extension Theme {
    /// The canvas's light Cat page (CAT_UI_PLAN §4). ponytail: CAT_UI Phase 1 adds this to
    /// Shared/Theme.swift; this copy then won't compile (redeclaration), so delete it there.
    static let cat: Theme
}
#Preview { PaywallView().environment(PremiumViewModel()) }
```

**`Theme.cat`** copies `CAT_UI_PLAN.md:120-131`'s light column:
- background `#FEFBF7`, surface `#FFFFFF`, ink `#1E1B26`, muted `#625D6E`
- definition `#2A2633`, example `#4B4658`, accent `#5B3FD6`, rule `#E9792B`, hairline `#E9E2D6`
- roundness 1.5, with glow and tiles left at their defaults

**`content`** (the platform split):
- **macOS:** `ZStack { offers.accessibilityHidden(premium.isUnlocked); if premium.isUnlocked { Color(hex: 0x1E1B26).opacity(0.34).ignoresSafeArea(); thanks } }`. The dim layer sits over the plans and takes their clicks `[Inference]`.
- **iOS:** `if premium.isUnlocked { thanks } else { offers }`.
- On the Mac this means a restored or reopened window for an owner shows the thank-you over the plans. There's nothing to buy, and Done closes it.

**Body** (root modifiers, in order):
1. `content`, then `.animation(.spring(duration: 0.5, bounce: 0.25), value: premium.isUnlocked)`.
2. `#if os(macOS) .frame(width: 760, height: 600) #endif`. This is the window's size under `.contentSize`, and it's a knob.
3. `.background(t.background)` and `.environment(\.colorScheme, .light)`, so `ProgressView`, `Link` and scrollers draw for paper. **Not** `.preferredColorScheme` (R13 is the only exception).
4. `.tint(t.accent)`, because Midnight's tint (`RootView.swift:214`) reaches into an iOS sheet (m10).
5. `.presentationDetents([.medium, .large])` (Step 5 makes it conditional), `.presentationDragIndicator(.visible)` and `.presentationBackground(t.background)`, mirroring `HomeView.swift:234-236`. All three are iOS 16 / macOS 13 and have no effect in the Mac window.

**Offers layout** (top to bottom, padding 44/20 as in `PremiumView.swift:64`):
- **Close X**, top-trailing, `.buttonStyle(.plain)` with `.keyboardShortcut(.cancelAction)`. It calls `dismiss()`, which closes the sheet or the window.
- **Fan:** `PremiumView.fan(shelf, height: isPhone ? 72 : 100, scale: displayScale)`, where `shelf = Wordbook.all.filter { $0.id != SavedWords.resource }` (8 books, `Wordbook.swift:56`).
- **Title** in `Font.serif(isPhone ? 30 : 36, .medium)` (`Theme.swift:169`) with `.accessibilityAddTraits(.isHeader)`. Then the pitch line and `perks` as checkmark rows, shaped like `PremiumView.perk` (`:383-398`).
- **Cards** in an `HStack` on macOS and a `VStack` on iOS (D13).
  - `answered = premium.product != nil || premium.storeUnavailable`.
  - The subscription card is drawn if `!answered || (products[yearlyID] != nil && products[monthlyID] != nil)`.
  - The Lifetime card is drawn if `!answered || premium.product != nil`.
  - If `answered` and neither card can be drawn: `premium.problem` plus "Try Again" (`Task { await premium.load() }`).
- **`card(emphasized:)`:** white surface, a 1pt `t.hairline` border, and `RoundedRectangle(cornerRadius: t.radius(12))`, which is 18pt under Cat's 1.5 roundness and matches the board. Emphasized adds a 2pt `t.accent` border and the `PremiumView.card` shadow (`:431`).
- **Subscription card:**
  - The "Premium" heading, plus `periodToggle` top-trailing. The toggle is one `.plain` capsule button reading "Monthly · Yearly" with the current one filled; it runs `withAnimation(.snappy) { yearly.toggle() }`.
  - `.accessibilityLabel("Billing period")`, `.accessibilityValue(yearly ? "Yearly" : "Monthly")`, `.accessibilityHint("Switches between monthly and yearly")`.
  - The price in serif 40 with `.contentTransition(.numericText())`, plus " / year" or " / month".
  - When `yearly` and `Premium.savings(yearly: y.price, monthly: m.price)` is non-nil: a chip reading "Save \(n)%".
  - "Renews every \(year|month) at \(displayPrice) until you cancel. Cancel anytime in your App Store account settings."
  - `buyButton(yearly ? Premium.yearlyID : Premium.monthlyID, "Subscribe", yearly ? "Premium Yearly" : "Premium Monthly")`.
- **Lifetime card** (emphasized, F3):
  - "Lifetime", the price plus "once", and "Pay once. Yours for good. Nothing renews."
  - `buyButton(Premium.productID, "Buy", "Premium Lifetime")`.
  - The cushion cat: `.overlay(alignment: .bottomTrailing) { Image(.catCushion).resizable().interpolation(.high).scaledToFit().frame(width: isPhone ? 118 : 168).modifier(Breathe()).offset(x: isPhone ? 8 : 30, y: isPhone ? 20 : 34).allowsHitTesting(false).accessibilityHidden(true) }`. That's the 30pt overhang from `CAT_UI_PLAN.md` §3.6.
  - **The cat never covers a Buy button.** On the Mac and iPad the button is 160×40 and leading. On the phone it is full width at 50pt, with `.padding(.bottom, 96)` on the card. All of these are knobs.
- **`buyButton`:**
  - `.purchasing` → spinner.
  - A product exists → a violet filled `.plain` button: `{ UnlockButton.buy(p, with: purchase, premium) }`. It is 40pt with radius 12 on Mac/iPad, and 50pt full width with radius 14 on the phone. Label: `"\(label), \(p.displayPrice)"`. `.accessibilityLabel("\(label) \(name), \(p.displayPrice)")`.
  - `answered` but no product → nothing.
  - Otherwise → spinner.
- **Below the cards:**
  - "Restore Purchase" as a violet `.plain` text button: `Task { await premium.restore() }`, disabled while purchasing.
  - `premium.problem`, as `PremiumView.swift:248-254` shows it.
  - `Link("Terms of Use", destination: Self.terms) · Link("Privacy Policy", destination: Self.privacy)` at 12pt in muted.

**`thanks` (Step 4 stub):** "Welcome to the Premium Club" plus a Done button calling `dismiss()`, with `.keyboardShortcut(.defaultAction)`. Step 5 replaces it.

**`Breathe`** (only if the cats are in):
- `phaseAnimator([false, true])` scaling (1.006 × 1.02), anchored `.bottom`, at `.easeInOut(duration: 3.6)` per phase.
- Under Reduce Motion it returns `content` untouched.

**`OneWord/OneWordApp.swift` MODIFIED:** after the `WindowGroup`'s closing `#endif` (`:102`), add:

```swift
        #if os(macOS)
        // The Mac's paywall is its own window (Q1), opened only by Profile's Buy pill.
        Window("Premium", id: PaywallView.windowID) {
            PaywallView()
                .environment(premium)   // the only environment value it reads; \.doodle defaults to .off
                // A window restored on its own at launch has no RootView to load the prices.
                .task { if premium.product == nil { await premium.load() } }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commandsRemoved()   // no Window-menu entry: the pill is the way in (RQ5)
        // ponytail: a Premium window left open can come back at launch. restorationBehavior(.disabled)
        // is macOS 15+, and SceneBuilder has no buildEither, so an `if #available` would drop the
        // window on macOS 14. Add it when the floor reaches macOS 15.
        #endif
```

**`OneWord/Views/ProfileView.swift` MODIFIED:**
- `@State private var paywall = false`, commented "iPhone and iPad: the sheet. The Mac opens its window instead."
- `@Environment(\.openWindow) private var openWindow`.
- A helper:
  ```swift
  /// The plans: their own window on the Mac (Q1), a sheet on iPhone and iPad.
  private func showPlans() {
      #if os(macOS)
      openWindow(id: PaywallView.windowID)
      #else
      paywall = true
      #endif
  }
  ```
- At `:498`, **change only** `UnlockButton(name: "Buy Premium", verb: "Buy")` to `UnlockButton(name: "Buy Premium", verb: "Buy", open: { showPlans() })`. **Keep `owned`** and everything else in `plans` (M1).
- After `.task { model.refresh() }` (`:97`), add `.sheet(isPresented: $paywall) { PaywallView() }`. The environment, including `PremiumViewModel` and `\.purchase`, propagates into sheets, as `FeedbackView.swift:28` relies on.

- **Isolation:** all MainActor. The window's `.task` is the only new task, and it is cancelled with the window.
- **Verify** (Xcode Run, StoreKit config):
  - **Mac:**
    - The pill opens a "Premium" window at 760×600 with Cat paper, and a second tap brings it forward instead of opening another.
    - The Window menu lists no "Premium" (RQ5; `[Inference]`, accept it if it does).
    - Buy Monthly (then delete it), Yearly (then delete it), and Lifetime. Each time the StoreKit confirmation appears **from the Premium window** (R2), the window shows the stub thank-you, Done closes it, and Profile flips to the **old owned cards** (Premium tagged Current, no pill). Cancel leaves everything unchanged.
  - **iPhone:**
    - A bottom sheet at medium drags to large, and the subscription price is visible at medium on an SE-size simulator. If not, raise the first detent to `.fraction(0.6)`.
    - The grabber is visible on Midnight (R13).
    - Links and spinners are violet, not Midnight's blue.
  - **iPad:** a form sheet with stacked cards and leading 40pt buttons. The cat clears the button.
  - **Prices** read 14.99, 149.99 and 169.99. The toggle switches the price, and "Save 16%" shows on Yearly only.
  - **The free Profile** matches Step 2's baseline apart from the price text (R3).

#### Step 5: The thank-you, confetti and haptic

**`OneWord/Views/PaywallView.swift` MODIFIED.**

**`thanks`:**
- **Mac (MacPremiumThanks):**
  - A centred card, `.frame(width: 740, height: 420)`, with `t.surface` in `RoundedRectangle(cornerRadius: 20)` and a soft shadow. It sits over the Step 4 dim, and the sizes are knobs.
  - Left column:
    - "PREMIUM" (violet, 11 bold, uppercase, tracking 2).
    - "Welcome to the Premium Club" in `Font.serif(36, .medium)` with `.isHeader`.
    - Body: "Thank you for backing One Word. Premium is yours on every Mac and iPhone signed in to this Apple ID." Universal Purchase makes this true (`ARCHITECTURE.md:120-124`).
    - A violet filled `.plain` "Done" (40pt, radius 12) with `.keyboardShortcut(.defaultAction)`, calling `dismiss()`, which **closes the window** (D15).
  - Right column: `Image(.catCafe)` 300 wide, with `Breathe` and `accessibilityHidden`.
- **iOS (PhonePremiumThanks):** stacked. The cat at 244 wide, then the label, the centred headline at serif 30, the body, and a full-width 50pt Done.
- **Entrance:** `.transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))`, driven by the root's `.animation(…, value: premium.isUnlocked)`.
- **No "Pick a book"** (F8).

**On the root (D4):**
- `.overlay { if !reduceMotion { Confetti(trigger: premium.celebrations).allowsHitTesting(false).accessibilityHidden(true) } }`. It covers the whole Mac window, or the iPhone sheet (m12).
- `.sensoryFeedback(Self.feel, trigger: premium.celebrations)`, where `#if os(macOS) static let feel = SensoryFeedback.levelChange #else … .success #endif`.
  - `.levelChange` "only plays feedback on macOS" (SwiftUI swiftdoc); `.success` plays on iOS (SwiftUICore swiftdoc).
  - It is one modifier for both platforms, unlike the `NSHapticFeedbackManager` precedent at `DictionaryPicker.swift:232-237`, which exists because `.error` has no Mac rendering (m3, Q4).
- `.onChange(of: premium.celebrations) { AccessibilityNotification.Announcement("Welcome to the Premium Club").post() }`, mirroring `SyncToast.swift:50`.
- `.presentationDetents(premium.isUnlocked ? [.height(584)] : [.medium, .large])`. 584 is the PhonePremiumThanks board's height.

**`Confetti`** (private):

```swift
private struct Confetti: View { let trigger: Int }   // KeyframeAnimator(initialValue: 0.0, trigger: trigger)
                                                     //   { p in Canvas { … } } keyframes: { _ in MoveKeyframe(0.0); LinearKeyframe(1.0, duration: 2.8) }
private nonisolated struct Piece { /* x0 (0…1), drift, fall speed, spin, w/h, colour */
    static let all: [Piece]                          // ~90, built once
}
```

- Draw nothing at `p == 0 || p >= 1`.
- Each piece:
  - starts above the top edge at `x0 × width`,
  - falls under gravity scaled to `size.height`,
  - wobbles on a sine,
  - rotates by `spin × t`,
  - fades over the last 25%.
- Colours: `#5B3FD6`, `#E9B949`, `#F07167`, `#2BB3A3`, `#6CA8F0`, `#1E1B26`.
- Capture `let pieces = Piece.all` before the `Canvas` (R5).

- **Verify:**
  - **Buy Yearly.**
    - Mac: the dim and the modal thank-you appear, confetti falls over the whole window for about 2.8s, and Done (or Return) closes the window.
    - iPhone: the sheet becomes the thank-you at 584pt, with confetti inside the sheet and a haptic on a **device** (the simulator has none).
    - VoiceOver announces the headline.
  - **Ask to Buy** shows "Waiting for approval.". After approval in Transaction Manager, the thank-you shows **without** confetti, because it arrives via `Transaction.updates`.
  - **Reduce Motion** on: no confetti, no breathing, and the thank-you fades in.
  - **Mac haptic:** with a finger resting on a Force Touch trackpad, note whether `.levelChange` is felt (Q4). Either result is acceptable.
  - **Restore-celebrate (Q7)** can't be set up locally (m14). It moves to matrix row 8.

#### Step 6: The golden Premium card *(plus the M1 swap, in this one commit)*

**`OneWord/Views/ProfileView.swift` MODIFIED:**
- **Imports** (`:21-23`): add `import StoreKit   // manageSubscriptionsSheet — MEMBER_IMPORT_VISIBILITY needs it named`.
- **State:** `@State private var perksShown = false`, `@State private var managing = false`, and `@Environment(\.openURL) private var openURL`.
- **Body** (`:76`): `plans(t)` becomes `if premium.isUnlocked { premiumCard(t) } else { plans(t) }`.
- **`plans`** (`:485-510`, same commit):
  - Drop `owned`: `section("Plan", t, note: premium.problem)`, `planCard("Free", current: true, t) { EmptyView() }`, and `planCard("Premium", current: false, t) { …Lifetime caption, the UnlockButton with open:, Restore… }`.
  - Doc comment: "Free's plans; an owner sees `premiumCard` instead."
  - For a free reader this renders exactly what renders today.
- `#if os(iOS) .manageSubscriptionsSheet(isPresented: $managing) #endif`, beside the paywall `.sheet`.
- **`private func premiumCard(_ t: Theme) -> some View`**, after `planCard` (`:529`), inside `section("Plan", t)`:
  - **Header row:** a `.plain` `Button { withAnimation(.snappy) { perksShown.toggle() } }` with `.contentShape(Rectangle())`. Its label holds:
    - `Image(systemName: "crown.fill")`,
    - "PREMIUM" at 11 bold, tracking 2,
    - "One Word Premium" in `doodle.face(22)`,
    - `premium.subscribed ? "Subscription" : "Lifetime"` (m7 deferred),
    - a chevron rotated 90° when open.
  - **Below the header** (siblings, not nested in the header button):
    - When `perksShown`: `ForEach(PaywallView.perks, id: \.self)` checkmark rows.
    - When `premium.subscribed`: a `.plain` "Manage Subscription" button. iOS sets `managing = true`. macOS calls `openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)` `[Unverified]` (R10).
  - **Look:**
    - A fixed `LinearGradient` from `#F6D77A` (top leading) to `#D4A52C` (bottom trailing), on every appearance.
    - Ink `#2A1E05`.
    - Corners `t.radius(12)`, to sit with `ProfileCard` (`ProfileView.swift:685-690`).
    - Shadow `#D4A52C` at 0.35, radius 14, y 6 (a knob).
  - **Contrast** (WCAG 2.1): ink is 7.17:1 on `#D4A52C` and 11.6:1 on `#F6D77A`. **Don't add a darker third stop**: `#B07D1A` measures 4.5:1, which is the floor.
  - **Accessibility:** `.accessibilityLabel("One Word Premium, \(subscribed ? "subscription" : "lifetime")")`, `.accessibilityValue(perksShown ? "Expanded" : "Collapsed")`, `.accessibilityHint("Shows what Premium includes")`.

- **Verify:**
  - **Owned Lifetime:** the gold card reads "Lifetime", tapping expands the perks, and there is no Manage row.
  - **Owned Yearly:** "Subscription" plus Manage. On iPhone, Manage opens Apple's sheet; on the Mac it opens the subscriptions page (R10).
  - **Delete the transactions:** the free Profile is back and matches Step 2's baseline.
  - The card looks right on Midnight, System light and System dark.

#### Step 7: Docs

**`Docs/00_Context/ARCHITECTURE.md`:**
- `:126-127`: "Today's purchase UI (`UnlockButton`) sells lifetime only" becomes "The paywall (`Views/PaywallView.swift`) sells all three; `UnlockButton` elsewhere sells lifetime."
- `:142-146` "Where it's sold": add these points.
  - Profile's Buy pill opens the paywall: its own `Window` on the Mac, a sheet on iPhone and iPad.
  - **`celebrations` is the celebration signal**, bumped only by a completed purchase or by a Restore that unlocked.
  - Owners see Profile's gold card.
  - `PaywallView.perks` is the one list both of them read.
- `:147-148`: add "The Mac's Premium window is a scene of its own; `OneWordApp` injects `PremiumViewModel` there too."
- `:184`: "`OneWordApp.swift` @main — the main window, the Mac's Premium window, app-active refresh".
- `:190`: add `PaywallView` to the Views list.

**`Docs/00_Context/REPO_MAP.md`:**
- `:30` Assets row: "…, dictionary covers, avatars, `Cat/Poses/` (the paywall's two cat drawings, 1x slot)".
- `:52` `check_premium.sh`: "…and the yearly-savings figure".

**`Docs/README.md` Dossiers:** add or update a "**Paywall**" line with the state **at this commit** (e.g. "built; gates green; true perks, App Store Connect and a sandbox pass gate release"). Link the plan, the audit and this resolved plan.

Do not edit any other `01`–`06` doc.

- **Verify:** `grep -rn "PaywallView\|cat_cushion" Docs/00_Context Docs/README.md` hits ARCHITECTURE, REPO_MAP and README.

### 4.4 Data, persistence & API changes

- **StoreKit products.** All three are loaded once at launch (`OneWordApp.swift:93`), on Try Again, and when a restored Mac Premium window finds none. No product ids are new.
- **No persistence change.** With `Features.premium` off, `set` writes nothing to the App Group (`PremiumViewModel.swift:127`). `subscribed` and `celebrations` are in memory only, and `celebrations` resets to 0 each launch.
- **Widget:** unchanged. `reloadAllTimelines()` on unlock is harmless (`OneWordApp.swift:95`).
- **Expiry:** a lapsed subscription relocks at the next refresh (`PremiumViewModel.swift:66-70`), and the gold card goes with it.
- **Errors:** the existing `Phase` and `message(for:)` (`:20,131-139`), read via `premium.problem`.

### 4.5 Concurrency, state & memory

| Type | Isolation | Notes |
|---|---|---|
| `PremiumViewModel` | MainActor (default) | `products`, `subscribed` and `celebrations` are mutated only on main. `Product.products(for:)` and the entitlement iteration hop off main and back. `Product` and `Transaction` are `Sendable`. |
| `Premium.savings` | `nonisolated` (enum) | Pure Decimal math, callable from the harness compiled with `-default-isolation MainActor` (`check_premium.sh:98`) |
| `UnlockButton.buy` (static) | MainActor | Its `Task {}` inherits MainActor and captures `Product` (Sendable), `PurchaseAction` and the MainActor VM |
| `PaywallView`, `Confetti`, `Breathe`, `Theme.cat` | MainActor | The animators are framework-driven, stop when the view leaves, and start no Tasks |
| `Piece` | `nonisolated struct` | Mirrors `DoodleTheme.swift:58`, and is captured as a local `let` for the `Canvas` (R5) |
| `PaywallView.windowID` | MainActor static | Read by `OneWordApp.body` and `ProfileView`, both MainActor |

- **Task lifecycle.**
  - Purchase and restore `Task`s are unstructured and **outlive** a dismissed sheet or a closed window on purpose, so a purchase in flight still lands in the VM.
  - The Mac window's `.task` reload is cancelled when the window closes.
  - `Transaction.updates` keeps its `[weak self]` (`:38`).
- **Ownership.**
  - `@State`, view-local: `yearly` (resets to Yearly on each open), `paywall`, `perksShown`, `managing`.
  - The VM is app-owned and injected into both scenes.
- **Retain cycles:** none.
  - `open: { showPlans() }` captures the value-type `ProfileView`.
  - The window's `.task` captures the value-type `OneWordApp`.
  - The buy `Task` holds the app-lifetime VM briefly.
- **Ordering behind D4.**
  - `handle` and `restore` bump `celebrations` right after their own `await refresh()` returns. That is likely the same MainActor turn as the unlock `[Inference]`, but nothing depends on it, because the triggers sit on a root that exists before and after the swap.
  - If that refresh lost the generation race, the bump is skipped and a newer refresh shows the thank-you without confetti. This is accepted (m5).

### 4.6 Accessibility, localization & project mechanics

- **VoiceOver.**
  - Cats, fan and confetti are `accessibilityHidden`.
  - The toggle has a label, value and hint, and Buy buttons carry the product name and price.
  - The paywall title and the thank-you headline are `.isHeader`.
  - The celebration posts an announcement, and the gold card exposes expanded/collapsed.
  - On the Mac, the plans under the modal are `accessibilityHidden` while the thank-you shows.
  - The free pill keeps its label and gains the hint "Shows the plans" (Q6).
- **Keyboard (Mac).** Escape is the Close X (`.cancelAction`) and Return is Done (`.defaultAction`). Both call `dismiss()` and close the window.
- **Reduce Motion:** no confetti, no breathing, and the thank-you fades. The haptic still fires.
- **Contrast.**
  - The paywall uses `CAT_UI_PLAN.md` §4's light values, and white on violet is 6.72:1.
  - The gold card is computed in Step 6.
  - The paywall forces `.environment(\.colorScheme, .light)` on its content.
- **Dynamic Type:** fixed sizes, per the app's convention. This is a pre-existing gap, not widened here.
- **Localization:** there is no String Catalog. New literals follow `Text("…")`, and prices come localized from StoreKit.
- **Target membership:**
  - `PaywallView.swift`, the `OneWordApp.swift` edit and the assets fall under synchronized groups, so there is no `project.pbxproj` edit.
  - **Nothing new goes in `Shared/`.** `Premium.swift` is an existing Shared file, which the widget and `check_premium.sh:101` already compile.
- **Info.plist and entitlements:** none. `Link` and `openURL` work in the sandbox.
- **Availability** (all fit iOS 17 / macOS 14, so no `#available` is needed):
  - `Window`, `.windowResizability` and `.commandsRemoved` are macOS 13. `openWindow` is iOS 16 / macOS 13.
  - `PurchaseAction`, `KeyframeAnimator`, `phaseAnimator`, `.sensoryFeedback` and `AccessibilityNotification` are iOS 17 / macOS 14.
  - `.presentationBackground` is iOS 16.4 / macOS 13.3.
  - `Window` sits inside `#if os(macOS)` because it is iOS-unavailable.
  - `.manageSubscriptionsSheet` sits inside `#if os(iOS)`.
  - `restorationBehavior` (macOS 15) is **not used** (D14).

### 4.7 Test plan

**Headless** (the only new code check): extend the `PremiumCheck.swift` heredoc in `tools/check_premium.sh` with a "yearly savings" block. Build the inputs with `Decimal(string:)`.
- `savings(149.99, 14.99) == 16`: the real prices, rounded down.
- `savings(120, 12.5) == 20`: an exact boundary that fails if anyone swaps Decimal for Double.
- `savings(180, 15) == nil`: no saving means no label.
- `savings(100, 0) == nil`: guards the divide.

**Not testable headless:**
- `PremiumViewModel` needs StoreKit's runtime. The seam would be a protocol over `Product`/`Transaction`: one implementation, rejected per house style.
- SwiftUI bodies, confetti, the window and the sheets are checked by eye.

**Manual matrix** (Xcode Run with `StoreKit/OneWord.storekit`; never `open -n` or kill the debug run):

| # | Check |
|---|---|
| 1 | The free Profile at Mac 1000×680 and on iPhone matches Step 2's baseline, except the price text. |
| 2 | **Mac:** the pill opens the Premium window, a second tap focuses it, and the Window menu has no entry. **iPhone:** the sheet goes medium → large and the grabber shows on Midnight. **iPad:** a form sheet. **All:** prices, the toggle, "Save 16%", Restore, and both links open in the browser. |
| 3 | Buy Monthly, Yearly and Lifetime, deleting transactions in between. **Mac:** the dimmed modal, confetti over the window, Done closes the window. **iPhone:** the 584pt thank-you, confetti in the sheet, the haptic on a device. The announcement plays, and the gold card label is right after Step 6. |
| 4 | Ask to Buy approve (thank-you, no confetti) and decline (idle). Cancel (unchanged). A purchase error toggled in the config (problem line). |
| 5 | Subscription expiry: speed up the config's time rate and let a subscription lapse. After relaunch the Profile is free. |
| 6 | {Mac, iPhone simulator and device, iPad simulator} × {Midnight, System light, System dark} × {Reduce Motion off, on}. Spot-check VoiceOver on the toggle, the Buy labels, the gold card and the Mac modal. |
| 7 | **Mac:** quit with the Premium window open and relaunch. Note whether it returns (R11). If it does, prices load in it. |
| 8 | **Sandbox/TestFlight, before submission:** a purchase from the Mac Premium window (R2). Subscription renewal and expiry. A **Restore that unlocks**, on a device or account whose entitlement isn't present at launch: the full celebration (Q7). |

**Gates** (all must be green): both `xcodebuild` builds, plus `for s in check_words check_related check_learned check_capture check_sentences check_premium check_sync; do bash tools/$s.sh; done`.

### 4.8 Decision forks

| # | Fork | Status / default | The other branch wins when… |
|---|---|---|---|
| F1 | Mac presentation | **Decided (Q1): its own `Window`.** iPhone gets a bottom sheet, and iPad a sheet. | n/a |
| F2 | Paywall palette | The canvas's light Cat page on every appearance | …the paywall should match the reader's appearance. Then use `Theme.of(scheme, doodle)`, and the cats need a dark-page rim. |
| F3 | Emphasized card / cushion cat | Lifetime | …recurring revenue is the priority |
| F4 | Toggle's starting period | Yearly, so the chip shows | …the lowest entry price should show first |
| F5 | Restore inside the paywall | **Decided (Q7): full celebration** when it unlocks | n/a |
| F6 | Savings label | On, rounded down | …you don't want it: delete one `Text` |
| F7 | The free pill | Opens the paywall; wording unchanged (Q6, RQ4) | see RQ4 |
| F8 | Thank-you buttons | Done only (nothing is gated) | …books are gated: add "Pick a book" |
| F9 | How owners see the features | Inline expansion of the gold card | …the list grows past about 6 rows or gains imagery |
| F10 | Perks and release | **Decided (Q2): one list on both surfaces.** Replacing the mocks with true statements gates submission. | see RQ1 (Q3) |

### 4.9 Risks & exits

| Risk | Severity · Confidence | Leading indicator | Cheapest exit |
|---|---|---|---|
| R1: App Review rejects subscriptions that unlock nothing, or mock or unsupported claims (3.1.2(a), 2.3) | **High** · Med | Rejection citing ongoing value or accurate metadata | (a) The F10 gate: perks and IAP metadata become true before submission (Step 0). (b) If 1.1.0 must ship first: Lifetime only, via `static let subscriptions = false` in `Features.swift` and a filter on `load()`'s ids (`Features.subscriptions ? Premium.productIDs : [Premium.productID]`). That is two lines, not "config-only", because a product left unattached may still be returned in sandbox `[Inference]`. The paywall hides the subscription card by itself (D6), and the perks must still be true. (c) If the disclosures are flagged: `SubscriptionStoreView` for the subscription card. |
| R2: `PurchaseAction` doesn't present from the Premium window `[Unverified]` | Med · Low–Med | Step 4 Mac: the spinner holds and no dialog appears | Mac-only `try await product.purchase()` (StoreKit, `@MainActor`, macOS 12) into `premium.handle` |
| R3: The free Profile regresses visually | Med · Low | The Step 2 baseline comparison | Revert the `plans` hunk, keeping only `open:` |
| R4: The Mac haptic is never felt (Force Touch, finger down) | Low · High | Nothing felt | Accept it; the confetti carries the moment (Q4) |
| R5: `Canvas` renderer isolation warns or errors | Low · Low–Med | A Step 5 build warning | `nonisolated Piece` plus a local capture (planned). Last resort: `TimelineView` + `ForEach`. |
| R6: The iPhone detent change looks janky | Low · Med | By eye in Step 5 | Static detents |
| R7: Cat PNGs missing or low-resolution | Med · Med | Step 3 prerequisite or `sips` | The planned no-overlay path (Step 3 fallback) |
| R8: Subscription prices wrong at first approval | Med · Low | Step 0 review | Check prices before attaching the IAPs |
| R9: The privacy URL isn't live | Med · Low–Med | `curl -sI …/privacy` isn't 200 | Deploy `feat/website` before submission |
| R10: The Mac Manage URL misses `[Unverified]` | Low · Med | Step 6 on the Mac | `macappstores://apps.apple.com/account/subscriptions` |
| R11: The Premium window is restored at launch (any macOS; see D14) | Low · Med | Matrix row 7 | Accept it: it shows the plans, or the thank-you for an owner, and prices reload via the window's `.task`. Add `.restorationBehavior(.disabled)` once the floor is macOS 15. |
| R12: `.commandsRemoved()` leaves the Window-menu item `[Inference]` | Low · Low–Med | Step 4 Mac menu | Accept it: an owner opening it sees the thank-you with Done |
| R13: The grabber is near-invisible on Midnight, or the sheet's chrome is dark `[Inference]` | Low · Med | Step 4 iPhone on Midnight | iOS-only `.preferredColorScheme(.light)` on the paywall root. Confirm it doesn't flip the main window. |

### 4.10 Sequencing summary & verification

1. [ ] **Step 0** (operator, in parallel; gates release): App Store Connect prices, metadata and true copy, the site check, the sandbox pass.
2. [ ] **Step 1**, the first reversible move: `.storekit` prices, `Premium` ids and `savings`, plus the check. **Unblocks** Step 2.
3. [ ] **Step 2**: `products`, `subscribed` and `celebrations` (purchase and restore bumps); `UnlockButton.open` and static `buy`; the baseline screenshots. **Unblocks** Steps 4 and 6.
4. [ ] **Step 3** (prerequisite: the PNGs fetched): the two imagesets. **Unblocks** the cat overlays and `Breathe` in Steps 4–5, and only those (fallback in Step 3).
5. [ ] **Step 4**: `PaywallView` offers; `PremiumView.fan` made static; the Mac `Window` scene; the Profile pill → window or sheet, with `plans` touched only for `open:`. This is the end-to-end slice. **Unblocks** Step 5.
6. [ ] **Step 5**: thank-you (Mac modal, iOS swap), confetti, haptic, announcement, detents.
7. [ ] **Step 6**: gold card, perks, Manage, plus the `owned` removal and body swap in one commit.
8. [ ] **Step 7**: the `00_Context` docs and the README dossier.

**After every step:**

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
for s in check_words check_related check_learned check_capture check_sentences check_premium check_sync; do bash tools/$s.sh; done
```

**End-to-end path:**
1. Xcode Run on the Mac with the StoreKit config.
2. Open Profile: it looks as today, and the pill reads "Buy — $169.99".
3. Tap it: the Premium window opens.
4. Toggle to Yearly, check "Save 16%", Subscribe and confirm: dimmed modal, confetti, "Welcome to the Premium Club".
5. Press Return: the window closes, and Profile shows the gold card. Expand it to see the perks and Manage Subscription.
6. Delete the transaction in Transaction Manager and relaunch: the free Profile is back.
7. Repeat on an iPhone device (sheet, drag to large, haptic) and with Reduce Motion on.

### 4.11 Open questions & assumptions

- `[Unverified]` The Apple EULA URL `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/` opens. *Resolved by:* opening it at build time.
- `[Unverified]` The privacy page is deployed and its copy is current. Its "your Mac" and "no network requests" wording predates the iPhone version and iCloud. *Resolved by:* Step 0's `curl` and a re-read of `site/public/privacy.html` on `feat/website`.
- `[Unverified]` `PurchaseAction` presents from the Premium window (R2). *Resolved by:* the Step 4 Mac purchase, then sandbox row 8.
- `[Inference]` `.commandsRemoved()` removes the `Window`'s Window-menu entry (R12). *Resolved by:* Step 4.
- `[Inference]` On macOS, a restored Premium window can come back without the main window, which is why the window's `.task` reload exists. *Resolved by:* matrix row 7.
- `[Inference]` On Midnight, the iPhone sheet's grabber is hard to see on paper (R13). *Resolved by:* Step 4.
- `[Inference]` A full-frame dim `Color` blocks clicks to the plans beneath it. *Resolved by:* Step 5 on the Mac. If clicks leak, add `.disabled(premium.isUnlocked)` on the offers.
- `[Inference]` Asset symbols name `cat_cushion` as `.catCushion` in a non-namespaced folder. *Resolved by:* Step 3's grep.
- `[Inference]` A detent change while presented animates (R6). *Resolved by:* Step 5 by eye.
- `[Inference]` A subscription that isn't attached may still load in sandbox (R1b). *Resolved by:* the Step 0 sandbox pass, if the Lifetime-only route is ever taken.
- `[Assumption]` The build session can fetch the two PNGs from the operator's artifact (per the operator). *Resolved by:* Step 3's prerequisite.
- `[Assumption]` The PNGs are at least 2× their draw width. *Resolved by:* `sips` in Step 3.
- `[Assumption]` The operator replaces the mock perks before submitting (Q2, F10).
- `[Assumption]` `ONBOARDING_PLAN_RESOLVED.md`'s later `PlanPair` extraction rebases over the two-hunk `fan` → `static func` edit.

---

## 5. Operator review queue

Each item below was applied by recommended default. None blocks the build. Accept or override each one.

**RQ1 · Q3: what ships if the perks aren't real by submission.**
- **Applied:** no kill switch is built now. Replacing `PaywallView.perks` and the IAP metadata with true statements is the gate for submission (F10, Step 0).
  - It is recommended because you said you'll replace the mocks before submitting, and the two-line flag is fully specified in R1(b) if it's ever needed.
- **Alternatives:**
  - (a) Ship Lifetime only: add the R1(b) flag, and write true perk copy for the paywall.
  - (b) Ship the full paywall with true but modest copy.
- **Flips when:** 1.1.0 must be submitted before real Premium features exist.

**RQ2 · Q4: Mac haptic.**
- **Applied:** keep `.sensoryFeedback(.levelChange)` on the Mac. It costs nothing, and the SDK says it plays on macOS, but only through a Force Touch trackpad with a finger resting on it. That's unlikely right after a system purchase dialog.
- **Alternatives:**
  - (a) Drop the Mac haptic (`.success` only, iOS).
  - (b) The repo's `NSHapticFeedbackManager … .generic` precedent (`DictionaryPicker.swift:232-237`), which has the same hardware limit.
- **Flips when:** you'd rather not ship a Mac path that is rarely felt, or the Step 5 check shows it never plays.

**RQ3 · Q5 / G3: subscriber-to-Lifetime upgrade.**
- **Applied:** not built. Owners never see the paywall.
- **Alternative:** a "Switch to Lifetime" row on the gold card for `subscribed` owners that opens the paywall with only the Lifetime card. It would come with a `lifetime` flag in `refresh()`, which also settles m7's label.
- **Flips when:** you want upgrade revenue, or subscribers ask for it.

**RQ4 · Q6 / F7: free pill wording.**
- **Applied:** the visuals are unchanged ("Buy — $169.99", with "Lifetime" above it, which still matches the price). VoiceOver gets the hint "Shows the plans".
  - It is recommended because "free Profile looks exactly like the current one" is a locked constraint.
- **Alternative:** relabel the pill "See plans", which changes the free Profile.
- **Flips when:** you decide clarity beats "visually identical", or testers are surprised that Buy opens a plan picker that defaults to Yearly.

**RQ5 · Q1 cost: the Window-menu entry.**
- **Applied:** `.commandsRemoved()` on the Premium window, so only Profile's pill opens it. An owner then can't land on a thank-you with nothing to buy.
- **Alternative:** keep Window → Premium as a second way in. To do that, delete one line.
- **Flips when:** you want the paywall reachable from the menu bar.

---

## 6. Remaining / deferred

- **m7, the label for an owner of both (Deferred).** It can't be reached in-app under RQ3's default. *Resolves when:* RQ3 flips. Add `lifetime` beside `subscribed` in `refresh()` and prefer "Lifetime" in the label while still offering Manage.
- **m15(3), the duplicated privacy URL (Deferred).** `FeedbackViewModel.privacyPolicy` exists only on `feat/website` (`:31` there). *Resolves when:* that branch merges. Point `PaywallView.privacy` at it, as the `ponytail:` comment says.
- **Carried `[Unverified]` items** (each has a named check in §4.11):
  - R2: purchase from the second window.
  - R10: the Mac Manage URL.
  - R12: the Window-menu removal.
  - R13: grabber visibility on Midnight.
  - The EULA URL.
  - Whether the privacy page is live.
  - The artifact fetch for the two PNGs.
- **Restoration control on macOS 14.** The SDK offers no route: there is no `buildEither`, and `restorationBehavior` and `defaultLaunchBehavior` are macOS 15. Restoration is therefore accepted, with mitigation (R11). *Resolves when:* the deployment floor reaches macOS 15. Add `.restorationBehavior(.disabled)`.
