# Related Words — Implementation Plan

Companion to [RELATED_WORDS_BRAINSTORM.md](RELATED_WORDS_BRAINSTORM.md), which decided the
approach (option 4: bag-of-embeddings centroid over term + definition, ranked inside the
open dictionary). This descends to the file level.

> **Revision 3.** r2 fixed the two blocking concurrency defects from the
> [first audit](RELATED_WORDS_PLAN_AUDIT.md) and resolved fork 9.1 toward the **full browsable
> chain** — which made the change *smaller*, not bigger: the index moved out of `WordViewModel`
> into an environment store, so `WordViewModel` is no longer touched at all. r3 then applies the
> [second audit](RELATED_WORDS_PLAN_AUDIT_R2.md): cooperative cancellation (N1) and corrected
> citations (N2, N3).
>
> Every code shape below was type-checked under the project's real build flags in both Swift 5
> and Swift 6 language modes, and the environment-propagation assumption was verified by
> running it (§5).

## 1. Grounding

**Files read:** `OneWord/Shared/Word.swift` (1–19), `Shared/WordProvider.swift` (1–107),
`Shared/SavedWords.swift` (1–140), `Shared/WordStore.swift`, `Shared/AppGroup.swift`,
`Shared/Theme.swift`, `WordDetail.swift` (1–120), `WordView.swift`, `WordViewModel.swift`,
`WordListView.swift`, `WordListViewModel.swift`, `Wordbook.swift`, `OneWordApp.swift`,
`ARCHITECTURE.md`, `OneWord.xcodeproj/project.pbxproj`, `tools/check_words.sh`.

**Detected stack** — each with the evidence that proves it:

| | Detected | Evidence |
|---|---|---|
| Platform | **macOS, min 14.0** (not iOS) | `SDKROOT = macosx`, `MACOSX_DEPLOYMENT_TARGET = 14.0` |
| Build system | `.xcodeproj`, 2 targets (app + widget extension) | `productType` = `application`, `app-extension` |
| Target membership | app = **synchronized root group**; widget = **explicit 11-file list** | `PBXFileSystemSynchronizedRootGroup` path `OneWord`; widget `PBXSourcesBuildPhase` |
| UI | SwiftUI | `@main struct OneWordApp: App`, `OneWordApp.swift:11` |
| Architecture | MVVM, `@Observable` | `WordViewModel.swift:14`, `WordListViewModel.swift:13` (exemplars to mirror) |
| Language mode | **Swift 5** (not Swift 6 strict) | `SWIFT_VERSION = 5.0` |
| Default isolation | **`MainActor`** | `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |
| Async isolation | **`SWIFT_APPROACHABLE_CONCURRENCY = YES`** — load-bearing, see §5 | `project.pbxproj` |
| Persistence | `UserDefaults` via App Group; JSON in bundle | `AppGroup.swift:22`, `WordProvider.swift:72` |
| Testing | **No test target.** Standalone `swiftc` check scripts | only 2 `productType`s; `tools/check_words.sh` |
| Dependencies | none (no SPM/CocoaPods) | no `Package.swift`, no `Podfile` |

Three consequences that shape everything below:

1. **Getting off the main actor here is not obvious.** Under this project's settings, *two*
   of the four ways to do background work silently stay on the main thread. §5 has the
   measurements. This is the single most dangerous part of the change.
2. **App-only is free.** A new `.swift` file under `OneWord/` is auto-compiled into the app
   by the synchronized group and reaches the widget only if someone hand-adds a
   `PBXBuildFile` entry. So there is **no target-membership step** — the usual `.xcodeproj`
   footgun is inverted here. Keep the file out of `Shared/`, whose headers all declare
   "member of app + widget targets".
3. **No XCTest/Swift Testing exists.** The test plan follows `tools/check_words.sh` — a
   standalone binary compiled from the real sources — not a framework this project doesn't have.

`NLEmbedding.wordEmbedding(for:)` is macOS 10.15+, so min 14.0 needs **no `@available` gating**.

## 2. Scope & outcome

**Done when:** below the "Used as" footer of *any* word detail screen, a box titled *In the
same vein* shows three related words from the open dictionary — each with its part of speech,
definition, and example — and each navigates to that word's own detail screen, **which shows
its own box**. The chain the brainstorm promises (warm → scorching → sultry) works at any depth.

**Scope shape:** single change. Three source files + one new file + one check script; lands
and reverts together.

**In scope:** the home screen and the browse list's detail screen (both reached through
`WordDetail`), all nine dictionaries including runtime-captured "My Words", the index +
ranking, one check script.

**Out of scope:** the widget (memory ceiling — see brainstorm §5); cross-dictionary results;
any disk cache.

## 3. Architecture fit

New code lands in the **app target only**: a `nonisolated` pure-value model type (mirrors
`WordProvider.swift:14`) plus an `@Observable` store injected through the environment
(mirrors the `@Observable` idiom at `WordViewModel.swift:14`).

| Type | File | Isolation | Responsibility |
|---|---|---|---|
| `RelatedWordsIndex` | **NEW** `OneWord/RelatedWords.swift` | `nonisolated` | Builds centroids for a `[Word]`; answers `nearest(to:limit:)`. No UI, no app state. |
| `RelatedWordsStore` | **NEW** same file | `@MainActor` (default) | Owns the index for the open dictionary, its build `Task`, and cancellation. Injected via `.environment`. |
| `WordDetail` | MODIFIED `OneWord/WordDetail.swift` | view | Reads the store from `@Environment`; renders the box; drives the load. |
| `OneWordApp` | MODIFIED `OneWord/OneWordApp.swift` | view | Owns the store instance and injects it. |
| `WordView`, `WordListView` | MODIFIED (previews only) | view | `#Preview` needs `.environment(RelatedWordsStore())`; without it `WordView`'s traps on open, `WordListView`'s on first click. |

**`WordViewModel` is not modified.** This is the payoff from resolving fork 9.1 toward the
full chain: because the box has to appear on *every* `WordDetail` — including ones pushed
from inside another box — the data cannot be a parameter threaded from one parent. Putting it
in the environment means each `WordDetail` serves itself, so the view model stays out of it
entirely, and the recursion terminates naturally (the user stops tapping).

`WordDetail` is used at exactly two call sites — `WordView.swift:19` and
`WordListView.swift:27` — plus, after this change, recursively from its own box. All three
are served by the same environment store.

## 4. Implementation steps

Ordered so the riskiest piece (the pure model type, verifiable from the command line without
ever launching the app) lands first, and the check script proves it before any UI exists.

### Step 1 — `RelatedWordsIndex` (NEW `OneWord/RelatedWords.swift`)

The whole algorithm, as a pure value type with no UI and no app state.

```swift
nonisolated struct RelatedWordsIndex {
    /// nil when NLEmbedding is unavailable, or when the build was cancelled part-way.
    init?(words: [Word])
    func nearest(to word: Word, limit: Int = 3) -> [Word]
}
```

- `init?` loads `NLEmbedding.wordEmbedding(for: .english)` once and returns `nil` if it hands
  back `nil`. It builds, for each `Word`, a normalised 300-dim centroid: average the word
  vectors of the tokens of `term + " " + definition`, skipping tokens ≤3 chars and a small
  stopword set. Entries with no vectorisable token are dropped from the index — measured at 2
  of 12,000 in `words.json`.
- **`vector(for:)` returns `[Double]`** (verified). Accumulate in `Double`, then **store
  `[Float]`**: 12,000 × 300 × 4 bytes ≈ 14.4MB, where `Double` would be ~29MB. Every other
  book is under 2MB.
- **`nearest(to:)` computes the query's centroid on demand from the passed `Word` — never by
  looking the word up in the index.** This is load-bearing, not a style preference:
  `SavedWords.pinned` takes the day *whatever dictionary is selected* (`WordProvider.swift:44`),
  so today's word may be absent from the index being searched. Return `[]` when no centroid
  can be built — which is also the correct, quiet behavior for a captured word stored with an
  empty definition (`SavedWords.swift:75`, when `lookUp` finds nothing) and for
  `SavedWords.placeholder`, whose em-dash term has no vector (both verified).
- Ranking is a dot product (the vectors are normalised, so that *is* cosine similarity), with
  four filters that the measurements showed are each necessary:
  1. skip the query itself;
  2. skip candidates sharing the query's first 4 characters — kills `warm` → `warmed`,
     `warmer`, `warmth`;
  3. dedupe survivors against **each other** by the same 4-char stem — kills `wistful` and
     `wistfulness` both taking a slot;
  4. drop anything below a similarity floor, so the 20-entry books return nothing rather than
     strangers. Measured good matches scored 0.73–0.87; start the floor at **0.55** and treat
     it as a tuning knob, not a truth — it wants a `ponytail:` comment naming that.
- **The build loop must check `Task.isCancelled` — cancelling the task alone does nothing.**
  Swift cancellation is cooperative, so a synchronous build loop with no check runs to
  completion even after `cancel()`; the store's `guard` then throws the result away. Measured:
  three quick dictionary switches produced three *concurrent* full builds, two of them already
  cancelled. Flicking through the nine-book picker would put several ~14MB builds in flight at
  once, each slowing the one you actually want. `Task.isCancelled` does read `true` inside the
  loop — nothing consults it. Check it periodically and return `nil`, which is exactly what the
  failable initialiser already models:
  ```swift
  for (i, word) in words.enumerated() {
      if i % 512 == 0 && Task.isCancelled { return nil }
      // …centroid…
  }
  ```
- `nonisolated` for the reason `WordProvider.swift:14` gives: it is built off the main actor,
  and the target defaults to `MainActor`. `Word` is a struct of `String` lets, so it is
  implicitly `Sendable`; `[Float]` likewise — the type crosses the `Task` boundary cleanly.

**Verify:** step 2's check script. No app launch needed.

### Step 2 — `tools/check_related.sh` + `tools/RelatedWordsCheck.swift` (NEW)

Prove the algorithm before building any UI on it. Mirrors `tools/check_words.sh` exactly —
`swiftc -O` over the real sources plus a `@main` check, run from the command line. Asserts:

- index coverage ≥99% for each of the eight bundled books (the regression that matters — a
  reworded definition can silently drop entries);
- known pairs still rank in the top three (`emotions`/`melancholy` → `wistful`;
  `startup`/`10x engineer` → one of `zero to one` / `network effect` — that one is the proof
  multi-word terms work at all, since they have no word vector);
- no two results share a 4-char stem (filter 3 above);
- the 20-entry books return `[]` under the threshold rather than strangers;
- a `Word` with an empty definition and an unknown term yields `[]`, not a crash (the
  captured-word path).

Because `RelatedWordsIndex` is explicitly `nonisolated`, it compiles identically under
`swiftc` without the project's isolation flags — the script needs no special arguments. Note
the source path differs from `check_words.sh`: this file is in `OneWord/`, not `OneWord/Shared/`.

### Step 3 — `RelatedWordsStore` (NEW, same file as step 1)

Owns the index for the open dictionary. **This shape is type-checked clean under
`-swift-version 5` and `-swift-version 6`, both with `-default-isolation MainActor` and
approachable concurrency enabled** — see §5 for why each line is the way it is.

```swift
@Observable
final class RelatedWordsStore {
    private var index: RelatedWordsIndex?
    private var builtFor: String?
    private var task: Task<Void, Never>?

    /// @concurrent, NOT a bare `nonisolated async`: under this project's
    /// SWIFT_APPROACHABLE_CONCURRENCY a nonisolated async func inherits the CALLER's
    /// actor, which would build the index on the main thread. Measured — see plan §5.
    @concurrent private nonisolated func build(_ words: [Word]) async -> RelatedWordsIndex? {
        RelatedWordsIndex(words: words)
    }

    /// Idempotent — repeat calls for the same dictionary are free. Required, because
    /// `.task`/`.onAppear` re-fire every time a pushed detail screen pops back.
    func load(_ book: Wordbook) {
        guard builtFor != book.id else { return }
        builtFor = book.id
        index = nil
        task?.cancel()
        let words = WordProvider(resource: book.id).allWords   // read ON the main actor
        task = Task { [weak self] in
            let idx = await self?.build(words)
            guard !Task.isCancelled else { return }
            self?.index = idx
        }
    }

    func related(to word: Word) -> [Word] { index?.nearest(to: word) ?? [] }
}
```

Three details that are each a fixed defect, not a preference:

- `let words = provider.allWords` is read **on the main actor** before the task starts.
  Reading it inside the background work is a main-actor isolation violation (a warning in
  Swift 5, an error in Swift 6).
- The outer `Task {}` deliberately **stays on the main actor** so touching `self` is safe;
  it is `await self?.build(words)` that hops off. Doing it the other way — background task
  hopping back in via `MainActor.run { self.… }` — trips `#SendableClosureCaptures`.
- `guard builtFor != book.id` is what stops a full rebuild every time the user navigates back
  out of a related word.

**Verify:** builds clean; the box populates after launch.

### Step 4 — the box (MODIFIED `WordDetail.swift`, `OneWordApp.swift`, + two previews)

- `OneWordApp` owns the store and injects it:
  ```swift
  @State private var relatedWords = RelatedWordsStore()
  // …
  NavigationStack { WordView() }
      .environment(relatedWords)
  ```
- `WordDetail` reads it, drives the load, and renders the box:
  ```swift
  @Environment(RelatedWordsStore.self) private var store
  @AppStorage("dictionaryID", store: AppGroup.defaults) private var dictionaryID = Wordbook.everydayEnglish.id
  // in body:
  let related = store.related(to: word)
  // …
  .task(id: dictionaryID) { store.load(Wordbook.named(dictionaryID)) }
  ```
  `.task(id:)` re-runs on dictionary change and is safe to re-fire on pop because `load` is
  idempotent. Because `related(to:)` reads the store's `index` during `body`, SwiftUI
  observation re-renders the box in when the build finishes — that *is* the fade-in, with no
  extra state.
  > `ponytail:` re-ranks once per body evaluation (~5ms at 12k words). Memoize by term if a
  > bigger dictionary ever lands.
- **Styling mirrors the existing footer** (`WordDetail.swift:105–120`) so it reads as the same
  document: `Text("In the same vein")` at `.system(size: 10, weight: .bold)`,
  `.textCase(.uppercase)`, `.tracking(1.6)`, `foregroundStyle(t.muted)`, over a
  `Rectangle().fill(t.hairline).frame(height: 1)` top overlay.
- **The label wording is deliberate.** Not "Similar words" — the ranking returns relatedness,
  not synonymy (`warm` → `dank`, "unpleasantly cool and humid"), and a synonym promise the
  data can't keep is a bug in the copy.
- Each row: `NavigationLink { WordDetail(word: w) } label: { … }`, mirroring
  `WordListView.swift:27`. Term in `.serif(20)` / `t.ink`, part of speech in
  `.system(size: 11).italic()` / `t.muted`, definition in `.system(size: 13)` /
  `t.definition`, example in `.serif(14).italic()` / `t.example` — the example being the
  "usecase" the feature exists to show. The pushed `WordDetail` reads the same environment
  store, so **it renders its own box**; that is the chain.
- **Switching dictionaries while deep in a chain is intentionally left simple:** the stacked
  screens keep their own words but re-rank against the newly-loaded index, because there is one
  store and one index. Accepted rather than overlooked — the user did just change dictionary,
  and per-screen indexes would multiply the memory cost by the stack depth.
- `if related.isEmpty { }` → the box does not render at all. One branch covers the
  unavailable-embedding case, the below-threshold small books, the captured-word-with-no-
  definition case, and the pre-build window.
- **Both `#Preview`s must inject the store** (`WordView.swift:61`, `WordListView.swift:116`):
  `.environment(RelatedWordsStore())`. They fail *differently*, which matters — fixing only the
  obviously-broken one leaves a landmine. `WordView`'s preview renders `WordDetail` directly, so
  it traps the moment the preview opens. `WordListView`'s renders a `List` whose `WordDetail`
  sits behind a `NavigationLink` (`WordListView.swift:27`), so that preview opens fine and traps
  only when you click a row.

**Verify:** launch; confirm the box on the home screen; click a related word and confirm the
pushed screen has **its own** box (the chain); go back and confirm no rebuild pause; switch
dictionaries and confirm it repopulates; press New Word and confirm an instant re-rank.

## 5. Concurrency, state & memory model

**The measured core of this change.** Under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` with
`SWIFT_APPROACHABLE_CONCURRENCY = YES`, only two of four plausible mechanisms actually leave
the main thread. Same file, compiled twice, printing `Thread.isMainThread`:

| shape | approachable concurrency **ON** (this project) | OFF |
|---|---|---|
| `nonisolated async` | **MAIN — blocks the UI** | off-main |
| `@concurrent async` | **off-main ✅** | off-main |
| `Task.detached` | **off-main ✅** | off-main |
| plain `Task {}` | **MAIN — blocks the UI** | MAIN |

The trap is row 1: `nonisolated async` is the modern idiom and the natural thing to reach for,
it matches the `nonisolated` markers already all over this codebase, and here it silently runs
the 2.4s build on the main thread **with no warning**. `tools/check_related.sh` cannot catch
it either, because it never launches the app. `@concurrent` is the fix, and the comment in
step 3 exists to stop someone "simplifying" it away later.

- **`RelatedWordsIndex`: `nonisolated`.** Pure value type, built off-main, crosses a `Task`
  boundary. `Word` (struct of `String` lets) and `[Float]` are implicitly `Sendable`.
- **`RelatedWordsStore`: `@MainActor`** by default isolation. Only `build` is `@concurrent`.
- **`NLEmbedding` is created and used entirely inside `build`** and never crosses a boundary,
  which sidesteps whether it is thread-safe — `[Unverified]`, and worth keeping that way.
- **Cancellation has two halves, and both are required.** The store's `task?.cancel()` only
  discards a *result*; the index's own `Task.isCancelled` check (Step 1) is what actually stops
  the work. Without the second half, rapid dictionary switching runs several full builds
  concurrently — measured. The `builtFor` guard is the cheaper third layer: it prevents the
  redundant build being started at all when the dictionary hasn't changed.
- **Retain cycles:** `[weak self]` on the task. No Combine `sink` and no delegate is added, so
  that is the only capture to watch.
- **Memory:** ~14.4MB resident for `words`, under 2MB for the rest. One index at a time,
  shared by every screen in the navigation stack.

## 6. Accessibility, localization & project mechanics

- **Target membership: nothing to do** — the synchronized root group picks up
  `OneWord/RelatedWords.swift` automatically. Do **not** add it to the widget's source list.
- **`NaturalLanguage`** is a system framework, auto-linked by `import`. No `Frameworks` build
  phase edit, no entitlement, no Info.plist usage string — the embedding is on-device and
  touches no protected resource.
- **Accessibility:** each row needs an `.accessibilityLabel` combining term + definition;
  without one VoiceOver reads four disconnected text runs per row.
- **Dynamic Type:** this project uses fixed `.system(size:)` / `.serif(n)` sizes throughout
  (`Theme.swift:60`), so match that and do **not** introduce a lone scaling row. A pre-existing
  gap, not this change's to fix.
- **Localization:** no `.xcstrings` in the project — strings are inline literals. "In the same
  vein" follows that convention.

## 7. Decision forks (operator-owned)

1. ~~List detail screen too?~~ **Resolved: full chain.** The box renders on every `WordDetail`
   at any depth. This is what moved the index into the environment, and it removed the
   `WordViewModel` changes r1 needed.
2. **Three results, or five?** Planned at three. Five makes the box a real detour; the code
   difference is one constant.
3. **Same part of speech only?** Not planned. It would tighten `warm` toward adjectives, but
   thins the pool badly in the 20-entry books. Cheap to add later — one predicate.
4. **Index build UX:** background fade-in, per your call, with the ceiling recorded in a
   `ponytail:` comment. The App Group cache is the upgrade if 2.4s ever becomes felt; it would
   need a content hash and My Words excluded.

## 8. Risks & exits

| Risk | Severity | Confidence | Leading indicator | Cheapest exit |
|---|---|---|---|---|
| Someone replaces `@concurrent` with `nonisolated async` — main thread blocked, no warning | **High** | High (measured) | ~2.4s beachball on first launch of the big book | Restore `@concurrent`; the comment in step 3 is the guard. No automated check can catch this |
| Unbounded navigation depth via the chain | Low | Medium | Memory growth after many hops | Each `WordDetail` is a small struct sharing one index; NavigationStack already handles the stack |
| Similarity floor mistuned — box empty on good words, or junk on the small books | Medium | Medium | Empty box on `words`, or strangers on `character` | Tune the one constant; the check script asserts both ends |
| Preview crash from the missing environment injection | Low | High | Previews trap immediately | Add `.environment(RelatedWordsStore())` — listed in step 4 |
| Relatedness ≠ synonymy (`warm` → `dank`) | Low | High (measured, inherent) | Your own reaction reading it | The honest label absorbs most of it; a hand-authored override field for a few dozen high-traffic words is the escape hatch, not a rewrite |

## 9. Sequencing & verification

1. `OneWord/RelatedWords.swift` — `RelatedWordsIndex` only. *(reversible, verifiable headless)*
2. `tools/check_related.sh` + `RelatedWordsCheck.swift` — prove the algorithm before any UI.
3. `RelatedWordsStore` — the `@concurrent` build, cancellation, idempotence.
4. `WordDetail` + `OneWordApp` + the two previews — the box, the injection, the chain.

Steps 1–2 are independently valuable: they confirm the measured coverage and ranking still
hold against the real JSON without launching anything. Step 3 is where the concurrency risk
lives and is the one to review closely. Step 4 is pure view code.

**End to end:** run `tools/check_related.sh` (expect coverage ≥99% and the known pairs
passing), then build and launch. On the home screen: the box appears below "Used as" with
three rows; clicking one navigates to that word **and that screen has its own box**; going
back is instant with no rebuild; Dictionary of Medicine repopulates with medical neighbours;
the three 20-entry books show no box at all; New Word re-ranks with no perceptible pause.

## 10. Open questions & assumptions

- `[Unverified]` No app build was run — the plan is verified by type-checking isolated
  snippets under the project's flags, not by compiling the app target.
- `[Unverified]` `NLEmbedding` thread-safety. Sidestepped by construction — the model is
  created and consumed inside one `@concurrent` function. Resolved by keeping it that way.
- `[Assumption]` The 0.55 similarity floor. Derived from measured scores (0.73–0.87 for good
  matches), not from a swept threshold. The check script's two-ended assertion is what turns
  this into a verified number.
- `[Assumption]` `-enable-upcoming-feature NonisolatedNonsendingByDefault` is the effect of
  `SWIFT_APPROACHABLE_CONCURRENCY = YES`. The measured ON/OFF contrast in §5 is the evidence;
  Xcode's build-setting expansion was not read directly.
- `[Inference]` `.task`/`.onAppear` re-fire when a pushed view pops. Documented SwiftUI
  behavior, not measured here — but the `builtFor` guard is correct either way.
- **Resolved (was `[Unverified]`): environment propagation into `NavigationStack` destinations.**
  The chain's load-bearing assumption. Verified by running it — a SwiftUI app with
  `.environment(Store())` on the `NavigationStack`, pushing via `NavigationPath`, printed
  `DESTINATION saw environment -> INJECTED-OK` from the destination. `[Inference]` remains on
  the last hop only: the probe used `.navigationDestination(for:)` while the plan uses an inline
  `NavigationLink { … }`; both render inside the stack's hierarchy.
