# Premium — plan audit

**Audited:** [PREMIUM_PLAN.md](../PREMIUM_PLAN.md) (501 lines, written 2026-09-21, unchanged on disk).
**Mode:** inline `/plan-audit`, re-grounded against `main` at `ecdcf9c`. **Audited by the plan's author** —
every citation was re-opened rather than trusted, and the findings below are the ones the code
contradicted or the plan missed.

### Stack as re-verified

| | Plan claimed | Re-verified | Match |
|---|---|---|---|
| Min target | macOS 14.0 (`pbxproj:360`) | 14.0. The **app** has no override and inherits it from the project configs (`pbxproj:454,512`); `:360` is the **widget's** block | ✔ substance, citation points at the widget |
| Default isolation | MainActor (`:367`) | MainActor in both targets: widget `:367,:394`, app `:550,:587` | ✔ |
| Language mode | Swift 5 (`:369`) | Swift 5 in both targets (`:369,:396,:553,:590`) | ✔ |
| Approachable concurrency | "approachable concurrency" | **App only** (`:549,:586`); the widget block doesn't set it | ~ harmless for a `nonisolated` pure-Foundation file |
| `Shared/` → app | synchronized group | The group excepts only `Info.plist` (`pbxproj:85-93`) → `Premium.swift` auto-joins the app | ✔ |
| `Shared/` → widget | 4 explicit entries mirroring `WordSelectionStore` | `:20,:81,:142`, and `:320` sits in Sources phase `442CD88A…`, which is the widget's | ✔ |
| Tests | none; `tools/check_*.sh` | as claimed | ✔ |
| SPM | Firebase + GoogleSignIn | products: `FirebaseAuth`, `FirebaseCore`, `GoogleSignIn` only — **no `FirebaseAnalytics`** (`pbxproj:650-660`) | ✔ |

**Opened for this audit:** `WordListView.swift:52-153` · `WordListViewModel.swift:25-27,56-60,78-85` ·
`WordDetail.swift:28-48,52,113-124,148-175,224-242,276-317` · `SavedWords.swift:7-45,62-96,111` ·
`WordCapture.swift:60,78-110` · `Theme.swift:105-155` · `PaneHeader.swift:25-34` · `RootView.swift:84-94,126-128,140-152` ·
`SettingsView.swift:31,50-51,134` · `ProfileViewModel.swift:20,26` · `ProfileView.swift:38,66,201-202` ·
`SignInView.swift:40-83` · `AuthViewModel.swift:5-31,53,157` · `RefreshWordIntent.swift:1-20` · `WordEntry.swift:10-12` ·
`WordWidgetView.swift` (grep) · `HomeView.swift:51` · `HistoryView.swift:56` · `tools/check_capture.sh:13-30,112-118` ·
`project.pbxproj` as above.

---

## Verdict — **Fix blockers first** · confidence medium-high

The architecture holds up under re-grounding. There is one shared, `nonisolated` rule file that
the widget also reads. There is one lock at the shelf, the pick's only writer. The one
widget-side chokepoint is real. `WordProvider` is correctly left alone. The membership recipe,
the isolation map and the claim that the existing gates stay untouched all check out against the
project file. **One core step is missing:** the plan gates *opening* a locked word but not the
**search result row**, which already prints the Hindi gloss. For the Urdu dictionary (the
premium anchor), that gloss *is* the entry. The fix is one condition in one function. Two majors
are product gaps the plan didn't see, not code defects, and they need the operator's call.

---

## Blocking findings

### B1 — Search rows give the locked content away before anything is opened
- **Where in the plan:** §1 D5 ("opening one shows the premium bar, never the definition"), §2 done-when, §4 Step 5.
- **What's wrong:** A search hit's row renders `hit.word.partOfSpeech` and, when `showHindi` is on (the
  default — `AppGroup.swift:46`), **`hit.word.hindi`**, right in the result list
  (`WordListView.swift:118`, `:123-124`, inside `row(_:_:mark:scale:)` at `:108`). The plan's Step 5
  only adds a lock beside the book name (`shelfMark`, `:144`) and gates `WordDetail`. For a Hindi
  reader searching Urdu, the row *is* the translation — the operator's choice ("nobody can read
  locked words", D5) is not met, and the premium anchor leaks through the free tier.
- **Evidence:** `WordListView.swift:123-124` — `if showHindi { Text(hit.word.hindi) … }`, no shelf condition.
- **Fix:** Add `@Environment(PremiumViewModel.self) private var premium` to `WordListView`. In
  `row(…)`, gate the gloss on the hit's shelf — `if showHindi && premium.allows(hit.shelf)` at `:123`.
  Part of speech (`:118`) is grammar rather than meaning, so it can stay. The row's VoiceOver text
  follows the visible text, so no extra accessibility work is needed. Add to Step 5's verify:
  "search a word only Urdu has → the row shows the term, its part of speech and a lock — no Hindi."
  The Bookmarks pane reuses this row pinned to `.saved`, which is free, so it's unaffected.
- **Why a blocker:** a core step for a decision the operator made explicitly is missing. As
  written, the plan would ship a paywall that the search box bypasses.

---

## Major findings

### M1 — Profile's German fluency goal depends on a dictionary the plan locks
- **Where:** not in the plan (missing case). §2 lists Home, History, the widget, search and Settings, not Profile.
- **What's wrong:** Settings has a `fluencyGoal` switch (`ProfileView.swift:38`). With it on, Profile
  draws a goal (`:66`) whose progress is **words learned from the German dictionary** —
  `model.learnedGerman` (`ProfileView.swift:201-202`), counted from `Wordbook.german.id`
  (`ProfileViewModel.swift:26`). Under the plan, German is premium. A free reader who turns the goal
  on sees a target they can never move.
- **Fix (needs the operator — see Q1):** either hide the goal (and its Settings switch) while German
  is locked, show it with the premium bar as a deliberate upsell, or retarget it. Whichever is
  chosen, add a step to §4 and a check to §11.
- **Why major:** a user-visible dead feature for the free tier on day one. It won't break the build,
  and the right behavior is a product call.

### M2 — R7 is under-rated: the purchase can only be reached *after* a mandatory Google sign-in
- **Where:** §10 R7 ("High · Med **[Unverified]** — `SignInView` not read"); §2 out-of-scope.
- **What's wrong:** Now verified, and worse than R7 assumed:
  - **Sign-in is mandatory.** Without it the app shows only `SignInView`: `RootView.swift:88-93`,
    `AuthViewModel.swift:5` ("Signing in is how you get into the app at all").
  - **Google is the only provider** (`SignInView.swift:83`). The skip button is labelled
    `(Debug)` (`:54`).
  - **There's no in-app account deletion** (grep: none).

  So the premium bar is unreachable without registering. **[Inference]** App Review commonly
  rejects apps that require registration before buying a non-account-based in-app purchase
  (Guideline 5.1.1). Separately, 4.8 (login services) and 5.1.1(v) (account deletion) are likely
  to be raised against the same submission. None of this stops the paywall from being built and
  tested, but it may stop the release that carries it.
- **Fix:** Re-rate R7 to **High · High** on the code facts, and **[Inference]** on the review outcome.
  Add an explicit **release gate** to §11: "resolve the sign-in gate before submitting the IAP
  build". Raise **Q2**. The work itself belongs in a separate plan — likely a no-login path, or
  Sign in with Apple plus account deletion — rather than in this one.
- **Why major:** risk honesty. The plan treats a probable review blocker for its own release as an
  unverified footnote.

---

## Minor findings & nits

1. **The premium bar isn't attached to the pane's ground** (§4 Step 3). The plan puts the bar in a
   `VStack` *under* `DictionaryShelf`, but the pane's ground is the shelf's own `.paneBackground(t)`
   (`DictionaryPicker.swift:139` → `background { PaneGround }`, `Theme.swift:153-155`).
   - **The seam is [Unverified].** The strip around the bar would paint on whatever is behind the
     detail column; RootView's shell wasn't read, so whether that shows a seam is unconfirmed.
   - **The idiom mismatch is certain.** The project attaches strips with
     `.safeAreaInset(edge:spacing: 0)` (`RootView.swift:146`; `PaneHeader.swift:27`).
   - **Fix:** `DictionaryShelf(…).safeAreaInset(edge: .bottom, spacing: 0) { if !premium.isUnlocked { PremiumBar() } }`.
     `PaneGround`'s `.ignoresSafeArea()` (`Theme.swift:139`) then paints under the bar, and the
     shelf's `GeometryReader` sizes to the remaining height. Check by eye in a light theme and in Midnight.
2. **`load()` makes the entitlement check wait on the network** (§4 Step 2: "products(for:).first,
   then refresh()"). The product fetch is a network call; `refresh()` reads the local transaction
   store. As written, a slow or failing fetch delays or (with an early `return` in a `catch`) skips
   the refresh. That in turn delays normalization and a new Mac's unlock.
   **Fix:** call `await refresh()` first and independently, then fetch the product.
3. **The gate-script shim doesn't match the compile flag** (§4 Step 1: "copy `check_capture.sh:17-26`",
   "`-default-isolation MainActor` like `check_learned.sh:191`"). `check_capture`'s shim is a plain
   `enum AppGroup` (`check_capture.sh:21`), compiled *without* that flag (`:115`). Under the flag it
   becomes MainActor-isolated, and `nonisolated enum Premium` then reads `AppGroup.defaults` /
   `.dictionaryKey` across isolation — **[Inference]** warnings or errors depending on whether the SDK
   marks `UserDefaults` Sendable. **Fix:** copy `check_learned.sh:20-31`'s **`nonisolated enum AppGroup`**
   shim, which was written for that flag.
4. **Refresh re-entrancy** (§4 Step 2, §6). `refresh()` suspends while iterating
   `currentEntitlements`, so two refreshes can interleave, and a refresh whose snapshot predates a
   purchase can land *after* `handle()` has called `set(true)`. That flips the app back to locked,
   and — through `Premium.set(unlocked: false)` — moves the reader's pick back to English.
   **[Inference]** the window is small. **Fix:** after a verified purchase call `refresh()` instead of
   `set(true)`, and only apply the latest refresh — a generation counter is enough.
5. **`.pending` never clears if Ask to Buy is declined** — no transaction arrives, so the bar says
   "Waiting for approval" until relaunch. **Fix:** reset `.pending` → `.idle` in `refresh()`.
6. **`restore()` doesn't say what it does on failure.** `AppStore.sync()` throws on cancel or when
   offline. **Fix:** map to `failed(_:)`, ignoring `StoreKitError.userCancelled`.
7. `private var updates: Task<Void, Never>?` in an `@Observable` class should be `@ObservationIgnored`.
8. **Citation nits:**
   - The stack table cites the widget's build block for app settings (see the table above).
   - SettingsView's sections `VStack` is at `:50`, not `:49`, and `:51` is a *call* to `section(…)`,
     not its definition (the helpers are generic `func`s the plan didn't locate).
   - D10 says "five views read the raw `dictionaryID` via `@AppStorage`" but its list includes
     `Wordbook.swift:62`, a static reader — four views plus one static.
9. **Step 3 contradicts itself.** Its snippet passes `PremiumBar(book: …)`; its prose then settles on
   the generic `PremiumBar()`. Pick one; generic is the simpler one, since `front` stays private.
10. **§11 step 2 expects "2,435 entries"** — a number from the scout brief, not from the code. Compare
    against the shelf's own `entryCount` instead.

---

## Coverage gaps

- **Search-row content** (B1) — the plan's leak analysis stopped at `WordDetail`.
- **Profile** as a surface that consumes a premium dictionary (M1).
- **The release gate for App Review** (M2) — the plan has setup steps for App Store Connect but none
  for review readiness.
- **No automated check for any view-level gate.** The shelf lock, the row gloss and the `WordDetail`
  teaser are all verified by hand only. That's consistent with the project having no test target, but
  §7 should list them as manual checks by name. Today only the `WordDetail` one is in §11.

---

## What the plan got right

- **The chokepoints are real.**
  - `WidgetDictionary.resource` is the widget's only dictionary read: the refresh intent only
    advances the offset (`RefreshWordIntent.swift:16`), and `WordEntry` carries no book name (`:10-12`).
  - The shelf is the app pick's only writer (`DictionaryPicker.swift:174`).
- **Not gating `WordProvider`** is right — it feeds search, entry counts and warm-up.
- **The bookmark leak is correctly identified and closed.** A bookmark stores the full `Word`
  (`SavedWords.swift:18-19`), and the only bookmark writer is `WordActions`' toggle
  (`WordDetail.swift:285`). Its other two call sites (`HomeView:51`, `HistoryView:56`) only ever show
  allowed books, so hiding it on the teaser is sufficient.
- **No browse leak.** Browsing is only ever pinned to Bookmarks (`RootView.swift:126`).
- **No search-by-meaning leak.** Search matches only the folded *term* (`WordListViewModel.swift:78`),
  so typing a Hindi or English meaning can't surface locked words.
- **The environment-crash risk (R5) doesn't reach the capture HUD** — it hosts `CaptureHUDView`, which
  the plan doesn't touch (`WordCapture.swift:97`).
- **No `FirebaseAnalytics`**, so there's no automatic in-app-purchase event logging and no extra
  privacy-label work.
- **"Always write through, only move a premium pick"** keeps a free reader's widget offset intact
  across launches — the easy version would have reset it on every launch.
- **Correct platform facts:**
  - non-consumable vs subscription;
  - `@Environment(\.purchase)` on macOS 14;
  - literal AppIntents strings;
  - the first IAP must ride with an app version;
  - Family Sharing can't be switched off once it's on.
- **The four existing gates really do stay untouched** — none of their compile lists names a file the
  plan changes.

---

## Operator questions

- **Q1 (from M1):** Profile's German fluency goal — once German is premium, should it **hide** (goal
  and switch) for free readers, **stay as an upsell** with the premium bar, or be **retargeted** to
  Everyday English?
- **Q2 (from M2):** Does mandatory Google sign-in stay for the release that introduces Premium? If
  yes, a separate plan needs to clear App Review first: a no-login path, or Sign in with Apple plus
  in-app account deletion. If sign-in becomes optional, the premium bar must work signed-out too —
  StoreKit ties the purchase to the Apple ID, not the Google account, so nothing in this plan changes.

---

## What would change the verdict

- **→ Ready to build:** B1's one-line gate is added to Step 5, and Q1 is answered so M1 becomes a
  step. The minors can be folded in during the build.
- **→ Needs rework:** if One Word will ship **outside the Mac App Store** (Developer ID / notarized
  download). StoreKit in-app purchases only work for App Store builds, so the payment approach itself
  would have to change. The plan infers App Store distribution (§12) but no fact in the repo confirms it.
- M2 does not change the verdict on the *plan*. It changes whether the *release* can pass review.
