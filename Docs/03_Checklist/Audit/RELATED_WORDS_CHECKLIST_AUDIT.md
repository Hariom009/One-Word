# Related Words — Checklist Audit

**Audited:** [RELATED_WORDS_CHECKLIST.md](../RELATED_WORDS_CHECKLIST.md) (step granularity, 15 items + 7 gates + 9 DoD items)
**Fidelity reference:** [RELATED_WORDS_PLAN.md](../../02_Plan/RELATED_WORDS_PLAN.md) r3 — itself **audited + resolved**
([audit 1](../../02_Plan/Audit/RELATED_WORDS_PLAN_AUDIT.md), [audit 2](../../02_Plan/Audit/RELATED_WORDS_PLAN_AUDIT_R2.md), all forks closed),
so the checklist inherits a clean provenance chain.
**Contract applied:** `~/.claude/agents/checklist-writer.md`.
**Opened for grounding:** the checklist and plan in full; bounded spot-checks (5 tool calls):
`Wordbook.swift` 1–41 (`named(_:)`, book ids), `WordProvider.swift` (`resource:` init, `allWords`),
`dictionaryID` @AppStorage idiom (`SettingsView.swift:15`, `WordListView.swift:12`),
`#Preview` locations (`WordView.swift:97`, `WordListView.swift:116`), root/tools listings.
**Audit mode:** inline interactive, 2026-08-24. This audits the transformation (checklist vs.
plan vs. contract), not the plan's own code claims — those were `/plan-audit`'s job upstream.

## Verdict — **Ready to build** (high confidence)

Zero blockers. The transformation is faithful: every plan section maps to covering items, no
invented scope was found, every item carries a verifiable done-when, sequencing mirrors plan
§9, and the plan's two *measured* concurrency failure modes survived as grep-able gates (G1,
G4) rather than prose. One major finding (M1, a dropped accepted-behavior note) and four
minors — all hand-patchable; regeneration is not warranted. **M1, m1, and m2 were confirmed by
the operator during the walkthrough and patched into the checklist immediately after this
audit was written** (see Resolution).

## Fidelity map

| Plan section | Covering checklist item(s) | Status |
|---|---|---|
| §2 Scope & done-when | header, E3–E8 | covered |
| §3 Architecture fit (4 types, env store, `WordViewModel` untouched) | 1a, 3a–3c, 4a–4d | covered (untouched-claim unguarded — nit n1) |
| §4 Step 1 — index, centroids, 4 filters, floor, cancellation | 1a–1e | covered |
| §4 Step 2 — check script, 5 assertion families | 2a–2c | covered |
| §4 Step 3 — store, `@concurrent`, idempotent `load` | 3a–3c | covered |
| §4 Step 4 — injection, box, styling, label, previews | 4a–4d | **partial → M1** (accepted-behavior note dropped) |
| §5 Concurrency/memory model (measured table, both cancellation halves, NLEmbedding confinement) | G1–G4, G6 | covered |
| §6 Mechanics & a11y (membership-by-omission, a11y label, fixed sizes, inline literals) | G5, G7, 4c | covered |
| §7 Decision forks (all four resolved) | DECIDE section; D1, D3 | covered |
| §8 Risks & exits | G1, 2c, 4d, 4c/D5 | covered |
| §9 Sequencing & end-to-end | item order 1→2→3→4; E1–E8 (one-to-one) | covered |
| §10 `[Unverified]`/`[Assumption]` carry-forward | header, 1d, G6, E9 | **partial → m2** (two tags dropped) |

## Blocking findings

None.

## Major findings

- **M1 — dropped accepted-behavior note (plan §4, step 4).** The plan explicitly *accepts*
  that switching dictionaries while deep in a chain leaves stacked screens showing their old
  words re-ranked against the newly-loaded index ("accepted rather than overlooked" — one
  store, one index; per-screen indexes were rejected on memory grounds). No checklist item
  carried it. **Build impact:** whoever runs E6 with a chain pushed will see old-book words
  with new-book neighbors and may log it as a bug — or "fix" it with per-screen indexes the
  plan rejected. **Fix (applied):** one known-accepted sentence on E6. **Severity rationale:**
  can misdirect the E6 verification and invite scope creep, but cannot break the build order
  or skip work — major, not blocker. *Operator: confirmed.*

## Minor findings

- **m1 — stale preview locator (verified).** Item 4d cited `WordView.swift:61`; the
  `#Preview` is at **line 97** (grep-confirmed; the `WordListView.swift:116` half is exact).
  Inherited from the plan's citation; the done-when never depended on it. **Fix (applied):**
  `:61` → `:97`. *(Lane note: the plan's own citation being stale is `/plan-audit` territory;
  recorded here only because the checklist copied it into a locator.)*
- **m2 — honesty tags dropped.** 3c stated "`.task` re-fires on every pop" plainly where the
  plan tags it `[Inference]` (impact nil — the `builtFor` guard is correct either way, per
  the plan); G1 omitted the plan's `[Assumption]` that `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  ≙ `NonisolatedNonsendingByDefault`. **Fix (applied):** both tags restored.
- **m3 — over-tight dependency.** 4d (`blocked-by: 4a`) needs only the `RelatedWordsStore`
  type from 3a, not the app injection. Harmless given the build order; left as-is.
- **m4 — parallelism unmarked.** 1e can proceed alongside 1c/1d, and 4d alongside 4b/4c; the
  contract asks for parallel markers. Low impact at this scale (solo builder, short list);
  left as-is.

## Nits

- n1: plan §3's "`WordViewModel` is not modified" payoff has no guard — a free
  `git diff --stat` glance at merge time covers it; not added to avoid gate inflation.
- n2: fork 3's "resolved" status rests on the plan's "Not planned" default plus the
  operator's in-chat acceptance (2026-08-24) rather than a struck-through fork in §7; accurate
  in effect, and D3 preserves the flip-path.

## Coverage gaps

None — every plan section has representation in the map above; the checklist has all the
contract's structural sections (done-whens throughout, rigor gates, DECIDE, ⏸ deferred, DoD).

## What the checklist got right

- E1–E8 map the plan's §9 end-to-end list one-to-one — nothing from the success criteria was
  thinned.
- G1 and G4 turn the plan's two *measured* failure modes (`@concurrent` silently downgraded;
  one-sided cancellation) into greps + manual signals a hurried builder cannot skim past.
- G5's "pbxproj grep must return **zero**" faithfully operationalizes the plan's inverted
  target-membership footgun (synchronized group ⇒ membership by omission).
- The ⏸ section preserves all six deferred items with gates — including D4, the
  operator-chosen Option A (no cross-dictionary fallback) with its reopen condition.
- The fail-differently preview nuance (trap-on-open vs. trap-on-click) survived into 4d's
  done-when, which requires exercising *both* failure paths.
- Header carries the plan's biggest caveat forward honestly: no app build ever ran during
  planning, so 1a's first ⌘B is itself a checkpoint.

## Operator questions

None outstanding — the single question raised (M1: intentional cut or omission?) was resolved
in the walkthrough: omission, confirmed, patched.

## Resolution (post-audit patches, operator-approved)

1. E6 gained the known-accepted mid-chain re-rank sentence (M1).
2. 4d's locator corrected to `WordView.swift:97` (m1).
3. `[Inference]` restored on 3c's `.task` re-fire claim; `[Assumption]` restored on G1's
   approachable-concurrency equivalence (m2).

m3/m4/n1/n2 recorded only, by operator's scope choice (patch offer covered M1 + m1 + m2).

## What would change the verdict

- **→ Fix gaps first:** discovering a plan step with no covering item (none found), or a
  load-bearing done-when that cannot actually be checked (none found — 2c and the G-greps are
  all concrete).
- **→ Rebuild the checklist:** only if the plan itself were revised (e.g., reopening
  cross-dictionary scope), which would invalidate the fidelity map wholesale — re-run
  `/checklist` against the revised plan in that case.
- The applied patches close M1/m1/m2; nothing else observed moves the needle off **Ready to
  build**.
