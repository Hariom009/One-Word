# Resolved plan: wire the "Dictionary of Cats & Dogs" (`pets`) shelf

## 1. Header

- **Audit resolved:** "Dictionary of Cats & Dogs (`pets`) wiring plan". The verdict was *Fix blockers first*, not *Needs rework*, so the approach stands.
- **Stack, re-grounded:** macOS SwiftUI app plus a WidgetKit widget, with MVVM and shell gates in `tools/`.
- **Files I opened in this pass:**
  - `/Users/hariom/Desktop/One Word/OneWord/Models/Wordbook.swift`, lines 1-65.
  - `/Users/hariom/Desktop/One Word/OneWordWidget/WordWidget.swift`, lines 15-40.
  - `/Users/hariom/Desktop/One Word/OneWord/Assets.xcassets/Dictionary_of_Idioms.imageset/Contents.json`.
  - Directory listings of `OneWord/Shared` and `Assets.xcassets`.
- **Carried over from the audit, not re-opened:** the pbxproj lines, the `Premium.swift` lines and the tools lines.
- **Re-grounded facts:**
  - `pets.json` and the `Dictionary_of_CatsAndDogs` imageset do not exist yet (confirmed by listing).
  - The Idioms `Contents.json` hard-codes `"filename": "Dictionary_of_Idioms.png"` on the 1x slot (B2 is real).
  - `grep -rn "\.mark\b"` over `OneWord` and `OneWordWidget` returned no hits, so `Wordbook.mark` appears unused in the UI `[Inference]`.

## 2. Resolution summary

| Type | Count |
|---|---|
| Self-resolved | B1, B2, M1, M2 (verification step added), M3, M4 (partly), the minors, and the coverage gaps |
| Operator decision, recommended default applied | 3 (F1, F2, F3) |
| Not a defect | 0 |
| Deferred | 1 (the final `cover` hex, which depends on the art) |

Both blockers are cleared in the plan. Three operator decisions and the cover-hex sampling await review.

## 3. Resolution log

- **B1 (blocking) · Self-resolved.**
  - Change: Step 0 now gates everything. `pets.json` must exist and pass the Python check before any pbxproj, `Wordbook` or tool edit. All wiring lands in one commit with the JSON.
  - Grounding: the `Shared/` listing has no `pets.json`. `Wordbook.swift:43` makes `entryCount` call `WordProvider(resource: id)`, which would fail without the file.
- **B2 (blocking) · Self-resolved.**
  - Change: the imageset step now says to rewrite the 1x `filename` to `Dictionary_of_CatsAndDogs.png` after copying.
  - Grounding: the Idioms `Contents.json` hard-codes its own PNG name.
- **M1 (major) · Self-resolved.**
  - Change: `Dictionary_of_CatsAndDogs` is now the single authoritative asset name. The art producer must use it, and the brief's `Dictionary_of_PetsDogsCats` is superseded.
- **M2 (major) · Self-resolved, with `[Unverified]` carried.**
  - Change: a verification step now checks `pawprint.fill` against the SDK, plus a visual check. If it is missing, fall back to `pawprint`, then to `teddybear.fill`.
  - I could not confirm the symbol from here.
- **M3 (major) · Operator decision, F3.** Recommended default applied.
  - Decision: use the text mark `"Mw"` instead of the emoji or a Cyrillic letter.
  - Why: every existing mark is typographic, and the emoji would render in colour.
  - Alternative: `"\u{1F43E}"`.
  - Flip condition: only if a live render shows the mark is drawn somewhere and the emoji looks right. Since `.mark` appears unused, the stakes are low.
- **M4 (major) · Partly self-resolved.**
  - Change: the placeholder hex is now darker, `0x4A3426`, so it stays in the dark band like the other covers. The real `cover` must be sampled from the finished art.
  - Luma: 0.299·74 + 0.587·52 + 0.114·38 ≈ 57, below 150, so the lettering is light.
  - The final hex is deferred until the art exists.
- **Minor: `RelatedWordsCheck` line 61 · Self-resolved.** Leave `pets` out of the all-or-nothing loop. The audit read that loop and found it requires `served == words.count`, which sound and gesture entries may not meet.
- **Minor: `Wordbook.swift:52` comment · Self-resolved.** Update "five" to "six".
- **Gap: case-insensitive term collisions · Self-resolved.** Added a lower-cased uniqueness check to Step 0.
- **Gap: the rest of `WordProviderCheck` · Self-resolved.** The gate is run in full, and a failure is reported rather than assumed.
- **Gap: stored `dictionaryID == "pets"` · Self-resolved.** `named()` falls back to `everydayEnglish` (`Wordbook.swift:56-58`), so removing the book later is safe.
- **F1, cover art · Operator decision.** Recommended default applied.
  - Decision: real art is required before release. During development, the plan may use the placeholder `image: "Dictionary_of_Idioms"` (the trick `saved` uses at `Wordbook.swift:32`). It must be replaced before shipping.
  - Alternative: ship the placeholder. It shows the wrong title, so I don't recommend it.
  - Flip condition: the operator accepts a wrong-titled cover for an interim build.
- **F2, widget case · Operator decision.** Recommended default applied.
  - Decision: add `case pets` and `.pets: "Cats & Dogs"`, matching `shortName` (the audit's fix for the mismatch).
  - Alternative: skip it. Follow App Settings still works, but the book can't be pinned in the widget's Edit menu.
  - Flip condition: the operator doesn't want the widget picker to grow.

## 4. The resolved plan

**Stack:** macOS SwiftUI app plus a WidgetKit widget, MVVM, no dependencies. Gates are shell scripts in `tools/` that compile Swift files by explicit path.

**Scope:**
- Add one shelf, id `pets`, named "Dictionary of Cats & Dogs".
- Content is text only. Entries are sound types and signals, not literal translation.
- Out of scope: audio, the `RelatedWordsCheck` small-book loop, and any Premium change.

**Architecture fit:** `pets` is a bundled JSON plus a `Wordbook` static plus an entry in `Wordbook.all`. It mirrors `german` and `idioms`. Because `Premium` and the widget are shared with the app, their ids are plain strings.

**Step 0: gate (blocking).**
- Land `/Users/hariom/Desktop/One Word/OneWord/Shared/pets.json` first.
- It must be a JSON array of `{term, partOfSpeech, hindi, definition, example}`, with every value a non-empty string.
- Terms must be unique, including when lower-cased.
- Run from `/Users/hariom/Desktop/One Word`:
  ```
  python3 -I -c "import json; d=json.load(open('OneWord/Shared/pets.json')); K={'term','partOfSpeech','hindi','definition','example'}; assert all(set(e)==K and all(isinstance(e[k],str) and e[k].strip() for k in K) for e in d), 'shape/empty'; assert len({e['term'].lower() for e in d})==len(d), 'dup terms'; print(len(d),'entries ok')"
  ```
- Do not start Steps 1-5 until this passes. All steps below land in the same commit as the JSON.
- Definitions need plenty of tokens longer than 3 characters, because `check_related` needs at least 99% vectorisation coverage.

**Step 1: `OneWord/Models/Wordbook.swift` (app target).**
- After `german` (line 30), add:
  `static let pets = Wordbook(id: "pets", name: "Dictionary of Cats & Dogs", cover: 0x4A3426, symbol: "pawprint.fill", mark: "Mw", image: "Dictionary_of_CatsAndDogs", height: 0.91)`
- Change line 53 to `[everydayEnglish, emotions, philosophy, startup, idioms, pets, saved]`.
- Change the line 52 comment to say six shelves.
- Replace `0x4A3426` with the hex sampled from the finished art. It must stay dark.

**Step 2: `OneWord/Shared/Premium.swift:24`.** Append `"pets"` to `free`.

**Step 3: `OneWord.xcodeproj/project.pbxproj` (4 lines).**
- Generate two fresh unique 24-hex IDs, F (file ref) and B (build file), and `grep -c` each against the file to confirm they are unused.
- Mirror the german.json lines:
  - (a) after line 17, in PBXBuildFile: `B /* pets.json in Resources */ = {isa = PBXBuildFile; fileRef = F /* pets.json */; };`
  - (b) after line 63, in PBXFileReference: `F /* pets.json */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = text.json; name = pets.json; path = OneWord/Shared/pets.json; sourceTree = "<group>"; };`
  - (c) after line 154, in the `SharedRefs` group `660DA6AB7808D2D0208B1301`: `F /* pets.json */,`
  - (d) after line 298, in the widget Resources phase `B456E8B2F38A6579AA1B5E8C`: `B /* pets.json in Resources */,`
- Do not touch the app Resources phase `BFCC5B543011545500C0FE1F`, the synchronized group, or its exception set.
- Edit by hand or with a careful `sed`. Opening and saving in Xcode may rewrite the file.
- Before editing, confirm that `B456E8B2…` appears in the widget target's `buildPhases` list. The audit did not read the `PBXNativeTarget` block.
- `grep -c 'pets.json' OneWord.xcodeproj/project.pbxproj` must print 4.

**Step 4: tools.**
- `tools/WordProviderCheck.swift:11`: append `"pets"` to `books`.
- `tools/RelatedWordsCheck.swift:21-22`: append `"pets"` to `books`. Do not add it to the line 61 loop.
- `tools/check_premium.sh:52`: append `"pets"` to `shipped`. Keep it out of `premium`, and never use the id `medical`.

**Step 5: `OneWordWidget/WordWidget.swift`.**
- Line 19: `case followApp, words, emotions, philosophy, startup, idioms, pets`.
- Add `.pets: "Cats & Dogs",` to `caseDisplayRepresentations`.
- The raw value `pets` is the JSON resource name.

**Step 6: cover asset (required before release).**
- Create `OneWord/Assets.xcassets/Dictionary_of_CatsAndDogs.imageset/`. This is the one authoritative asset name.
- Copy `Contents.json` from `Dictionary_of_Idioms.imageset`, then change the 1x `filename` to `Dictionary_of_CatsAndDogs.png`.
- Add the PNG with these properties:
  - Title printed on the cover.
  - Cut tight, with no transparent margin.
  - Aspect w/h of at most 0.69.
  - Board foot about 0.936 down the art.
  - Roughly 570x828.
- Without this asset the shelf image renders blank.

**Concurrency and state:** nothing new. `Premium` is nonisolated and `Wordbook` is a value type. `entryCount` goes through the cached `WordProvider`. The widget decodes `pets.json` from its own bundle, so Step 3 is critical.

**Data:** the only new data is `pets.json`. A stored `dictionaryID` that no longer matches falls back to everyday English through `Wordbook.named`.

**Test plan** (run from `/Users/hariom/Desktop/One Word`):
1. The Step 0 Python check.
2. `grep -c 'pets.json' OneWord.xcodeproj/project.pbxproj`, which should print 4.
3. `for s in check_words check_related check_learned check_capture check_premium; do bash tools/$s.sh; done`.
   - If `check_related` reports low coverage, lengthen the definitions. Do not weaken the gate.
4. `xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build`.
5. The same command with `-scheme OneWordWidget`.
6. The bundle check, where both files must exist:
   ```
   D=$(xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' -showBuildSettings 2>/dev/null | awk '/ BUILT_PRODUCTS_DIR /{print $3; exit}')
   ls "$D/One Word.app/Contents/Resources/pets.json" "$D/One Word.app/Contents/PlugIns/OneWordWidget.appex/Contents/Resources/pets.json"
   ```
7. Confirm `pawprint.fill` exists, either with a one-line `NSImage(systemSymbolName:accessibilityDescription:)` check or visually. A missing symbol shows a blank chip quietly rather than failing the build.
8. Manual check:
   - The shelf shows the book with the right cover and it is tappable, not locked.
   - A pinned or followed widget shows a pets word.
   - Do not use `open -n` or kill the Xcode debug run.

**Accessibility and localization:**
- VoiceOver should read `Wordbook.name` from the existing shelf code `[Inference]`.
- No `.xcstrings` changes appear necessary `[Inference]`.
- The content keeps honest framing: sound types and signals, not translation.

**Risks and exits:**

| Risk | Severity | Exit |
|---|---|---|
| Widget pbxproj entries missed | High: widget `fatalError` at runtime | Re-check the four lines, then the `.appex` `ls` |
| JSON missing when pbxproj lands | High: build fails | Step 0 gate |
| Blank cover (wrong filename or asset name) | Medium | Fix the `Contents.json` filename and the asset name |
| Not in `Premium.free` | Medium | `check_premium` catches it once `shipped` is updated |
| Short definitions fail the coverage floor | Low to medium | Lengthen the definitions |
| `pawprint.fill` missing | Low | Fall back to `pawprint`, then `teddybear.fill` |

**Sequencing:** Step 0, then Steps 1-5 together in one commit with the JSON, then Step 6 (art required before release), then the full test plan.

**Open questions:** F1, F2 and F3 are in the review queue below.

## 5. Operator review queue

- **F1, cover art.**
  - Default: real art is required before release. The Idioms placeholder is allowed in development only.
  - Alternative: ship the placeholder.
  - Flip condition: you accept a wrong-titled cover in an interim build.
- **F2, widget case.**
  - Default: add `case pets` with the label "Cats & Dogs".
  - Alternative: skip it.
  - Flip condition: you don't want the widget Edit-menu picker to grow.
- **F3, mark glyph.**
  - Default: the text mark `"Mw"`.
  - Alternative: the emoji `"\u{1F43E}"`.
  - Flip condition: a live render shows the mark is drawn and the emoji looks right.

## 6. Remaining and deferred

- **Final `cover` hex:** deferred until the art exists. Sample it from the finished art, and keep it dark.
- **`[Unverified]` `pawprint.fill` on macOS 14:** resolved by Test plan step 7.
- **`[Unverified]` widget target membership of `B456E8B2…`:** resolved by reading the `PBXNativeTarget` block before the pbxproj edit.
- **`[Unverified]` `check_related` coverage and the `WordProviderCheck` per-book assertions:** these can only be confirmed by running the gates once `pets.json` exists.
