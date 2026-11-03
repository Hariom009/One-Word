# Plan audit: PAYWALL_PLAN

## 1. Header

**Plan audited:** `/Users/hariom/Desktop/One Word/Docs/02_Plan/PAYWALL_PLAN.md` ("Paywall: Plan"). The file is 555 lines and untracked. The audit ran on branch `release/1.1.0` @ `9c0bdf9`, with no code changes in the working tree. Every path cited below is relative to `/Users/hariom/Desktop/One Word`.

**Brief and definition of done:** `/private/tmp/claude-501/-Users-hariom-Desktop-One-Word/ad09efae-44c3-4a4e-a3a9-123bc838e427/scratchpad/plan-paywall-brief.md`. It includes the operator's words verbatim.

### Stack, re-checked from disk

| Aspect | Re-verified | Evidence | vs. plan's claim |
|---|---|---|---|
| Build | One `.xcodeproj` with two targets: the app (`application`) and the widget (`app-extension`). Synchronized groups. `Shared/` is referenced by explicit path. | `project.pbxproj:207,234,64-72` | Matches |
| Platforms | iOS 17 and macOS 14; device family `1,2` | `project.pbxproj:463,465,578` | Matches. The plan's `:363` and `:371` are the **widget** Release config lines. The app's own settings are at `:573-578`. |
| Toolchain installed | Xcode 27.0 (27A266a), macOS 27 and iOS 27 SDKs | `xcodebuild -version` | Not stated in the plan. Every API below was checked against these SDK interfaces' `@available` lines. |
| Concurrency | Swift 5 mode. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`. No `SWIFT_STRICT_CONCURRENCY` is set, so checking is minimal. | `project.pbxproj:573-577` | Matches |
| UI / architecture | SwiftUI and MVVM. View models are `@Observable` and never import SwiftUI. `PremiumViewModel` is app-owned and injected through the environment. | `PremiumViewModel.swift:14-19`, `OneWordApp.swift:35,85` | Matches |
| Persistence | UserDefaults / App Group. `Premium.set` writes only when `Features.premium` is on. | `PremiumViewModel.swift:126-129` | Matches |
| Tests | No XCTest target (0 hits in the pbxproj). Headless `swiftc` harnesses run from `tools/check_*.sh`. | `tools/check_premium.sh:98-102` | Matches. The plan's citations `:107-111` and `:109` do not exist (the file has 104 lines). |
| Asset symbols | Generated. `learned_icon` becomes `.learnedIcon`. | DerivedData `GeneratedAssetSymbols.swift:98`; `project.pbxproj:414,480` | Matches the plan's inference |
| Asset catalog | **`OneWord/Assets.xcassets`** is the only catalog in the repo | `find` | **Mismatch.** The plan writes `Assets.xcassets/…` and says its paths are relative to the project root (see M2). |

### Files and symbols opened

| File | Lines |
|---|---|
| `/Users/hariom/.claude/agents/plan-auditor.md`, both briefs | all |
| `/Users/hariom/Desktop/One Word/Docs/02_Plan/PAYWALL_PLAN.md` | 1–555 |
| `/Users/hariom/Desktop/One Word/OneWord/ViewModels/PremiumViewModel.swift` | 1–140 |
| `/Users/hariom/Desktop/One Word/OneWord/Shared/Premium.swift` | 1–54 |
| `/Users/hariom/Desktop/One Word/OneWord/Views/PremiumBar.swift` | 1–131 |
| `/Users/hariom/Desktop/One Word/OneWord/Views/PremiumView.swift` | 1–469 |
| `/Users/hariom/Desktop/One Word/OneWord/Views/ProfileView.swift` | 1–820 |
| `/Users/hariom/Desktop/One Word/OneWord/Views/RootView.swift` | 20–40, 75–100, 136–290 |
| `/Users/hariom/Desktop/One Word/OneWord/OneWordApp.swift` | 1–104 |
| `/Users/hariom/Desktop/One Word/OneWord/Shared/Theme.swift` | 1–172 |
| `/Users/hariom/Desktop/One Word/OneWord/Models/{Features,Wordbook,DoodleTheme}.swift` | all / 1–80 / 50–70 |
| `/Users/hariom/Desktop/One Word/OneWord/Views/{HomeView,FeedbackView,SyncToast,PaneHeader,DictionaryPicker}.swift` | 25–40 and 140–240 / 1–70 and 115–140 / 40–58 / 1–30 / 1–20, 52–63, 190–240 |
| `/Users/hariom/Desktop/One Word/OneWord/ViewModels/FeedbackViewModel.swift` | 20–45, plus the `feat/website` copy at 24–34 |
| `/Users/hariom/Desktop/One Word/StoreKit/OneWord.storekit` | 1–140 |
| `/Users/hariom/Desktop/One Word/tools/check_premium.sh` | 1–104 |
| `/Users/hariom/Desktop/One Word/OneWord.xcodeproj/project.pbxproj` | grep, plus 536–580 |
| `/Users/hariom/Desktop/One Word/OneWord.xcodeproj/xcshareddata/xcschemes/OneWord.xcscheme` | 55–66 |
| `/Users/hariom/Desktop/One Word/OneWord/Assets.xcassets/` | tree, plus `Dictionary_of_EverydayEnglish.imageset/Contents.json` |
| `/Users/hariom/Desktop/One Word/Docs/00_Context/{ARCHITECTURE,REPO_MAP,DESIGN_BRIEF}.md` | 35–46 and 115–195 / 25–61 / grep |
| `/Users/hariom/Desktop/One Word/Docs/02_Plan/CAT_UI_PLAN.md` | grep (§3.0, §3.6, §4, §5) |
| `/Users/hariom/Desktop/One Word/Docs/02_Plan/Resolved/{PREMIUM,WEBSITE,ONBOARDING}_PLAN_RESOLVED.md` | grep, plus WEBSITE 78–95 and 305–315 |
| `feat/website` via `git show` | `site/firebase.json`, `site/public/privacy.html` (grep) |

### SDK interfaces checked (Xcode 27 SDKs)

- `SwiftUI`, `SwiftUICore` and `_StoreKit_SwiftUI` `.swiftinterface`, plus the swiftdoc text, for:
  - `SensoryFeedback`
  - `KeyframeAnimator` and `KeyframesBuilder`
  - `Canvas`
  - `phaseAnimator`
  - `presentationDetents`, `presentationDragIndicator` and `presentationBackground`
  - `restorationBehavior`
  - `manageSubscriptionsSheet`
  - `PurchaseAction`
  - `SubscriptionStoreView`
- `StoreKit` (macOS and iOS), for `showManageSubscriptions` and `Transaction.productType`.
- `Accessibility`, for `AccessibilityNotification.Announcement`.
- `CoreGlyphs` `name_availability.plist`, for `crown.fill`.

---

## 2. Verdict

**Ready to build. Steps 1–3 can start now. Before Step 4, the operator should answer F1 and the plan text should get the M1–M3 fixes. Confidence: medium-high.**

I found nothing that would fail to compile, race, or lose data if the plan is built as intended. I re-opened about 60 cited `file:line` locations. All but four held up, and the four are line-number drift or a path prefix, not wrong claims.

**APIs.** Every API the plan names exists on iOS 17 / macOS 14 per the SDK's `@available` annotations. That includes `.manageSubscriptionsSheet` being `@available(macOS, unavailable)`, which the plan's `#if os(iOS)` already handles.

**The celebration signal (D3/D4) is correct:**
- `handle(_:)` has exactly one caller, `UnlockButton.buy` (`PremiumBar.swift:125`).
- Launch, restore and `Transaction.updates` all go through `refresh()` and never reach `handle`'s `.success(.verified)` arm.
- The haptic and the trigger skip their initial value, so reopening the sheet never re-fires them.

**The free Profile stays visually identical.** The only changes are the price text and a VoiceOver-only hint.

**What remains is plan-text fixes plus one operator answer:**
- Step 4 removes the owner branch two commits before Step 6 replaces it (M1).
- The asset catalog path is wrong as written (M2).
- The cat art is sequenced as a release-only dependency, but it gates compilation (M3).
- R1's escape hatch is weaker than stated (M4).
- F1, sheet versus "separate screen", changes the shape of Steps 4–5 if the operator reads it differently. It should be answered before Step 4, not after.

---

## 3. Blocking findings

None found. Each item that came close is graded down below with its reason. M2 would break the build only if followed literally, and Step 3's own verify catches it.

---

## 4. Major findings

### M1. Step 4 removes the owner's Profile branch two commits before Step 6 adds its replacement

**Where in the plan:** Step 4 (plan lines 305–312), Step 4 verify (line 318), and Step 6 (line 370).

**What's wrong:**
- Step 4 says: "In `plans` (`:488-510`), drop `owned`", with `planCard("Free", current: true…)` and an unconditional `UnlockButton(… open:)`.
- The swap that keeps owners out of `plans`, `if premium.isUnlocked { premiumCard(t) } else { plans(t) }`, only lands in Step 6.
- So from the Step 4 commit through Step 5, an owner's Profile shows **Free tagged "Current" plus a Buy pill**.
- Tapping that pill opens a paywall that immediately renders `thanks`, because the body is `Group { if premium.isUnlocked { thanks } else { offers } }`.
- Step 4's own verify, "Profile flips to owned (still the old cards until Step 6)", would therefore fail: with `owned` gone, the old cards cannot flip.

**Evidence:**
- `ProfileView.swift:76` calls `plans(t)` for everyone.
- `ProfileView.swift:489-497` holds the `owned` branches that move the tag and hide the pill today.

**Fix:** Two options.
- In Step 4, touch `plans` only to add `open: { paywall = true }` to the existing `UnlockButton(name: "Buy Premium", verb: "Buy")` at `:498`, and keep `owned`. Then do the `owned` removal and the body swap together in Step 6.
- Or move the body swap into Step 4.

**Severity / confidence:** Major, high confidence. Users are only exposed if an intermediate commit ships. But the plan promises "every step builds green" with a verify per step, and a builder will hit a failing verify and may go looking for a view-model bug that isn't there.

### M2. Asset catalog paths are wrong as written

**Where in the plan:**
- Line 5: "Every path below is relative to the project root".
- Line 45: `Assets.xcassets/Dictionary_of_EverydayEnglish.imageset/Contents.json`.
- Line 113: `Assets.xcassets/Cat/Poses/{cat_cushion,cat_cafe}.imageset`.
- Step 3 table, lines 221–223.

**What's wrong:**
- The only catalog is `OneWord/Assets.xcassets`. `REPO_MAP.md:30` lists it under the `OneWord/` section.
- A catalog created at `<root>/Assets.xcassets` sits outside the synchronized `OneWord/` group and joins no target.
- `.catCushion` and `.catCafe` would then never be generated, and Step 4's `Image(.catCushion)` would fail to compile.

**Evidence:** `find` returns only `./OneWord/Assets.xcassets`. The symbol naming itself is right: `GeneratedAssetSymbols.swift:98` maps `learned_icon` to `learnedIcon`. CAT_UI_PLAN uses the same shorthand (`CAT_UI_PLAN.md:163,267`), which is likely where this came from.

**Fix:** Use `OneWord/Assets.xcassets/Cat/Contents.json`, `…/Cat/Poses/Contents.json` and `…/Cat/Poses/cat_{cushion,cafe}.imageset/` everywhere in the plan.

**Severity / confidence:** Major, high confidence. Step 3's verify ("`ImageResource.catCushion` … generated") would catch it right away, so this is build friction rather than a shipped bug.

### M3. The cat art is sequenced as "blocks release only", but it gates compilation of Steps 4–5

**Where in the plan:**
- Step 0, line 143: "runs in parallel; blocks release only".
- §11, line 512: "Gates release only".
- Step 3, line 515: "Unblocks Steps 4 and 5".
- D8, line 132: "A missing asset then fails the build".

**What's wrong:**
- Step 3 cannot run without Step 0's two PNGs.
- Because of D8's generated symbols, Steps 4 and 5 cannot compile without Step 3.
- How the PNGs are fetched is "from the artifact by asset id" on a claude.ai URL (`CAT_UI_PLAN.md:323`). Whether a build session can download those is `[Unverified]`.
- R7's exit ("delete the two `Image(.cat…)` overlays") exists, but it is filed as a risk, not as the planned path when the art isn't available.

**Fix:**
- Mark Step 0's art bullet as a prerequisite of Step 3, not a release gate.
- Add one sentence: "If the PNGs aren't in hand, land Steps 4–5 without the two overlays (and without `Breathe` call sites), and add them in a follow-up commit once Step 3 lands."

**Severity / confidence:** Major, medium-high confidence. This is a likely mid-build stall.

### M4. R1's cheapest exit is weaker than stated

**Where in the plan:** R1 (line 499): "Submit Lifetime only (F10). This is config-only because of D6." F10 (line 493) shows `perks` on the paywall and on the gold card.

**What's wrong:**

(a) **"Lifetime only" doesn't remove the mock claims.**
- The paywall still renders `PaywallView.perks` above the Lifetime card.
- The operator asked for mock points on the owner's card: "when tapped features of premiun( for now show some mock points …)". The plan also puts them on the sales surface, which is where Guidelines 2.3 and 3.1.2(c) apply.

(b) **"Config-only" depends on store state.**
- `[Inference]` Products in "Ready to Submit" are typically still returned by `Product.products(for:)` in the sandbox environment App Review uses.
- If so, a reviewer could still see and try to buy subscriptions that weren't attached to the version.

(c) **The product copy is also untrue right now.**
- The bundled descriptions say "Every dictionary, unlocked for good." / "…renewed each year." / "…renewed each month." (`OneWord.storekit:21,99,121`).
- Today every shipped shelf is free (`Premium.swift:28`).
- Step 0 doesn't mention rewriting the App Store Connect equivalents.

**Fix:**
1. Decide (Q2) whether the paywall shows `perks` before they're real. The smallest safe default is to render the list only on the gold card.
2. Add a one-line `Features` flag in the project's own idiom (`Features.swift:5-6`, "Flip a flag, not a branch") that drops the two subscription ids from `load()`'s set. "Lifetime only" then becomes a flag flip rather than a bet on store state.
3. Add "make IAP display names and descriptions true for this release" to Step 0.

**Severity / confidence:** Major for release, not for build. Confidence is high for (a) and (c), medium-low for (b).

---

## 5. Minor findings and nits

**Plan text and citations**
- **m1. Harness metadata leaked into the plan file.** `PAYWALL_PLAN.md:552-555` contains `agentId: aa4db9eb…` and a `<usage>` block. Strip it **before** this audit is filed: CLAUDE.md says never to overwrite a plan once an audit has challenged it.
- **m2. Stale line citations.** `tools/check_premium.sh:107-111` and `:109` don't exist. `swiftc` is at `:98-102` and `Premium.swift` is compiled at `:101`. `project.pbxproj:363` and `:371` are the widget's Release config. The claims themselves are true.

**Things the plan left `[Unverified]` that are now verified**
- **m3. Mac haptic (R4, §12).** The SDK swiftdoc says `.success` "Only plays feedback on iOS and watchOS", `.levelChange` "Only plays feedback on macOS", and `.alignment` "iOS and macOS". The plan's `Self.feel` split compiles and has the right shape. However, the repo already has a Mac haptic precedent: `NSHapticFeedbackManager.defaultPerformer.perform(.generic, …)` in `DictionaryPicker.swift:232-237`, whose comment at `:194-195` says `.error` has no Mac rendering. Cite it and pick one approach on purpose.
- **m4. `crown.fill` exists.** It is in `name_availability.plist` as "2020" (iOS 14 / macOS 11). The fallback can go.

**Code details to adjust**
- **m5. §6's "timing guarantee" is overstated.**
  - If `handle`'s `refresh()` loses the generation race (`PremiumViewModel.swift:81`), it returns without calling `set`, but `bought` still bumps.
  - The result is confetti over the offers for a moment before a newer refresh flips the view to `thanks`. D4's root placement makes this harmless.
  - Either soften the claim, or bump `bought` only `if isUnlocked` after `refresh()`. The second also covers a verified purchase whose entitlement isn't listed yet.
- **m6. Button styles on the gold card.** The plan doesn't specify `.buttonStyle(.plain)` for the header `Button` or for Manage Subscription. On macOS a default-styled Button draws a bezel. Every other Profile button uses `.plain` (e.g. `ProfileView.swift:169,202,225`).
- **m7. Label precedence.** `subscribed ? "Subscription" : "Lifetime"` labels someone who owns both as "Subscription". Consider showing "Lifetime" while still offering Manage when a subscription renews.
- **m8. Parameter order.** Declare `UnlockButton.open` **after** `verb`, so the call `UnlockButton(name:verb:open:)` matches the memberwise order.

**Look and feel to check by eye**
- **m9. iPad gets a mix of the two layouts.**
  - Card layout follows `#if os(macOS)`, so iPad cards stack.
  - Button and cat sizes follow `isPhone`, so iPad gets the Mac sizes without the phone's 96pt bottom padding.
  - This is probably fine in a form sheet, but the plan should say so. iPad is already in the test matrix.
- **m10. Midnight on iPhone, `[Inference]`.**
  - The sheet's drag indicator follows the presentation's dark traits, not `.environment(\.colorScheme, .light)`, so it may be nearly invisible on `#FEFBF7`. Midnight is the default look, so check this in Step 4.
  - Midnight's `.tint` (`RootView.swift:184,214`) also reaches into the sheet. Add `.tint(t.accent)` on the paywall root.
- **m11. The Mac sheet can be bigger than its window.** The 760×600 sheet can exceed a shrunken window (the default is 1000×680). It's a knob; note it.
- **m12. Confetti stays inside the sheet.** On iPhone it falls within the sheet, 584pt tall, not over the whole screen. That is likely intended (it matches the board); flag it in Step 5's eyeball check.

**Housekeeping**
- **m13. Shared/ placement.** D11 puts app-only paywall math in `Shared/`, which compiles into the widget, to save a gate file. CLAUDE.md's routing table reserves `Shared/` for what the widget must read. It's an acceptable trade; say so in the `ponytail:` comment.
- **m14. An unreproducible verify.** Step 5's "Restore with an existing transaction shows the thank-you without confetti" probably can't be set up with local StoreKit testing. An existing transaction unlocks at launch (`PremiumViewModel.swift:60-61`), so the free paywall is never shown. Mark it as a sandbox, second-device check.
- **m15. Nits.**
  - The README dossier line "planned, not built" will be stale in the same commit that finishes the build.
  - The paywall's own `privacy` URL will duplicate `FeedbackViewModel.privacyPolicy` once `feat/website` merges.
  - The free pill's VoiceOver label still reads "Buy Premium, $169.99" for an action that now opens plans. This is F7 territory.

---

## 6. Coverage gaps

These are things the plan leaves out, as opposed to things it gets wrong.

- **No sandbox or TestFlight pass.** All purchase checks use the Xcode StoreKit config. R2 (the purchase flow presented from a Mac sheet), subscription renewal and expiry, and the F5 restore path all deserve one real-sandbox run before submission. `PREMIUM_PLAN_RESOLVED.md` check #12 ran "Restore, for real" the same way.
- **IAP metadata accuracy.** The product names and descriptions in App Store Connect and in `.storekit` describe unlocking dictionaries (see M4c).
- **Subscriber to Lifetime upgrade.** Owners never see the paywall, so an active subscriber has no in-app way to buy Lifetime (Q5).
- **No `#Preview` for `PaywallView`.** It would need `.environment(PremiumViewModel())`. Step 3's verify relies on a `#Preview` for the symbol check.

---

## 7. What the plan got right

**Grounding**
- About 60 citations were re-opened. All but four hold, and those four are line-number or path-prefix drift.
- `Theme.cat`'s values match `CAT_UI_PLAN.md:122-131` exactly.
- The "8 books" count is right (`Wordbook.swift:56`, minus `saved`).
- One subtle catch is handled correctly. The dormant pane's `PremiumView.books` (locked shelves) is **empty** today, because every shipped shelf is free. Passing `shelf` to the paywall's fan is therefore right, and `hero` keeps its current empty-fan behaviour.

**The celebration signal**
- `bought` is bumped only in the `.success(.verified)` arm of `handle`, and `handle` has a single caller.
- Using an `Int` follows the existing `kept` pattern (`HomeView.swift:32,149,164`).
- Root placement is right: the thanks view appears in the same update in which `bought` changes, so a trigger inside it would never fire.
- `KeyframeAnimator(trigger:)`, `.sensoryFeedback(_:trigger:)` and `onChange` without `initial:` all skip their initial value. Reopening the sheet never re-fires, and launch and restore never celebrate.

**State design**
- D2 makes `product` a computed lifetime, so `PremiumBar.swift:88` and `PremiumView.swift:222,226` compile untouched.
- D6 keeps `storeUnavailable` meaning "lifetime didn't load", so the free Profile doesn't change when a subscription isn't live yet.

**API availability**
- `KeyframesBuilder` accepts bare keyframes for a `Double` value (it has a `buildExpression` for `KeyframeTrackContent`).
- `Canvas`'s renderer closure is neither `@Sendable` nor isolated, so R5 is low-risk as rated.
- `restorationBehavior` really is macOS 15+, so F1's cost note is accurate.
- `showManageSubscriptions` is also macOS-unavailable, so `openURL` is the right Mac route.

**Other reasoning that checks out**
- Avoiding `.preferredColorScheme` inside a sheet matches the sheet-is-its-own-window note in `FeedbackView.swift:19-22`.
- The savings math checks out. Decimal gives 16.6166… and truncates to 16. Double gives 19.999999999999996 for 120 / 12.5, so the boundary check would catch a swap to Double.
- The contrast numbers check out under WCAG 2.1: 7.17, 11.6, 4.5 and 6.72 to 1.
- The free Profile's only visible change is the price text, as the plan says.

**Scope and house style**
- There is one StoreKit owner, no new view model, no new script, and the gate wiring comes for free through `check_premium.sh`, which is already in the CLAUDE.md loop.
- The plan is honest about what can't be tested headless.
- Its forks are well formed, and the risk table is mostly honest.

---

## 8. Operator questions

**Q1. F1: what does "a separate screen in mac" mean?** *(Answer before Step 4.)*
- The plan defaults to a `.sheet`. That is a modal attached to the main window.
- You use "screen" for panes elsewhere: "the profile screen's ui should update", "the free user profile screen will look the same". On the Mac, Profile is a pane inside the main window.
- The brief describes MacPremiumThanks as "a centred modal over a dimmed window". That suggests the canvas draws the paywall as window content with the thank-you as a modal over it. `[Inference]` I haven't opened the canvas.

Three readings:
- **(a) A sheet**, as planned.
- **(b) A pane in the main window.**
  - Re-point `Pane.premium` to it; Profile already holds `@Binding var pane` (`ProfileView.swift:28`).
  - On iPhone, `route` would *push* `.premium` instead of showing a bottom sheet (`RootView.swift:151-153`), so this needs a platform split.
  - The thank-you would then be the sheet.
- **(c) Its own `Window`.** The costs are in F1.

Readings (b) and (c) change how Steps 4–5 present the paywall. The view-model and asset work in Steps 1–3 doesn't change.

**Q2. Should the mock perks appear on the paywall, or only on the owner's gold card (what you asked for)?** The paywall is the surface App Review judges for accuracy (M4a).

**Q3. If real Premium features don't exist by submission, what ships?**
- Lifetime only? Then add the one-line subscriptions kill switch (M4b).
- The full paywall with true copy?
- Or hold the paywall?

**Q4. Is a Mac haptic that effectively never plays acceptable?** Mac haptics need a Force Touch trackpad with a finger on it, and the purchase ends in a system dialog. Your definition of done says "Mac and iPhone both"; the plan's R4 accepts that the Mac part may never be felt.

**Q5. Should an active subscriber see a way to switch to Lifetime on the gold card?** Today owners never reach the paywall.

**Q6. F7: is the free Profile's pill wording right?**
- It keeps reading "Buy — $169.99" but now opens a plan picker that defaults to Yearly at $149.99.
- Keeping it preserves "looks exactly like the current one".
- Relabelling it, e.g. "See plans", would be clearer but changes the free Profile.

**Q7. F5: on Restore inside the paywall, should it show the thank-you without confetti (the plan's default), celebrate, or just dismiss?**

---

## 9. What would change the verdict

- **Moves toward partial rework (Steps 4–5 only):**
  - Q1 is answered (b) or (c).
  - Or Step 4's Mac purchase shows R2 failing: no StoreKit dialog from a sheet.
  - Steps 1–3 and Step 6 survive either way.
- **Moves to "Fix blockers first":**
  - M2 isn't corrected before handing the plan to a build agent that follows paths literally.
  - Or M3's art isn't available and no "build without overlays" path is adopted. Step 4 then cannot compile.
- **Stays "Ready to build":**
  - F1 is confirmed as a sheet.
  - The M1–M3 text fixes are applied (each is a sentence or a path).
  - m1's footer is stripped before this audit is filed.
- M4 and Q2/Q3 gate **submission**, not the build. They should be settled before Step 0's App Store Connect work is final.
