# Themes — the rest of the slate — Plan Audit

Audit of [THEMES_SLATE_PLAN.md](../THEMES_SLATE_PLAN.md) against the working tree at
`5f0b6bd`. Read-only: nothing was built or run. Every `file:line` below was re-opened from
disk for this audit, and every contrast figure recomputed.

> **Independence caveat.** The plan and this audit came from the same session. Citations
> were re-opened rather than trusted, and that turned up a real ordering defect (M1) and a
> wrong count (m1) — but an author's blind spots survive their own review. A fresh auditor
> with no memory of the plan's reasoning would be worth more than this file.

> **Tooling caveat, inherited.** Xcode's MCP file tools served a stale snapshot during the
> plan's authoring. This audit used `Read`/`grep` on disk exclusively. Both agree that the
> Themes plan is built and Umber has shipped.

**Stack, re-verified** — matches the plan: Xcode project, two targets · SwiftUI · MVVM with
`@Observable` · `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` · `@AppStorage` / `UserDefaults`
/ App Group · macOS 14.0 · no XCTest target, gates are `tools/check_*.sh`.

**Opened:** `Theme.swift` (all 172) · `Appearance.swift` (all 50) · `DoodleTheme.swift`
(`:70-110, 140-190`) · `OneWordApp.swift` (all 47) · `AppGroup.swift` (all 49) ·
`RootView.swift:78-170` · `SettingsView.swift:15-80, 105-115, 289-430` ·
`WordWidgetView.swift:1-220` · `Wordbook.swift:1-50` · `Doodles.swift:140` ·
`project.pbxproj:77, 136-160, PBXSourcesBuildPhase` · `tools/check_learned.sh:185-205` ·
`tools/check_capture.sh:113-125` · `tools/check_sentences.sh:1-10`.

---

## 1. Verdict

**Ready to build — Steps 1 and 2 as written; Step 3 needs one rewrite first.** Confidence:
high on Steps 1 and 2, medium on Step 3, medium on the look.

No blocker. Step 1 is four values-only edits and every switch it touches is exhaustive, so
the compiler enforces completeness. Step 2's structural claims all held up under checking —
including the one I most expected to fail (§5, the pbxproj membership question), which
verifies cleanly and can be upgraded from `[Inference]` to fact.

Step 3 is where the plan is weakest, and in a specific way: **it was written against
pre-Step-2 code.** M1 is a genuine internal contradiction, not a wording slip, and M2 is an
overclaimed verification on the exact axis the whole plan is about. Both are cheap to fix
and neither changes a decision.

---

## 2. Blocking findings

None.

---

## 3. Major findings

**M1 — Step 3c edits a `switch` that Step 2b deletes.** *Internal contradiction.*

Step 2b collapses the app-side resolver to a delegate:

> `OneWord/Models/DoodleTheme.swift:169-176` collapses to a delegate:
> `Theme.of(scheme, look.appearance)`.

Step 3c then prescribes:

> `OneWord/Models/DoodleTheme.swift:170` | `case .system: return look.increasedContrast ? … : .of(scheme)`

There is no `case .system` left to edit, and `:170` is the pre-Step-2 line. §9 compounds it
by claiming both *"Step 3 needs nothing from 1 or 2"* and *"Any step ships alone"* — only the
Step-3-before-Step-2 ordering matches the text as written, and §9 recommends the opposite
order.

**Fix.** Step 3c's row becomes a guard in front of the delegate, which works in either
order and is shorter than the switch arm it replaces:

```swift
static func of(_ scheme: ColorScheme, _ look: DoodleTheme) -> Theme {
    // Increase Contrast applies only under .system (D9): picking a palette is an
    // override, and an override should not be silently overridden back.
    if look.appearance == .system, look.increasedContrast {
        return scheme == .dark ? .highContrastDark : .highContrastLight
    }
    return Theme.of(scheme, look.appearance)
}
```

**Why major, not minor:** a builder following §9's order reaches Step 3 and finds its
instructions describe code that no longer exists. That is the failure mode a plan exists to
prevent.

**M2 — auto-contrast never reaches the widget, and Step 3's verification claims it does.**

D10 routes the contrast flag through `DoodleTheme`, which is app-only and deliberately not in
the App Group (Step 2c keeps `iconsKey`/`handwritingKey` in standard defaults for the same
reason). The widget reads `AppGroup.appearance` and nothing else. So under D9 — `.system`
plus the Mac's Increase Contrast — the **app** goes high-contrast and the **widget** stays
normal.

Step 3's verify 6 says:

> Relaunch on High Contrast → it sticks, and the widget (after Step 2) paints it too.

True for an explicitly-picked `.highContrast`. False for the automatic path, which is the
path D9 exists to serve and the one the brainstorm called *"the only theme that helps people
who will never open the picker."* Leaving it is a hairline-invisible widget for exactly the
user the theme is for — the same mismatch class Step 2 is being built to end.

**Fix.** The widget resolves contrast itself. Increase Contrast is a **systemwide** setting,
so unlike the appearance it needs no App Group — `@Environment(\.colorSchemeContrast)` is
available to a widget's view. Two lines in `WordWidgetView`:

```swift
@Environment(\.colorSchemeContrast) private var contrast
// in body, replacing the plain resolve:
let a = AppGroup.appearance
let t = (a == .system && contrast == .increased)
      ? (scheme == .dark ? Theme.highContrastDark : .highContrastLight)
      : Theme.of(scheme, a)
```

That duplicates D9's rule in two places, which is worth avoiding. **Better:** put the rule
on `Theme` itself in Step 2b — `Theme.of(_ scheme:_ contrast: ColorSchemeContrast,_ appearance:)`
— and have both `DoodleTheme.of` and the widget call it. Then M1's guard and this fix are the
same three lines, written once, in the file both targets compile. Recommended: fold this into
Step 2b rather than patching Step 3.

`[Inference — derived from which values cross the process boundary; not run.]`

---

## 4. Minor findings

**m1 — the `Theme.of` call-site count is wrong, in two places.** D10 and §1 both say
**"23 call sites in 14 files."** Actual: **20 in 12 files.**

`grep -rn "Theme\.of(scheme" OneWord OneWordWidget` returns 22 lines; two are prose
(`DoodleTheme.swift:20` and `:186`), so `DoodleTheme.swift` contributes no real call site.
Per file: `RootView` 8 · `WordDetail` 2 · `PaneHeader` 2 · `SettingsView`, `DictionaryPicker`,
`MonthCalendar`, `SentenceView`, `WordListView`, `HomeView`, `LearnedListView`,
`HistoryView`, `ProfileView`, `SignInView` 1 each.

D10's conclusion is unaffected — 20 edits still dwarfs one flag — but a plan whose authority
rests on counted line numbers should have them right.

**m2 — the migration's ordering risk is avoidable, not merely `[Unverified]`.** Step 2c puts
`AppGroup.migrateAppearance()` in `OneWordApp.init()` and §7 files the timing as **High ·
Med `[Unverified]`** — the plan's highest-severity row.

It can be designed away. Fold the migration into `AppGroup.defaults`'s own initializer: the
store cannot be read through without being evaluated, so "did migration run first?" stops
being a question.

```swift
static let defaults: UserDefaults = {
    let d = UserDefaults(suiteName: id) ?? .standard
    // One-time lift out of standard defaults, where the appearance lived until the
    // widget started reading it. Here rather than at app launch because nothing can
    // read through this store without first evaluating it — no ordering to get wrong.
    if d.object(forKey: appearanceKey) == nil,
       let old = UserDefaults.standard.string(forKey: appearanceKey) {
        d.set(old, forKey: appearanceKey)
    }
    return d
}()
```

The `let` (not `var`) reasoning at `AppGroup.swift:28-31` still holds — one container open
for the life of the process, and now one migration check with it. Drop the §7 row.

Note the benign case the plan already gets right: if the group is unprovisioned, `defaults`
falls back to `.standard` (`AppGroup.swift:35`), the guard finds the key present, and the
migration no-ops.

**m3 — Steps 1 and 3 list no comment rewrites.** The previous round enumerated every comment
its change falsified and added a `grep` to prove it. This plan keeps that discipline in Step
2e and drops it in Steps 1 and 3. False or incomplete after Step 1:

- `Appearance.swift:5-10` — the header names only `.midnight` and `.umber`.
- `Theme.swift:5-13` — *"Umber is **the other** painted palette"*. Paper makes it a third.
- `RootView.swift:157-160` — *"Light and Dark keep the material"* stays true, but *"a painted
  appearance"* now includes a **light** one, which is the comment's unstated assumption.

And after Step 3:

- `Theme.swift:25` — `// emphasis — ink, not a hue (Midnight's is a light blue)`. Already
  half-stale since Umber; High Contrast is the case where accent genuinely *is* ink again.

**Fix:** one row per step, and reuse the previous round's trick — a `grep` that must come
back empty.

**m4 — the popover citation is off by a line, and the fix already shipped.** Step 1 verify 2
says *"the fix at `SettingsView.swift:317` should already carry it."* It is at **`:317-318`**:

```
:317                .background(theme.surface)
:318                .background(theme.background)
```

So last round's M1 fix is in. Paper's `surface` is opaque, which makes this check a formality
— keep it, but say that, so a builder doesn't read a passing check as evidence of anything.

**m5 — `ContrastAware`'s wiring is under-specified in a way that would silently drop the
flag.** §3c says only *"Wrap `RootView()` in a small `ContrastAware` view."* But
`OneWordApp.swift:37-38` currently injects `\.doodle` **outside** where the wrapper would
sit. If that injection stays, it wins, and `increasedContrast` is never seen. The existing
`.environment(\.doodle, DoodleTheme(…))` must **move inside** `ContrastAware`, with
`.preferredColorScheme(look.colorScheme)` (`:39`) staying outside. One sentence, but the
failure is silent — the theme just never activates.

**m6 — High Contrast's surface separation is ordinary, not high.** The plan gives
`surface #F0F0F0` on `background #FFFFFF`: **1.14:1**.

Recomputed against the rest of the app, that is *not* an outlier — Light is 1.10, Dark 1.21,
Umber 1.08, Paper 1.09 — and the 40% hairline is doing the structural work the theme exists
for. So this is not a defect. But it is a free win the plan should have argued one way or the
other:

| surface | vs ground | `ink` on it |
|---|---|---|
| `#F0F0F0` / `#141414` (as planned) | 1.14 / 1.14 | 18.43 / 18.42 |
| **`#E8E8E8` / `#1F1F1F`** | **1.23 / 1.27** | 17.14 / 16.48 |

The second pair matches Dark's separation, stays far above AAA, and costs two hex digits.

---

## 5. Claims checked and found sound

Recorded because they were the plan's riskiest assertions, and because the plan marks two of
them weaker than they deserve.

**The pbxproj claim verifies — upgrade it from `[Inference]`.** §11 hedges that moving
`Appearance.swift` within the app's synchronized group keeps its app membership. Confirmed
structurally: there are exactly two `PBXSourcesBuildPhase` entries, and the app's
(`BFCC5B52…`) has `files = ()` — **empty**. The app is entirely synchronized-group driven;
the `SharedRefs` group's explicit references feed only the widget's phase (`442CD88A…`, 11
files, including `Theme.swift` and `AppGroup.swift`). So adding `Appearance.swift` to
`SharedRefs` **and** the widget's phase creates no duplicate app membership and no
duplicate-symbol risk. Step 2a is correct as written, and the §7 "do it in Xcode's UI"
caution is still the right advice for a three-section edit with generated UUIDs.

**The gate-script claim verifies, and it is exactly one script.** Only
`check_learned.sh:194` compiles `Theme.swift`. `check_capture.sh:115-117` compiles
`Word.swift`, `WordProvider.swift`, `WordSelectionStore.swift`, `SavedWords.swift` and its
own shims — no `Theme`, no `Appearance`, no `DoodleTheme`. `check_sentences.sh:7` compiles
`Sentences.swift` alone. `Appearance.swift` is a `nonisolated enum` importing only SwiftUI,
which `check_learned.sh` already provides, so it compiles under that script's
`-default-isolation MainActor`.

**The overload is unambiguous.** `Theme.of(ColorScheme, Appearance)` alongside the existing
`Theme.of(ColorScheme, DoodleTheme)` resolves on the second argument's type, and all 20
call sites pass `doodle`. (If M2's recommended three-argument form is adopted instead, this
stops mattering.)

**`Doodles.swift:140` survives Step 3.** It builds `DoodleTheme(icons: on, handwriting: on)`
with labels, so a fourth member with a default is additive. Same for
`DoodleTheme.swift:85` (`.off`) and `:95` (`current`).

**Step 2d's "not pixel-identical, on purpose" is accurate.** `Theme.light.background` is
literally `.white` (`Theme.swift:43`) and `.dark`'s is `.black` (`:55`), so the System /
Light / Dark grounds really are unchanged; only the ink ramp moves. The plan is right to
name this rather than claim a no-op.

---

## 6. Coverage gaps

**G1 — `tools/check_sentences.sh` is not in the gate loop.** Five scripts exist; `CLAUDE.md`'s
loop and this plan's §9 both name four. Nothing in this plan touches `Sentences.swift`, so it
is not a defect here — flagged once so it is not later discovered as one.

**G2 — D9's side effects on the shell are not named.** Under `.system` + Increase Contrast,
`DoodleTheme.paintsPalette` flips true, and two things follow at `RootView.swift:118,161-162`:
the sidebar loses its stock grey material for a flat painted ground, and `.tint` becomes
**pure black or pure white**. That is the intent, but it is a large, unrequested-looking
change triggered by a system accessibility toggle, and a pure-black tint on stock macOS
controls is unusual enough to want a look. Add a by-eye item to Step 3.

**G3 — Step 1 leaves a knowingly mismatched intermediate state and does not say so.** Ship
Paper without Step 2 and a Paper user gets a stark white widget beside a cream app — the
§3 problem, newly worsened by the step that precedes the fix. The ordering is still right
(Paper is the cheapest win and Step 2 wants a light painted theme to test against), but the
plan should state the intermediate cost rather than let it surface as a bug report.

---

## 7. Questions for the operator

**Q1 — F2: does High Contrast ship, or just its hairlines?** Sharper after this audit. Step 3
carries both major findings and all three of the plan's remaining `[Unverified]`s, while its
fork F2 — *raise every theme's `hairline` from ~11% to ~20%, one number per palette* — fixes
the 1.2:1 invisible-hairline defect for **every** user rather than for whoever finds the
switch, and needs no new case, no `ContrastAware`, no widget rule, and no `paintsPalette`
move. If Step 3 is likely to slip, F2 is not the consolation prize the plan frames it as; it
may be the better first move, with the full theme following.

**Q2 — F1 stands unchanged.** Paper vs Sepia vs Manuscript. Nothing in this audit bears on
it; §4's contrast table holds for Paper as specified.

---

## 8. Summary

| # | Finding | Type | Fix size |
|---|---|---|---|
| M1 | Step 3c edits a `switch` Step 2b deletes | Major — contradiction | 1 function, shorter than what it replaces |
| M2 | Auto-contrast never reaches the widget; verify 6 overclaims | Major — correctness | 3 lines, best folded into Step 2b |
| m1 | "23 call sites in 14 files" → **20 in 12** | Minor — accuracy | two numbers |
| m2 | Migration ordering is designable-away, not `[Unverified]` | Minor — design | move 4 lines into `AppGroup.defaults` |
| m3 | Steps 1 and 3 list no comment rewrites | Minor — discipline | one row per step |
| m4 | Popover citation `:317` → `:317-318`; fix already shipped | Minor — accuracy | one line |
| m5 | `ContrastAware` wiring would silently drop the flag | Minor — precision | one sentence |
| m6 | High Contrast's `surface` separation is ordinary (1.14) | Minor — taste, with numbers | two hex digits |
| G1 | `check_sentences.sh` outside the gate loop | Gap — pre-existing | note only |
| G2 | D9's sidebar/tint side effects unnamed | Gap | one by-eye item |
| G3 | Paper-without-widget mismatch unstated | Gap | one sentence |

**2 major · 6 minor · 3 gaps · 2 operator questions.** All eight findings land in the plan's
text, not its decisions: no decision D1–D11 is overturned, and the palettes in §4 and §3a
survive recomputation unchanged.
