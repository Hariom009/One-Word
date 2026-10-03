# Checklist audit: iPhone Leaf 1 build checklist (the iOS build compiles)

> Audited 2026-10-03 by `/checklist-audit --report` (the `checklist-auditor` subagent). It checks [IPHONE_CHECKLIST.md](../IPHONE_CHECKLIST.md) against the resolved plan [IPHONE_PLAN_RESOLVED.md](../../02_Plan/Resolved/IPHONE_PLAN_RESOLVED.md) it derives from and against the checklist-writer contract. Read-only: nothing was built or run.

## 1. Header

- **Checklist audited:** `Docs/03_Checklist/IPHONE_CHECKLIST.md`. The on-disk copy is byte-identical to the copy embedded in the brief (diffed). Read in full: header, the DECIDE block, 1.0–1.10, G1–G10, the L2–L5 pointers, the ⏸ section and the definition of done.
- **Plan checked against:** `Docs/02_Plan/Resolved/IPHONE_PLAN_RESOLVED.md`, which is **audited and resolved**: `/plan` → `/plan-audit` → `/plan-resolver`, with 20 fixes and 4 operator defaults (Q1, Q2, Q3, M3). §1–§6 read in full: the stack table, resolution log, §4.1–§4.12, §5 review queue and §6.
- **Contracts applied:** `$HOME/.claude/agents/checklist-auditor.md` and `$HOME/.claude/agents/checklist-writer.md`.
- **Bounded spot-checks (4 read-only commands, no code re-grounding):**
  - `tools/check_*.sh`: the six gates exist, and which Swift files each one compiles was listed.
  - `grep canImport` in `OneWord/Shared` and `OneWord/Models`: the only hits are `SavedWords.swift:13` and `:139`, so G1's done-when looks tickable after step 1.3.
  - The 1.9d grep: the string-literal hits are exactly the plan's eight sites, so the done-when looks tickable.
  - `OneWord/WordCapture.swift:24-56`: the body of `configureFirebase()`.

## 2. Verdict

**Fix gaps first.** Confidence: medium-high.

The transformation is unusually faithful. Every Leaf 1 sub-step in plan §4.3 has a covering item. All four operator defaults are carried as `DECIDE:` items with a default, an alternative and a flip condition. The plan's `[Unverified]`, `[Inference]` and `[Assumption]` tags travel with the items they touch. The deferred work sits intact in the ⏸ section. The iOS rigor is lifted into ten checkable gates.

The defects are executability defects, not dropped plan steps:
- One pair of items has a **circular done-when/blocked-by**. Step 1.4 cannot be ticked honestly.
- Two items **observe the iOS build before it can compile**. 1.5f stalls the build at step 1.5. 1.2e is satisfied vacuously, so ticking it says nothing.

All of these are small wording or ordering fixes, so this is not a rebuild. Nothing here points back at the plan itself.

## 3. Fidelity map

| Plan section / step | Covering checklist item(s) | Status |
|---|---|---|
| §1 provenance, stack | Header | covered |
| §2 R1 (app runpath untouched) | 1.1c "leave the app runpath alone" + done-when | covered |
| §2 R2 (SDKROOT at project level) | 1.1a, 1.1b | covered |
| §2 R3 (don't run gen_appicon) | 1.8b, 1.8d | covered |
| §2 R4 (two extra strings) | 1.9a (`:159`), 1.9c (`:116`) | covered |
| §2 R5 (GSI 9.2 iOS signature unverified) | 1.5c `[Unverified]`, L4 pointer | covered |
| §2 R6 (`#if` inside `WindowDragArea.body`) | 1.7a | covered |
| B1 / B2 | 1.3b / 1.7c; DoD line | covered |
| §4.1 Leaf 1 done-when | DoD | covered |
| §4.1 program-level done (widget gallery, Premium purchase, full iPhone pass) | none (out of Leaf 1 scope) | partial, see Coverage gaps |
| §4.1 out-of-scope list (6 items) | ⏸ section (all 6) | covered |
| Invariant 1 (no new target) | none | missing (minor) |
| Invariant 2 (`#if os`, never `canImport`) | G1 | covered |
| Invariant 3 (macOS-only stays gated) | G3 | covered |
| Invariant 4 (Mac unchanged except copy) | G9, DECIDE M3 | covered (G9 omits the 1.9 by-eye pass) |
| Invariant 5 (`[sdk=]`/project values, no xcconfig, no duplicate config) | none | missing (minor) |
| Invariant 6 (bundle id unchanged; one GoogleService plist `[Unverified]`) | ⏸ open facts (plist only) | partial |
| Invariant 7 (member import visibility) | G2 | covered |
| §4.2 macOS-only inventory (15 rows) | 1.3–1.7, G3; the two "no change" rows need no item | covered |
| 1.0 runtime | 1.0 | covered |
| 1.1 a/b/c/d + verify | 1.1a–1.1e | covered |
| 1.2 entitlements + verify + exit + signing-UI caveat | 1.2a–1.2e, G5 caveat | covered (1.2e done-when not observable at its position, see B2) |
| 1.3 AppGroup, SavedWords, `[Unverified]` registration | 1.3a–c, G6 | covered |
| 1.4 imports, init, move, guards, postfix `#if` exit, WordCapture | 1.4a–1.4g | covered (dependency defect, see B1) |
| 1.5 seam (import, typealias, signatures, GSI split, avatar, SignInView anchor) | 1.5a–1.5e, 1.5g | covered |
| §4.7 cheap preview (m8) | 1.5f | covered but misplaced (B2) |
| 1.6 SettingsView / DictionaryPicker / SentenceView / PremiumView + by-eye | 1.6a–1.6e | covered |
| 1.7 PaneHeader, RootView + verify + exit | 1.7a–1.7d | covered |
| 1.8 fonts, icon (one-off, Contents.json, script), both manifests, verify, `[Assumption]` | 1.8a–1.8g | covered |
| 1.9 eight strings + grep + `[Inference]` | 1.9a–1.9d | covered |
| 1.10 CLAUDE.md, PROJECT_CONTEXT, REPO_MAP, version check | 1.10a–1.10d, G10 | covered |
| §4.4 L2–L5 touchpoints | L2–L5 pointer items | covered as pointers (L2 drops the a11y notes, L4 drops some console checks) |
| §4.5 data (no migration; fresh `group.` container) | G6 / 1.3a comment | covered (nothing to migrate) |
| §4.6 concurrency and memory | per-group isolation notes + G8 | covered |
| §4.7 test plan (gates every step, builds, by-hand passes 1.4–1.7 **and 1.9**) | step verifies, DoD | partial (per-step gates and the 1.9 by-eye pass missing, minor) |
| §4.8 a11y / localisation / target membership / `@available` / versions / signing caveat | G4, G5, G7, G10, 1.9 header; Dynamic Type in ⏸ | covered |
| §4.9 forks F1/F2 locked; F3–F5 defaulted; Q1–Q3/M3 | DECIDE ×4; F1–F5 in prose; F4/F5 in ⏸ | partial (F3 has Leaf 1 code, see M1) |
| §4.10 risks / exits (11 rows) | G6, 1.2e, 1.7d, 1.0, 1.5c, L4, 1.6a, 1.8g, L4 (ITMS) | partial (Firebase-record exit and the "revert that file" swap exit missing) |
| §4.11 sequencing | group order 1.0→1.10, "Unblocks" headers | covered |
| §4.11 program end-to-end confirmation | none | missing (out of Leaf 1 scope; no pointer) |
| §4.12 open questions | inline tags + ⏸ "open facts" | covered |
| §5 operator review queue (4) | DECIDE Q1, Q2, Q3, M3 | covered |
| §6 remaining | ⏸ open facts | covered |

## 4. Blocking findings

**B1. 1.4b's done-when depends on 1.4f, but 1.4f is blocked-by 1.4b (circular).**
- **Location:** 1.4b, 1.4f.
- **What's wrong:** 1.4b's done-when is "`configureFirebase` is defined in `OneWordApp.swift` and nowhere else (`grep -rn 'func configureFirebase' OneWord` shows one hit)". The copy in `WordCapture.swift` is deleted only in 1.4f, which carries `blocked-by: 1.4b`. So 1.4b cannot be ticked truthfully until a step it blocks is done: the builder either ticks a lie or deadlocks.
- **Evidence:** plan §4.3 step 1.4 does the move (OneWordApp) and the delete (WordCapture) as two bullets of the same step. The checklist split them and attached the "nowhere else" condition to the wrong half. The spot-check confirms `private func configureFirebase()` lives at `WordCapture.swift:46-53` today.
- **Fix:** change 1.4b's done-when to `grep -n 'func configureFirebase' OneWord/OneWordApp.swift` shows one hit. 1.4f's existing grep already proves the WordCapture copy is gone; optionally add the repo-wide one-hit grep to 1.4f.
- **Why blocking:** a load-bearing item in the critical path cannot be honestly checked, and the group header says 1.4 unblocks 1.5.

**B2. Two done-whens observe the iOS build before it can compile.**
- **Location:** 1.5f, and through it 1.5g; also 1.2e.
- **What's wrong:**
  - **1.5f:** the done-when is "the canvas renders the preview on an iPhone device". A SwiftUI preview on an iPhone destination has to compile the app target for the iOS simulator. Per the plan (§4.3 header and §4.11 item 8), that first happens at the end of step 1.7 `[Inference]`. 1.5g is blocked-by 1.5f, and the 1.5 group "unblocks 1.6". So the build stalls at 1.5, or the builder ticks 1.5f unverified.
  - **1.2e:** the done-when is "the iOS build no longer reports an entitlement the profile lacks". At step 1.2 the iOS build still fails on Swift errors (1.1e expects exactly that), so it never reaches code signing. The condition holds vacuously and proves nothing. The plan's exit (condition the macOS path `[sdk=macosx*]`) is then stranded in 1.2. If a signing problem first shows up at 1.7d or 1.8g, there is no pointer back to it.
- **Evidence:** plan §4.7 introduces the preview as a test-plan item and doesn't tie it to step 1.5; the checklist placed it there. The plan's own 1.2 verify has the same timing issue, but the transformation turned it into a gating checkbox.
- **Fix:**
  - **1.5f:** keep the edit in 1.5f with a static done-when ("the `.frame` sits inside `#if os(macOS)`; Mac build green"). Move "canvas renders on an iPhone device" to 1.7d or 1.8g.
  - **1.2e:** give it static done-whens: `plutil -lint` on both new files, the conditional lines present (already in 1.2c/1.2d), Mac build green. Add "iOS signing accepts the `-iOS` entitlements; if it complains about `app-sandbox`, apply the 1.2 exit" to 1.7d (first compile) and 1.8g (first launch).
- **Why blocking:** "tick a lie / build in a broken order". Each is a two-line fix.

## 5. Major findings

**M1. F3 has Leaf 1 code, but the checklist says no flippable default does.**
- **Location:** the paragraph after the DECIDE block ("None of these is an open item for Leaf 1"), and 1.1b.
- **What's wrong:** plan §4.9 lists F3 (iPad in, `TARGETED_DEVICE_FAMILY = "1,2"`) as "Defaulted, the operator may flip". Step 1.1b writes `TARGETED_DEVICE_FAMILY = "1,2"` into the widget. The fork is surfaced in prose, so it isn't silently settled. But it is labelled as having no Leaf 1 effect, and it has neither a `DECIDE:` item nor a note on 1.1b.
- **Fix:** add `DECIDE: F3` (default "1,2"; flips to "1" if iPad isn't worth it before the first iOS release; done-when: accepted, or 1.1b and the app's existing value changed to "1"). Or at least tag 1.1b "(F3 default)". F4 and F5 are correctly parked in ⏸.

**M2. 1.4c is missing its dependency, and the double-configure window isn't fenced.**
- **Location:** 1.4c.
- **What's wrong:** 1.4c calls `Self.configureFirebase()`, which exists only after 1.4b, but it carries no `blocked-by: 1.4b`.
- **Double-configure risk:** between 1.4c and 1.4f, both `OneWordApp.init` and `AppDelegate.init` (`WordCapture.swift:30-33`) call an unguarded `FirebaseApp.configure()` (spot-checked at `:47`). The done-whens there are build-only, so nothing forces a run. But a builder who launches the app mid-step would likely hit Firebase's "already configured" exception `[Inference]`.
- **Fix:** add `blocked-by: 1.4a, 1.4b` to 1.4c. Add a one-line note: "don't launch the Mac app between 1.4c and 1.4f".

**M3. 1.8g's "Firebase is configured" has no observable signal, and the plan's exit is dropped.**
- **Location:** 1.8g, mirrored in the DoD.
- **What's wrong:** the item gives no way to see that Firebase is configured. Plan §4.10 names the leading indicator ("`FirebaseApp.configure()` logs a bundle mismatch on iOS") and the exit ("add an iOS app with the same bundle id and regenerate the plist"). Neither was carried. The ⏸ open fact names the log but not the exit.
- **Fix:** done-when: "the Xcode console shows no FirebaseCore configure or bundle-mismatch error, and the `No CLIENT_ID` assertion doesn't fire". Add the exit line.

**M4. 1.8f's "`git diff` gained **exactly** these" can't be checked as written.**
- **Location:** 1.8f.
- **What's wrong:** by step 1.8 the uncommitted `project.pbxproj` diff already holds all the 1.1 and 1.2 edits. Neither the plan nor the checklist has a per-step commit, so `git diff` against `HEAD` can't isolate four new entries.
- **Fix:** name a baseline, for example "commit or `git stash`-snapshot before 1.8f, then diff against it". Or use a scoped check: `grep -c 'PrivacyInfo.xcprivacy' OneWord.xcodeproj/project.pbxproj` equals the expected count, with the Resources-phase entry under `B456E8B2`.

## 6. Minor findings and nits

- **Per-step gates missing from the step verifies.** The checklist states "every step must leave the Mac build and the gates green", and plan §4.7 says all six gates run in every step's check. But the verify items 1.1e, 1.2e, 1.4g, 1.5g, 1.7d and 1.9d check only builds. The impact appears low: the spot-check shows the gates compile only `Shared/` and `Models/` files, and none of the files edited in 1.4–1.9. A cheap fix is to add "gates green" to each verify item.
- **1.6c's done-when cites a gate that doesn't compile the edited file.** It cites `check_sentences`, which compiles only `OneWord/Models/Sentences.swift`, not `SentenceView.swift`. The gate proves nothing about the edit; the Mac build is the real signal. Keep it, but don't read it as coverage.
- **1.3b names only one gate.** Its done-when names `check_capture`. `check_learned` and `check_premium` also compile the real `SavedWords.swift` (this was already covered by 1.3c's all-six check).
- **Invariants 1, 5 and 6 have no gate.** Cheap greps would cover them: two `PBXNativeTarget`s, no `.xcconfig` and no new `XCBuildConfiguration`, and `PRODUCT_BUNDLE_IDENTIFIER` unchanged.
- **G9 omits the 1.9 Mac by-eye pass.** Plan §4.7 lists "the Mac pass in steps 1.4–1.7 and 1.9". G9 checks only 1.4g–1.7d, and 1.9d is grep-only. Add a by-eye check that the eight strings read correctly on the Mac.
- **G8's "adds no actor" is ambiguous.** 1.6b and 1.6c add `@MainActor`. Make it a pattern, for example `git diff | grep -E '^\+.*(\bactor\b|Task\.detached|nonisolated)'`.
- **1.7d dropped a plan tag.** The plan's `[Inference]` on "iOS should compile at 1.7" (§4.3 header) is gone, though the exit is carried.
- **1.10 header miscount.** It says "three doc edits" but holds four items, counting 1.10d. The 1.9 and 1.10 groups also lack an "Unblocks" header.
- **1.1a's done-when needs interpretation.** "No project-level hits" requires reading line numbers, because the widget hits remain until 1.1b. 1.1e could add `plutil -lint OneWord.xcodeproj/project.pbxproj` as a scriptable stand-in for the "damaged project" check.
- **Undo-point overstatement (inherited from the plan).** After 1.2, `git checkout -- OneWord.xcodeproj` doesn't remove the two untracked `-iOS.entitlements` files. They're harmless once unreferenced.
- **1.8d could have a non-mutating syntax check,** for example `python3 -c "import ast;ast.parse(open('tools/gen_appicon.py').read())"`.
- **Leaf pointers drop some plan detail.** L2 drops plan §4.8's a11y notes (VoiceOver labels on the new Profile rows and tab items; `HeaderButtonStyle` raised to 44×44). L4 drops "Sign in with Apple on the App ID", "StoreKit file attached to the scheme Run action" and the manual matrix. Each leaf's own `/plan` should re-carry these.
- **One risk exit is missing.** The "revert that file" exit for a Mac swap regression (§4.10) isn't on 1.6e.

## 7. Coverage gaps

- **No program-level end-to-end confirmation, even as a pointer.** Plan §4.11 (sign in, Emotions chip, search "stab", buy and restore, Practice from Profile, flip doesn't stop music, medium widget follows the pick) and §4.1's program done-when have no home. Leaf 1 scope justifies leaving them out of the active list. But a final "Program done" pointer after L5 would stop them being lost. The Q2 music check currently survives only as a ⏸ open fact.
- **No step-level gate runs.** See the first minor finding. This is a contract-shape gap rather than a dropped plan step.

## 8. What the checklist got right

- **Leaf 1 coverage is complete.** Every sub-bullet of 1.0–1.10 maps to an item, down to comment updates, citing lines and the R1/R3/R6 "don't touch" constraints.
- **Most done-whens are concrete and scriptable.** They use grep-clean checks, `plutil -lint`, `sips` alpha and size checks, and named gates. The by-eye passes are itemised as sub-boxes (1.6e, 1.7d).
- **Plan honesty is carried forward.** It keeps the `[Unverified]` tags (1.0, 1.5c, 1.6a, G6), `[Inference]` (1.4e, 1.9d) and `[Assumption]` (1.8g), each with its exit.
- **The DECIDE items are well formed.** Each has a default, an alternative, a flip condition, a done-when and the step it lives in.
- **Deferred work is preserved and gated.** It includes the plan's §6 "settled in passing" facts, correctly marked "not tasks".
- **The iOS rigor gates G1–G10 are specific and checkable.** Isolation, member imports, `@available`, entitlements per SDK, target membership for each new non-source file, and version lockstep. The signing-UI caveat is kept.
- **Useful operational additions that stay within the plan:** the line-drift warning for `project.pbxproj`, the command shorthand, the parallelism markers for 1.6a–d and 1.8, and an honest "Files peeked: none".

## 9. Operator questions

1. **F3:** should iPad (`TARGETED_DEVICE_FAMILY = "1,2"`, which 1.1b writes into the widget) be a `DECIDE:` item for Leaf 1, or is it settled enough to stay prose?
2. **DECIDE timing:** Q2, Q3 and M3 each change Leaf 1 code (1.4c, 1.1c, 1.9). The checklist only asks for them to be settled "before the L2 `/plan` run". Do you want to settle them before those steps are built, to avoid rework if you override one?
3. **Program confirmation:** should a "program done" pointer (§4.11's end-to-end pass) be added after L5, or does each leaf's own checklist own that?

## 10. What would change the verdict

- **→ Ready to build:** fix B1 (1.4b's done-when, about one line) and B2 (move 1.5f's canvas check and 1.2e's signing observation to 1.7d/1.8g). M1–M4 are each a one- or two-line edit and are worth doing in the same pass.
- **→ Rebuild:** only if the plan itself changed, for example an operator override of Q3 or M3 that restructures 1.1 or 1.9 beyond a line edit, or a new plan revision. Then regenerate with `/checklist` from the revised plan.
- **Confidence would drop** if Xcode 27 previews turn out not to need a full iOS compile of the target. That would downgrade the 1.5f half of B2 to Minor `[Inference]`. The 1.2e half and B1 would stand.
