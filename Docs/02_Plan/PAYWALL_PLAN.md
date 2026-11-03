# Paywall: Plan

This plan adds a paywall, a golden Premium card on Profile for owners, and a purchase celebration. The paywall sells Monthly and Yearly in one card with a corner toggle, plus a Lifetime card. It opens as a sheet on the Mac and as an expandable bottom sheet on iPhone. The celebration is confetti, a "Welcome to the Premium Club" thank-you, and a success haptic. Purchases go through StoreKit 2 with no sign-in. Nothing is gated: `Features.premium` stays `false`. A free reader's Profile looks the same as today.

> **Paths.** Every path below is relative to the project root, `/Users/hariom/Desktop/One Word`, on `release/1.1.0` @ `9c0bdf9`. Line numbers are as of that commit. The symbol named beside each citation is the anchor that lasts.
>
> **Upstream.** There is no strategy doc, so this plan is weaker than one built on a strategy. The inputs are the operator's words, as quoted in the brief, and the Claude Design canvas "Pencil Cat Mascot" (boards MacPremium, PhonePremium, MacPremiumThanks, PhonePremiumThanks). The canvas is treated as inspiration, not a pixel spec, the same stance as `Docs/02_Plan/CAT_UI_PLAN.md`. These docs are honoured and not relitigated: `PREMIUM_PLAN_RESOLVED.md`, `CAT_UI_PLAN.md` §3.0, §3.6 and §5's breathe spec, and `ONBOARDING_PLAN_RESOLVED.md`. That plan's `PlanPair` is not built, and nothing here depends on it.
>
> **Scope shape.** This is a **single change** of seven ordered commits. Every step builds green on both platforms. The pieces land, get verified and revert together, so there are no leaves.

---

## 1. Header

### Files read

| File | Lines |
|---|---|
| `~/.claude/agents/ios-planner.md`, the brief | all |
| `CLAUDE.md`, `Docs/00_Context/REPO_MAP.md`, `ARCHITECTURE.md`, `DESIGN_BRIEF.md`, `Docs/README.md` | all (README 1–200) |
| `Docs/02_Plan/CAT_UI_PLAN.md` | 1–24, 83–265, 321–417, 508–560 |
| `Docs/02_Plan/Resolved/PREMIUM_PLAN_RESOLVED.md` | outline + D4/D12 |
| `Docs/02_Plan/Resolved/WEBSITE_PLAN_RESOLVED.md` | 38–350 (grep) |
| `Docs/02_Plan/Resolved/ONBOARDING_PLAN_RESOLVED.md` | PlanPair rows |
| `OneWord/ViewModels/PremiumViewModel.swift` | 1–140 |
| `OneWord/Shared/Premium.swift` | 1–54 |
| `OneWord/Views/PremiumBar.swift` | 1–131 |
| `OneWord/Views/PremiumView.swift` | 1–469 |
| `OneWord/Views/ProfileView.swift` | 1–820 |
| `OneWord/Views/RootView.swift` | 1–400 |
| `OneWord/OneWordApp.swift` | 1–104 |
| `OneWord/Models/Features.swift`, `DoodleTheme.swift` | all / 1–140 |
| `OneWord/Shared/Theme.swift` | 40–172 |
| `OneWord/Views/HomeView.swift` | 25–60, 120–240, 262–275 |
| `OneWord/Views/FeedbackView.swift` | 1–60, 125 |
| `OneWord/Views/SettingsView.swift` | 315–360 |
| `OneWord/Views/SyncToast.swift` | 40–58 |
| `OneWord/Views/PaneHeader.swift` | 1–80 |
| `OneWord/ViewModels/FeedbackViewModel.swift` | 1–45 |
| `OneWord/Models/Wordbook.swift` | 20–56 |
| `StoreKit/OneWord.storekit` | 1–140 |
| `tools/check_premium.sh` | all |
| `OneWord.xcodeproj/project.pbxproj` (grep) | 363, 369, 371, 414, 463, 470, 480, 573–578 |
| `OneWord.xcscheme` | 60–62 |
| `Assets.xcassets/Dictionary_of_EverydayEnglish.imageset/Contents.json` | all |
| `feat/website` (via `git show`): `site/firebase.json`, `site/public/privacy.html`, `FeedbackViewModel.swift:28-31` | all |

### Detected stack (confirmed from disk)

| Aspect | Finding | Evidence |
|---|---|---|
| Build | One `.xcodeproj`. App target plus widget target. Xcode 16 synchronized groups. `Shared/` is listed by explicit path. | `REPO_MAP.md` "Adding files"; `CLAUDE.md` |
| Platforms | iOS 17 (iPhone + iPad, family `1,2`) and macOS 14 | `project.pbxproj:363,463,578` |
| Deps | SPM: Firebase and GoogleSignIn, both unused while `Features.accounts` is off. No StoreKit or UI libraries. | `OneWordApp.swift:10-11,53`; `Features.swift:21` |
| UI | SwiftUI, with no toolbars; each pane draws its own header | `PaneHeader.swift:1-10` |
| Architecture | MVVM. View models are `@Observable` and import Observation/StoreKit, never SwiftUI. Exemplar: `PremiumViewModel.swift:14-19`. | `ARCHITECTURE.md:37-44` |
| Concurrency | Swift 5 mode. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `MEMBER_IMPORT_VISIBILITY = YES`. | `project.pbxproj:371,573-576` |
| State | `@Observable` + `@State`/`@Environment`. `PremiumViewModel` is app-owned and injected. | `OneWordApp.swift:35,85,93` |
| Persistence | UserDefaults/App Group. Premium mirrors StoreKit into the App Group only when `Features.premium` is on. | `PremiumViewModel.swift:126-129` |
| Network | StoreKit only. No URLSession in this path. | `Features.swift:18-21` |
| DI seam | Environment injection of the view models | `OneWordApp.swift:83-85` |
| Testing | No XCTest target. Headless `swiftc` harnesses in `tools/check_*.sh`; `check_premium.sh` compiles `Shared/Premium.swift` by path. | `tools/check_premium.sh:107-111` |
| Purchase testing | `StoreKit/OneWord.storekit` on the OneWord scheme's Run action | `OneWord.xcscheme:60-62` |
| Asset symbols | On at project level | `project.pbxproj:414,480` |
| Strings | No String Catalog: plain `Text("…")` literals | `find … *.xcstrings` returns nothing |

---

## 2. Scope & outcome

**Done when:**
1. **Free Profile.**
   - It looks as it does today. The only visible difference is the price inside the existing "Buy" pill, which StoreKit now reports as $169.99.
   - Tapping that pill opens the paywall instead of buying Lifetime outright.
2. **Paywall placement.** On the Mac it is a sheet on the main window (F1). On iPhone it is a bottom sheet with a grabber, `.medium` up to `.large`. On iPad it is a form sheet.
3. **Paywall content.**
   - A fan of covers, a serif title, and the perks list.
   - A **subscriptions card**: Monthly/Yearly with a corner toggle, the price plus its period, a "Save N%" chip computed from the two Products, a renewal line, and a Subscribe button.
   - A **Lifetime card**: price plus "once", a Buy button, and the cushion cat breathing in its corner.
   - Restore Purchase, links to Terms of Use and the Privacy Policy, and any problem line.
   - Every price is StoreKit's `displayPrice`.
4. **After a completed purchase**, the sheet turns into the thank-you: "PREMIUM", **"Welcome to the Premium Club"**, body copy, Done, and the café cat breathing. Confetti falls and a success haptic fires. Launch, Restore and `Transaction.updates` never set off the confetti or the haptic.
5. **Owner's Profile.** In place of the plan cards, a **golden Premium card** appears. Tapping it expands the mock perks. A subscriber also gets "Manage Subscription".
6. **Nothing is gated.** `Features.premium` stays `false`, and `Premium.free` / `allows` / `set` do not change.

**In scope:** loading all three products, the price edits in the StoreKit config, the two cat PNGs, one new view file, edits to PremiumViewModel, Premium, PremiumBar, PremiumView and ProfileView, one extended gate, and the `00_Context` docs.

**Out of scope:**
- The Cat UI theme (Besley, palettes, `CatArt`).
- Gating any feature, sign-in, intro or offer codes.
- Redesigning `PremiumView` / `Pane.premium` (it stays dormant, D12).
- The sidebar `PlanTag`.
- A website terms page (Apple's standard EULA applies, per `WEBSITE_PLAN_RESOLVED.md:81`).

---

## 3. Architecture fit

The new code is one View file plus small edits. No new view model is added: `PremiumViewModel` stays the one StoreKit owner (`PremiumViewModel.swift:5-11`, `ARCHITECTURE.md:130-131`).

| Type / file | Layer, target | Responsibility | Mirrors |
|---|---|---|---|
| `PaywallView` **NEW** (`OneWord/Views/PaywallView.swift`) | Views, app | The sheet. Offers state, then the thanks state; `static let perks` (the one mock list). | `FeedbackView` (one sheet, compose → thanks, `FeedbackView.swift:31-38,125`); `PremiumView` cards (`:420-435`) |
| `Confetti` (private, same file) | Views | A `KeyframeAnimator`-driven `Canvas` burst keyed on an `Int` trigger | `HomeView.ribbonDrop` (`HomeView.swift:164-205`) |
| `Piece` (private, same file) | Views | One confetti piece: start, drift, spin, colour | `nonisolated struct DoodleTheme` (`DoodleTheme.swift:58`) |
| `Breathe` (private, same file) | Views | The cat's idle: `phaseAnimator`, still under Reduce Motion | `CAT_UI_PLAN.md` §5 "Idle" |
| `extension Theme { static let cat }` (same file) | Views, app only | The canvas's light Cat page, used only by the paywall | `Theme.umber` (`Theme.swift:93-103`); values from `CAT_UI_PLAN.md` §4 |
| `PremiumViewModel` *MODIFIED* | ViewModels | Adds `products` by id, `product` as a computed lifetime, `subscribed`, and the `bought` counter | itself |
| `Premium` *MODIFIED* | Shared (app + widget) | Adds `yearlyID`, `monthlyID` and `savings(yearly:monthly:)` | itself (`nonisolated enum`) |
| `UnlockButton` *MODIFIED* | Views | Adds `open:` (the pill opens the paywall); `buy` becomes `static`, shared with the paywall | itself (`PremiumBar.swift:71-131`) |
| `PremiumView.fan` *MODIFIED* | Views | Becomes `static func fan(_:height:scale:)` so the paywall reuses it | itself (`:116-132`) |
| `ProfileView` *MODIFIED* | Views | Owners get `premiumCard(t)`; the free pill opens the paywall | `plans` / `planCard` (`:483-529`) |
| Assets **NEW** | `Assets.xcassets/Cat/Poses/{cat_cushion,cat_cafe}.imageset` | The two cat drawings, in the 1x slot | `Dictionary_of_*.imageset` (1x slot only); folder per `CAT_UI_PLAN.md` §3.0 |

**Native option considered (ladder rung 4):** StoreKit's `SubscriptionStoreView` (iOS 17 / macOS 14) builds a compliant subscription paywall for free. I rejected it here for two reasons:
- The operator's locked layout (one card toggling two subscriptions, plus a separate Lifetime card, plus the cat) doesn't map onto its control styles.
- It can't hold the non-consumable.

It stays the fallback if App Review flags the custom paywall's disclosures (R1).

### Decisions the code made

| # | Decision | Forced by |
|---|---|---|
| D1 | Extend `PremiumViewModel`; add no `PaywallViewModel`. | It is "the app's one StoreKit owner" (`PremiumViewModel.swift:5`). `Premium.set` has a single caller (`ARCHITECTURE.md:130-131`). |
| D2 | `products: [String: Product]`. `product` stays as a **computed** lifetime, so `UnlockButton`, `PremiumView` and `PremiumBar` compile untouched. | `PremiumBar.swift:88`, `PremiumView.swift:222,226` read `premium.product`. |
| D3 | The celebration signal is `bought: Int`, bumped **only** in `handle`'s `.success(.verified)` arm. | That arm is reached only from a user-initiated `PurchaseAction` (`PremiumBar.swift:120-129`). `refresh()` is shared by launch (`:61`), `Transaction.updates` (`:38-43`) and restore (`:119`), so it can't tell them apart. It is an Int, not a Bool, because of trigger semantics: see `kept` (`HomeView.swift:32,149,166`). |
| D4 | Confetti, haptic and announcement are attached to the **paywall's root**, not inside the thanks content. | The thanks view is inserted in the same update in which `bought` changes. A trigger inside it would read the new value as its *initial* one and never fire. `KeyframeAnimator(trigger:)` also skips its initial value, which is why it's safe on the root. |
| D5 | Buying stays on `@Environment(\.purchase)` → `premium.handle`. `UnlockButton.buy` becomes `static` and is shared. | The VM must not import SwiftUI (`PremiumViewModel.swift:8-9`). There is no second copy of the begin/handle/failed sequence. |
| D6 | `storeUnavailable` keeps its meaning ("lifetime didn't load"). The paywall derives each card's availability itself, and a card the App Store didn't return isn't drawn. | The free Profile's note (`ProfileView.swift:490`) and pill (`PremiumBar.swift:91`) read it. Widening it would change the free Profile whenever a subscription isn't live in App Store Connect. |
| D7 | `plans(t)` renders only for non-owners, so its `owned` branches go. The only change is the pill's action. | `ProfileView.swift:489-497`. An owner now gets `premiumCard`. |
| D8 | Cat art is referenced through generated `ImageResource` symbols (`Image(.catCushion)`). | Asset symbols are on (`project.pbxproj:414,480`). A missing asset then fails the build, not the screen. This mirrors `CAT_UI_PLAN.md` D6 `[Inference: snake_case → .catCushion]`. |
| D9 | The cats live under `Assets.xcassets/Cat/Poses/`. | `CAT_UI_PLAN.md` §3.0 names `cat_cushion` there, so the later Cat UI import finds it already present instead of colliding. |
| D10 | Manage Subscription: iOS uses `.manageSubscriptionsSheet`; the Mac uses `openURL` to Apple's subscriptions page. | The sheet modifier is iOS-only `[Unverified: macOS unavailability per SDK]`. |
| D11 | The savings math lives in `Shared/Premium.swift`. | `check_premium.sh:109` already compiles that file by path, so the one new check needs no new script. It is pure Foundation, safe for the widget. |
| D12 | `PremiumView` / `Pane.premium` stay dormant. Only `fan` is made reusable. | They are unreachable while `Features.premium` and `Features.practice` are off (`RootView.swift:245-247,264`; `Features.swift:13,15`). |
| D13 | Cards sit side by side on the Mac (`#if os(macOS)`) and stack on iOS, iPad included. | An iPad form sheet is roughly 540pt wide `[Inference]`, too tight for two price cards. `PremiumView`'s note on `ViewThatFits` failing to size to the column (`:55-56`) rules out letting SwiftUI choose. |

---

## 4. Implementation steps

### Step 0: App Store Connect and assets *(operator; runs in parallel; blocks release only)*

**Prices** (USD base, other storefronts equalized):

| Product | id | Price |
|---|---|---|
| Lifetime | `com.hariom.swift.oneword.premium` | 169.99 |
| Yearly | `…premium.yearly` | 149.99 |
| Monthly | `…premium.monthly` | 14.99 |

**Before release:**
- Set each subscription's price before its first approval (R8).
- Subscription group "Premium": add a display-name localization, and an App Review screenshot of the paywall for each IAP.
- Attach all three IAPs to the version.

**Metadata:**
- Privacy Policy URL: `https://one-word-a2f3a.web.app/privacy` (`WEBSITE_PLAN_RESOLVED.md:93,311`).
- Terms of Use: Apple's standard EULA, linked in the App Description, since the EULA field is left blank.

**Site:** `site/` exists only on the unmerged `feat/website` branch. Before submission, `curl -sI https://one-word-a2f3a.web.app/privacy` should print 200 (R9).

**Art** (an operator or build-session step, per `CAT_UI_PLAN.md` §3.0): fetch two PNGs from the artifact by asset id. No code names an asset id.
- `50c675b315b299354651463e5565870b` → `cat_cushion` (the cat sprawled on the cushion)
- `143a622eb1a84b228c2e7124932b2b85` → `cat_cafe` (beret, scarf, coffee, croissant)

### Step 1: Prices, ids and savings math *(first reversible move; nothing calls it yet)*

| File | Change |
|---|---|
| `StoreKit/OneWord.storekit:16,92,114` MODIFIED | `displayPrice` becomes `"169.99"` (lifetime), `"149.99"` (yearly) and `"14.99"` (monthly). Nothing else. |
| `OneWord/Shared/Premium.swift:20-23` MODIFIED (Shared, both targets) | Add `static let yearlyID` and `monthlyID`; `productIDs = [productID, yearlyID, monthlyID]`. Same strings, so no stored id changes. |
| `OneWord/Shared/Premium.swift` MODIFIED | Add `static func savings(yearly: Decimal, monthly: Decimal) -> Int?` (see below). |
| `tools/check_premium.sh` heredoc MODIFIED | A "yearly savings" block of four checks (§7). |

`savings(yearly:monthly:)` computes `(1 − yearly / (monthly × 12)) × 100` in **`Decimal`**, rounded with `NSDecimalRound(…, 0, .down)`. It returns `nil` when `monthly ≤ 0` or when the result is ≤ 0.
- It rounds down so the label never overstates.
- It uses Decimal, not Double, because `Product.price` is already `Decimal`, and 120 against 12.5 gives 19.999… in Double, which would truncate to 19.
- Add a `ponytail:` note: rounding down is deliberate.

- **Isolation:** `nonisolated enum`, unchanged. Pure.
- **Verify:** `bash tools/check_premium.sh` passes, including the new block; both `xcodebuild` builds pass.

### Step 2: StoreKit plumbing *(no UI change yet)*

**`OneWord/ViewModels/PremiumViewModel.swift` MODIFIED:**

```swift
private(set) var products: [String: Product] = [:]          // replaces stored `product` (:24)
var product: Product? { products[Premium.productID] }       // lifetime — every existing caller unchanged
private(set) var subscribed = false                          // a renewing sub is among what's owned
private(set) var bought = 0                                  // bumped only by a completed purchase (D3)
```

- `load()` (`:60-64`):
  - Fetch `Product.products(for: Premium.productIDs)`.
  - `products = Dictionary(found.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })`.
  - `storeUnavailable = product == nil` stays as it is (D6).
- `refresh()` (`:71-85`):
  - Inside the loop, `if transaction.productType == .autoRenewable { renews = true }`.
  - After the generation guard, `if renews != subscribed { subscribed = renews }`. This mirrors `set`'s write-only-on-change (`:128`).
- `handle(_:)` (`:91-95`): after `phase = .idle`, add `bought += 1`, with a comment that launch, restore and updates never reach this arm.
- Update the header comment (`:5-11`): the VM now loads all three products, and `bought` is the celebration signal.

**`OneWord/Views/PremiumBar.swift` MODIFIED (`UnlockButton`, `:71-131`):**
- `var open: (() -> Void)? = nil`, documented as: "Profile's: the pill opens the paywall rather than buying Lifetime outright."
- `:89`: the action becomes `{ if let open { open() } else { Self.buy(product, with: purchase, premium) } }`, plus `.accessibilityHint(open == nil ? "" : "Shows the plans")`.
- `:120`: `private func buy(_:)` becomes `static func buy(_ product: Product, with purchase: PurchaseAction, _ premium: PremiumViewModel)`. The body is unchanged.

- **Isolation:** both types are MainActor by default. `Product.products(for:)` hops off the main actor and back, and `Product` is `Sendable`. The static `buy`'s `Task {}` inherits MainActor, so no value crosses an isolation boundary.
- **Verify:**
  - Both builds pass.
  - Xcode Run: the free Profile pill reads **"Buy — $169.99"** and still buys Lifetime directly (no `open` passed yet). That proves the VM edits didn't break the existing path.
  - In Xcode's Transaction Manager, delete the transaction and relaunch: the Profile is free again.

### Step 3: Import the two cats

| File | Change |
|---|---|
| `Assets.xcassets/Cat/Contents.json`, `Cat/Poses/Contents.json` NEW | Plain folder `{"info":{"author":"xcode","version":1}}`, with **no** `provides-namespace`, so names stay flat. |
| `Assets.xcassets/Cat/Poses/cat_cushion.imageset/` NEW | The PNG in the **1x** slot, mirroring `Dictionary_of_EverydayEnglish.imageset/Contents.json` (2x and 3x present but empty). |
| `Assets.xcassets/Cat/Poses/cat_cafe.imageset/` NEW | Same. |

- **Verify:** both builds pass, and `ImageResource.catCushion` / `.catCafe` are generated (`[Inference]`: check by referencing one in a `#Preview`). Check that the PNGs are at least 2× their largest draw width: cushion ≥336px, café ≥600px. Smaller files will look soft (R7).

### Step 4: The paywall, offers state *(the thin end-to-end slice)*

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
    /// MOCK — the one list of what Premium gives. Profile's gold card reads it too.
    /// ponytail: placeholder copy; replace when features are flagged (gates release, R1).
    static let perks: [String]
    @Environment(PremiumViewModel.self) private var premium
    @Environment(\.purchase) private var purchase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var yearly = true                         // F4
    private let t = Theme.cat                                // F2
    var body: some View
    private var offers: some View
    private var thanks: some View                            // Step 5
    private var subscriptionCard: some View
    private var lifetimeCard: some View
    private var periodToggle: some View
    private func buyButton(_ id: String, _ label: String, _ name: String) -> some View
    private func card<C: View>(emphasized: Bool, @ViewBuilder _ content: () -> C) -> some View
    private static let terms: URL     // Apple's standard EULA [Unverified URL, confirm at build]
    private static let privacy: URL   // https://one-word-a2f3a.web.app/privacy (WEBSITE_PLAN_RESOLVED F1)
}
private struct Breathe: ViewModifier
extension Theme {
    /// The canvas's light Cat page (CAT_UI_PLAN §4). ponytail: CAT_UI Phase 1 adds this to
    /// Shared/Theme.swift — this copy then won't compile (redeclaration), so delete it there.
    static let cat: Theme
}
```

**Theme values.** `Theme.cat` copies `CAT_UI_PLAN.md` §4's light column exactly: background `#FEFBF7`, surface white, ink `#1E1B26`, muted `#625D6E`, definition `#2A2633`, example `#4B4658`, accent `#5B3FD6`, rule `#E9792B`, hairline `#E9E2D6`, roundness 1.5. That plan's contrast table applies, and every text pair clears AA.

**Body.**
- `Group { if premium.isUnlocked { thanks } else { offers } }`, animated on `premium.isUnlocked`.
- `#if os(macOS) .frame(width: 760, height: 600)`, with ScrollView inside. The size is a knob.
- `.background(t.background)` and `.environment(\.colorScheme, .light)`, so `ProgressView` and `Link` draw for paper. **Not** `.preferredColorScheme`, which can escape a sheet.
- `.presentationDetents([.medium, .large])` (Step 5 makes this conditional), `.presentationDragIndicator(.visible)`, `.presentationBackground(t.background)`. This mirrors `HomeView.swift:234-236`.

**Offers layout** (top to bottom, padding 44/20 as in `PremiumView.swift:64`):
- **Close X**, top-trailing, with `.keyboardShortcut(.cancelAction)` (`FeedbackView.swift:57-58`).
- **Fan:** `PremiumView.fan(shelf, height: isPhone ? 72 : 100, scale: displayScale)`, where `shelf = Wordbook.all.filter { $0.id != SavedWords.resource }` (8 books; `PremiumView.swift:38`).
- **Title** in `Font.serif(isPhone ? 30 : 36, .medium)` (`Theme.swift:169`), then the pitch line and `perks` as checkmark rows (the `PremiumView.perk` shape, `:383-398`). Copy belongs to F10.
- **Cards** in an `HStack` on the Mac or `VStack` on iOS (D13). Each card is drawn only if `!answered || its product(s) exist`, where `answered = premium.product != nil || premium.storeUnavailable` (D6).
  - If `answered` and neither card can be drawn, show `premium.problem` plus "Try Again" (`premium.load()`).
- **Subscription card** (hairline):
  - "Premium" heading plus `periodToggle` in the top-trailing corner. That is one capsule button showing "Monthly · Yearly" with the current one filled. Tapping it runs `withAnimation(.snappy) { yearly.toggle() }`.
  - The price in serif 40 with `.contentTransition(.numericText())`, plus " / year" or " / month".
  - When `yearly` and `Premium.savings(...)` is non-nil, a chip reading "Save \(n)%" (F6).
  - The line "Renews every year at \(price) until you cancel. Cancel anytime in your App Store account settings."
  - `buyButton(yearly ? Premium.yearlyID : Premium.monthlyID, "Subscribe", …)`.
- **Lifetime card** (emphasized, F3: a 2pt `t.accent` border and the `PremiumView.card` shadow):
  - "Lifetime" heading, price plus "once", and "Pay once. Yours for good. Nothing renews."
  - `buyButton(Premium.productID, "Buy", …)`.
  - The cushion cat as `.overlay(alignment: .bottomTrailing) { Image(.catCushion).resizable().interpolation(.high).scaledToFit().frame(width: isPhone ? 118 : 168).modifier(Breathe()).offset(x: isPhone ? 8 : 30, y: isPhone ? 20 : 34).allowsHitTesting(false).accessibilityHidden(true) }`. This uses the 30pt overhang from `CAT_UI_PLAN.md` §3.6.
  - Rule: **the cat never covers a Buy button**. On the Mac the button is 160×40, leading. On the phone it is full-width at 50pt, and the card takes `.padding(.bottom, 96)` so the cat lies below it. All of these are knobs; check them by eye.
- **`buyButton`** has four branches:
  - `.purchasing` → spinner.
  - A product exists → a violet filled `Button { UnlockButton.buy(p, with: purchase, premium) }`. Mac: 40pt, radius 12. Phone: 50pt, full width, radius 14. Label: `"\(label) \(name), \(p.displayPrice)"`.
  - `answered` but no product → nothing (the card is hidden anyway).
  - Otherwise → spinner.
- **Below the cards:** "Restore Purchase" as a violet text button (`Task { await premium.restore() }`, disabled while purchasing), then `premium.problem` (`PremiumView.swift:243-254`), then `Link("Terms of Use") · Link("Privacy Policy")` at 12pt in muted.

**`Breathe`:** `phaseAnimator([false, true])`, scaling (1.006 × 1.02) anchored `.bottom`, `.easeInOut(duration: 3.6)` per phase (`CAT_UI_PLAN.md` §5; the duration is a knob). Under Reduce Motion it returns `content` untouched.

**`OneWord/Views/ProfileView.swift` MODIFIED:**
- Add `@State private var paywall = false`.
- In `plans` (`:488-510`), drop `owned`:
  - `section("Plan", t, note: premium.problem)`.
  - `planCard("Free", current: true…)`, `planCard("Premium", current: false…)`.
  - The unconditional `UnlockButton(name: "Buy Premium", verb: "Buy", open: { paywall = true })` plus Restore.
  - Rewrite the doc comment: "Free's plans; an owner sees `premiumCard` instead."
- After `.task { model.refresh() }` (`:97`), add `.sheet(isPresented: $paywall) { PaywallView() }`. The environment, including `PremiumViewModel` and `\.purchase`, propagates into sheets, as `FeedbackView.swift:28` already relies on.

- **Isolation:** everything is MainActor views. No `.task` is added.
- **Verify** (Xcode Run, StoreKit config):
  - The pill opens the paywall. On the Mac it is a sheet; on iPhone it is a bottom sheet at medium that drags to large, with the subscription price visible at medium on an SE-size simulator. If it isn't visible there, raise the first detent to `.fraction(0.6)`.
  - Prices read 14.99, 149.99 and 169.99. The toggle switches the price, and "Save 16%" shows on Yearly only.
  - Buy Monthly, then delete it; buy Yearly, then delete it; buy Lifetime. Each time the StoreKit confirmation appears **from the Mac sheet** (R2), and Profile flips to owned (still the old cards until Step 6). Cancel leaves everything as it was.

### Step 5: The thank-you, confetti and haptic

**`OneWord/Views/PaywallView.swift` MODIFIED:**

**`thanks`:**
- **Mac:** two columns at 740×420. The `#if os(macOS)` frame becomes `premium.isUnlocked ? (740, 420) : (760, 600)`; if the resize looks janky, keep one size (R6).
  - Left: "PREMIUM" (violet, 11 bold, uppercase, tracking 2), "Welcome to the Premium Club" in `Font.serif(36, .medium)`, and the body "Thank you for backing One Word. Premium is yours on every Mac and iPhone signed in to this Apple ID." (true by Universal Purchase, `ARCHITECTURE.md:120-124`).
  - A violet filled "Done" with `.keyboardShortcut(.defaultAction)` (`FeedbackView.swift:125-126`).
  - Right: `Image(.catCafe)` at 300 wide with `Breathe`, `accessibilityHidden`.
- **iOS:** stacked. The cat at 244 wide, then the label, the centred headline at serif 30, the body, and a full-width Done.
- **Entrance:** `.transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))` under `.spring(duration: 0.5, bounce: 0.25)`.
- **No "Pick a book"** (F8).

**On the root (D4):**
- `.overlay { if !reduceMotion { Confetti(trigger: premium.bought).allowsHitTesting(false).accessibilityHidden(true) } }`.
- `.sensoryFeedback(Self.feel, trigger: premium.bought)`, where `feel` is `.levelChange` on macOS and `.success` on iOS (`[Unverified]` which Mac type plays; R4).
- `.onChange(of: premium.bought) { AccessibilityNotification.Announcement("Welcome to the Premium Club").post() }`. This mirrors `SyncToast.swift:50`.
- `.presentationDetents(premium.isUnlocked ? [.height(584)] : [.medium, .large])`, which is the PhonePremiumThanks board's height.

**`Confetti`** (private):

```swift
private struct Confetti: View { let trigger: Int }   // KeyframeAnimator(initialValue: 0.0, trigger: trigger)
                                                     //   { p in Canvas { … } } keyframes: { _ in MoveKeyframe(0.0); LinearKeyframe(1.0, duration: 2.8) }
private nonisolated struct Piece { /* x0 (0…1), drift, fall speed, spin, w/h, colour */
    static let all: [Piece]                          // ~90, built once
}
```

- Draw nothing at `p == 0 || p >= 1`. That covers both the at-rest state and the finished state.
- Each piece:
  - Starts just above the top edge at `x0 × width`.
  - Falls under constant gravity scaled to `size.height`, so the burst fills any sheet size.
  - Drifts sideways along a sine wobble and rotates by `spin × t`.
  - Fades over the last 25%.
- Colours are fixed: violet `#5B3FD6`, gold `#E9B949`, coral `#F07167`, teal `#2BB3A3`, sky `#6CA8F0`, ink `#1E1B26`.
- Capture `let pieces = Piece.all` before the `Canvas`, so the renderer reads a `nonisolated` value whatever its closure's inferred isolation (R5).

- **Verify:**
  - Buy Yearly: the sheet swaps to the thank-you, confetti falls for about 2.8s, and a haptic fires (iPhone **device**; the simulator has none). VoiceOver announces the headline.
  - Done dismisses.
  - Restore inside the paywall with an existing transaction shows the thank-you **without** confetti or haptic (F5).
  - Ask to Buy (StoreKit config) shows "Waiting for approval."; after approval in Transaction Manager, the thank-you shows with no confetti.
  - Reduce Motion on: no confetti, no breathing, and the thank-you fades in.

### Step 6: The golden Premium card on Profile

**`OneWord/Views/ProfileView.swift` MODIFIED:**
- Imports (`:21-23`): add `import StoreKit   // manageSubscriptionsSheet — MEMBER_IMPORT_VISIBILITY needs it named` (the same comment style as `PremiumView.swift:26`).
- State: `@State private var perksShown = false` and `@State private var managing = false`. Environment: `@Environment(\.openURL) private var openURL`.
- Body (`:76`): `plans(t)` becomes `if premium.isUnlocked { premiumCard(t) } else { plans(t) }`.
- `#if os(iOS) .manageSubscriptionsSheet(isPresented: $managing) #endif`, beside the paywall `.sheet`.
- **`private func premiumCard(_ t: Theme) -> some View`**, placed after `planCard` (`:529`), inside `section("Plan", t)`:
  - **Header row**, a `Button { withAnimation(.snappy) { perksShown.toggle() } }`:
    - `crown.fill` (`[Unverified]` symbol name; fall back to `star.circle.fill`).
    - "PREMIUM" at 11 bold, tracking 2.
    - "One Word Premium" in `doodle.face(22)`.
    - `subscribed ? "Subscription" : "Lifetime"`.
    - A chevron rotated 90° when open.
  - **Below the header** (a sibling, **not** inside the header button, so there are no nested buttons): when `perksShown`, `ForEach(PaywallView.perks, id: \.self)` checkmark rows. When `premium.subscribed`, a "Manage Subscription" button: iOS sets `managing = true`; macOS calls `openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)` (`[Unverified]`; R10).
  - **Look:** a fixed gold `LinearGradient` from `#F6D77A` (top leading) to `#D4A52C` (bottom trailing), the same on every appearance. Ink is `#2A1E05`. Corners `t.radius(12)`, so the card sits with `ProfileCard`. Shadow `#D4A52C` at 0.35 opacity, radius 14, y 6 (a knob).
  - **Contrast**, computed by WCAG 2.1: ink against `#D4A52C` is **7.2:1**; against `#F6D77A` it is **11.6:1**. **Do not add a darker third stop**: `#B07D1A` measures 4.5:1, which is the AA floor.
  - **Accessibility:** the header gets `.accessibilityLabel("One Word Premium, \(subscribed ? "subscription" : "lifetime")")`, `.accessibilityValue(perksShown ? "Expanded" : "Collapsed")` and `.accessibilityHint("Shows what Premium includes")`.

- **Verify:**
  - Owned Lifetime: the gold card reads "Lifetime", tap expands the perks, and there is no Manage row.
  - Owned Yearly: "Subscription", plus Manage. On iPhone it opens Apple's sheet; on the Mac it opens the App Store subscriptions page (R10).
  - Delete the transactions: the free Profile is back, identical to the Step 2 screenshot.
  - Check the card on Midnight, System light and System dark.

### Step 7: Docs (`00_Context` is kept current)

**`Docs/00_Context/ARCHITECTURE.md`:**
- `:126-127`: "Today's purchase UI (`UnlockButton`) sells lifetime only" becomes "The paywall (`Views/PaywallView.swift`) sells all three; `UnlockButton` elsewhere sells lifetime."
- `:142-146` "Where it's sold": add the paywall sheet opened from Profile's Buy pill. Add that **`bought` is the celebration signal, bumped only by a completed purchase**. Add that owners see Profile's gold card, and that `PaywallView.perks` is the one list both read.
- `:190`: add `PaywallView` to the Views list.

**`Docs/00_Context/REPO_MAP.md`:**
- `:30` Assets row: "…, dictionary covers, avatars, `Cat/Poses/` (the paywall's two cat drawings, 1x slot)".
- `:52` `check_premium.sh`: "…and the yearly-savings figure".

**`Docs/README.md` Dossiers:** add "**Paywall** — planned, not built. [plan](02_Plan/PAYWALL_PLAN.md)".

Do not edit `CAT_UI_PLAN.md` or any other `01`–`06` doc.

- **Verify:** `grep -rn "PaywallView\|cat_cushion" Docs/00_Context` hits all three docs.

---

## 5. Data, persistence & API changes

- **StoreKit products:** all three are loaded once, at launch (`OneWordApp.swift:93`), and on Try Again. There are no new product ids.
- **No persistence change.** With `Features.premium` off, `set` writes nothing to the App Group (`PremiumViewModel.swift:127`). `isUnlocked` is the observed flag the gold card reads. `subscribed` and `bought` are in-memory only, and `bought` resets to 0 each launch, which is intended.
- **Widget:** unchanged. It still receives `reloadAllTimelines()` on an unlock (`OneWordApp.swift:95`), which is harmless.
- **Entitlements and expiry:** unchanged. A lapsed subscription relocks at the next refresh (`PremiumViewModel.swift:68-70`), and the gold card goes with it.
- **Errors:** the existing `Phase` and `message(for:)` (`:20,131-139`) cover the paywall, read through `premium.problem`.

## 6. Concurrency, state & memory

| Type | Isolation | Notes |
|---|---|---|
| `PremiumViewModel` | MainActor (project default) | `products`, `subscribed` and `bought` are mutated only on main. `Product.products(for:)` and the `currentEntitlements` iteration hop off main and back. `Product` and `Transaction` are `Sendable`. |
| `Premium.savings` | `nonisolated` (the enum) | Pure Decimal math. Callable from the view and the harness. |
| `UnlockButton.buy` (static) | MainActor | Its `Task {}` inherits MainActor. It captures `Product` (Sendable), `PurchaseAction` and the MainActor VM, so no boundary is crossed. It compiles today as an instance method, and making it static changes nothing about isolation. |
| `PaywallView`, `Confetti`, `Breathe` | MainActor | `KeyframeAnimator` and `phaseAnimator` are framework-driven, stop when the view leaves, and start no Tasks. |
| `Piece` | **`nonisolated struct`** | Mirrors `DoodleTheme.swift:58`, so the `Canvas` renderer can read it whatever its closure's inferred isolation. Captured as a local `let` (R5). |
| `Theme.cat` | MainActor static | Read only by views. |

- **Task lifecycle:** the purchase and restore `Task`s are unstructured and **outlive a dismissed sheet** on purpose, so a purchase in flight still lands in the VM. `Transaction.updates` keeps its existing `[weak self]` (`:38`). No `.task` is added.
- **Ownership:**
  - `@State` view-local: `yearly` (resets to Yearly on each open), `paywall`, `perksShown`, `managing`.
  - Environment: `PremiumViewModel`, unchanged.
  - The paywall needs no theme passed in: it paints a fixed palette (contrast `FeedbackView.swift:19-23`).
- **Retain cycles:** none. The `open: { paywall = true }` closure is held by a value-type view and captures a value-type `ProfileView`. The buy `Task` holds the app-lifetime VM strongly and briefly. No Combine `sink` or delegate is added.
- **Timing guarantee behind D4:** `handle` sets `isUnlocked` (inside `refresh`) and then `bought` within one MainActor turn, with no suspension after `refresh` returns. Both changes therefore land in one SwiftUI update, and nothing depends on which `onChange` runs first.

## 7. Test plan

**Headless (the only new code check):** extend the existing `PremiumCheck.swift` heredoc in `tools/check_premium.sh` with a "yearly savings" block:
- `savings(149.99, 14.99) == 16`: the real prices, rounded down. Build the inputs with `Decimal(string:)`.
- `savings(120, 12.5) == 20`: an exact boundary, which fails if anyone swaps Decimal for Double.
- `savings(180, 15) == nil`: no saving means no label.
- `savings(100, 0) == nil`: guards the divide.

**Not testable headless, and why:**
- `PremiumViewModel` needs StoreKit's runtime. The seam that would make it testable is a protocol over `Product`/`Transaction`, which would be an abstraction with one implementation (rejected per the house style).
- SwiftUI bodies, confetti and layout are verified by eye.
- The `bought` path is verified by the manual matrix below.

**Manual matrix** (Xcode Run with `StoreKit/OneWord.storekit`; never `open -n` or kill the debug run):

| # | Check |
|---|---|
| 1 | The free Profile at Mac 1000×680 and on iPhone matches a screenshot from before Step 2. The only difference is the price text. |
| 2 | Paywall: prices from the config, the toggle, "Save 16%", Restore, both links open in the browser. |
| 3 | Buy Monthly, Yearly and Lifetime (deleting transactions in between): confetti, haptic (device), announcement, gold card label. |
| 4 | Restore, Ask to Buy (approve and decline), Cancel, and a purchase error toggled in the config: thank-you with no confetti, "Waiting for approval.", unchanged, and the problem line. |
| 5 | Subscription expiry: speed up the config's time rate, let a subscription lapse, relaunch. The Profile is free again. |
| 6 | {Mac, iPhone simulator + device, iPad simulator} × {Midnight, System light, System dark} × {Reduce Motion off, on}. Spot-check VoiceOver on the toggle, the Buy labels and the gold card. |

**Gates** (all must be green): both `xcodebuild` builds, plus `for s in check_words check_related check_learned check_capture check_sentences check_premium check_sync; do bash tools/$s.sh; done`.

## 8. Accessibility, localization & project mechanics

- **VoiceOver:**
  - The cats, the fan and the confetti are `accessibilityHidden`.
  - The toggle reads its label, value and hint.
  - Buy buttons carry the product name and price.
  - The paywall title has `.isHeader`.
  - The purchase posts an announcement.
  - The gold card exposes expanded/collapsed.
  - A close button is always there, and on the Mac `cancelAction`/`defaultAction` give keyboard access.
- **Reduce Motion:** no confetti, no breathe, and the thank-you fades instead of scaling. The haptic still fires, since it isn't motion.
- **Contrast:** the paywall uses `CAT_UI_PLAN.md` §4's light values (AA on every text pair). White on violet measures 6.7:1. The gold card is computed in Step 6.
- **Dynamic Type:** fixed sizes, matching the app's existing convention. This is a pre-existing gap, not widened here.
- **Localization:** there is no String Catalog. New literals follow `Text("…")`, and prices come localized from StoreKit.
- **Target membership:** `PaywallView.swift` and the assets fall under synchronized groups, so there is no `project.pbxproj` edit and **nothing new in `Shared/`**. `Premium.swift` is an edit to an existing Shared file, which the widget and `check_premium.sh` already compile.
- **Info.plist and entitlements:** none. StoreKit IAP needs no usage string. `Link` and `openURL` are allowed in the sandbox (`FeedbackViewModel.swift:33-34`).
- **Availability:** `PurchaseAction`, `KeyframeAnimator`, `phaseAnimator`, `.sensoryFeedback`, `ImageResource`, `AccessibilityNotification` and `.presentationBackground` all fit iOS 17 / macOS 14, so no `#available` is needed. `.manageSubscriptionsSheet` is wrapped in `#if os(iOS)`.

## 9. Decision forks (operator-owned)

| # | Fork | Recommended default | The other branch wins when… |
|---|---|---|---|
| F1 | How the Mac presents the paywall | A **`.sheet` on the main window**. It shares one code path with iPhone and iPad, and `FeedbackView` already does compose → thanks in a sheet. | …you want it movable, resizable or beside the main window. Then use a `Window("Premium", id:)` scene with `openWindow`, accepting three costs: re-inject `PremiumViewModel`, the doodle and the scheme at the second scene; a "Premium" item appears in the Window menu; and on **macOS 14** `restorationBehavior(.disabled)` doesn't exist (it is macOS 15+), so a window left open likely reopens at launch `[Inference]`. A third option is to re-point `Pane.premium` to show it in-window. |
| F2 | Paywall palette | **The canvas's light Cat page on every appearance.** The cat art is drawn for paper, and the default appearance is Midnight. | …the paywall should match the reader's appearance. Then use `Theme.of(scheme, doodle)` with `t.accent`, and the cats need `CAT_UI_PLAN` D7's dark-page rim. |
| F3 | Which card is emphasized and carries the cushion cat | **Lifetime.** It is the canvas's "once" card, and the best value per dollar. | …recurring revenue is the priority. Then move the border and the cat to the subscription card. |
| F4 | The toggle's starting period | **Yearly**, so the savings chip shows. | …the lowest entry price should show first (Monthly). |
| F5 | Restore inside the paywall | **The thank-you, without confetti or haptic.** | …returning owners should be celebrated too (bump `bought` in `restore()` when ownership flips from false to true), or the sheet should simply dismiss. |
| F6 | Savings label | **On**, rounded down ("Save 16%"). | …you don't want it. Delete one `Text`, and the check stays harmless. |
| F7 | The free Profile's Buy pill | **It opens the paywall.** It looks the same, and the "Lifetime" caption above it still matches its price. | …you want one-tap Lifetime kept. Then add a "See all plans" link, which changes the free Profile. |
| F8 | Thank-you buttons | **Done only.** Nothing is gated, so "Pick a book" has nothing to pick. | …books are gated (`Features.premium` on). Then add "Pick a book" routed to `.dictionaries`. |
| F9 | How owners see the features | **Inline expansion of the gold card.** | …the list grows past about 6 rows or gains imagery. Then use a sheet. |
| F10 | Paywall copy and release | Show `perks` on the paywall and on the gold card (one list), and **treat replacing the mock perks with true statements as the gate for submitting the subscriptions.** | …1.1.0 must ship before real features exist. Then submit Lifetime only. The paywall hides any card the store doesn't return (D6), so this needs no code change. |

## 10. Risks & exits

| Risk | Severity · Confidence | Leading indicator | Cheapest exit |
|---|---|---|---|
| R1: App Review rejects subscriptions that unlock nothing, or mock or unsupported perk claims (Guidelines 3.1.2(a), 2.3) | **High** · Med | Rejection citing ongoing value or accurate metadata | Submit Lifetime only (F10). This is config-only because of D6. If the *disclosures* are what gets flagged, swap the subscription card for `SubscriptionStoreView`. |
| R2: `PurchaseAction` misbehaves when called from inside a Mac sheet `[Unverified]` | Med · Low–Med | Step 4 on the Mac: the spinner holds and no StoreKit dialog appears | F1's `Window` scene, or call `product.purchase()` for the Mac only |
| R3: The free Profile regresses visually | Med · Low | The Step 2 and Step 4 screenshot comparison | Revert the `plans` hunk; keep only `open:` |
| R4: No Mac haptic. Mac haptics need a Force Touch trackpad with a finger on it, and the purchase ends in a system dialog. | Low · **High** | Nothing felt on a MacBook | Accept it; the confetti carries the moment. Try `.alignment`/`.generic`. |
| R5: The `Canvas` renderer's isolation inference warns or errors | Low · Low–Med | A build warning in Step 5 | `nonisolated Piece` plus a local capture (already planned). Last resort: a `TimelineView` + `ForEach` of rotated `Rectangle`s. |
| R6: The Mac sheet resize or the dynamic detents look janky | Low · Med | By eye in Step 5 | One fixed size and static detents |
| R7: Cat PNGs unreachable or under-resolution | Med · Med | Step 3 fetch fails or the art looks soft | Delete the two `Image(.cat…)` overlays. Symbols make a missing asset a build error, so Step 3 catches it early. |
| R8: Subscription prices set wrong before first approval are awkward to fix later | Med · Low | An App Store Connect review in Step 0 | Check prices before attaching the IAPs |
| R9: The privacy URL isn't live (`site/` is unmerged) | Med · Low–Med | `curl -sI …/privacy` doesn't return 200 | Deploy `feat/website` before submission |
| R10: The Mac "Manage Subscription" URL doesn't open the subscriptions page `[Unverified]` | Low · Med | Step 6 on the Mac | `macappstores://apps.apple.com/account/subscriptions` |

## 11. Sequencing summary & verification

1. [ ] **Step 0** (operator, in parallel): App Store Connect prices and metadata, the site check, and fetching the two PNGs. Gates release only.
2. [ ] **Step 1**, the first reversible move: `.storekit` prices, `Premium` ids and `savings`, plus the check. **Unblocks** Step 2.
3. [ ] **Step 2**: `products`, `subscribed`, `bought`; `UnlockButton.open` and static `buy`. **Unblocks** Steps 4 and 6.
4. [ ] **Step 3**: the two imagesets. **Unblocks** Steps 4 and 5.
5. [ ] **Step 4**: `PaywallView` offers, `PremiumView.fan` made static, the Profile pill → sheet. This is the end-to-end slice. **Unblocks** Step 5.
6. [ ] **Step 5**: thank-you, confetti, haptic, announcement.
7. [ ] **Step 6**: golden card, perks, Manage Subscription.
8. [ ] **Step 7**: `00_Context` docs and the README dossier.

**After every step:**

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
for s in check_words check_related check_learned check_capture check_sentences check_premium check_sync; do bash tools/$s.sh; done
```

**End-to-end path to confirm it works:**
1. Xcode Run on the Mac with the StoreKit config.
2. Open Profile: it looks as today, and the pill reads "Buy — $169.99".
3. Tap it: the paywall sheet opens.
4. Toggle to Yearly, check "Save 16%", tap Subscribe and confirm: confetti, "Welcome to the Premium Club".
5. Tap Done: the gold card appears. Expand it to see the perks and Manage Subscription.
6. In Transaction Manager, delete the transaction and relaunch: the free Profile is back.
7. Repeat on an iPhone device (bottom sheet, drag to large, haptic) and with Reduce Motion on.

## 12. Open questions & assumptions

- `[Unverified]` Apple's standard EULA URL, `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`. *Resolved by:* opening it at build time.
- `[Unverified]` The privacy page is deployed. Its copy also says "your Mac" and "no network requests", which predates the iPhone version and iCloud sync. *Resolved by:* the `curl` in Step 0, and re-reading `site/public/privacy.html` on `feat/website`.
- `[Unverified]` `PurchaseAction` presents correctly from a Mac sheet (R2). *Resolved by:* the Step 4 Mac purchase.
- `[Unverified]` Which `SensoryFeedback` type macOS 14 actually plays (R4). *Resolved by:* the Step 5 check on a Force Touch trackpad.
- `[Unverified]` `crown.fill` exists in SF Symbols at these deployment targets. *Resolved by:* the build or the SF Symbols app.
- `[Unverified]` `.manageSubscriptionsSheet` is unavailable on macOS, and Apple's subscriptions URL opens the Mac App Store page (R10). *Resolved by:* the Step 6 build and run.
- `[Inference]` Asset symbols name `cat_cushion` as `.catCushion` and do so inside a non-namespaced folder. *Resolved by:* the Step 3 build.
- `[Inference]` Changing `presentationDetents` while presented animates to the new detent, and a Mac sheet animates its frame change. *Resolved by:* the Step 5 check by eye (R6).
- `[Inference]` An iPad form sheet is about 540pt wide, which is why cards stack on iOS. *Resolved by:* the iPad simulator run.
- `[Assumption]` The source PNGs are at least 2× their draw width. *Resolved by:* inspecting them on import (Step 3).
- `[Assumption]` The mock perks are placeholders the operator rewrites before submitting the subscriptions (F10 / R1).
- `[Assumption]` `ONBOARDING_PLAN_RESOLVED.md`'s later `PlanPair` extraction from `PremiumView` will rebase over the `fan` → `static func` edit. That edit is 2 hunks, so a conflict should be low-risk.
