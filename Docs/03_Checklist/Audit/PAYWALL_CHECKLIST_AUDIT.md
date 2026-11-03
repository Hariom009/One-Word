# Checklist audit: PAYWALL_CHECKLIST

## 1. Header

- **Checklist audited:** `Docs/03_Checklist/PAYWALL_CHECKLIST.md` ("Paywall: Build Checklist"). I read all 579 lines: every item from S0.1 to S7.G, RG1–RG15, the five DECIDE items, the deferred section, and DOD1–DOD13.
- **Plan it was checked against:** `Docs/02_Plan/Resolved/PAYWALL_PLAN_RESOLVED.md`, all 906 lines (§1–§6).
  - The plan has been through an audit (`Docs/02_Plan/Audit/PAYWALL_PLAN_AUDIT.md`, verdict *Ready to build*, no blockers; I opened only its headings) and a resolution pass.
  - Q1, Q2 and Q7 are final. RQ1–RQ5 are recommended defaults sitting in the review queue.
- **Contract applied:** `~/.claude/agents/checklist-writer.md` (1–88), using the protocol in `~/.claude/agents/checklist-auditor.md` (1–106).
- **Goal reference:** the operator's brief, `/private/tmp/claude-501/-Users-hariom-Desktop-One-Word/ad09efae-44c3-4a4e-a3a9-123bc838e427/scratchpad/plan-paywall-brief.md` (1–161).
- **Bounded spot-checks.** Three read-only tool calls at `release/1.1.0` @ `9c0bdf9`:
  - I ran the checklist's own S7.4 and RG12 greps against the baseline, and grepped RG13's tokens in the files the plan edits.
  - `git status --porcelain -- Docs/` and `git ls-files Docs/02_Plan | grep -i paywall`.
  - I read the referents behind several done-whens:
    - `OneWord/Views/PremiumView.swift:84-132` (the fan's `accessibilityHidden`)
    - `tools/check_premium.sh` (the `check`/`print` lines, and `:91`)
    - `Docs/00_Context/ARCHITECTURE.md:124-128, 140-150, 182-192`
    - `Docs/00_Context/REPO_MAP.md:30, 52`
  - I piped the plan's verbatim S4.3 comment (`PAYWALL_PLAN_RESOLVED.md:537-539`) through RG7's grep.
- **Out of scope:** I did not re-check the plan's API or `file:line` claims against the source. That was /plan-audit's job.

## 2. Verdict

**Fix gaps first.** Confidence is high on fidelity and on B1, and medium on the three Major findings.

The checklist is a close and honest transformation of the resolved plan:
- Every Step 0–7 bullet, every matrix row, every risk exit and every review-queue item has a covering item, with IDs that trace back to the plan.
- The plan's `[Unverified]`, `[Inference]` and `[Assumption]` tags are carried forward, and there's a table showing which item settles each one.
- It found and flagged a real defect inside the plan (S7.4). My baseline grep confirms it.
- The rule for MANUAL items fits a builder agent that can't click through StoreKit dialogs.

One gate can never pass on a correct build, though:
- RG7's grep matches the `ponytail:` comment that S4.3 must add word for word and that RG14 requires.
- Faced with that, a builder agent will report a false red, delete the plan's comment to get a green, or tick a box whose done-when doesn't hold.

Three Major findings should be fixed in the same pass:
- an App Review screenshot that can be taken while the perks are still mock copy,
- the "the cat must never cover Buy" requirement, which has nothing checking it on Mac or iPhone,
- a Step 7 done-when that forbids committing the dossier that the README line links to.

Each fix is a one- to three-line edit to the checklist. Nothing needs a `/checklist` rebuild or a plan change. None of the findings touch Steps 1–3, so the build can start those now.

## 3. Fidelity map

| Plan section / step | Covering checklist items | Status |
|---|---|---|
| Header provenance (audited, resolved, Q1/Q2/Q7 final, RQ defaults) | §1 Header | covered |
| §4.1 done-when 1–6 | DOD1–DOD6 | covered |
| §4.1 in/out of scope (nothing gated, no new Shared file, `PremiumView` stays dormant) | RG1, RG13, S4.1b | covered |
| §4.2 D1–D15 | D2 S2.1 · D3 RG3 · D4 S5.4, RG4 · D5 S2.7c, S4.2j, RG2 · D6 S2.2, S4.2f · D7 S6.3 · D8 S3.G · D9 S3.1 · D10 S6.5, S6.6b · D11 S1.3 · D12 S4.1 · D13 S4.2f · D14 S4.3 · D15 S4.2c, S5.1 · D1 (no new VM) RG1 | covered |
| Step 0: prices, R8, group localization, true IAP metadata, mirror to `.storekit` | S0.1–S0.4 | covered |
| Step 0: true perks (F10), review screenshot, attach IAPs | S0.5, S0.6, S0.7 | covered, but S0.6 is mis-ordered (**M1**) |
| Step 0: metadata, privacy page live (R9), sandbox/TestFlight pass | S0.8, S0.9, S0.10a–c | covered |
| Step 1: `.storekit` prices, ids, `savings`, four headless checks, verify | S1.1–S1.4d, S1.G | covered |
| Step 2: `PremiumViewModel` fields, `load`, `refresh`, `handle`, `restore`, header comment | S2.1–S2.6 | covered |
| Step 2: `UnlockButton` `open:`, hint, static `buy` | S2.7a–c | covered |
| Step 2 verify: builds, pill, delete, baseline screenshots | S2.G, S2.M1–M3 | covered |
| Step 3: prerequisite fetch, folder JSONs, two imagesets, `sips`, symbol grep, fallback | S3.0–S3.4, S3.G, S3.F | covered |
| Step 4: `PremiumView.fan` made static | S4.1a–b | covered |
| Step 4: `PaywallView` skeleton, `Theme.cat`, content, root modifiers, offers, cards, `buyButton`, below the cards, stub `thanks`, `Breathe` | S4.2a–m | covered; the cat-clear-of-Buy rule isn't in any done-when (**M2**) |
| Step 4: the Mac `Window` scene | S4.3 | covered |
| Step 4: Profile pill → window or sheet, `owned` kept | S4.4a–d | covered |
| Step 4 verify (Mac ×3, iPhone ×3, iPad, prices, R3 baseline) | S4.G, S4.M1–M9 | covered |
| Step 5: Mac and iOS `thanks`, entrance, no "Pick a book" | S5.1–S5.3 | covered; the iOS Done action is implicit (m9) |
| Step 5: root triggers and conditional detents | S5.4a–d | covered |
| Step 5: `Confetti`, `Piece`, local capture (R5) | S5.5a–c | covered |
| Step 5 verify (Buy Yearly, VoiceOver, Ask to Buy, Reduce Motion, Mac haptic, restore moved to row 8) | S5.G, S5.M1–M6, S0.10c | covered |
| Step 6: imports, state, body swap, `plans` without `owned`, `manageSubscriptionsSheet`, `premiumCard` (header, perks, Manage, look, contrast, a11y), one commit | S6.1–S6.7 | covered |
| Step 6 verify | S6.G, S6.M1–M4 | covered |
| Step 7: ARCHITECTURE ×5, REPO_MAP ×2, README dossier line, no other 01–06 doc, verify grep | S7.1a–e, S7.2, S7.3, S7.5, S7.4, S7.G | covered; S7.4's plan defect is correctly flagged; S7.5 is stricter than the plan (**M3**) |
| §4.4 data, persistence, expiry, errors | RG13, DOD8, S4.2k, DOD7 | covered |
| §4.5 isolation, task lifetime, retain cycles | RG5, RG6, S5.5c | covered ("`yearly` resets on each open" is unchecked; nit) |
| §4.6 VoiceOver, keyboard, Reduce Motion, contrast, localization, target membership, Info.plist, availability | RG1, RG7, RG8, RG9, RG11, RG15, S6.6c | covered; **RG7 can't pass (B1)** |
| §4.7 headless test block | S1.4a–d | covered |
| §4.7 matrix rows 1, 2, 4, 5, 6, 7, 8 | DOD1 / S4.M9 / S6.M3 · S4.M1–M8 · DOD7 · DOD8 · DOD9 · DOD10 · S0.10a–c | covered |
| §4.7 matrix row 3 (buy all three; final celebration; gold card label after Step 6) | S4.M3 (stub stage), S5.M1–M2 (Yearly only), S6.M1–M2 (Lifetime, Yearly) | **partial** (m1) |
| §4.7 gates after every step | GATES, every `.G` item, DOD12 | covered |
| §4.8 forks: F1, F5, F10 decided; F7 → RQ4 | Header, RQ4, RQ1 | covered |
| §4.8 forks F2, F3, F4, F6, F8, F9 (default plus flip-condition) | §5 tail list, defaults only | **partial**: flip-conditions dropped (m6) |
| §4.9 R1–R13 exits | R1 DOD13 · R2 S4.M3 · R3 S4.M9 · R4 RQ2/S5.M6 · R5 S5.5c · R6 S5.M2 · R7 S3.4/S3.F · R8 S0.1 · R9 S0.9 · R10 S6.M2 · R11 DOD10 + deferred · R12 S4.M2 · R13 S4.M5/RG9 | covered |
| §4.10 sequencing, unblocks, end-to-end path | Step headers, `blocked-by`, DOD11 | covered (Step 4's "unblocks" header is incomplete; nit) |
| §4.11 open questions and assumptions | The carried table under the deferred section; R1b's `[Inference]` in RQ1 | covered |
| §5 RQ1–RQ5 | Five DECIDE items | covered (RQ1(a) clashes with RG13; m12) |
| §6 deferred (m7, m15(3), restoration, carried unverified items) | Deferred section and its table | covered |

## 4. Blocking findings

### B1. RG7 can't pass on a correct build: its grep matches the plan's required comment

- **Location:** §4 iOS rigor gates, RG7, first done-when bullet. It interacts with S4.3, RG14 and DOD12.
- **What's wrong:**
  - RG7 requires that `git diff 9c0bdf9 -- OneWord | grep -nE '^\+.*(#available|@available|restorationBehavior|defaultLaunchBehavior)'` prints nothing.
  - S4.3 says to add the Window scene "exactly as in the plan's Step 4 block", including the `ponytail:` restoration comment. RG14 requires that comment to be present.
  - The comment mentions both `restorationBehavior` and `#available`.
- **Evidence:** I piped `PAYWALL_PLAN_RESOLVED.md:537-539` (the verbatim comment) through RG7's pattern. Two lines match:
  ```
  +        // ponytail: a Premium window left open can come back at launch. restorationBehavior(.disabled)
  +        // is macOS 15+, and SceneBuilder has no buildEither, so an `if #available` would drop the
  ```
- **Fix:** have RG7 skip comment-only added lines. For example:
  `git diff 9c0bdf9 -- OneWord | grep -E '^\+' | grep -vE '^\+[[:space:]]*//' | grep -nE '#available|@available|restorationBehavior|defaultLaunchBehavior'` prints nothing.
  Also add a note: "the S4.3 `ponytail:` comment is expected to name `restorationBehavior`; that is not a violation."
- **Why it blocks:**
  - DOD12 requires "RG1–RG15 are clean", so the build can't be declared done.
  - A builder agent hitting this red has three ways out, and two are bad: reword or delete the plan's mandated comment, which loses required work and breaks RG14, or tick RG7 on the grounds that "only comments match", which ticks a box whose done-when doesn't hold.
- The fix is one line, and RG7 only runs at the pre-merge pass. Steps 1–7 can proceed meanwhile.
- **Related:** RG12 and RG13 use the same `^\+.*` shape. I checked both: RG12's grep is clean at baseline, and no comment the plan specifies contains a price, `UserDefaults` or `AppGroup` `[Inference from the plan's text]`. They're fine today, but they'd break the same way if a builder wrote such a comment. Consider the same comment filter there.

## 5. Major findings

### M1. S0.6's App Review screenshot can be taken while the perks are still mock copy

- **Location:** S0.6, `blocked-by: S5.G`.
- **What's wrong:**
  - The screenshot is of the paywall. S4.2e puts `perks` at the top of the offers.
  - S0.6 depends only on S5.G, not on S0.5, which replaces the perks with true statements.
  - So the checklist allows submitting a review screenshot that shows the MOCK list.
- **Evidence:**
  - Plan Step 0 says replacing `PaywallView.perks` "gates submitting the subscriptions" (F10).
  - R1 is the plan's only **High** risk: App Review rejecting "mock or unsupported claims (3.1.2(a), 2.3)".
  - That a screenshot showing mock copy would hurt review is `[Inference]`.
- **Fix:** change S0.6 to `blocked-by: S5.G, S0.5`.
- **Severity:** Major. It misorders the step that guards the plan's highest risk. It affects release, not the build. Confidence: medium.

### M2. "The cat must never cover Buy" has no check on Mac or iPhone

- **Location:** S4.2i, plus S4.M1, S4.M4 and S4.M7.
- **What's wrong:**
  - S4.2i states the rule in bold, but its done-when is only "both builds pass, with the overlay or without it".
  - The only manual check of it is S4.M7, which covers iPad.
  - S4.M1 (Mac) and S4.M4 (iPhone, medium detent) never look at it, and neither does DOD3.
- **Evidence:**
  - Plan Step 4's Lifetime card says: "**The cat never covers a Buy button.** On the Mac and iPad the button is 160×40 and leading. On the phone it is full width at 50pt, with `.padding(.bottom, 96)`… All of these are knobs."
  - The plan's own Verify lists only iPad. That gap is inherited from the plan, but the contract asks the checklist to lift flagged constraints into gates.
  - On the phone, the overlay's `offset(y: 20)` plus a full-width button is the tightest case.
- **Fix:** add "the cushion cat leaves the Lifetime Buy button fully visible" to S4.M1 and to S4.M4, checked at both `.medium` and `.large`. It doesn't apply under S3.F.
- **Severity:** Major. A bolded requirement has no checkable signal on two of three platforms. Confidence: medium.

### M3. S7.5's done-when goes beyond the plan and blocks committing the dossier S7.3 links to

- **Location:** S7.5, and S7.3.
- **What's wrong:**
  - The plan says "Do not edit any other `01`–`06` doc."
  - S7.5's done-when instead says "under `Docs/`, the Step 7 commit changes **only** ARCHITECTURE.md, REPO_MAP.md and README.md, plus this checklist."
  - Committing a new, untracked file isn't editing a doc. But S7.5 as written forbids it.
- **Evidence:**
  - `git status` shows `PAYWALL_PLAN.md`, `Audit/PAYWALL_PLAN_AUDIT.md`, `Resolved/PAYWALL_PLAN_RESOLVED.md` and `PAYWALL_CHECKLIST.md` all untracked (`??`). `git ls-files Docs/02_Plan | grep -i paywall` returns nothing.
  - S7.3 makes the README's Paywall line link to three of those files.
  - Built as written, the README line in the Step 7 commit would link to files that aren't in the repository, and no item ever commits them.
- **Fix:**
  - Reword S7.5's done-when to: "no existing point-in-time doc is modified: `git diff --name-only --diff-filter=M 9c0bdf9 -- 'Docs/0[1-6]*'` prints nothing."
  - Decide where the dossier gets committed (Operator question 1).
- **Severity:** Major. A done-when that conflicts with S7.3 would misdirect the builder. Confidence: medium. It drops to Minor if you commit the dossier on its own.

## 6. Minor findings and nits

**Minor**

- **m1. Matrix row 3 is only partly covered.** Plan row 3: "Buy Monthly, Yearly and Lifetime … dimmed modal, confetti … the gold card label is right after Step 6."
  - After Step 5, only Yearly goes through the real celebration (S5.M1, S5.M2).
  - After Step 6, Lifetime and Yearly labels are checked (S6.M1, S6.M2), but a Monthly owner's label isn't.
  - Unlike rows 4–7, row 3 has no DOD row.
  - The code path doesn't depend on the product, so the residual risk is low `[Inference]`.
  - Fix: widen S5.M1 and S5.M2 to "each of Monthly, Yearly and Lifetime, deleting in between". Either add "Monthly owner reads Subscription" to S6.M2, or add a DOD row for row 3.
- **m2. RG11 depends on a MANUAL item, which locks the agent out of DOD12.** RG11's done-when includes "DOD9's VoiceOver spot-check passes". DOD12 needs RG1–RG15, so the one DoD row a builder agent can otherwise finish becomes unfinishable. Fix: make RG11 a read-through only. DOD9 already carries the VoiceOver check.
- **m3. Items inside S4.2 depend on later siblings.**
  - S4.2i's "both builds pass" can't hold until `buyButton` (S4.2j) and `Breathe` (S4.2m) exist, and both are listed after it.
  - S4.2e calls `PremiumView.fan` but has no `blocked-by: S4.1`.
  - Fix: add `blocked-by: S4.2j, S4.2m` to S4.2i (or move S4.2m before S4.2i), and `blocked-by: S4.1` to S4.2e.
- **m4. Step 0 changes repo files with no commit and no gates.**
  - S0.4 edits `StoreKit/OneWord.storekit`, and S0.5 edits `OneWord/Views/PaywallView.swift`, a Swift file.
  - Neither says which commit it lands in or requires GATES afterwards. DOD13 doesn't either, so the binary that gets submitted could carry an unbuilt Swift edit. That conflicts with the project's "all three must be green" rule.
  - S0.5 also doesn't say what happens to the `MOCK` doc comment and the `ponytail: placeholder copy…` line. RG14 requires that line to be present.
  - Fix: add "GATES exit 0 after the edit; commit `<name>`" to S0.4 and S0.5, and say in S0.5 that the MOCK and placeholder comments are removed (and RG14's perks entry retired).
- **m5. S0.7 isn't blocked by RQ1.** RQ1 decides what gets attached ("If RQ1 flips to (a), attach only Lifetime"). The contract says a fork that is a prerequisite of a step must be listed as its `blocked-by`. This blocks release only, not the build. Fix: add `blocked-by: DECIDE RQ1` to S0.7.
- **m6. F2, F3, F4, F6, F8 and F9 are listed as "not open" without their flip-conditions.**
  - Plan §4.8 gives each one a "the other branch wins when…" column. The checklist keeps only the defaults.
  - This is visible, so it isn't silently settling a fork. But F8 (Done only, where the canvas has "Pick a book") and F2 (light page on Midnight) both depart from the canvas.
  - Fix: add the plan's flip-condition to each line. See Operator question 3.
- **m7. The header overclaims.** "Every line number the plan cites still matched the code" isn't supported by the peek list. The list doesn't include ARCHITECTURE, CAT_UI_PLAN, SyncToast, `PremiumView.swift:222-431` or Wordbook. The few I spot-checked (`ARCHITECTURE.md:127`, around `:184` and `:190`, and `REPO_MAP.md:30, 52`) do match. Fix: "every cited line in the files peeked at matched."
- **m8. S2.M3's baseline can be recovered later.**
  - S2.M3 says that if it isn't run before Step 4, "S4.M9, S6.M3 and DOD1 have no baseline either." But the steps land as ordered commits, so the baseline can be rebuilt later by checking out the Step 2 commit.
  - Inherited from the plan: S4.M9's "the only difference is the price text" doesn't fit. The Step 2 baseline already shows $169.99 (Step 1 changed it), so against that baseline any difference at all is a regression.
  - Fix: say "or later, from the Step 2 commit", and make S4.M9 "no difference from the baseline".
- **m9. The iPhone thank-you's Done is never specified or checked.** S5.2 doesn't say what Done does (presumably `dismiss()`, closing the sheet, per the plan's `\.dismiss` comment). No MANUAL item checks that it closes the sheet. The iOS headline's `.isHeader` is caught only by RG11's read-through. Fix: add "Done calls `dismiss()`; the headline is `.isHeader`" to S5.2, and "Done closes the sheet" to S5.M2.
- **m10. "Done" is unclear under the S3.F path.** DOD3 requires "the Lifetime card with the cat". If S3.F is taken, the build can't reach DOD3 until the deferred follow-up lands. See Operator question 2.
- **m11. DOD9 has no pass criterion.** "Every combination has been looked at" says what to look at, not what passing looks like. Fix: name the criterion, e.g. no clipping, the cat clear of Buy, legible on all three appearances, and RG11's Reduce Motion behaviour.
- **m12. RQ1's alternative (a) contradicts RG13 and DOD6.** Option (a) adds `static let subscriptions = false` to `Features.swift`. RG13 requires `git diff 9c0bdf9 -- OneWord/Models/Features.swift` to print nothing. Fix: under RQ1(a), note "amends RG13: `Features.swift` gains only `subscriptions`; `premium` is still `false`."

**Nits**

- S4.2g says "checked by eye in S4.M". There's no `S4.M` item; it should be S4.M1, S4.M4 or S4.M7.
- Step 4's header says it "unblocks Step 5". S6 (via S4.G) and S0.5 (via S4.2a) depend on it too. The checklist was right to add the S6 → S4.G edge that plan §4.10 leaves out, but it didn't update the header.
- S2.1's done-when cites `PremiumBar.swift:88`. After S2.7a inserts a line, that becomes `:89`. Anchor on the symbol instead.
- S1.3's done-when is "S1.4 passes", but S1.4 is `blocked-by: S1.3`. Tick them together.
- S3.G's DerivedData glob `OneWord-*` may match an older DerivedData folder. Prefer the path from `xcodebuild -showBuildSettings`.
- S4.2d's `preferredColorScheme` grep breaks if R13's way out (S4.M5) is taken. RG9 allows for that; S4.2d doesn't.
- Escape closing the window is only checked by read-through (RG11). No MANUAL item presses Escape.
- §4.5 says `yearly` "resets to Yearly on each open". Nothing checks it.
- S0.10 (sandbox/TestFlight) isn't `blocked-by` S0.1 or S0.7, though a TestFlight pass needs the IAPs set up in App Store Connect.

## 7. Coverage gaps

These are things the checklist leaves out, as opposed to things it gets wrong:

- **No DOD row for matrix row 3.** Rows 1, 4, 5, 6, 7 and 8 all have one (m1).
- **No commit or gate home for Step 0's two repo edits** (S0.4, S0.5) (m4).
- **The dossier commit.** No item commits the four untracked plan/checklist docs, or this audit, which S7.3 links to (M3).
- **Two manual checks are missing:** Done closing the iPhone sheet, and Escape closing the Mac window (m9, nits).

Everything else in the contract is present: test items, an a11y gate, a deferred section, a definition of done, and DECIDE items.

## 8. What the checklist got right

- **Nothing lost.** Every plan step and verify bullet, every risk exit, every review-queue item and every deferred item maps to a checklist item. IDs follow `S<step>.<n>`, so each item traces straight back to the plan.
- **Honesty carried forward.**
  - Every `[Unverified]`, `[Inference]` and `[Assumption]` tag from §4.11 and §6 is kept, and a table names the item that settles each one.
  - S7.4 flags a real defect in the plan instead of hiding it. My baseline grep of `PaywallView\|cat_cushion` over `Docs/00_Context` and `Docs/README.md` returns nothing, which supports the checklist's claim that the plan's wording can only hit ARCHITECTURE.
- **MANUAL items fit this builder.** "A green build never checks a MANUAL box", the `— not run: <reason>` marking, and "a DoD row whose MANUAL items are not run stays unchecked" are exactly right for an agent that can't click StoreKit dialogs.
- **The iOS rigor became gates.** RG1–RG15 turn §4.5 and §4.6 into greps and read-throughs: target membership, keeping SwiftUI out of the view model, exactly two `celebrations += 1`, root-placed triggers, `nonisolated Piece`, `[weak self]` kept, platform guards, explicit imports, prices only from StoreKit, nothing gated. The referents I checked hold up:
  - `check_premium.sh` prints `ok <what>` for each check and `all checks passed` at `:91`, so S1.4a–d can be observed.
  - The `fan` already has `.accessibilityHidden(true)`, so RG11's "fan hidden" holds by reuse.
  - RG12 is clean at baseline.
  - `ARCHITECTURE.md:127` reads exactly as S7.1a expects.
- **Decisions handled correctly.**
  - Q1, Q2 and Q7 are built as final, not reopened.
  - RQ1–RQ5 are non-blocking DECIDE items, each with the applied default, the alternatives, a flip condition and a done-when.
- **Sequencing.**
  - M1's one-commit rule is S6.7, with a check across the whole branch.
  - The S3.F fallback has a marking rule and a deferred follow-up.
  - Step 4 is the thin end-to-end slice.
  - Step 3 is correctly marked as able to run in parallel.
  - The checklist adds the S6 → S4.G edge that the plan's own unblocks list leaves out. Step 6 reads `PaywallView.perks`, so the edge is needed.

## 9. Operator questions

1. **Where does the Paywall dossier get committed?** `PAYWALL_PLAN.md`, its audit, the resolved plan, this checklist and this audit are all untracked. Should they go in the Step 7 commit (which means relaxing S7.5, see M3) or in a separate docs commit? And should S7.3's README line wait until they're tracked?
2. **If S3.F is taken (no cat PNGs), is the build "done"?** Is it done at DOD1–DOD12 with the Step 3 follow-up still open, or does DOD3 ("the Lifetime card with the cat") wait for the follow-up?
3. **Should F2, F3, F4, F6, F8 and F9 stay closed?** Accept them as closed knobs, or carry them as non-blocking DECIDE items with the plan's flip-conditions? This matters most for F8 (Done only, where the canvas had "Pick a book") and F2 (a light paywall over Midnight). Neither was put to you as a question upstream.
4. **Is checking only Yearly through the final celebration enough?** Or do you want matrix row 3 as the plan wrote it: all three products through Steps 5 and 6, plus the Monthly owner's gold card label?

## 10. What would change the verdict

- **To "Ready to build":**
  - Fix B1 (exclude comment lines from RG7's grep).
  - Make the three Major edits: add S0.5 to S0.6's `blocked-by`; add the cat-clear-of-Buy check to S4.M1 and S4.M4; reword S7.5's done-when.
  - Those changes alone would flip it, with no plan change and no `/checklist` rerun. The Minor findings can be fixed while building.
- **M3 drops to Minor** if you say the dossier is committed separately (question 1). That alone doesn't change the verdict while B1 is open.
- **Toward "Rebuild the checklist"** only if a final decision is reopened before the build:
  - RQ1 flipping to (a) adds a `Features.subscriptions` flag, a `load()` filter, and RG13/DOD6 changes.
  - RQ3 flipping adds an upgrade row, a `lifetime` flag, and brings m7 into the build.
  - Reversing Q1 reshapes Steps 4–5.
  - Any of those means new build items. Re-resolve the plan and rerun `/checklist` rather than patching this one.
- **Nothing found here points back to `/plan-audit`.** The one plan-level defect (S7.4's grep) is already flagged and has a sound path to acceptance.
