# Themes — Plan Audit

Audit of [THEMES_PLAN.md](../THEMES_PLAN.md) against `main` at `c5d1ba4`. Read-only: nothing
was built or run. Every `file:line` below was re-opened for this audit.

> **Independence caveat.** The plan and this audit came from the same session. The
> citations were re-opened rather than trusted and that did turn up errors (§3), but an
> author's blind spots survive their own review. `/plan-audit --report` runs a fresh
> auditor with no memory of the plan's reasoning.

**Stack, re-verified** — matches the plan on every point: Xcode project, two targets, no
dependencies · SwiftUI · `SWIFT_VERSION = 5.0` with `SWIFT_DEFAULT_ACTOR_ISOLATION =
MainActor` on both targets (`project.pbxproj:367,394,550,587`) · macOS 14.0 · no XCTest
target, gates are `tools/check_*.sh`.

**Opened:** `Theme.swift` (all) · `Appearance.swift` (all) · `DoodleTheme.swift` (all) ·
`OneWordApp.swift:14-44` · `RootView.swift:70-200` · `SettingsView.swift:45-70, 196-262,
286-415` · `PaneHeader.swift:1-130` · `WordDetail.swift:40-50, 320-350` ·
`WordCapture.swift:84-150` · `WordWidgetView.swift:45-70` · `HomeView.swift:20-50` ·
`WordListView.swift:36-80` · `check_learned.sh:185-200` · `check_capture.sh:116-117`.

---

## 1. Verdict

**Ready to build — after four small corrections to the plan text.** Confidence: medium-high
on the code, medium on the look.

No blocker. The refactor is sound, every wiring point is covered, the isolation reasoning
holds, and nothing proposed is unavailable on macOS 14. The one place the plan contradicts
the code (m1) is a missing `let`. The real uncertainty is visual — whether the band lines up
at two seams — and the plan already marks both `[Unverified]` with a working fallback for
each. That is the right shape for something only a running app can answer.

---

## 2. Blocking findings

None.

---

## 3. Major findings

**M1 — the (i) popover goes unreadable on a Light-mode Mac, and the repaint makes it a
little worse.** *Pre-existing; adjacent to Step 2.*
`SettingsView.swift:302-311` paints the popover with `.background(theme.surface)` and
`theme.ink` text, and its own comment gives the reason: a popover "doesn't inherit the
app's appearance override". That fix relies on `surface` being **opaque** — true for Light
(`#F4F4F4`) and Dark (`#1A1A1A`), false for Midnight (`white 9%`, `Theme.swift:67`). With
the Mac in Light and the app in Midnight, 9% white lands on a light system popover and
`#FBFBFC` text sits on near-white. Step 2 drops the alpha to 7%.
`[Inference — follows from the code and the comment's own premise; not run.]`
**Fix:** one line in Step 2 — `.background(theme.surface).background(theme.background)` at
`:311`. Umber is unaffected (opaque surface), which is worth a sentence in the plan: opaque
surfaces are the safer default for any future theme.
**Why major, not minor:** it is a readable-text failure on a common configuration, and the
plan edits the exact token that causes it.

---

## 4. Minor findings

**m1 — `t` is not in scope where the plan uses it.** Step 1's table says
`Theme.midnight.background → t.background` at `RootView.swift:159`, and Step 2 says the
sidebar paints `PaneGround(t: t)`. Both are inside `var sidebar` (`:134-167`), which has no
`t` — that local belongs to `shell` (`:107`). As written it would not compile.
**Fix:** `Theme.of(scheme, doodle)` inline, which `:160` already does two lines down, or a
`let t` at the top of `sidebar`. *The only confirmed contradiction between plan and code.*

**m2 — stale comments the plan does not list.** Step 2 names `Theme.swift` and
`Appearance.swift`. "Navy" and "periwinkle" also appear at `DoodleTheme.swift:78, 141, 161`,
`RootView.swift:116, 156`, `DictionaryPicker.swift:64`. `:141` is a *reason* ("reads thin
set light-on-navy") and stays true on near-black — reword, don't delete.
**Fix:** add `grep -rn -i "navy\|periwinkle" OneWord` → empty to Step 2's verify.

**m3 — a false comment in the file being edited.** `Theme.swift:8` says "The widget resolves
`Theme.of(colorScheme)`." It does not — no file in `OneWordWidget/` mentions `Theme`
(`WordWidgetView.swift:67` paints `.black` / `.white`). The plan's §1 has this right; Step 2
rewrites `:5-8` anyway, so correct it in the same pass.

**m4 — banding is an unstated risk.** A 330pt ramp across ~63 levels of blue is a ~5pt step
per level — the textbook case for visible stripes on an 8-bit panel. Today's dome covers a
similar range (27→92 over 560pt) without complaint, and Mac window backing is usually deeper
than 8-bit, so: low likelihood `[Inference]`.
**Fix:** one row in §8 and one by-eye check on an external display. Exit: accept, or a faint
static grain — which §10 rightly refuses to build speculatively.

**m5 — citation drift.** `paneBackground` has 11 call sites *including* `PaneHeader` — 10
panes, not "11 panes and `PaneHeader`". The second `Appearance` parse is
`OneWordApp.swift:36`, not `:37`. `entryBlock` is declared at `WordDetail.swift:333`
(`:332` is its `@ViewBuilder`). None changes a step.

---

## 5. Coverage gaps

- **`DoodleTheme` is now a misnomer** — it has carried Midnight since `:10-13` said "Not a
  doodle", and will carry every appearance. The plan is right not to rename it (34 `face(`
  call sites read `\.doodle`), but should say that out loud so nobody does it mid-build.
- **The sidebar divider over the band.** `NavigationSplitView` draws its own separator; over
  navy it disappears, over `#15204E` it may not. One more line for Step 2's by-eye list.
- Nothing else. No persistence migration is needed (D3 keeps the raw value, and
  `?? .system` at `OneWordApp.swift:36` already absorbs an unknown string). No async, no
  captures, no new files, no target membership, no entitlements.

---

## 6. What the plan got right

- **D2 is correct and load-bearing.** `check_learned.sh:194` does compile `Theme.swift` by
  path; no gate compiles `Appearance.swift` or `DoodleTheme.swift`
  (`check_capture.sh:116-117` names neither). A reference to `Appearance` inside `Theme.swift`
  would break that gate *and* the widget target. Keeping resolution in
  `DoodleTheme.swift:164` avoids both.
- **Every wiring point is found.** All 10 sites that set or read the flag are in Step 1's
  table. The two `DoodleTheme(...)` constructions outside it — `Doodles.swift:140` and
  `DoodleTheme.off` — never pass `midnight:` and compile unchanged. The capture HUD
  (`WordCapture.swift:99`) reads only `face()` and paints `.regularMaterial`, so
  `DoodleTheme.current` is its whole exposure, and that is covered.
- **The band carries no new alignment risk.** It needs exactly what the dome needs today —
  header ground and pane ground sharing a top edge (`PaneHeader.swift:22-24`). The *new*
  risk is overflow, and the plan's `.clipped()` is the answer to it. The point-sized,
  y-only reasoning in §3 is sound, and it also fixes something the plan did not claim: the
  dome re-centres while the sidebar folds (`PaneHeader.swift:55`); a band cannot.
- **`t.glow.opacity(0)`, not `.clear`,** as the far stop — avoids the grey fringe.
- **Exhaustive switches with no `default`** turn "add a theme" into a compiler checklist.
- **The isolation note is right to be conservative.** `paintsPalette` touches no `Theme`,
  so the question of MainActor statics from a `nonisolated` enum never arises.
- **Umber's palette omits `roundness`, `glow`, `tiles`** — matches how `.light` and `.dark`
  are already written (`Theme.swift:38-60`).
- **"No unit test" is justified**, not lazy: there is no branch the compiler does not
  already check.
- Risks are rated with severity and confidence apart, and each has a real exit.

---

## 7. Operator questions

1. **Fix M1 inside this change, or separately?** It predates the plan. Recommended: inside —
   one line, in a file Step 2 already opens.
2. **F1 and F2 (which theme, what name) are still open.** Step 1 and Step 2 do not depend on
   them; Step 3 does, and the name is permanent once shipped (D3).

---

## 8. What would change the verdict

- **→ Fix blockers first** if a build shows `.clipped().ignoresSafeArea()` leaves the ground
  short of the window top *and* swapping the order does not cure it. The plan's dome
  fallback then becomes the design and §3 of the plan needs rewriting.
- **→ Needs rework** only if the operator rejects a y-only band on sight. Everything else
  in the plan survives that.
- Stays **Ready** regardless of how F1/F2 land.
