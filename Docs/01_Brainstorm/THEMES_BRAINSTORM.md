# Themes — Brainstorm

Which *kinds* of theme One Word should ship, and the reason each earns a slot.

> **Where this sits.** Out of order on purpose: `02_Plan/THEMES_PLAN.md` was written first,
> straight from an operator brief with no upstream brainstorm (its §Scope says so). This
> fills that gap and answers the one call the resolved plan left open — **F1/F2, the second
> theme and its name** (`Resolved/THEMES_PLAN_RESOLVED.md:44`, Q2). Nothing here is decided.
> Grounded in the code at `c5d1ba4`; Steps 1–3 of the plan are **not built yet**.

---

## 1. The design space `Theme` already has

A theme is a value: nine colours plus three modifiers. Everything below is what a theme can
change **without one line of view code** — which is why most candidates cost ~15 lines.

| # | Axis | Field | Range in use |
|---|---|---|---|
| A1 | Ground | `background` | pure white · pure black · near-black |
| A2 | Surface | `surface` | opaque grey step · translucent white (frosted) |
| A3 | Sections | `tiles` | filled tiles · hairline blocks |
| A4 | Corners | `roundness` | ×1 (as drawn) · ×2.2 (pills) |
| A5 | Light | `glow` | none · a band/dome from the top |
| A6 | The one hue | `accent` + `rule` | none (ink) · periwinkle · brass |
| A7 | Display face | `DoodleTheme.face` | serif · geometric sans · marker |

A7 is the only one that is not free — a face is a `switch` arm in `face()`/`tracking()`,
not a field. Anything **outside** this table (paper grain, a second gradient shape, a
per-theme Devanagari face, time-of-day switching) is a new mechanism, and the plan's §10
rule applies: don't build the mechanism until a theme on the list needs it.

## 2. What the space looks like once the plan ships

| | Light | Dark | Midnight | Umber |
|---|---|---|---|---|
| Ground | white | black | near-black `#0F0F0F` | warm charcoal `#161412` |
| Temperature | neutral | neutral | cool | warm |
| Depth from | nothing | nothing | light + glass | nothing |
| Face | serif | serif | sans | serif |
| Hue | none | none | blue | brass |

Read down the columns and one thing jumps out:

> **Four painted looks, and three of them are dark.** The entire light half of the app is
> one untinted default that nobody designed — `#FFFFFF` with greys on it.

That is the single biggest hole, and it is the hole `DESIGN_BRIEF.md` §3 named and nobody
filled: *"a serif, editorial dictionary feel (cream paper, ink, a fine serif for the
headword) is the natural direction; a warmer ambers/golds palette is the other."* Both of
those describe a **light** theme. The app shipped neither.

Second observation: a word-of-the-day app is read in **daylight, at a desk**. Optimising the
dark half three times over and the light half zero times has the priorities backwards.

---

## 3. The candidates

Each one states the gap it fills — not the mood it evokes. Palettes are **sketches**;
contrast gets computed when one is picked, the way the plan did for Umber.

### Tier A — fills a hole that exists today

#### A-1 · **Paper** — warm light, serif, hairlines  ★ top pick

A cream ground, true ink, brass on the Hindi rule. Umber's palette turned inside out.

```
background  #F7F3EA   unbleached stock
surface     #EFE9DC
ink         #1C1815
muted       #6E6459
definition  #2A2520
example     #554C42
accent      #8A6A2F   brass, darkened to hold on a light ground
rule        accent @ 50%
hairline    ink @ 12%
roundness 1 · glow .clear · tiles false
```

**Why it earns a slot**

1. **It is the only candidate that adds to the light half.** Every other theme on this page,
   shipped or proposed, is dark. Light : dark is 1 : 3 today and 1 : 4 after Umber.
2. **It is the direction the brief named first** and the one the app was described as
   wanting from the beginning — "a beautiful desk dictionary."
3. **Pure white is the worst ground for the thing this app does.** Long definitions, two
   scripts, a screen you glance at all day. `#FFFFFF` at desk brightness is the highest-glare
   surface the app can draw; cream drops the luminance without dropping contrast.
4. **It is Umber for free.** Same decisions, same axes, inverted — so if you build Umber you
   have already done the thinking. Values only, no view code.
5. **The widget sits on a wallpaper.** Light users get white today; cream reads as *paper on
   a desk* rather than *a blank window* (see A-5 — the widget doesn't read `Theme` yet).

**Risk.** Warm light can look yellowed/aged on a cool-calibrated display. Mitigation: keep
the tint under ~4% saturation; `#F7F3EA` is a hair, not sepia.

#### A-2 · **High Contrast** — the one theme with a non-taste justification

Maximum separation on every pair: black on white (or white on black), visible hairlines, no
translucency, no glow, no muted greys below 7:1.

**Why it earns a slot**

1. **`DESIGN_BRIEF.md` §8 lists "sufficient contrast" as a requirement**, and the app half
   meets it. `muted #757575` on white is ≈4.6:1 — AA for body, **fails AAA**, and `muted`
   carries the part of speech, dates and every label. Midnight's `muted` is white @ 55%.
2. **Hairlines are invisible to the people who need them most.** `hairline` is ink at 11%
   everywhere — ≈1.1:1. Anyone with reduced contrast sensitivity sees no section structure
   at all. A theme where hairlines go to 40% is the only fix that doesn't ruin the other four.
3. **It can be automatic.** macOS exposes Increase Contrast; `@Environment(\.colorSchemeContrast)`
   can select this palette without the user finding Settings. That makes it the only theme
   that helps people who will never open the picker.
4. **Every other item here is taste. This one is a defect fix wearing a theme's clothes** —
   which also means it is the easiest to justify to yourself when the list gets cut.

**Risk.** Two of them, really (light and dark), or one that flips on the scheme. Prefer the
latter: `Appearance.highContrast` with `colorScheme → nil` and a `Theme.of` arm that picks
by scheme. That is slightly more than a `static let` — it is the first theme that *resolves*.

#### A-3 · **Widget parity** — not a theme; the thing that makes themes real

`WordWidgetView.swift:67` paints `.containerBackground(scheme == .dark ? .black : .white)`.
The widget has never read `Theme`, and Settings admits it.

**Why it belongs on a themes list**

1. **The widget is the product.** `DESIGN_BRIEF.md` §6D marks it **high priority** and
   PROJECT_CONTEXT's whole pitch is "the word is just *there* on their desktop, no app to
   open." The surface people actually look at is the one theming doesn't reach.
2. **Every theme you add makes the mismatch worse.** With Light and Dark, black/white was
   *correct*. With Midnight, Umber, Paper and High Contrast it is wrong four ways, and a
   user who picks Paper sees a stark white widget next to a cream app.
3. **Most of the wiring exists.** `Theme.swift` and `AppGroup.swift` are already compiled
   into both targets; `SavedWords`/`WordSelectionStore` already cross the App Group. What's
   missing is `Appearance` on the widget's side of the fence and the choice written to the
   group suite instead of standard defaults.

**Cost — the honest part.** This is the only Tier A item that is *not* values-only. `Appearance`
lives in `Models/` (app-only) and `Shared/` is referenced by explicit path in
`project.pbxproj` — moving it is a pbxproj edit and a `check_learned.sh` path update. Call it
a small change, not a free one. **Do it before the slate grows past Umber**, not after.

### Tier B — earns a slot on identity, if you want the app to have one

#### B-1 · **Manuscript** — the bilingual theme

Off-white ground, black ink, **vermilion** as the one hue — and the hue is spent on the
Hindi line, not on chrome. Serif Latin, generous leading for Devanagari.

**Why it earns a slot**

1. **The bilingual line is the app's only real differentiator**, and no theme spends
   anything on it. Every WOTD app has a dark mode; none of them set Hindi as a first-class
   element. `DESIGN_BRIEF.md` §6A explicitly asks: *"The Hindi should feel like a
   first-class part of the entry, not an afterthought."* Five themes in, it is still a line
   with a 60%-opacity border next to it.
2. **Red-on-off-white for the gloss is not decoration, it's the convention** — rubrication in
   manuscript traditions marks exactly this relationship: the primary text in ink, the
   gloss/heading in red. It is the correct typographic answer to "what colour is a translation."
3. **The dictionary shelf already proves colour works here.** `Wordbook.swift` gives Urdu a
   green cover, Philosophy an olive one — the app is already comfortable with a pigment
   vocabulary. This extends it inward by exactly one hue.

**Risk.** A culturally-specific palette can slide into costume. The guard: it must be a
*restraint* theme (two colours and a lot of paper), not an ornament theme. Also `Wordbook.swift:8`
records the rule *"covers are the only coloured surface — the reading UI stays monochrome."*
Manuscript is the one proposal that deliberately breaks that rule; it should break it on
purpose and only for the Hindi rule + Hindi text, or not at all.

#### B-2 · **Graphite** — cool neutral dark, depth from stacked greys

Already in the plan as fork F1. `#17181A` ground, opaque grey steps, `tiles: true`,
`roundness 1.4`, one soft-teal accent, no glow.

**Why it earns a slot** — it occupies A2+A5 in a way nothing else does: *depth without
light*. Midnight gets depth from a glow and glass; Umber and Paper refuse depth entirely.
Graphite stacks opaque greys, which is how most modern desktop UI reads. It is the answer if
Umber lands **too bookish** next to Midnight.

**Risk — and the reason it's Tier B.** The plan flags it: closest to plain Dark. A theme
whose honest description is "Dark, but with tiles" is a picker slot spent on very little.

#### B-3 · **Moss** — one hue, tinted throughout

`#0D1210` ground, sage ink, sage accent, serif, flat. Plan fork F1's third option.

**Why it earns a slot** — it is the only proposal where the hue is in the *ink*, not the
accent. That is a genuinely different construction and it's the answer if warm brown reads
dated to you.

**Risk.** Tinted body text tires the eye faster than neutral over a long read, and long
reads are what this app is for. That is why it sits below Graphite despite being more
distinctive.

### Tier C — needs a mechanism; don't build the mechanism yet

#### C-1 · **Sundial** — the appearance follows the time of day

Paper by day, Midnight or Umber after dark.

**Why it's interesting** — it matches the product loop better than anything else here. One
word, one day, ambient, never opened. A theme you never pick is the logical end of "no app
to open," and the widget refreshing on a daily timeline means the scheduling spine half
exists.

**Why Tier C** — it is not a palette, it is a *resolution policy*: a new `Appearance` arm
that resolves to a different `Theme` over time, plus invalidation (a static read can't
invalidate a view — the same trap `DoodleTheme`'s header comment already records), plus
widget timeline coordination so the two don't disagree at dusk. Revisit once there are two
light themes worth switching *between*; today there is one, and it isn't built.

#### C-2 · **Per-theme Devanagari / Nastaliq face**

Real Newsreader + Tiro Devanagari, as `Theme.swift`'s own header note has wanted since day
one — and Nastaliq for the Urdu book.

**Why Tier C** — it is font bundling and a second face axis in `face()`, not a theme. But
note it here because **B-1 Manuscript is the theme that would justify it**, and A7 is the
axis with the least room left. If Manuscript gets picked, this stops being optional.

---

## 4. Rejected, with reasons

| Idea | Why not |
|---|---|
| **Theme follows the selected dictionary** (Emotions → maroon, Philosophy → olive) | Breaks the rule `Wordbook.swift:8` states outright — covers are the only coloured surface. Also 9 books × 5 appearances is a matrix nobody can eyeball, and the reading pane would change colour when you switch books mid-session, which reads as a bug. |
| **A custom colour picker / user-defined themes** | Every pair in every palette is contrast-checked before it ships. A colour well hands people a one-click path to unreadable text and moves accessibility from "we verified it" to "hope they didn't." The plan also declines a registry, JSON themes and a `ThemeManager` by name — this needs all three. |
| **True-black OLED theme** | `Theme.dark.background` is already `.black`. There is nothing to add, and no Mac has an OLED panel to save power on. |
| **Seasonal / holiday themes** | Directly contradicts "calm, literary, quietly delightful" and buys permanent recurring maintenance. A word app's seasonal content is the *word*, not the chrome. |
| **A separate "Amber / night reading" dim theme** | Genuinely good idea that Umber already occupies — warm dark, serif, no glow. Shipping both spends two picker slots on one axis. If dimmed-for-night reading is the goal, **tune Umber toward it** rather than adding a fifth dark look. |
| **Sepia as its own theme, separate from Paper** | Same axis as A-1 at a different intensity. It's a slider on Paper, not a slot. Pick one temperature and commit. |

---

## 5. A recommended slate

Five painted looks plus System is about the ceiling before the picker stops being a choice
and starts being a menu. Proposed:

| Slot | Theme | Carries |
|---|---|---|
| 1 | **Light** | neutral paper, the default |
| 2 | **Dark** | neutral night, the default |
| 3 | **Midnight** | cool, lit, glass, sans, pills |
| 4 | **Paper** | warm light, serif, hairlines ← **new** |
| 5 | **Umber** | warm dark, serif, hairlines |
| — | **High Contrast** | resolves by scheme; ideally auto from the system setting |

That reads as a **2 × 2 the user can feel** — warm/cool × light/dark — with Midnight as the
one expressive outlier and High Contrast off to the side as an accessibility answer rather
than a taste. Graphite, Moss and Manuscript stay as forks; Sundial stays in Tier C.

### Order to build

1. **Plan Step 1** — the flag becomes the `Appearance`. Everything below is blocked on it,
   and it changes no pixels.
2. **Paper** (A-1). Biggest hole, values only, and it makes the picker feel like a grid
   instead of a list of dark modes.
3. **Umber** (plan Step 3, F1 default confirmed). Paper's partner — building the pair
   together is what makes both legible as a *system*.
4. **Widget parity** (A-3). Do it here, while the slate is five and not eight.
5. **High Contrast** (A-2). The first theme that resolves rather than being a constant.
6. Hold Graphite / Moss / Manuscript. Revisit after the five have been lived with.

### On the open call (plan F1/F2)

**Keep Umber, keep the name** — but the argument for it changes. The plan justified Umber as
"the different approach to Midnight." The stronger argument is that **Umber is half of a
pair**: it only fully pays off with Paper beside it, and building them together answers the
plan's own risk that Umber reads as "Dark, but brown." On its own that risk is real. Next to
Paper it evaporates, because the warmth becomes a *dimension of the system* rather than a
quirk of one theme.

---

## 6. Assumptions

- `[Sketch]` Every palette above is a starting point, not measured. Contrast per surface gets
  computed at plan time — the resolved plan's Step 3 is the template.
- `[Unverified]` A-2's `@Environment(\.colorSchemeContrast)` auto-selection has not been
  tried in this app; it may want to be an explicit picker slot too, for people who want it
  without turning on the system-wide setting.
- `[Inference]` A-3's cost estimate assumes `Appearance` can move to `Shared/` as a plain
  value. It imports SwiftUI for `ColorScheme` only, which the widget target has.
- `[Assumption]` Five painted looks is the picker's ceiling. That is a judgement about the
  `LazyVGrid` the plan introduces, not a measurement.
