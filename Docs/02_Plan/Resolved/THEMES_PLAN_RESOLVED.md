# Themes — Resolved Plan

[THEMES_PLAN.md](../THEMES_PLAN.md) with every finding from
[THEMES_PLAN_AUDIT.md](../Audit/THEMES_PLAN_AUDIT.md) answered. **Build from this file — it
stands alone.** Grounded in `main` at `c5d1ba4`; nothing here is built yet.

Three things, in this order:

1. **Make a theme cheap.** Midnight is a `Bool` threaded through the app. It becomes the
   `Appearance` itself. No visual change.
2. **Repaint Midnight.** Navy → neutral near-black, with the blue as a band across the
   **top** edge. Same name, same stored value, same sans, same pills and tiles. The (i)
   popover gets fixed in the same pass.
3. **Add Umber.** A second dark theme built the opposite way: warm, flat, serif, hairlines.

**Reference.** A desktop AI-assistant window the operator likes — style only. **Never name
the theme, a symbol or a comment after the product, and none of its marks or artwork.**

**Stack** (verified twice, plan and audit): Xcode project, two targets, no dependencies ·
SwiftUI · MVVM with `@Observable` · `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION =
MainActor` on both targets (`project.pbxproj:367,394,550,587`) · `@AppStorage` /
`UserDefaults` · macOS 14.0 · no XCTest target — gates are `tools/check_*.sh`.

---

## 0. Resolution

Audit verdict was **Ready to build**. 1 major, 5 minor, 2 coverage gaps, 2 operator questions.

**8 self-resolved · 1 operator-decided · 0 not a defect · 0 deferred · 1 still open (does
not block Steps 1–2).**

| Finding | Type | What changed here |
|---|---|---|
| **M1** popover unreadable, Mac in Light + app in Midnight | **Operator decided: fix in this change** | New edit in Step 2 at `SettingsView.swift:311` — paint `theme.background` under `theme.surface`. New by-eye check 7. New rule in §10. Re-grounded: `InfoButton` already holds the theme (`:290`, passed at `:271`); it is the app's only popover. |
| **m1** `t` not in scope in `sidebar` | Self | Step 1 now adds `let t = Theme.of(scheme, doodle)` at the top of `var sidebar` (`RootView.swift:134`). Re-grounded: `:134-167` has no `t`; `:160` already resolves the theme inline, and `shell` (`:107-108`) is the `let` + `return` exemplar. |
| **m2** stale comments not listed | Self | Step 2 lists all six sites and adds a grep to verify. |
| **m3** false comment at `Theme.swift:8` | Self | Folded into Step 2's header rewrite. |
| **m4** banding unstated | Self | Row in §8, by-eye check 8. |
| **m5** three citations off | Self | Corrected throughout: 10 panes + `PaneHeader`; `OneWordApp.swift:36`; `WordDetail.swift:333`. |
| Gap — `DoodleTheme` misnomer | Self | §1 says: do not rename. |
| Gap — sidebar divider over the band | Self | By-eye check 3. |
| Q1 — fix M1 here or separately | Operator | Here. |
| Q2 — F1 / F2, which theme and its name | **Open** | Default applied: Umber. See §7 — confirm before Step 3 ships. |

---

## 1. What we're reusing

| Need | Already here | File |
|---|---|---|
| A palette as a value | `struct Theme` — 9 colours + `roundness`, `glow`, `tiles` | [Theme.swift:15](../../../OneWord/Shared/Theme.swift) |
| A painted ground under every pane | `paneBackground(_:)` — 11 call sites: 10 panes and `PaneHeader` | [Theme.swift:88](../../../OneWord/Shared/Theme.swift) |
| App-side palette resolution | `Theme.of(_:_:)` | [DoodleTheme.swift:164](../../../OneWord/Models/DoodleTheme.swift) |
| The display face, decided once | `DoodleTheme.face(_:_:)` / `tracking(_:)` | [DoodleTheme.swift:134](../../../OneWord/Models/DoodleTheme.swift) |
| Hairline blocks vs filled tiles | `entryBlock(_:onTap:)` switches on `t.tiles` | [WordDetail.swift:333](../../../OneWord/Views/WordDetail.swift) |
| The picker | `ForEach(Appearance.allCases)` → `AppearanceTile` | [SettingsView.swift:54](../../../OneWord/Views/SettingsView.swift) |
| The stored choice | `@AppStorage("appearance")`, raw string, `?? .system` on a miss | [OneWordApp.swift:14, :36](../../../OneWord/OneWordApp.swift) |

Every call site reads colour through `t.<token>` and every radius through `t.radius(_:)`.
**Umber adds no view code**, and Midnight's repaint touches one function.

**Not added:** a theme protocol, a registry, JSON themes, a `ThemeManager`, a new font.
**Not touched:** the widget — no file in `OneWordWidget/` mentions `Theme`
(`WordWidgetView.swift:67` paints `.black` / `.white` from the scheme).
**Not renamed:** `DoodleTheme`. It has been a misnomer since it took Midnight
(`DoodleTheme.swift:10-13` says so itself) and will be more of one. 34 `face(` call sites
read `\.doodle`; a rename is churn with no behaviour in it. Leave it.

---

## 2. Decisions

| # | Decision | Choice | Who / why |
|---|---|---|---|
| D1 | How a theme is carried | `DoodleTheme.midnight: Bool` → `DoodleTheme.appearance: Appearance` | **Code.** The flag is set or read at 10 sites in 4 files; a second `Bool` doubles each. An exhaustive `switch` makes the compiler list every site for theme #3. |
| D2 | Where palette resolution lives | Stays in `extension Theme` in `DoodleTheme.swift` | **Code.** `Theme.swift` is compiled into the widget and into `check_learned.sh:194` by path; neither has `Appearance`. Audit confirmed no gate compiles `Appearance.swift` or `DoodleTheme.swift`. |
| D3 | Midnight's stored value | Keep `"midnight"` | **Code.** A rename silently drops every Midnight user to System. |
| D4 | Shape of the blue | A **y-only band of fixed height** | **Code — §3.** |
| D5 | Midnight's type and shapes | Unchanged | **Operator:** "use colors like this". |
| D6 | The second theme | **Umber** | **Recommended default — still open, §7.** |
| D7 | Picker layout | `HStack` → adaptive `LazyVGrid` | **Code.** Five tiles fit the 520pt column at 96pt each (the `section` helper adds no padding — `SettingsView.swift:231-246`); a sixth, or a narrow window, does not. |
| D8 | The popover bug | Fixed in Step 2 | **Operator.** |

### Why Umber is the *different approach*

| | Midnight | Umber |
|---|---|---|
| Depth comes from | light — a band of blue, glass tiles over it | temperature — nothing glows, nothing floats |
| Ground | neutral `#0F0F0F` + gradient | flat warm `#161412` |
| Surfaces | translucent white | opaque warm stock |
| Sections | filled tiles | hairline rules |
| Corners | ×2.2 — pills | ×1 — as drawn |
| Face | geometric sans, tight | the editorial serif |
| One hue | cool blue | brass, spent on the Hindi rule |

It is the direction `DESIGN_BRIEF.md` §3 named and nobody built: *"a warmer ambers/golds
palette is the other."*

---

## 3. The band — measured, and why it is y-only

Sampled from the reference (2000×1134, sRGB), columns clear of text:

| From the glowing edge | 1.5% | 5% | 10% | 15% | 22% | 30% | 38% | 45% |
|---|---|---|---|---|---|---|---|---|
| Colour | `#141F4B` | `#121D47` | `#131D43` | `#121B3C` | `#12172F` | `#111320` | `#101118` | `#0F1112` |
| Strength vs peak | 0.95 | 0.89 | 0.83 | 0.71 | 0.51 | 0.27 | 0.14 | 0.05 |

Ground `#0F0F0F`; peak `#15204E`. The reference's edge runs a few levels darker at its
centre — dropped on purpose `[Inference: not visible at pane scale]`.

Half by ~22% of the height, gone by ~48%. On the default 680pt window: **half at ~150pt,
gone at ~330pt** → stops `1.0 @ 0`, `0.5 @ 0.45`, `0 @ 1` over a **330pt** band.

**Why fixed height and y-only.**

- **Header seam.** `PaneHeader` is a 52pt strip that paints the pane's ground again
  (`PaneHeader.swift:90`) and relies on "same top, same width" (`:22-24`). Anything sized
  relative to bounds compresses into 52pt and the seam shows. The dome works today only
  because its radius is in points. The band needs exactly the same thing the dome already
  gets — a shared top edge — so it adds **no new alignment risk**; the new risk is
  overflow, answered by the clip in Step 2.
- **Sidebar split.** The sidebar is painted flat (`RootView.swift:159`). A band is full
  strength at the pane's corner — a hard edge against a flat sidebar. A gradient with no x
  in it can be painted in the sidebar too and meets the pane at any column width.
- **A side effect worth having:** the dome re-centres while the sidebar folds
  (`PaneHeader.swift:55` animates it). A band cannot move.

---

## 4. Implementation steps

### Step 1 — the flag becomes the appearance *(refactor; pixel-identical)*

| File | Change |
|---|---|
| `OneWord/Models/Appearance.swift` | Add `var paintsPalette: Bool` — `true` for `.midnight`; exhaustive `switch`, no `default`. Stays `nonisolated`. |
| `OneWord/Models/DoodleTheme.swift` | `var midnight = false` (`:79`) → `var appearance: Appearance = .system`. `current` (`:92-97`) parses `Appearance(rawValue:) ?? .system`. `face` (`:140`) and `tracking` (`:154`) test `appearance == .midnight`. `Theme.of(_:_:)` (`:164`) becomes an exhaustive `switch look.appearance` — `.midnight → .midnight`; `.system, .light, .dark → .of(scheme)`. |
| `OneWord/OneWordApp.swift:34-36` | Hoist `Appearance(rawValue: appearance) ?? .system` to one `let`; pass it as `appearance:` at `:34` and read `.colorScheme` from it at `:36`. |
| `OneWord/Views/RootView.swift` | **`var sidebar` (`:134`) gains `let t = Theme.of(scheme, doodle)` as its first line and an explicit `return` — the shape `shell` already has at `:107-108`.** Then `:118`, `:158`, `:159`: `doodle.midnight` → `doodle.appearance.paintsPalette`; `Theme.midnight.background` → `t.background`; `:160` can take `t` too. |
| `OneWord/Views/SettingsView.swift:385-399` | `page(_:midnight:)` → `page(_ t: Theme, as mode: Appearance)`, setting `look.appearance = mode`. `.system` draws `page(.light, as: .light)` beside `page(.dark, as: .dark)`. |

Untouched and still compiling: `Doodles.swift:140` and `DoodleTheme.off` never pass
`midnight:`. `WordCapture.swift:99` takes `DoodleTheme.current`, reads only `face()`, and
paints `.regularMaterial` — no palette.

**Isolation.** `Appearance` and `DoodleTheme` are `nonisolated`; `Theme` is MainActor by the
project default. `paintsPalette` must **not** return or touch a `Theme`. Resolution stays in
`Theme.of(_:_:)`, MainActor like every `body` that calls it.

**Verify.** Build + all gates. All four appearances look exactly as before.
`grep -rn "doodle\.midnight\|look\.midnight" OneWord` → empty.

### Step 2 — repaint Midnight, and fix the popover

**`OneWord/Shared/Theme.swift` — values**

| Token | Now | New | Note |
|---|---|---|---|
| `background` | `#080F1B` | `#0F0F0F` | measured |
| `surface` | white 9% | white 7% | → `#202020` on the ground; the reference's controls are `#1C1C1C`. Stays translucent so a tile over the band picks up blue. |
| `accent` | `#A5B4FC` | `#A8C7FA` | The reference's button blue (`#223E9B`) is a *fill*; at 2.2:1 on the ground it cannot be an accent drawn as text and glyphs. |
| `rule` | accent 60% | accent 60% | follows |
| `glow` | `#3B5BDB` | `#15204E` | now the band's **peak colour**, opaque at the edge — no longer a colour at 0.34 alpha |
| everything else | — | unchanged | |

Contrast, ground / band peak: ink 18.5 / 15.1 · definition 14.1 / 11.8 · example 9.6 / 8.2 ·
muted 6.2 / 5.6 · accent 11.2 / 9.1. All clear AA.

**Same file — `paneBackground(_:)` (`:88-101`)**

- Lift the ground into `struct PaneGround: View { let t: Theme }`; `paneBackground` becomes
  `background { PaneGround(t: t) }`.
- Body: `t.background` with the band as `.overlay(alignment: .top)` —
  `LinearGradient(stops:)` from `t.glow` through `t.glow.opacity(0.5)` to `t.glow.opacity(0)`
  at the stops in §3, `.frame(height: 330)`, drawn only when `t.glow != .clear` — then
  `.clipped()`, then `.ignoresSafeArea()`. **The clip is load-bearing:** in the 52pt header
  an unclipped 330pt overlay spills over the content scrolling beneath it.
- `t.glow.opacity(0)`, not `.clear`, as the far stop — no grey fringe.
- Keep the two facts the current comment records: under the content, and plain alpha with
  no blend mode.
- `330` and the stops stay local constants until a second glowing theme exists.

**`OneWord/Views/RootView.swift:158-159`** — the sidebar paints `PaneGround(t: t)` when
`paintsPalette` (as a `.background { }` view), in place of the flat colour. `t` is the
local Step 1 added.

**`OneWord/Views/SettingsView.swift:408`** — the tile's `page` draws a miniature:
`t.background` with a top-to-bottom `t.glow → t.glow.opacity(0)` gradient over it when
`t.glow != .clear`. (The real 330pt band would fill a 58pt tile with solid blue.)

**`OneWord/Views/SettingsView.swift:311` — the popover (audit M1)**

`.background(theme.surface)` → `.background(theme.surface).background(theme.background)`.

Why: the comment at `:302-303` records that a popover ignores the app's appearance
override, so the code paints its own surface. That only works if the surface is **opaque**
— true for Light (`#F4F4F4`) and Dark (`#1A1A1A`), false for Midnight. With the Mac in
Light, 7% white lands on a light system popover and `#FBFBFC` text sits on near-white
`[Inference — follows from the code; not run]`. Painting the ground underneath makes every
palette opaque there. Extend the comment to say so. Umber needs nothing: its surface is
opaque already.

**Comments the repaint makes false** — rewrite each to what is true:

- `Theme.swift:5-8` — "navy", "periwinkle", and **`:8` "The widget resolves
  `Theme.of(colorScheme)`", which was never true** (see §1).
- `Theme.swift:62-64`, `Appearance.swift:6-8` — "navy".
- `DoodleTheme.swift:78`, `:161` — "navy palette". `:141` "reads thin set light-on-navy" is
  a *reason* and still holds on near-black: reword to "light-on-dark", do not delete.
- `RootView.swift:116` "periwinkle", `:156` "paints its navy through it".
- `DictionaryPicker.swift:64` "Midnight's navy".

**Verify — build, gates, `grep -rn -i "navy\|periwinkle" OneWord` → empty, then by eye:**

1. Home, scrolled: no line where the header strip meets the pane.
2. The band meets itself across the sidebar at the same y, sidebar open and folding.
3. The split view's own divider over the band — invisible on navy today; if it reads as a
   dark line through the blue, that is the thing to look at.
4. Full screen: band starts at the very top, no grey strip.
5. A list pane (Search, Bookmarks): rows stay clear over the band.
6. Dictionaries: spines and shadows still read on `#0F0F0F`. Settings: the Midnight tile
   shows a small band.
7. **Mac in Light, app in Midnight → open any (i) in Settings: dark card, legible text.**
   Repeat with the Mac in Dark.
8. On an external display if one is to hand: no horizontal stripes in the band.

### Step 3 — Umber

| File | Change |
|---|---|
| `OneWord/Models/Appearance.swift` | `case umber`; `name → "Umber"`; `colorScheme → .dark`; `paintsPalette → true`. |
| `OneWord/Shared/Theme.swift` | `static let umber` — below. |
| `OneWord/Models/DoodleTheme.swift` | One arm in `Theme.of`: `.umber → .umber`. `face` / `tracking` untouched — Umber falls through to the serif; Handwriting still outranks it. |
| `OneWord/Views/SettingsView.swift` | `preview` (`:385`) gains `case .umber: page(.umber, as: .umber)`. The picker `HStack` (`:53`) → `LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10)`. |

The compiler finds every one: each `switch` is exhaustive.

```
background  #161412   warm charcoal — lifted off black so it reads as stock, not void
surface     #1F1C19   opaque, one step up
ink         #EDE6DA   parchment
muted       #9C9284
definition  #DDD5C8
example     #B9AFA0
accent      #D0A667   brass
rule        #D0A667 @ 55%
hairline    #EDE6DA @ 10%
roundness, glow, tiles — omit; the defaults are right, as .light and .dark do (Theme.swift:38-60)
```

Contrast, ground / surface: ink 14.8 / 13.7 · definition 12.6 / 11.7 · example 8.5 / 7.8 ·
muted 6.0 / 5.5 · accent 8.2 / 7.5. All clear AA.

**Verify.** Build + gates. Pick Umber: serif headword, hairline sections, square corners,
brass Hindi rule, brass switches, warm sidebar, flat ground with no band. Handwriting on →
the marker face wins, palette stays. Relaunch → it sticks. A junk `appearance` string in
defaults → System. An (i) popover reads, Mac in Light and in Dark.

### Step 4 — standing docs

- `Docs/00_Context/DESIGN_BRIEF.md` §3 / §8 — still says "a light + dark theme". Record the
  looks and what each is for.
- `Docs/00_Context/ARCHITECTURE.md` — "adding a theme": one `case`, one `static let`, the
  compiler lists the rest; **give it an opaque `surface` unless there is a reason not to**.

---

## 5. Isolation, state, memory

Nothing async, nothing escaping: no `Task`, no capture, no retain-cycle surface. The whole
concurrency story is D2 and Step 1's isolation note. State ownership is unchanged:
`@AppStorage("appearance")` is read in `OneWordApp` and `SettingsView`, resolved once into
the environment, and every pane reads `\.doodle`.

`DoodleTheme` stays `Equatable` by synthesis (`Appearance` is a `String` enum) —
`DoodleSample`'s `.animation(value: doodle)` depends on it. `PaneGround` is a `View`, so
MainActor either way, and compiles inside `check_learned.sh`'s
`-default-isolation MainActor` invocation with nothing but SwiftUI.

---

## 6. Accessibility & mechanics

- Text contrast is computed above; both themes clear AA on every surface they meet.
- `accent.opacity(0.5)` draws the 52pt empty-state glyphs: 3.6:1 in Midnight, **2.9:1 in
  Umber** — decorative and large, but the weakest pair here. Nudge the brass lighter if it
  looks faint.
- The tile carries `.isSelected`; "Umber" is read from `name`. No new labels.
- No new files → no `project.pbxproj` edit. `Theme.swift` stays free of app-only types, so
  no gate script changes.
- No migration: D3 keeps the raw value; `?? .system` absorbs an unknown string.

---

## 7. Still open — confirm before Step 3 ships

Steps 1, 2 and 4 do not depend on either. Step 3 does, and the raw value is permanent once
it is in people's defaults (D3).

**F1 — the second theme. Default applied: Umber.** Each alternative is the same ~15 lines.
- **Graphite** — cool neutral `#17181A`, depth from stacked opaque greys, `tiles: true`,
  `roundness 1.4`, soft-teal accent. Wins if Umber reads too bookish beside Midnight.
  Risk: closest to plain Dark.
- **Moss** — one hue throughout: `#0D1210` ground, sage ink, sage accent, serif, flat. Wins
  if warm brown feels dated. Risk: tinted body text tires faster than neutral.

**F2 — the name. Default applied: "Umber".** A pigment, and a good word for a vocabulary
app. "Ember" is more familiar but promises a glow the theme refuses to have.

**F3 — Midnight keeps its sans.** Settled by D5; listed only because it was never asked.

---

## 8. Risks & exits

| Risk | Sev · Conf | Leading indicator | Exit |
|---|---|---|---|
| `.clipped()` + `.ignoresSafeArea()` order leaves the band short of the window top, or the header seam shows | Med · Med `[Unverified — not compiled]` | Checks 1, 4 | Swap the order. Failing that, keep `RadialGradient(center: .top)` with the new colours and `endRadius ≈ 900` — a dome again, seam-safe by construction, loses the horizon. §3 then needs rewriting. |
| Sidebar's ground does not start at the same y as the pane's | Med · Low `[Unverified]` | Check 2 | Sidebar back to flat `t.background`; soften the edge by starting the band at 0.8. |
| Popover fix does not take — the system draws its own material over the content | Low · Low `[Unverified]` | Check 7 | The popover's content is ours edge to edge (`:304-311` pads inside the background), so this is unlikely; if it fails, `.presentationBackground(theme.background)` is available on macOS 13.3+. |
| Banding — a 330pt ramp over ~63 levels of blue is ~5pt a step | Low · Low `[Inference]` — the dome covers a similar range today without complaint | Check 8 | Accept. A grain overlay is a new mechanism; §10 says not yet. |
| Sidebar selection: white label on a light accent — 1.7:1 Midnight, 2.3:1 Umber | Low · High — **pre-existing** (2.0:1 today) | Selected row hard to read while the sidebar has focus | Out of scope; a darker `tint` separate from `accent` is its own change. |
| Band too quiet or too loud under real content | Low · Med | First look | `glow` and three stops are the only knobs. |
| Umber is "Dark, but brown" | Med · Low — taste | First look | F1. |

---

## 9. Sequence & verification

1. **Step 1** — refactor. First reversible move: no pixels change.
2. **Step 2** — Midnight + popover. Needs Step 1's `paintsPalette` and the sidebar's `t`.
3. **Step 3** — Umber. Needs Step 1. Confirm §7 first.
4. **Step 4** — docs.

Steps 2 and 3 are independent of each other; either can ship alone.

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture; do bash tools/$s.sh; done
```

Both green after every step, then the by-eye lists. No unit test to add: a palette has no
branch to break, and the one piece of logic — an unknown stored string falls back to
System — is a `??` that already exists.

---

## 10. More themes, later

After Step 1 a theme costs one `case` with three `switch` arms, one `static let`, one
`Theme.of` arm, one tile arm. **Graphite** and **Moss** are the next candidates and are
values only.

Two rules from this round:

- **Opaque `surface` by default.** A translucent one is what broke the popover (M1).
  Midnight earns its exception — the frosted read over the band is the point — and pays
  for it with one extra background.
- **No new mechanism until a listed theme needs it.** Paper grain, a second gradient shape,
  a per-theme face: that is where the cost returns.

## 11. Assumptions

- `[Inference]` The reference's corner-brighter edge is not worth reproducing (§3).
- `[Inference]` White 7% is the right surface. Tune by eye between 0.06 and 0.09.
- `[Inference]` M1's failure mode — derived from `SettingsView.swift:302-311` and
  `Theme.swift:67`, never observed. Check 7 confirms or clears it; the fix is harmless
  either way.
- `[Unverified]` The three rows in §8 marked so — they need a build and a look.
- `[Assumption]` Colours were sampled from a compressed screenshot; every measured hex ±2.
