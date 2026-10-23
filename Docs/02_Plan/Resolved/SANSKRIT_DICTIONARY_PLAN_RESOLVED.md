# Resolved plan: Dictionary of Sanskrit (wiring only)

## 1. Header

- **Resolved:** the "Dictionary of Sanskrit (wiring only)" plan and its audit. The audit verdict was Ready to build once the content file exists, so no Needs-rework caveat applies.
- **Stack, as re-grounded:**
  - macOS and iOS SwiftUI MVVM with no dependencies.
  - The app target is a synchronized group. The widget target takes explicit pbxproj entries.
- **Opened this run:**
  - `OneWord/Models/Wordbook.swift`, lines 10–66.
  - `OneWord/Shared/Premium.swift`, lines 26–30.
  - `tools/check_premium.sh`, lines 48–56.
  - `OneWordWidget/WordWidget.swift`, lines 15–45.
- **Carried from the audit and not re-opened:** the pbxproj anchors, and the `books` arrays in `tools/WordProviderCheck.swift` and `tools/RelatedWordsCheck.swift`.
- **Not present yet:** `OneWord/Shared/sanskrit.json` (`ls` fails). That is a sequencing dependency on the content workflow.

## 2. Resolution summary

| Outcome | Count | Findings |
|---|---|---|
| Self-resolved | 6 | M1, M2, minors 1, 2, 3 and 7 |
| Operator decision, recommended default applied | 4 | Q1 free or Premium, Q2 placeholder art, Q3 widget picker, Q4 `mark` (minors 4, 5 and 6 fold into these) |
| Not a defect | 0 | |
| Deferred | 2 | Shelf capacity check, `DICTIONARY_3000_PLAN.md` content spec |

There are no blockers. Four operator decisions await review. The build and data gates stay red until `sanskrit.json` lands.

## 3. Resolution log

- **M1 (Major), `.hi` symbol on the macOS 14 / iOS 17 floors. Self-resolved.**
  - The symbol is now plain `character.book.closed.fill`, with `book.closed.fill` as the fallback.
  - Grounding: `Wordbook.swift:18` documents the symbol as one that must exist on macOS 14.
  - The `.hi` variant carries the floor risk and is dropped.
  - [Inference] The plain symbol's introduction version is unconfirmed, though it is likely older than the `.hi` variant.
  - If the chip renders blank on a macOS 14 or iOS 17 simulator, switch to `book.closed.fill`.
- **M2 (Major), 99% embedding coverage. Self-resolved by sequencing.**
  - Step 0 now runs `tools/check_related.sh` on the draft `sanskrit.json` before any other wiring.
  - The content brief is told that 1% of 300 entries is 3 failures.
- **Minor 1, `check_premium.sh`. Self-resolved.**
  - `tools/check_premium.sh:51` hard-codes `shipped`. It does not assert `free == shipped`.
  - Add `"sanskrit"` to `shipped` so the free status is pinned (new step 6).
  - This clears the plan's earlier `[Unverified]` on `check_premium`.
- **Minor 2, widget mapping. Self-resolved.**
  - `WordWidget.swift:41–42` maps through `rawValue`, so `case sanskrit` resolves to `"sanskrit"`.
  - The comment at line 27 says pets is app-only. Sanskrit is not, so that comment stays accurate and is left alone.
- **Minor 3, stale comments. Self-resolved.**
  - `Wordbook.swift:54` is rewritten.
  - `LearnedWords.swift:89` ("all ten") is left alone.
- **Minor 7, pbxproj ordering. Self-resolved.**
  - Insert next to the `pets.json` lines. Order does not matter.
- **Minor 4, placeholder art shows "Idioms". Operator decision, default applied.**
  - Default: ship with `Dictionary_of_Idioms` as the placeholder and a TODO comment. This matches the pets precedent at `Wordbook.swift:33`.
  - Alternative: hold the shelf entry until the painted cover exists.
  - Flip it if you do not want two "Idioms" books visible on the shelf.
- **Q1, free or Premium. Operator decision, default applied.** See the review queue.
- **Q3, widget picker. Operator decision, default applied.** See the review queue.
- **Q4 and minors 5 and 6, `mark` and cover. Operator decision, default applied.** See the review queue.
- **Fork 9.2 (cover colour). Operator decision, default applied.**
  - Keep `0x8C2F1E`.
  - [Unverified] Its L* of about 33–35 is an estimate. The luma is about 73, so lettering is white.
  - Flip it if it reads too close to Emotions or Pets on the shelf.
- **Deferred:** the shelf capacity check and the `DICTIONARY_3000_PLAN.md` spec check. See section 12.

## 4. The resolved plan

### Scope

Register `Wordbook.sanskrit` and ship `sanskrit.json` in both targets. Update the check scripts. The word content comes from the content workflow and is not written here. Single change, one PR.

### Architecture fit

No new types. The new static copies the sibling statics at `Wordbook.swift:20–31`.

### Steps

**0. Gate the draft content first.**
- Once the content workflow produces `OneWord/Shared/sanskrit.json`, run steps 1, 5 and 7 in the order below.
- Run `tools/check_related.sh` before the rest of the wiring.
- Content requirements:
  - Entries have exactly `term`, `partOfSpeech`, `hindi`, `definition`, `example`, all non-empty strings.
  - Terms are unique.
  - Terms are in Roman transliteration. Devanagari goes in `hindi` and `mark` only, never in `term`.
  - Definitions are in English.
  - No `sound` key.
  - At most 1% of entries may fail to embed.

**1. `OneWord/Shared/sanskrit.json` (NEW).** The content from step 0.

**2. `OneWord.xcodeproj/project.pbxproj` (four edits, two fresh 24-hex UUIDs).**
- Pick UUIDs that `grep -c` shows are not already in the file.
- Do not touch the app's Resources phase `BFCC5B54…`.
- Edits (copy the `pets.json` entries as the template):
  1. PBXBuildFile section: `<BF> /* sanskrit.json in Resources */ = {isa = PBXBuildFile; fileRef = <FR> /* sanskrit.json */; };`
  2. PBXFileReference section: `<FR> /* sanskrit.json */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = text.json; name = sanskrit.json; path = OneWord/Shared/sanskrit.json; sourceTree = "<group>"; };`
  3. SharedRefs group `660DA6AB…`: add `<FR> /* sanskrit.json */,` after the `pets.json` line.
  4. Widget Resources phase `B456E8B2…`: add `<BF> /* sanskrit.json in Resources */,` after the `pets.json` line.
- Verify with `grep -c 'sanskrit.json' OneWord.xcodeproj/project.pbxproj`. Expect 4.

**3. `OneWord/Models/Wordbook.swift`.**
- Add after `pets`:
  ```swift
  // TODO(develop): Idioms art is a dev placeholder; swap to "Dictionary_of_Sanskrit" and re-sample `cover` once the painted cover lands.
  static let sanskrit = Wordbook(id: "sanskrit", name: "Dictionary of Sanskrit", cover: 0x8C2F1E, symbol: "character.book.closed.fill", mark: "\u{0950}", image: "Dictionary_of_Idioms", height: 0.92)
  ```
- Change `all` to `[everydayEnglish, emotions, philosophy, startup, idioms, pets, sanskrit, saved]`.
- Rewrite the line 54 comment to: `// v1 ships seven shelves; classical, urdu and german stay defined (and bundled) for the next release.`
- `0.92` is distinct from the existing heights: 1, 0.9, 0.96, 0.86, 0.93, 0.98, 0.88, 0.94 and 0.91.

**4. `OneWord/Shared/Premium.swift:28`.**
- Add `"sanskrit"` to `free`. The new set is `["words","emotions","philosophy","startup","idioms","pets","sanskrit", SavedWords.resource]`.
- Without this, the shelf shows Sanskrit locked and the widget swaps it to "words".

**5. `tools/WordProviderCheck.swift:11` and `tools/RelatedWordsCheck.swift:21–22`.**
- Append `"sanskrit"` to each `books` array.
- Leave the small-books full-service list `["german","classical","pets"]` alone. Add Sanskrit there only if the data run shows every entry gets at least one neighbour.

**6. `tools/check_premium.sh:51`.** Append `"sanskrit"` to `shipped`.

**7. `OneWordWidget/WordWidget.swift`.**
- Add `sanskrit` to the `case` line at line 19.
- Add `.sanskrit: "Sanskrit",` to `caseDisplayRepresentations` after `.idioms`.
- `resource` needs no change, because it maps through `rawValue`.

### Concurrency, state and memory

Nothing new. `Wordbook` is a value type, the `WordProvider` cache is unchanged, and an extra `AppEnum` case changes no isolation.

### Data and persistence

Bundled JSON only. The app target joins the file automatically through the synchronized group. The widget target joins it only through the step 2 edits.

### Tests and gates

No new test files. Adding the id to the `books` arrays and to `shipped` exercises the new data.

```bash
cd "/Users/hariom/Desktop/One Word"
python3 -c "import json;d=json.load(open('OneWord/Shared/sanskrit.json'));print(len(d), len({w['term'] for w in d})==len(d), all(set(w)=={'term','partOfSpeech','hindi','definition','example'} and all(isinstance(v,str) and v for v in w.values()) for w in d))"
grep -c 'sanskrit.json' OneWord.xcodeproj/project.pbxproj   # expect 4
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
xcodebuild -project OneWord.xcodeproj -scheme OneWordWidget -destination 'platform=macOS' build
for s in check_words check_related check_learned check_capture check_sentences check_premium check_sync; do bash tools/$s.sh; done
```

- Confirm the widget bundle itself contains the file. Search the `.appex` directly, because a search of all DerivedData would also match the app's copy:
  ```bash
  find ~/Library/Developer/Xcode/DerivedData -path '*OneWordWidget.appex*' -name sanskrit.json
  ```
- Manual checks, without killing the Xcode debug run:
  1. The Sanskrit book is unlocked and selectable on the shelf.
  2. The cover lettering is white.
  3. The Om glyph renders. The cover font may lack Devanagari, so system fallback is expected.
  4. The chip symbol renders, ideally on a macOS 14 or iOS 17 simulator.
  5. Sanskrit appears in the widget Edit menu.

### Accessibility, localization and mechanics

- No new strings.
- No Info.plist, entitlement or Package changes.

### Risks and exits

| Risk | Severity / confidence | Exit |
|---|---|---|
| pbxproj typo or UUID collision | Medium / medium | `git checkout` only `project.pbxproj` and redo. |
| Widget `fatalError` at runtime | Medium / high | Re-check pbxproj edit 4 and inspect the `.appex`. |
| `Premium.free` forgotten | High / high | Edit step 4. |
| Symbol or Om glyph blank | Low / low | Use `book.closed.fill`, or `\u{0938}\u{0902}` (सं). |
| `check_related` below 99% | Medium / medium | The content workflow expands the definitions of the failing entries. |

### Open questions

- [Unverified] The plain `character.book.closed.fill` symbol on the macOS 14 / iOS 17 floors.
- [Unverified] Whether `DictionaryShelf` has room for a seventh book.
- [Assumption] `sanskrit.json` lands before the gates run, with Roman transliteration in `term`.

## 5. Operator review queue

1. **Free or Premium (Q1).**
   - Default: add `"sanskrit"` to `Premium.free` and `shipped`.
   - Why: `Features.premium` is off and every other shelf book is free.
   - Alternative: Sanskrit as a paid-only book.
   - Flip condition: you want it paid-only. Skip steps 4 and 6, and expect the lock on free accounts.
   - Precedent: classical, urdu and german are bundled but outside `all` and `free`.
2. **Placeholder art (Q2).**
   - Default: ship with `Dictionary_of_Idioms` plus a TODO.
   - Alternative: hold the shelf entry until the painted cover exists.
   - Flip condition: you do not want two "Idioms" covers visible.
3. **Widget picker (Q3).**
   - Default: include Sanskrit (step 7).
   - Alternative: app-only, like pets.
   - Flip condition: you want it app-only. Skip the picker additions in step 7 and add a Sanskrit clause beside `id == "pets"` at `WordWidget.swift:42`.
4. **`mark` (Q4).**
   - Default: Om (`\u{0950}`).
   - Alternative: सं.
   - Flip condition: Om renders badly in the cover font.
5. **Cover colour (fork 9.2).**
   - Default: `0x8C2F1E`.
   - Alternative: re-sample once the painted cover lands.
   - Flip condition: it reads too close to Emotions or Pets on the shelf.

## 6. Remaining and deferred

- **Shelf capacity for seven books:** check that `DictionaryShelf` fits a seventh book. This resolves with a visual check after build.
- **Content spec:** read `DICTIONARY_3000_PLAN.md` for entry count and style. It already matched a `Sanskrit` grep and feeds the content workflow, not this wiring.
- **Docs routing:** per `CLAUDE.md`, the plan and audit belong in `Docs/02_Plan/`.
