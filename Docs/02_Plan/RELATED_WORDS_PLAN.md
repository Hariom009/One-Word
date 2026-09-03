# Related Words — Implementation Plan

Companion to [RELATED_WORDS_BRAINSTORM.md](../01_Brainstorm/RELATED_WORDS_BRAINSTORM.md), which decided the
approach (option 4: bag-of-embeddings centroid over term + definition, ranked inside the
open dictionary). This descends to the file level.

> **Revision 3.** r2 fixed the two blocking concurrency defects from the
> [first audit](Audit/RELATED_WORDS_PLAN_AUDIT.md) and resolved fork 9.1 toward the **full browsable
> chain** — which made the change *smaller*, not bigger: the index moved out of `WordViewModel`
> into an environment store, so `WordViewModel` is no longer touched at all. r3 then applies the
> [second audit](Audit/RELATED_WORDS_PLAN_AUDIT_R2.md): cooperative cancellation (N1) and corrected
> citations (N2, N3).
>
> **Revision 4 (2026-08-24).** Applies the validated external review
> ([RELATED_WORDS_REVIEW_VALIDATION.md](../04_PR/Review/RELATED_WORDS_REVIEW_VALIDATION.md)) — six confirmed
> findings: the small-book floor claim was measured **false** (60/60 words clear 0.55), so the
> three 20-entry books now **show** their within-book results (operator ruling); My Words
> invalidates on capture (V2); the JSON decode moves off the main actor (V4); builds are
> serialized so two `NLEmbedding` instances are never live (V5); one canonical case-folded
> term identity for the filters (V6); the example row renders only when non-empty + fuller
> VoiceOver label (V3); the box animates in (V7). r4's revised store snippet is the one
> exception to the next paragraph — it was **not** re-type-checked; the checklist's build
> gates carry its verification.
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

**Out of scope:** the widget (memory ceiling — see brainstorm §5); cross-dictionary results
(operator-confirmed 2026-08-24: curated books stay pure; if the boxless 20-entry books ever
feel bad, the upgrade is a size-gated fallback that borrows from Everyday for those three
books only); any disk cache.

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
  can be built — the correct, quiet behavior for a captured word stored with an empty
  definition (`SavedWords.swift:75`, when `lookUp` finds nothing). `SavedWords.placeholder`
  needs an **explicit guard** (r4, found by the check script): its em-dash term has no vector
  but its instructional *definition* vectorises, so without the guard the teaching card finds
  "related" words for a sentence about the Services menu.
- Ranking is a dot product (the vectors are normalised, so that *is* cosine similarity), with
  four filters that the measurements showed are each necessary:
  All three term comparisons use one canonical identity —
  `folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)` — because
  captures are stored lowercased (`SavedWords.swift:91`) while `startup` carries 175
  mixed-case terms: raw equality would let indexed `KPI` surface as "related" to a captured
  `kpi` (validated V6).
  1. skip the query itself (canonical equality);
  2. skip candidates sharing the query's first 4 canonical characters — kills `warm` →
     `warmed`, `warmer`, `warmth`;
  3. dedupe survivors against **each other** by the same 4-char canonical stem — kills
     `wistful` and `wistfulness` both taking a slot;
  4. drop anything below the similarity floor **0.55** — a *quality* gate, not an emptiness
     mechanism: good matches measure 0.73–0.87, and the 20-entry books measurably clear the
     floor too (60/60 words have a neighbour above it; `affable → amiable` 0.841 — validated
     V1), so the small books **show their own results by design** (operator ruling,
     2026-08-24). Keep the floor a tuning knob with a `ponytail:` comment naming that.
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
- known pairs still rank in the top three (`emotions`/`melancholy` → `wistful` as the
  semantic pin; `startup`/`10x engineer` → a non-empty result containing a multi-word term —
  the proof multi-word terms work at all, since they have no word vector. Measured under the
  final canonical tokenizer: `tech lead`, `lifestyle business`, `maker time` — the brainstorm's
  `zero to one` pick ranked differently once folding landed, so the assertion pins the
  *purpose*, not that exact pair);
- no two results share a 4-char canonical stem (filter 3 above);
- the 20-entry books return real results (`character`/`affable` → top three contains
  `amiable`, measured 0.841) and no result anywhere scores below the floor;
- case identity: a lowercased query never receives its own uppercase twin as a result
  (`kpi` against `startup`'s `KPI` — filter 1/2's canonical folding at work);
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

    init() {
        // My Words invalidation (validated V2): capture posts didChange
        // (SavedWords.swift:81) from the Services thread; queue: .main hops back.
        // Without this, a word captured while My Words is open never becomes a
        // CANDIDATE in other words' boxes until relaunch or book-switch.
        NotificationCenter.default.addObserver(forName: SavedWords.didChange, object: nil,
                                               queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.builtFor == SavedWords.resource else { return }
                self.builtFor = nil
                self.load(.saved)
            }
        }
    }

    /// @concurrent, NOT a bare `nonisolated async`: under this project's
    /// SWIFT_APPROACHABLE_CONCURRENCY a nonisolated async func inherits the CALLER's
    /// actor, which would build the index on the main thread. Measured — see plan §5.
    /// The book is decoded HERE, off the main actor (validated V4: the decode costs a
    /// measured ~21ms and WordViewModel already pays it once on main per switch) —
    /// legal because WordProvider is a nonisolated struct and UserDefaults reads
    /// (the "saved" path) are thread-safe.
    @concurrent private nonisolated func build(_ resource: String) async -> RelatedWordsIndex? {
        RelatedWordsIndex(words: WordProvider(resource: resource).allWords)
    }

    /// Idempotent — repeat calls for the same dictionary are free. Required, because
    /// `.task`/`.onAppear` re-fire every time a pushed detail screen pops back.
    func load(_ book: Wordbook) {
        guard builtFor != book.id else { return }
        builtFor = book.id
        index = nil
        let previous = task
        previous?.cancel()
        task = Task { [weak self] in
            await previous?.value      // serialize: never two NLEmbedding builds alive (V5)
            guard !Task.isCancelled else { return }
            let idx = await self?.build(book.id)
            guard !Task.isCancelled else { return }
            self?.index = idx
        }
    }

    func related(to word: Word) -> [Word] { index?.nearest(to: word) ?? [] }
}
```

Four details that are each a fixed defect, not a preference:

- **The decode lives inside `build`, off the main actor** (r4, validated V4). r3 read
  `allWords` on the main actor before the task — correct isolation-wise, but it added a
  measured ~21ms synchronous decode to a switch that `WordViewModel.select`
  (`WordViewModel.swift:30`) already pays for on main. `WordProvider` is a `nonisolated`
  struct, so constructing it inside `@concurrent build` is not an isolation violation.
- **`await previous?.value` serializes builds** (r4, validated V5). Cancellation still makes
  the old build exit at its next `%512` check; the await only enforces ordering, so two
  `NLEmbedding` instances are never live concurrently and the thread-safety question is moot.
- The outer `Task {}` deliberately **stays on the main actor** so touching `self` is safe;
  it is `await self?.build(book.id)` that hops off. Doing it the other way — background task
  hopping back in via `MainActor.run { self.… }` — trips `#SendableClosureCaptures`.
- `guard builtFor != book.id` is what stops a full rebuild every time the user navigates back
  out of a related word — and the `didChange` observer clears it for My Words only, so a
  capture triggers exactly one rebuild of exactly one book (V2).

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
  observation re-renders the box in when the build finishes. Give the box one
  `.animation(.default, value: related.map(\.term))` so that redraw *fades* — without the
  modifier it pops (validated V7). That one modifier is the whole fade-in; no extra state.
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
  "usecase" the feature exists to show, **rendered only when non-empty** (validated V3:
  6,406 of Everyday's 12,000 and 94% of Medical's entries have no example; an unconditional
  row ships blank quote lines — mirror the footer's own guard, `WordDetail.swift:97`). The
  pushed `WordDetail` reads the same environment store, so **it renders its own box**; that
  is the chain.
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
  r4 closes the residual hole the review found (V5): `load` awaits the previous task before
  building, so two embedding instances are never *live* at once — the cancelled build still
  exits at its next `%512` check; the await only enforces ordering.
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
- **Accessibility:** each row needs one `.accessibilityLabel` combining every field the row
  displays — term, part of speech, definition, and the example when shown (validated V3);
  without it VoiceOver reads four disconnected text runs per row.
- **Dynamic Type:** this project uses fixed `.system(size:)` / `.serif(n)` sizes throughout
  (`Theme.swift:60`), so match that and do **not** introduce a lone scaling row. A pre-existing
  gap, not this change's to fix.
- **Localization:** no `.xcstrings` in the project — strings are inline literals. "In the same
  vein" follows that convention.

## 7. Decision forks (operator-owned)

1. ~~List detail screen too?~~ **Resolved: full chain.** The box renders on every `WordDetail`
   at any depth. This is what moved the index into the environment, and it removed the
   `WordViewModel` changes r1 needed.
2. ~~Three results, or five?~~ **Resolved: three, floor-trimmed.** A hard 1–2 was considered
   and rejected — the 0.55 floor already shrinks the box adaptively, and fewer slots make a
   single off result louder, not quieter.
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
| Similarity floor mistuned — box empty on good words, or near-floor strangers | Medium | Medium | Empty box on `words`, or a pair like `defenestration → sonder` (measured 0.618) in `curiosities` | Tune the one constant; the check script asserts both ends |
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
back is instant with no rebuild; Dictionary of Medicine repopulates with medical neighbours
**with no blank example lines** (94% of Medical has no example); the three 20-entry books
show **their own within-book neighbours** (`affable → amiable`); a word captured while My
Words is open becomes a candidate without relaunch; New Word re-ranks with no perceptible
pause.

## 10. Open questions & assumptions

- `[Unverified]` No app build was run — the plan is verified by type-checking isolated
  snippets under the project's flags, not by compiling the app target.
- `[Unverified]` `NLEmbedding` thread-safety. Sidestepped by construction — the model is
  created and consumed inside one `@concurrent` function. Resolved by keeping it that way.
- **Resolved (was `[Assumption]`): the 0.55 floor is now measured on both ends** — good
  matches 0.73–0.87, and the small books clear it too (60/60 words, top scores 0.581–0.848;
  [validation](../04_PR/Review/RELATED_WORDS_REVIEW_VALIDATION.md) V1). It stays a taste knob; `curiosities`
  sits closest to the line.
- `[Unverified]` r4's revised store snippet (§4 step 3) was **not** re-type-checked under the
  project's flags the way r3's snippets were; the checklist's build items are its
  verification.
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
