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
- **Sentence practice** — planned, not built.
  [resolved plan](02_Plan/Resolved/SENTENCE_PRACTICE_PLAN_RESOLVED.md)
  *(plan and audit were worked through in session and never filed — the resolved plan
  carries the audit findings in §1 and stands alone)*
