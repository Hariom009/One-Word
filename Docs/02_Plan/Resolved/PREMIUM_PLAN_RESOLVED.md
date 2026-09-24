# Premium — resolved plan

**Resolves:** [PREMIUM_PLAN_AUDIT.md](../Audit/PREMIUM_PLAN_AUDIT.md) (verdict *Fix blockers first*) against
[PREMIUM_PLAN.md](../PREMIUM_PLAN.md). **This document stands alone — build from it.** Neither the
original plan nor the audit is needed to execute it.

**The change.** One Word goes freemium. **Everyday English is free.** The other seven dictionaries —
Emotions, Philosophy, Corporate Slang, Idioms, Classical English, Urdu, German — unlock **together**
with **one $9.99 one-time Apple in-app purchase** ("Premium"), sold from a **premium bar**. The
desktop widget obeys the same lock. No subscription.

---

## 0. Resolution

### Summary

| | Count | Findings |
|---|---|---|
| Self-resolved (code-dictated, re-grounded) | 11 | B1, m1–m9, C1 |
| Operator decisions, made live | 2 | M1, M2 |
| Not a defect | 1 | m10 |
| Deferred to their own work | 2 | German goal cap (from M1), sign-in plan (from M2) |

**Net:** the blocker is cleared. The plan is buildable as written. **Shipping it is gated** on a
separate sign-in plan (Sign in with Apple + account deletion) landing first — §11.

### Resolution log

| Id · sev | Resolution | What changed | Grounding |
|---|---|---|---|
| **B1** · blocker | Self | Search rows show a locked word's term, part of speech and a lock — **never its Hindi gloss**. `WordListView` reads `PremiumViewModel` from the environment; the gloss is gated on `premium.allows(hit.shelf)`. Step 5; §11 check 4 | `WordListView.swift:108,118,123-124` (gloss printed with no shelf condition); `:27` `showHindi` defaults on |
| **M1** · major | **Operator: hide when locked** | Profile's goal renders only when `fluencyGoal && premium.allows(Wordbook.german.id)`, and the Settings "Fluency goal" row is wrapped in the same condition. The stored switch value is kept, so it returns after purchase. Step 6 | `ProfileView.swift:38,66,198-202`; `ProfileViewModel.swift:26`; `SettingsView.swift:34,147-159`; target `LearnedWords.swift:109` = 3,000 |
| **M2** · major | Self (rating) + **operator: keep sign-in mandatory, add Sign in with Apple + account deletion** | R7 re-rated **High · High** on the code facts. A **release gate** in Step 0 and §11 — the sign-in plan lands before the Premium build is submitted. The residual "must register before buying" risk is carried as R7 with its exit | `RootView.swift:88-93` (hard gate); `AuthViewModel.swift:5`; `SignInView.swift:51-58` (skip is `#if DEBUG` only), `:83` (Google only); no account deletion (grep) |
| m1 | Self | The bar attaches with `.safeAreaInset(edge: .bottom, spacing: 0)` on the shelf instead of a `VStack`, so `PaneGround` paints under it. Step 3 | `RootView.swift:146`, `PaneHeader.swift:27` (the project's idiom); `Theme.swift:139` (`PaneGround.ignoresSafeArea()`), `:153-155`. The seam itself stays a by-eye check |
| m2 | Self | `load()` runs `refresh()` first (local store, works offline), then fetches the product. Neither gates the other. Step 2 | — |
| m3 | Self | `check_premium.sh` copies **`check_learned.sh:20-31`**'s `nonisolated enum AppGroup` shim to match its `-default-isolation MainActor` flag | `check_learned.sh:20-31,191`; `check_capture.sh:21,115` (plain enum, no flag) |
| m4 | Self | A verified purchase calls `refresh()` instead of `set(true)`, and `refresh()` applies only if it's still the latest (generation counter). Step 2, §6 | — |
| m5 | Self | `refresh()` clears `.pending` → `.idle` | — |
| m6 | Self | `restore()` maps a thrown error to `failed(_:)`, except `StoreKitError.userCancelled` | — |
| m7 | Self | `@ObservationIgnored` on the listener task and the generation counter | — |
| m8 | Self | Citations corrected throughout (stack table, SettingsView `:50`/`:51`, D10 wording) | `project.pbxproj` per the table in §1 |
| m9 | Self | Step 3 uses the generic `PremiumBar()` everywhere in the Dictionaries pane; `front` stays private to the shelf | `DictionaryPicker.swift:37` |
| m10 | **Not a defect** | "2,435 entries" is correct: `urdu.json` holds 2,435. The manual step now reads it as "the shelf's own count (2,435 today)" | `OneWord/Shared/urdu.json` counted |
| C1 · gap | Self | §7 lists every view-level gate as a named manual check | — |

### Operator decisions (for the record)

| | Decision | Alternative not taken | Flips if… |
|---|---|---|---|
| M1 | Hide the German goal and its Settings row while German is locked | Retire the goal · keep German free | German is expanded toward 3,000 entries — then an upsell becomes honest |
| M2 | Keep mandatory Google sign-in; add Sign in with Apple + in-app account deletion in a separate plan, landed **before** submission | Make sign-in optional · submit as is | App Review rejects for "registration before a non-account in-app purchase" → make the premium bar reachable signed-out (R7's exit) |

### Deferred

- **The German goal is unreachable even with Premium.** 96 entries in `german.json` against a 3,000
  target (`LearnedWords.swift:109`) caps every user at 3.2%. It predates this plan — expand German or
  retire the goal, separately.
- **The sign-in plan** (Sign in with Apple, in-app account deletion) — its own `/plan`. It is a
  **release gate** for this one, not a build dependency.

---

## 1. Header

**Read for this resolution** (`main` at `ecdcf9c`):
`WordListView.swift:20-45,52-153` · `WordListViewModel.swift:25-27,49,56-60,78-85` ·
`WordDetail.swift:19-60,100-124,148-175,224-242,276-317` · `DictionaryPicker.swift:1-281` ·
`HistoryView.swift:11-29,56-58,159-184` · `HomeView.swift:18,51-55` · `ProfileView.swift:38,60-70,195-225` ·
`ProfileViewModel.swift:20,26` · `SettingsView.swift:19-75,133-159` · `LearnedWords.swift:109` ·
`OneWordApp.swift:1-46` · `RootView.swift:84-94,126-128,140-152` · `SignInView.swift:40-83` ·
`AuthViewModel.swift:5-31,42-67` · `AppGroup.swift:1-48` · `WordSelectionStore.swift:1-34` ·
`SavedWords.swift:7-45,62-96,111-125` · `Wordbook.swift:1-63` · `Theme.swift:105-155` · `PaneHeader.swift:25-34` ·
`WordCapture.swift:60,78-110` · `WordWidget.swift:1-60` · `WordTimelineProvider.swift:1-45` ·
`RefreshWordIntent.swift:1-20` · `WordEntry.swift:10-12` · `tools/check_learned.sh:1-80,191-196` ·
`tools/check_capture.sh:13-30,112-118` · `OneWord.xcodeproj/project.pbxproj` (settings, membership, packages) ·
`OneWord/Shared/*.json` (entry counts).

### Detected stack

| | Detected | Evidence |
|---|---|---|
| Build | One `.xcodeproj`, two targets: app + WidgetKit extension. App sources in an Xcode 16 **file-system-synchronized** group that excepts only `Info.plist`; `Shared/` joins the widget by **explicit path** | `project.pbxproj:85-104`; `WordSelectionStore.swift` → widget at `:20,:81,:142,:320` (`:320` is in the widget's Sources phase `442CD88A…`) |
| Dependencies | SPM products `FirebaseAuth`, `FirebaseCore`, `GoogleSignIn` — no `FirebaseAnalytics`. **No StoreKit code yet** | `project.pbxproj:650-660`; grep |
| Min target | **macOS 14.0** — the app inherits it from the project configs; the widget sets it itself | project `:454,:512`; widget `:360,:387` |
| UI | SwiftUI; AppKit only as glue | `OneWordApp.swift:10`; `WordCapture.swift` |
| Architecture | MVVM; `@Observable` view models with no SwiftUI import; an SDK-wrapping view model held in `@State` at the app root | `WordViewModel.swift:12-16`; `AuthViewModel` at `OneWordApp.swift:25,34` |
| Concurrency | Swift 5 language mode in both targets; **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` in both**; approachable concurrency in the **app only**. Shared types the widget reads off-main are `nonisolated` | Swift 5 `:369,:396,:553,:590`; isolation widget `:367,:394`, app `:550,:587`; approachable `:549,:586`; `AppGroup.swift:11-14` |
| Shared state | App Group `UserDefaults` read by both processes | `AppGroup.swift:26,35` |
| Tests | **No test target.** Verification = `tools/check_*.sh`: `swiftc` over named sources + an `AppGroup` shim on a scratch suite | `check_learned.sh:8-31,191-196`; `CLAUDE.md` |
| Auth | **Mandatory** Google sign-in in release builds; the skip button is `#if DEBUG` | `RootView.swift:88-93`; `SignInView.swift:51-58,83` |
| Distribution | `MARKETING_VERSION = 1.0`, build 1 → **[Inference]** not on the Mac App Store yet; Mac App Store distribution is implied by "Apple's payment method" (D3) | `project.pbxproj:351,361` |

StoreKit 2 (`Product`, `Transaction`, `AppStore`) needs macOS 12; SwiftUI's `@Environment(\.purchase)`
needs macOS 14. Both clear the 14.0 floor with no `@available` gating.

---

## 2. Decisions

| # | Decision | Made by | Why |
|---|---|---|---|
| D1 | Free tier = Everyday English only | Operator | Stated |
| D2 | One product, **$9.99, pay once**, unlocks every premium dictionary | Operator | Stated; inside the scout's $9.99–$24.99 band; the one Mac comparable is $9.99 |
| D3 | Apple In-App Purchase only (→ Mac App Store distribution) | Operator | Stated |
| D4 | The product is a **non-consumable**, not a subscription | Apple's model | "Lifetime" = bought once, restorable forever |
| D5 | Search **teaser**: locked words are listed (term, part of speech, lock) but **no meaning is shown** in the row or on opening | Operator + B1 | Chosen over *hide* and *leave open* |
| D6 | **Bookmarks stay free** | Planner — F5 | The reader's own words; scout: LookUp took 1★ for locking collections |
| D7 | The lock is **not** in `WordProvider` | Code | It feeds search, entry counts and warm-up (`DictionaryPicker.swift:126,142-147`; `WordListViewModel.swift:49`) |
| D8 | The rules live in one new shared file, `Shared/Premium.swift`, `nonisolated` | Code | The widget reads off-main (`AppGroup.swift:11-14`) and has its **own** dictionary menu (`WordWidget.swift:18-48`) |
| D9 | The app-wide pick is locked **in `DictionaryShelf`** | Code | Its only writer (`DictionaryPicker.swift:174`, grep); History reuses it (`HistoryView.swift:184`) |
| D10 | Losing Premium **moves a locked pick back to English** in storage | Code | Four views read the raw `dictionaryID` through `@AppStorage` (`HomeView:18`, `WordDetail:32`, `HistoryView:18`, `DictionaryPicker:170`), plus one static reader (`Wordbook.swift:62`). Normalizing the stored value keeps all five right with **zero edits** to them, `AppGroup.swift` or `Wordbook.swift` |
| D11 | Widget: a locked choice renders Everyday English; its Edit menu labels premium books "· Premium" | Planner — F4 | Honest with no new widget layout; the widget itself is never paywalled |
| D12 | **Restore Purchase** in the bar and in Settings | App Review 3.1.1 | Non-consumables need a restore mechanism |
| D13 | Purchase via SwiftUI `@Environment(\.purchase)`; the result goes to the view model | Code | Correct presentation on macOS 14; the view model stays free of SwiftUI |
| D14 | Widget reloads on entitlement change **from the view layer** | Code | View models don't import UI frameworks; views already own `WidgetCenter` (`DictionaryPicker.swift:175`) |
| D15 | No grandfathering | Planner, from **[Inference]** 1.0/unshipped | Flips if a free build reaches the store first — F3 |
| D16 | The German fluency goal and its Settings row are **hidden while German is locked** | Operator (M1) | The goal counts only the German dictionary |
| D17 | Sign-in stays mandatory; **Sign in with Apple + in-app account deletion ship first**, in a separate plan | Operator (M2) | Release gate, not a build step |
| D18 | The premium bar attaches with `.safeAreaInset(edge: .bottom)` | Code (m1) | The project's idiom for pane strips; keeps the bar on `PaneGround` |

---

## 3. Scope & outcome

**Done when:**
- **Fresh install:**
  - Home, History and the widget show Everyday English.
  - The shelf shows seven locked spines, with the premium bar pinned under it showing Apple's
    localized price — never a hard-coded "$9.99".
- **Tapping a locked spine** brings its cover forward (the flip still plays) but **doesn't change the
  word of the day**. The caption reads "*N* entries · Premium".
- **Unlock** → Apple's purchase sheet → on success the locks and the bar disappear, the previewed book
  becomes the pick, and the widget redraws.
- **Search:**
  - "Search every dictionary" still finds words in locked books. Each row shows **the term, its part
    of speech and a lock — no Hindi**.
  - Opening one shows the headword and the premium bar: no definition, no related words, no bookmark
    button, and nothing is counted as learned.
- **Widget:** a widget set to "Urdu · Premium" while locked renders Everyday English; after purchase it
  renders Urdu.
- **German goal:** Profile's goal and its Settings row are hidden until German unlocks.
- **Refund or revocation:** the app returns to English on the next launch or `Transaction.updates`
  event, and the widget follows.
- **Restore Purchase** works from the bar and from Settings.
- **Gates:** `xcodebuild … build` and all **five** gates are green.

**In scope:**
- StoreKit 2 plumbing
- the shared lock
- the shelf lock and preview
- the premium bar
- the widget gate and labels
- the search teaser (row + detail)
- the Settings Premium section
- the German goal gate
- a local StoreKit config
- the gate script
- docs

**Out of scope:**
- subscriptions, offers, promo codes
- server receipt checks
- per-dictionary purchases
- **the sign-in changes** — a separate plan, but a release gate (D17)
- expanding German or retiring its goal (deferred)
- analytics

**Scope shape: single change** — one PR, landed as the ordered commits in §5.

---

## 4. Architecture fit

```
 StoreKit 2 ─ Transaction.currentEntitlements · Transaction.updates · AppStore.sync()      (app only)
      │
      ▼
 PremiumViewModel  @Observable · MainActor (default isolation)                     ViewModels/
      │  isUnlocked · allows(_:) (observed) ──► PremiumBar · DictionaryShelf · WordDetail
      │                                          · WordListView · SettingsView · ProfileView
      │  Premium.set(unlocked:)
      ▼
 App Group ── "premiumUnlocked" ──► Premium  nonisolated enum               Shared/ (app + widget)
           └─ "dictionaryID" ◄──── moved to "words" when Premium is lost
                                      ▲
                     WidgetDictionary.resource ── Premium.resolve(…)          OneWordWidget/
```

| Type | File | Target | Role | Mirrors |
|---|---|---|---|---|
| `Premium` (NEW) | `OneWord/Shared/Premium.swift` | app + **widget** | The rules: free ids, the cached flag, `allows`, `resolve`, and the one writer `set(unlocked:)` (with normalization) | `AppGroup.swift` / `WordSelectionStore.swift` |
| `PremiumViewModel` (NEW) | `OneWord/ViewModels/PremiumViewModel.swift` | app | The only StoreKit owner: product, entitlement refresh (latest-wins), updates listener, purchase result, restore, UI phase | `AuthViewModel` held at the root (`OneWordApp.swift:25,34`) |
| `PremiumBar` (NEW) | `OneWord/Views/PremiumBar.swift` | app | The bar: price, Unlock, Restore, phase states | Theme-token views (`DictionaryPicker.swift:86,125-134`) |
| `DictionaryShelf` / `DictionaryPicker` (MOD) | `OneWord/Views/DictionaryPicker.swift` | app | Spine lock, preview-don't-commit, "Premium" caption, commit-on-unlock; the bar as a bottom inset | — |
| `WordDetail` (MOD) | `OneWord/Views/WordDetail.swift` | app | Teaser gate — the single end of every full-view route | — |
| `WordListView` (MOD) | `OneWord/Views/WordListView.swift` | app | Lock mark **and gloss gate** on search rows | — |
| `SettingsView` (MOD) | `OneWord/Views/SettingsView.swift` | app | Premium section; Fluency-goal row gated | its own `section`/`card`/`row` calls (`:51` onward) |
| `ProfileView` (MOD) | `OneWord/Views/ProfileView.swift` | app | German goal gated | — |
| `OneWordApp` (MOD) | `OneWord/OneWordApp.swift` | app | Own and inject the view model; load on appear; reload widgets on change | `auth` at `:25,:34` |
| `WidgetDictionary` (MOD) | `OneWordWidget/WordWidget.swift` | widget | `resource` resolves through `Premium`; "· Premium" labels | — |

No new pattern is introduced: every new type copies an existing one.

---

## 5. Implementation steps

### Step 0 — App Store Connect, Xcode, and the release gate *(operator; parallel; blocks release only)*
- **Agreements.** Paid Applications Agreement signed, banking + tax complete — until then even sandbox
  purchases fail. **[Unverified]** current account state.
- **App record** for `com.hariom.swift.oneword` (`project.pbxproj:546`) if none exists.
- **In-app purchase:**

  | Field | Value |
  |---|---|
  | Type | **Non-Consumable** |
  | Product ID | **`com.hariom.swift.oneword.premium`** |
  | Reference name | "Premium" |
  | Price | **$9.99** (US) |
  | Display name | "One Word Premium" |
  | Description | "Every dictionary, unlocked for good." |
  | Review screenshot | the premium bar |
  | Family Sharing | per F1 |

- **The first IAP must be submitted with an app version** — attach it on the version page before *Submit for Review* (R1).
- **Xcode:** OneWord target → Signing & Capabilities → **+ In-App Purchase**. **[Unverified]** whether
  it writes an entitlements key on macOS; StoreKit runs through a system service, so the sandbox
  likely needs nothing more **[Inference]**.
- A **sandbox tester** Apple ID.
- **Release gate (D17):** the separate sign-in plan — Sign in with Apple beside Google, plus in-app
  account deletion — is **built and merged before the Premium build is submitted**.
- *Verify:* the product shows **Ready to Submit**; the sign-in plan's PR is merged.

### Step 1 — The shared lock and its gate *(foundation; reversible — nothing calls it yet)*
**NEW `OneWord/Shared/Premium.swift`** — pure Foundation, `nonisolated`:

```swift
nonisolated enum Premium {
    /// App Store Connect product id. Forever once shipped — Apple never lets an id be reused.
    static let productID = "com.hariom.swift.oneword.premium"
    /// What a free reader gets: Everyday English (the literal "words", as AppGroup.swift:41 does)
    /// and Bookmarks, which are the reader's own words.
    static let free: Set<String> = ["words", SavedWords.resource]
    private static let key = "premiumUnlocked"   // App Group; absent = locked

    static var isUnlocked: Bool { AppGroup.defaults.bool(forKey: key) }
    static func allows(_ id: String, unlocked: Bool = isUnlocked) -> Bool { unlocked || free.contains(id) }
    static func resolve(_ id: String) -> String { allows(id) ? id : "words" }
    /// The only writer. Losing Premium also moves a locked pick back to English — offset and pin
    /// with it — so every raw `@AppStorage("dictionaryID")` reader agrees without being touched.
    static func set(unlocked: Bool)
}
```
- `allows(_:unlocked:)` is **the** rule. The view model passes its observed flag so the two can't drift.
- `set(unlocked:)`: write the flag. If `!unlocked` and the stored `AppGroup.dictionaryKey` isn't in
  `free`, write `"words"` and call `WordSelectionStore.reset()` (`WordSelectionStore.swift:33`).
  Unlocking never moves the pick.
- **Dependencies are all `nonisolated`:** `SavedWords.resource` (`SavedWords.swift:27`),
  `AppGroup.defaults`/`.dictionaryKey` (`AppGroup.swift:14,35,37`), `WordSelectionStore.reset()`.
- **Widget membership:** mirror `WordSelectionStore.swift`'s four entries with fresh IDs —
  - `PBXBuildFile` (`project.pbxproj:20`)
  - `PBXFileReference` with `path = OneWord/Shared/Premium.swift` (`:81`)
  - the group child (`:142`)
  - the widget Sources phase (`:320`)

  The app target picks the file up through the synchronized group (`:85-93` excepts only `Info.plist`).
- **NEW `tools/check_premium.sh`** (§8):
  - compiles `Word`, `WordProvider`, `WordSelectionStore`, `SavedWords`, `Premium`, a shim and the check
    with `swiftc -O -default-isolation MainActor` (as `check_learned.sh:191`);
  - the shim is **`check_learned.sh:20-31`'s `nonisolated enum AppGroup`** on the scratch suite
    `com.hariom.swift.oneword.check`.
- **MOD `CLAUDE.md`** — add `check_premium` to the verify loop.
- *Verify:* `xcodebuild` builds both targets; `bash tools/check_premium.sh` is green. The four existing
  gates stay untouched and green — none of their compile lists names a file this plan changes.

### Step 2 — StoreKit plumbing and local test store
**NEW `StoreKit/OneWord.storekit`** at the repo root — **outside** the synchronized `OneWord/` folder,
so it isn't bundled into the app **[Inference]**.
- One Non-Consumable: `com.hariom.swift.oneword.premium`, $9.99, same display name.
- Attach it via Edit Scheme → OneWord → Run → Options → StoreKit Configuration. The scheme is shared
  (`OneWord.xcodeproj/xcshareddata/xcschemes/OneWord.xcscheme`), so the setting is committed.

**NEW `OneWord/ViewModels/PremiumViewModel.swift`** — `import Foundation, Observation, StoreKit`
(no SwiftUI, no WidgetKit):

```swift
@Observable
final class PremiumViewModel {                 // MainActor by default isolation
    enum Phase: Equatable { case idle, purchasing, pending, failed(String) }

    private(set) var isUnlocked: Bool           // seeded from Premium.isUnlocked (the cache)
    private(set) var product: Product?           // nil until loaded; drives the price
    private(set) var phase: Phase = .idle
    private(set) var storeUnavailable = false    // product didn't load — the bar offers Retry

    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private var generation = 0   // latest refresh wins

    init()                                       // seeds isUnlocked; starts the Transaction.updates listener
    func allows(_ id: String) -> Bool            // Premium.allows(id, unlocked: isUnlocked)
    func load() async                            // await refresh() FIRST (local, offline); THEN
                                                 //   product = try? await Product.products(for: [Premium.productID]).first
                                                 //   storeUnavailable = (product == nil)
    func refresh() async                         // generation += 1; let mine = generation
                                                 // owned ← Transaction.currentEntitlements: .verified, this productID,
                                                 //   revocationDate == nil
                                                 // guard mine == generation else { return }  — a newer refresh decides
                                                 // if phase == .pending { phase = .idle }; set(owned)
    func begin()                                 // phase = .purchasing (called by the view before the sheet)
    func handle(_ result: Product.PurchaseResult) async
    func failed(_ error: Error)                  // StoreKitError / Product.PurchaseError → one short line
    func restore() async                         // phase = .purchasing; try await AppStore.sync()
                                                 //   catch StoreKitError.userCancelled → ignore; other errors → failed(_:)
                                                 // then refresh(); phase back to .idle unless failed
    private func set(_ owned: Bool)              // always Premium.set(unlocked:); assign isUnlocked only if changed
}
```
- **`handle`:**
  - `.success(.verified(t))` → `await t.finish()`, `await refresh()`, `phase = .idle`. It deliberately
    does **not** call `set(true)` directly — a refresh keeps "latest wins" intact.
  - `.success(.unverified)` → `failed` ("Apple couldn't verify this purchase").
  - `.userCancelled` → `.idle`.
  - `.pending` (Ask to Buy) → `.pending`; the listener lands the approval.
  - `@unknown default` → `.idle`.
- **The listener:** `updates = Task { [weak self] in for await update in Transaction.updates { if case .verified(let t) = update { await t.finish() }; await self?.refresh() } }`.
  One recompute path for purchases made elsewhere, Ask to Buy approvals, refunds and revocations.
- **No `deinit`:** the object lives as long as the app (`@State` on the `App`).
  `// ponytail: app-lifetime owner — no cancel`.

**MOD `OneWord/OneWordApp.swift`** — mirror `auth` (`:25,:34`):
- `@State private var premium = PremiumViewModel()`.
- On `RootView()`: `.environment(premium)`, `.task { await premium.load() }`, and
  `.onChange(of: premium.isUnlocked) { WidgetCenter.shared.reloadAllTimelines() }` (`import WidgetKit`).
- *Verify:* build and run with the StoreKit config. Manage Transactions shows nothing owned. A
  temporary `print(premium.product?.displayPrice)` shows `$9.99` — remove it before committing.

### Step 3 — The premium bar and the shelf lock *(first end-to-end slice)*
**NEW `OneWord/Views/PremiumBar.swift`** — `struct PremiumBar: View { var book: Wordbook? = nil }`
- **Reads:** `@Environment(PremiumViewModel.self)`, `@Environment(\.purchase)`, and the theme via
  `Theme.of(scheme, doodle)`.
- **Monochrome** — the covers stay the only coloured surface (`Wordbook.swift:8`): a `t.surface` card,
  `t.hairline` edge, `t.ink` / `t.muted` text, `t.radius(_:)`.
- **Copy (F6):**
  - title "Unlock every dictionary" — or "Unlock \(book.shortName)" when a book is passed (the
    `WordDetail` teaser);
  - subline "\(n) dictionaries, one payment, yours for good", with
    `n = Wordbook.all.filter { !Premium.free.contains($0.id) }.count`;
  - primary button "Unlock — \(product.displayPrice)";
  - secondary "Restore Purchase" → `Task { await premium.restore() }`.
- **Unlock:** `Task { premium.begin(); do { await premium.handle(try await purchase(product)) } catch { premium.failed(error) } }`.
- **States:**
  - product loading → a disabled "Unlock" and a small `ProgressView`;
  - `.purchasing` → spinner, both buttons disabled;
  - `.pending` → "Waiting for approval";
  - `.failed(msg)` → `msg` in `t.muted`;
  - `storeUnavailable` → "The App Store isn't reachable" + Retry (`await premium.load()`);
  - unlocked → `EmptyView()`.

**MOD `OneWord/Views/DictionaryPicker.swift`**
- **Environment:** `DictionaryShelf` gets `@Environment(PremiumViewModel.self) private var premium`.
- **`pick(_:)` (`:152-165`):** keep the swap animation for every book, but commit only an allowed one —
  `if premium.allows(book.id) { selection = book.id; onPick(book) }`. The reduce-motion path (`:156`)
  sets `front` only, as today.
- **Commit on unlock:** `.onChange(of: premium.isUnlocked)` — when it turns true and
  `front != selection`, `selection = front; onPick(Wordbook.named(front))`.
- **Caption (`:125-134`):** when `!premium.allows(front)`, show "\(count) entries · Premium" with an
  accessibility-hidden `lock.fill`, instead of "· Selected for word of the day".
- **Spine:** `ShelfBook` (`:184`) forwards `locked: Bool` to `BookSpine` (`:222`, used at `:200`), which
  draws a small `lock.fill` in its own ink near the foot.
- **Accessibility (`:114-117`):** locked books add `.accessibilityValue("Premium")` and
  `.accessibilityHint("Shows how to unlock")`.
- **The bar — `DictionaryPicker.body` (`:173-178`):**
  `DictionaryShelf(selection: $dictionaryID) { _ in WidgetCenter.shared.reloadAllTimelines() }`
  `.safeAreaInset(edge: .bottom, spacing: 0) { if !premium.isUnlocked { PremiumBar() } }` then
  `.paneHeader("Dictionaries")`.
  - This mirrors `RootView.swift:146` and `PaneHeader.swift:27`.
  - `PaneGround`'s `.ignoresSafeArea()` (`Theme.swift:139`) paints under the inset, and the shelf's
    `GeometryReader` sizes to what's left.
  - `DictionaryPicker` reads the view model from the environment too.
- **`#Preview` (`:279-281`):** add `.environment(PremiumViewModel())`. A missing `@Observable`
  environment object is a runtime crash, not a compile error.
- **History** (`HistoryView.swift:184`) gets the lock, the preview and the caption for free, and shows
  no bar.
- *Verify:*
  - locked spines;
  - preview without commit (Home keeps English);
  - the bar sits on the pane's ground **by eye in a light theme and in Midnight**;
  - Unlock → sheet → bought → locks gone, the previewed book becomes the pick, the widget redraws.

### Step 4 — Widget gate
**MOD `OneWordWidget/WordWidget.swift`**
- **`resource` (`:36-38`)** becomes `Premium.resolve(self == .followApp ? AppGroup.dictionaryID : rawValue)`.
  - This is the widget's single dictionary read: `provider(for:)` (`WordTimelineProvider.swift:19-21`)
    and `snapshot`/`timeline` all route through it.
  - `placeholder` uses `.words`, which is free.
  - The refresh intent only advances the offset (`RefreshWordIntent.swift:16`), and `WordEntry` carries
    no book name (`:10-12`).
- **`caseDisplayRepresentations` (`:22-32`):** the seven premium cases become `"Emotions · Premium"` etc.
  - **Keep them string literals** — AppIntents extracts these at build time **[Inference]**.
    `// ponytail: mirrors Premium.free by hand — a literal is all AppIntents accepts`.
  - Raw values are untouched, so stored widget configurations survive.
- *Verify:* while locked, Edit Widget → "Urdu · Premium" → the widget shows Everyday English. Buy → it
  redraws to Urdu.

### Step 5 — Search teaser (row + detail)
**MOD `OneWord/Views/WordListView.swift`** *(B1)*
- Add `@Environment(PremiumViewModel.self) private var premium` beside the other environment reads (`:31`).
- **`row(_:_:mark:scale:)` (`:108`):** the gloss condition at `:123` becomes
  `if showHindi && premium.allows(hit.shelf)`. The term (`SwellingTerm`) and part of speech (`:118`)
  stay. The row's VoiceOver text follows what's visible, so the gloss drops out of it too.
- **`shelfMark(_:_:)` (`:144-153`):** add a `lock.fill` when `!premium.allows(shelf)`; the accessibility
  label (`:153`) becomes "\(name), Premium".
- **Unaffected:**
  - The Bookmarks pane reuses this row pinned to `.saved` (`RootView.swift:126`), which is free.
  - Search matches only the folded term (`WordListViewModel.swift:78`), so typing a meaning can't
    surface locked words.
  - The everywhere copy (`:197-202`) stays true.

**MOD `OneWord/Views/WordDetail.swift`** — the single end of every full-view route (`:119-122`), so one
gate covers search hits, related words, Learned and Profile rows:
- **Setup:** `@Environment(PremiumViewModel.self) private var premium`;
  `private var locked: Bool { !premium.allows(shelfID) }` (`shelfID` at `:232`).
- **In `page` (`:52`):** keep the headword; replace everything below it — definition, Hindi, example,
  related — with `PremiumBar(book: Wordbook.named(shelfID))` when `locked`. **[Unverified]** the exact
  subview boundaries between `:56` and `:110`; wrap the entry body, not the `ZStack` transition.
- **`.task(id: shelfID)` (`:118`):** `guard !locked else { return }` — no related index for a locked book.
- **Learned recording (`:123-124`):** skip `LearnedWords.record` when `locked`.
- **Header (`:48`):** `.paneHeader(back: true) { if !locked { WordActions(word: word) } }`. A bookmark
  stores the full `Word` (`SavedWords.swift:18-19`), and `WordActions`' toggle (`:285`) is the only
  bookmark writer. Its other callers (`HomeView:51`, `HistoryView:56`) only ever show allowed books.
- *Verify:* checks 3 and 4 in §11.

### Step 6 — Settings and Profile
**MOD `OneWord/Views/SettingsView.swift`**
- `@Environment(PremiumViewModel.self) private var premium`.
- **A Premium section** at the top of the sections `VStack` (`:50`, before `section("Appearance"` at
  `:51`), using the same `section`/`card`/`row` calls:
  - **locked** → `PremiumBar()` (it carries Restore);
  - **unlocked** → one row, "All dictionaries unlocked", with no button.
- **The Fluency goal row (`:147-159`)** is wrapped in `if premium.allows(Wordbook.german.id)` *(M1)*.
  The `@AppStorage("fluencyGoal")` value (`:34`) is left alone, so the switch returns as it was after purchase.

**MOD `OneWord/Views/ProfileView.swift`** *(M1)*
- `@Environment(PremiumViewModel.self) private var premium`.
- `:66` becomes `if fluencyGoal && premium.allows(Wordbook.german.id) { goal(t) }`.
- `ProfileViewModel.learnedGerman` (`ProfileViewModel.swift:26`) is unchanged; it's simply not shown.
- Add `.environment(PremiumViewModel())` to any `#Preview` in these two files.
- *Verify:* check 6 in §11. Restore: delete the transaction in the manager → Settings shows the bar →
  re-buy (with the local config that's the practical test; `AppStore.sync()` is exercised for real in
  sandbox/TestFlight — check 10).

### Step 7 — Refund, revocation, Ask to Buy *(verification of Step 2)*
No new code. The recipe is checks 7–9 in §11. The one place to fix if something fails is `refresh()`.

### Step 8 — Docs (`00_Context` is kept current)
- `Docs/00_Context/REPO_MAP.md`: add `StoreKit/`, `Shared/Premium.swift`,
  `ViewModels/PremiumViewModel.swift`, `Views/PremiumBar.swift`.
- `Docs/00_Context/ARCHITECTURE.md`: a short "Premium — where the lock lives" section covering:
  - the rule lives in `Premium`, and `set(unlocked:)` is its only writer;
  - the widget's one chokepoint;
  - the `WordDetail` teaser gate and the search-row gloss gate;
  - never gate `WordProvider`.

---

## 6. Data & persistence

| Key (App Group) | Type | Writer | Readers | Note |
|---|---|---|---|---|
| `premiumUnlocked` (NEW) | Bool | `Premium.set(unlocked:)` only | `Premium.isUnlocked` → the widget via `resolve`; the view model's seed | Absent = locked — `bool(forKey:)`'s false-when-missing is the right default here |
| `dictionaryID` | String | the shelf (`DictionaryPicker.swift:174`) **and** `Premium.set(unlocked: false)` | four `@AppStorage` views + `Wordbook.selected` + `AppGroup.dictionaryID` | Normalized to `"words"` when Premium is lost |
| `wordOffset`, `pinnedTerm` | Int, String? | unchanged + normalization | as today | Reset only when the pick moves |
| `fluencyGoal` (standard defaults) | Bool | Settings | Profile | Untouched; its row and the goal are hidden while German is locked |

- **No migration** — one new key, absent = locked.
- **Forever values:** the product ID and the key name `premiumUnlocked`.
- StoreKit is the truth; the cache is a mirror the widget can read off-main. **Known ceiling:** a
  user-editable plist (R4).

---

## 7. Concurrency, state & memory

- **Isolation map:**
  - `PremiumViewModel` is MainActor by the target default.
  - `Premium` is **explicitly `nonisolated`** — the widget's `timeline(for:in:)` calls `resolve`
    off-main. Its callees are `nonisolated` too (`AppGroup.swift:14`, `WordSelectionStore.swift:15-33`,
    `SavedWords.swift:27`).
  - All views are MainActor.
- **Sendable and awaits:**
  - `Product`, `Transaction`, `VerificationResult` and `Product.PurchaseResult` are `Sendable`.
  - `await purchase(product)` and `await t.finish()` suspend without blocking.
  - `for await` over `currentEntitlements` / `.updates` runs on the main actor — low frequency, fine.
- **Re-entrancy (m4):**
  - `refresh()` suspends while it reads `currentEntitlements`, so two refreshes can interleave.
  - The generation counter makes the *latest-started* refresh the only one that applies.
  - A refresh whose snapshot predates a purchase can no longer flip the app back to locked — which
    would also have moved the pick back to English.
  - A purchase ends in a `refresh()`, never a bare `set(true)`.
- **Tasks:**
  - **The listener** is an unstructured `Task` started in `init` and lives as long as the app.
  - **`load()`** runs from `.task` on the root view: it's cancelled with the window, re-runs for a new
    window, and is idempotent. Its entitlement refresh never waits on the network (m2).
  - **Purchase and restore** are unstructured `Task`s from the bar. If the view goes, the system sheet
    still owns the outcome and the listener catches it.
- **Retain cycles:**
  - The listener captures `[weak self]` and calls `self?.refresh()` per update.
  - Purchase and restore `Task`s hold the view model for seconds only.
  - No delegates, no Combine.
- **Observation:** views read `premium.isUnlocked` / `premium.allows(_:)` — **never
  `Premium.isUnlocked`**, a `UserDefaults` read Observation can't see. Only the widget and `Premium`
  itself read the cache. `updates` and `generation` are `@ObservationIgnored`.
- **Launch ordering:** the view model seeds from the cache synchronously, so owners see no flash of
  "locked". `refresh()` then corrects it — offline-capable from the device's transaction store
  **[Inference]**.

---

## 8. Test plan

**`tools/check_premium.sh`** — real sources, the `nonisolated` scratch-suite `AppGroup` shim,
`check(_:_:)` lines, and `fatalError` on failure:

```
Premium, locked
  ok  a fresh install is locked
  ok  Everyday English is free
  ok  Bookmarks is free
  ok  emotions, philosophy, startup, idioms, classical, urdu, german are each locked
  ok  a locked id resolves to Everyday English
  ok  an unknown id (the removed "medical") resolves to Everyday English
Premium, unlocked
  ok  every shelf is open
  ok  resolve passes a premium id through
Losing Premium
  ok  a premium pick falls back to Everyday English
  ok  and the word offset resets with it
  ok  and a pinned capture is dropped
  ok  a free pick survives the lock with its offset intact
  ok  Bookmarks survives the lock
  ok  unlocking never moves the pick
```

**View-level gates are verified by hand, each by name** (C1). The project has no XCTest target, so
these are manual checks in §11:

| Gate | Where | Manual check |
|---|---|---|
| Shelf preview-don't-commit | `DictionaryPicker.swift:152-165` | 2 |
| Search-row gloss hidden | `WordListView.swift:123` | 4 |
| Detail teaser (no body, no actions, not learned) | `WordDetail.swift:48,52,118,123` | 3 |
| Widget resolve + labels | `WordWidget.swift:22-38` | 5 |
| German goal hidden | `ProfileView.swift:66`, `SettingsView.swift:147-159` | 6 |

**Hard to test here:** everything in `PremiumViewModel` that touches StoreKit. The seam that would fix
it is an XCTest target running `SKTestSession` against `OneWord.storekit` — deliberately out of scope.
Its stateful effects all go through `Premium.set`, which the gate covers.

---

## 9. Accessibility, localization & project mechanics

- **VoiceOver:**
  - locked spines read "Dictionary of Urdu, Premium", hint "Shows how to unlock";
  - search hits read "…, Premium", and a locked row's utterance carries no gloss;
  - lock glyphs beside text that already says it are `accessibilityHidden`;
  - the bar's primary button reads "Unlock every dictionary, \(displayPrice)".
- **Reduce Motion:** the locked preview follows the shelf's existing path (`DictionaryPicker.swift:156`).
- **Localization:** the app uses literal `Text` strings (no String Catalog — none in the repo). **Never
  format a price**; `displayPrice` is already localized per storefront.
- **Target membership:** `Premium.swift` joins the widget by explicit pbxproj path (Step 1). Everything
  else new is app-only and joins through the synchronized group. `OneWord.storekit` belongs to no target.
- **Scheme:** the StoreKit config lives on the shared `OneWord.xcscheme` Run action.
- **Capabilities:** + In-App Purchase on the app target. No Info.plist keys.
- **Environment:** injected once at the root (Step 2). Sheets inherit it — History's sheet already
  reads `\.doodle` from the root. The capture HUD's `NSHostingView` (`WordCapture.swift:97`) hosts only
  `CaptureHUDView`, which reads no premium state — **keep it that way**.
- **Previews:** every `#Preview` that renders `DictionaryShelf`, `WordDetail`, `WordListView`,
  `SettingsView`, `ProfileView` or `PremiumBar` needs `.environment(PremiumViewModel())`.
- **Gates:** new `check_premium.sh`; the existing four are unchanged; `CLAUDE.md` lists five.

---

## 10. Forks still open (operator)

| | Fork | Default | The other branch wins when… |
|---|---|---|---|
| F1 | Family Sharing on the IAP | **Off** at launch | Reviews or support ask — Apple won't let you switch it off again once it's on |
| F2 | India price | Apple's auto-equalized price for the $9.99 tier | India's conversion lags after ~30 days → set a manual India price |
| F3 | Paywall in the first store release | Yes — no grandfathering | A free build ships first → grant on `AppTransaction.shared`'s `originalAppVersion` |
| F4 | Widget honesty | "· Premium" labels only | Support mail says the widget "doesn't change" → a one-line caption in `WordEntry`/`WordWidgetView` |
| F5 | Bookmarks free (D6) | Free | You want Bookmarks premium → remove `SavedWords.resource` from `Premium.free` |
| F6 | Bar copy and placement | Step 3 draft; bar under the shelf; Premium section first in Settings | Taste — edit strings in `PremiumBar` only |

---

## 11. Risks & exits

| | Risk | Sev · Conf | Leading indicator | Cheapest exit |
|---|---|---|---|---|
| R1 | IAP not attached to the first app version → purchases fail in production | High · High | IAP still "Ready to Submit" after launch; `products(for:)` empty in prod | Attach it on the version page before Submit (Step 0) |
| R2 | `Premium.swift` missing from the widget target | Med · Med | Widget build: "cannot find 'Premium' in scope" | Mirror `WordSelectionStore.swift`'s four pbxproj entries |
| R3 | Product never loads in dev | Med · Med | Bar stuck on Retry | StoreKit config on the scheme; the ID lives only in `Premium.productID` |
| R4 | The cache is a user-editable plist; a refund while the app is closed leaves the widget on a premium book until the next launch | Low · High (by design) | — | The widget checks `Transaction.currentEntitlements` itself — **[Unverified]** in a macOS widget extension |
| R5 | `@Environment(PremiumViewModel.self)` read with nothing injected → crash | Med · Med | Crash in a preview, sheet or AppKit-hosted view | Root injection; fix previews; keep premium reads out of `CaptureHUDView` |
| R6 | Computed AppIntents display strings fail metadata extraction | Low · Med | A build error from the AppIntents processor | Literals (Step 4) |
| R7 | **Release blocked at review by the sign-in gate** | High · **High** on the code facts (`RootView.swift:88-93`, `SignInView.swift:83`, no deletion) | Rejection citing 4.8 / 5.1.1(v) / registration before an in-app purchase | **Chosen:** Sign in with Apple + account deletion land first (Step 0 gate). **Residual [Inference]:** a "must register before a non-account in-app purchase" rejection can still come → make the premium bar reachable signed-out |
| R8 | A teaser leak through search rows, Bookmarks or Learned | Med · Med | A locked word's meaning is visible anywhere on the free tier | Row gloss gate (Step 5) + `WordDetail` gate (hides actions, skips recording) |
| R9 | Two refreshes interleave and flip the state | Low · Med **[Inference]** | Premium "blinks" locked right after buying; the pick jumps to English | Generation counter; purchase ends in `refresh()` (Step 2) |

---

## 12. Sequencing & verification

- [ ] **0** App Store Connect + capability *(operator, parallel)* · **release gate:** the sign-in plan merged
- [ ] **1** `Premium.swift` + widget membership + `check_premium.sh` + `CLAUDE.md` — *first reversible move*
- [ ] **2** `OneWord.storekit` + scheme + `PremiumViewModel` + root injection — unblocks 3–6
- [ ] **3** `PremiumBar` + shelf lock/preview + the bar as a bottom inset — *first end-to-end slice*
- [ ] **4** Widget gate + labels
- [ ] **5** Search teaser: row gloss gate + `WordDetail` gate + lock marks
- [ ] **6** Settings Premium section + German goal gate in Settings and Profile
- [ ] **7** Refund / revocation / Ask to Buy verification
- [ ] **8** REPO_MAP + ARCHITECTURE

**Gates**
```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```
```bash
for s in check_words check_related check_learned check_capture check_premium; do bash tools/$s.sh; done
```

**Manual checks** — run from Xcode with `OneWord.storekit` (Debug → StoreKit → Manage Transactions):

1. **Fresh state.** Delete all transactions, then relaunch. Home, History and the widget show Everyday
   English. There are seven locked spines, and the bar shows **$9.99** on the pane's ground — check it
   by eye in a light theme and in Midnight.
2. **Preview.** Tap the Urdu spine. It comes forward and the caption shows the shelf's own count
   (2,435 today) · Premium. Home still shows English.
3. **Detail teaser.** Open a locked search hit. You see the headword and the bar only: no definition,
   no related words, no bookmark button. Profile's Learned count is unchanged.
4. **Search rows.** Search a word only Urdu has. The row shows **the term, its part of speech and a lock
   — no Hindi**, with Show Hindi on in Settings.
5. **Widget.** Edit Widget → "Urdu · Premium". The widget shows English.
6. **German goal.** Turn on Fluency goal (on a debug build, before locking), then lock. The Profile goal
   and the Settings row are gone. Buy, and both return with the switch as it was.
7. **Purchase.** Unlock and buy. The bar and locks disappear, Urdu becomes the pick, Home shows Urdu,
   and the widget redraws to Urdu.
8. **Refund.** Manage Transactions → **Refund**. Everything goes back to English and the widget follows.
9. **Ask to Buy.** Enable Ask to Buy → Unlock → "Waiting for approval". Approve in the manager: it
   unlocks without a relaunch. Decline instead: the bar stops saying "Waiting" after the next refresh.
10. **Failure.** Enable **Fail Transactions** → the bar shows a one-line error and nothing unlocks.
11. **Localized price.** Set the config's storefront to **India** → the bar shows ₹.
12. **Restore, for real** (once, before release, sandbox/TestFlight). Buy on one Mac → **Restore
    Purchase** on another. Cancelling the Apple ID prompt shows no error.

---

## 13. Open questions & assumptions

- **[Inference]** The app isn't on the Mac App Store yet (1.0, build 1, no release trail) → no
  grandfathering. D3 ("Apple's payment method") implies Mac App Store distribution. **If it will ship
  outside the Mac App Store** (Developer ID), StoreKit in-app purchases don't work there and the payment
  approach must change. *Resolves:* App Store Connect's app record.
- **[Unverified]** The In-App Purchase capability writes no entitlements key on macOS. *Resolves:*
  `git diff OneWord/OneWord.entitlements` after Step 0.
- **[Unverified]** `OneWord.storekit` outside `OneWord/` stays out of the app bundle. *Resolves:* inspect
  `OneWord.app/Contents/Resources` after a build.
- **[Unverified]** `WordDetail.page`'s subview boundaries (`:56-:110`). *Resolves:* read the span while
  building Step 5.
- **[Unverified]** Whether a seam shows under the bar in any theme. *Resolves:* manual check 1.
- **[Inference]** AppIntents requires literal `caseDisplayRepresentations`. *Resolves:* the Step 4 build.
- **[Unverified]** StoreKit's `Transaction` APIs inside a macOS widget extension — this matters only for
  R4's exit. *Resolves:* a spike, only if R4 bites.
- **[Assumption]** The Paid Applications Agreement, banking and tax are, or will be, complete before
  sandbox testing. *Resolves:* App Store Connect → Business.
- **Deferred:**
  - The German goal is unreachable at 96 of 3,000 even with Premium — expand German or retire the goal,
    separately.
  - The sign-in plan — its own `/plan`, gating release (D17).
