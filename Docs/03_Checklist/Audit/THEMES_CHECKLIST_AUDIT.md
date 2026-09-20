# Themes — Checklist Audit

Audit of [THEMES_CHECKLIST.md](../THEMES_CHECKLIST.md) against the plan it derives from,
[THEMES_PLAN_RESOLVED.md](../../02_Plan/Resolved/THEMES_PLAN_RESOLVED.md) — itself **audited
and resolved** — and against the checklist-writer contract. Read-only; nothing built or run.

This audits the **transformation**, not the code: the plan's `file:line` claims were
re-grounded upstream in [THEMES_PLAN_AUDIT.md](../../02_Plan/Audit/THEMES_PLAN_AUDIT.md).
Code was touched only for bounded spot-checks of three done-whens (4 commands).

> **Independence caveat.** Plan, plan audit, checklist and this audit came from one session.
> Every mapping below was re-read rather than trusted, and two gates turned out un-tickable
> (M1, M2) — but `/checklist-audit --report` gives a reader with no memory of the reasoning.

**Opened:** the checklist, all 250 lines · the resolved plan, all sections · the contract ·
spot-checks: `grep` of 2g's done-when as written, `OneWord.entitlements:5-6`,
`project.pbxproj` bundle ids, `git branch --show-current`.

---

## 1. Verdict

**Fix gaps first.** Confidence: high on fidelity, high on the four majors.

Fidelity is strong — no plan step is dropped, no fork was settled, deferred work is intact,
every `[Unverified]` row from plan §8 is tagged on the item it touches. The problem is on the
other axis: **two gates cannot do their job as written.** One can never be ticked (M1); one
passes without checking anything on the branch the repo is on right now (M2). A third makes
the definition of done contradict itself on the likeliest build path (M3). Each is a
one-line fix; none needs the checklist regenerated.

---

## 2. Fidelity map

| Plan | Checklist | |
|---|---|---|
| Step 1 · `Appearance.paintsPalette` | 1a | covered |
| Step 1 · `DoodleTheme` field, `current`, `face`, `tracking`, `Theme.of` | 1b, 1b-i…iii | covered |
| Step 1 · `OneWordApp.swift:34-36` hoist | 1c | covered |
| Step 1 · `sidebar` gains `let t` (audit m1) | 1d | covered |
| Step 1 · `RootView` `:118, :158, :159` | 1e | covered |
| Step 1 · `SettingsView` `page(_:as:)` | 1f | covered |
| Step 1 · "untouched and still compiling" (`Doodles.swift:140`, `.off`, `WordCapture.swift:99`) | — | **missing** (m7) |
| Step 1 · isolation note | G1 | covered, weak done-when (m3) |
| Step 1 · verify | 1g | covered |
| Step 2 · values table | 2a | covered |
| Step 2 · `PaneGround`, overlay, stops, `glow != .clear`, clip order, `opacity(0)`, two facts, local constants | 2c-i…v | covered |
| Step 2 · sidebar paints `PaneGround` | 2d | covered |
| Step 2 · tile miniature | 2e | covered |
| Step 2 · popover (M1) + comment | 2f | covered |
| Step 2 · nine stale comments + `Theme.swift:8` | 2g-i…iv | covered — **done-when cannot hold (M1)** |
| Step 2 · by-eye checks 1–8 | 2h-1…8 | covered, 1:1 |
| Step 3 · `case umber`, palette, `Theme.of` arm, tile arm, grid | 3a–3e | covered |
| Step 3 · verify list (11 points) | 3f-1…6 | covered |
| Step 4 · `DESIGN_BRIEF`, `ARCHITECTURE` + opaque-surface rule | 4a, 4b | covered |
| §5 · `Equatable` synthesis · `PaneGround` compiles in the gate | G7 · 2c done-when | covered |
| §6 · accent @ 50% in Umber · `.isSelected` · no migration | 3f-7 · G8 · G4 | covered |
| §6 · no new file, no `pbxproj`, no `tools/` change | prose in the gates intro | **partial** (nit) |
| §7 · F1, F2 | D-F1, D-F2, both blocking Step 3 | covered — surfaced, not settled |
| §7 · F3 | — | correctly absent (settled by D5) |
| §8 · clip order · sidebar edge · popover — each with its exit | tags on 2c-iii, 2d, 2f + exits under 2h | covered |
| §8 · banding · selection contrast | 2h-8 · ⏸ | covered |
| §8 · **band too quiet / too loud — `glow` and stops are the knobs** | — | **missing** (M4) |
| §8 · Umber is "Dark, but brown" | D-F1 | covered |
| §9 · 1 → {2, 3 independent} → 4 | group headers | covered |
| §10 · Graphite, Moss, no new mechanism, band fields | ⏸ ×3 | covered |
| §11 · M1 inference · three `[Unverified]` · ±2 hex | header + item tags | covered |
| §11 · **`[Inference]` white 7%, tune 0.06–0.09** | — | **missing** (M4) |
| header · never name the product | G5, 2g-v | covered — **vacuous on `main` (M2)** |

**Not in the plan:** 4c (m1), 2b (m2), 2h-9 (kept — see §6).

---

## 3. Blocking findings

None. No load-bearing step is dropped, no dependency is inverted, no fork was settled.

---

## 4. Major findings

**M1 — 2g's done-when can never hold.** It reads
`grep -rn -i "navy\|periwinkle" OneWord` → empty. Run as written today it hits six files,
and one of them is `OneWord/Shared/words.json` — two lines of vocabulary content. After a
perfect comment sweep it still returns those two. The gate is un-tickable, and the tempting
way to tick it is to edit a word list.
**Fix:** `grep -rn -i --include="*.swift" "navy\|periwinkle" OneWord` → empty. *(Five Swift
files hit today — exactly 2g's list.)*
**Inherited:** the same command is the resolved plan's Step 2 verify line, carried from
plan-audit m2. The checklist transcribed it faithfully; the defect is upstream. Correct it
in the revised checklist, not by editing the plan.

**M2 — G5 and G6 pass without checking anything if the work is committed on `main`.** Both
use `git diff main`. The repo is on `main` now (`git branch --show-current`), and no item
creates a branch. Commit Step 1 there and `git diff main` is empty forever — the no-brand
gate and the no-rename gate both go green having looked at nothing.
**Fix:** a **0a** at the top — *branch off `main`; done-when: `git branch --show-current`
is not `main`* — and pin both gates to the base commit, `git diff c5d1ba4 -- …`, which
holds on any branch.

**M3 — the definition of done contradicts itself on the likeliest path.** Line 1 allows
"3f explicitly left for later with D-F1 / D-F2 still open" — and the header says Steps 1, 2
and 4 "can be built today". Line 2 then requires **G1–G8**, but G8 needs the Umber tile
("announces all five names") and G3's second clause needs 3a's failure "observed". Ship
Steps 1 + 2 and the final gate cannot be completed.
**Fix:** mark G8 and G3's second clause *Step 3 only*; DoD line 2 becomes "G1–G7, plus G8
when 3f is checked".

**M4 — two of the plan's tuning prompts were dropped.** Plan §11 tags the new surface
`[Inference]` — "tune by eye between 0.06 and 0.09" — and §8 names `glow` and the three
stops as the knobs if the band is too quiet or too loud. Neither reached the checklist. 2a's
done-when is "the five values read back as written", so a builder ticks it on transcription
and nothing ever asks whether values sampled from a compressed screenshot look right.
**Fix:** two lines under 2h — *tiles read as frosted glass, not grey boxes (tune `surface`
0.06–0.09)* and *the band is neither lost nor loud under a real entry (tune `glow`, stops)*.
Low build impact; ranked major because it is a dropped honesty tag, which the contract
treats as one.

---

## 5. Minor findings & nits

- **m1 — 4c is invented, and already true.** The plan's Step 4 has two docs; `README.md` is
  a third. It follows the project's own rule, so keep it — but its done-when ("lists plan ·
  audit · resolved plan · checklist") holds today, before any work. **Fix:** "the line no
  longer says *planned, not built*".
- **m2 — 2b points at the wrong comment.** It says `Theme.swift:28-30` must stop describing
  "a colour at 0.34 alpha". Those lines never mention alpha and stay true. The 0.34 lives at
  `:93-94`, inside the body 2c replaces wholesale. **Fix:** fold 2b into 2c-v, or reduce it
  to "add *the band's peak colour* to `:28-30`".
- **m3 — two gates check less than they claim.** G1 asserts both types are still
  `nonisolated` and touch no `Theme`; its grep looks at `Appearance.swift` only and never
  checks the keyword. **Fix:** add `grep -n "^nonisolated" Appearance.swift DoodleTheme.swift`
  → two hits. G6 asks `git diff --stat` to show "`\.doodle` churn", which `--stat` cannot.
  **Fix:** `grep -rn "struct DoodleTheme" OneWord` → one hit, and `--stat` lists only the
  seven files Steps 1–3 name — which also turns §6's "no `pbxproj`, no `tools/`" from prose
  into a check.
- **m4 — two dependency edges are wrong.** 1b is `blocked-by: 1a` but needs nothing from it;
  1e uses `paintsPalette` and is not blocked by 1a. Harmless in listed order. Also 1b says
  "the type does not compile alone" — the type does; it is the *target* that is red until 1f.
- **m5 — "covered by 1g / 3f"** on 1c–1f and 3c–3d. Fair for an atomic refactor, but a
  per-item signal exists even in a red build: *`xcodebuild` reports no error in this file*.
- **m6 — 3f-5 names a command without its argument.** The domain is
  `com.hariom.swift.oneword`, and the app is sandboxed (`OneWord.entitlements:5-6`), so the
  value may need to land in the container's plist rather than `~/Library/Preferences`
  `[Unverified]`. **Fix:** give the domain; add "confirm with `defaults read` that the app
  sees it".
- **m7 — the plan's negatives were not carried.** `Doodles.swift:140`, `DoodleTheme.off` and
  `WordCapture.swift:99` "need no edit". Worth one line in 1g: a build-fixer facing a red
  target may "fix" files that were never broken.
- **m8 — no baseline.** 1g asks for "exactly as they did before" and G4 for a Mac "that had
  Midnight picked before". Neither can be checked from memory. **Fix:** fold into 0a —
  screenshot Home and Settings in all four appearances, and leave Midnight selected.
- **Nits.** 2g-v has no signal of its own (it is G5). 2a's "read back as written" is
  circular; 2h is its real signal — say so. Sub-item ids mix `1b-i` and `2h-1`. 2d–2g are
  parallel once 2a and 2c land; not marked.

---

## 6. What the checklist got right

- **Nothing load-bearing is missing.** Every file edit in Steps 1–4 has an item, down to the
  single line at `SettingsView.swift:311`.
- **Forks surfaced, not settled** — D-F1 and D-F2 carry default, alternatives and
  flip-conditions, block Step 3 at its header, and say *why* the call is permanent.
- **Honesty survived the transformation.** All three `[Unverified]` rows from plan §8 sit on
  the item they touch (2c-iii, 2d, 2f), each with its exit printed beside the check that
  would trigger it — a builder who hits the seam does not need the plan open.
- **3a's done-when is a build that fails in exactly two named places.** It turns the plan's
  "the compiler finds every one" from a claim into an observation, and G3 stops a
  build-fixer answering it with `default:`.
- **2h-9** is not in the plan and should stay: it is the only check on 2c-ii's
  `glow != .clear` guard — the one thing standing between this change and Light / Dark.
- The by-eye checks are concrete paths ("Mac in Light, app in Midnight → open any (i)"),
  not "looks right".
- The rigor section opens by naming what this change *does not* have — no `Task`, no
  capture, no migration — rather than padding gates for them.
- The `⏸` section is intact and each entry names its gate; banding is explicitly barred from
  opening the "new mechanism" gate.
- Provenance is stated correctly: audited, resolved, never compiled.

---

## 7. Operator questions

1. **Keep 4c?** It is outside the plan but inside the project's doc rules. Recommended: keep,
   with m1's done-when.
2. **Branch name for 0a** — the last theme branch was `feat/midnight-theme`.
   Recommended: `feat/themes`.

---

## 8. What would change the verdict

- **→ Ready to build** once M1–M3 are patched: three lines, plus 0a. M4 and the minors are
  worth folding into the same pass but would not hold the build on their own.
- **→ Rebuild the checklist** — nothing here points that way; fidelity is intact.
- If the operator builds on `main` deliberately, M2 stands regardless: pin the gates to
  `c5d1ba4`.
