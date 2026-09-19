# Themes — Build Checklist

Derived from [THEMES_PLAN_RESOLVED.md](../02_Plan/Resolved/THEMES_PLAN_RESOLVED.md). The plan is
**audited and resolved**: [one audit round](../02_Plan/Audit/THEMES_PLAN_AUDIT.md), verdict
*Ready to build*, all nine findings folded in. This checklist is a faithful transformation of
that plan — it adds no scope and re-verifies none of its claims.

**Stack** (per plan header): macOS 14.0, SwiftUI, `@Observable` MVVM, Swift 5 language mode
with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on both targets (load-bearing — gate G1), no
test target (standalone `tools/check_*.sh`), no dependencies.

**Sizing peek** (not an audit): none beyond what the plan and audit already opened — every
file below was read in full or by span while they were written.

Carried forward from plan §11: `[Unverified]` **nothing here was ever compiled or run.** The
`.clipped()` / `.ignoresSafeArea()` order (2c), the sidebar's top edge (2d) and the popover
fix (2f) each need a build and a look — items 2h-1, 2h-2 and 2h-7 are their verification,
and plan §8 has an exit for each. `[Inference]` the popover bug itself was derived from the
code, never observed. `[Assumption]` every measured hex is ±2 levels.

**One fork is still open** (plan §7) and gates Step 3 only — see **DECIDE**. Steps 1, 2 and 4
can be built today.

## How to use

`- [ ]` todo · `- [x]` done · `blocked-by:` must be checked first · `DECIDE:` operator call ·
`⏸` deferred by design. **One rule: never check an item until its done-when holds.** Items are
in build order (plan §9). "Builds + gates" always means both commands at the foot of this file.

Steps 2 and 3 are independent of each other — either can be picked up once Step 1 is done.

## Checklist

### Step 1 — the flag becomes the appearance *(refactor; pixel-identical — unblocks 2 and 3)*

- [ ] **1a** Add `var paintsPalette: Bool` to `Appearance` — `true` for `.midnight`, `false`
  for the rest; **exhaustive `switch`, no `default`** — files: `OneWord/Models/Appearance.swift`
  · isolation: stays `nonisolated`, touches no `Theme` (G1) · **done-when:** builds.
- [ ] **1b** In `DoodleTheme`, replace `var midnight = false` (`:79`) with
  `var appearance: Appearance = .system` — files: `OneWord/Models/DoodleTheme.swift` ·
  blocked-by: 1a · **done-when:** covered by 1g (the type does not compile alone until
  1c–1f land).
  - [ ] **1b-i** `current` (`:92-97`) parses
    `Appearance(rawValue: UserDefaults.standard.string(forKey: "appearance") ?? "") ?? .system`.
  - [ ] **1b-ii** `face` (`:140`) and `tracking` (`:154`) test `appearance == .midnight`.
    Handwriting still outranks it — order of the two `if`s unchanged.
  - [ ] **1b-iii** `Theme.of(_:_:)` (`:164`) becomes an **exhaustive** `switch look.appearance`
    — `.midnight → .midnight`; `.system, .light, .dark → .of(scheme)`. It stays in this file's
    `extension Theme`, **not** `Theme.swift` (G2).
- [ ] **1c** `OneWordApp.swift:34-36` — hoist `Appearance(rawValue: appearance) ?? .system`
  to one `let`; pass it as `appearance:` at `:34`, read `.colorScheme` from it at `:36` —
  blocked-by: 1b · **done-when:** covered by 1g.
- [ ] **1d** `RootView.swift` — give `var sidebar` (`:134`) a first line
  `let t = Theme.of(scheme, doodle)` and an explicit `return`, the shape `shell` has at
  `:107-108` *(audit m1: `t` is not in scope there today)* — blocked-by: 1b · **done-when:**
  covered by 1g.
- [ ] **1e** Same file — `:118`, `:158`, `:159`: `doodle.midnight` →
  `doodle.appearance.paintsPalette`; `Theme.midnight.background` → `t.background`; `:160` may
  take `t` too — blocked-by: 1d · **done-when:** covered by 1g.
- [ ] **1f** `SettingsView.swift:385-399` — `page(_:midnight:)` →
  `page(_ t: Theme, as mode: Appearance)`, setting `look.appearance = mode`; `.system` draws
  `page(.light, as: .light)` beside `page(.dark, as: .dark)` — blocked-by: 1b · **done-when:**
  covered by 1g.
- [ ] **1g** **Step 1 gate** — blocked-by: 1a–1f · **done-when:** builds + gates green;
  `grep -rn "doodle\.midnight\|look\.midnight" OneWord` → empty; **by eye:** System, Light,
  Dark and Midnight each look exactly as they did before, and each Settings tile still draws
  in its own face (Midnight's in the sans). *First reversible move — nothing on screen has
  changed.*

### Step 2 — repaint Midnight, and fix the popover *(blocked-by: 1g)*

- [ ] **2a** `Theme.midnight` values (`Theme.swift:65-78`): `background #0F0F0F` ·
  `surface` white **7%** · `accent #A8C7FA` · `rule` accent 60% · `glow #15204E`. Ink, muted,
  definition, example, hairline, `roundness 2.2`, `tiles` — **unchanged** — files:
  `OneWord/Shared/Theme.swift` · **done-when:** builds; the five values read back as written.
- [ ] **2b** Rewrite the `glow` doc comment (`:28-30`): it is now the band's **peak colour,
  opaque at the top edge**, no longer a colour at 0.34 alpha — blocked-by: 2a · **done-when:**
  comment matches 2c's code.
- [ ] **2c** Replace `paneBackground`'s body (`Theme.swift:88-101`) — blocked-by: 2a ·
  **done-when:** builds + gates (`check_learned.sh` compiles this file by path — G2); visual
  proof is 2h-1, 2h-4, 2h-5.
  - [ ] **2c-i** New `struct PaneGround: View { let t: Theme }` in the same file;
    `paneBackground` becomes `background { PaneGround(t: t) }`.
  - [ ] **2c-ii** Body: `t.background`, then `.overlay(alignment: .top)` holding
    `LinearGradient(stops:)` — `t.glow @ 0` → `t.glow.opacity(0.5) @ 0.45` →
    `t.glow.opacity(0) @ 1`, top to bottom, `.frame(height: 330)` — **drawn only when
    `t.glow != .clear`**.
  - [ ] **2c-iii** Then `.clipped()`, then `.ignoresSafeArea()`, in that order
    `[Unverified — plan §8 row 1]`. **The clip is load-bearing:** without it the 330pt band
    spills out of the 52pt header over the scrolling content.
  - [ ] **2c-iv** Far stop is `t.glow.opacity(0)`, **not** `.clear` (grey fringe).
  - [ ] **2c-v** Keep the two facts the old comment recorded: the ground is *under* the
    content, and it is plain alpha with **no blend mode**. `330` and the stops stay local
    constants.
- [ ] **2d** `RootView.swift:158-159` — the sidebar paints `PaneGround(t: t)` inside a
  `.background { }` when `paintsPalette`, in place of the flat colour; keeps
  `.scrollContentBackground(.hidden)` on the same condition — blocked-by: 1d, 2c ·
  **done-when:** builds; visual proof is 2h-2, 2h-3 `[Unverified — plan §8 row 2]`.
- [ ] **2e** `SettingsView.swift:408` — the tile's `page` paints `t.background` with a
  top-to-bottom `t.glow → t.glow.opacity(0)` gradient over it when `t.glow != .clear` —
  blocked-by: 1f, 2a · **done-when:** builds; visual proof is 2h-6.
- [ ] **2f** **Popover (audit M1)** — `SettingsView.swift:311`: `.background(theme.surface)`
  → `.background(theme.surface).background(theme.background)`; extend the comment at
  `:302-303` to say the surface must be opaque here and why — blocked-by: 2a ·
  **done-when:** builds; visual proof is 2h-7 `[Inference — bug derived, never observed]`.
- [ ] **2g** Comment sweep — rewrite each to what is now true — blocked-by: 2a ·
  **done-when:** `grep -rn -i "navy\|periwinkle" OneWord` → empty, and `Theme.swift:8` no
  longer claims the widget resolves a `Theme`.
  - [ ] **2g-i** `Theme.swift:5-8` (incl. `:8`, *never true* — audit m3) and `:62-64`.
  - [ ] **2g-ii** `Appearance.swift:6-8`.
  - [ ] **2g-iii** `DoodleTheme.swift:78`, `:161`. At `:141` **reword, don't delete**:
    "light-on-navy" → "light-on-dark" — the reason still holds.
  - [ ] **2g-iv** `RootView.swift:116`, `:156`. `DictionaryPicker.swift:64`.
  - [ ] **2g-v** Nothing anywhere names the reference product (G5).
- [ ] **2h** **Step 2 gate — by eye.** The build cannot see any of this — blocked-by: 2a–2g ·
  **done-when:** builds + gates green **and** every sub-item below holds.
  - [ ] **2h-1** Home, scrolled: no line where the header strip meets the pane.
  - [ ] **2h-2** The band meets itself across the sidebar at the same y — sidebar open, and
    while it folds.
  - [ ] **2h-3** The split view's own divider over the band does not read as a dark line
    through the blue.
  - [ ] **2h-4** Full screen: band starts at the very top, no grey strip.
  - [ ] **2h-5** A list pane (Search, Bookmarks): rows stay clear over the band.
  - [ ] **2h-6** Dictionaries: spines and shadows read on `#0F0F0F`. Settings: the Midnight
    tile shows a small band.
  - [ ] **2h-7** **Mac in Light, app in Midnight → open any (i) in Settings: dark card,
    legible text.** Repeat with the Mac in Dark.
  - [ ] **2h-8** On an external display if one is to hand: no horizontal stripes in the band.
  - [ ] **2h-9** Light, Dark and System are untouched by any of it.

  *If 2h-1 or 2h-4 fails:* swap 2c-iii's order; failing that, plan §8's dome fallback
  (`RadialGradient(center: .top)`, new colours, `endRadius ≈ 900`) — and plan §3 then needs
  rewriting. *If 2h-2 fails:* sidebar back to flat `t.background`, soften by starting the
  band at 0.8. *If 2h-7 fails:* `.presentationBackground(theme.background)` (macOS 13.3+).

### Step 3 — Umber *(blocked-by: 1g, **D-F1**, **D-F2**)*

- [ ] **3a** `Appearance` gains `case umber` — `name → "Umber"`, `colorScheme → .dark`,
  `paintsPalette → true` — files: `OneWord/Models/Appearance.swift` · **done-when:** the
  build **fails**, naming exactly `Theme.of` (3c) and `AppearanceTile.preview` (3d) as
  non-exhaustive. That failure is the proof Step 1's switches do their job; anything else
  failing is a surprise worth reading.
- [ ] **3b** `static let umber` in `Theme.swift`, beside `midnight` — `background #161412` ·
  `surface #1F1C19` · `ink #EDE6DA` · `muted #9C9284` · `definition #DDD5C8` ·
  `example #B9AFA0` · `accent #D0A667` · `rule #D0A667 @ 55%` · `hairline #EDE6DA @ 10%`.
  **Omit** `roundness`, `glow`, `tiles` — the defaults are the design, as `.light` and
  `.dark` do (`:38-60`) — **done-when:** compiles in isolation (`check_learned.sh` green).
- [ ] **3c** One arm in `Theme.of` (`DoodleTheme.swift:164`): `.umber → .umber`. `face` and
  `tracking` untouched — Umber falls through to the serif — blocked-by: 3a, 3b ·
  **done-when:** covered by 3f.
- [ ] **3d** `SettingsView.swift:385` — `preview` gains
  `case .umber: page(.umber, as: .umber)` — blocked-by: 3a, 3b · **done-when:** covered by 3f.
- [ ] **3e** `SettingsView.swift:53` — picker `HStack(spacing: 10)` →
  `LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10)` —
  **done-when:** builds; five tiles sit on **one row** at the default window size, and wrap
  rather than truncate when the window is narrowed.
- [ ] **3f** **Step 3 gate** — blocked-by: 3a–3e · **done-when:** builds + gates green, and
  by eye with Umber picked:
  - [ ] **3f-1** Serif headword, hairline sections (no tiles), square corners, **flat ground
    with no band**.
  - [ ] **3f-2** Brass Hindi rule, brass switches, warm sidebar matching the pane.
  - [ ] **3f-3** Handwriting on → the marker face wins, the palette stays.
  - [ ] **3f-4** Quit and relaunch → Umber sticks.
  - [ ] **3f-5** `defaults write` a junk `appearance` string → the app opens in System.
  - [ ] **3f-6** An (i) popover reads, Mac in Light and in Dark.
  - [ ] **3f-7** The 52pt empty-state glyph (Bookmarks, empty) is not too faint — it is
    `accent @ 50%`, 2.9:1, the weakest pair in the plan (§6). Nudge the brass lighter if so.

### Step 4 — standing docs *(blocked-by: 2h; the Umber lines wait for 3f)*

- [ ] **4a** `Docs/00_Context/DESIGN_BRIEF.md` §3 / §8 — replace "a light + dark theme" with
  the looks that exist and what each is for — **done-when:** the brief names every case in
  `Appearance`, and no more.
- [ ] **4b** `Docs/00_Context/ARCHITECTURE.md` — an "adding a theme" note: one `case`, one
  `static let`, the compiler lists the rest; **opaque `surface` unless there is a reason not
  to** — **done-when:** a reader could add a theme from that note alone.
- [ ] **4c** `Docs/README.md` dossier line → "shipped", with this checklist linked —
  **done-when:** the Themes line lists plan · audit · resolved plan · checklist.

## Rigor gates — check before merging

Nothing here is async: no `Task`, no capture list, no migration, no new file, no target
membership. These are the gates the plan *does* have.

- [ ] **G1 Isolation.** `Appearance` and `DoodleTheme` are still `nonisolated`, and neither
  returns nor touches a `Theme`. Palette resolution lives only in `Theme.of(_:_:)` —
  **done-when:** `grep -n "Theme" OneWord/Models/Appearance.swift` shows comments only.
- [ ] **G2 `Theme.swift` stays shareable.** It names no `Appearance`, no `DoodleTheme`, no
  app-only type — it is compiled into the widget and into `check_learned.sh:194` by path —
  **done-when:** `grep -n "Appearance\|DoodleTheme" OneWord/Shared/Theme.swift` shows
  comments only; the widget target builds.
- [ ] **G3 No `default:`** in any `switch` over `Appearance` — **done-when:**
  `grep -n "default:" OneWord/Models/Appearance.swift OneWord/Models/DoodleTheme.swift` →
  nothing inside those switches; 3a's expected failure was observed.
- [ ] **G4 Stored value.** The raw value is still `"midnight"`; no case was renamed —
  **done-when:** a Mac that had Midnight picked before the change opens in Midnight after it.
- [ ] **G5 No brand.** No theme, symbol, comment or doc names the reference product or
  borrows its marks — **done-when:** `git diff main -- OneWord Docs/00_Context | grep -i "^+.*\(gemini\|google\|offsuit\)"`
  → empty. *(Diff-scoped on purpose: the app has Google sign-in, so a repo-wide grep is never
  clean.)*
- [ ] **G6 `DoodleTheme` was not renamed** (plan §1) — **done-when:** `git diff --stat` shows
  no file rename and no `\.doodle` churn beyond Step 1's sites.
- [ ] **G7 `Equatable` by synthesis** still holds on `DoodleTheme` — **done-when:** no
  hand-written `==`; toggling a Doodle switch still animates `DoodleSample`.
- [ ] **G8 Accessibility.** The Umber tile reads "Umber" and carries `.isSelected` when
  picked (it inherits both from `AppearanceTile` — confirm, don't add) — **done-when:**
  VoiceOver on the Appearance row announces all five names and the selected one.

## Open operator decisions (DECIDE)

Both gate **Step 3 only**. Both are permanent once shipped: the raw value lands in people's
defaults, and a later rename drops them to System (plan D3).

- [ ] **DECIDE: D-F1 — the second theme.** Default applied: **Umber** (warm, flat, serif).
  Flip to **Graphite** (cool `#17181A`, stacked opaque greys, `tiles`, `roundness 1.4`, teal)
  if Umber reads too bookish beside Midnight; to **Moss** (`#0D1210`, sage throughout, serif,
  flat) if warm brown feels dated. Either is the same ~15 lines; 3b's values and 3f's by-eye
  list change, nothing else does.
- [ ] **DECIDE: D-F2 — the name.** Default applied: **"Umber"**. "Ember" is more familiar but
  promises a glow the theme refuses to have. Changes 3a's `case` and `name` only.

## Deferred (⏸ — not now)

- ⏸ **Sidebar selection contrast** — white label on a light accent: 1.7:1 Midnight, 2.3:1
  Umber, 2.0:1 today. Pre-existing. *Gate:* someone reports the selected row is hard to read
  → a darker `tint` separate from `accent`, as its own change.
- ⏸ **Graphite, Moss** — values only once Step 1 lands. *Gate:* D-F1 picks one, or a third
  theme is asked for.
- ⏸ **Any new mechanism** — paper grain, a second gradient shape, a per-theme face.
  *Gate:* a listed theme needs it (plan §10). Banding (2h-8) alone does not open this gate.
- ⏸ **Band height and stops as `Theme` fields.** *Gate:* a second glowing theme exists.

## Definition of done

- [ ] 1g, 2h and 3f all checked — or 3f explicitly left for later with D-F1 / D-F2 still open.
- [ ] G1–G8 checked.
- [ ] Both commands green on the final commit:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture; do bash tools/$s.sh; done
```

- [ ] Step 4's docs describe what shipped, not what was planned.
- [ ] Any `[Unverified]` row in plan §8 that fired is recorded — which exit was taken, and
  whether plan §3 needed rewriting.
