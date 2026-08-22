# Audit — RELATED_WORDS_PLAN.md (revision 2)

Second audit pass. The [first audit](RELATED_WORDS_PLAN_AUDIT.md) covered r1; this one treats
r2 as a fresh document, because the revision replaced the architecture (parameter-threading →
environment store) and a rewrite can introduce defects of its own.

**Verdict: Ready to build — after one major.** Confidence: high. Both r1 blockers are gone and
verified by compilation. No new blockers. One resource defect, three accuracy defects.

## r1 findings — all seven confirmed fixed

Re-checked against the file, not from memory: B1 (`allWords` hoisted to the main actor, L188),
B2 (`@concurrent` + the measured table, L177/L269), M3 (chain at any depth, L58/L91), M4
(`guard builtFor != book.id`, L184), M5 (on-demand query centroid, L119), M6 (`Double` →
`Float`, L116), M7 (check script sequenced before the UI, §9).

## Upgraded — the plan's biggest open question is now settled

r2 §10 carried `[Unverified]` on environment propagation to `NavigationStack` destinations.
That is the load-bearing assumption of the whole chain design: if it were wrong, the box would
silently vanish past depth 1 — the exact bug M3 existed to fix.

**Runtime-verified, not inferred.** A minimal SwiftUI macOS app with `.environment(Store())`
applied to the `NavigationStack`, pushing programmatically via `NavigationPath`, printed from
the destination's `onAppear`:

```
DESTINATION saw environment -> INJECTED-OK
```

Promote this out of §10's assumption list.

## Major

### N1 — Cancellation is cosmetic; concurrent builds pile up

`RelatedWordsStore.load` calls `task?.cancel()`, and the plan presents that as the mechanism
that stops redundant work. It does not. Swift cancellation is cooperative, and
`RelatedWordsIndex.init?` as specified in Step 1 is a synchronous build loop with **no
`Task.isCancelled` check anywhere inside it**. Cancelling only discards the *result*.

Demonstrated with a stand-in build loop, simulating three quick dictionary switches:

```
simulating a user switching dictionary 3 times quickly:
   build #2 RAN TO COMPLETION (cancelled: true)
   build #2 result DISCARDED
   build #1 RAN TO COMPLETION (cancelled: true)
   build #1 result DISCARDED
   build #3 RAN TO COMPLETION (cancelled: false)
```

All three ran to completion, in parallel. Applied to the real thing: flicking through the
nine-book picker can put several ~2.4s builds in flight at once, each allocating up to ~14MB,
all competing for cores — which also makes the *wanted* build finish later than it would have
alone. Note `Task.isCancelled` correctly reads `true` inside the cancelled builds, so the
information is available; nothing consults it.

**Severity:** major, not blocking — results stay correct (the `guard` discards stale ones) and
nothing crashes. It is a resource defect with a two-line fix.

**Fix:** have the build loop cooperate, and let `init?` return `nil` for a cancelled build —
the failable initialiser already models exactly that outcome:

```swift
for (i, word) in words.enumerated() {
    if i % 512 == 0 && Task.isCancelled { return nil }
    // …centroid…
}
```

The `builtFor` guard already prevents the *same*-dictionary case, so this only bites on rapid
switching between *different* books — reachable from both the Settings picker and the list's
own picker.

## Minors

### N2 — Three inaccurate `file:line` citations

Citations are the part of a plan a builder trusts without re-checking, so these matter more
than their size suggests:

| Plan says | Actually |
|---|---|
| `WordView.swift:63` (`#Preview`) | **61** |
| `WordListView.swift:113` (`#Preview`) | **116** |
| `WordProvider.swift:70` (JSON in bundle) | a bare `return`; the bundle load is ~73–77 |

The rest spot-check clean or are off-by-one in a defensible direction (pointing at the `final
class` / `struct` line rather than the `@Observable` / `@main` attribute above it):
`SavedWords.swift:75`, `AppGroup.swift:22`, `WordProvider.swift:44`, `WordViewModel.swift:14`,
`WordListViewModel.swift:13`, `OneWordApp.swift:11`, `WordDetail.swift:105–120`.

### N3 — The preview-crash symptom is wrong for one of the two previews

Step 4 says both `#Preview`s "trap at runtime the moment the preview renders" without the
environment injection. True for `WordView`'s — it renders `WordDetail` immediately. **Not**
true for `WordListView`'s: it renders a `List` whose `WordDetail` sits behind a
`NavigationLink` (`WordListView.swift:27`) and isn't constructed until you navigate. That
preview opens fine and traps only on a click.

Both still need `.environment(RelatedWordsStore())` — the instruction is right, the stated
symptom isn't, and a builder who adds the injection to only the visibly-broken one leaves a
preview that fails later.

### N4 — Switching dictionaries mid-chain is undecided

If you are three words deep in Everyday English and switch to Medical from the list picker,
the stacked screens keep their own words but rank them against the *medical* index. Not
wrong exactly — you did change dictionary — but nobody chose it. Worth one sentence in the
plan saying which behavior is intended. Low severity.

## What r2 got right

`@concurrent` was checked under three flag sets — with approachable concurrency, with only
`-default-isolation MainActor`, and with no isolation flags at all — and compiles clean in
every one, so the fix does not depend on how Xcode expands `SWIFT_APPROACHABLE_CONCURRENCY`.
That was worth confirming, since the whole B2 fix rests on that attribute being available.
The store shape type-checks clean in both Swift 5 and Swift 6 language modes. The `builtFor`
guard genuinely closes M4. And resolving the chain fork really did shrink the change —
`WordViewModel` is untouched, which removes three edit sites r1 needed.

## Assumptions & limits

- `[Unverified]` No app build was run — this skill is read-only. Findings come from compiling
  and running isolated snippets under the project's flags, not the app target itself.
- N1's demonstration used a synthetic build loop, not the real centroid code (which doesn't
  exist yet). What it establishes is the *cancellation semantics* of the plan's task shape,
  which is what the finding is about.
- The environment-propagation test used `.navigationDestination(for:)`; the plan uses inline
  `NavigationLink { WordDetail(word: w) }`. Both render the destination inside the stack's
  hierarchy, so the result should carry over — `[Inference]` on that last step.
