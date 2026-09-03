# Repo map

Every folder in One Word and what belongs in it. High level — for depth on the app's
layering see [ARCHITECTURE.md](ARCHITECTURE.md); for what the app *is*, see
[PROJECT_CONTEXT.md](PROJECT_CONTEXT.md).

```
One Word/
├── OneWord/              macOS app target
├── OneWordWidget/        WidgetKit extension target
├── OneWord.xcodeproj/    project file — see "Adding files" below
├── tools/                verification gates + word generators (not shipped)
└── Docs/                 all written docs — see Docs/README.md
```

## OneWord/ — the app

| Path | Holds | Rule |
|---|---|---|
| `OneWordApp.swift` | `@main`, window + scene, app-active refresh. | Entry point. Not a layer. |
| `WordCapture.swift` | AppKit glue: `NSServices` "Save to One Word", the capture HUD. | Neither M, V, nor VM — AppKit lives at root. |
| `Views/` | SwiftUI `View`s only. | **No data loading, no persistence, no JSON.** |
| `ViewModels/` | `@Observable` classes driving those views. | `import Observation` only — **never** SwiftUI, never a view type. This is the testable seam. |
| `Models/` | App-only data and state: `Wordbook`, `Appearance`, `LearnedWords`, `RelatedWords`. | No SwiftUI. Not visible to the widget. |
| `Shared/` | `Word`, `WordProvider`, `WordStore`, `SavedWords`, `Theme`, `AppGroup`, and every `<book>.json`. | **Member of BOTH targets.** Anything the widget reads must live here. |
| `Assets.xcassets/` | App icon, accent color. | |

## OneWordWidget/ — the widget

`WordWidget`, `WordTimelineProvider`, `WordWidgetView`, `WordEntry`, `RefreshWordIntent`.

No view models: a widget is timeline-driven, not user-event-driven, so `TimelineProvider`
*is* its driver. It reads `OneWord/Shared/` and nothing else from the app.

## tools/ — gates and generators

| Path | What |
|---|---|
| `check_words.sh` | Every book decodes; date→word mapping is deterministic. |
| `check_related.sh` | Related-words embedding coverage per book (≥99%). |
| `check_learned.sh` | Learned-log recording and per-shelf counting. |
| `check_capture.sh` | Pinned-word precedence over the daily offset. |
| `*Check.swift` | Headless harnesses the `check_*.sh` scripts compile and run. |
| `gen_words/` | Python word-set generation/translation. Has its own README. |

Run all four before calling work done:

```bash
for s in check_words check_related check_learned check_capture; do bash tools/$s.sh; done
```

They compile source **by explicit path** — moving a Swift file means updating the script
that names it.

## Docs/ — written docs

Top-level folders are artifact types in workflow order; `Audit/` and `Resolved/` sit beneath
the artifact they challenge, so a plan and its audits live together.

```
00_Context/   standing truth (this file, ARCHITECTURE, PROJECT_CONTEXT, DESIGN_BRIEF)
01_Brainstorm/
02_Plan/         Audit/  Resolved/
03_Checklist/    Audit/  Resolved/
04_PR/           Review/ Fixed/
05_Thoughts/  06_Misc/
```

[Docs/README.md](../README.md) has the routing table: match what you produced to a row and
it names the exact path. Only `00_Context/` is kept current — the rest is a point-in-time record.

## Adding files

`OneWord/` and `OneWordWidget/` are Xcode 16 **file-system-synchronized groups**: create a
file or folder on disk and it joins the target automatically. No `project.pbxproj` edit, no
target-membership step.

One exception. `OneWord/Shared/` files are *also* referenced by explicit path in
`project.pbxproj` so the widget target can compile them. **Moving or renaming anything in
`Shared/` breaks the widget build** and needs a project-file edit. Everything else moves freely.

## Where things get referenced from outside the code

Move a file, and grep these too — they name paths as strings, so the compiler won't catch it:

- `tools/check_*.sh` — compile source by path.
- `.claude/workflows/*.js` and `.claude/commands/*.md` — tell agents which files to read.
- `Docs/00_Context/*` — kept current.
- `Docs/01_*` through `Docs/06_*` — **do not update.** Point-in-time records; stale paths
  in them are correct.
