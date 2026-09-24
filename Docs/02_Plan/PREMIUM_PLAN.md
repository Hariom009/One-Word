# Premium — plan

**The change.** One Word goes freemium. **Everyday English is free.** The other seven dictionaries —
Emotions, Philosophy, Corporate Slang, Idioms, Classical English, Urdu, German — unlock **together**
with **one $9.99 one-time Apple in-app purchase** ("Premium"), sold from a **premium bar**. The
desktop widget obeys the same lock. No subscription.

**Upstream.** No `/strategize` doc. Planned from the live discussion, the code, and the
dictionary-lineup scout run of 2026-09-21 (`~/Desktop/scout-oneword-dictionary-lineup-260921.html`;
brief at [DICTIONARY_LINEUP_SCOUT_PROMPT.md](../06_Misc/DICTIONARY_LINEUP_SCOUT_PROMPT.md)).
Planning without a committed strategy is weaker; §1 records who made each call so the audit can
challenge the right ones.

**Read for this plan** (all on `main` at `ecdcf9c`):
`OneWord/OneWordApp.swift:1-46` · `OneWord/Shared/AppGroup.swift:1-48` ·
`OneWord/Shared/WordSelectionStore.swift:1-34` · `OneWord/Shared/SavedWords.swift:27,125` ·
`OneWord/Models/Wordbook.swift:1-63` · `OneWord/Views/DictionaryPicker.swift:1-281` ·
`OneWord/Views/HistoryView.swift:11-29,159-184` · `OneWord/Views/WordListView.swift:25-59,144-153,197-202` ·
`OneWord/ViewModels/WordListViewModel.swift:40-60` · `OneWord/Views/WordDetail.swift:19-60,100-122,232-238` ·
`OneWord/Views/SettingsView.swift:19-75` · `OneWord/ViewModels/WordViewModel.swift:1-45` ·
`OneWordWidget/WordWidget.swift:1-60` · `OneWordWidget/WordTimelineProvider.swift:1-45` ·
`OneWord/OneWord.entitlements` · `OneWordWidget/OneWordWidget.entitlements` ·
`OneWord.xcodeproj/project.pbxproj` (settings + `WordSelectionStore` membership) ·
`tools/check_learned.sh:1-80,191-196` · `tools/check_capture.sh:13-26,115-117` · `tools/check_{words,related}.sh` ·
`Docs/README.md` · `Docs/00_Context/ARCHITECTURE.md` · `Docs/00_Context/DESIGN_BRIEF.md` (grep) ·
`~/.claude/agents/ios-planner.md`.

### Detected stack

| | Detected | Evidence |
|---|---|---|
| Build | One `.xcodeproj`, two targets: app + WidgetKit extension. App sources in an Xcode 16 **file-system-synchronized** group; `Shared/` joins the widget by **explicit path** | `project.pbxproj:85-104` (sync group), `:20,:81,:142,:320` (`WordSelectionStore.swift` → widget) |
| Dependencies | SPM: `firebase-ios-sdk`, `GoogleSignIn-iOS`. **No StoreKit code anywhere** | `project.pbxproj:628-644`; grep `storekit\|purchase\|entitle` → none in Swift |
| Platform / target | **macOS 14.0** | `project.pbxproj:360` |
| UI | SwiftUI; AppKit only as glue | `OneWordApp.swift:10`, `WordCapture.swift` |
| Architecture | MVVM, `@Observable` view models with no SwiftUI import; SDK-wrapping VM injected at the app root | `WordViewModel.swift:12-16`; `AuthViewModel` at `OneWordApp.swift:25,34` |
| Concurrency | Swift 5 language mode, **`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`**, approachable concurrency; shared types the widget reads off-main are marked `nonisolated` | `project.pbxproj:367,369,549`; `AppGroup.swift:11-14`; `WordSelectionStore.swift:8` |
| Shared state | App Group `UserDefaults` (`LAP54KU2SV.group.com.hariom.swift.oneword`), read by both processes | `AppGroup.swift:26,35` |
| Tests | **No test target.** Verification = `tools/check_*.sh`: `swiftc` over named sources + an `AppGroup` shim on a scratch suite | `check_learned.sh:8-31,191-196`; `CLAUDE.md` "Verify before saying it's done" |
| Distribution | `MARKETING_VERSION = 1.0`, build 1, no release trail in git or Docs → **[Inference]** not on the Mac App Store yet | `project.pbxproj:351,361` |

StoreKit 2 (`Product`, `Transaction`, `AppStore`) needs macOS 12; SwiftUI's `@Environment(\.purchase)`
needs macOS 14 — both clear the 14.0 floor with no `@available` gating.

---

## 1. Decisions log

| # | Decision | Made by | Why |
|---|---|---|---|
| D1 | Free tier = Everyday English only | **Operator** | Stated in the request. (The scout suggested one free themed teaser pack; not taken.) |
| D2 | One product, **$9.99, pay once**, unlocks every premium dictionary | **Operator** | Stated. Inside the scout's evidenced $9.99–$24.99 band; the only Mac comparable (Word of the Day by LookUp) is $9.99 |
| D3 | Apple In-App Purchase only | **Operator** | Stated |
| D4 | The product is a **non-consumable**, not a subscription | Apple's model | "Lifetime subscription" in App Store Connect terms is a non-consumable: bought once, restorable forever. An auto-renewable subscription renews |
| D5 | Search **teaser**: locked words appear in "Search every dictionary" with a lock; opening one shows the premium bar, never the definition | **Operator** | Chosen over *hide* and *leave open* |
| D6 | **Bookmarks stay free** | Planner — flip in §9 F5 | They are the reader's own words. Scout: LookUp took 1★ reviews for moving collections behind Pro |
| D7 | The lock is **not** in `WordProvider` | Code | `WordProvider` also feeds search, the shelf's entry counts and warm-up (`DictionaryPicker.swift:126,142-147`; `WordListViewModel.swift:49`) — locking it blanks them |
| D8 | The lock's rules live in **one new shared file**, `Shared/Premium.swift`, `nonisolated` | Code | The widget reads off the main actor (`AppGroup.swift:11-14`); the widget has its **own** per-widget dictionary menu (`WordWidget.swift:18-48`), so an app-only lock leaves a hole |
| D9 | The app-wide pick is locked **in `DictionaryShelf`**, not `DictionaryPicker` | Code | The shelf is the pick's only writer (`DictionaryPicker.swift:174`, confirmed by grep) and History reuses it (`HistoryView.swift:184`) — one lock covers both |
| D10 | Losing Premium **moves a locked pick back to English** in storage | Code | Five views read the raw `dictionaryID` via `@AppStorage` (`HomeView:18`, `WordDetail:32`, `HistoryView:18`, `DictionaryPicker:170`, `Wordbook.swift:62`). Normalizing the stored value keeps every one of them right with **zero edits** to those readers, `AppGroup.swift` and `Wordbook.swift` |
| D11 | Widget: a locked choice **renders Everyday English**; the Edit Widget menu labels premium books "· Premium" | Planner — §9 F4 | Honest without new widget layout. The widget itself is never paywalled (scout: *"paywalls galore i love the daily vocab widget feature…"*) |
| D12 | **Restore Purchase** in the bar and in Settings | App Review 3.1.1 | Non-consumables need a restore mechanism |
| D13 | Purchase via SwiftUI **`@Environment(\.purchase)`**, result handed to the view model | Code | Correct presentation context on macOS 14, and the view model stays free of SwiftUI (`ARCHITECTURE.md` "Conventions") |
| D14 | Widget reloads on entitlement change **from the view layer** | Code | View models don't import UI frameworks; views already own `WidgetCenter` calls (`DictionaryPicker.swift:175`) |
| D15 | No grandfathering | Planner, from **[Inference]** 1.0/unshipped | Flips if a free build reaches the store first — §9 F3 |

---

## 2. Scope & outcome

**Done when:**
- A fresh install shows Everyday English on Home, History and the widget. The shelf shows seven locked
  spines and the premium bar with Apple's localized price (₹ in India, never a hard-coded "$9.99").
- Tapping a locked spine brings its cover forward (the flip still plays) but **does not change the
  word of the day**; the caption reads "*N* entries · Premium".
- Unlock → Apple's purchase sheet → on success the locks and the bar disappear, the previewed book
  becomes the pick, and the widget redraws.
- "Search every dictionary" still finds words in locked books, each wearing a lock; opening one
  shows the headword and the premium bar — no definition, no related words, not counted as learned,
  no bookmark button.
- A widget set to "Urdu · Premium" while locked renders Everyday English; after purchase it renders Urdu.
- Refund or revocation: on the next launch or `Transaction.updates` event the app goes back to
  English and the widget follows.
- Restore Purchase works from the bar and from Settings.
- `xcodebuild … build` and all **five** gates are green (four existing + the new `check_premium`).

**In scope:** StoreKit 2 plumbing, the shared lock, shelf lock + preview, premium bar, widget gate +
labels, search teaser, Settings section, StoreKit config file for local testing, gate script, docs.

**Out of scope:** subscriptions, promo codes/offers, a server-side receipt check, per-dictionary
purchases, Android/iOS targets, Sign in with Apple / account deletion (see R7 — they may gate the
same release), paywall A/B testing, analytics.

**Scope shape: single change.** One PR, landed as the ordered commits below. Every step compiles
alone, but only the whole ships.

---

## 3. Architecture fit

```
 StoreKit 2 ─ Transaction.currentEntitlements · Transaction.updates · AppStore.sync()      (app only)
      │
      ▼
 PremiumViewModel  @Observable · MainActor (default isolation)          ViewModels/
      │  isUnlocked (observed) ──────────► PremiumBar · DictionaryShelf · WordDetail · WordListView · SettingsView
      │  Premium.set(unlocked:)            (views read it from the environment)
      ▼
 App Group ── "premiumUnlocked" ──► Premium  nonisolated enum                      Shared/ (app + widget)
           └─ "dictionaryID" ◄──── moved to "words" when Premium is lost
                                      ▲
                     WidgetDictionary.resource ── Premium.resolve(…)                OneWordWidget/
```

| Type | File | Target | Role | Mirrors |
|---|---|---|---|---|
| `Premium` (NEW) | `OneWord/Shared/Premium.swift` | app + **widget** | The rules: which ids are free, the cached flag, `allows`, `resolve`, and the one writer `set(unlocked:)` (incl. normalization) | `AppGroup.swift` / `WordSelectionStore.swift` — `nonisolated` enum over `AppGroup.defaults` |
| `PremiumViewModel` (NEW) | `OneWord/ViewModels/PremiumViewModel.swift` | app | The only StoreKit owner: product, entitlement refresh, `Transaction.updates` listener, purchase result handling, restore, UI phase | `AuthViewModel` (SDK-wrapping VM held in `@State` at the root, `OneWordApp.swift:25,34`) |
| `PremiumBar` (NEW) | `OneWord/Views/PremiumBar.swift` | app | The premium bar: price, Unlock, Restore, phase states. Used by the Dictionaries pane, the WordDetail teaser, Settings | Theme-token views (`Theme.of(scheme, doodle)`, e.g. `DictionaryPicker.swift:86,125-134`) |
| `DictionaryShelf` (MOD) | `OneWord/Views/DictionaryPicker.swift` | app | Spine lock, preview-don't-commit, "Premium" caption, commit-on-unlock | — |
| `DictionaryPicker` (MOD) | same | app | Hosts the bar under the shelf for free readers | — |
| `WordDetail` (MOD) | `OneWord/Views/WordDetail.swift` | app | Teaser gate: the single end of every full-view route | — |
| `WordListView` (MOD) | `OneWord/Views/WordListView.swift` | app | Lock mark on search hits from locked books | — |
| `SettingsView` (MOD) | `OneWord/Views/SettingsView.swift` | app | "Premium" section: status, bar, Restore | its own `section(_:_:note:)` helper (`:50`) |
| `OneWordApp` (MOD) | `OneWord/OneWordApp.swift` | app | Own + inject the view model, load on appear, reload widgets on change | `auth` at `:25,:34` |
| `WidgetDictionary` (MOD) | `OneWordWidget/WordWidget.swift` | widget | `resource` resolves through `Premium`; "· Premium" labels | — |

No new pattern is introduced: every new type copies an existing one.

---

## 4. Implementation steps

### Step 0 — App Store Connect and Xcode setup (operator; runs in parallel, blocks only release)
- **Agreements:** Paid Applications Agreement signed, banking + tax complete. Until then even
  sandbox purchases fail. **[Unverified]** current state of the account.
- **App record** for bundle id `com.hariom.swift.oneword` (`project.pbxproj:546`) if it doesn't exist.
- **In-app purchase:** type **Non-Consumable** · Product ID **`com.hariom.swift.oneword.premium`** ·
  Reference name "Premium" · price **$9.99** (US) · display name "One Word Premium" · description
  "Every dictionary, unlocked for good." · a review screenshot of the premium bar · Family Sharing
  per §9 F1.
- **The first IAP must be submitted with an app version** — attach it on the version page before
  *Submit for Review* (R1).
- **Xcode:** OneWord target → Signing & Capabilities → **+ In-App Purchase**. **[Unverified]** whether
  this writes an entitlements key on macOS; StoreKit itself runs through a system service, so the
  sandbox should need nothing more **[Inference]**.
- A **sandbox tester** Apple ID for TestFlight/sandbox runs.
- *Verify:* the product shows **Ready to Submit** in App Store Connect.

### Step 1 — The shared lock and its gate  *(foundation, reversible: nothing calls it yet)*
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
- `allows(_:unlocked:)` is **the** rule; the view model passes its observed flag so the two never
  drift (§6).
- `set(unlocked:)`: write the flag; if `!unlocked` and the stored `AppGroup.dictionaryKey` isn't in
  `free`, write `"words"` and call `WordSelectionStore.reset()` (`WordSelectionStore.swift:33`).
  Unlocking never moves the pick.
- **Widget membership:** add `Premium.swift` to the **OneWordWidget** target by explicit path. Mirror
  `WordSelectionStore.swift`'s four entries — `PBXBuildFile` (`project.pbxproj:20`),
  `PBXFileReference` with `path = OneWord/Shared/Premium.swift` (`:81`), the group child (`:142`),
  the widget Sources phase (`:320`) — with fresh IDs. The app target picks it up through the
  synchronized group.
- **NEW `tools/check_premium.sh`** — §7. Compiles `Word, WordProvider, WordSelectionStore,
  SavedWords, Premium` + an `AppGroup` shim (copy `check_capture.sh:17-26`) + the check, with
  `-default-isolation MainActor` like `check_learned.sh:191`.
- **MOD `CLAUDE.md`** — add `check_premium` to the verify loop.
- *Verify:* `xcodebuild` builds **both** targets; `bash tools/check_premium.sh` green; the four
  existing gates untouched and green (none of their compile lists names a file that now references
  `Premium` — `AppGroup.swift`, `Wordbook.swift`, `SavedWords.swift`, `WordViewModel.swift` are
  unchanged).

### Step 2 — StoreKit plumbing and local test store
**NEW `StoreKit/OneWord.storekit`** at the repo root — **outside** the synchronized `OneWord/`
folder so it isn't bundled into the app **[Inference]**. One Non-Consumable, ID
`com.hariom.swift.oneword.premium`, $9.99, same display name. Attach it: Edit Scheme → OneWord →
Run → Options → StoreKit Configuration. The scheme is shared
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

    init()                                       // seeds isUnlocked, starts the Transaction.updates listener
    func allows(_ id: String) -> Bool            // Premium.allows(id, unlocked: isUnlocked)
    func load() async                            // Product.products(for: [Premium.productID]).first, then refresh()
    func refresh() async                         // Transaction.currentEntitlements → verified, this productID,
                                                 //   revocationDate == nil → set(owned)
    func begin()                                 // phase = .purchasing (called by the view before the sheet)
    func handle(_ result: Product.PurchaseResult) async
    func failed(_ error: Error)                  // StoreKitError / Product.PurchaseError → one short line
    func restore() async                         // try await AppStore.sync(), then refresh()
    private func set(_ owned: Bool)              // always Premium.set(unlocked:); assign isUnlocked only if changed
}
```
- `handle`: `.success(.verified(t))` → `await t.finish()`, `set(true)`, `phase = .idle` ·
  `.success(.unverified)` → `failed` ("Apple couldn't verify this purchase") · `.userCancelled` →
  `.idle` · `.pending` (Ask to Buy) → `.pending`, and the listener lands it later · `@unknown default` → `.idle`.
- Listener: `Task { [weak self] in for await update in Transaction.updates { if case .verified(let t) = update { await t.finish() }; await self?.refresh() } }` —
  one recompute path for purchases from elsewhere, Ask to Buy approvals, refunds and revocations.
- No `deinit`: the object lives as long as the app (`@State` on the `App`).
  `// ponytail: app-lifetime owner — no cancel`.

**MOD `OneWord/OneWordApp.swift`** — mirror `auth` (`:25,:34`):
`@State private var premium = PremiumViewModel()`; on `RootView()` add `.environment(premium)`,
`.task { await premium.load() }` and
`.onChange(of: premium.isUnlocked) { WidgetCenter.shared.reloadAllTimelines() }` (`import WidgetKit`).
- *Verify:* build; run with the StoreKit config; in Debug → StoreKit → Manage Transactions nothing is
  owned; a temporary `print(premium.product?.displayPrice)` shows `$9.99` (remove before commit).

### Step 3 — The premium bar and the shelf lock  *(first end-to-end slice)*
**NEW `OneWord/Views/PremiumBar.swift`** — `struct PremiumBar: View { var book: Wordbook? = nil }`
- Reads `@Environment(PremiumViewModel.self)`, `@Environment(\.purchase)`, theme via
  `Theme.of(scheme, doodle)`. Monochrome: the covers stay the only coloured surface
  (`Wordbook.swift:8`) — `t.surface` card, `t.hairline` edge, `t.ink` / `t.muted` text, `t.radius(_:)`.
- Copy (draft, §9 F6): title "Unlock every dictionary", or "Unlock \(book.shortName)" when a book
  is given · subline "\(n) dictionaries, one payment, yours for good", with
  `n = Wordbook.all.filter { !Premium.free.contains($0.id) }.count` (never a hard-coded 7) ·
  primary button "Unlock — \(product.displayPrice)" · secondary "Restore Purchase".
- Tap Unlock: `Task { premium.begin(); do { await premium.handle(try await purchase(product)) } catch { premium.failed(error) } }`.
- States: product loading → disabled "Unlock" + small `ProgressView`; `.purchasing` → spinner,
  both buttons disabled; `.pending` → "Waiting for approval"; `.failed(msg)` → `msg` in `t.muted`;
  `storeUnavailable` → "The App Store isn't reachable" + Retry (`await premium.load()`); unlocked → `EmptyView()`.

**MOD `OneWord/Views/DictionaryPicker.swift`**
- `DictionaryShelf` gets `@Environment(PremiumViewModel.self) private var premium`.
- `pick(_:)` (`:152-165`): keep the swap animation for every book, but only commit an allowed one:
  `if premium.allows(book.id) { selection = book.id; onPick(book) }` — a locked book comes forward to
  be looked at, not picked.
- `.onChange(of: premium.isUnlocked)`: when it turns true and `front != selection`, commit the
  previewed book (`selection = front; onPick(.named(front))`) — they tapped Urdu, then bought.
- Caption (`:125-134`): when `!premium.allows(front)`, "\(count) entries" + "· Premium" with a small
  `lock.fill` (accessibility-hidden) instead of "· Selected for word of the day".
- Spine (`BookSpine`, `:222`): a small `lock.fill` in the spine's own ink near the foot when locked
  (pass `locked: Bool` in; `ShelfBook` forwards it).
- Accessibility (`:114-117`): locked books add `.accessibilityValue("Premium")` and
  `.accessibilityHint("Shows how to unlock")`.
- `DictionaryPicker.body` (`:173-178`): `VStack(spacing: 0) { DictionaryShelf(…); if !premium.isUnlocked { PremiumBar(book: …) } }`
  — **this is the premium bar.** Pass the front book when it's locked. That means lifting `front`
  out, or letting the bar go generic; the planner's default is generic — `PremiumBar()` — so
  `front` stays private to the shelf.
- `#Preview` (`:279-281`): add `.environment(PremiumViewModel())` — a missing `@Observable`
  environment object is a runtime crash, not a compile error.
- History gets the lock and the preview for free (`HistoryView.swift:184`) and shows no bar:
  its sheet stays a picker, and the caption says "Premium".
- *Verify (manual, StoreKit config):* locked spines, preview-without-commit (Home keeps English),
  Unlock → sheet → bought → locks gone, previewed book becomes the pick, widget redraws.

### Step 4 — Widget gate
**MOD `OneWordWidget/WordWidget.swift`**
- `resource` (`:36-38`) → `Premium.resolve(self == .followApp ? AppGroup.dictionaryID : rawValue)`.
  This is the widget's single chokepoint: `WordTimelineProvider.provider(for:)` (`:19-21`) and
  `snapshot`/`timeline` all route through it; `placeholder` uses `.words`, which is free.
- `caseDisplayRepresentations` (`:22-32`): the seven premium cases become `"Emotions · Premium"`, etc.
  **Keep them string literals** — AppIntents extracts these at build time and rejects computed
  values **[Inference]**. `// ponytail: mirrors Premium.free by hand — a literal is all AppIntents accepts`.
- Raw values are untouched — stored widget configurations survive (`ARCHITECTURE.md`: "A stored raw
  value is forever").
- *Verify:* while locked, Edit Widget → "Urdu · Premium" → the widget shows Everyday English;
  buy → it redraws to Urdu (Step 2's `onChange` reload).

### Step 5 — Search teaser
**MOD `OneWord/Views/WordDetail.swift`** — the single end of every full-view route (`:119-122`), so
one gate covers search hits, related words, Learned and Profile rows:
- `@Environment(PremiumViewModel.self) private var premium`; `private var locked: Bool { !premium.allows(shelfID) }` (`shelfID` at `:232`).
- In `page` (`:52`): keep the headword; replace everything below it — definition, Hindi, example,
  related — with `PremiumBar(book: Wordbook.named(shelfID))` when `locked`. **[Unverified]** exact
  subview boundaries between `:56` and `:110` — wrap the entry body, not the ZStack transition.
- `.task(id: shelfID)` (`:118`): `guard !locked else { return }` — don't build a related index for a locked book.
- The learned-recording `onChange(…, initial: true)` after `:122`: skip when `locked` — a teaser isn't a word learned.
- Header (`:48`): `.paneHeader(back: true) { if !locked { WordActions(word: word) } }` — **bookmarking a
  locked word would copy its full entry into the free Bookmarks pane.**

**MOD `OneWord/Views/WordListView.swift`**
- `shelfMark(_:_:)` (`:144-153`): add a `lock.fill` when `!premium.allows(shelf)`; the accessibility
  label (`:153`) becomes "\(name), Premium".
- The everywhere copy (`:197-202`) stays true — search still spans every book.
- *Verify:* search a word that only Urdu has → one locked hit → opens to headword + bar; no
  definition, no related words, no bookmark button, Learned count unchanged.

### Step 6 — Settings
**MOD `OneWord/Views/SettingsView.swift`** — a `section("Premium", t, note: …)` at the top of the
sections `VStack` (`:49`), using the file's own `section`/`card`/`row` helpers:
- Locked: `PremiumBar()` (it carries Restore).
- Unlocked: one row, "All dictionaries unlocked", with no button. Restore isn't needed on a device
  that already owns it.
- *Verify:* delete the transaction in the StoreKit manager → Settings shows the bar → Restore
  Purchase re-grants (with the local config, re-buying is the practical test; `AppStore.sync()`
  is exercised for real in sandbox/TestFlight).

### Step 7 — Refund, revocation, Ask to Buy *(verification of Step 2's listener)*
No new code. The recipe is in §11. The one place to fix if something fails is `refresh()`.

### Step 8 — Docs (00_Context is kept current)
- `Docs/00_Context/REPO_MAP.md`: `StoreKit/`, `Shared/Premium.swift`, `ViewModels/PremiumViewModel.swift`,
  `Views/PremiumBar.swift`.
- `Docs/00_Context/ARCHITECTURE.md`: a short "Premium — where the lock lives" section — the rule in
  `Premium`, the only writer `set(unlocked:)`, the widget's chokepoint, the WordDetail teaser gate,
  "never gate `WordProvider`".
- `CLAUDE.md` verify loop (done in Step 1).

---

## 5. Data & persistence

| Key (App Group) | Type | Writer | Readers | Note |
|---|---|---|---|---|
| `premiumUnlocked` (NEW) | Bool | `Premium.set(unlocked:)` only | `Premium.isUnlocked` → widget via `resolve`; the view model's seed | Absent = locked; `bool(forKey:)`'s false-when-missing is the right default here (unlike `showHindi`, `AppGroup.swift:44-46`) |
| `dictionaryID` | String | the shelf (`DictionaryPicker.swift:174`) **and now** `Premium.set(unlocked: false)` | 5 raw `@AppStorage` readers + `AppGroup.dictionaryID` | Normalized to `"words"` when Premium is lost |
| `wordOffset`, `pinnedTerm` | Int, String? | unchanged + normalization | as today | Reset only when the pick moves |

- **No migration:** one new key, absent = locked.
- **Forever values:** the product ID and the `premiumUnlocked` key name.
- StoreKit, not the cache, is the truth. The cache is a mirror the widget can read off-main.
  **Known ceiling:** a plist the user can edit (R4).

---

## 6. Concurrency, state & memory

- **Isolation map.** `PremiumViewModel` — MainActor by the target default (same as `WordViewModel.swift:9`).
  `Premium` — **explicitly `nonisolated`** (the widget's `timeline(for:in:)` calls `resolve` off-main);
  its callees `AppGroup` and `WordSelectionStore` are already `nonisolated` (`AppGroup.swift:14`,
  `WordSelectionStore.swift:15-33`). The views are MainActor.
- **Sendable / hops.** `Product`, `Transaction`, `VerificationResult`, `Product.PurchaseResult` are
  `Sendable`. `await purchase(product)` and `await t.finish()` suspend without blocking the main
  actor. `for await` over `Transaction.currentEntitlements` / `.updates` runs on the main actor —
  low frequency, fine.
- **Tasks.** The listener is an unstructured `Task` started in `init`, living as long as the app.
  `load()` runs from `.task` on the root view: cancelled with the window, re-run for a new window,
  idempotent. The purchase is an unstructured `Task` from the button; if the view goes, the system
  sheet still owns the outcome and the listener catches it.
- **Retain cycles.** The listener captures `[weak self]` and calls `self?.refresh()` per update, so it
  never holds the view model. The purchase `Task` holds `premium` strongly for seconds only — fine.
  No delegates, no Combine.
- **Observation.** Views must read `premium.isUnlocked` / `premium.allows(_:)` — **never
  `Premium.isUnlocked`**, which is a `UserDefaults` read Observation can't see; a view reading it
  would draw right once and then miss the purchase. Only the widget and `Premium` itself read the cache.
- **Ordering at launch.** The view model seeds from the cache synchronously (no flash of "locked" for
  owners), then `refresh()` corrects it. A refund while the app was closed shows the premium book until
  `refresh()` lands — ≈ one run loop of `currentEntitlements`, which works offline from the device's
  transaction store **[Inference]**.

---

## 7. Test plan

**`tools/check_premium.sh`** — the project's test style: real sources, a scratch-suite `AppGroup`
shim, `check(_:_:)` lines, `fatalError` on failure.

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

- **Hard to test here:** everything in `PremiumViewModel` that touches StoreKit. The project has no
  XCTest target, and `SKTestSession` needs one. The seam that would fix it is a test target running
  `SKTestSession` against `OneWord.storekit` — deliberately out of scope. Until then it's the manual
  script in §11, run against the StoreKit config.
- Kept small on purpose: the view model's own logic is `handle`'s switch plus `set` — everything
  stateful it does goes through `Premium.set`, which **is** covered.

---

## 8. Accessibility, localization & project mechanics

- **VoiceOver:** locked spines "Dictionary of Urdu, Premium", hint "Shows how to unlock"; search hits
  "…, Premium"; lock glyphs next to text that already says it are `accessibilityHidden`. The bar's
  primary button reads "Unlock every dictionary, \(displayPrice)". Standard `Button`s give keyboard focus.
- **Reduce Motion:** the locked preview follows the shelf's existing `reduceMotion` path (`DictionaryPicker.swift:156`).
- **Localization:** the app uses literal `Text` strings (no String Catalog) — keep that. **Never
  format a price**; `displayPrice` is already localized per storefront.
- **Target membership:** `Premium.swift` → widget by explicit pbxproj path (Step 1). Everything else
  new is app-only and joins through the synchronized group. `OneWord.storekit` belongs to no target.
- **Scheme:** StoreKit config on the shared `OneWord.xcscheme` Run action; the widget scheme doesn't need it.
- **Capabilities:** + In-App Purchase on the app target (Step 0). No Info.plist keys.
- **Previews:** every `#Preview` that renders `DictionaryShelf`, `WordDetail`, `WordListView`,
  `SettingsView` or `PremiumBar` needs `.environment(PremiumViewModel())` — grep `#Preview` in those files.
- **Gates:** new `check_premium.sh`; the existing four unchanged; `CLAUDE.md` lists five.

---

## 9. Forks (operator)

| | Fork | Default | The other branch wins when… |
|---|---|---|---|
| F1 | **Family Sharing** on the IAP | **Off** at launch | Reviews or support ask for it. Apple doesn't let you switch it off again once on, so Off is the reversible start |
| F2 | **India price** | Apple's auto-equalized price for the $9.99 tier | After ~30 days, India's conversion lags other storefronts — the scout's Hindi-bridge audience is price-sensitive; set a manual India price |
| F3 | **Paywall ships in the first store release** | Yes — no grandfathering code | A free build reaches the store first. Then add a grant for `AppTransaction.shared`'s `originalAppVersion` < the paywall build |
| F4 | **Widget honesty** | "· Premium" labels only | Support mail says the widget "doesn't change". Then add a one-line "Unlock in One Word" to `WordEntry` / `WordWidgetView` |
| F5 | **Bookmarks** free (D6) | Free | You want Bookmarks behind Premium — remove `SavedWords.resource` from `Premium.free`; the gate covers the rest |
| F6 | **Bar copy and placement** | §4 Step 3 draft, bar under the shelf, Settings first | Taste — edit strings in `PremiumBar` only |

---

## 10. Risks & exits

| | Risk | Sev · Conf | Leading indicator | Cheapest exit |
|---|---|---|---|---|
| R1 | IAP not attached to the first app version → purchases fail in production | High · High | IAP still "Ready to Submit" after launch; `products(for:)` empty in prod | Attach it on the version page before Submit for Review (Step 0) |
| R2 | `Premium.swift` missing from the widget target | Med · Med | Widget build: "cannot find 'Premium' in scope" | Mirror `WordSelectionStore.swift`'s four pbxproj entries |
| R3 | Product never loads in dev | Med · Med | Bar stuck on Retry | StoreKit config attached to the scheme; product ID lives only in `Premium.productID` |
| R4 | Cache is a user-editable plist; a refund while the app is closed leaves the widget on a premium book until the next launch | Low · High (exists by design) | — | If piracy shows up: the widget checks `Transaction.currentEntitlements` itself **[Unverified]** in a macOS widget extension |
| R5 | `@Environment(PremiumViewModel.self)` read with nothing injected → crash | Med · Med | Crash in a preview or a sheet | Inject at the root (Step 2); fix previews (§8). Sheets inherit the environment (History's sheet already reads `\.doodle`) |
| R6 | Computed AppIntents display strings fail metadata extraction | Low · Med | Build error from the AppIntents metadata processor | Literals (Step 4) |
| R7 | **Outside this plan, same release:** Google Sign-In likely needs Sign in with Apple beside it (Guideline 4.8), and account creation needs in-app deletion (5.1.1(v)) | High · Med **[Unverified]** — `SignInView` not read | Rejection | Check before submission; separate plan |
| R8 | Teaser leak through Bookmarks or Learned | Med · Med | A locked word appears in Bookmarks or Learned | The `WordDetail` gate hides actions and skips recording (Step 5) |

---

## 11. Sequencing & verification

- [ ] **0** App Store Connect + capability *(operator, parallel)*
- [ ] **1** `Premium.swift` + widget membership + `check_premium.sh` + `CLAUDE.md` — *first reversible move*
- [ ] **2** `OneWord.storekit` + scheme + `PremiumViewModel` + root injection — unblocks 3–6
- [ ] **3** `PremiumBar` + shelf lock/preview + bar in the Dictionaries pane — *first end-to-end slice*
- [ ] **4** Widget gate + labels
- [ ] **5** WordDetail teaser + search lock marks
- [ ] **6** Settings section
- [ ] **7** Refund / revocation / Ask to Buy verification
- [ ] **8** REPO_MAP + ARCHITECTURE

**Gates**
```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```
```bash
for s in check_words check_related check_learned check_capture check_premium; do bash tools/$s.sh; done
```

**Manual script** (Xcode run with `OneWord.storekit`; Debug → StoreKit → Manage Transactions):
1. Delete all transactions → relaunch. Home, History and the widget show Everyday English. Seven
   locked spines; the bar shows **$9.99**.
2. Tap the Urdu spine → it comes forward, caption "2,435 entries · Premium". Home still English.
3. Search a word only Urdu has → locked hit → headword + bar only; Learned count unchanged; no bookmark button.
4. Edit Widget → "Urdu · Premium" → the widget shows English.
5. Unlock → buy → bar and locks gone; Urdu becomes the pick; Home shows Urdu; the widget redraws to Urdu.
6. Manage Transactions → **Refund** → back to English everywhere; the widget follows.
7. Enable **Ask to Buy** in the config → Unlock → "Waiting for approval" → approve in the manager →
   unlocks without a relaunch.
8. Config → **Fail Transactions** (e.g. `purchase`) → the bar shows the one-line error, no unlock.
9. Config storefront **India** → the bar shows ₹.
10. Sandbox/TestFlight once before release: buy on one Mac → **Restore Purchase** on another.

---

## 12. Open questions & assumptions

- **[Inference]** The app isn't on the Mac App Store yet (1.0, build 1, no release trail) → no
  grandfathering. *Resolves:* App Store Connect's app record / TestFlight history. Flips F3.
- **[Unverified]** Adding the In-App Purchase capability writes no entitlements key on macOS.
  *Resolves:* `git diff OneWord/OneWord.entitlements` after Step 0.
- **[Unverified]** `OneWord.storekit` outside `OneWord/` stays out of the app bundle.
  *Resolves:* inspect `OneWord.app/Contents/Resources` after a build.
- **[Unverified]** `WordDetail.page`'s subview boundaries (`:56-:110`) — the teaser wraps the entry
  body only. *Resolves:* read the span when building Step 5.
- **[Inference]** AppIntents requires literal `caseDisplayRepresentations`. *Resolves:* the Step 4 build.
- **[Unverified]** StoreKit's `Transaction` APIs work inside a macOS widget extension (only matters
  for R4's exit). *Resolves:* a spike, only if R4 bites.
- **[Assumption]** Paid Applications Agreement, banking and tax are, or will be, complete before
  sandbox testing. *Resolves:* App Store Connect → Business.
