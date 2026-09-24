# One Word — Architecture

MVVM + SwiftUI. The main app and the widget share one data layer; each has its own view /
view-model surface. See [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) for what/why.

## Layers

```
        ┌─────────────────────┐        ┌──────────────────────┐
        │      Main App        │        │   Widget Extension   │
        │  (SwiftUI window)    │        │      (WidgetKit)     │
        ├─────────────────────┤        ├──────────────────────┤
  View  │  HomeView            │        │  WordWidgetView      │
        │  WordListView        │        │  (entry -> SwiftUI)  │
        ├─────────────────────┤        ├──────────────────────┤
 VM /   │  WordViewModel       │        │  TimelineProvider    │
 driver │  (@Observable)       │        │  (builds entries)    │
        └──────────┬──────────┘        └──────────┬───────────┘
                   │                               │
                   └───────────────┬───────────────┘
                                   ▼
                    ┌───────────────────────────────┐
              Model │  WordProvider (word(for:Date)) │
                    │  Word (id, term, definition…)  │
                    │  words.json  (bundled)         │
                    └───────────────────────────────┘
```

## Roles

**Model**
- `Word` — a plain `struct` (`Codable`, `Identifiable`): term, definition, part of speech, example.
- `WordProvider` — loads `words.json` once and exposes `word(for date: Date) -> Word`.
  The mapping is pure date math (e.g. days-since-epoch modulo count), so it's deterministic:
  the app and the widget compute the *same* word for a given day with no shared mutable state.

**ViewModel**
- `@Observable`, `Observation` only — no SwiftUI imports, no view types. This is the
  unit-testable seam. `WordViewModel` (today's word + peek), `WordListViewModel`
  (browse/search a book), `ProfileViewModel` (per-shelf progress; owns the expensive
  all-books decode so no view does it).
- The widget does **not** reuse `WordViewModel`. Its "view model" is the WidgetKit
  `TimelineProvider`, which asks `WordProvider` for entries. Same model, different driver —
  because widgets are timeline-driven, not user-event-driven.

**View**
- App: `HomeView` (today), `HistoryView` (a past day), `WordListView` (browse/search) — dumb,
  bind to the view model.
- Widget: `WordWidgetView` renders a single `TimelineEntry`.

## Data flow

App (interactive):
`View` → `WordViewModel.load()` → `WordProvider.word(for:)` → view model publishes → `View` re-renders.

Widget (timeline):
`TimelineProvider.timeline()` → builds one `TimelineEntry` per upcoming day (or one entry +
a refresh policy of `.after(nextMidnight)`) → WidgetKit renders `WordWidgetView` and wakes it
at midnight for the next word.

## Sharing between app & widget
- Code: put `Word`, `WordProvider`, and `words.json` in a **shared target / framework** (or
  add them to both targets' membership) so both compile against one source of truth.
- Runtime state (if any is ever needed — e.g. "favorited" words): an **App Group**
  (`LAP54KU2SV.group.com.hariom.swift.oneword` — the TEAM ID prefix matters, see AppGroup.swift) via `UserDefaults(suiteName:)`. For pure word-of-the-day,
  no shared runtime state is needed because selection is date-derived.

## Refresh
Widget requests reload at the next local midnight (`Calendar.nextDate` → `Timeline(...,
policy: .after(midnight))`). No timers, no background fetch.

## Conventions
- View models never import view types; views never do data loading.
- `WordProvider` is the only thing that touches the bundle / disk — inject it into view
  models and the timeline provider so both can be tested with a stub list.
- Keep `words.json` the single source of word data; don't duplicate copy in code.

## Appearances — adding a theme

An appearance is a `case` of `Appearance` (`Models/`) and, if it brings its own palette, a
`static let` on `Theme` (`Shared/`). Every pane reads colour as `t.<token>` and every corner
as `t.radius(_:)`, so a new theme is values, not view code.

1. Add the `case` to `Appearance`. Its three switches — `name`, `colorScheme`,
   `paintsPalette` — have no `default`, so the file won't compile until each answers.
2. Build. The compiler now names the two remaining sites: `Theme.of(_:_:)` in
   `DoodleTheme.swift` and `AppearanceTile.preview` in `SettingsView.swift`. **Never answer
   either with `default:`** — that failure is the checklist.
3. Add the palette as a `static let` on `Theme`. Leave `roundness`, `glow` and `tiles` out
   unless the theme needs them; the defaults are square corners, no band, hairline sections.
4. Compute contrast for ink, definition, example, muted and accent against both `background`
   and `surface` before shipping. AA is the floor.

Rules that have already cost something:

- **Give it an opaque `surface` unless there is a reason not to.** Anything outside the app's
  own windows — a popover — doesn't inherit the appearance override, and a see-through
  surface lands on whatever the system drew. Midnight's is translucent on purpose (the
  frosted read over its band) and pays for it: `InfoButton` paints `background` underneath.
- **`Theme.swift` names nothing app-only.** It is compiled into the widget (for `Font.serif`)
  and into `tools/check_learned.sh` by path; neither has `Appearance` or `DoodleTheme`. That
  is why palette resolution lives in `DoodleTheme.swift`'s `extension Theme`.
- **`Appearance` and `DoodleTheme` are `nonisolated` and never touch a `Theme`**, which is
  MainActor by the project default. Resolve palettes only in `Theme.of(_:_:)`.
- **A stored raw value is forever.** `appearance` is a string in `UserDefaults`; renaming a
  shipped case silently drops its users to System.
- **The band is in points and has no x in it** (`PaneGround`). `PaneHeader` repaints the
  pane's ground in a 52pt strip, and the sidebar paints it too; a gradient sized to its
  bounds would show a seam at both. A second glowing theme should reuse the band, and only
  then promote its height and stops to `Theme` fields.
- The type is still called `DoodleTheme` though it now carries the appearance. Known
  misnomer; a rename touches every pane for no behaviour.

## Premium — where the lock lives

Everyday English (and Bookmarks) is free; every other dictionary unlocks with one
non-consumable in-app purchase. Plan: `Docs/02_Plan/Resolved/PREMIUM_PLAN_RESOLVED.md`.

- **The rule is `Shared/Premium.swift`**, `nonisolated` so the widget can read it off-main:
  `free`, `allows(_:)`, `resolve(_:)`, and the flag mirrored into the App Group.
- **`Premium.set(unlocked:)` is its only writer**, called only by `PremiumViewModel` (the one
  StoreKit owner, held at the app root). Losing Premium also walks a locked `dictionaryID`
  back to `"words"`, so every raw `@AppStorage("dictionaryID")` reader stays right untouched.
- **Views read `premium.allows(_:)` from the environment, never `Premium.isUnlocked`** — that
  is a `UserDefaults` read Observation can't see; a view reading it misses the purchase.
- **The gates, one per route:** the shelf (`DictionaryShelf.pick`, the pick's only writer —
  a locked book comes forward but isn't picked); the widget (`WidgetDictionary.resource`, its
  only dictionary read); search rows (no Hindi gloss for a locked hit); and `WordDetail`, where
  every full-view route ends (headword + `PremiumBar`, no bookmark, not counted as learned).
- **Never gate `WordProvider`.** It feeds search, the shelf's entry counts and warm-up.
- A new sheet or pane that shows a word or the shelf inherits the environment. An AppKit-hosted
  view (`NSHostingView`, like the capture HUD) does **not** — inject `PremiumViewModel` there.

## Testing seam
`WordProvider.word(for:)` and `WordViewModel` are pure over an injected word list — unit-test
date→word mapping (boundaries: day rollover, list wrap-around) without WidgetKit or SwiftUI.

## Layout

```
OneWord/                        app target
  OneWordApp.swift              @main — window, scene, app-active refresh
  WordCapture.swift             AppKit glue: NSServices "Save to One Word" + HUD
  Views/                        SwiftUI only. No data loading, no persistence.
    RootView, PaneHeader, HomeView, HistoryView, WordDetail, WordListView,
    LearnedListView, ProfileView, SettingsView, DictionaryPicker, MonthCalendar
  ViewModels/                   @Observable. No view types. The unit-testable seam.
    WordViewModel, WordListViewModel, ProfileViewModel, PremiumViewModel
  Models/                       App-only model + state. No SwiftUI.
    Wordbook, Appearance, LearnedWords, RelatedWords
  Shared/                       MEMBER OF BOTH TARGETS — app + widget
    Word, WordProvider, WordSelectionStore, SavedWords, Theme, AppGroup, Premium, *.json
  Assets.xcassets/

OneWordWidget/                  widget target
  WordWidget, WordTimelineProvider, WordWidgetView, WordEntry, RefreshWordIntent

tools/                          check_*.sh gates + generators
Docs/                           see Docs/README.md
```

Two files sit at the app-target root on purpose: `OneWordApp.swift` is the entry point and
`WordCapture.swift` is AppKit/NSServices glue — neither is a model, a view, or a view model.

### Where a new file goes

| It… | Folder |
|---|---|
| is a `View` | `Views/` |
| is `@Observable` and drives a view | `ViewModels/` |
| is data/state the app owns alone | `Models/` |
| must be readable by the **widget** too | `Shared/` |

`Shared/` files are referenced by explicit path in `project.pbxproj` for the widget target —
moving one breaks the widget build. Everything else lives under an Xcode 16
file-system-synchronized group, so new folders and files are picked up with no project edit.

The `tools/check_*.sh` gates also compile sources by explicit path; moving a file means
updating the script that names it.
