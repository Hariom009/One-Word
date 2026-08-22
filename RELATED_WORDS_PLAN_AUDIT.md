# Audit — RELATED_WORDS_PLAN.md

**Verdict: Fix blockers first.** Confidence: high on the two blockers (both reproduced with
the compiler under the project's real build flags), medium on the majors.

The approach is sound and the stack detection re-verified clean. Both blockers sit in the
same place — Step 2's concurrency shape — and both have verified fixes below. Everything
else is a correctness gap in the *instructions*, not in the design.

## Stack re-verification

Re-detected independently from `project.pbxproj`; **no mismatch** with the plan's claims:
macOS 14.0 min · `SWIFT_VERSION = 5.0` · `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` ·
`SWIFT_APPROACHABLE_CONCURRENCY = YES` · app target = `PBXFileSystemSynchronizedRootGroup`,
widget = explicit 11-file `PBXSourcesBuildPhase` · no test target · no dependencies.

The plan under-read one of these. `SWIFT_APPROACHABLE_CONCURRENCY = YES` is not cosmetic —
it changes which code runs off the main actor, and that is blocker 2.

---

## Blockers

### B1 — Step 2 reads `provider.allWords` inside `Task.detached`: main-actor violation

`RELATED_WORDS_PLAN.md` §4 Step 2 says "build the index from `provider.allWords`" *inside*
the detached task. `WordViewModel` is `@MainActor` by default isolation, so `provider` is
main-actor-isolated and reading it from a detached task is a data race.

Reproduced by compiling the plan's shape verbatim with the project's flags
(`-swift-version 5 -default-isolation MainActor`):

```
warning: main actor-isolated property 'provider' cannot be accessed from outside
         of the actor; this is an error in the Swift 6 language mode
```

It compiles **today** (warning only, Swift 5 mode) and would break the moment the project
moves to Swift 6 — and it is a genuine race in the meantime.

**Fix:** read the words on the main actor, then hand the array to the background work.
`Word` is a struct of `String` lets, so the array crosses cleanly.

### B2 — No mechanism named that is *both* off-main and warning-free — and the obvious repair silently runs on main

The plan correctly says a plain `Task {}` inherits the main actor here. But it stops there,
and the idiomatic repair a builder would reach for — a `nonisolated async` method — is
**also on the main actor in this project**, because `SWIFT_APPROACHABLE_CONCURRENCY = YES`
enables `NonisolatedNonsendingByDefault`, under which `nonisolated async` inherits the
caller's isolation.

Measured, same file compiled twice:

| shape | approachable concurrency **ON** (this project) | OFF |
|---|---|---|
| `nonisolated async` | **MAIN — blocks UI** | off-main |
| `@concurrent async` | off-main ✅ | off-main |
| `Task.detached` | off-main ✅ | off-main |
| plain `Task {}` | MAIN — blocks UI | MAIN |

This is the dangerous one: it produces **no warning**, so a 2.4s frozen window would ship
looking correct. It is also invisible to `tools/check_related.sh`, which never launches the app.

**Fix — verified warning-free under both `-swift-version 5` and `-swift-version 6`:**

```swift
/// @concurrent, not a bare `nonisolated async`: under this project's
/// SWIFT_APPROACHABLE_CONCURRENCY a nonisolated async func inherits the caller's
/// actor and would build the index ON the main thread.
@concurrent private nonisolated func build(_ words: [Word]) async -> RelatedWordsIndex? {
    RelatedWordsIndex(words: words)
}

func loadRelated() {
    relatedTask?.cancel()
    let words = provider.allWords          // B1: read ON the main actor, then hand off
    relatedTask = Task { [weak self] in    // MainActor task — safe to touch self here
        guard let idx = await self?.build(words), !Task.isCancelled else { return }
        self?.index = idx
        self?.rank()
    }
}
```

Note the plan's own suggested `await MainActor.run { self.index = … }` with `[weak self]`
*also* warns (`#SendableClosureCaptures` — captured var `self` in concurrent code). The shape
above avoids it by keeping the outer `Task` on the main actor and hopping *outward* to do the
work, rather than hopping back inward to publish.

---

## Majors

### M3 — The browsable chain the feature was sold on doesn't exist

`RELATED_WORDS_BRAINSTORM.md` promises "a browsable chain: warm → scorching → sultry."
But the plan's rows push `WordDetail(word: w)` with no `related:` argument, and §3 makes the
parameter default `[]` — so the pushed screen has **no box**. The chain dies at depth 1.

Not a bug in the code, a contradiction between the two docs. Resolve deliberately: either
accept depth-1 and strike the chain claim from the brainstorm, or take fork 9.1 (promote the
index to `@Environment`), which is what actually delivers the chain.

### M4 — `.onAppear` re-fires on pop, and `loadRelated()` rebuilds unconditionally

The plan triggers `loadRelated()` from `WordView.onAppear` (`WordView.swift:47`), and
specifies it as "cancel in-flight, clear `related`, start the build" — with no guard. In a
`NavigationStack`, the root's `.onAppear` fires again when a pushed view pops, so every
back-navigation from a related word would kick off another full 2.4s rebuild of the *same*
dictionary's index. `[Inference]` on the re-fire (documented SwiftUI behavior, not measured
here); the guard is correct regardless.

**Fix:** make it idempotent — rebuild only when the dictionary actually changed
(`guard index == nil || builtFor != wordbook.id`), and let `refresh()`/`shuffle()` re-rank
from the cached index as §4 Step 2 already intends.

### M5 — The day's word may not be in the open dictionary, and may have no definition

Two facts the plan didn't account for:

1. `SavedWords.pinned` takes the day **whatever dictionary is selected** — stated at
   `WordProvider.swift:44` and honored in `word(for:offset:pinned:)`. So today's word can be
   absent from the index being searched.
2. `SavedWords.capture` stores `Word(term:, partOfSpeech:"", hindi:"", definition:"", example:"")`
   when `lookUp` returns nil (`SavedWords.swift:75`). So the query word can have an **empty
   definition**, leaving only the term to vectorise — and I confirmed an unknown term
   (`"zzqx"`) and the `SavedWords.placeholder` em-dash both return `nil` from
   `vector(for:)`.

The plan's `nearest(to word: Word, limit:)` signature permits the right implementation, but
never states it, and a builder could reasonably implement it as an index lookup — which
yields an **empty box every time you capture a word**.

**Fix:** state explicitly that `nearest(to:)` computes the query centroid on demand from the
passed `Word`, never by looking it up in the index, and returns `[]` when no centroid can be
built. That last case is also the correct behavior for the placeholder entry.

---

## Minors

- **M6 — type mismatch, unstated.** `NLEmbedding.vector(for:)` returns `Optional<Array<Double>>`
  (verified). The plan stores `[Float]` for the memory win but never mentions the narrowing
  conversion. Correct as designed; just needs saying, since accumulating in `Double` and
  storing `Float` is the intended shape.
- **M7 — the plan contradicts its own build order.** §4 numbers the check script *Step 4*
  (after the UI); §9 sequences it as *item 2* (before). §9's order is the right one — the
  script is what makes steps 1–2 verifiable headless. Renumber §4.

## What the plan got right

Worth recording so the fixes don't over-correct: every stack claim re-verified, including the
two non-obvious ones — that a plain `Task {}` stays on main (measured) and that target
membership is *inverted* here, so app-only costs nothing and no `.pbxproj` edit is needed.
The `Float` memory math (14.4MB) is correct. The decision to route the box through
`WordDetail` reaches both call sites (`WordView.swift:19`, `WordListView.swift:27`) as
claimed. The filter set and the 0.55 floor trace to real measurements, and the check-script
design targets the regression that actually matters (definition edits silently dropping
coverage).

## Operator questions

1. **M3 — depth-1 box, or the full chain?** Fork 9.1 was already yours to call; M3 just
   raises the stakes, because the brainstorm currently promises the chain in writing.
2. **B2 — `@concurrent` or `Task.detached`?** Both verified off-main. `@concurrent` reads
   closer to this project's existing `nonisolated` idiom; `Task.detached` is more familiar.
   I'd take `@concurrent`.

## Assumptions & limits of this audit

- `[Unverified]` No build was run — this skill is read-only. Findings come from compiling
  isolated snippets under the project's flags, not the app target itself.
- `[Inference]` M4's `.onAppear` re-fire on pop is documented SwiftUI behavior, not measured.
- `[Assumption]` The `-enable-upcoming-feature NonisolatedNonsendingByDefault` flag I used is
  the effect of `SWIFT_APPROACHABLE_CONCURRENCY = YES`. The observed contrast between the two
  modes is the evidence; I did not read Xcode's build-setting expansion to confirm the exact
  flag set it passes.
