# Related Words — External Review Validation

**Source validated:** a feature-readiness review pasted into chat (2026-08-24), 8 findings
(assigned V1–V8; source carried no IDs), targeting [RELATED_WORDS_PLAN.md](../../02_Plan/RELATED_WORDS_PLAN.md)
r3 and [RELATED_WORDS_CHECKLIST.md](../../03_Checklist/RELATED_WORDS_CHECKLIST.md).
**Tree state:** `975ed05` + untracked planning docs; source files clean. No diff context —
findings are about the *plan/design*, validated against the plan text, the real data files,
and the existing sources.
**Method:** every citation re-opened fresh; every measurement independently reproduced
(scratch Swift implementation of the plan's exact algorithm + `jq` over the bundled JSON).
The review's own evidence lines were treated as claims, per the validator protocol.
**Files opened this session:** `SavedWords.swift` (full), `WordViewModel.swift`,
`WordListViewModel.swift`, `WordDetail.swift`, `WordView.swift` (grep), `Wordbook.swift`,
`WordProvider.swift` (grep), all 8 `OneWord/Shared/*.json` (via jq), plan + checklist in full.

## Scoreboard

**Confirmed: 7** (one as-designed) · **Mechanism-confirmed / harm-unverifiable: 1 (V5)** ·
**Refuted: 0** · Severity corrections: 4 trimmed one notch (V2, V4, V5, V6 High→Medium;
V7 Medium→Low) · Detail errors in the source: 2 (V6's example pair, V4's intent framing).

**Calibration:** this review is trustworthy on its measurements — three independent
reproductions matched to the digit/decimal (V1 similarity scores, V3 counts, V4 timing).
Severities run about one notch hot. Its framing is also correct that the prior
checklist-audit validated plan→checklist *traceability*, not the plan's empirical
assumptions — V1 is precisely a tagged `[Assumption]` (plan §10) failing its first test.

## Confirmed — act on these

### V1 · CONFIRMED ✓ · Blocker (upheld) — the 0.55 floor does not empty the 20-entry books

- **Claim:** all 60/60 small-book words have an eligible neighbour above 0.55, so the plan's
  "the 20-entry books return nothing rather than strangers" (plan:137-138) and checklist E7
  are unsatisfiable as written.
- **Fresh evidence (reproduced):** scratch implementation of the plan's exact spec
  (term+definition centroid, ≤3-char/stopword skip, 4 filters, floor 0.55):
  **character 20/20 · eloquence 20/20 · curiosities 20/20** words return ≥1 result
  (top scores 0.581–0.848). Score-level matches with the source review:
  `affable → amiable` **0.841**, `eloquent → rhetoric` **0.848** — identical to three
  decimals, so the reviewer genuinely ran the algorithm.
- **Nuance the review underplays:** the results are mostly *good*, not strangers —
  the small books are semantically clustered by design (`gregarious → affable, amiable,
  gracious`; `laconic → verbose, pithy`). `curiosities` is the weak one
  (`defenestration → sonder` 0.618 is a stranger just above the floor).
- **RESOLVED by operator (2026-08-24): small books SHOW their within-book results.**
  E7's no-box expectation is dropped; the floor remains the only gate. This stays within the
  earlier Option A decision (no cross-book borrowing — unaffected). Plan §2/§4/§8/§9 and
  checklist 1d/2a-iv/E7 need a revision pass to match.

### V2 · CONFIRMED ✓ · High → **Medium** — My Words index goes stale on capture

- **Fresh evidence:** `capture` rewrites the list and posts `didChange`
  ([SavedWords.swift:77-81](OneWord/Shared/SavedWords.swift:77)); the day's word does refresh on that
  notification ([WordView.swift:84](OneWord/WordView.swift:84)); the plan's store keys rebuilds
  solely on `builtFor != book.id` (plan:201-206) with no notification/revision path — for
  My Words the key is the constant `"saved"` ([SavedWords.swift:26](OneWord/Shared/SavedWords.swift:26)).
- **Trigger:** My Words open → capture from any app via Services → the new word is missing
  as a *candidate* in other words' boxes until relaunch or book-switch.
- **Severity trim rationale:** the captured word still gets its own box (query centroid is
  computed on demand from the passed `Word`, plan:126-129); staleness affects one book's
  candidate pool only. Fix direction: rebuild on `didChange` or fold a revision counter into
  the `builtFor` key.

### V3 · CONFIRMED ✓ · High (Medical) / Medium (rest) — the box promises examples the data lacks

- **Fresh evidence (jq, exact match to the review):** missing examples — words **6406/12000**,
  medical **1634/1736 (94%)**, philosophy **120/138**, emotions **486/987**; the three small
  books and startup are 100% complete.
- **Trigger:** plan:262-267 renders the example row unconditionally; `WordDetail`'s own
  footer guards emptiness ([WordDetail.swift:97](OneWord/WordDetail.swift:97)). In the Medical book
  nearly every related-word row would carry a blank/empty-quote line.
- **Fix direction:** conditional example row (mirror the footer's guard). The a11y sub-point
  is valid as a minor: include whatever is displayed (example, part of speech) in the row's
  VoiceOver label, not just term+definition.

### V4 · CONFIRMED ✓ (with one misframing) · High → **Medium** — duplicate main-actor decode; A→B→A rebuilds

- **Fresh evidence:** `words.json` load+decode measured **21.4 ms** best-of-5 on this Mac
  (review said 22–23 ms). The plan's `load` does this synchronously on the main actor
  (plan:206) — *in addition to* the decode `WordViewModel.select` already performs on main
  ([WordViewModel.swift:30](OneWord/WordViewModel.swift:30); likewise
  [WordListViewModel.swift:38-42](OneWord/WordListViewModel.swift:38)). Double (sometimes triple)
  decode per dictionary switch, ~21 ms each.
- **Misframing:** "despite the build-once-per-dictionary intent" — the plan never promised
  cross-switch caching; the `builtFor` guard exists for pop re-fires (plan:227-228), and
  single-index was a conscious memory trade-off (plan §5). A→B→A rebuilding is a real
  limitation but a *chosen* one.
- **Fix direction:** share the already-loaded word snapshot (pass `[Word]` in) rather than
  re-decoding; LRU remains deferred unless felt.

### V5 · Mechanism CONFIRMED ✓ / harm UNVERIFIABLE ? · High → **Medium** — overlapping builds use NLEmbedding concurrently

- **Fresh evidence:** the plan itself measured overlapping builds (plan:143-145); the %512
  cancellation check (plan:149-152) bounds but does not eliminate overlap — a cancelled build
  runs until its next check while the new one starts. Each build creates its own `NLEmbedding`;
  plan §5's sidestep (plan:307-309) addresses instance-*sharing*, not two live instances.
- **What would settle the harm question:** an Apple thread-safety statement, or a stress test
  of concurrent `wordEmbedding(for:)` instances. **Cheaper than either:** serialize builds
  (await the prior task before starting the next) — one line, and the question disappears.

### V6 · CONFIRMED (as underspecification) ✓ · High → **Medium** — no canonical term identity; startup acronyms

- **Fresh evidence:** captures are lowercased ([SavedWords.swift:91](OneWord/Shared/SavedWords.swift:91));
  startup has **175** mixed-case terms (exact match; short all-caps acronyms: my count 135 vs
  the review's 137 — pattern-definition quibble, immaterial). The plan's filters (plan:132-138)
  specify no case rule for "skip the query itself" or the 4-char stems — a case-sensitive
  implementation lets indexed `KPI` surface as "related" to a captured `kpi`; a lowercased
  identity blocks it (my reproduction lowercased stems and self-matches were filtered).
- **Detail error in the review:** "AI governance" vs "AI literacy" do **not** share a 4-char
  stem ("ai g" ≠ "ai l") — that example is wrong. But real over-merges exist in startup:
  `agency | agenda | agent | agentic` and `accelerator | acceptance criteria | accessibility`
  each collapse to one stem slot (grep-verified).
- **Fix direction:** define one lowercase(+diacritic-folded) canonical identity for
  self-exclusion and stem dedupe; phrase-aware stems can stay deferred.

### V7 · CONFIRMED ✓ · Medium → **Low** — "fade-in" is a pop-in

- plan:250-252 calls the observation-driven re-render "the fade-in, with no extra state";
  no `.animation`/`.transition` appears anywhere in step 4 → the box appears instantly.
  Fix: one `.animation(.default, value:)` modifier, or rename the promise.

### V8 · CONFIRMED (as-designed) ✓ · Low — chains can loop A→B→A

- Real: `affable ↔ amiable` (0.841) is near-symmetric, so the loop is one tap away. The plan
  already accepts unbounded depth as Low risk (plan §8: small structs sharing one index;
  NavigationStack owns the stack). The review itself calls it "probably acceptable."
  Disposition: add it to the manual test pass consciously; no mechanism change.

## Refuted

None. (Two detail-level errors inside otherwise-confirmed findings are noted on V4 and V6.)

## Unverifiable

Only V5's harm sub-question (concurrent `NLEmbedding` instance safety) — see V5 for the
settling experiment and the cheaper serialize-instead fix.

## Noticed in passing (unvalidated)

- `SavedWords.lookUp` compares terms case-sensitively (`$0.term == term`,
  [SavedWords.swift:104](OneWord/Shared/SavedWords.swift:104)) while `normalize` lowercases input — a
  captured "KPI" can never match startup's `KPI` entry and falls through to the macOS
  dictionary. Pre-existing, unrelated to this feature; worth its own small fix.

## Bottom line

The review is substantially correct and its measurements reproduce exactly; trust it at face
value on facts, trim its severities ~one notch. The build should **not** start from the
current checklist. Order of work: **V1** (now resolved: small books show results — revise
plan §2/§4/§8/§9 + checklist 1d/2a-iv/E7) → **V3** (conditional example row + a11y label) →
**V2** (saved-words invalidation) → **V4b** (share the word snapshot; drop the duplicate
main-actor decode) + **V5** (serialize builds) → **V6** (canonical lowercase identity) →
**V7** (animate or rename). V8 becomes a manual-test line item. After the plan revision, the
checklist needs a matching update pass before item 1a is touched.
