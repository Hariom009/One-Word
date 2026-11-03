# Paywall: Build Checklist

## 1. Header

- **Derived from:** `Docs/02_Plan/Resolved/PAYWALL_PLAN_RESOLVED.md` ("Paywall: Resolved Plan"). Its §4 is the plan this checklist builds. §3 is the resolution log, §5 the operator review queue and §6 the deferred work. The original plan is `Docs/02_Plan/PAYWALL_PLAN.md`.
- **Status: audited and resolved.**
  - The audit is `Docs/02_Plan/Audit/PAYWALL_PLAN_AUDIT.md`. Its verdict is *Ready to build*, with no blockers.
  - The operator answered three questions live, and those answers are final, not open:
    - Q1: the Mac paywall is its own `Window`.
    - Q2: the mock perks show on both the gold card and the paywall.
    - Q7: a Restore that unlocks gets the full celebration.
  - Review items RQ1–RQ5 were applied by their recommended defaults. They appear below as non-blocking `DECIDE` items.
- **Stack:**
  - SwiftUI with MVVM. View models are `@Observable` and import only Observation and StoreKit.
  - Default MainActor isolation, Swift 5 mode, iOS 17 / macOS 14, Xcode 27 SDKs.
  - Folders are synchronized groups, except `OneWord/Shared/`. That folder is listed by explicit path in `project.pbxproj` and compiled into the widget too.
  - There is one asset catalog, `OneWord/Assets.xcassets`.
  - There is no XCTest target. The test gates are the headless scripts `tools/check_*.sh`.
- **Baseline:** `release/1.1.0` @ `9c0bdf9`, with no code changes. Paths are relative to `/Users/hariom/Desktop/One Word`. Checklist dated 2026-11-03.
- **Files peeked at, only to size the steps.** Every line number the plan cites still matched the code; nothing had moved.
  - `StoreKit/OneWord.storekit` (grep): `displayPrice` at `:16,92,114`, currently `49.99` / `19.99` / `2.99`; descriptions at `:21,99,121`.
  - `OneWord/Shared/Premium.swift`: lines 18–30.
  - `OneWord/ViewModels/PremiumViewModel.swift` (grep): `:24,27,38,60,63,71,83,89,95,109`.
  - `OneWord/Views/PremiumBar.swift`: lines 71–92, plus a grep (`:117` `.plain`, `:120` `buy`, `:125` `handle`).
  - `OneWord/Views/ProfileView.swift`: lines 19–24, 74–78, 94–99 and 483–530. `let owned` is at `:489` and the `UnlockButton` at `:498`.
  - `OneWord/OneWordApp.swift`: lines 80–104.
  - `OneWord/Views/PremiumView.swift` (grep): `:33,86,116,123,152`.
  - `tools/check_premium.sh`: lines 60–104.
  - `Docs/00_Context/REPO_MAP.md` (grep `:52`), and a listing of `OneWord/Assets.xcassets/`.
- **One problem inside the plan itself, flagged but not fixed.** Step 7's verify grep can't hit REPO_MAP or README with the wording the plan gives those edits. See **S7.4**.

## 2. How to use

- **Legend:**
  - `- [ ]` to do · `- [x]` done
  - `blocked-by:` that item must be checked first
  - `∥` can run in parallel
  - **MANUAL**: checked by eye, or needs a StoreKit dialog clicked
  - `DECIDE:` the operator's call
  - `⏸` deferred on purpose
- **Rule:** don't check an item until its **done-when** holds.
- **MANUAL items.** The build session can build and run the gates, but it can't click through StoreKit purchase dialogs. If a MANUAL item isn't run, leave it unchecked and add `— not run: <reason>`. A green build never checks a MANUAL box.
- **Where each done-when comes from.**
  - MANUAL items and each step's `.G` item restate the plan's own Verify bullets.
  - Grep and diff checks on code items come from the plan's text. The plan doesn't list them itself.
- **GATES** means all three commands below, run from the repo root, exit 0. If one fails, report it with its output.
  ```bash
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
  for s in check_words check_related check_learned check_capture check_sentences check_premium check_sync; do bash tools/$s.sh; done
  ```
- **Commits.** This is one change, landed as seven ordered commits (Steps 1–7), plus the operator's Step 0.
  - Each step ends green on both platforms.
  - Step 6 must be a single commit (M1).
- **Running the app** (plan §4.7): use Xcode Run with `StoreKit/OneWord.storekit`. Never launch it with `open -n`, and never kill the debug run.

## 3. The checklist

### Step 0: App Store Connect and release prerequisites (operator only · ∥ with Steps 1–7 · gates release, not the build)

- [ ] **S0.1** Set the prices, in USD with other storefronts equalized:
  - Lifetime `com.hariom.swift.oneword.premium`: 169.99
  - Yearly `com.hariom.swift.oneword.premium.yearly`: 149.99
  - Monthly `com.hariom.swift.oneword.premium.monthly`: 14.99

  Set each subscription's price before its first approval (R8). **done-when:** App Store Connect shows those three prices on those ids, and you checked them before attaching the IAPs.
- [ ] **S0.2** Add a display-name localization to the subscription group "Premium". **done-when:** the group shows one.
- [ ] **S0.3** Make the IAP display names and descriptions true for this release (M4c, G2). Today's copy says "Every dictionary, unlocked for good" and "…renewed each year/month". That is untrue while every shelf is free (`Premium.swift:28`). **done-when:** none of the three makes a claim the 1.1.0 build doesn't deliver.
- [ ] **S0.4** Copy the final strings into `StoreKit/OneWord.storekit:21,99,121`. blocked-by: S0.3, S1.1 (same file). **done-when:** the file's descriptions and display names match App Store Connect.
- [ ] **S0.5** Replace `PaywallView.perks` with true statements (F10, R1). The gold card reads the same list. This is `[Assumption]`: the plan expects the operator to do it before submitting. blocked-by: S4.2a. **done-when:** the operator confirms every line is true of the shipped build. This item gates submitting the subscriptions.
- [ ] **S0.6** Add an App Review screenshot of the paywall for each IAP. blocked-by: S5.G. **done-when:** all three IAPs have one.
- [ ] **S0.7** Attach all three IAPs to the version. If RQ1 flips to (a), attach only Lifetime. **done-when:** the version page lists them.
- [ ] **S0.8** Fill in the metadata:
  - Privacy Policy URL: `https://one-word-a2f3a.web.app/privacy`.
  - Terms of Use: Apple's standard EULA, linked in the App Description.

  **done-when:** both are set.
- [ ] **S0.9** Make sure the privacy page is live and current (R9, `[Unverified]`).
  - `site/` exists only on the unmerged `feat/website` branch, so deploy it before submission.
  - Re-read `site/public/privacy.html` on `feat/website`. Its "your Mac" and "no network requests" wording predates the iPhone version and iCloud.

  **done-when:** `curl -sI https://one-word-a2f3a.web.app/privacy` prints 200, and the operator has re-read the copy.
- [ ] **S0.10 MANUAL** Run one sandbox/TestFlight pass before submission (G1, matrix row 8). blocked-by: S6.G.
  - [ ] **S0.10a** Buy from the **Mac Premium window** (R2). **done-when:** the purchase completes and the celebration shows.
  - [ ] **S0.10b** Let a subscription renew, then expire. **done-when:** it renews, and after expiry the Profile locks again.
  - [ ] **S0.10c** Run a **Restore that unlocks**, on a device or account whose entitlement isn't present at launch (m14). Under Q7 it should get the full celebration. **done-when:** you see confetti, the Premium Club entrance and the haptic, and hear the announcement.

### Step 1: Prices, ids and savings math (commit 1 · the first reversible move · unblocks Step 2)

- [ ] **S1.1** Change the three `displayPrice` values: `:16` → `"169.99"`, `:92` → `"149.99"`, `:114` → `"14.99"`. They are now `49.99` / `19.99` / `2.99`. Files: `StoreKit/OneWord.storekit`. **done-when:** `grep -n '"displayPrice"' StoreKit/OneWord.storekit` shows exactly those values on those lines, and the diff changes nothing else.
- [ ] **S1.2** Add `static let yearlyID = "com.hariom.swift.oneword.premium.yearly"` and `static let monthlyID = "com.hariom.swift.oneword.premium.monthly"`, and set `productIDs = [productID, yearlyID, monthlyID]`. Files: `OneWord/Shared/Premium.swift:20-23` (Shared: app and widget). **done-when:** the diff shows the same three id strings, now held in constants.
- [ ] **S1.3** Add `static func savings(yearly: Decimal, monthly: Decimal) -> Int?`.
  - It computes `(1 − yearly / (monthly × 12)) × 100` in `Decimal`, rounded with `NSDecimalRound(…, 0, .down)`.
  - It returns `nil` when `monthly ≤ 0` or the result is ≤ 0.
  - It carries the plan's `// ponytail: rounds down so the chip never overstates. …` comment word for word (m13).

  Files: `OneWord/Shared/Premium.swift`. Isolation: inside the existing `nonisolated enum`, pure. **done-when:** S1.4 passes, and `grep -n "ponytail: rounds down" OneWord/Shared/Premium.swift` finds the comment.
- [ ] **S1.4** Add a "yearly savings" block to the `PremiumCheck.swift` heredoc. Build its inputs with `Decimal(string:)`. Files: `tools/check_premium.sh`. blocked-by: S1.3.
  - [ ] **S1.4a** `savings(149.99, 14.99) == 16`: the real prices, rounded down. **done-when:** it passes in the script's output.
  - [ ] **S1.4b** `savings(120, 12.5) == 20`: an exact boundary that fails if anyone swaps `Decimal` for `Double`. **done-when:** it passes.
  - [ ] **S1.4c** `savings(180, 15) == nil`: no saving means no label. **done-when:** it passes.
  - [ ] **S1.4d** `savings(100, 0) == nil`: guards the divide. **done-when:** it passes, and the script still ends with "all checks passed".
- [ ] **S1.G** Run GATES. **done-when:** they exit 0. This is the plan's Step 1 verify.

### Step 2: StoreKit plumbing (commit 2 · no UI change · blocked-by: S1.G · unblocks Steps 4 and 6)

Files: `OneWord/ViewModels/PremiumViewModel.swift`, `OneWord/Views/PremiumBar.swift`.

Isolation:
- Everything is MainActor by default.
- `Product.products(for:)` and the entitlement loop hop off the main actor and back.
- `Product` and `Transaction` are `Sendable`.
- The static `buy`'s `Task {}` inherits MainActor.

- [ ] **S2.1** Replace the stored `product` (`:24`) with:
  - `private(set) var products: [String: Product] = [:]`
  - `var product: Product? { products[Premium.productID] }`
  - `private(set) var subscribed = false`
  - `private(set) var celebrations = 0`, with its doc comment: bumped by a completed purchase or a Restore that unlocked, never by launch or `Transaction.updates`.

  **done-when:** `PremiumBar.swift:88` and `PremiumView.swift:222,226` still read `premium.product` and compile with no edits (D2).
- [ ] **S2.2** Rewrite `load()` (`:60-64`):
  - `await refresh()`
  - then `let found = (try? await Product.products(for: Premium.productIDs)) ?? []`
  - then `products = Dictionary(found.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })`
  - leave `storeUnavailable = product == nil` as it is (D6)

  **done-when:** `grep -n "storeUnavailable = product == nil"` still finds it, and `products = Dictionary(` is inside `load()`.
- [ ] **S2.3** Extend `refresh()` (`:71-85`):
  - Declare `var renews = false`.
  - Inside the verified, unrevoked branch (`:76-78`), next to `owned = true`, add `if transaction.productType == .autoRenewable { renews = true }`.
  - After `set(owned)`, add `if renews != subscribed { subscribed = renews }`.

  **done-when:** both lines are there, and `refresh()` never touches `celebrations`.
- [ ] **S2.4** In `handle(_:)` (`:91-95`, the `.success(.verified)` arm), add `if isUnlocked { celebrations += 1 }` after `phase = .idle`, with the plan's `// ponytail: if this refresh lost the generation race (:81)…` comment (m5). **done-when:** the bump is in that arm only, and the comment is present.
- [ ] **S2.5** In `restore()` (`:109-120`):
  - Make the first line `let was = isUnlocked`.
  - After the last `await refresh()`, add `if !was && isUnlocked { celebrations += 1 }` with `// Q7: a Restore that unlocks is celebrated like a purchase.`

  **done-when:** both lines are present, with the bump after the last `refresh()`.
- [ ] **S2.6** Update the header comment (`:5-11`). It should say the VM loads all three products and that `celebrations` is the paywall's trigger. **done-when:** it says both.
- [ ] **S2.7** Edit `UnlockButton` (`PremiumBar.swift:71-131`):
  - [ ] **S2.7a** After `var verb` (`:77`), add `var open: (() -> Void)? = nil  // Profile's: the pill opens the plans rather than buying Lifetime outright`. Declaring it last keeps `UnlockButton(name:verb:open:)` in memberwise order (m8). **done-when:** `open` is the last stored `var` before the `@Environment` lines.
  - [ ] **S2.7b** At `:89`, make the action `{ if let open { open() } else { Self.buy(product, with: purchase, premium) } }`, and add `.accessibilityHint(open == nil ? "" : "Shows the plans")` (Q6). **done-when:** the diff leaves the `:90` label line alone.
  - [ ] **S2.7c** At `:120`, change `private func buy(_:)` to `static func buy(_ product: Product, with purchase: PurchaseAction, _ premium: PremiumViewModel)` (D5). The body stays the same. **done-when:** the diff changes only the signature line.
- [ ] **S2.G** Run GATES. **done-when:** they exit 0.
- [ ] **S2.M1 MANUAL** Xcode Run with the StoreKit config. **done-when:** the free pill reads **"Buy — $169.99"** and still buys Lifetime directly. Nothing passes `open` yet.
- [ ] **S2.M2 MANUAL** Delete the transaction in Transaction Manager and relaunch. **done-when:** the Profile is free again.
- [ ] **S2.M3 MANUAL** Take the **baseline screenshots** of the free Profile, on the Mac at 1000×680 and on iPhone (R3). Take them before any Step 4 edit. **done-when:** both images are saved where Steps 4 and 6 can compare against them. The plan doesn't name a location. If this item isn't run, S4.M9, S6.M3 and DOD1 have no baseline either.

### Step 3: Import the two cats (commit 3 · ∥ with S1–S2, touches only assets · unblocks only the cat overlays and `Breathe` in Steps 4–5)

- [ ] **S3.0** Before this step, the build session fetches the two PNGs from the operator's artifact, `https://claude.ai/artifact/7av5v7AY5UwCtik4DQyEvv`. This is `[Assumption]`: the plan expects the session can fetch them.
  - `50c675b315b299354651463e5565870b` → `cat_cushion` (sprawled on the cushion)
  - `143a622eb1a84b228c2e7124932b2b85` → `cat_cafe` (beret, scarf, coffee, croissant)

  No code names an asset id. **done-when:** both PNGs are on disk under those names. If they aren't by the time Step 4 starts, use S3.F.
- [ ] **S3.1** Create `OneWord/Assets.xcassets/Cat/Contents.json` and `…/Cat/Poses/Contents.json`, each containing `{"info":{"author":"xcode","version":1}}`. Leave out `provides-namespace`, so the asset names stay flat (D9). **done-when:** both files exist, and `grep -rn provides-namespace OneWord/Assets.xcassets/Cat` prints nothing.
- [ ] **S3.2** Create `OneWord/Assets.xcassets/Cat/Poses/cat_cushion.imageset/` with `cat_cushion.png` and a `Contents.json` copied from `Dictionary_of_EverydayEnglish.imageset/Contents.json`: PNG in the 1x slot, 2x and 3x present but empty. blocked-by: S3.0. **done-when:** `diff` against the Dictionary `Contents.json` differs only in the filename.
- [ ] **S3.3** Create `…/Cat/Poses/cat_cafe.imageset/` the same way, with `cat_cafe.png`. blocked-by: S3.0. **done-when:** the same diff check passes.
- [ ] **S3.4** Check the resolution (R7, `[Assumption]` that the art is at least 2× its draw width) with `sips -g pixelWidth`. **done-when:** cushion is **≥ 336px** and café is **≥ 600px**. Smaller art looks soft, and R7's way out is S3.F.
- [ ] **S3.G** Run GATES, then check the generated asset symbols (D8). It is `[Inference]` that they come out as `.catCushion` and `.catCafe`:
  `grep -rn "catCushion\|catCafe" ~/Library/Developer/Xcode/DerivedData/OneWord-*/Build/Intermediates.noindex/OneWord.build/*/OneWord.build/DerivedSources/GeneratedAssetSymbols.swift`

  **done-when:** GATES exit 0 and the grep finds both symbols.
- [ ] **S3.F** Fallback (M3, R7), used only if the PNGs aren't in hand when Step 4 starts:
  - Skip Step 3.
  - Land Steps 4–5 without the cats or `Breathe`. That means skipping the cat in S4.2i, all of S4.2m, the right column of S5.1 and the cat in S5.2.
  - Add Step 3 and the overlays in a follow-up commit.

  **done-when:** either S3.0–S3.G are checked before S4 starts, or each cat sub-item is marked `deferred (S3.F)` and the ⏸ follow-up below is still open.

### Step 4: The offers, the Mac window and the Profile entry (commit 4 · the thin end-to-end slice · blocked-by: S2.G, with cat pieces also blocked-by S3.G · unblocks Step 5)

- [ ] **S4.1** Make `fan` reusable (D12). Files: `OneWord/Views/PremiumView.swift:84-132`.
  - [ ] **S4.1a** Change `private var fan` to `static func fan(_ books: [Wordbook], height: CGFloat, scale: CGFloat) -> some View`. Keep the body, with `Self.books` → `books` and `displayScale` → `scale`. `cover` stays `private static`. **done-when:** it compiles, and `cover` is still `private static`.
  - [ ] **S4.1b** In `hero` (`:86`), call `Self.fan(Self.books, height: isPhone ? 72 : 100, scale: displayScale)`. **done-when:** the `PremiumView.swift` diff is just these two hunks. The plan's `[Assumption]` that the planned `PlanPair` work rebases cleanly depends on that.
- [ ] **S4.2** Create `OneWord/Views/PaywallView.swift`. The synchronized group adds it to the app target. It is **not** in `Shared/`, and `project.pbxproj` is not edited. Isolation: MainActor (default).
  - [ ] **S4.2a** The skeleton:
    - `import SwiftUI`, plus `import StoreKit` with its MEMBER_IMPORT_VISIBILITY comment
    - `static let windowID = "premium"`
    - `static let perks: [String]`: four mock lines, with the `MOCK` doc comment and `ponytail: placeholder copy; true statements replace it before submission (F10, R1)`
    - five `@Environment` values: premium, `\.purchase`, `\.dismiss`, `\.displayScale` and `\.accessibilityReduceMotion`
    - `@State private var yearly = true` (F4)
    - `private let t = Theme.cat` (F2)
    - at the end, `#Preview { PaywallView().environment(PremiumViewModel()) }` (G4)

    **done-when:** the file exists, both builds compile it, and `grep -n "#Preview" OneWord/Views/PaywallView.swift` finds the preview.
  - [ ] **S4.2b** Add `extension Theme { static let cat }`, copying the light column of `CAT_UI_PLAN.md:120-131`:
    - background `#FEFBF7`, surface `#FFFFFF`, ink `#1E1B26`, muted `#625D6E`
    - definition `#2A2633`, example `#4B4658`, accent `#5B3FD6`, rule `#E9792B`, hairline `#E9E2D6`
    - roundness 1.5; glow and tiles at their defaults
    - the `ponytail:` note that CAT_UI Phase 1 will make this a redeclaration, so it must be deleted then

    **done-when:** all nine hex values grep in the file, and the comment is present.
  - [ ] **S4.2c** Add `content`, the platform split (D15):
    - macOS: `ZStack { offers.accessibilityHidden(premium.isUnlocked); if premium.isUnlocked { Color(hex: 0x1E1B26).opacity(0.34).ignoresSafeArea(); thanks } }`
    - iOS: `if premium.isUnlocked { thanks } else { offers }`

    **done-when:** both builds pass.
  - [ ] **S4.2d** Add the root modifiers, in this order:
    1. `content.animation(.spring(duration: 0.5, bounce: 0.25), value: premium.isUnlocked)`
    2. `#if os(macOS) .frame(width: 760, height: 600) #endif`. The size is a knob.
    3. `.background(t.background)` and `.environment(\.colorScheme, .light)`. Do **not** use `.preferredColorScheme`.
    4. `.tint(t.accent)` (m10)
    5. `.presentationDetents([.medium, .large])`, `.presentationDragIndicator(.visible)` and `.presentationBackground(t.background)`

    **done-when:** the order matches, and `grep -n preferredColorScheme OneWord/Views/PaywallView.swift` prints nothing.
  - [ ] **S4.2e** Build the top of the offers, with padding 44/20 as in `PremiumView.swift:64`:
    - A close X, top-trailing, with `.buttonStyle(.plain)` and `.keyboardShortcut(.cancelAction)`. It calls `dismiss()`.
    - The fan: `PremiumView.fan(shelf, height: isPhone ? 72 : 100, scale: displayScale)`, where `shelf = Wordbook.all.filter { $0.id != SavedWords.resource }`.
    - The title in `Font.serif(isPhone ? 30 : 36, .medium)` with `.accessibilityAddTraits(.isHeader)`.
    - The pitch line, then `perks` as checkmark rows shaped like `PremiumView.perk` (`:383-398`).

    **done-when:** `cancelAction` and `isHeader` grep in the file, and both builds pass.
  - [ ] **S4.2f** Lay out the cards (D6, D13):
    - Use an `HStack` on macOS and a `VStack` on iOS.
    - `answered = premium.product != nil || premium.storeUnavailable`.
    - Draw the subscription card if `!answered || (products[yearlyID] != nil && products[monthlyID] != nil)`.
    - Draw the Lifetime card if `!answered || premium.product != nil`.
    - If `answered` and neither card can be drawn, show `premium.problem` and "Try Again" (`Task { await premium.load() }`).

    **done-when:** those three conditions appear in the file as written.
  - [ ] **S4.2g** Add `card(emphasized:)`:
    - a white surface, a 1pt `t.hairline` border, and `RoundedRectangle(cornerRadius: t.radius(12))`, which is 18pt at Cat's 1.5 roundness
    - when emphasized, a 2pt `t.accent` border and the `PremiumView.card` shadow (`:431`)

    **done-when:** both builds pass. The look is checked by eye in S4.M.
  - [ ] **S4.2h** Add `subscriptionCard`:
    - A "Premium" heading, with `periodToggle` top-trailing. The toggle is one `.plain` capsule reading "Monthly · Yearly", with the current period filled. It runs `withAnimation(.snappy) { yearly.toggle() }`.
    - On the toggle: `.accessibilityLabel("Billing period")`, `.accessibilityValue(yearly ? "Yearly" : "Monthly")` and `.accessibilityHint("Switches between monthly and yearly")`.
    - The price in serif 40 with `.contentTransition(.numericText())`, followed by " / year" or " / month".
    - When `yearly` is on and `Premium.savings(yearly: y.price, monthly: m.price)` isn't nil, a "Save \(n)%" chip (F6).
    - The renewal line: "Renews every \(year|month) at \(displayPrice) until you cancel. Cancel anytime in your App Store account settings."
    - `buyButton(yearly ? Premium.yearlyID : Premium.monthlyID, "Subscribe", yearly ? "Premium Yearly" : "Premium Monthly")`.

    **done-when:** the three accessibility modifiers grep, and the renewal string matches.
  - [ ] **S4.2i** Add `lifetimeCard`, the emphasized one (F3):
    - "Lifetime", the price plus "once", and "Pay once. Yours for good. Nothing renews."
    - `buyButton(Premium.productID, "Buy", "Premium Lifetime")`
    - The cat overlay (blocked-by: S3.G, or skip under S3.F): `.overlay(alignment: .bottomTrailing) { Image(.catCushion).resizable().interpolation(.high).scaledToFit().frame(width: isPhone ? 118 : 168).modifier(Breathe()).offset(x: isPhone ? 8 : 30, y: isPhone ? 20 : 34).allowsHitTesting(false).accessibilityHidden(true) }`
    - **The cat must never cover Buy.** On Mac and iPad the button is 160×40 and leading. On the phone it is full width at 50pt, with `.padding(.bottom, 96)` on the card. All of these are knobs.

    **done-when:** both builds pass, with the overlay or without it under S3.F.
  - [ ] **S4.2j** Add `buyButton(_:_:_:)`:
    - While purchasing: a spinner.
    - If the product exists: a violet filled `.plain` button running `{ UnlockButton.buy(p, with: purchase, premium) }`. It is 40pt with radius 12 on Mac and iPad, and 50pt full width with radius 14 on the phone. Its label is `"\(label), \(p.displayPrice)"`, with `.accessibilityLabel("\(label) \(name), \(p.displayPrice)")`.
    - If `answered` but there's no product: nothing.
    - Otherwise: a spinner.

    **done-when:** it buys through `UnlockButton.buy` and adds no second purchase path (D5).
  - [ ] **S4.2k** Add what goes below the cards:
    - "Restore Purchase", a violet `.plain` text button running `Task { await premium.restore() }`, disabled while a purchase is in progress.
    - `premium.problem`, shown the way `PremiumView.swift:248-254` shows it.
    - `Link("Terms of Use", destination: Self.terms) · Link("Privacy Policy", destination: Self.privacy)`, at 12pt in the muted colour.
    - `terms` = `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/` (`[Unverified]`).
    - `privacy` = `https://one-word-a2f3a.web.app/privacy`, with the `ponytail:` note about `FeedbackViewModel.privacyPolicy`.

    **done-when:** both URLs and the comment grep in the file.
  - [ ] **S4.2l** Add a stub `thanks`: "Welcome to the Premium Club" and a Done button that calls `dismiss()`, with `.keyboardShortcut(.defaultAction)`. Step 5 replaces it. **done-when:** `defaultAction` greps, and both builds pass.
  - [ ] **S4.2m** Add `private struct Breathe: ViewModifier` (blocked-by: S3.G, or skip under S3.F):
    - `phaseAnimator([false, true])`, scaling by 1.006 × 1.02 anchored at `.bottom`, with `.easeInOut(duration: 3.6)` per phase.
    - Under Reduce Motion, it returns `content` unchanged.

    **done-when:** both builds pass, and the Reduce Motion branch returns `content`.
- [ ] **S4.3** Add the Mac `Window` scene after the `WindowGroup`'s closing `#endif` (`:102`), exactly as in the plan's Step 4 block. Files: `OneWord/OneWordApp.swift`.
  - Wrap it in `#if os(macOS)`.
  - `Window("Premium", id: PaywallView.windowID) { PaywallView().environment(premium).task { if premium.product == nil { await premium.load() } } }`.
  - Add `.windowStyle(.hiddenTitleBar)`, `.windowResizability(.contentSize)` and `.commandsRemoved()` (RQ5).
  - Add the `ponytail:` restoration comment (D14). Don't add `restorationBehavior`.

  **done-when:** both builds pass. The iOS build passing shows the `#if` guard works.
- [ ] **S4.4** Wire up Profile's pill. Files: `OneWord/Views/ProfileView.swift`.
  - [ ] **S4.4a** Add `@State private var paywall = false`, commented "iPhone and iPad: the sheet. The Mac opens its window instead.", and `@Environment(\.openWindow) private var openWindow`. **done-when:** both are declared.
  - [ ] **S4.4b** Add `private func showPlans()` with its doc comment. On macOS it calls `openWindow(id: PaywallView.windowID)`; everywhere else it sets `paywall = true`. **done-when:** both builds pass.
  - [ ] **S4.4c** At `:498`, **change only** `UnlockButton(name: "Buy Premium", verb: "Buy")` → `UnlockButton(name: "Buy Premium", verb: "Buy", open: { showPlans() })`. **Keep `owned`** and the rest of `plans` (M1, D7). **done-when:** the `plans` change is one line, and `grep -n "let owned" OneWord/Views/ProfileView.swift` still finds it.
  - [ ] **S4.4d** After `.task { model.refresh() }` (`:97`), add `.sheet(isPresented: $paywall) { PaywallView() }`. **done-when:** both builds pass.
- [ ] **S4.G** Run GATES. **done-when:** they exit 0.
- [ ] **S4.M1 MANUAL · Mac** Tap the pill. **done-when:** it opens a "Premium" window at 760×600 on Cat paper, and a second tap brings that window forward instead of opening another.
- [ ] **S4.M2 MANUAL · Mac** Look at the Window menu. **done-when:** it lists no "Premium" entry, or it does and you accept that. This is RQ5/R12 and `[Inference]`; either outcome is acceptable.
- [ ] **S4.M3 MANUAL · Mac** Buy Monthly (then delete it), Yearly (then delete it), and Lifetime. **done-when:** each time,
  - the StoreKit confirmation appears **from the Premium window** (R2, `[Unverified]`),
  - the stub thank-you shows,
  - Done closes the window,
  - Profile flips to the **old owned cards** (Premium tagged Current, no pill),
  - and Cancel leaves everything as it was.

  If the spinner just keeps spinning and no dialog appears, use R2's way out: a Mac-only `try await product.purchase()` that feeds `premium.handle`.
- [ ] **S4.M4 MANUAL · iPhone** Open the sheet. **done-when:** it opens at medium, drags to large, and the subscription price is visible at medium on an SE-size simulator. If the price is hidden, raise the first detent to `.fraction(0.6)`.
- [ ] **S4.M5 MANUAL · iPhone on Midnight** **done-when:** the grabber is visible (R13, `[Inference]`). If it isn't, use R13's way out: an iOS-only `.preferredColorScheme(.light)` on the paywall root, after confirming it doesn't flip the main window.
- [ ] **S4.M6 MANUAL · iPhone** **done-when:** links and spinners are violet, not Midnight's blue.
- [ ] **S4.M7 MANUAL · iPad** **done-when:** the paywall is a form sheet with stacked cards and leading 40pt buttons, and the cat stays clear of the button.
- [ ] **S4.M8 MANUAL · all platforms** **done-when:**
  - prices read 14.99, 149.99 and 169.99,
  - the toggle switches the price,
  - "Save 16%" shows on Yearly only,
  - Restore is there,
  - and both links open in the browser. The EULA URL is `[Unverified]`, and this check settles it.
- [ ] **S4.M9 MANUAL · R3** Compare the free Profile with S2.M3's baseline. blocked-by: S2.M3. **done-when:** the only difference is the price text. If it regressed, use R3's way out: revert the `plans` change, keeping only `open:`.

### Step 5: The thank-you, confetti and haptic (commit 5 · blocked-by: S4.G)

Files: `OneWord/Views/PaywallView.swift`.

- [ ] **S5.1** Replace `thanks` on the Mac (the MacPremiumThanks board):
  - A centred card: `.frame(width: 740, height: 420)`, `t.surface` in `RoundedRectangle(cornerRadius: 20)`, a soft shadow, sitting over the Step 4 dim. The sizes are knobs.
  - Left column:
    - "PREMIUM": violet, 11 bold, uppercase, tracking 2.
    - "Welcome to the Premium Club" in `Font.serif(36, .medium)` with `.isHeader`.
    - The body: "Thank you for backing One Word. Premium is yours on every Mac and iPhone signed in to this Apple ID."
    - A violet filled `.plain` Done (40pt, radius 12) with `.keyboardShortcut(.defaultAction)`. It calls `dismiss()`, which closes the window (D15).
  - Right column: `Image(.catCafe)`, 300 wide, with `Breathe` and `accessibilityHidden` (blocked-by: S3.G, or skip under S3.F).

  **done-when:** the macOS build passes, and the body string matches.
- [ ] **S5.2** Replace `thanks` on iOS (the PhonePremiumThanks board). Stack, top to bottom:
  - the cat at 244 wide (blocked-by: S3.G, or skip under S3.F)
  - the label
  - the headline, centred, in serif 30
  - the body
  - a full-width 50pt Done

  **done-when:** the iOS build passes.
- [ ] **S5.3** Add the entrance, `.transition(reduceMotion ? .opacity : .scale(scale: 0.92).combined(with: .opacity))`, driven by the root's `.animation(…, value: premium.isUnlocked)`. There is **no "Pick a book"** button (F8). **done-when:** `grep -n "Pick a book" OneWord/Views/PaywallView.swift` prints nothing.
- [ ] **S5.4** Add the celebration modifiers to the paywall's root, never inside `thanks` (D4):
  - [ ] **S5.4a** `.overlay { if !reduceMotion { Confetti(trigger: premium.celebrations).allowsHitTesting(false).accessibilityHidden(true) } }`. It covers the whole Mac window, or the iPhone sheet (m12). **done-when:** it is on the root.
  - [ ] **S5.4b** `.sensoryFeedback(Self.feel, trigger: premium.celebrations)`, where `static let feel` is `.levelChange` under `#if os(macOS)` and `.success` otherwise (m3, RQ2). **done-when:** both builds pass.
  - [ ] **S5.4c** `.onChange(of: premium.celebrations) { AccessibilityNotification.Announcement("Welcome to the Premium Club").post() }`, with no `initial:`. It mirrors `SyncToast.swift:50`. **done-when:** it is on the root, without `initial:`.
  - [ ] **S5.4d** `.presentationDetents(premium.isUnlocked ? [.height(584)] : [.medium, .large])`. **done-when:** it replaces S4.2d's fixed detents.
- [ ] **S5.5** Add `Confetti` and `Piece`, both private and in the same file:
  - [ ] **S5.5a** `private struct Confetti: View { let trigger: Int }`, built on `KeyframeAnimator(initialValue: 0.0, trigger: trigger) { p in Canvas { … } } keyframes: { _ in MoveKeyframe(0.0); LinearKeyframe(1.0, duration: 2.8) }`. It draws nothing when `p == 0 || p >= 1`. **done-when:** both builds pass.
  - [ ] **S5.5b** `private nonisolated struct Piece` with x0 (0…1), drift, fall speed, spin, width/height and colour, plus `static let all` holding about 90 pieces, built once. Each piece:
    - starts above the top edge at `x0 × width`,
    - falls under gravity scaled to `size.height`,
    - wobbles on a sine,
    - rotates by `spin × t`,
    - and fades over the last 25%.

    Colours: `#5B3FD6`, `#E9B949`, `#F07167`, `#2BB3A3`, `#6CA8F0`, `#1E1B26`. **done-when:** `nonisolated struct Piece` greps.
  - [ ] **S5.5c** Capture `let pieces = Piece.all` before the `Canvas` (R5). **done-when:** the capture is there, and the macOS build log has no isolation warning or error from `PaywallView.swift`. Such a warning is R5's early sign. If one appears, the last resort is `TimelineView` with `ForEach`.
- [ ] **S5.G** Run GATES. **done-when:** they exit 0.
- [ ] **S5.M1 MANUAL · Mac** Buy Yearly. **done-when:**
  - the dim and the thank-you modal appear,
  - confetti falls over the whole window for about 2.8s,
  - Done or Return closes the window,
  - and clicks don't reach the plans under the dim. This last point is `[Inference]`; if clicks get through, add `.disabled(premium.isUnlocked)` on the offers.
- [ ] **S5.M2 MANUAL · iPhone** Buy Yearly. **done-when:**
  - the sheet becomes the thank-you at 584pt, with confetti inside the sheet,
  - the haptic fires **on a device** (the simulator has none),
  - and the detent change animates. That last point is R6 and `[Inference]`; if it looks janky, go back to fixed detents.
- [ ] **S5.M3 MANUAL · VoiceOver** **done-when:** the headline is announced on both Mac and iPhone.
- [ ] **S5.M4 MANUAL · Ask to Buy** **done-when:** it shows "Waiting for approval.", and after you approve it in Transaction Manager, the thank-you shows **without** confetti, because it arrives through `Transaction.updates`.
- [ ] **S5.M5 MANUAL · Reduce Motion on** **done-when:** there's no confetti and no breathing, and the thank-you fades in.
- [ ] **S5.M6 MANUAL · Mac haptic** (Q4, RQ2) With a finger resting on a Force Touch trackpad, note whether `.levelChange` is felt. **done-when:** the result is written down. Either result is acceptable.
- The Restore celebration (Q7) can't be set up locally (m14), so it is checked in S0.10c.

### Step 6: The golden Premium card, plus the M1 swap (commit 6, **one commit** · blocked-by: S2.G, S4.G because it reads `PaywallView.perks`)

Files: `OneWord/Views/ProfileView.swift`. Isolation: MainActor.

- [ ] **S6.1** At the imports (`:21-23`), add `import StoreKit   // manageSubscriptionsSheet — MEMBER_IMPORT_VISIBILITY needs it named`. **done-when:** it greps.
- [ ] **S6.2** Add `@State private var perksShown = false`, `@State private var managing = false` and `@Environment(\.openURL) private var openURL`. **done-when:** all three are declared.
- [ ] **S6.3** In the body (`:76`), replace `plans(t)` with `if premium.isUnlocked { premiumCard(t) } else { plans(t) }` (D7). **done-when:** the swap is in the body.
- [ ] **S6.4** In `plans` (`:485-510`), drop `owned`:
  - `section("Plan", t, note: premium.problem)`
  - `planCard("Free", current: true, t) { EmptyView() }`
  - `planCard("Premium", current: false, t) { …Lifetime caption, the UnlockButton with open:, Restore… }`
  - the doc comment becomes "Free's plans; an owner sees `premiumCard` instead."

  For a free reader this draws exactly what draws today. **done-when:** `grep -n "let owned" OneWord/Views/ProfileView.swift` prints nothing.
- [ ] **S6.5** Next to the paywall `.sheet`, add `#if os(iOS) .manageSubscriptionsSheet(isPresented: $managing) #endif` (D10). **done-when:** both builds pass. The macOS build passing shows the guard works.
- [ ] **S6.6** Add `private func premiumCard(_ t: Theme) -> some View` after `planCard` (`:529`), inside `section("Plan", t)`:
  - [ ] **S6.6a** The header: a `.plain` `Button { withAnimation(.snappy) { perksShown.toggle() } }` with `.contentShape(Rectangle())`. Its label holds:
    - `Image(systemName: "crown.fill")`
    - "PREMIUM", 11 bold, tracking 2
    - "One Word Premium" in `doodle.face(22)`
    - `premium.subscribed ? "Subscription" : "Lifetime"` (m7 is deferred)
    - a chevron that turns 90° when the card is open

    **done-when:** both builds pass.
  - [ ] **S6.6b** Below the header, as siblings and not inside its button:
    - When `perksShown`: `ForEach(PaywallView.perks, id: \.self)` checkmark rows (Q2: one list).
    - When `premium.subscribed`: a `.plain` "Manage Subscription" button. On iOS it sets `managing = true`. On macOS it calls `openURL(URL(string: "https://apps.apple.com/account/subscriptions")!)`, which is `[Unverified]` (R10).

    **done-when:** `ProfileView.swift` reads `PaywallView.perks` and declares no perk strings of its own.
  - [ ] **S6.6c** The look:
    - a fixed `LinearGradient` from `#F6D77A` (top leading) to `#D4A52C` (bottom trailing), the same on every appearance
    - ink `#2A1E05`, corners `t.radius(12)`
    - a shadow of `#D4A52C` at 0.35, radius 14, y 6 (a knob)
    - **no darker third stop.** `#B07D1A` would sit at the 4.5:1 contrast floor; the ink is 7.17:1 on `#D4A52C` and 11.6:1 on `#F6D77A`.

    **done-when:** the gradient has exactly those two stops.
  - [ ] **S6.6d** Accessibility: `.accessibilityLabel("One Word Premium, \(subscribed ? "subscription" : "lifetime")")`, `.accessibilityValue(perksShown ? "Expanded" : "Collapsed")` and `.accessibilityHint("Shows what Premium includes")`. **done-when:** all three grep.
- [ ] **S6.7** Land Step 6 as one commit (M1). Removing `owned` (S6.4), the body swap (S6.3) and `premiumCard` (S6.6) go in together. **done-when:** the Step 6 commit contains all three, and no commit on the branch removes `owned` without the swap.
- [ ] **S6.G** Run GATES. **done-when:** they exit 0.
- [ ] **S6.M1 MANUAL · Lifetime owner** **done-when:** the gold card reads "Lifetime", tapping it expands the perks, and there's no Manage row.
- [ ] **S6.M2 MANUAL · Yearly owner** **done-when:** the card reads "Subscription" and shows Manage. On iPhone, Manage opens Apple's sheet; on the Mac it opens the subscriptions page. If the Mac URL fails (R10), use `macappstores://apps.apple.com/account/subscriptions`.
- [ ] **S6.M3 MANUAL · R3** Delete the transactions. blocked-by: S2.M3. **done-when:** the free Profile is back and matches S2.M3's baseline.
- [ ] **S6.M4 MANUAL** **done-when:** the card looks right on Midnight, System light and System dark.

### Step 7: Docs (commit 7 · blocked-by: S6.G)

- [ ] **S7.1** Edit `Docs/00_Context/ARCHITECTURE.md`:
  - [ ] **S7.1a** At `:126-127`, change "Today's purchase UI (`UnlockButton`) sells lifetime only" to "The paywall (`Views/PaywallView.swift`) sells all three; `UnlockButton` elsewhere sells lifetime." **done-when:** the line reads so.
  - [ ] **S7.1b** Under "Where it's sold" (`:142-146`), add four points:
    - Profile's pill opens the paywall: its own `Window` on the Mac, a sheet on iPhone and iPad.
    - **`celebrations` is the celebration signal**, bumped only by a completed purchase or a Restore that unlocked.
    - Owners see Profile's gold card.
    - `PaywallView.perks` is the one list both of them read.

    **done-when:** all four are there.
  - [ ] **S7.1c** At `:147-148`, add "The Mac's Premium window is a scene of its own; `OneWordApp` injects `PremiumViewModel` there too." **done-when:** the sentence is there.
  - [ ] **S7.1d** At `:184`, change the line to "`OneWordApp.swift` @main — the main window, the Mac's Premium window, app-active refresh". **done-when:** it reads so.
  - [ ] **S7.1e** At `:190`, add `PaywallView` to the Views list. **done-when:** it's listed.
- [ ] **S7.2** Edit `Docs/00_Context/REPO_MAP.md`:
  - The Assets row (`:30`): "…, dictionary covers, avatars, `Cat/Poses/` (the paywall's two cat drawings, 1x slot)".
  - The `check_premium.sh` row (`:52`): "…and the yearly-savings figure".

  **done-when:** both rows read so.
- [ ] **S7.3** In the `Docs/README.md` Dossiers list, add or update a "**Paywall**" line. It gives the state **at this commit**, for example "built; gates green; true perks, App Store Connect and a sandbox pass gate release". It links the plan, the audit and the resolved plan (m15). **done-when:** the line exists and claims only what this checklist has actually checked. MANUAL items marked `not run` aren't verified.
- [ ] **S7.4** Run the plan's check: `grep -rn "PaywallView\|cat_cushion" Docs/00_Context Docs/README.md` should hit ARCHITECTURE, REPO_MAP and README.

  **`[Unverified]` problem inside the plan, not fixed here:** as the plan words them, REPO_MAP's two edits (`Cat/Poses/`, "yearly-savings figure") and the README example contain neither search term. So this grep can only hit ARCHITECTURE.

  **done-when:** one of these holds:
  - the grep hits all three files, because the REPO_MAP and README lines were written to name `PaywallView` or `cat_cushion`;
  - or the operator accepts S7.2 and S7.3 as checked by `git diff`.

  A hit in ARCHITECTURE alone does not count.
- [ ] **S7.5** Edit no other `01`–`06` doc. **done-when:** under `Docs/`, the Step 7 commit changes only ARCHITECTURE.md, REPO_MAP.md and README.md, plus this checklist if its boxes are being ticked.
- [ ] **S7.G** Run GATES. The plan runs them after every step. **done-when:** they exit 0.

## 4. iOS rigor gates (one block, run before merge on the full diff from `9c0bdf9`)

- [ ] **RG1 Target membership.** New files sit only in synchronized groups: `OneWord/Views/PaywallView.swift` and `OneWord/Assets.xcassets/Cat/…`. Nothing new goes in `OneWord/Shared/`, and `project.pbxproj` isn't edited. **done-when:** `git diff --name-only 9c0bdf9 -- OneWord.xcodeproj/project.pbxproj` and `git diff --name-only --diff-filter=A 9c0bdf9 -- OneWord/Shared` both print nothing.
- [ ] **RG2 The view model stays free of SwiftUI** (D5). **done-when:** `grep -n "import SwiftUI" OneWord/ViewModels/PremiumViewModel.swift` prints nothing.
- [ ] **RG3 Only a purchase or an unlocking Restore celebrates** (D3, Q7). **done-when:** `grep -n "celebrations += 1" OneWord/ViewModels/PremiumViewModel.swift` finds exactly two lines, one in `handle` and one in `restore`. There is none in `load`, `refresh` or the `Transaction.updates` task.
- [ ] **RG4 The celebration triggers sit on the root** (D4). **done-when:** a read-through of `PaywallView.body` shows the confetti overlay, `.sensoryFeedback` and `.onChange(of: premium.celebrations)` on the root, not inside `thanks`, and `grep -n "initial:" OneWord/Views/PaywallView.swift` prints nothing.
- [ ] **RG5 Isolation** (§4.5). **done-when** all of these hold:
  - the diff doesn't touch `Premium`'s `nonisolated enum` declaration;
  - `Piece` is a `private nonisolated struct`, with `let pieces = Piece.all` captured before the `Canvas`;
  - `Task` appears in `PaywallView.swift` only in the Try Again and Restore actions, so Confetti and Breathe start none;
  - the build logs carry no new isolation warning.
- [ ] **RG6 Memory and task lifetime** (§4.5). **done-when** all of these hold:
  - `grep -n "weak self" OneWord/ViewModels/PremiumViewModel.swift` still finds the `Transaction.updates` task (`:38`);
  - the new closures capture only what §4.5 lists: `open: { showPlans() }` captures the value-type `ProfileView`, the window's `.task` captures the value-type `OneWordApp`, and the buy `Task` holds the app-lifetime VM briefly;
  - the purchase and restore Tasks stay unstructured on purpose, so they outlive a closed sheet or window.
- [ ] **RG7 Availability and platform guards** (§4.6). **done-when** all of these hold:
  - `git diff 9c0bdf9 -- OneWord | grep -nE '^\+.*(#available|@available|restorationBehavior|defaultLaunchBehavior)'` prints nothing;
  - `Window(` sits inside `#if os(macOS)`, and `.manageSubscriptionsSheet` inside `#if os(iOS)`;
  - the iOS Simulator build is green.
- [ ] **RG8 Explicit imports** (MEMBER_IMPORT_VISIBILITY). **done-when:** `import StoreKit`, with its reason comment, is in both `PaywallView.swift` and `ProfileView.swift`.
- [ ] **RG9 Colour scheme and tint.** **done-when:** `PaywallView` forces `.environment(\.colorScheme, .light)` and `.tint(t.accent)` on its root. It has no `.preferredColorScheme` unless R13's iOS-only fix was taken, and in that case the main window was confirmed unaffected.
- [ ] **RG10 Button styles** (m6). **done-when:** a read-through finds `.buttonStyle(.plain)` on every custom-drawn `Button` in `PaywallView` and `premiumCard`.
- [ ] **RG11 Accessibility and keyboard** (§4.6). **done-when:** a read-through confirms each point below, and DOD9's VoiceOver spot-check passes.
  - The cats, the fan and the confetti are `accessibilityHidden`.
  - The toggle has a label, value and hint.
  - The Buy buttons carry the product name and price.
  - The paywall title and the thank-you headline are `.isHeader`.
  - The celebration posts its announcement.
  - The gold card has a label, value (Expanded/Collapsed) and hint.
  - On the Mac, the offers are `accessibilityHidden` while the thank-you shows.
  - The free pill keeps its label and gains the hint "Shows the plans".
  - Escape is the close X (`.cancelAction`) and Return is Done (`.defaultAction`).
  - Under Reduce Motion: no confetti, no breathing, a fade, and the haptic still fires.
- [ ] **RG12 Every price comes from StoreKit.** **done-when:** `grep -rnE '14\.99|149\.99|169\.99' OneWord --include='*.swift'` prints nothing. The figures live only in `.storekit` and in the check script.
- [ ] **RG13 Nothing gated, nothing persisted** (§4.1-6, §4.4). **done-when** all of these hold:
  - `git diff 9c0bdf9 -- OneWord/Models/Features.swift` prints nothing;
  - the `Premium.swift` diff doesn't touch `free`, `allows` or `set`;
  - `PremiumViewModel`'s `set` (`:126-129`) is unchanged;
  - `git diff 9c0bdf9 -- OneWord | grep -nE '^\+.*(UserDefaults|AppGroup)'` prints nothing.
- [ ] **RG14 Every `ponytail:` comment the plan calls for is present.** There are six:
  - `savings`, in `Premium.swift`
  - the generation race in `handle`, in `PremiumViewModel.swift`
  - the `perks` placeholder, in `PaywallView.swift`
  - the duplicated privacy URL, in `PaywallView.swift`
  - the `Theme.cat` redeclaration, in `PaywallView.swift`
  - window restoration, in `OneWordApp.swift`

  **done-when:** `grep -n "ponytail:"` finds each in its file.
- [ ] **RG15 No Info.plist, entitlement or string-catalog changes** (§4.6). **done-when:** `git diff --name-only 9c0bdf9 | grep -E 'Info\.plist|\.entitlements|\.xcstrings'` prints nothing.

## 5. Open operator decisions (DECIDE)

Each of these was applied by its recommended default (§5), and **none blocks the build**. Build on the default, then record accept or override here. Q1, Q2 and Q7 are final, so they aren't listed.

- [ ] **DECIDE: RQ1 (Q3). What ships if the perks aren't real by submission?**
  - **Applied:** no kill switch. True `PaywallView.perks` and true IAP metadata gate submission (S0.3–S0.5, F10).
  - **Alternative (a):** Lifetime only, using R1(b)'s two lines: add `static let subscriptions = false` to `Features.swift`, and have `load()` fetch `Features.subscriptions ? Premium.productIDs : [Premium.productID]`. The paywall hides the subscription card by itself (D6). The perks must still be true. An unattached subscription may still load in sandbox (`[Inference]`), which the Step 0 sandbox pass checks.
  - **Alternative (b):** the full paywall with true but modest copy.
  - **Flips when:** 1.1.0 must be submitted before real Premium features exist.
  - **done-when:** the operator records accept, (a) or (b). Choosing (a) adds a new item before S0.7.
- [ ] **DECIDE: RQ2 (Q4). The Mac haptic.**
  - **Applied:** keep `.levelChange` on the Mac (S5.4b). It's felt only through a Force Touch trackpad with a finger resting on it.
  - **Alternatives:** (a) drop it, keeping `.success` on iOS only; (b) use `NSHapticFeedbackManager … .generic` (`DictionaryPicker.swift:232-237`), which has the same hardware limit.
  - **Flips when:** you'd rather not ship a path that's rarely felt, or S5.M6 shows it never plays.
  - **done-when:** recorded. An override changes only S5.4b.
- [ ] **DECIDE: RQ3 (Q5/G3). An upgrade from subscription to Lifetime.**
  - **Applied:** not built. Owners never see the paywall.
  - **Alternative:** a "Switch to Lifetime" row on the gold card for `subscribed` owners. It would open the paywall with only the Lifetime card, and add a `lifetime` flag in `refresh()`, which also settles ⏸ m7.
  - **Flips when:** you want upgrade revenue, or subscribers ask for it.
  - **done-when:** recorded.
- [ ] **DECIDE: RQ4 (Q6/F7). The free pill's wording.**
  - **Applied:** it looks the same ("Buy — $169.99" under "Lifetime"). VoiceOver gets the hint "Shows the plans" (S2.7b).
  - **Alternative:** relabel it "See plans". That changes the free Profile, which the locked constraint says must look exactly as it does today.
  - **Flips when:** clarity matters more than looking identical, or testers are surprised that Buy opens a plan picker set to Yearly.
  - **done-when:** recorded.
- [ ] **DECIDE: RQ5 (a cost of Q1). The Window-menu entry.**
  - **Applied:** `.commandsRemoved()` (S4.3), so only the pill opens the window.
  - **Alternative:** keep Window → Premium as a second way in, by deleting that one line.
  - **Flips when:** you want the paywall reachable from the menu bar.
  - **done-when:** recorded.

The other forks in plan §4.8 aren't open: they're built with the plan's defaults and remain knobs for later.
- F2: the Cat light palette on every appearance.
- F3: Lifetime is the emphasized card, with the cushion cat on it.
- F4: the toggle starts on Yearly.
- F6: the savings chip is on, rounded down.
- F8: the thank-you has only Done.
- F9: owners see the perks by expanding the gold card.

## 6. Deferred / evidence-gated (⏸, not now)

- [ ] ⏸ **m7: the label for someone who owns both a subscription and Lifetime.** They'd see "Subscription", but that state can't be reached in the app under RQ3's default. **Gate:** if RQ3 flips, add `lifetime` next to `subscribed` in `refresh()`, and prefer "Lifetime" in the label while still offering Manage.
- [ ] ⏸ **m15(3): the duplicated privacy URL.** `FeedbackViewModel.privacyPolicy` exists only on `feat/website` (`:31` there). **Gate:** when that branch merges, point `PaywallView.privacy` at it, as the `ponytail:` comment from S4.2k says.
- [ ] ⏸ **Window restoration on macOS 14.** The SDK offers no way to control it there: there is no `buildEither`, and `restorationBehavior` and `defaultLaunchBehavior` need macOS 15. So restoration is accepted, softened by the window's `.task` reload (R11). **Gate:** once the deployment floor reaches macOS 15, add `.restorationBehavior(.disabled)` to the Premium window.
- [ ] ⏸ **The Step 3 follow-up.** Only needed if S3.F was used. **Gate:** once the PNGs are in hand, do S3.0–S3.G and add the cat overlays and `Breathe`.

**Unconfirmed plan items carried forward, and where each is checked** (from §4.11 and §6):

| Item | Checked at |
|---|---|
| R2: buying works from the second window `[Unverified]` | S4.M3, S0.10a |
| R10: the Mac Manage URL `[Unverified]` | S6.M2 |
| R12: `.commandsRemoved()` removes the Window-menu entry `[Inference]` | S4.M2 |
| R13: the grabber on Midnight `[Inference]` | S4.M5 |
| The EULA URL opens `[Unverified]` | S4.M8 |
| The privacy page is live and current `[Unverified]` | S0.9 |
| The PNGs can be fetched; they are ≥ 2× their draw width `[Assumption]` | S3.0, S3.4 |
| The asset symbols are `.catCushion` / `.catCafe` `[Inference]` | S3.G |
| The dim blocks clicks to the plans `[Inference]` | S5.M1 |
| The detent change animates `[Inference]` | S5.M2 |
| A restored window can come back without the main window `[Inference]` | DOD10 |
| The operator replaces the mock perks `[Assumption]` | S0.5 |
| The later `PlanPair` work rebases over the `fan` edit `[Assumption]` | not checked by this change. S4.1b keeps the edit to two hunks. |

## 7. Definition of done

- **The build is done** when DOD1–DOD12 are checked.
- **It is releasable** when DOD13 is checked too.
- A DoD row whose MANUAL items are `not run` stays unchecked. Report it as not run; don't smooth it over.

- [ ] **DOD1 Free Profile** (§4.1-1). It looks as it does today; the only visible difference is $169.99 in the pill, and tapping the pill opens the paywall. **done-when:** S4.M9 and S6.M3 (matrix row 1), plus S4.M1 and S4.M4, are checked.
- [ ] **DOD2 Placement** (§4.1-2). On the Mac, a 760×600 window with a hidden title bar, which a second tap brings forward. On iPhone, a bottom sheet with a grabber, medium to large. On iPad, a form sheet. **done-when:** S4.M1, S4.M4, S4.M5 and S4.M7 are checked.
- [ ] **DOD3 Content** (§4.1-3). The fan, title and perks; the subscription card with its toggle, savings, renewal line and Subscribe; the Lifetime card with the cat; Restore, both links, and the problem line. Every price comes from `displayPrice`. **done-when:** S4.M8 is checked and RG12 is clean.
- [ ] **DOD4 Celebration** (§4.1-4). A purchase, or a Restore that unlocks, shows the thank-you, confetti, the haptic and the announcement. Launch and `Transaction.updates` never celebrate. **done-when:** S5.M1–S5.M5 and S0.10c are checked, and RG3 and RG4 are clean.
- [ ] **DOD5 Owner's Profile** (§4.1-5). The gold card, the perks expanding, and Manage for subscribers. **done-when:** S6.M1 and S6.M2 are checked.
- [ ] **DOD6 Nothing gated** (§4.1-6). **done-when:** RG13 is clean.
- [ ] **DOD7 MANUAL · matrix row 4.** **done-when:** you've seen all four:
  - Ask to Buy approved: the thank-you shows, with no confetti.
  - Ask to Buy declined: the paywall goes back to idle.
  - Cancel: nothing changes.
  - A purchase error switched on in the StoreKit config: the problem line shows.
- [ ] **DOD8 MANUAL · matrix row 5.** Speed up the StoreKit config's time rate and let a subscription lapse. **done-when:** after relaunch the Profile is free, and the gold card is gone.
- [ ] **DOD9 MANUAL · matrix row 6.** Test {Mac, iPhone simulator and device, iPad simulator} × {Midnight, System light, System dark} × {Reduce Motion off, on}. Spot-check VoiceOver on the toggle, the Buy labels, the gold card and the Mac modal. **done-when:** every combination has been looked at.
- [ ] **DOD10 MANUAL · matrix row 7.** On the Mac, quit with the Premium window open, then relaunch (R11). **done-when:** you've noted whether the window comes back, and if it does, that its prices load. Either outcome is accepted.
- [ ] **DOD11 MANUAL · the end-to-end path** (§4.10). **done-when:** you've seen each step:
  1. Xcode Run on the Mac with the StoreKit config.
  2. Open Profile: it looks as it does today, and the pill reads "Buy — $169.99".
  3. Tap the pill: the Premium window opens.
  4. Toggle to Yearly, see "Save 16%", tap Subscribe and confirm: the dimmed modal, confetti, and the headline appear.
  5. Press Return: the window closes, and Profile shows the gold card. Expanding it shows the perks and Manage.
  6. Delete the transaction and relaunch: the free Profile is back.
  7. Repeat on an iPhone device (sheet, drag to large, haptic), and again with Reduce Motion on.
- [ ] **DOD12 Gates and audit items.** **done-when** all of these hold:
  - GATES are green at the Step 7 commit;
  - every step's `.G` item is checked;
  - RG1–RG15 are clean;
  - the audit had no blockers, and its fixes are all checked: M1 by S4.4c and S6.7, M2 by S3.1–S3.3, M3 by S3.0/S3.F, and M4(c) by S0.3–S0.4.
- [ ] **DOD13 Release gate.** Step 0 is complete: true perks and IAP metadata (F10), prices, metadata, a live privacy page, and the sandbox/TestFlight pass. **done-when:** S0.1–S0.10 are checked. If App Review rejects the build anyway (R1), the ways out are, in order: (a) the F10 gate, (b) RQ1's Lifetime-only flag, (c) `SubscriptionStoreView` for the subscription card.
