# Related Words — Build Checklist

Derived from [RELATED_WORDS_PLAN.md](../02_Plan/RELATED_WORDS_PLAN.md) (revision 4). The plan is
**audited, resolved, and review-validated**: both audit rounds applied
([first](../02_Plan/Audit/RELATED_WORDS_PLAN_AUDIT.md), [second](../02_Plan/Audit/RELATED_WORDS_PLAN_AUDIT_R2.md)), all forks
closed, and the six confirmed external-review findings folded in as r4
([validation](../04_PR/Review/RELATED_WORDS_REVIEW_VALIDATION.md)). This checklist is a faithful
transformation of that plan — it adds no scope and re-verifies none of its claims.

**Stack** (per plan §1): macOS 14+, SwiftUI, `@Observable` MVVM, Swift 5 language mode with
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` **and** `SWIFT_APPROACHABLE_CONCURRENCY = YES`
(load-bearing — see gate G1), no test target (standalone `swiftc` check scripts), no dependencies.

**Sizing peek** (not an audit): `OneWord/WordDetail.swift` 1–119, `OneWord/OneWordApp.swift`
1–24, `tools/check_words.sh`, root listing.

Carried forward from plan §10: `[Unverified]` no app build was ever run while planning — the
**first ⌘B in item 1a is itself a checkpoint**, not a formality. The 0.55 floor is now
**measured on both ends** (good matches 0.73–0.87; the small books clear it — 60/60 words,
top scores 0.581–0.848) — item 2c keeps it honest as a regression check. `[Unverified]`
r4's revised store snippet was not re-type-checked the way r3's were — items 3a–3d are its
verification.

## How to use

`- [ ]` todo · `- [x]` done · `blocked-by:` must be checked first · `DECIDE:` operator call ·
`⏸` deferred by design. **One rule: never check an item until its done-when holds.** Items are
in build order (plan §9); the riskiest piece lands first and is provable headless.

## Checklist

### Step 1 — `RelatedWordsIndex` (pure model, headless-verifiable)

- [x] **1a** Create `OneWord/RelatedWords.swift` at the app root — **not** in `Shared/` — with
  `nonisolated struct RelatedWordsIndex { init?(words: [Word]); func nearest(to:limit:) -> [Word] }`
  (limit default 3) — files: `OneWord/RelatedWords.swift` (NEW · app target only, via
  synchronized root group) · isolation: `nonisolated` · **done-when:** app target builds (⌘B)
  and the file sits under `OneWord/`, not `OneWord/Shared/`.
- [x] **1b** `init?` builds normalised 300-dim `[Float]` centroids: load
  `NLEmbedding.wordEmbedding(for: .english)` **once**, return `nil` if it's `nil`; per word,
  average vectors of the tokens of `term + " " + definition`, skipping tokens ≤3 chars and the
  small stopword set; accumulate in `Double`, store `[Float]`; drop entries with no
  vectorisable token — blocked-by: 1a · **done-when:** builds; behavior proven by 2c's
  coverage assertion (≥99% per bundled book).
- [x] **1c** `nearest(to:)` computes the query centroid **on demand from the passed `Word`**,
  never by index lookup (today's pinned word may be absent from the searched book —
  `WordProvider.swift:44` per plan); returns `[]` when no centroid can be built (captured word
  with empty definition), and guards `SavedWords.placeholder` **explicitly** (its teaching
  definition vectorises even though the em-dash term doesn't — found by 2c) — blocked-by:
  1b · **done-when:** builds; 2c's captured-word + placeholder assertions return `[]` without
  crashing.
- [x] **1d** Ranking = dot product + the four filters — all term comparisons through ONE
  canonical identity, `folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)`
  (V6: captures are lowercased while `startup` has 175 mixed-case terms — raw equality would
  show `KPI` as "related" to a captured `kpi`): skip the query itself (canonical equality);
  skip candidates sharing the query's first 4 canonical chars; dedupe survivors against each
  other by the same canonical stem; drop results below the **0.55 floor** (measured both
  ends — a quality gate, NOT an emptiness mechanism; the small books clear it by design),
  with a `ponytail:` comment naming it a tuning knob — blocked-by: 1c · **done-when:**
  builds; 2c's stem-dedupe, small-books-results, and case-identity assertions pass;
  `grep -n "ponytail" OneWord/RelatedWords.swift` hits the floor constant.
- [x] **1e** Cooperative cancellation inside the build loop:
  `if i % 512 == 0 && Task.isCancelled { return nil }` (cancelling the task alone does nothing —
  measured, plan §5) — blocked-by: 1b · **done-when:**
  `grep -n "Task.isCancelled" OneWord/RelatedWords.swift` hits inside the loop; behavior gated at G4.

### Step 2 — check script (prove the algorithm before any UI)

- [x] **2a** `tools/RelatedWordsCheck.swift` — `@main` check asserting all six families:
  (i) coverage ≥99% for each of the eight bundled books; (ii) known pairs rank top-3
  (`emotions`/`melancholy` → `wistful`; `startup`/`10x engineer` → non-empty with a
  multi-word result — the multi-word-term proof; measured: `tech lead`); (iii) no two
  results share a 4-char
  canonical stem; (iv) the 20-entry books return **real results** (`character`/`affable` →
  top-3 contains `amiable`, measured 0.841) and nothing anywhere scores below the floor;
  (v) empty-definition + unknown-term `Word` yields `[]`, not a crash; (vi) case identity —
  a lowercased `kpi` query against the `startup` index never receives `KPI` itself as a
  result — files: `tools/RelatedWordsCheck.swift` (NEW · no target) ·
  **done-when:** compiles via 2b.
- [x] **2b** `tools/check_related.sh` mirroring `check_words.sh` (`swiftc -O` over the real
  sources + the check main; `RelatedWordsIndex` is `nonisolated`, so no special isolation
  flags) — **note the source path differs from the template**: this compiles
  `OneWord/RelatedWords.swift`, not `OneWord/Shared/…` — files: `tools/check_related.sh`
  (NEW) · blocked-by: 1a–1e, 2a · **done-when:** `sh tools/check_related.sh` exits 0.
- [x] **2c** Run it green — **done-when:** all six assertion families pass. This is the
  acceptance signal for the whole of step 1; if the floor assertion fails at both ends, tune
  the one constant (plan §8) rather than adding mechanism.

### Step 3 — `RelatedWordsStore` (where the concurrency risk lives — review this one closely)

- [x] **3a** `@Observable final class RelatedWordsStore` (same file), main-actor by default
  isolation, holding `index`, `builtFor: String?`, `task: Task<Void, Never>?`, and
  `func related(to:) -> [Word]` returning `index?.nearest(to:) ?? []` — files:
  `OneWord/RelatedWords.swift` · isolation: `@MainActor` (default) · blocked-by: 2c ·
  **done-when:** builds.
- [x] **3b** `@concurrent private nonisolated func build(_ resource: String) async` — **exactly
  `@concurrent`, never a bare `nonisolated async`**, which under this project's approachable
  concurrency inherits the caller's actor and runs the 2.4s build on the main thread with no
  warning (measured, plan §5) — and the book is **decoded inside `build`, off the main actor**
  (r4 — V4: the ~21ms decode otherwise doubles the main-actor cost `WordViewModel.select`
  already pays; legal because `WordProvider` is a nonisolated struct). Keep both comments so
  nobody "simplifies" them away — blocked-by: 3a · **done-when:**
  `grep -n "@concurrent" OneWord/RelatedWords.swift` hits; the comments name both traps; builds.
- [x] **3c** `load(_ book:)` per the plan's r4 shape: `guard builtFor != book.id` first
  (idempotence — `.task` re-fires on every pop, `[Inference]` per plan §10; the guard is
  correct either way); then `builtFor = book.id`, `index = nil`; hold `let previous = task`,
  `previous?.cancel()`; the new outer `Task { [weak self] in … }` stays on main and **first
  `await previous?.value`** (serialization — never two `NLEmbedding` builds alive, r4 — V5),
  then `guard !Task.isCancelled`, then `await self?.build(book.id)` hops off, then
  `guard !Task.isCancelled` again before assigning the result — blocked-by: 3b ·
  **done-when:** builds with no isolation warning; runtime behavior verified by DoD items
  and G4.
- [x] **3d** My Words invalidation (r4 — V2): in `init`, observe `SavedWords.didChange`
  (`queue: .main`, `[weak self]`, `MainActor.assumeIsolated`) → if
  `builtFor == SavedWords.resource`, clear it and `load(.saved)`. Capture posts from the
  Services flow (`SavedWords.swift:81`); without this the guard holds a stale saved-book
  index until relaunch or book-switch — blocked-by: 3c · **done-when:** builds;
  `grep -n "didChange" OneWord/RelatedWords.swift` hits; behavior proven by E10.

### Step 4 — the box (pure view code)

- [x] **4a** `OneWordApp`: `@State private var relatedWords = RelatedWordsStore()`, inject via
  `.environment(relatedWords)` on the `NavigationStack` — files: `OneWord/OneWordApp.swift`
  (MODIFIED) · blocked-by: 3c · **done-when:** builds; app launches without an
  environment-missing trap.
- [x] **4b** `WordDetail` reads and drives: `@Environment(RelatedWordsStore.self)`,
  `@AppStorage("dictionaryID", store: AppGroup.defaults)` defaulting to
  `Wordbook.everydayEnglish.id`, `let related = store.related(to: word)` in `body`,
  `.task(id: dictionaryID) { store.load(Wordbook.named(dictionaryID)) }` — reading `index`
  during `body` is what makes the box fade in when the build lands (no extra state); add the
  plan's `ponytail:` comment on the ~5ms per-body re-rank — files: `OneWord/WordDetail.swift`
  (MODIFIED) · blocked-by: 4a · **done-when:** builds; box appears on the home screen below
  "Used as" shortly after launch.
- [x] **4c** The box itself, below `footer(t)`: title `In the same vein` styled exactly like
  the "Used as" footer (`.system(size: 10, weight: .bold)`, `.textCase(.uppercase)`,
  `.tracking(1.6)`, `t.muted`, hairline top rule) — **label wording is deliberate, not
  "Similar words"** (relatedness ≠ synonymy, plan §4); each row a
  `NavigationLink { WordDetail(word: w) }` (mirrors `WordListView.swift:27`): term
  `.serif(20)`/`t.ink`, part of speech `.system(size: 11).italic()`/`t.muted`, definition
  `.system(size: 13)`/`t.definition`, example `.serif(14).italic()`/`t.example` **only when
  non-empty** (r4 — V3: 6,406/12,000 Everyday and 94% of Medical entries have no example —
  mirror the footer's guard, `WordDetail.swift:97`); one
  `.animation(.default, value: related.map(\.term))` so the box **fades** in rather than pops
  (r4 — V7); `if related.isEmpty` → render nothing (one branch covers no-embedding, captured
  words with no vectorisable text, and the pre-build window) — blocked-by: 4b ·
  **done-when:** manual — box matches the footer treatment; box fades in after launch;
  Medical book rows show no blank example lines.
- [x] **4d** Inject the store into **both** previews — they fail differently, so fixing one
  hides the other (plan §4): `WordView.swift:97` traps the moment the preview opens;
  `WordListView.swift:116` opens fine and traps on first row click — files: `WordView.swift`,
  `WordListView.swift` (previews only) · blocked-by: 4a · **done-when:** both previews open
  AND a row click in the `WordListView` preview navigates without trapping.

## iOS rigor gates (pre-merge — each one traces to a measured plan finding)

- [x] **G1** `@concurrent` survived review — the plan's #1 risk is someone replacing it with
  `nonisolated async` (silently main-thread, no warning, uncatchable by the check script;
  `[Assumption]` per plan §10: approachable concurrency ≙ `NonisolatedNonsendingByDefault`,
  evidenced by the measured ON/OFF contrast) —
  **done-when:** grep from 3b still hits AND first open of the 12k book shows no ~2.4s beachball.
- [x] **G2** No synchronous decode on the main actor (r4 — V4): the only `WordProvider(`
  construction in `RelatedWords.swift` sits inside `@concurrent build` — **done-when:**
  `grep -n "WordProvider(" OneWord/RelatedWords.swift` hits only within `build`; no isolation
  warning in the build log; no visible hitch when switching dictionaries.
- [x] **G3** Retain cycle: `[weak self]` on the store's task is the only capture to watch (no
  Combine, no delegate added) — **done-when:** `grep -n "weak self" OneWord/RelatedWords.swift` hits.
- [x] **G4** Cancellation has both halves: store-side `task?.cancel()` + index-side
  `Task.isCancelled` loop check (either alone fails — measured) — **done-when:** both greps
  hit; manual — flick rapidly through all nine books in the picker; no pile-up, no beachball,
  the finally-selected book's box populates.
- [x] **G5** Target membership by *omission*: the synchronized root group auto-compiles the new
  file into the app; the widget's explicit source list must NOT gain it — **done-when:**
  `grep -c "RelatedWords" OneWord.xcodeproj/project.pbxproj` returns 0 and the widget target
  still builds.
- [x] **G6** `NLEmbedding` never crosses a concurrency boundary (thread-safety `[Unverified]`,
  deliberately sidestepped by construction — plan §5) **and builds are serialized** so two
  instances are never live at once (r4 — V5) — **done-when:** `NLEmbedding` is referenced
  only inside `RelatedWordsIndex.init` in `OneWord/RelatedWords.swift` (grep the repo) AND
  `grep -n "await previous?.value" OneWord/RelatedWords.swift` hits inside `load`.
- [x] **G7** Accessibility: each row carries one `.accessibilityLabel` combining **every
  displayed field** — term, part of speech, definition, and the example when shown (r4 — V3;
  else VoiceOver reads disconnected runs) — **done-when:**
  `grep -n "accessibilityLabel" OneWord/WordDetail.swift` hits inside the box's row view.

## Open operator decisions (DECIDE)

None open — all four plan forks are resolved (chain everywhere; three results,
floor-trimmed; no part-of-speech filter; background fade-in). Cross-dictionary is
operator-confirmed out of scope (2026-08-24), and the small books **show** their
within-book results — measured and operator-ruled during review validation (2026-08-24;
E7 tests it).

## ⏸ Deferred / evidence-gated (listed so it isn't lost — do NOT build now)

- ⏸ **D1** App Group disk cache for the index — gate: the ~2.4s background build ever becomes
  *felt* (needs a content hash + My Words excluded, plan §7.4).
- ⏸ **D2** Memoize `nearest(to:)` by term — gate: a dictionary meaningfully bigger than 12k
  lands (the `ponytail:` comment in 4b marks the spot).
- ⏸ **D3** Same-part-of-speech predicate — gate: results feel loose in practice (one
  predicate, plan §7.3).
- ⏸ **D4** Size-gated Everyday fallback for the three 20-entry books — gate: their boxless
  state feels bad in real use (operator chose pure-books option A; plan §2).
- ⏸ **D5** Hand-authored override field for a few high-traffic words — gate: relatedness ≠
  synonymy (`warm` → `dank`) draws real complaints (plan §8 exit, not a rewrite).
- ⏸ **D6** Widget support — gate: the widget's memory ceiling is re-examined (brainstorm §5).
- ⏸ **D7** Per-book in-memory index cache (LRU) — gate: `Everyday → Medical → Everyday`
  rebuild churn is *felt* in use (single live index is a chosen memory trade-off, validated
  V4; the rebuild is background + serialized either way).

## Definition of done (plan §9 end-to-end — checking every box = shippable per the plan)

- [x] **E1** `sh tools/check_related.sh` green: coverage ≥99%, known pairs, stem dedupe,
  small-books-empty, captured-word-no-crash.
- [x] **E2** Both targets build (app + widget), Swift 5 mode, no new warnings.
- [ ] **E3** Home screen: box below "Used as" with three rows (term / part of speech /
  definition / example each).
- [ ] **E4** The chain: click a related word → pushed `WordDetail` shows **its own** box, at
  any depth.
- [ ] **E5** Back is instant — no rebuild pause (the `builtFor` guard doing its job).
- [ ] **E6** Switch to Dictionary of Medicine → box repopulates with medical neighbours.
  Known-accepted (plan §4): screens already stacked from a chain keep their words but re-rank
  against the new book's index — not a bug; do NOT add per-screen indexes (rejected on memory
  grounds).
- [ ] **E7** The three 20-entry books (`character`, `eloquence`, `curiosities`) show **their
  own within-book neighbours** — spot-check `affable → amiable` and `eloquent → rhetoric`
  (measured 0.841 / 0.848; operator-ruled via review validation, 2026-08-24).
- [ ] **E8** New Word → instant re-rank, no perceptible pause.
- [ ] **E9** All G-gates checked; every `[Unverified]` in the plan's §10 either discharged by
  the running app or still true and accepted.
- [ ] **E10** With My Words open, capture a word via Services from another app → after the
  rebuild it appears as a candidate in other captured words' boxes, without relaunch (r4 — V2).
