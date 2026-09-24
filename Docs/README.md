# Docs

Written docs for One Word. Code lives in `OneWord/` — see
[00_Context/REPO_MAP.md](00_Context/REPO_MAP.md).

Top-level folders are **artifact types**, numbered in workflow order. A type that gets
challenged and revised has `Audit/` and `Resolved/` beneath it, so a plan and its audits
sit together instead of being filed apart.

```
Docs/
├── 00_Context/          standing truth — kept current, never archived
├── 01_Brainstorm/       options weighed, nothing committed yet
├── 02_Plan/             the decided approach
│   ├── Audit/           adversarial passes over the plan
│   └── Resolved/        the plan after audit findings are answered
├── 03_Checklist/        the plan decomposed into buildable, checkable items
│   ├── Audit/           adversarial passes over the checklist
│   └── Resolved/        the checklist after audit findings are answered
├── 04_PR/               shipping a change
│   ├── Review/          review findings, and validations of them
│   └── Fixed/           what was actually fixed in response
├── 05_Thoughts/         loose notes, half-ideas, open questions — no format
└── 06_Misc/             anything that fits nowhere above
```

## Where do I save this? (for agents)

| You produced | Save as |
|---|---|
| Options weighed, nothing decided | `01_Brainstorm/<FEATURE>_BRAINSTORM.md` |
| A committed approach | `01_Brainstorm/<FEATURE>_STRATEGY.md` |
| A file-level implementation plan | `02_Plan/<FEATURE>_PLAN.md` |
| An audit of a plan | `02_Plan/Audit/<FEATURE>_PLAN_AUDIT.md` (re-audits: `_R2`, `_R3`) |
| A plan revised to answer its audit | `02_Plan/Resolved/<FEATURE>_PLAN_RESOLVED.md` |
| A build checklist | `03_Checklist/<FEATURE>_CHECKLIST.md` |
| An audit of a checklist | `03_Checklist/Audit/<FEATURE>_CHECKLIST_AUDIT.md` |
| A checklist revised to answer its audit | `03_Checklist/Resolved/<FEATURE>_CHECKLIST_RESOLVED.md` |
| Code-review findings on a change | `04_PR/Review/<FEATURE>_REVIEW.md` |
| A validation of review findings | `04_PR/Review/<FEATURE>_REVIEW_VALIDATION.md` |
| A record of what got fixed and what was declined | `04_PR/Fixed/<FEATURE>_FIXES.md` |
| A rough note or open question | `05_Thoughts/<TOPIC>.md` |
| None of the above | `06_Misc/<TOPIC>.md` |

Which skill lands where:

| Skill | Folder |
|---|---|
| `/brainstorm`, `/strategize` | `01_Brainstorm/` |
| `/plan` | `02_Plan/` |
| `/plan-audit` | `02_Plan/Audit/` |
| `/plan-resolver` | `02_Plan/Resolved/` |
| `/checklist` | `03_Checklist/` |
| `/checklist-audit` | `03_Checklist/Audit/` |
| `/code-review`, `/validate-findings` | `04_PR/Review/` |

## Rules that keep this navigable

- **`<FEATURE>` is the join key.** Same screaming-snake prefix everywhere — the folders split
  a dossier up, and that prefix is the only thing tying it back together.
  `grep -rl RELATED_WORDS Docs/` returns the whole trail.
- **Screaming snake case**, `.md`. `RELATED_WORDS_PLAN.md`, not `related-words-plan.md`.
- **`Resolved/` is a new file, `Audit/` re-runs are a new file.** Never overwrite an audit
  or the plan it challenged — the point is the trail from what was proposed to what survived.
- **Cross-folder links need `../`**, and `../../` from inside `Audit/` or `Resolved/`.
- **Don't refresh stale file paths inside `01`–`06`.** They record what was thought and
  decided at the time. Only `00_Context/` is kept current.
- **Add a line to "Dossiers"** when you start a new feature's docs.

## 00_Context — read these first

- [REPO_MAP.md](00_Context/REPO_MAP.md) — every folder in the repo and what belongs in it.
- [ARCHITECTURE.md](00_Context/ARCHITECTURE.md) — MVVM layers, data flow, where a new file goes.
- [PROJECT_CONTEXT.md](00_Context/PROJECT_CONTEXT.md) — what the app is and why.
- [DESIGN_BRIEF.md](00_Context/DESIGN_BRIEF.md) — the visual language.

## Dossiers

- **Related words** — shipped.
  [brainstorm](01_Brainstorm/RELATED_WORDS_BRAINSTORM.md) →
  [plan](02_Plan/RELATED_WORDS_PLAN.md) ·
  [audit](02_Plan/Audit/RELATED_WORDS_PLAN_AUDIT.md) ·
  [audit r2](02_Plan/Audit/RELATED_WORDS_PLAN_AUDIT_R2.md) →
  [checklist](03_Checklist/RELATED_WORDS_CHECKLIST.md) ·
  [checklist audit](03_Checklist/Audit/RELATED_WORDS_CHECKLIST_AUDIT.md) →
  [review validation](04_PR/Review/RELATED_WORDS_REVIEW_VALIDATION.md)
  *(the plan was revised in place to r4 — predates `Resolved/`)*
- **Startup dictionary** — shipped.
  [brainstorm](01_Brainstorm/STARTUP_DICTIONARY_BRAINSTORM.md)
- **Firebase auth** — planned, not built.
  [plan](02_Plan/FIREBASE_AUTH_PLAN.md) ·
  [audit](02_Plan/Audit/FIREBASE_AUTH_PLAN_AUDIT.md) →
  [resolved plan](02_Plan/Resolved/FIREBASE_AUTH_PLAN_RESOLVED.md)
  *(blockers B1/B2 patched; majors M1/M2 carried forward unpatched — see its §0)*
- **Feedback** — planned, not built.
  [plan](02_Plan/FEEDBACK_PLAN.md) ·
  [audit](02_Plan/Audit/FEEDBACK_PLAN_AUDIT.md) →
  [resolved plan](02_Plan/Resolved/FEEDBACK_PLAN_RESOLVED.md)
  *(email + an in-app note filed to a Firestore `complaints` collection; every audit finding
  resolved — build from the resolved plan, it stands alone)*
- **Themes** — built on `feat/themes` (Steps 1–4: the `Appearance` refactor, Midnight's repaint +
  the popover fix, Umber, these docs); not merged. Build and gates green; the by-eye checks in
  the resolved checklist are still open.
  [brainstorm](01_Brainstorm/THEMES_BRAINSTORM.md) *(written after the plan — it had no
  upstream brainstorm; weighs which themes to ship and argues F1/F2)* →
  [plan](02_Plan/THEMES_PLAN.md) ·
  [audit](02_Plan/Audit/THEMES_PLAN_AUDIT.md) →
  [resolved plan](02_Plan/Resolved/THEMES_PLAN_RESOLVED.md) →
  [checklist](03_Checklist/THEMES_CHECKLIST.md) ·
  [checklist audit](03_Checklist/Audit/THEMES_CHECKLIST_AUDIT.md) →
  [resolved checklist](03_Checklist/Resolved/THEMES_CHECKLIST_RESOLVED.md)
  *(**tick the resolved checklist** — it stands alone. The first checklist has two gates that
  cannot do their job; every new done-when in the resolved one was dry-run against `main`.)*
  *(every audit finding resolved — build from the resolved plan, it stands alone. The
  second theme's pick and name are the one open call; they gate Step 3 only.)*
  *(Midnight repainted near-black with a blue band from the top; a second dark theme, Umber;
  the Midnight flag becomes the `Appearance` so a theme is a `case` and a `static let`)*
- **Themes — the rest of the slate** — planned, not built.
  [brainstorm](01_Brainstorm/THEMES_BRAINSTORM.md) →
  [plan](02_Plan/THEMES_SLATE_PLAN.md) ·
  [audit](02_Plan/Audit/THEMES_SLATE_PLAN_AUDIT.md)
  *(builds the brainstorm's three Tier A items on top of the shipped Themes work: **Paper**,
  a warm light palette; the **widget** finally reading `Theme`; and **High Contrast**, the
  first appearance that resolves by scheme. Each step ships alone.)*
  *(audit: Steps 1–2 ready; **Step 3 needs a rewrite first** — it was written against
  pre-Step-2 code, and its auto-contrast path never reaches the widget)*
- **Sentence practice** — planned, not built.
  [resolved plan](02_Plan/Resolved/SENTENCE_PRACTICE_PLAN_RESOLVED.md)
  *(plan and audit were worked through in session and never filed — the resolved plan
  carries the audit findings in §1 and stands alone)*
- **Premium** — built on `feat/premium` (Steps 1–6 + 8); not merged. Build and all gates green;
  free tier smoke-tested live. Purchase, refund, Ask to Buy and restore still need an Xcode Run
  with `StoreKit/OneWord.storekit`; App Store Connect setup and the sign-in plan gate release.
  [plan](02_Plan/PREMIUM_PLAN.md) ·
  [audit](02_Plan/Audit/PREMIUM_PLAN_AUDIT.md) →
  [resolved plan](02_Plan/Resolved/PREMIUM_PLAN_RESOLVED.md)
  *(Everyday English free; the other seven dictionaries unlock together with one $9.99
  non-consumable Apple in-app purchase, sold from a premium bar under the shelf. Search keeps
  locked words as a teaser. The lock's rules live in `Shared/Premium.swift` so the widget obeys
  them. Grounded in the 2026-09-21 dictionary-lineup scout run.)*
  *(every audit finding resolved — **build from the resolved plan, it stands alone**. Search rows
  hide a locked word's Hindi; the German goal hides until German unlocks. **Release is gated** on a
  separate sign-in plan: Sign in with Apple + in-app account deletion.)*
