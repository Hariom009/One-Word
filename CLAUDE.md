# One Word

macOS word-of-the-day app + WidgetKit widget. SwiftUI, MVVM, no dependencies, no network —
every word ships as bundled JSON.

## Orientation

Read these before making changes. They are kept current; trust them.

- **[Docs/00_Context/REPO_MAP.md](Docs/00_Context/REPO_MAP.md)** — every folder and what belongs in it. Start here.
- **[Docs/00_Context/ARCHITECTURE.md](Docs/00_Context/ARCHITECTURE.md)** — MVVM layers, data flow, where a new file goes.
- **[Docs/00_Context/PROJECT_CONTEXT.md](Docs/00_Context/PROJECT_CONTEXT.md)** — what the app is and why.
- **[Docs/00_Context/DESIGN_BRIEF.md](Docs/00_Context/DESIGN_BRIEF.md)** — the visual language. Read before touching UI.

## Where code goes

| It… | Folder |
|---|---|
| is a SwiftUI `View` | `OneWord/Views/` |
| is `@Observable` and drives a view | `OneWord/ViewModels/` |
| is app-only data or state | `OneWord/Models/` |
| must be readable by the **widget** too | `OneWord/Shared/` |

Views never load data or touch persistence. View models never import SwiftUI or name a view
type — that's the testable seam. `OneWord/Shared/` is compiled into **both** targets and is
referenced by explicit path in `project.pbxproj`: moving a file there breaks the widget build.
Everywhere else, files on disk join the target automatically (Xcode 16 synchronized groups).

## Where docs go

`Docs/` folders are artifact types in workflow order. `Audit/` and `Resolved/` sit beneath
the artifact they challenge:

```
00_Context/   01_Brainstorm/   02_Plan/{,Audit,Resolved}/
03_Checklist/{,Audit,Resolved}/   04_PR/{,Review,Fixed}/   05_Thoughts/   06_Misc/
```

**[Docs/README.md](Docs/README.md) has the routing table** — match what you produced to a
row and it names the exact path, including which skill lands where. Name files
`<FEATURE>_<KIND>.md` in screaming snake case; that `<FEATURE>` prefix is the only thing
tying a dossier together once the folders split it up.

Docs in `01`–`06` are a point-in-time record. Don't refresh stale file paths inside them, and
never overwrite an audit or the plan it challenged — only `00_Context/` is kept current.

## Verify before saying it's done

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture; do bash tools/$s.sh; done
```

Both must be green. The gates compile Swift files by explicit path, so if you move a file,
update the script that names it. Report failures with the output — never smooth over a red gate.
