# Themes — the rest of the slate — Plan

Three things, in this order:

1. **Add Paper.** A warm light theme: cream stock, true ink, brass. Umber's palette turned
   inside out, and the first thing ever designed for the light half of the app. Values only.
2. **Give the widget the palette.** `WordWidgetView.swift:67` paints `.black` / `.white`
   from the scheme and has never read `Theme`. Four painted themes in, that is now wrong
   four ways on the surface the product is actually about.
3. **Add High Contrast.** The first appearance that *resolves* — light or dark by the
   scheme — and the first one the Mac can pick for you.

> **Scope.** Grounded in the working tree at `5f0b6bd`, where
> [THEMES_PLAN_RESOLVED.md](Resolved/THEMES_PLAN_RESOLVED.md) is **already built**:
> `Appearance` carries the theme (`Appearance.swift:44`), Midnight is repainted near-black
> with its band (`Theme.swift:72`, `PaneGround` at `:111`), and Umber has shipped
> (`Theme.swift:93`). That plan's open call F1/F2 is closed by the code.
>
> Upstream: [THEMES_BRAINSTORM.md](../01_Brainstorm/THEMES_BRAINSTORM.md). This plan builds
> its three **Tier A** items and nothing else — Manuscript, Graphite, Moss and Sundial stay
> forks (§8). Scope shape: **three steps, each green and shippable on its own.**

**Stack** (re-read for this plan): Xcode project, two targets · SwiftUI · MVVM with
`@Observable` · `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` ·
`@AppStorage` / `UserDefaults` / App Group · macOS 14.0 · no XCTest target — the gates are
`tools/check_*.sh`, which compile Swift files by explicit path.

> **A note on tooling.** Xcode's MCP file tools served a **stale snapshot** of this repo
> while this plan was being written (they showed `DoodleTheme.midnight: Bool`, which has not
> existed since Step 1 shipped). Every line number and every quoted line below was re-read
> from disk. If you verify with `XcodeRead` and disagree with a citation, check the file
> directly before trusting it.

---

## 1. What we're reusing

| Need | Already here | File |
|---|---|---|
| A palette as a value | `struct Theme` — 9 colours + `roundness`, `glow`, `tiles` | `OneWord/Shared/Theme.swift:18` |
| Four palettes to pattern-match | `.light` `.dark` `.midnight` `.umber` | `Theme.swift:42,54,72,93` |
| A painted ground | `PaneGround` + `paneBackground(_:)` | `Theme.swift:111,153` |
| App-side resolution | `Theme.of(_ scheme:_ look: DoodleTheme)` — exhaustive, no `default` | `DoodleTheme.swift:169` |
| "Does this appearance bring a palette?" | `Appearance.paintsPalette` | `Appearance.swift:44` |
| The picker | `LazyVGrid(.adaptive(minimum: 92))` → `AppearanceTile` | `SettingsView.swift:55,362` |
| A tile that previews in its own face | `page(_ t: Theme, as mode: Appearance)` | `SettingsView.swift:404` |
| Cross-process storage | `AppGroup.defaults`, already carrying `dictionaryID` / `showHindi` / `showExample` | `AppGroup.swift:35,37,46` |
| Telling the widget to repaint | `WidgetCenter.shared.reloadAllTimelines()` — 5 existing call sites | `SettingsView.swift:110` |
| A shared file reaching the widget | `SharedRefs` group + the widget's Sources phase | `project.pbxproj:136,442CD88A` |

Every view reads colour through `t.<token>` and every radius through `t.radius(_:)`, so
**Step 1 adds no view code at all** and Step 3 adds one small wrapper. Step 2 is the only
structural one.

**Not added:** a theme protocol, a registry, JSON themes, a `ThemeManager`, a new font, a
new mechanism of any kind. The rule from the last round still holds: *no new mechanism until
a listed theme needs it.*

**Not renamed:** `DoodleTheme`. Already a misnomer, already argued, still not worth the churn
across 23 `Theme.of(scheme, doodle)` call sites.

---

## 2. Decisions

| # | Decision | Choice | Who / why |
|---|---|---|---|
| D1 | The light-side theme | **Paper** — cream stock, true ink, brass, serif, hairlines | **Recommended; operator's to overrule — fork F1.** It is the direction `DESIGN_BRIEF.md` §3 named first and nobody built, and it is the only proposal that touches the light half. |
| D2 | Paper's accent | `#63491B` — a **darkened** brass, not Umber's `#D0A667` | **Code.** The brainstorm's `#8A6A2F` measures 4.53:1 on the cream and **4.15:1 on the surface** — under AA. `#63491B` is 7.59 / 6.95, which lands it in Umber's band (8.2 / 7.5). §4 has the table. |
| D3 | Paper's `muted` | `#60564B` — 6.47:1, deliberately stronger than Light's | **Code.** `Light.muted #757575` is **4.61:1 on white** — AA by 0.11, and it carries every part of speech, date and label. A new light theme should not inherit the weakest pair in the app. |
| D4 | Where widget palette resolution lives | A new `Theme.of(_ scheme:_ appearance: Appearance)` **in `Theme.swift`** | **Code — this reverses the old plan's D2.** That decision was "Theme.swift must not name `Appearance`, because the widget and `check_learned.sh:194` compile it without one." Step 2 gives both of them `Appearance`, which is exactly what removes the constraint. |
| D5 | `.light` / `.dark` in the widget | Resolve **directly**, not through the scheme | **Code — §5.1.** In the app these are identical because `preferredColorScheme` has already forced the scheme. In the widget nothing forces it, so `.of(scheme)` would paint Dark for a user who picked Light on a dark Mac. |
| D6 | Where the appearance is stored | Moves from `UserDefaults.standard` to `AppGroup.defaults` | **Code.** The widget is a separate process; standard defaults are not shared. Same move `dictionaryID` and `showHindi` already made. |
| D7 | Migration | One-time copy in `OneWordApp.init()`, guarded on the group key being absent | **Code — §5.2.** Without it every Midnight and Umber user silently resets to System on update. |
| D8 | High Contrast as one case, not two | One `case highContrast`, `colorScheme → nil`, resolving to `.highContrastLight` / `.highContrastDark` | **Code.** Two picker slots for one idea, and neither could follow the Mac. |
| D9 | Auto-selection from the Mac's Increase Contrast | **Only under `.system`** | **Code + principle — §6.2.** Picking `.system` means "follow the Mac", and Increase Contrast *is* the Mac. Picking Paper or Midnight is an override, and an override should not be silently overridden back. |
| D10 | How contrast reaches the palette | A `DoodleTheme.increasedContrast` flag, set by one wrapper view | **Code.** Adding a parameter to `Theme.of` is **23 call sites in 14 files**. The flag rides the value already resolved once at the root and handed down — the pattern `DoodleTheme.swift:70-71` documents. |
| D11 | `paintsPalette` moves | `Appearance.paintsPalette` → `DoodleTheme.paintsPalette` | **Code.** Under D9, `.system` *can* paint a palette. The question needs both the appearance and the contrast, so it belongs on the value that has both. Two call sites (`RootView.swift:118,161-162`). |

### Why Paper is the right fourth palette

| | Light | Umber | **Paper** |
|---|---|---|---|
| Ground | `#FFFFFF` | `#161412` warm charcoal | `#F7F3EA` cream stock |
| Temperature | neutral | warm | warm |
| Depth from | nothing | nothing | nothing |
| Sections | hairlines | hairlines | hairlines |
| Face | serif | serif | serif |
| One hue | none — accent is ink | brass on the Hindi rule | brass on the Hindi rule |

Paper is **Umber's reflection**, and that is the point. It closes a 2 × 2 the user can feel —
warm/cool × light/dark — and retires the risk the last plan filed against Umber itself
(*"Dark, but brown"*): warmth stops being one theme's quirk and becomes a dimension of the set.

---

## 3. What is wrong with the widget, concretely

`WordWidgetView.swift` paints the **system label hierarchy** on a black-or-white container:

| Line | Draws | With |
|---|---|---|
| `:67` | the container | `.containerBackground(scheme == .dark ? .black : .white)` |
| `:86` | refresh glyph | `.tertiary` |
| `:105`, `:132`, `:153` | headword, Hindi ×2 | `.primary` |
| `:113`, `:176`, `:199`, `:213` | pos, definition ×2, example | `.secondary` |
| `:126` | the Hindi rule | `.tertiary` |
| `:206` | the example hairline | `.quaternary` |

Two separate problems, and the second is why the fix cannot be one line:

1. **The ground ignores the choice.** Pick Umber and the app goes warm charcoal; the widget
   two inches away stays black or white.
2. **The ink is the system's, not the app's.** A widget has no `preferredColorScheme` — it
   takes the Mac's scheme. So with the **Mac in Light** and the app in **Umber or Midnight**,
   changing only `:67` paints a dark ground and leaves `.primary` resolving to *black*.
   Unreadable. `[Inference — follows from the code; not run.]`

So `:67` and all nine `foregroundStyle` sites move together, or neither moves.

---

## 4. Paper — the palette

```
background  #F7F3EA   unbleached stock — a tint, not sepia
surface     #EFE9DC   one step down, opaque (the rule Umber's round set)
ink         #1C1815   true ink, warmed a hair off black
muted       #60564B   D3 — stronger than Light's
definition  #2A2520
example     #554C42
accent      #63491B   D2 — brass, darkened until it holds on cream
rule        #63491B @ 50%
hairline    #1C1815 @ 16%
roundness, glow, tiles — omit; the defaults are right, as .light, .dark and .umber do
```

Contrast, **ground / surface** (computed, sRGB, WCAG 2.1):

| Token | ground | surface | Umber, for scale |
|---|---|---|---|
| `ink` | **15.92** | 14.58 | 14.8 / 13.7 |
| `definition` | **13.70** | 12.54 | 12.6 / 11.7 |
| `example` | **7.59** | 6.95 | 8.5 / 7.8 |
| `muted` | **6.47** | 5.92 | 6.0 / 5.5 |
| `accent` | **7.59** | 6.95 | 8.2 / 7.5 |

All clear AA, and every pair beats the corresponding one in `Theme.light`.
`hairline` at 16% measures 1.39:1 against 1.28:1 in Light — a little stronger on purpose,
because cream gives a hairline less to separate from than white does.

**The one weak pair.** `accent.opacity(0.5)` draws the 52pt empty-state glyphs at
`WordListView.swift:186,191` and `LearnedListView.swift:217`. On Paper that measures
**2.37:1** — below Umber's 2.94, which the last plan already called the weakest thing it
shipped. Decorative and large, so it is not a blocker, but it is the one number here that
does not clear. Exit in §7; it is a taste call to make by eye, not in advance.

---

## 5. Implementation

### Step 1 — Paper *(values only; no view code)*

| File | Change |
|---|---|
| `OneWord/Models/Appearance.swift` | `case paper` in the `allCases` list (`:17`). `name → "Paper"` (`:26`). **`colorScheme → .light`** — join the `.light` arm at `:35`. `paintsPalette → true` — join `:47`. |
| `OneWord/Shared/Theme.swift` | `static let paper` after `.umber` (`:103`), the values in §4, with a doc comment saying what it is: Umber's reflection, and the light half's first designed palette. |
| `OneWord/Models/DoodleTheme.swift:170` | One arm: `case .paper: return .paper`. `face` (`:143`) and `tracking` (`:157`) are untouched — Paper falls through to the serif, and Handwriting still outranks everything. |
| `OneWord/Views/SettingsView.swift:396` | One arm in `preview`: `case .paper: page(.paper, as: .paper)`. |

The compiler finds all four: every `switch` in the chain is exhaustive with no `default`.
The picker grid is already `.adaptive` (`:55`), so a sixth tile wraps rather than clipping.

**Picker order.** `Appearance.allCases` follows declaration order, and the raw strings are
what's stored — so reordering is free and invisible. Put the pairs together:
`system, light, paper, dark, midnight, umber`. Light-side first, warm beside cool.

**Verify.** Build + all four gates. Pick Paper: cream ground, serif headword, brass Hindi
rule, brass toggles, hairline sections, square corners, warm sidebar, no band. Handwriting
on → the marker face wins and the palette stays. Relaunch → it sticks. Then the by-eye list:

1. The empty-state glyph in Search and Bookmarks — **the 2.37:1 pair.** Faint, or fine?
2. An (i) popover in Settings, Mac in Light **and** in Dark. Paper's surface is opaque, so
   the fix at `SettingsView.swift:317` should already carry it — confirm.
3. The Dictionaries shelf: nine painted covers were sampled against white and near-black.
   Do the spines and their shadows still read on cream?
4. Midnight's tile and Paper's tile side by side in the picker — the grid should read as
   pairs now, not a list.

### Step 2 — the widget gets the palette

**2a · `Appearance` becomes shared.**

| File | Change |
|---|---|
| `OneWord/Models/Appearance.swift` → `OneWord/Shared/Appearance.swift` | `git mv`. Both directories are inside the app target's synchronized group, so the **app** target follows automatically. |
| `OneWord.xcodeproj/project.pbxproj` | The **widget** does not. Add a `PBXFileReference` (`path = OneWord/Shared/Appearance.swift`, the shape of `:77`), add it to the `SharedRefs` group's `children` (`:136-153`), and add a `PBXBuildFile` + an entry in the widget's Sources phase (`442CD88A…`). |
| `tools/check_learned.sh:194` | Add `"$ROOT/OneWord/Shared/Appearance.swift"` before `Theme.swift` — 2b makes `Theme.swift` name `Appearance`, and this gate compiles it by explicit path. |

> Do 2a's pbxproj edit **in Xcode** (drag the file, tick the widget in Target Membership),
> not by hand. Three linked sections with generated UUIDs is where a hand edit corrupts a
> project. Confirm afterwards that both the group and the Sources phase list it.

**2b · resolution moves to `Theme.swift` (D4, D5).**

`OneWord/Shared/Theme.swift` — add beside `of(_ scheme:)` at `:105`:

```swift
/// The palette for an appearance. `.light` and `.dark` resolve DIRECTLY rather than
/// through the scheme: in the app that is the same answer, because
/// `preferredColorScheme` has already forced the scheme to match — but the widget is a
/// separate process with nothing forcing it, and `.of(scheme)` there would paint Dark
/// for someone who picked Light on a dark Mac.
static func of(_ scheme: ColorScheme, _ appearance: Appearance) -> Theme {
    switch appearance {          // no `default`: a new case must answer here
    case .midnight: return .midnight
    case .umber:    return .umber
    case .paper:    return .paper
    case .light:    return .light
    case .dark:     return .dark
    case .system:   return .of(scheme)
    }
}
```

`OneWord/Models/DoodleTheme.swift:169-176` collapses to a delegate:
`Theme.of(scheme, look.appearance)`. All 23 app-side call sites are untouched.

**2c · the choice moves to the App Group (D6, D7).**

`OneWord/Shared/AppGroup.swift` — beside `dictionaryKey` (`:37`):

```swift
static let appearanceKey = "appearance"

/// The picked appearance. Unknown or missing is System, as it is at the app root.
static var appearance: Appearance {
    defaults.string(forKey: appearanceKey).flatMap(Appearance.init(rawValue:)) ?? .system
}

/// One-time lift out of standard defaults, where this lived until the widget started
/// reading it. Without it, every Midnight and Umber user resets to System on update.
/// Guarded on absence, so it cannot clobber a later choice.
static func migrateAppearance() {
    guard defaults.object(forKey: appearanceKey) == nil,
          let old = UserDefaults.standard.string(forKey: appearanceKey) else { return }
    defaults.set(old, forKey: appearanceKey)
}
```

Then, in order:

- `OneWord/OneWordApp.swift` — add `init() { AppGroup.migrateAppearance() }`. **Ordering is
  load-bearing:** `@AppStorage` reads through on access, and the first access is the first
  `body`, which is after `init()`. `AppDelegate` (`WordCapture.swift:23`) is the other
  candidate and is *not* safe — `applicationWillFinishLaunching` is not guaranteed to
  precede the first body evaluation. `[Unverified — reasoned from the property wrapper's
  semantics, not observed.]`
- `OneWord/OneWordApp.swift:14` and `OneWord/Views/SettingsView.swift:20` —
  `@AppStorage("appearance", store: AppGroup.defaults)`.
- `OneWord/Models/DoodleTheme.swift:98` — `UserDefaults.standard` → `AppGroup.defaults`.
  (`iconsKey` / `handwritingKey` stay in standard defaults: the widget ships neither the
  doodle art nor Pulpen, so sharing them would promise it something it cannot draw. The
  comment at `:15-17` already says this — extend it to note that `appearance` is now the
  exception.)

**2d · the widget paints it.**

`OneWordWidget/WordWidgetView.swift` — `let t = Theme.of(scheme, AppGroup.appearance)` at the
top of `body` (`:52`), then the eleven sites from §3:

| Site | From | To |
|---|---|---|
| `:67` | `.black` / `.white` | `t.background` |
| `:105`, `:132`, `:153` | `.primary` | `t.ink` |
| `:113` | `.secondary` (part of speech) | `t.muted` |
| `:176`, `:199` | `.secondary` (definition) | `t.definition` |
| `:213` | `.secondary` (example) | `t.example` |
| `:126` | `.tertiary` (Hindi rule) | `t.rule` |
| `:206` | `.quaternary` (hairline) | `t.hairline` |
| `:86` | `.tertiary` (refresh glyph) | `t.muted` |

`refresh()` and `ruledHindi()` are `private func`s without `t` in scope — pass it, or hoist
`t` to a stored `private var` computed from `scheme`. Passing is the smaller diff.

**This is not pixel-identical for existing users, on purpose.** System / Light / Dark grounds
are unchanged (`Theme.light.background` *is* `.white`), but the ink moves from the system
label hierarchy to the app's ramp — `.secondary` becomes `#4A4A4A`-ish rather than a
system alpha. The widget joins the app's typography instead of approximating it. Say so in
the header comment.

**2e · the seams.**

- `OneWord/Views/SettingsView.swift:110` — add
  `.onChange(of: appearance) { WidgetCenter.shared.reloadAllTimelines() }`. Without it the
  widget keeps the old palette until its next timeline entry.
- `OneWord/Views/SettingsView.swift:52-53` — the Appearance section's note still reads *"The
  app only — the desktop widget follows the Mac's own light or dark."* **Now false.** Rewrite:
  the widget follows the palette; the Doodle note below it (`:70-71`) stays true and unchanged.
- Comments the step makes false: `Theme.swift:8-11` ("The widget reads no Theme at all… So
  nothing app-only may be named here"), `WordWidgetView.swift:5-11` ("monochrome… no palette,
  no accent… Both appearances follow the system color scheme"), `AppGroup.swift:5-6`.
- `Resolved/THEMES_PLAN_RESOLVED.md` D2 is superseded by D4. Don't edit it — `01`–`06` are a
  point-in-time record. This plan's D4 is where the reversal is written down.

**Verify.** Build both schemes + all four gates (`check_learned` now compiles one more file).
Then, with the widget on the desktop:

1. Pick each of the six appearances. The widget repaints to match, immediately.
2. **Mac in Light, app in Umber** — the §3 failure mode. Warm ground, parchment ink, legible.
3. **Mac in Dark, app in Paper** — cream widget, dark ink.
4. `.system` on a light Mac, then a dark one: identical to what shipped before this step.
5. All three families: small, medium, large. The Hindi rule and the example hairline take
   the palette's colours.
6. Refresh button still works and still hits (`Theme`'s `allowsHitTesting(false)` is on
   `PaneGround`, which the widget does not use — but confirm).
7. **Upgrade path:** set `appearance` to `umber` in standard defaults only, delete the group
   key, relaunch → still Umber, and the group key now exists.
8. Junk string in the group key → System, app and widget both.

### Step 3 — High Contrast

**3a · the two palettes.** `OneWord/Shared/Theme.swift`:

```
                    light half            dark half
background          #FFFFFF               #000000
surface             #F0F0F0               #141414
ink                 #000000               #FFFFFF
muted               #3A3A3A               #D4D4D4
definition          #000000               #FFFFFF
example             #1A1A1A               #F2F2F2
accent              #000000               #FFFFFF
rule                #555555               #AAAAAA
hairline            #000000 @ 40%         #FFFFFF @ 40%
roundness, glow, tiles — defaults
```

Contrast, ground / surface:

| Token | light | dark |
|---|---|---|
| `ink` · `definition` · `accent` | **21.00** / 18.43 | **21.00** / 18.42 |
| `example` | 17.40 / 15.27 | 18.76 / 16.46 |
| `muted` | 11.37 / 9.98 | 14.17 / 12.43 |
| `rule` | 7.46 / 6.54 | 9.04 / 7.93 |

Every text pair clears **AAA** (7:1). The point of the theme is the two non-text pairs:

- `hairline` goes to **2.85 / 3.66**, against **1.28 / 1.23** in Light and Dark. Today a
  hairline is ~1.2:1 everywhere — invisible to anyone with reduced contrast sensitivity, so
  the section structure of a word entry simply is not there for them. This is the fix.
- the empty-state glyph (`accent.opacity(0.5)`) reaches **3.95 / 5.32**, clearing 3:1.

**3b · the case (D8).** `Appearance.swift`: `case highContrast`; `name → "High Contrast"`;
`colorScheme → nil` (join `.system` at `:34`); and it resolves in `Theme.of`:

```swift
case .highContrast: return scheme == .dark ? .highContrastDark : .highContrastLight
```

This is the first appearance that uses the `scheme` parameter for anything but `.system` —
worth a comment saying so.

**3c · auto-selection under `.system` (D9, D10, D11).** `colorSchemeContrast` is a `View`
environment value and `OneWordApp` is a `Scene`, so one wrapper reads it and folds it into
the value every pane already reads:

| File | Change |
|---|---|
| `OneWord/Models/DoodleTheme.swift` | `var increasedContrast = false`. Stays `Equatable` by synthesis (`DoodleSample`'s `.animation(value: doodle)` depends on that). `current` (`:94`) leaves it `false` — the capture HUD paints `.regularMaterial` and reads only `face()`. |
| `OneWord/Models/DoodleTheme.swift:170` | `case .system: return look.increasedContrast ? (scheme == .dark ? .highContrastDark : .highContrastLight) : .of(scheme)`. **Only `.system`** — every other case ignores the flag, which is D9 in one line. |
| `OneWord/Models/DoodleTheme.swift` | `var paintsPalette: Bool { appearance.paintsPalette \|\| (appearance == .system && increasedContrast) }` (D11). |
| `OneWord/Models/Appearance.swift:44` | `paintsPalette` stays — it is still the right answer for a bare appearance, and the tile previews use it. Add a doc line pointing at `DoodleTheme.paintsPalette` as the one the shell asks. |
| `OneWord/Views/RootView.swift:118,161,162` | `doodle.appearance.paintsPalette` → `doodle.paintsPalette`. Three sites, no other reader. |
| `OneWord/OneWordApp.swift:32-38` | Wrap `RootView()` in a small `ContrastAware` view that reads `@Environment(\.colorSchemeContrast)` and re-injects `\.doodle` with the flag set. It must sit **outside** `RootView`, because `RootView` reads `\.doodle` in its own body at `:90`, `:102`, `:107`. |

**3d · the tile.** `SettingsView.swift:396` — `case .highContrast:` draws both halves the way
`.system` does: `HStack(spacing: 0) { page(.highContrastLight, as: .highContrast); page(.highContrastDark, as: .highContrast) }`.
That is also the honest picture: it is the one appearance that is two palettes.

**Verify.** Build + gates. Then:

1. Pick High Contrast. Flip the Mac between Light and Dark → the app follows, both legible.
2. **Hairlines are visible.** Open a word detail: the section rules actually read.
3. System Settings → Accessibility → Display → **Increase Contrast, on.** App on `.system`:
   it switches. App on Paper, Midnight, Umber, Light or Dark: **it does not** (D9).
4. Turn it off → back to plain Light/Dark under `.system`, live, without a relaunch.
5. The tile name: **"High Contrast" is the longest name in the picker** and the grid is
   `.adaptive(minimum: 92)` with 7pt padding each side — ~78pt for a 12pt label. See §7.
6. Relaunch on High Contrast → it sticks, and the widget (after Step 2) paints it too.

### Step 4 — standing docs

- `Docs/00_Context/DESIGN_BRIEF.md` — §3 still says *"a light **+** dark theme"* and §8
  repeats it. Record the seven appearances and what each is for; §6D's widget section needs
  the palette note after Step 2.
- `Docs/00_Context/ARCHITECTURE.md` — the "adding a theme" note gains two lines: it is now
  also a `Theme.of(_:_: Appearance)` arm, and it reaches the widget for free.

---

## 6. Isolation, state, memory

Nothing async, nothing escaping: no `Task`, no closure capture, no retain-cycle surface.

- `Appearance` and `DoodleTheme` are `nonisolated`; `Theme` is MainActor by the project
  default. Step 2b puts `Theme.of(_:_: Appearance)` on `Theme` — MainActor, called from
  `body`, fine. `AppGroup.appearance` is a `nonisolated` static returning a `nonisolated`
  value, so the widget's timeline provider can read it off the main actor, which is the
  reason `AppGroup` is marked `nonisolated` in the first place (`AppGroup.swift:11-14`).
- `AppGroup.migrateAppearance()` writes once, at `init()`, on the main thread.
- State ownership is unchanged. `@AppStorage("appearance")` is read in `OneWordApp` and
  `SettingsView`, resolved once into `\.doodle`, and every pane reads it from there.
  Step 3 adds one flag to that same value rather than a second channel.
- `DoodleTheme` stays `Equatable` by synthesis — `Bool` and a `String` enum.

---

## 7. Risks & exits

| Risk | Sev · Conf | Leading indicator | Exit |
|---|---|---|---|
| **pbxproj hand-edit corrupts the project** (2a) | High · Low | Xcode won't open it, or the widget won't link | Do it in Xcode's UI, and commit 2a alone so `git checkout` reverts one file. |
| **The migration runs too late** and Midnight/Umber users land on System (D7) | High · Med `[Unverified]` | Verify 7 in Step 2 | If `init()` proves too late, read the raw value through a computed property that migrates on first access instead of relying on `@AppStorage`'s default. |
| Paper's empty-state glyph at **2.37:1** reads as faint | Med · Med — measured, not seen | Verify 1 in Step 1 | Three call sites share `accent.opacity(0.5)`. Raising it to **0.7** puts Paper at 3.65 and lifts Umber from 2.94 to 3.92, costing Light and Dark nothing they'd notice. That is a view change at 3 sites, so it is out of "values only" — do it as its own commit if the eye agrees. |
| **"High Contrast" truncates** in a 92pt tile | Low · Med `[Unverified — not rendered]` | Verify 5 in Step 3 | `.minimumScaleFactor(0.85)` on the label, or raise `.adaptive(minimum:)` to 104, or name it **"Contrast"**. Prefer the last — it is a name, not a spec, and 7 tiles at 104pt no longer fit the 520pt column in one row. |
| Widget ink change is noticed as a regression (2d) | Low · Med — intentional | First look at a medium widget | Revert the four `.secondary` rows only; the ground can stay. |
| App Group not provisioned → `defaults` silently falls back to `.standard` (`AppGroup.swift:35`) | Low · High — **pre-existing**, same for `dictionaryID` | Widget doesn't follow the app | Build once in Xcode to provision. Unchanged by this plan. |
| Paper's cream widget looks dingy on a bright wallpaper | Low · Med — taste | Verify 3 in Step 2 | `background` is one hex. Lighten toward `#FAF7F1`; the contrast table has ~1.5 points of headroom on every pair. |
| Nine painted dictionary covers were sampled against white and near-black, never cream | Low · Med | Verify 3 in Step 1 | Covers are image assets — out of scope. If one clashes, it is its own change. |
| Sidebar selection: white label on a light accent fill | Low · High — **pre-existing** (1.7:1 Midnight, 2.3:1 Umber) | Selected row hard to read | Out of scope, as it was last round. A `tint` separate from `accent` is its own change. |

---

## 8. Forks — the operator's

**F1 — the light theme. Default applied: Paper.** Values only, so it is cheap to change
before it ships and permanent after (the raw value lands in people's defaults).
- **Sepia** — the same theme warmer and darker (`#F0E6D2`). Wins if `#F7F3EA` reads as
  "white that needs calibrating" rather than as stock. Risk: at that depth it stops being a
  *light* theme and starts being a third thing.
- **Manuscript** — the brainstorm's B-1: off-white, black ink, **vermilion on the Hindi
  line**. Wins if you want the light theme to also be the theme that says what this app is.
  Risk: it breaks the rule `Wordbook.swift:8` records (covers are the only coloured surface),
  and it is the one candidate that would pull in a Devanagari face.

**F2 — does High Contrast ship at all, or just its hairlines?** Step 3 is the biggest of the
three and the least likely to be picked by anyone in Settings. The cheap alternative is to
**raise every theme's `hairline`** from ~11% to ~20% and stop — one number per palette, no
new case, and it fixes the defect for everyone rather than for whoever finds the switch.
Recommended only if Step 3 slips; it is a smaller win, not a smaller version of the same one.

**F3 — auto-contrast under `.system` (D9).** Recommended, and it is what §3c costs most of
its lines for. Dropping it leaves High Contrast as a plain sixth palette and removes D10,
D11, the `ContrastAware` wrapper and the `RootView` edits. The accessibility argument goes
with it.

---

## 9. Sequence & verification

1. **Step 1 — Paper.** Independent. First reversible move: four values-only edits.
2. **Step 2 — the widget.** Independent of Step 1 in code; do it **after**, so Paper is
   available to test the light-ground case with.
3. **Step 3 — High Contrast.** Needs nothing from 1 or 2, but reads better after Step 2 —
   otherwise the most accessibility-motivated theme is the one the widget ignores.
4. **Step 4 — docs.** After whichever steps land.

Any step ships alone. Commit 2a (the pbxproj move) separately from 2b–2e.

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture; do bash tools/$s.sh; done
```

Both green after every step, then the by-eye list for that step. **No unit test to add**: a
palette has no branch to break. The three pieces of real logic — `.light` resolving directly
(D5), the migration guard (D7), and contrast applying only under `.system` (D9) — are each
one line and each have a by-eye check above that fails loudly if they are wrong.

---

## 10. After this

The slate is then six painted looks plus System, which the brainstorm argues is the picker's
ceiling. **Graphite**, **Moss** and **Manuscript** stay values-only candidates; **Sundial**
(appearance follows the time of day) is the first one that would need a mechanism, and the
rule holds: don't build it until a theme on the list needs it.

One rule this round adds to the last round's two:

> **A theme is not shipped until the widget has it.** Step 2 is the last time that is a
> migration; after it, a new theme reaches both targets by being a `case`.

---

## 11. Assumptions

- `[Sketch → measured]` Paper's palette started as a brainstorm sketch; every number in §4
  is computed, and D2/D3 are corrections that came out of computing them.
- `[Unverified]` The three rows in §7 marked so — the migration's timing, the tile's
  truncation, and everything that needs a build and a look.
- `[Inference]` §3's second failure mode (dark ground, black system ink) follows from the
  code and has not been observed. The fix is correct either way.
- `[Inference]` Moving `Appearance.swift` within the app target's synchronized group keeps
  its app membership automatically, as `CLAUDE.md` states for everywhere outside `Shared/`.
  Verify by building the app scheme after 2a and before touching the widget.
- `[Assumption]` Contrast is computed on flat sRGB composites. Nothing in these two themes
  is translucent over a gradient, so there is no Midnight-style "on the band" column to add.
