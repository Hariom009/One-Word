# One Word — Project Context

## What it is
A macOS app whose main job is a **desktop widget that shows a new word every day**.
Open the app to browse today's word (and past words); the widget on the desktop /
Notification Center surfaces the word-of-the-day at a glance and refreshes once a day.

## Goal
Learn a word a day with zero effort — no app to open, no notification to tap. The word
just sits on the Mac's display and rotates daily.

## Platform & stack
| | |
|---|---|
| Platform | macOS (widget target via WidgetKit) |
| UI | SwiftUI |
| Architecture | MVVM (see [ARCHITECTURE.md](ARCHITECTURE.md)) |
| Language | Swift 5.0 |
| Bundle id | `com.hariom.swift.MacBee` — deliberately kept at the old name; changing it means re-registering the App Group |
| Min version | TBD — set a real `MACOSX_DEPLOYMENT_TARGET` |

## Current state (2026-07-25)
- App retargeted to **macOS** (`SDKROOT = macosx`, `MACOSX_DEPLOYMENT_TARGET = 14.0`).
- Shared model layer done: `Word` (adds `hindi`), `WordProvider`, `words.json` (`OneWord/Shared/`).
- **`words.json` is a generated ~12k-word set** (WordNet + offline Argos Hindi), not hand-written —
  see [tools/gen_words](../../tools/gen_words/README.md) to regenerate/expand. `Word.hindi` is the
  Hindi rendering of the *definition* (context makes offline NMT reliable).
- App UI done: `OneWordApp` → `WordView` → `WordViewModel` (today's word + Hindi, MVVM).
- Browse/search: `WordListView` lists a whole dictionary alphabetically with a toolbar search
  field; a search button on the today screen opens it. `Wordbook` (`OneWord/Models/Wordbook.swift`) is
  the dictionary registry — four so far: **Everyday English** (`words.json`, 12k),
  **Emotions** (`emotions.json`, ~990), **Philosophy** (`philosophy.json`, ~140) and
  **Medical** (`medical.json`, ~1.7k) — the themed ones are dominant-sense filtered (no
  generic words), all from open WordNet (not the copyrighted books/MedlinePlus). Each
  dictionary has its own word of the day; a toolbar picker switches them.
- **Widget Extension target `OneWordWidget` now exists and is live.** Builds green, the
  `.appex` embeds in the app, and the system registers it (`pluginkit -m | grep OneWord`).
  Drop it on the desktop via right-click desktop ▸ Edit Widgets ▸ "Word of the Day".

### Widget: how it's wired
- Target `OneWordWidget` (app-extension, bundle id `…MacBee.MacBeeWidget`) added via the
  `xcodeproj` Ruby gem, not the Xcode wizard. Its 4 files + the 3 `Shared/` files are its
  members; the `.appex` is embedded via an "Embed Foundation Extensions" copy phase.
- `OneWordWidget/Info.plist` carries the `NSExtension → com.apple.widgetkit-extension` dict
  (the one thing `GENERATE_INFOPLIST_FILE` can't express).
- **App Sandbox is required** — a macOS widget won't register without it. Both targets have
  `com.apple.security.app-sandbox` (see `*/…​.entitlements`). This was the non-obvious gotcha.

## Roadmap (rough)
1. Retarget to macOS.
2. Add a bundled word list (`words.json`) + a "word for date D" selector.
3. Build the main app view (today's word + detail) with MVVM.
4. Add a **Widget Extension** target (WidgetKit) with a daily-refreshing timeline.
5. Share the word-of-the-day between app and widget via an **App Group**.

## Key decisions
- **Word source: bundled list, not an API.** A dated pick from a local `words.json` is
  offline, free, and deterministic. ~12k words ≈ 30+ years of daily words, so no network
  source is needed. Translation is done once at generation time (offline, no key), never
  at runtime — a widget calling an API on its daily timeline would be fragile.
- **Daily selection is date-derived, not stored.** `word(for: today)` maps a date to an
  index (e.g. day-of-epoch % count) so app and widget always agree without syncing state.

## Not doing (yet)
Accounts, sync, notifications, an editable word list, iOS/iPadOS support. Add when asked.
