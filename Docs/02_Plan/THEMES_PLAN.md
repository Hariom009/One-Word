# Themes — Plan

Three things, in this order:

1. **Make a theme cheap.** Today Midnight is a `Bool` threaded through the app. A second
   painted theme on that design is a second `Bool` at every site, so the flag becomes the
   `Appearance` itself. No visual change.
2. **Repaint Midnight.** Navy ground → neutral near-black, and the blue arrives as a band
   across the **top** edge (the reference has it along the bottom; we flip it). Same name,
   same stored value, same sans, same pills and tiles — colours and the glow's shape only.
3. **Add Umber.** A second dark theme built the opposite way: warm, flat, serif, hairlines.
   No glow, no glass, no pills.

> **Scope.** Grounded in the code on `main` (HEAD `c5d1ba4`). Nothing here is built yet.
> No upstream brainstorm or strategy doc — the brief came straight from the operator with
> a reference screenshot, so the design calls in §2 are recommendations, not settled taste.
> Scope shape: **single change**, three steps that each build green on their own.

**Reference.** A desktop AI-assistant window the operator likes: `#0F0F0F` ground, deep
blue rising from the bottom edge, neutral grey controls. Style only — colours and the shape
of the light. Same rule as Midnight's first reference: **never name the theme, a symbol or a
comment after the product, and none of its marks or artwork.**

**Detected stack** (each re-read for this plan): Xcode project, two targets, no
dependencies · SwiftUI · MVVM with `@Observable` · `SWIFT_VERSION = 5.0`,
`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`
(`project.pbxproj:549-553`) · `@AppStorage` / `UserDefaults` · macOS 14.0 · no XCTest
target — the gates are `tools/check_*.sh`, which compile Swift files by explicit path.

---

## 1. What we're reusing

| Need | Already here | File |
|---|---|---|
| A palette as a value | `struct Theme` — 9 colours + `roundness`, `glow`, `tiles` | [Theme.swift:15](../../OneWord/Shared/Theme.swift) |
| A painted ground under every pane | `paneBackground(_:)`, called by 11 panes and `PaneHeader` | [Theme.swift:88](../../OneWord/Shared/Theme.swift) |
| App-side palette resolution | `Theme.of(_:_:)` — the one place a pane asks "which palette?" | [DoodleTheme.swift:164](../../OneWord/Models/DoodleTheme.swift) |
| The display face, decided once | `DoodleTheme.face(_:_:)` / `tracking(_:)` | [DoodleTheme.swift:134](../../OneWord/Models/DoodleTheme.swift) |
| Hairline blocks vs filled tiles | `entryBlock(_:onTap:)` switches on `t.tiles` | [WordDetail.swift:332](../../OneWord/Views/WordDetail.swift) |
| The picker | `ForEach(Appearance.allCases)` → `AppearanceTile` | [SettingsView.swift:54](../../OneWord/Views/SettingsView.swift) |
| The stored choice | `@AppStorage("appearance")`, raw string, `?? .system` on a miss | [OneWordApp.swift:14](../../OneWord/OneWordApp.swift) |

Every call site already reads colour through `t.<token>` and every radius through
`t.radius(_:)`. That is why both themes below are almost entirely values: **Umber adds no
view code at all**, and Midnight's repaint touches one function.

**Not added:** a theme protocol, a registry, JSON-defined themes, a `ThemeManager`. A theme
is one `static let` and one `case`. **Not added:** a new font — Umber keeps the serif the
app already has. **Not touched:** the widget. It never reads `Theme` at all
(`WordWidgetView.swift:67` paints `.black` / `.white` from the scheme), and Settings
already says so.

---

## 2. Decisions

| # | Decision | Choice | Who / why |
|---|---|---|---|
| D1 | How a theme is carried | `DoodleTheme.midnight: Bool` → `DoodleTheme.appearance: Appearance` | **Code.** The flag is set or read at 10 sites in 4 files; a second `Bool` doubles each. One enum keeps them single, and an exhaustive `switch` makes the compiler list every site when theme #3 arrives. |
| D2 | Where palette resolution lives | Stays in `extension Theme` in `DoodleTheme.swift` | **Code.** `Theme.swift` is compiled into the widget and into `check_learned.sh:194` by explicit path; neither has `Appearance`. A reference to it there breaks both. |
| D3 | Midnight's stored value | Keep `"midnight"` | **Code.** It is a raw string in `UserDefaults`; a rename silently drops every Midnight user to System. |
| D4 | Shape of the blue | A **y-only band of fixed height**, not the dome (`RadialGradient`) and not a bounds-relative gradient | **Code — see §3.** It is the only shape that survives both seams the app has. |
| D5 | Midnight's type and shapes | Unchanged: Plus Jakarta Sans, `roundness 2.2`, tiles | **Operator:** "use colors like this". |
| D6 | The second theme | **Umber** — warm charcoal, parchment ink, brass accent, serif, hairlines, square corners | **Recommended; operator's to overrule — fork F1.** |
| D7 | Settings picker layout | `HStack` → adaptive `LazyVGrid` | **Code.** Five tiles fit the 520pt column (96pt each); a sixth, or a narrow window, does not. One line now beats a truncated "Midnight" later. |

### Why Umber is the *different approach*

| | Midnight | Umber |
|---|---|---|
| Depth comes from | light — a band of blue, glass tiles over it | temperature — nothing glows, nothing floats |
| Ground | neutral `#0F0F0F` + gradient | flat warm `#161412` |
| Surfaces | translucent white (frosted) | opaque warm stock |
| Sections | filled tiles | hairline rules |
| Corners | ×2.2 — pills | ×1 — as drawn |
| Face | geometric sans, tight | the editorial serif |
| One hue | cool blue | brass, spent on the Hindi rule |

It is also the direction `DESIGN_BRIEF.md` §3 named and nobody built: *"a serif, editorial
dictionary feel … a warmer ambers/golds palette is the other."* A dictionary by lamplight.

---

## 3. The band — measured, and why it is y-only

Sampled from the reference (2000×1134, sRGB), columns clear of text:

| From the glowing edge | 1.5% | 5% | 10% | 15% | 22% | 30% | 38% | 45% |
|---|---|---|---|---|---|---|---|---|
| Colour (x = 15%) | `#141F4B` | `#121D47` | `#131D43` | `#121B3C` | `#12172F` | `#111320` | `#101118` | `#0F1112` |
| Strength vs peak | 0.95 | 0.89 | 0.83 | 0.71 | 0.51 | 0.27 | 0.14 | 0.05 |

Ground `#0F0F0F` everywhere else. Peak `#15204E` (corners); the centre of the edge runs a
few levels darker (`#101733`) — a difference this plan deliberately drops `[Inference: not
visible at pane scale]`.

So: full at the edge, half by ~22% of the height, gone by ~48%. On the default 680pt window
that is **half at ~150pt, gone at ~330pt** → stops `1.0 @ 0`, `0.5 @ 0.45`, `0 @ 1` over a
**330pt** band. Today's dome peaks at about `#19295C`; the new peak is a touch quieter.

**Why fixed height and y-only.** Two seams constrain the shape:

- **Header seam.** `PaneHeader` is a 52pt strip that paints the pane's ground *again*
  (`PaneHeader.swift:90`) and relies on "same top, same width" to line up with the pane
  behind it (`PaneHeader.swift:22-24`). Anything sized relative to bounds —
  `LinearGradient(.top → .bottom)`, `EllipticalGradient`, a `UnitPoint` above the edge —
  compresses into 52pt and the seam shows. Today's dome works only because its radius is in
  points. The band must be in points too.
- **Sidebar split.** The sidebar is painted flat (`RootView.swift:159`). The dome is weakest
  at the pane's corners, so that edge is soft today. A band is *full strength* at the corner
  — a hard vertical edge against a flat sidebar. A gradient with no x in it can be painted
  in the sidebar as well and meets the pane perfectly at any column width.

A fixed band also leaves more neutral black under the text as the window grows, which suits
a reading app better than a proportional one.

---

## 4. Implementation steps

### Step 1 — the flag becomes the appearance *(refactor; pixel-identical)*

| File | Change |
|---|---|
| `OneWord/Models/Appearance.swift` MODIFIED | Add `var paintsPalette: Bool` — `true` for `.midnight`, exhaustive `switch`, no `default`. Pure value; stays `nonisolated`. |
| `OneWord/Models/DoodleTheme.swift` MODIFIED | `var midnight = false` → `var appearance: Appearance = .system`. `current` (`:92`) parses `Appearance(rawValue:) ?? .system`. `face` (`:140`) and `tracking` (`:154`) test `appearance == .midnight`. `Theme.of(_:_:)` (`:164`) becomes an exhaustive `switch look.appearance` — `.midnight → .midnight`; `.system, .light, .dark → .of(scheme)`. |
| `OneWord/OneWordApp.swift:34` MODIFIED | Pass `appearance: Appearance(rawValue: appearance) ?? .system` — the same parse line 37 already does; hoist it to one `let`. |
| `OneWord/Views/RootView.swift:118,158,159` MODIFIED | `doodle.midnight` → `doodle.appearance.paintsPalette`; `Theme.midnight.background` → `t.background`. |
| `OneWord/Views/SettingsView.swift:385-399` MODIFIED | `page(_:midnight:)` → `page(_ t: Theme, as mode: Appearance)`; it sets `look.appearance = mode` so each tile draws in the face it would really get. |

**Isolation.** `Appearance` and `DoodleTheme` are `nonisolated`; `Theme` is MainActor by the
project default. `paintsPalette` must therefore **not** return or touch a `Theme` — a
`var palette: Theme?` on `Appearance` reads MainActor statics from a nonisolated context.
Resolution stays in `Theme.of(_:_:)`, which is MainActor like every `body` that calls it.

**Verify.** Build + all gates. Midnight, Light, Dark and System look exactly as before;
`grep -rn "\.midnight" OneWord` shows no `doodle.midnight` left.

### Step 2 — repaint Midnight

`OneWord/Shared/Theme.swift` MODIFIED — values:

| Token | Now | New | Note |
|---|---|---|---|
| `background` | `#080F1B` | `#0F0F0F` | measured |
| `surface` | white 9% | white 7% | → `#202020` on the ground; the reference's controls are `#1C1C1C`. Still translucent, so a tile over the band picks up blue — keeps the frosted read. |
| `accent` | `#A5B4FC` | `#A8C7FA` | lavender → a truer light blue. The reference's button blue (`#223E9B`) is a *fill*; at 2.2:1 on the ground it cannot be our accent, which is drawn as text and glyphs. |
| `rule` | accent 60% | accent 60% | follows |
| `glow` | `#3B5BDB` | `#15204E` | now the band's **peak colour**, painted opaque at the edge — no longer a colour at 0.34 alpha. Update the doc comment. |
| ink · muted · definition · example · hairline · roundness · tiles | — | unchanged | |

Contrast on the new ground / on the band's peak: ink 18.5 / 15.1 · definition 14.1 / 11.8 ·
example 9.6 / 8.2 · muted 6.2 / 5.6 · accent 11.2 / 9.1. All clear AA.

Same file — `paneBackground(_:)` (`:88-101`):

- Lift the ground into `struct PaneGround: View { let t: Theme }` so the sidebar can paint
  it too; `paneBackground` becomes `background { PaneGround(t: t) }`.
- Body: `t.background`, with the band as an `.overlay(alignment: .top)` —
  `LinearGradient(stops:)` from `t.glow` to `t.glow.opacity(0)` at the stops in §3,
  `.frame(height: 330)` — then `.clipped()`, then `.ignoresSafeArea()`. The clip is
  load-bearing: in the 52pt header an unclipped 330pt overlay spills over the content
  scrolling beneath it.
- Keep the two facts the current comment records: under the content, and plain alpha with
  no blend mode (the blend-mode overlay re-composited every moving frame).
- `330` and the stops are local constants. Umber has no glow, so nothing else needs them —
  promote to `Theme` fields the day a second glowing theme exists.

`OneWord/Views/RootView.swift:158-159` MODIFIED — the sidebar paints
`PaneGround(t: t)` when `paintsPalette`, in place of the flat colour.

`OneWord/Views/SettingsView.swift:408` MODIFIED — the tile's `page` draws a miniature:
`t.background` with a top-to-bottom `t.glow → clear` gradient over it when `t.glow != .clear`.
(The real 330pt band would fill a 58pt tile with solid blue.)

Header comments in `Theme.swift` (`:5-8`, `:62-64`) and `Appearance.swift` (`:6-8`) say
"navy" — rewrite them to what is true.

**Verify, by eye — the build cannot see any of this:**
1. Home, scrolled: no line where the header strip meets the pane.
2. The band meets itself across the sidebar divider at the same y, sidebar folded and open.
3. Full screen: band starts at the very top, no grey strip.
4. A list pane (Search, Bookmarks): rows stay clear over the band.
5. Dictionaries: spines and their shadows still read on `#0F0F0F`.
6. Settings: the Midnight tile shows a small band.

### Step 3 — Umber

| File | Change |
|---|---|
| `OneWord/Models/Appearance.swift` MODIFIED | `case umber`; `name → "Umber"`; `colorScheme → .dark`; `paintsPalette → true`. |
| `OneWord/Shared/Theme.swift` MODIFIED | `static let umber` — below. |
| `OneWord/Models/DoodleTheme.swift` MODIFIED | One arm in `Theme.of`: `.umber → .umber`. `face` / `tracking` untouched — Umber falls through to the serif, and Handwriting still outranks it. |
| `OneWord/Views/SettingsView.swift` MODIFIED | `preview` (`:385`) gains `case .umber: page(.umber, as: .umber)`. The picker `HStack` (`:53`) → `LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10)`. |

The compiler finds every one of these: each `switch` is exhaustive.

```
background  #161412   warm charcoal — lifted off black so it reads as stock, not void
surface     #1F1C19   opaque, one step up
ink         #EDE6DA   parchment
muted       #9C9284
definition  #DDD5C8
example     #B9AFA0
accent      #D0A667   brass
rule        #D0A667 @ 55%      the Hindi border is where the one hue is spent
hairline    #EDE6DA @ 10%
roundness 1 · glow .clear · tiles false      (all three are the defaults — omit them)
```

Contrast on ground / on surface: ink 14.8 / 13.7 · definition 12.6 / 11.7 · example 8.5 / 7.8
· muted 6.0 / 5.5 · accent 8.2 / 7.5. All clear AA.

**Verify.** Build + gates. Pick Umber: serif headword, hairline sections, square corners,
brass Hindi rule, brass switches, warm sidebar. Turn Handwriting on → the marker face wins,
palette stays. Relaunch → it sticks. Set `appearance` to a junk string in defaults → System.

### Step 4 — standing docs

- `Docs/00_Context/DESIGN_BRIEF.md` §3 / §8 — it still says "a light + dark theme". Record
  the four looks and what each is for.
- `Docs/00_Context/ARCHITECTURE.md` — a short "adding a theme" note: one `case`, one
  `static let`, the compiler lists the rest.

---

## 5. Isolation, state, memory

Nothing here is async and nothing escapes: no `Task`, no closure capture, no retain-cycle
surface. The whole concurrency story is D2 and the isolation note in Step 1 —
`nonisolated` values must not reach for MainActor `Theme` statics. State ownership is
unchanged: `@AppStorage("appearance")` is read in `OneWordApp` and `SettingsView`, resolved
once into the environment, and every pane reads `\.doodle`.

`DoodleTheme` stays `Equatable` by synthesis (`Appearance` is a `String` enum) —
`DoodleSample`'s `.animation(value: doodle)` depends on that.

---

## 6. Accessibility & mechanics

- Text contrast is computed above; both themes clear AA on every surface they meet.
- `accent.opacity(0.5)` draws the 52pt empty-state glyphs: 3.6:1 in Midnight, **2.9:1 in
  Umber**. Decorative and large, but it is the weakest pair in the plan — nudge the brass
  lighter if it looks faint.
- The tile already carries `.isSelected`; "Umber" is read from `name`. No new labels.
- No new files → no `project.pbxproj` edit, no target-membership risk. `Theme.swift` stays
  free of app-only types, so `check_learned.sh` needs no change.
- No new fonts, assets, entitlements or strings files.

---

## 7. Forks — the operator's

**F1 — the second theme.** Recommended: **Umber**. After Step 1 each alternative is the same
~15 lines, so this is cheap to change — before it ships. After, the raw value is in
people's defaults (D3).
- **Graphite** — cool neutral `#17181A`, depth from stacked opaque greys, `tiles: true`,
  `roundness 1.4`, one soft-teal accent. Wins if Umber reads *too bookish* next to
  Midnight and you want a second modern look. Risk: closest to plain Dark.
- **Moss** — one hue, tinted throughout: `#0D1210` ground, sage ink, sage accent, serif,
  flat. Wins if warm brown feels dated. Risk: tinted body text tires faster than neutral.

**F2 — the name.** "Umber" is a pigment, and a good word for a vocabulary app. "Ember" is
more familiar but promises a glow the theme refuses to have. Decide before shipping (D3).

**F3 — does Midnight keep its sans?** Kept (D5). The reference is a sans too, so nothing
argues for a change — flagged only because it is the one part of the look not asked about.

---

## 8. Risks & exits

| Risk | Sev · Conf | Leading indicator | Exit |
|---|---|---|---|
| `.clipped()` + `.ignoresSafeArea()` order leaves the band short of the window top, or the header seam shows | Med · Med `[Unverified — not compiled]` | Verify 1 and 3 in Step 2 | Swap the order; failing that, `GeometryReader`-free fallback: keep `RadialGradient(center: .top)` with the new colours and `endRadius ≈ 900` — a dome again, seam-safe by construction, loses the horizon. |
| Sidebar's ground does not start at the same y as the pane's | Med · Low `[Unverified]` — the sidebar's safe-area behaviour under a hidden title bar was not tested | Verify 2 | Sidebar goes back to flat `t.background`; judge the hard edge by eye, and soften by ending the band's first stop at 0.8. |
| Sidebar selection: white label on a light accent fill — 1.7:1 Midnight, 2.3:1 Umber | Low · High — **pre-existing** (periwinkle is 2.0:1 today) | Selected row hard to read while the sidebar has focus | Out of scope here; a darker `tint` separate from `accent` is its own small change. |
| Band is too quiet or too loud once real content sits on it | Low · Med | First look | `glow` and the three stops are the only knobs. |
| Umber is "Dark, but brown" — too little to justify a slot | Med · Low — taste | First look at the mockup | F1. |

---

## 9. Sequence & verification

1. Step 1 — refactor. **First reversible move**: no pixel changes, reverts clean.
2. Step 2 — Midnight. Depends on 1 only for `paintsPalette` in the sidebar.
3. Step 3 — Umber. Depends on 1.
4. Step 4 — docs.

Steps 2 and 3 are independent of each other; either can ship alone.

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture; do bash tools/$s.sh; done
```

Both green after every step, then the by-eye lists in Steps 2 and 3. There is no unit test
to add: a palette has no branch to break, and the one piece of logic — an unknown stored
string falls back to System — is a `??` that already exists.

---

## 10. More themes, later

After Step 1 a theme costs: one `case` with three `switch` arms, one `static let`, one
`Theme.of` arm, one tile arm. **Graphite** and **Moss** (F1) are the next two candidates
and are values only. Anything wanting a *new mechanism* — paper grain, a second gradient
shape, a per-theme face — is where the cost returns; do not build that mechanism until a
theme on the list needs it.

## 11. Assumptions

- `[Inference]` The reference's corner-brighter edge is not worth reproducing (§3).
- `[Inference]` White 7% is the right surface; the reference's opaque `#1C1C1C` would cost
  the frosted read over the band. Tune by eye between 0.06 and 0.09.
- `[Unverified]` Both items in §8 marked so — they need a build and a look, which this plan
  does not do.
- `[Assumption]` Colours were sampled from a compressed screenshot; treat every measured
  hex as ±2 levels.
