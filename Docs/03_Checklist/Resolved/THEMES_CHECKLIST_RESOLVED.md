# Themes — Resolved Build Checklist

[THEMES_CHECKLIST.md](../THEMES_CHECKLIST.md) with every finding from
[THEMES_CHECKLIST_AUDIT.md](../Audit/THEMES_CHECKLIST_AUDIT.md) answered. **Tick this file —
it stands alone.** Derived from
[THEMES_PLAN_RESOLVED.md](../../02_Plan/Resolved/THEMES_PLAN_RESOLVED.md), which is audited
and resolved. It adds no scope to that plan and re-verifies none of its claims.

**Stack** (per plan header): macOS 14.0, SwiftUI, `@Observable` MVVM, Swift 5 language mode
with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on both targets (load-bearing — gate G1), no
test target (standalone `tools/check_*.sh`), no dependencies. Base commit: **`c5d1ba4`**.

Carried forward from plan §11: `[Unverified]` **nothing here was ever compiled or run.** The
`.clipped()` / `.ignoresSafeArea()` order (2c-iii), the sidebar's top edge (2d) and the
popover fix (2f) each need a build and a look — 2h-1, 2h-2 and 2h-7 are their verification,
and the exit for each is printed under 2h. `[Inference]` the popover bug was derived from
the code, never observed. `[Inference]` white 7% is a starting point, not a finding (2h-10).
`[Assumption]` every measured hex is ±2 levels — sampled from a compressed screenshot.

**One fork is still open** (plan §7) and gates Step 3 only — see **DECIDE**. Steps 0, 1, 2
and 4 can be built today.

## Build log — 2026-09-19, branch `feat/themes`, nothing committed

**Steps 1–4 are written and every machine-checkable signal is green.** Build succeeds (app
and widget), all four `tools/check_*.sh` pass, G1 · G2 · G3 · G5 · G6 hold.
**Nothing below that needs eyes on the running app has been checked** — screen access was
declined for this session, so 0b, 1g's by-eye half, 2h, 3e's layout, 3f, G4, G7 and G8 are
open, and they are the point of this change. Unticked means unverified, not failed.

What was checked without a screen, by rendering `PaneGround` offscreen (`ImageRenderer`,
raw sRGB bytes) at pane size (785×680) and at header-strip size (785×52):

| Question | Result |
|---|---|
| Does the 52pt strip match the pane's top 52pt? (2h-1's premise) | **0 differing samples** |
| Peak and ground colours | exactly `(21,32,78)` = `#15204E` at y=0, `(15,15,15)` = `#0F0F0F` from y=330 |
| Any x in the band? (2h-2's premise) | ≤ 2 levels across a row — SwiftUI's gradient dither, not a shape |
| Banding (2h-8) | longest run of identical rows is 6pt, and it is dithered — low risk |
| Light / Dark get no band (2h-9's guard) | flat top to bottom |

That proves the *drawing*. It does not prove the *layout*: whether the ground reaches the
window's top edge, whether the sidebar's copy starts at the same y, the divider, and the
popover are all real-window questions and still `[Unverified]`.

- **3a's expected failure was observed**, in exactly the two predicted places and nowhere
  else: `DoodleTheme.swift:170` (`Theme.of`), then — once that arm existed —
  `SettingsView.swift:390` (`AppearanceTile.preview`). The compiler reports them one build
  at a time, not together.
- **0b was not done as written.** No screenshots. The untouched build can be had any time
  with `git stash -u && xcodebuild … build` (or a worktree of `main`) for a side-by-side.
- **Step 3 was built with D-F1 / D-F2 at their defaults** (Umber, "Umber"), which
  `01_Brainstorm/THEMES_BRAINSTORM.md` also argues for. Both stay open: the name is only
  permanent once shipped, and on this branch it is a two-line change.
- One pre-existing warning, not from this change: `DoodleTheme.swift:149`, `.serif` called
  from a nonisolated context.
- Beyond the plan's list, one more false comment was fixed: `DoodleTheme.swift`'s doc on
  `Theme.of` also claimed the widget "keeps calling `Theme.of(scheme)`".

## What the audit changed

Verdict was *Fix gaps first*: fidelity intact, four gates unable to do their job.
**12 self-resolved · 2 operator defaults applied · 0 not a defect · 0 deferred.**

| Finding | Change here |
|---|---|
| **M1** 2g's grep can never be empty (`words.json`) | `--include="*.swift"` on 2g. *The resolved plan's Step 2 verify line has the same defect; it is a point-in-time record and was left alone — this file is the one to follow.* |
| **M2** G5 / G6 vacuous when committed on `main` | New **0a** (branch). Both gates pinned to `c5d1ba4`. |
| **M3** DoD requires gates that need Step 3 | G8 and G3's second clause marked *Step 3 only*; DoD reworded. |
| **M4** two tuning prompts dropped | New **2h-10**, **2h-11**. |
| m1 4c invented, done-when already true | Kept *(operator default)*; done-when now fails today. |
| m2 2b points at the wrong comment | 2b rewritten: `:28-30` gains a clause; the `0.34` comment goes with the body 2c replaces, and a grep proves it. |
| m3 G1, G6 check less than they claim | G1 checks the keyword; G6 checks the type name and a seven-file whitelist — which also turns "no `pbxproj`, no `tools/`" into a check. |
| m4 wrong dependency edges | 1b unblocked; 1e blocked-by 1a, 1b, 1d. Wording fixed: the *target* is red, not the type. |
| m5 "covered by 1g / 3f" | 1c–1f, 3c–3d carry a per-file signal that works in a red build. |
| m6 3f-5 has no domain | Domain given; sandbox caveat tagged. |
| m7 plan's "needs no edit" files not carried | In 1g. |
| m8 no baseline | New **0b**. |
| Nits | 2g-v now cites G5's command. 2a says its real signal is 2h. 2d–2g marked parallel. **Ids kept as they were** so the audit's references still resolve. |
| Q2 branch name | `feat/themes` *(operator default)*. |

## How to use

`- [ ]` todo · `- [x]` done · `blocked-by:` must be checked first · `∥` may run alongside its
neighbours · `DECIDE:` operator call · `⏸` deferred by design. **One rule: never check an item
until its done-when holds.** Items are in build order (plan §9). "Builds + gates" always
means both commands at the foot of this file.

Steps 2 and 3 are independent of each other — either can be picked up once Step 1 is done.

## Checklist

### Step 0 — before touching code

- [x] **0a** Branch off `main`: `git switch -c feat/themes`. The uncommitted Themes docs come
  along — that is fine — **done-when:** `git branch --show-current` prints `feat/themes`.
- [ ] **0b** Baseline, on the untouched build. Screenshot **Home** and **Settings** in System,
  Light, Dark and Midnight; plus, in Midnight, one list pane, Dictionaries, and an (i)
  popover open. Save them outside the repo. **Leave Midnight selected** — blocked-by: 0a ·
  **done-when:** eleven screenshots exist, and Settings shows Midnight as the picked tile.
  *(1g's "exactly as before" and G4 are checked against these — not against memory.)*

### Step 1 — the flag becomes the appearance *(refactor; pixel-identical — unblocks 2 and 3)*

The target is **red from 1b until 1f**. That is expected: 1b changes a stored property and
its three readers live in other files.

- [x] **1a** Add `var paintsPalette: Bool` to `Appearance` — `true` for `.midnight`, `false`
  for the rest; **exhaustive `switch`, no `default`** — files: `OneWord/Models/Appearance.swift`
  · isolation: stays `nonisolated`, touches no `Theme` (G1) · blocked-by: 0b ·
  **done-when:** builds.
- [x] **1b** In `DoodleTheme`, replace `var midnight = false` (`:79`) with
  `var appearance: Appearance = .system` — files: `OneWord/Models/DoodleTheme.swift` ·
  **done-when:** `xcodebuild` reports no error *in this file*; errors elsewhere are 1c–1f's.
  - [x] **1b-i** `current` (`:92-97`) parses the stored string with
    `Appearance(rawValue:) ?? .system` — a missing or unknown value is `.system`.
  - [x] **1b-ii** `face` (`:140`) and `tracking` (`:154`) test `appearance == .midnight`.
    Handwriting still outranks it — order of the two `if`s unchanged.
  - [x] **1b-iii** `Theme.of(_:_:)` (`:164`) becomes an **exhaustive** `switch look.appearance`
    — `.midnight → .midnight`; `.system, .light, .dark → .of(scheme)`. It stays in this file's
    `extension Theme`, **not** `Theme.swift` (G2).
- [x] **1c** ∥ `OneWordApp.swift:34-36` — hoist `Appearance(rawValue: appearance) ?? .system`
  to one `let`; pass it as `appearance:` at `:34`, read `.colorScheme` from it at `:36` —
  blocked-by: 1b · **done-when:** no error in this file.
- [x] **1d** ∥ `RootView.swift` — give `var sidebar` (`:134`) a first line
  `let t = Theme.of(scheme, doodle)` and an explicit `return`, the shape `shell` has at
  `:107-108` *(plan-audit m1: `t` is not in scope there today)* — blocked-by: 1b ·
  **done-when:** no *new* error in this file; `:118, :158, :159` still fail until 1e.
- [x] **1e** Same file — `:118`, `:158`, `:159`: `doodle.midnight` →
  `doodle.appearance.paintsPalette`; `Theme.midnight.background` → `t.background`; `:160` may
  take `t` too — blocked-by: 1a, 1b, 1d · **done-when:** no error in this file.
- [x] **1f** ∥ `SettingsView.swift:385-399` — `page(_:midnight:)` →
  `page(_ t: Theme, as mode: Appearance)`, setting `look.appearance = mode`; `.system` draws
  `page(.light, as: .light)` beside `page(.dark, as: .dark)` — blocked-by: 1b ·
  **done-when:** no error in this file.
- [ ] **1g** **Step 1 gate** — blocked-by: 1a–1f · **done-when:** all of:
  - builds + gates green;
  - `grep -rn "doodle\.midnight\|look\.midnight" OneWord` → empty;
  - `git diff --stat c5d1ba4 -- OneWord` lists **five** files — `Appearance`, `DoodleTheme`,
    `OneWordApp`, `RootView`, `SettingsView`. **`Doodles.swift`, `WordCapture.swift` and
    `DoodleTheme.off` needed no edit** (plan Step 1) — if a build-fixer touched them, revert;
  - **by eye against 0b:** System, Light, Dark and Midnight are indistinguishable from the
    baseline, and each Settings tile draws in its own face (Midnight's in the sans).

  *First reversible move — nothing on screen has changed.*

### Step 2 — repaint Midnight, and fix the popover *(blocked-by: 1g)*

- [x] **2a** `Theme.midnight` values (`Theme.swift:65-78`): `background #0F0F0F` ·
  `surface` white **7%** · `accent #A8C7FA` · `rule` accent 60% · `glow #15204E`. Ink, muted,
  definition, example, hairline, `roundness 2.2`, `tiles` — **unchanged** — files:
  `OneWord/Shared/Theme.swift` · **done-when:** builds. *Transcription only — whether the
  values are right is 2h's question, 2h-10 and 2h-11 above all.*
- [x] **2b** `Theme.swift:28-30` — the `glow` doc comment stays true; add one clause: it is
  the band's **peak colour**, painted opaque at the top edge. The `0.34` remark lives at
  `:93-94`, inside the body 2c replaces — it goes with it — blocked-by: 2c · **done-when:**
  `grep -n "0\.34" OneWord/Shared/Theme.swift` → empty.
- [x] **2c** Replace `paneBackground`'s body (`Theme.swift:88-101`) — blocked-by: 2a ·
  **done-when:** builds + gates (`check_learned.sh` compiles this file by path — G2); visual
  proof is 2h-1, 2h-4, 2h-5, 2h-9.
  - [x] **2c-i** New `struct PaneGround: View { let t: Theme }` **in the same file** — a new
    file in `Shared/` needs a hand edit to `project.pbxproj` for both targets;
    `paneBackground` becomes `background { PaneGround(t: t) }`.
  - [x] **2c-ii** Body: `t.background`, then `.overlay(alignment: .top)` holding
    `LinearGradient(stops:)` — `t.glow @ 0` → `t.glow.opacity(0.5) @ 0.45` →
    `t.glow.opacity(0) @ 1`, top to bottom, `.frame(height: 330)` — **drawn only when
    `t.glow != .clear`**.
  - [x] **2c-iii** Then `.clipped()`, then `.ignoresSafeArea()`, in that order
    `[Unverified — plan §8 row 1]`. **The clip is load-bearing:** without it the 330pt band
    spills out of the 52pt header over the scrolling content.
  - [x] **2c-iv** Far stop is `t.glow.opacity(0)`, **not** `.clear` (grey fringe).
  - [x] **2c-v** The new comment keeps the two facts the old one recorded: the ground is
    *under* the content, and it is plain alpha with **no blend mode**. `330` and the stops
    stay local constants.
- [x] **2d** ∥ `RootView.swift:158-159` — the sidebar paints `PaneGround(t: t)` inside a
  `.background { }` when `paintsPalette`, in place of the flat colour; keeps
  `.scrollContentBackground(.hidden)` on the same condition — blocked-by: 1d, 2c ·
  **done-when:** builds; visual proof is 2h-2, 2h-3 `[Unverified — plan §8 row 2]`.
- [x] **2e** ∥ `SettingsView.swift:408` — the tile's `page` paints `t.background` with a
  top-to-bottom `t.glow → t.glow.opacity(0)` gradient over it when `t.glow != .clear` —
  blocked-by: 1f, 2a · **done-when:** builds; visual proof is 2h-6.
- [x] **2f** ∥ **Popover (plan-audit M1)** — `SettingsView.swift:311`:
  `.background(theme.surface)` → `.background(theme.surface).background(theme.background)`;
  extend the comment at `:302-303` to say the surface must be opaque here and why —
  blocked-by: 2a · **done-when:** builds; visual proof is 2h-7, against 0b's popover shot
  `[Inference — bug derived, never observed]`.
- [x] **2g** ∥ Comment sweep — rewrite each to what is now true — blocked-by: 2a ·
  **done-when:** `grep -rn -i --include="*.swift" "navy\|periwinkle" OneWord` → empty, and
  `Theme.swift:8` no longer claims the widget resolves a `Theme`. ***`--include` is
  load-bearing: `words.json` holds "navy" as vocabulary and must not be touched.***
  - [x] **2g-i** `Theme.swift:5-8` (incl. `:8`, *never true* — plan-audit m3) and `:62-64`.
  - [x] **2g-ii** `Appearance.swift:6-8`.
  - [x] **2g-iii** `DoodleTheme.swift:78`, `:161`. At `:141` **reword, don't delete**:
    "light-on-navy" → "light-on-dark" — the reason still holds.
  - [x] **2g-iv** `RootView.swift:116`, `:156`. `DictionaryPicker.swift:64`.
  - [x] **2g-v** No rewritten comment names the reference product — **done-when:** G5's
    command, run now, is empty.
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
  - [ ] **2h-9** Light, Dark and System match 0b. *(The only check on 2c-ii's
    `glow != .clear` guard.)*
  - [ ] **2h-10** Tiles read as **frosted glass, not grey boxes**, both over the band and
    below it. If not, tune `surface` between 0.06 and 0.09 (plan §11, `[Inference]`).
  - [ ] **2h-11** Under a real entry the band is **neither lost nor loud**. If it is, `glow`
    and the three stops are the only knobs (plan §8).

  *If 2h-1 or 2h-4 fails:* swap 2c-iii's order; failing that, plan §8's dome fallback
  (`RadialGradient(center: .top)`, new colours, `endRadius ≈ 900`) — and plan §3 then needs
  rewriting. *If 2h-2 fails:* sidebar back to flat `t.background`, soften by starting the
  band at 0.8. *If 2h-7 fails:* `.presentationBackground(theme.background)` (macOS 13.3+).

### Step 3 — Umber *(blocked-by: 1g, **D-F1**, **D-F2**)*

- [x] **3a** `Appearance` gains `case umber` — `name → "Umber"`, `colorScheme → .dark`,
  `paintsPalette → true` — files: `OneWord/Models/Appearance.swift` · **done-when:** the
  build **fails**, naming exactly `Theme.of` (3c) and `AppearanceTile.preview` (3d) as
  non-exhaustive. That failure is the proof Step 1's switches do their job; anything else
  failing is a surprise worth reading. **Do not answer it with `default:`** (G3).
- [x] **3b** ∥ `static let umber` in `Theme.swift`, beside `midnight` — `background #161412` ·
  `surface #1F1C19` · `ink #EDE6DA` · `muted #9C9284` · `definition #DDD5C8` ·
  `example #B9AFA0` · `accent #D0A667` · `rule #D0A667 @ 55%` · `hairline #EDE6DA @ 10%`.
  **Omit** `roundness`, `glow`, `tiles` — the defaults are the design, as `.light` and
  `.dark` do (`:38-60`) — **done-when:** `bash tools/check_learned.sh` green (it compiles
  this file without the app, so it passes even while 3a has the target red).
- [x] **3c** One arm in `Theme.of` (`DoodleTheme.swift:164`): `.umber → .umber`. `face` and
  `tracking` untouched — Umber falls through to the serif — blocked-by: 3a, 3b ·
  **done-when:** the `Theme.of` error from 3a is gone.
- [x] **3d** ∥ `SettingsView.swift:385` — `preview` gains
  `case .umber: page(.umber, as: .umber)` — blocked-by: 3a, 3b · **done-when:** the
  `AppearanceTile.preview` error from 3a is gone; the target builds.
- [ ] **3e** ∥ `SettingsView.swift:53` — picker `HStack(spacing: 10)` →
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
  - [ ] **3f-5** Quit; `defaults write com.hariom.swift.oneword appearance junk`; confirm
    with `defaults read com.hariom.swift.oneword appearance`; launch → the app opens in
    **System**. The app is sandboxed (`OneWord.entitlements:5-6`): if it still opens in
    Umber, the write missed the container — target
    `~/Library/Containers/com.hariom.swift.oneword/Data/Library/Preferences/com.hariom.swift.oneword`
    instead `[Unverified]`. Afterwards pick a real appearance in Settings.
  - [ ] **3f-6** An (i) popover reads, Mac in Light and in Dark.
  - [ ] **3f-7** The 52pt empty-state glyph (Bookmarks, empty) is not too faint — it is
    `accent @ 50%`, 2.9:1, the weakest pair in the plan (§6). Nudge the brass lighter if so.

### Step 4 — standing docs *(blocked-by: 2h; the Umber lines wait for 3f)*

- [x] **4a** ∥ `Docs/00_Context/DESIGN_BRIEF.md` §3 / §8 — replace "a light + dark theme"
  with the looks that exist and what each is for — **done-when:** the brief names every case
  in `Appearance` as built, and no more.
- [x] **4b** ∥ `Docs/00_Context/ARCHITECTURE.md` — an "adding a theme" note: one `case`, one
  `static let`, the compiler lists the rest; **opaque `surface` unless there is a reason not
  to** — **done-when:** a reader could add a theme from that note alone.
- [x] **4c** ∥ `Docs/README.md` — the Themes dossier line *(not in the plan; the project's
  own doc rule — kept by operator default)* — **done-when:**
  `grep -n "Themes.*planned, not built" Docs/README.md` → empty, and the line says which
  steps shipped.

## Rigor gates — check before merging

Nothing here is async: no `Task`, no capture list, no migration, no new file, no target
membership. These are the gates the plan *does* have. Every diff below is against the base
commit, so it means the same thing on any branch.

- [x] **G1 Isolation.** `Appearance` and `DoodleTheme` are still `nonisolated`, and neither
  returns nor touches a `Theme` — **done-when:**
  `grep -n "^nonisolated" OneWord/Models/Appearance.swift OneWord/Models/DoodleTheme.swift`
  → two hits; `grep -nw "Theme" OneWord/Models/Appearance.swift` → comments only; and
  `sed -n '/^nonisolated struct DoodleTheme/,/^}/p' OneWord/Models/DoodleTheme.swift | grep -nw "Theme"`
  → comments only. *(`-w` so `DoodleTheme` itself does not count; the type `Theme` belongs
  only in the `extension Theme` below the struct.)*
- [x] **G2 `Theme.swift` stays shareable.** It names no `Appearance`, no `DoodleTheme`, no
  app-only type — it is compiled into the widget and into `check_learned.sh:194` by path —
  **done-when:** `grep -n "Appearance\|DoodleTheme" OneWord/Shared/Theme.swift` → comments
  only; the widget target builds.
- [x] **G3 No `default:`** in any `switch` over `Appearance` — there are four: `name`,
  `colorScheme`, `paintsPalette`, `Theme.of`, plus `AppearanceTile.preview` —
  **done-when:** `grep -n "default:" OneWord/Models/Appearance.swift` → empty; none inside
  `Theme.of` or `preview` (`SettingsView.swift:385-392`). ***Step 3 only:*** 3a's expected
  failure was observed.
- [ ] **G4 Stored value.** The raw value is still `"midnight"`; no case was renamed —
  **done-when:** the build launched after Step 1 opened in Midnight without anyone
  re-picking it (0b left it selected).
- [x] **G5 No brand.** No theme, symbol, comment or doc names a reference product or borrows
  its marks — **done-when:**
  `git diff c5d1ba4 -- OneWord Docs/00_Context | grep -i "^+.*\(gemini\|google\|offsuit\)"`
  → empty. *(Diff-scoped: the app has Google sign-in, so a repo-wide grep is never clean.
  Pinned to the base commit: `git diff main` is empty once work is committed on `main`.)*
- [x] **G6 Only the named files moved, and `DoodleTheme` kept its name** (plan §1, §6) —
  **done-when:** `grep -rnw "struct DoodleTheme" OneWord` → one hit *(`-w`: without it `DoodleThemeKey` counts too — it does on the base commit as well)*; and
  `git diff --stat c5d1ba4 -- OneWord OneWordWidget OneWord.xcodeproj tools` lists **only**
  `Appearance`, `DoodleTheme`, `OneWordApp`, `RootView`, `SettingsView`, `Theme`,
  `DictionaryPicker` — no `project.pbxproj`, nothing under `tools/`, nothing in the widget.
- [ ] **G7 `Equatable` by synthesis** still holds on `DoodleTheme` — **done-when:** no
  hand-written `==`; toggling a Doodle switch still animates `DoodleSample`.
- [ ] **G8 Accessibility — *Step 3 only*.** The Umber tile reads "Umber" and carries
  `.isSelected` when picked (it inherits both from `AppearanceTile` — confirm, don't add) —
  **done-when:** VoiceOver on the Appearance row announces all five names and the selected
  one.

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

- [ ] **0a, 0b, 1g and 2h** checked.
- [ ] **3f** checked — *or* Step 3 explicitly left for later, D-F1 / D-F2 still open, and
  `Appearance` has four cases.
- [ ] **G1–G7** checked. **G8** and G3's second clause too, if and only if 3f is.
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
