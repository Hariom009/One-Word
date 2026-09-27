# Sign in with Apple — Checklist Audit

**What was audited**

- **Checklist:** `Docs/03_Checklist/APPLE_SIGN_IN_CHECKLIST.md`.
- **Plan it was checked against:** `Docs/02_Plan/Resolved/APPLE_SIGN_IN_PLAN_RESOLVED.md`.
  That plan was itself audited and resolved, so this audit trusts it as the reference and
  doesn't re-audit its code claims.
- **Contract applied:** `~/.claude/agents/checklist-writer.md`.

> **Where the files are right now.** Both docs were read out of `stash@{0}`
> (`!!GitHub_Desktop<main>`). GitHub Desktop stashed them when the branch moved from
> `feat/premium` to `main`. `feat/premium` has since merged (`5911a75`). The same stash also
> holds unrelated work in progress:
> - a new `OneWord/Views/PremiumWelcome.swift`
> - changes to `project.pbxproj`, `PremiumViewModel.swift`, `PremiumView.swift`,
>   `ProfileView.swift`, `RootView.swift`, `SentenceView.swift` and `SettingsView.swift`
>
> This matters for findings M1 and m1 below.

**What was opened**

- The checklist, all items S1 through D5.
- The resolved plan: §1 facts, §2 scope, §4 steps 0-4, §6 concurrency, §7 matrix,
  §8 mechanics, §9 forks, §10 risks, §11 sequence, §12 open questions and the review queue.
- Spot-checks on `main` HEAD (`0f0bf03`):
  - `AuthViewModel.swift:151`
  - `SignInView.swift:9`, `:67`, `:78`, `:83`
  - every "Google" line in `Profile.swift`, `ProfileView.swift`, `RootView.swift` and
    `FeedbackViewModel.swift`
  - the same lines in the stash's copies of `ProfileView.swift` and `RootView.swift`

## Verdict

**Fix gaps first.** Confidence: high.

- **Coverage is good.** Every implementation step, every test row, all three forks and the
  deferred work map to items.
- **Two major findings, both one-line patches:**
  1. Five done-whens use `git diff`, which compares against the index. Once a step is
     staged or committed, and the plan's §11 suggests one commit per step, those checks
     pass without checking anything.
  2. One of the plan's risk exits (the token audience) has no item.
- There are no blockers. Nothing in the plan is dropped from the build path, and no fork
  was silently settled.

## Fidelity map

| Plan section | Checklist item(s) | Status |
|---|---|---|
| §2 outcome (the done-when) | D4 | covered |
| §2 in-scope: entitlement / flow / button + asset / sweep / `restore()` line | 1a-1c / 2a-2f / 3a-3f / 4a / 2g | covered |
| §2 out-of-scope (F1-F3, widget, `Shared/`) | ⏸ F1-F3, 1c, G4, G8 | covered |
| Step 0: Firebase provider, App ID capability | S1, S2 (S1 keeps its `[Unverified]`) | covered |
| Step 1: key, comment rule, signs, widget untouched | 1a, 1b, 1c | covered |
| Step 2: imports / header / method 1-6 / catch order + domain / nonce lowercase / bridge / drive-by | 2a / 2b / 2e / 2f / 2c / 2d-i..iv / 2g | covered. 2b's done-when is partial (m2). |
| Step 2 verify: no "nearly matches" warning | 2d-iii | covered |
| Step 3: signature / icon mods / static titles / order + symbols / comments / asset delete / HIG `[Unverified]` | 3a / 3b / 3c / 3d / 3f / 3e / 3g | covered |
| Step 4: six comment lines, grep done-when | 4a | partial: the plan's quoted text is dropped, and two line numbers drifted (m1) |
| §6: isolation / lifetime / continuation / `Sendable` / view state / cancellation | G1 / G2 / G3 / ⏸ Swift 6 / 3c / M2 | covered |
| §7: build + five gates | D2, D3 | covered |
| §7: "no automated test, deliberately" | header ("no XCTest target") | partial (nit) |
| §7: matrix rows 1-11 | M1-M11 (M8 keeps its `[Unverified]`) | covered. M6's uid check has no stated place to look (m3). |
| §8 mechanics: entitlement / membership / assets / `@available` / a11y | 1a+1c / G5 / 3e / G6 / G7 | covered |
| §9 forks F1-F3 (F2 wording: "fresh code") | ⏸ F1, F2, F3 | covered |
| §10 exits: capability / provider / delegate name / nonce | S2 / S1 / 2d-iii / 2c+2e | covered |
| §10 exit: token audience rejected → Services ID | none | **missing** (M2) |
| §10 exit: name never shows → `createProfileChangeRequest` | ⏸ Name fallback | covered |
| §11: "one commit per step; Steps 2-3 can squash" | none | missing (nit, n3) |
| §12 open questions (4) | S1, 3g, ⏸ Name fallback, M8 | covered |
| Review queue Q1-Q3 (decided) | 3e, 3d, 3c, and "DECIDE: none open" | covered, correctly as decided rather than open |

## Blocking findings

None.

## Major findings

**M1. Done-whens built on `git diff` stop checking anything once work is committed, and
they pick up unrelated work** (items 1c, G1, G4, G5, G6)

- **What's wrong:**
  - Bare `git diff` compares the working tree against the index, and `git diff --quiet`
    works the same way.
  - Once a step is staged or committed, the diff for those paths is empty, so G1 ("no
    `nonisolated`"), G4 ("nothing in `Shared/`"), G6 ("no `@available`") and 1c ("widget
    untouched") all pass without checking anything.
  - The plan's §11 recommends exactly that cadence: one commit per step.
  - The reverse problem: if `stash@{0}` is popped to recover these docs, its unrelated work
    in progress enters the working tree. G5 (`project.pbxproj` diff empty, no new `.swift`
    file) then fails because of `PremiumWelcome.swift` and the stash's pbxproj change. G6
    greps changes this plan didn't make.
  - G5's new-file check greps only `^??` (untracked). A new `.swift` file that has been
    `git add`-ed shows as `A ` and slips past.
- **Evidence:** the checklist's commands for 1c, G1, G4, G5 and G6. Plan §11: "One commit
  per step works."
- **Fix:** compare against the fork point and scope each command to the paths it names.
  Let `B=$(git merge-base main HEAD)`.
  - **1c:** `git diff --quiet $B -- OneWordWidget/`
  - **G1:** `git diff $B -- OneWord/ViewModels/AuthViewModel.swift | grep -nE "nonisolated|Task\.detached|@preconcurrency"`
  - **G4:** `git diff --name-only $B | grep "OneWord/Shared/"`
  - **G5:** `{ git diff --name-status $B; git status --porcelain | grep '^??'; } | grep '\.swift$'`
    should show only the two modified files, as `M`.
  - **G6:** `git diff $B -- OneWord/ViewModels/AuthViewModel.swift OneWord/Views/SignInView.swift | grep -n "@available\|#available"`
  - These still work after commits, and they ignore changes outside the plan.
- **Why major:** a gate that passes vacuously is a box that lies. Here it would lie on the
  exact isolation and `Shared/` checks the plan relies on. It isn't a blocker because the
  code is still right. Only the check stops checking.

**M2. The plan's token-audience exit has no item** (§10 → nothing)

- **What's wrong:** the plan's risk table has a row: "Token audience rejected … 'invalid
  audience' after the sheet … if it's still rejected, add a Services ID in the Apple
  provider's console settings."
  - M1's done-when doesn't mention this failure.
  - The `⏸` section lists the other evidence-gated exits (the name fallback, the App Review
    logo) but not this one.
  - A builder who hits "invalid audience" at M1 has no pointer in the checklist.
- **Fix:** add a `⏸` entry. "**Token audience.** Add a Services ID in Firebase ▸ Apple
  provider. **Gate:** M1 fails with 'invalid audience' after a successful sheet.
  `[Unverified]`: the plan rates it low because `GoogleService-Info.plist`'s `BUNDLE_ID`
  already matches."
- **Why major:** it's a dropped plan item, and the contract says evidence-gated work is
  "listed, not lost". It isn't a blocker because the plan rates it low probability and it
  sits off the happy path.

## Minor findings and nits

**m1. Step 4's sub-items give only file and line, and two lines have drifted.**
- The plan's Step 4 table quotes the current text of each line. 4a dropped that.
- Against `main` HEAD, `ProfileView.swift:48` and `:149` are **`:47` and `:148`**. The
  checklist's numbers match only the stash's copy, which has your work in progress applied.
- **Fix:** put the plan's quoted text back on each sub-item, for example
  `ProfileView.swift` "…the one Google gave". The done-when grep is already
  line-independent, so only the pointers need it.

**m2. 2b's done-when only proves removal.** It checks that "Google sign-in, the whole
feature" is gone, not that the new "Apple needs no extra SDK" line was added.
- **Fix:** add `grep -n "appleCredential" OneWord/ViewModels/AuthViewModel.swift` showing a
  hit in the header comment block.

**m3. M6's "same Firebase uid" says nowhere to look.** The app never shows the uid.
- **Fix:** "Firebase console ▸ Authentication ▸ Users lists **one** Apple-provider user
  after M1 and M6, not two."

**m4. 1b uses an unfilled placeholder.** `<BUILT_PRODUCTS_DIR>` needs looking up.
- **Fix:** add the lookup:
  `xcodebuild -project OneWord.xcodeproj -scheme OneWord -showBuildSettings | awk '/ BUILT_PRODUCTS_DIR /{print $3}'`.

**Nits:**

- **n1.** 3g and D5 both put the M8 result and the HIG risk "in the PR description". The
  plan says "record which one happens" and names no place. The choice is reasonable, but it
  reads as if the plan asked for it. Say "(checklist's choice)", or merge 3g into D5 to
  drop the duplicate.
- **n2.** G2's "M2 run twice in a row" is a stricter check than the plan's. It's harmless,
  but the plan didn't specify it.
- **n3.** Plan §11's commit guidance ("one commit per step; Steps 2-3 can squash") isn't
  carried. It's worth one line under "How to use", especially since it's what makes M1
  bite.
- **n4.** Plan §7's "no automated test, deliberately" reasoning (the gates can't link
  Firebase) appears only as "no XCTest target" in the header. A reader might think a test
  item is missing.

## Coverage gaps

- **No setup item for where the work happens.** The plan never names a branch, so the
  checklist correctly doesn't invent one. But the checklist assumes a tree where the Apple
  change is the only change, and the current state (docs in a stash next to unrelated work
  in progress, on `main`) breaks that assumption. This is raised as question 1 below, not
  as a defect.

Otherwise none. Every contract section is present: header, legend, ordered steps, iOS
gates, DECIDE (correctly "none open"), `⏸` deferred, and definition of done.

## What the checklist got right

- **It's lossless on the build path.** Every plan sub-step in Steps 0-4 has an item. The
  error-catch order, the lowercase nonce, the exact delegate names and "continuation = nil"
  are each pinned by their own done-when.
- **Most done-whens are mechanical.** They are `plutil`, `PlistBuddy`, `codesign`,
  `grep`-clean checks, the build log's "nearly matches" grep, and `test ! -e`, rather than
  "implemented". The few that rely on reading code (2d-ii, 2f, 3b) name exactly what to
  look for.
- **The iOS rigor is lifted into gates.** G1-G8 cover isolation, lifetime, continuation,
  `Shared/`, target membership, `@available`, a11y and the widget. The Swift 6 `sending`
  note went to `⏸` instead of being dropped.
- **Decision hygiene is right.** Q1-Q3 are treated as decided, not re-opened. F1-F3 are
  deferred with their gates. F2 keeps the resolved "fresh authorization code" wording.
- **Uncertainty is carried forward.** `[Unverified]` stays on S1, 3g, M8 and the name
  fallback.
- **Dependencies are sound.** They are acyclic and in plan order: S2 → 1a, Step 3 → 2e,
  matrix → S1/1b/3d, G1 → 2d/2e. Step 4 is correctly marked as parallel.

## Questions for you

1. **Where to build.** `feat/premium` is merged, and the Apple docs now live only in
   `stash@{0}` alongside unrelated Premium work in progress.
   - The suggested route is a fresh `feat/apple-sign-in` off `main`.
   - Restore just the five doc paths with `git checkout stash@{0} -- Docs/`. That brings
     back the four Apple docs and the stash's `Docs/README.md`.
   - Leave the rest of the stash (your Premium work) for its own branch.
   - Alternatively, pop the whole stash and build alongside it. That's only safe once M1's
     scoped commands are in.
2. **Once you pick, `Docs/README.md` needs this audit linked.** I didn't edit it on `main`.
   The stash already modifies that file, and an edit now would conflict when the stash is
   restored.

## What would change the verdict

- **To Ready to build:** patch M1 (five commands) and M2 (one `⏸` line). The minors are
  optional.
- **To Rebuild the checklist:** nothing found points this way. It would take the plan
  changing, for example a re-plan against the post-merge `main`. No such need is visible:
  the plan's files and symbols all still exist on `main` HEAD, and only `ProfileView.swift`'s
  line numbers moved.
