# Website checklist: audit

> Audit of [`../WEBSITE_CHECKLIST.md`](../WEBSITE_CHECKLIST.md) against
> [`../../02_Plan/Resolved/WEBSITE_PLAN_RESOLVED.md`](../../02_Plan/Resolved/WEBSITE_PLAN_RESOLVED.md),
> 2026-09-27. Read-only. This audits the transformation, not the code; the plan was re-grounded
> upstream by [`../../02_Plan/Audit/WEBSITE_PLAN_AUDIT.md`](../../02_Plan/Audit/WEBSITE_PLAN_AUDIT.md).

## Header

- **Checklist audited:** `Docs/03_Checklist/WEBSITE_CHECKLIST.md`, step granularity, one PR, items DECIDE F1–F3 · 0a–7b · G1–G10 · eight ⏸ · a ten-line definition of done.
- **Fidelity reference:** the resolved plan above — **audited and resolved** (one blocker cleared, three operator decisions taken live). The checklist's header says so; provenance is honest.
- **Contract applied:** `$HOME/.claude/agents/checklist-writer.md`.
- **Opened:** the checklist in full (from disk, after its one post-save edit to 7b); the resolved plan §0–§13 in full, with `:94`, `:279`, `:304`, `:384` re-read for the findings below; the contract. Spot-checks (5 tool calls): `grep -rc 'import SwiftUI' OneWord/ViewModels` (no matches, so G4 passes today); `FeedbackViewModel.swift:14-17` (Foundation, Observation, FirebaseCore, FirebaseAuth — 5a's grep referent is real); the diff-context windows around the three edit sites (`SettingsView.swift:203-214`, `SignInView.swift:62-72`, `FeedbackViewModel.swift:22-30`) contain none of G1's tokens; `Docs/README.md:184-193` (7b's tick is true: the dossier links the checklist).

## Verdict

**Ready to build** — confidence high.

Every plan step, gate, fork, risk exit and success criterion has a covering item, and every active item carries a done-when that can actually be observed. The three forks are surfaced, not settled; the deferred work is preserved; the plan's tags ride on the items they touch. What remains is one sequencing tension the plan itself carries and a handful of instruments that could be sharpened by hand. Nothing here misdirects the build; hand-patch the Major and the minors in the checklist rather than regenerating it.

## Fidelity map

| Plan section / step | Covering item(s) | Status |
|---|---|---|
| §0 resolution decisions (M1 WebP, M4 in this PR, Q1 price) | header; 0b, 2c; Step 5; 3b-1, 3b-5, 1f FAQ 3 | covered |
| §1 stack, tooling (`firebase-tools`, `webp`, `sips`), CLI absent | header; 0a–0c | covered |
| §2 done-when (200s, widths/schemes, links, alt, in-app links, ASC + consent screen, build + gates) | Definition of done; 4a, 1g/3f, 3e, 5b/5c, 6a–6d, 5d | covered |
| §2 not-doing list | nothing invented against it; 0d and n2 marked as checklist calls | covered |
| §3 site tree, `firebase.json`, `.firebaserc`, `.gitignore` | 1a, 1b | covered |
| §3 app touches: constant beside `address`; Settings row; sign-in link; `FeedbackViewModel` stays Foundation + Observation | 5a, 5b, 5c; G4 | covered (5b placement drifted — Minor 3) |
| §4 tokens, type, `<html lang="en">`, contrast floor, layout, no webfonts, build note | 1c; 1e, G9; 1c; 3f; G7; 3a | covered (1c's instrument weak — Minor 1) |
| §5a six sections, `<picture>` swap, entry from `words.json`, `<head>` metas | 3b-1…3b-6, 3c | covered |
| §5b privacy draft (twelve headings, photo sentences, region-free, retention, third party) | 1e, 1d, G5 | covered |
| §5b App Privacy answers `[Inference]` | 6b | covered, tag carried |
| §5c contact line first, eight FAQs, FAQ 1 `[Unverified]` wording, FAQ 4 path | 1f | covered, tag carried |
| §6 icons, badge licence, covers by folder with alpha, hero captures, Apple ID `[Assumption]`, weight ceiling `[Inference]` | 2a, 2b/G8, 2c, 2d, 2b, 2e | covered, tags carried |
| §7 Step 0 (tools) | 0a–0c, R6/R7 exits | covered |
| §7 Step 1 (scaffold, region check, two pages, emulator) | 1a–1g | covered (1d→1e edge over-tight — Minor 4) |
| §7 Step 2 (assets, weight) | 2a–2e, parallel marked | covered |
| §7 Step 3 (landing, skill, hrefs, alt, headings, responsive, covers dark) | 3a–3f | covered |
| §7 Step 4 (deploy, three 200s) | 4a; 4b/4c from §8 | covered (order vs §11 — Major 1) |
| §7 Step 5 (constant, row, link, build + six gates, manual) | 5a–5d | covered |
| §7 Step 6 (ASC fields, App Privacy, consent screen with domain check `[Unverified]`) | 6a–6d | covered, tag carried |
| §7 Step 7 (`REPO_MAP` row + reference line + synchronized-group fix; README line) | 7a; 7b ticked with evidence | covered |
| §8 test matrix (curl, clean URLs, schemes, covers dark, preview, contrast, keyboard, in-app, build + gates) | 4a, 4b, 1g/3f, 3f, 4c, G9, G9, 5b/5c, 5d | covered |
| §8 "hard to test" (App Review reads support) → contact line first | 1f | covered |
| §9 forks F1–F3 with defaults + flip conditions | DECIDE F1–F3; 5a `blocked-by` F1 | covered, not settled |
| §9 draft copy | 1e, 1f, 3b by reference | covered |
| §10 risks R1–R8 and exits | G5 + ⏸ photo; ⏸ Blaze; G8; 1f; 4a→6a edge; 0c; 0b/2c; 1d/1e | covered |
| §11 sequencing (0→…→7; "privacy and support live before the landing page is polished") | Step order; `blocked-by` edges | **partial** — see Major 1 |
| §12 operator review queue (already-taken decisions) | header | covered |
| §13 remaining: region, OAuth domains, cover rights, photo fetch, Apple ID, Family Sharing, App Privacy category, manual deletion | 1d, 6c, G10, ⏸, 2b/⏸, ⏸, 6b, — | covered; the manual-deletion note is operational, not build work, and rightly has no item |

No plan step is missing. No item adds work the plan did not decide, except the two marked checklist calls (0d, n2) and the sizing instruments noted below.

## Blocking findings

None.

## Major findings

### M1 — 4a waits on the landing page, which the plan said the required pages must not wait on

- **Where:** 4a `blocked-by: 1g, 3f`; Definition of done.
- **What's wrong:** The plan's §11 (`:384`) says "privacy and support are live before the landing page is polished, so the App Store record is never waiting on design." The checklist deploys once, after the full landing-page pass (3f). As written, `/privacy` and `/support` cannot go live until the hero, shelf, responsive and dark passes are all done, which is the wait the plan said it avoided.
- **Evidence:** The plan is the source of the tension: its numbered order is 3 (landing) → 4 (deploy), while its prose promises the two pages first. The checklist followed the numbers and dropped the promise. `cleanUrls` hosting with no `index.html` still serves `/privacy` and `/support`; only `/` would 404, and the Marketing URL is optional in App Store Connect.
- **Fix (minimal):** Split 4a. `4a` deploys as soon as 1g holds (privacy and support live; `/` may 404 or carry a one-line placeholder), `blocked-by: 1g`; `4d` redeploys after 3f with the same three-`curl` done-when. Point 6a's `blocked-by` at 4a, and the Definition of done's first line at 4d. Steps 5 and 6 can then start while Step 3 is still in progress.
- **Severity rationale:** Not a broken order, a slower one; but it delays the very URLs the site exists to provide. Confidence medium: the plan's own numbering supports the checklist's reading, so this may be intentional (Q1).

## Minor findings and nits

1. **1c's done-when cannot see the dark block.** `grep -c '--bg\|…'` counts every `var(--bg)` use as well as the definitions, so "at least 16" is met by a stylesheet with no dark block at all. Fix: `grep -cE '^\s*--(bg|surface|ink|muted|definition|example|rule|hairline):' site/public/style.css` prints `16`.
2. **G1 greps the whole diff, context lines included.** `git diff main -- OneWord | grep -c 'Task {\|@State\|async'` also counts unchanged context and removed lines. Today the three edit windows contain none of those tokens (spot-checked), so it passes, but a later edit nearby would trip it spuriously. Fix: `git diff main -- OneWord | grep '^+' | grep -c 'Task {\|@State\|async'` prints `0`.
3. **5b's placement drifted from the plan and is not marked.** The plan puts the row "after the Email row (`:194-205`)" (`:94`, `:304`); the checklist puts it "after the 'Write a message' button's block", i.e. last in the card. n2 marks the `Link`-wraps-row call but not this one. Fix: either follow the plan (between Email and Write a message, with `rule(t)` on both sides) or add `n3:` and say why last is better.
4. **1d hard-blocks 1e though the plan says the draft is correct without it.** Plan `:279`: "the draft is correct without it." Making a console look a prerequisite for writing the page can stall a build session that lacks console access. Fix: move 1d's edge to `4a` (`blocked-by: 1d` on the first deploy), so the page is written region-free and the region, if wanted, lands before it goes live.
5. **3a's done-when is not observable after the fact.** "The skill is loaded in the session that writes 3b" leaves no trace. It transforms the plan's build note faithfully, so keep it, but tick it in the same sitting as 3b or fold it into 3b's first sub-item.
6. **G3 can fail for a reason the plan never touched.** Xcode sometimes rewrites `project.pbxproj` on open (package resolution, object versions). If the diff is non-empty, the done-when should say: revert it, unless it names a new file. One clause.
7. **2d carries a note from memory, not the plan.** "never `open -n` a second copy and never kill the Xcode run" comes from the operator's live-testing notes. Harmless and useful, but per the contract it should be marked as the checklist's addition (`n`), like 0d.
8. **3b's `<section>` count is a checklist instrument.** The plan says six sections, not six `<section>` tags. Fine as a signal; mark it `n` or say "six `<section>` elements, one per §5a section" so a builder using another element knows to adjust.

## Coverage gaps

None against the plan or the contract: tests are items (§8 → 1g, 3f, 4a–4c, 5b–5d, G9), rigor is gated (G1–G4, G9), the ⏸ section exists and matches the plan's deferred set, the definition of done includes the audit blocker and both project gates, DECIDE items exist for all three forks.

## What the checklist got right

- **Lossless coverage** of a twelve-section plan, including the risks' exits and the §13 residue, with nothing promoted out of ⏸ and nothing invented beyond two marked calls.
- **Forks surfaced, not settled**, and the one item that depends on a fork (5a on F1) says so while the default keeps it unblocked.
- **Tags carried forward** onto the right items: `[Unverified]` on 1d, 1f, 6c; `[Assumption]` on 2b, G10; `[Inference]` on 2e, 6b.
- **Crisp done-whens** where it matters most: three `curl` lines for deploy, a `301` with a `location:` check for clean URLs, `sips` pixel widths for the icons, a file count and a dark-background look for the covers, `** BUILD SUCCEEDED **` plus the six-gate loop for the app edits, `git diff --stat` empties for the untouched targets.
- **Parallelism marked** (2a–2d), the first reversible move named (Step 0), and the deploy-before-App-Store-Connect edge (R5) enforced with `blocked-by`.
- **Provenance and honesty**: the header states the plan's audit trail, the `n` convention flags the checklist's own calls, and 7b is ticked only with evidence that holds.

## Operator questions

- **Q1 — Is one deploy after the landing page intentional?** If submission is not imminent and you would rather ship the site whole, M1 becomes a nit. If the App Store record should get its URLs as early as possible, take M1's split.
- **Q2 — Where does the Privacy Policy row sit?** After Email as the plan says, or last in the card as the checklist wrote it? Either is a one-line change; the checklist should say which and why.

## What would change the verdict

- **To Fix gaps first:** submission is imminent and the two required pages must be live before the landing page exists — then M1 is a must-fix, not a should-fix.
- **To Rebuild the checklist:** nothing found. Hand-patch M1 and Minors 1–4 in place; the rest are optional.
