# Cat UI: Plan

This plan makes the Cat look the app's default. The Appearance picker drops to two looks: **Cat** (light page and dark page) and **Midnight**. It has six phases, and each one should build green on macOS and iOS:

1. **Foundation.** Add the Besley face and the two Cat palettes. Collapse `Appearance`: Umber, plain Light/Dark and System go away, a stored "umber" is migrated, and the picker is redone.
2. **The cat icon set**, routed through the existing `Glyph` table. This includes the iPhone tab bar. The "Hand-drawn icons" switch retires.
3. **One drawing component (`CatArt`)** plus the art, placed screen by screen.
4. **Components the palette can't reach.** This covers the signing-in screen (paw prints instead of the dark busy overlay), paw prints in place of the spinner, and the iPhone Feedback sheet.
5. **The screens the canvas did not draw**, extended in the same style.
6. **Cleanup and standing docs.**

> **Scope.** Grounded in `feat/iphone` @ `4a001e1`. The working tree is clean apart from the untracked `Docs/01_Brainstorm/CAT_THEME_BRIEF.md`. Nothing here is built.
>
> **Upstream.** There is no strategy doc. The inputs are:
> - the operator's words;
> - the Claude Design canvas "Pencil Cat Mascot" (inspiration, not a spec);
> - [CAT_THEME_BRIEF.md](../01_Brainstorm/CAT_THEME_BRIEF.md).
>
> **Prior work mirrored.** [THEMES_PLAN.md](THEMES_PLAN.md) and [THEMES_PLAN_RESOLVED.md](Resolved/THEMES_PLAN_RESOLVED.md) supply the Midnight/Umber naming, the exhaustive-switch rule and the `Theme.of` seam. [THEMES_SLATE_PLAN.md](THEMES_SLATE_PLAN.md) (Paper, High Contrast, widget palette) was never built and is superseded by this plan. Leave it alone as a point-in-time record.
>
> **Scope shape.** This is a single change, landed as six ordered commits on `feat/cat-ui`. Branch it from `feat/iphone`, because `main` does not have the iPhone commit. Line numbers are as of `4a001e1` and will drift as earlier phases land; the symbol named beside each citation is the anchor that lasts. If the operator wants each phase as its own PR, re-ground Phases 3–5 just-in-time with `/plan`. The invariants in §3 stay canonical here.

---

## 0. Detected stack (re-read from disk for this plan)

| | Evidence |
|---|---|
| Build | `OneWord.xcodeproj` with two targets (app and widget). Xcode 16 synchronized groups: new files under `OneWord/` join the app target on their own. `OneWord/Shared/` is the exception: it is referenced by explicit path (`SharedRefs`, `project.pbxproj:129-148`) and compiled into the widget too. |
| Dependencies | SPM packages firebase-ios-sdk and GoogleSignIn-iOS (`project.pbxproj:643-660`). The brief's "no package deps" is out of date. This plan adds none. |
| Platforms | `IPHONEOS_DEPLOYMENT_TARGET 17.0`, `MACOSX_DEPLOYMENT_TARGET 14.0` (`:455-457`), `TARGETED_DEVICE_FAMILY 1,2` (`:565`). iPhone uses tabs, switched by `isPhone` (`PaneHeader.swift:20-24`). iPad uses the Mac split view. |
| UI / architecture | SwiftUI with MVVM. `@Observable` view models import Observation only (`WordViewModel.swift:12-16`). The pattern to copy: every pane resolves `let t = Theme.of(scheme, doodle)` at the top of `body` (e.g. `HomeView.swift:24`). |
| Concurrency | `SWIFT_VERSION 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `MEMBER_IMPORT_VISIBILITY` (`:560-565`). No `SWIFT_STRICT_CONCURRENCY`, so checking is minimal. `Appearance` and `DoodleTheme` are `nonisolated` (`Appearance.swift:16`, `DoodleTheme.swift:73`). |
| State | `@AppStorage("appearance")` holds a raw string (`OneWordApp.swift:22`, `SettingsView.swift:19`). The doodle switches are separate keys (`DoodleTheme.swift:90-91`). Everything is resolved once into `\.doodle` together with `.preferredColorScheme` (`OneWordApp.swift:80-82`). |
| Assets | `Assets.xcassets`, with Swift asset symbols on (`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES`, `:406,:472`). SVG is already in use (`bookmark_icon.imageset`). Bundled media sits at the `OneWord/` root and is loaded with `Bundle.main.url` (`DictionaryPicker.swift:20-23`). |
| Fonts | `OneWord/Fonts/`, registered via `UIAppFonts` plus `ATSApplicationFontsPath "."` (`Info.plist:5-6,35-41`). Precedent for a variable font: Plus Jakarta Sans, addressed by family name plus `.weight()` (`DoodleTheme.swift:116-123,144-149`). |
| Tests | No XCTest target. The gates `tools/check_*.sh` compile Swift by path. `check_learned.sh:191-196` compiles `Shared/Theme.swift` and `ViewModels/WordViewModel.swift`. |
| Localization | No `.xcstrings` or `.strings` files. Literal strings are used throughout. |

**Files read for this plan:**
- Models: `Appearance.swift` 1-50, `DoodleTheme.swift` 1-192, `Profile.swift` 1-71, `LearnedWords.swift` 1-110
- Shared: `Theme.swift` 1-172
- Root: `OneWordApp.swift` 1-94, `WordCapture.swift` 55-143, `Info.plist`
- Views:
  - `RootView.swift` 1-396, `Doodles.swift` 1-144, `SettingsView.swift` 1-451, `PaneHeader.swift` 1-192
  - `HomeView.swift` 1-120, `WordDetail.swift` 1-406, `SignInView.swift` 1-140, `FeedbackView.swift` 1-139
  - `WordListView.swift` 40-130 and 206-277, `LearnedListView.swift` 13-80 and 236-270
  - `MonthCalendar.swift` 100-237, `HistoryView.swift` 17-80, 150-180 and 270-338
  - `SentenceView.swift` 21-247, `DictionaryPicker.swift` 1-260, `PremiumBar.swift` 1-129
  - `PremiumView.swift` 28-140, 165-330 and 420-469
  - `ProfileView.swift` 23-330 and 530-628
- View models: `AuthViewModel.swift` 40-70, 180-245 and 300-350; `WordViewModel.swift` 1-88
- Gates and config: `tools/check_*.sh` (sources compiled), `project.pbxproj` settings, the `Assets.xcassets` Contents.json files
- Docs and design: the project `CLAUDE.md`; `Docs/00_Context/{REPO_MAP,ARCHITECTURE,DESIGN_BRIEF}.md`; `Docs/README.md`; the three prior theme plans; the canvas boards `ThemeIcons`, `ThemeAppearance`, `ThemeMotion`, `ThemePlacement` and every `Mac*`/`Phone*` image placement

**One fact verified on the dev host:** ImageIO decodes the animated satchel WebP as `org.webmproject.webp` with **24 frames, DelayTime 0.034 s each**, so the loop is about 0.82 s (probe run against the downloaded asset on macOS 27). The same behaviour on the deployment targets is `[Inference]`: WebP decoding has been in ImageIO since iOS 14 and macOS 11.

---

## 1. What we're reusing

| Need | Already here | File |
|---|---|---|
| A palette as a value | `struct Theme`: 9 colours plus `roundness`, `glow`, `tiles` | `Shared/Theme.swift:18-40` |
| Palette resolution, app side | `Theme.of(_:_:)`, an exhaustive switch with no `default` | `Models/DoodleTheme.swift:169-176` |
| The display face, decided in one place | `DoodleTheme.face(_:_:)` / `tracking(_:)` | `DoodleTheme.swift:138-159` |
| One table of icon *meanings* | `Glyph`, 13 cases, `(symbol, doodle)` pairs | `DoodleTheme.swift:37-67` |
| One view that draws a meaning | `GlyphIcon` (box 1.32×) | `Views/Doodles.swift:24-58` |
| A dark-mode rim on drawings | `Doodle`'s white halo shadow | `Doodles.swift:89-90` |
| Hairline sections vs tiles | `entryBlock` switches on `t.tiles` | `WordDetail.swift:349-364` |
| The picker | `LazyVGrid` → `AppearanceTile` with a per-mode `preview` | `SettingsView.swift:68-84, 380-446` |
| Animation state already in the app | `WordViewModel.isPeeking`, `DictionaryShelf.swapping`/`shakes`, `SentenceView.rolling` | `WordViewModel.swift:23`, `DictionaryPicker.swift:48-51`, `SentenceView.swift:41` |
| A one-shot "bump" effect | `Shake: GeometryEffect` | `DictionaryPicker.swift:214-225` |
| An environment flag added with `@Entry` | `\.sidebar` | `PaneHeader.swift:26-30` |
| Bookmark change signal | `SavedWords.didChange`, already observed by Home | `HomeView.swift:78-80` |

**Not added:** a theme protocol, a `ThemeManager`, a new view model, a dependency, network fetches, or a `Theme` field per canvas swatch.

**Not renamed:** `DoodleTheme`. It is a known misnomer (`ARCHITECTURE.md`, "Appearances"), and renaming it is still churn with no change in behaviour.

---

## 2. Decisions the code made

| # | Decision | Why, with the code that forced it |
|---|---|---|
| D1 | **Keep the stored raw values** `system`, `light`, `dark`, `midnight`. The first three *become* Cat (Automatic / Light / Dark). Only `umber` is retired. | "A stored raw value is forever" (`ARCHITECTURE.md`). The picker selects by raw-string equality (`SettingsView.swift:77`), so keeping the strings means every System, Light and Dark user lands on a selected tile with no migration. |
| D2 | **A stored `"umber"` is rewritten to `"dark"` (Cat's dark page) once, in `OneWordApp.init()`.** | Without the rewrite, `Appearance(rawValue:) ?? .system` (`OneWordApp.swift:39`, `DoodleTheme.swift:99-100`) would quietly land Umber users on Automatic with **no tile selected**, because Settings compares raw strings. Umber readers chose a dark page, so they keep one. *(This is the product half of F1. It flips to Automatic if the operator prefers.)* |
| D3 | **The palettes are `Theme.cat` and `Theme.catNight`**, renamed from `.light`/`.dark`. `Theme.umber` is deleted. They stay in `Shared/Theme.swift`. | Only three references exist (`DoodleTheme.swift:174` via `.of(scheme)`, `SettingsView.swift:412-416`, the `FeedbackView.swift:137` preview). `Theme.swift` must name nothing app-only (`check_learned.sh:194`, widget), and colour values pass that test. |
| D4 | **`Appearance.paintsPalette` is deleted.** **`Appearance.drawsCat`** takes its slot as the third exhaustive switch. | All four remaining appearances paint a palette, so the three `paintsPalette` tests (`RootView.swift:144,170,225-226`) collapse to their "true" branch. "Is this Cat?" is the new question every placement asks. It stays a pure `Bool` because `Appearance` is `nonisolated` and must not touch a MainActor `Theme`. |
| D5 | **Cat's `surface` is white `#FFFFFF`**, not the canvas's `#F5EFE4`. The sidebar keeps painting `PaneGround` (paper). | The canvas paints its **cards** white (MacSettings, MacPremium, MacSuggestion) and uses `#F5EFE4` for its sidebar. In the app, `t.surface` paints cards, sign-in buttons, the plank and fields: 14 sites, all card-like. There is no sidebar token, and none is added. *(Tuning knob: one value. A cream sidebar would be a new `Theme` field, and that is a separate change.)* |
| D6 | **Icons are SVG template imagesets referenced through generated `ImageResource` symbols** (`Image(.catIconHome)`), not string names. | Asset symbols are already on (`:406,:472`). A misspelled cat asset then fails to compile instead of rendering blank, which is the most likely silent failure across ~40 new names. `Image(ImageResource)` and `Label(…, image: ImageResource)` need iOS 17 / macOS 14, which matches the targets exactly. This is a deliberate departure from the string-name precedent (`Image("bookmark_icon")`). |
| D7 | **Every pose drawing goes through one view, `CatArt`.** It owns six rules: the Midnight rule (draw nothing or the given fallback), Reduce Motion, the dark-page rim, `catBenched`, `allowsHitTesting(false)` and `accessibilityHidden(true)`. | This is the same move as `GlyphIcon` (`Doodles.swift:5-10`): call sites ask for a pose and never for a rule. Avatars are the one exception; they go through `AvatarFace` (F5). |
| D8 | **The satchel walk ships as a bundled `.webp` at the `OneWord/` root.** It is decoded with ImageIO into `[CGImage]` off the main thread and stepped with a `TimelineView`. | Decoding was verified on the host (24 frames × 0.034 s). The root-file precedent is `book_pull.mp3`. SwiftUI's `Image` will not animate a WebP. If ImageIO ever refuses the file, converting it to APNG is the drop-in fix and the frame code stays the same. |
| D9 | **Event motion rides state that already exists.** No new view-model state. | The bookend leans on `swapping` and hops on `shakes` (already animated by `refuse`, `DictionaryPicker.swift:209`). Practice taps on `rolling`. The peek follows `isPeeking`. All of these already skip under Reduce Motion (`DictionaryPicker.swift:188,207`, `SentenceView.swift:206`). `WordViewModel` is untouched, so `check_learned.sh` is unaffected. |
| D10 | **The split view's tint is `Theme.cat.accent` (`#5B3FD6`) on both Cat pages.** Tabs keep `t.accent`. | macOS draws the selected sidebar row's label in white on the tint. White on Cat Night's `#A893FF` measures **2.54:1**; white on `#5B3FD6` measures **6.72:1**. Tabs tint the glyph itself on a dark bar, where `#A893FF` (6.95:1) is the readable one. |
| D11 | **Signing in under Cat is drawn inside `SignInView`.** The satchel replaces the standing cat and paw prints replace the buttons. `RootView` skips `BusyOverlay` under Cat. Elsewhere, `BusyOverlay` shows paws instead of a spinner under Cat (Feedback sending). | `auth.busy` is set only by the two sign-in calls (`AuthViewModel.swift:189-192,230-233`), and the overlay is applied only at `RootView.swift:107` and `FeedbackView.swift:38`. |
| D12 | **Header chrome icons stay SF Symbols in both looks.** This covers sidebar toggle, back, New Word, Pronounce, xmark, chevrons, lock, info and envelope. | The cat vocabulary is the 13 `Glyph` slots. Extending it is follow-up work, not this change. |
| D13 | **Shared layout does not change.** Header height stays 52pt, section-label type is unchanged, and tile sizes are unchanged. The only exceptions are the two iPhone fixes in F9. | "Midnight looks exactly as today." Anything not gated on `drawsCat` and not a Cat palette value reaches Midnight. |

---

## 3. Invariants (canonical, stated once)

1. **Midnight does not regress.** Every Cat-only change is either a Cat palette value or gated on `doodle.appearance.drawsCat`. Midnight's palette, `PaneGround` band, Jakarta face, tiles, pills and SF Symbols are untouched. The only exceptions are F9, if it is accepted.
2. **No cat in Midnight.** `CatArt` draws nothing (or its fallback). Avatars follow F5.
3. **Cats appear only where §6 Phase 3 places them.** They never appear in the word-entry column (an end-of-page "tail" below the entry is allowed), in search or bookmark rows, on covers or spines, in header strips, or in the widget. **There is at most one pose drawing per window**, and `catBenched` enforces that while the Mac suggestion card shows.
4. **Reduce Motion means every cat holds still.** Pose swaps become plain crossfades. `PawTrail` shows all prints lit. `SatchelWalk` shows the still satchel.
5. **`Theme.swift` names nothing app-only.**
6. **Stored raw values are forever.** That covers `appearance` and the `Avatar` raw values added here.
7. **Views load no data.** Decoding a bundled animation is presentation; the precedents are the sound players and `PremiumView.cover`.
8. **Widget unchanged.** It reads no `Theme` (`WordWidgetView.swift:67`) and gets no cat assets.

---

## 4. The two Cat palettes

Both are added to `Shared/Theme.swift`, replacing `light` and `dark`:

| Token | `cat` (light) | `catNight` (dark) | Note |
|---|---|---|---|
| background | `#FEFBF7` | `#1B1722` | |
| surface | `#FFFFFF` | `#272130` | D5 |
| ink | `#1E1B26` | `#F4EFE7` | |
| muted | `#625D6E` | `#A8A1B6` | |
| definition | `#2A2633` | `#E9E3DA` | |
| example | `#4B4658` | `#C9C2D3` | |
| accent | `#5B3FD6` | `#A893FF` | |
| rule (Hindi) | `#E9792B` | `#F38638` | |
| hairline | `#E9E2D6` | `#352E41` | |
| roundness | 1.5 | 1.5 | |
| glow / tiles | defaults (`.clear` / `false`) | defaults | Omit both, as `.umber` did. |

**Contrast** (WCAG 2.1, computed against background / surface):

| | Light | Dark |
|---|---|---|
| ink | 16.4 / 16.9 | 15.4 / 13.6 |
| definition | 14.3 / 14.8 | 13.8 / 12.2 |
| example | 8.8 / 9.1 | 10.2 / 9.0 |
| muted | 6.2 / 6.3 | 7.1 / 6.3 |
| accent | 6.5 / 6.7 | 7.0 / 6.2 |

Every text pair clears AA. Two weaker pairs:
- The light `rule` is 2.8:1. It only draws a decorative 2pt bar beside the Hindi line. Today's calendar ring therefore uses `accent`, not `rule` (Phase 2).
- Midnight's sidebar-selection contrast is the existing, accepted risk from `THEMES_PLAN.md` §8.

---

## 5. Architecture fit

Everything new is View-layer presentation. No view model is added or changed, apart from one defaults write in F5.

| Type / file | Layer, target | Responsibility | Copied from |
|---|---|---|---|
| `Appearance` *(MODIFIED)* | Models, app | 4 cases; `name` / `colorScheme` / **`drawsCat`** are exhaustive switches | `paintsPalette`, `Appearance.swift:44-49` |
| `Theme.cat`, `Theme.catNight` *(MODIFIED)* | Shared, app and widget | the two palettes | `Theme.umber`, `Theme.swift:93-103` |
| `DoodleTheme.face` *(MODIFIED)* | Models, app | Besley 500 for Cat, Jakarta for Midnight, Pulpen when handwriting is on | Jakarta arm, `DoodleTheme.swift:144-149` |
| `Glyph.cat: ImageResource` *(MODIFIED)* | Models, app | replaces `doodle: String?`; all 13 slots have art | the `art` table, `DoodleTheme.swift:50-66` |
| `GlyphIcon` *(MODIFIED)*, `Glyph.image(cat:)` *(NEW, in Doodles.swift)* | Views | cat template icon or SF Symbol; one `Image` value so `.tabItem` gets no conditional view | `GlyphIcon`, `Doodles.swift:24-58` |
| **`CatArt.swift`** *(NEW)*: `CatPose`, `CatIdle`, `CatEntrance`, `CatArt`, `CatBeat`, `SatchelWalk`, `PawTrail`, `@Entry catBenched` | Views, app | every cat drawing and its motion | `Doodle` (`Doodles.swift:68-92`), `Shake` (`DictionaryPicker.swift:214`), `@Entry sidebar` (`PaneHeader.swift:29`) |
| `Avatar` *(MODIFIED)* | Models, app | +12 cat faces and `isCat` | `Avatar` face table, `Profile.swift:54-69` |
| Assets *(NEW)* | `Assets.xcassets/Cat/{Icons,Poses,Avatars}`, `OneWord/cat_satchel_walk.webp`, `OneWord/Fonts/Besley-*` | app only | `bookmark_icon.imageset`, `book_pull.mp3`, `PlusJakartaSans-*` |

**`CatArt.swift` signatures** (these are the whole public surface; bodies are left to the build):

```swift
enum CatPose { case stand, satchel, asleep, lean, peek, lookup, study, bookend, tap, cushion, laptop
    var art: ImageResource }                       // .catStand … .catLaptop
enum CatIdle { case still, breathe, sway }
enum CatEntrance { case overLine, settle }         // rises once from behind a hairline / drops 6pt into place
struct CatArt<Midnight: View>: View {
    init(_ pose: CatPose, size: CGFloat, idle: CatIdle = .still, enter: CatEntrance? = nil,
         @ViewBuilder midnight: () -> Midnight)
    init(_ pose: CatPose, size: CGFloat, idle: CatIdle = .still, enter: CatEntrance? = nil)
        where Midnight == EmptyView
}
struct CatBeat: GeometryEffect { var t: CGFloat; var angle: Angle = .zero; var dx: CGFloat = 0; var dy: CGFloat = 0 }
                                                   // one out-and-back bump per whole step of t
struct SatchelWalk: View { let size: CGFloat }     // falls back to CatArt(.satchel) under Reduce Motion
struct PawTrail: View { let color: Color }
extension EnvironmentValues { @Entry var catBenched = false }
```

**What `CatArt` does:**
- **Gating.** If `!doodle.appearance.drawsCat`, it draws `midnight()`. If `catBenched`, it draws nothing.
- **Image.** `Image(pose.art).resizable().interpolation(.high).scaledToFit().frame(maxWidth: size)`. `size` means width, because the drawings are not square. It can shrink when the space it is offered is tighter (iPhone landscape sign-in).
- **Dark-page rim.** A white silhouette shadow, mirroring `Doodles.swift:89-90`, with a tighter radius of roughly `max(1, size × 0.012)` at opacity 0.9.
  - "Dark" is resolved from the **appearance**: `.dark` is true, `.light` is false, and `.system` follows `\.colorScheme`. That keeps sheets and popovers right even though they don't inherit `preferredColorScheme` (`FeedbackView.swift:19-22`, `SettingsView.swift:323-327`).
  - Knob: radius and opacity. If die-cut art arrives later, add it as the **Dark** appearance variant of each imageset and drop the rim. That needs no code.
- **Idle.** `breathe` is `phaseAnimator([false, true])` scaling y to 1.02 from the bottom over 3.6 s ease-in-out. `sway` is ±1.5° about the bottom over 4 s. Both are skipped under Reduce Motion.
- **Entrance.** `enter` is an on-appear offset (`overLine` draws a `t.hairline` rule under the cat and clips the rise behind it), skipped under Reduce Motion.
- **Pose swaps.** `.id(pose)` plus `.transition(.opacity)`, so a pose change animates as a crossfade.
- **Always on:** `.allowsHitTesting(false)` and `.accessibilityHidden(true)`.

---

## 6. Implementation phases

Verification is the same at the end of **every** phase:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'generic/platform=iOS Simulator' build
for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done
```

After the builds and gates, run that phase's by-eye list, **including a Midnight walk**: pick Midnight and visit Home, History, Search, Bookmarks, Dictionaries, Practice, Profile, Settings, Premium and Sign-in (Debug) on Mac and on the iPhone simulator. Expect no cat, SF Symbols, the band, tiles, pills and Jakarta.

### Phase 1: Foundation (first reversible move, then the look switches)

**1.1 Besley (no code).**

| File | Change |
|---|---|
| `OneWord/Fonts/Besley-Variable.ttf`, `Besley-Italic-Variable.ttf` NEW | Google Fonts' `Besley[wght].ttf` and `Besley-Italic[wght].ttf`, renamed to drop the brackets (mirrors `PlusJakartaSans-*-Variable.ttf`). |
| `OneWord/Fonts/Besley-OFL.txt` NEW | The OFL. Prefixed so it can't collide in the flat Resources copy (the precedent is `PlusJakartaSans-OFL.txt`). |
| `OneWord/Info.plist:35-41` MODIFIED | Two `UIAppFonts` strings. macOS registers them through `ATSApplicationFontsPath "."`. |

Verify: both builds pass. Nothing uses the font yet. This step reverts cleanly.

**1.2 Collapse the appearances and repaint.** This lands as one commit, because the `.umber` arms cannot compile half-removed.

| File | Change |
|---|---|
| `Models/Appearance.swift:5-49` | `case system, light, dark, midnight`. `name`: `"Automatic"`, `"Light"`, `"Dark"`, `"Midnight"` (F1). `colorScheme`: drop `.umber`. **Delete `paintsPalette`.** **Add `var drawsCat: Bool`**: `.system, .light, .dark → true`, `.midnight → false`, exhaustive with no `default`. Rewrite the header comment. |
| `Shared/Theme.swift:5-13, 42-64, 93-105` | `light`/`dark` become `cat`/`catNight` with §4's values. Delete `umber`. `of(_ scheme:)` returns `scheme == .dark ? .catNight : .cat`. Rewrite the header comment: Cat is the app's two pages, Midnight is the painted alternative, the widget still reads only `Font.serif`. |
| `Models/DoodleTheme.swift:169-176` | `Theme.of`: `.midnight → .midnight`; `.system, .light, .dark → .of(scheme)`. |
| `OneWordApp.swift:45-54` | In `init()`, before `configureFirebase()`: if `UserDefaults.standard.string(forKey: "appearance") == "umber"`, set it to `Appearance.dark.rawValue`. Add a `ponytail:` comment: a one-way rewrite, and it is safe to delete once no installed build predates this change. |
| `Views/RootView.swift:144` | `.tint(t.accent)`, unconditional. |
| `Views/RootView.swift:170` | `.tint(doodle.appearance.drawsCat ? Theme.cat.accent : t.accent)`, with a comment explaining D10. |
| `Views/RootView.swift:221-226` | `.scrollContentBackground(.hidden)` and `.background { PaneGround(t: t) }`, unconditional. Update the comment. |
| `Views/SettingsView.swift:410-418` | `preview`: `.system` → `HStack { page(.cat, as: .light); page(.catNight, as: .dark) }`, `.light` → `page(.cat, as: .light)`, `.dark` → `page(.catNight, as: .dark)`, `.midnight` unchanged. Fix the "five tiles" comment at `:70-71`. |
| `Views/FeedbackView.swift:137` | Preview `.light` → `.cat`. |

The compiler names every remaining site, because each switch is exhaustive.

**1.3 Besley through the one face seam.** `DoodleTheme.swift:138-151`. The handwriting branch stays first. Then:

```swift
switch appearance {
case .midnight:              // Jakarta, as today
case .system, .light, .dark: // .custom(Self.catFamily, fixedSize: size * Self.catScale)
                             //   .weight(weight == .regular ? .medium : weight)
}
```

- `catFamily = "Besley"`.
- `catScale` gets a **measured** constant, using the same method as `opticalScale` and `sansScale` (`:110-123`): take New York's cap height of 0.705em and divide by Besley's `CTFontGetCapHeight / pointSize`. `[Unverified]`: the measurement must be taken at build time.
- `tracking` is unchanged (Midnight only).
- Rewrite the header comment at `:5-22`.
- `Font.serif` stays for the widget and the spine titles (`DictionaryPicker.swift:328`; spines never change, per invariant 3).

**Verify (by eye):**
- Settings shows four tiles. Each Cat tile previews its "Aa" in Besley; Midnight's previews in Jakarta.
- Headword is Besley 500, part of speech is Besley italic (`WordDetail.swift:74`), Hindi falls back to the system Devanagari face, and corners are about ×1.5.
- The Cat Night sidebar selection reads white on deep violet.
- Set the stored value and relaunch:
  ```bash
  defaults write ~/Library/Containers/com.hariom.swift.oneword/Data/Library/Preferences/com.hariom.swift.oneword appearance umber
  ```
  The app should open on Cat's dark page with the **Dark** tile selected. A junk string should open on Automatic, as before.
- The Midnight walk.

### Phase 2: The cat icon set

**2.1 Author 15 SVG imagesets** in `Assets.xcassets/Cat/Icons/`. This is a plain folder, so it adds no namespace.
- **Names:** `cat_icon_{home,history,practice,bookmarks,dictionaries,search,settings,profile,feedback,learned,selected,bookmarked,premium,ring}` and `cat_paw`.
- **Path data:**
  - `ThemeIcons.dc.html` supplies the 13 slots.
  - `ring` is the outline path of `profile` alone (`M4.8 10 5.4 4l4.2 2.7…z`), stroke 1.3, from `MacHistory.dc.html`.
  - `cat_paw` is four circles and one path, fill only, from `MacSigningIn.dc.html`.
- **Style:** put presentation attributes **on each element**. Don't rely on CSS classes or `<g>` inheritance (`[Unverified]` how far Xcode's SVG renderer honours them).

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <path d="…" fill="none" stroke="#000" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="…" cy="…" r="1" fill="#000"/>   <!-- the canvas's ".f" shapes -->
</svg>
```

- **Contents.json:** `"images":[{"filename":"cat_icon_home.svg","idiom":"universal"}]` plus `"properties":{"preserves-vector-representation":true,"template-rendering-intent":"template"}`.
- **`cat_icon_bookmarked` is the exception.** It has `fill="#8F6CF7" stroke="#8F6CF7"` and `"template-rendering-intent":"original"`, so it keeps its own colour the way `bookmark_icon` does today.

**2.2 Glyph table.** `DoodleTheme.swift:37-67`: `art` becomes `(symbol: String, cat: ImageResource)`. `var doodle: String?` becomes `var cat: ImageResource`. Rewrite the doc comment, since every slot now has art. Add `extension Glyph { func image(cat: Bool) -> Image }` in `Doodles.swift`, returning `Image(cat)` or `Image(systemName: symbol)`; both are the same `Image` type.

**2.3 GlyphIcon.** `Doodles.swift:47-57`.
- **Cat branch:** `Image(glyph.cat)`, resizable, at `size × 1.85` square, centred in the **unchanged** `box` frame. At the sidebar's 13pt that draws the 24pt grid at its native 24pt, so the stroke is exactly 1.7pt and rows don't re-layout. 1.85 is the one tuning knob.
- **Midnight:** the SF Symbol as today.
- **Delete** `plated` and `struct Doodle` (`:60-92`). After 2.5 they have no callers; the rim reappears inside `CatArt` in Phase 3.

**2.4 Tab bar.** `RootView.swift:140` becomes `.tabItem { Label { Text(tab.title) } icon: { tab.glyph.image(cat: doodle.appearance.drawsCat) } }`. Template SVGs at 24pt are the size tab bars expect.

**2.5 The two state glyphs.**
- `BookmarkRibbon` (`WordDetail.swift:370-406`): replace the `doodle.icons` branch with a `drawsCat` branch.
  - Filled: `Image(.catIconBookmarked)`.
  - Not filled: `Image(.catIconBookmarks)` tinted `t.muted`.
  - Use the existing classic geometry: draw the 24-grid oversized, about `size × 1.5`, inside `frame(width: size × 0.7, height: size)`. The ribbon spans 10×16 of 24.
  - Add `@Environment(\.colorScheme)` and resolve `Theme.of`.
- `LearnedSeal` (`ProfileView.swift:609-621`): under Cat it draws `Image(.catIconLearned)` tinted `t.accent`. Midnight keeps `learned_icon`.

**2.6 Retire "Hand-drawn icons"** (F3, recommended). Delete:
- `DoodleTheme.icons` (`:75`), `iconsKey` (`:90`) and its read in `current` (`:96`);
- `OneWordApp.swift:26` and the `icons:` argument at `:80`;
- `SettingsView.swift:22`, plus the icons row and its rule (`:92-97`).

Rewrite the section note at `:87-88` to say the widget keeps its serif and the face doesn't ship in it. Fix the `Doodles.swift:140` preview. A stored `doodleIcons` key is simply ignored, so no migration is needed. The compiler lists every site, because the memberwise init changes.

**2.7 Today's cell.** `MonthCalendar.swift:181-183`. Under Cat, the `isToday` branch draws `Image(.catIconRing)`, resizable, 38×38, `foregroundStyle(t.accent)`, overflowing the 34×30 Mac cell the way the canvas does (`left:-3, top:-5`). Midnight keeps `strokeBorder(t.rule)`.

**Verify (by eye):**
- Sidebar, search launcher, feedback button and Profile rows show cat icons. The selected sidebar row's icon turns white with its label.
- iPhone tabs show cat icons, and the selected tab is violet.
- The bookmark toggle swaps between a grey and a violet ribbon, and the stretch still plays.
- On Mac: Services → Save to One Word shows the violet ribbon and Besley in the HUD (`WordCapture.swift:118-122`, through `DoodleTheme.current`).
- History shows the cat-ear ring on today.
- Settings → Doodle has one switch.
- Icons stay crisp at 52pt. The SVG strokes have round caps, and nothing renders as solid black (R1).
- The Midnight walk.

### Phase 3: `CatArt` and the placements

**3.0 Import the art.** This is an operator or build-session step; the assets are uploads on `https://claude.ai/artifact/7av5v7AY5UwCtik4DQyEvv`, fetched by asset id. No code ever names an asset id. Put each PNG in the **1x slot** of an imageset, the convention `Dictionary_of_*` already uses for large art drawn smaller.

| Folder | Asset id → name |
|---|---|
| `Cat/Poses/` | `3735e430…` → `cat_stand` (hero, flagged hi-res) · `b89b8f87…` → `cat_satchel` (hero, flagged) · `f406301d…` → `cat_asleep` · `7f221a64…` → `cat_lean` · `cb0d05a8…` → `cat_peek` · `6857b099…` → `cat_lookup` · `a8e59411…` → `cat_study` · `cf694cdf…` → `cat_bookend` · `687bda58…` → `cat_tap` · `50c675b3…` → `cat_cushion` · `bd53ccce…` → `cat_laptop` (244pt, flagged) |
| `Cat/Avatars/` | `033c704d…` closeup · `5237313c…` lookup · `70982048…` sideeye · `fa145203…` beret · `555c98ee…` atwork · `515ecbd5…` glasses · `c182d55e…` medal · `faa82a13…` asleep · `1ae663c5…` curious · `5e896bee…` peeking · `22d64d0c…` standing · `491bfbd3…` glancingback. Each is named `cat_avatar_<name>`. |
| `OneWord/` root | `742aa65d…` (animated WebP, 24 frames, 464×544) → `cat_satchel_walk.webp` (hero, flagged) |

Leave these out: the die-cut Asleep `2afe4f21…` (dark reference only) and all deferred-feature art (F6).

**3.1 `Views/CatArt.swift` NEW (§5), with one consumer as the vertical slice.** In `LearnedListView.emptyState` (`:243-266`), the query-empty branch becomes:

```swift
CatArt(.study, size: isPhone ? 190 : 200, idle: .breathe) {
    GlyphIcon(.learned, size: 52, weight: .thin).foregroundStyle(t.accent.opacity(0.5))
}
```

Midnight's mark is passed as the fallback, which is F2's recommended answer. Verify: build, then compare Learned empty in Cat, Cat Night (rim visible), Midnight (seal unchanged) and with Reduce Motion on (still).

**3.2 Empty states.** In `WordListView.emptyMark` (`:242-252`):
- **Bookmarks, query empty:** `CatArt(.lookup, size: isPhone ? 150 : 168, idle: .sway) { GlyphIcon(.bookmarks, …) }`.
- **Any no-match:** `CatArt(.peek, size: isPhone ? 152 : 160, enter: .overLine) { hexagon }`.
- The Search empty-query state is handled in Phase 5.

The mark's `.foregroundStyle(t.accent.opacity(0.5))` moves into the fallbacks.

**3.3 Home.**
- `WordDetail` gains `var tail: CatPose? = nil`.
  - Wrap the ScrollView's `ZStack` (`:62-122`) in a `VStack(spacing: 0)`. Append `CatArt(tail, size: isPhone ? 128 : 144, idle: .breathe)`, trailing-aligned with the page's margins, **outside** the `.id(word.term)` content. That keeps the word's cross-dissolve from carrying the cat (§ThemeMotion).
  - Add `static let columnEdge: CGFloat = 56 + 720`, written beside the `:113-116` numbers it restates, so the two can't drift.
- `HomeView` (`:23-81`): wrap the Group's content in a `GeometryReader`.
  - `room = width − WordDetail.columnEdge − 16`.
  - **If `room ≥ 158` (corner fits):** an `.overlay(alignment: .bottomTrailing)` draws the resident at 144pt, 14pt in. While `model.isPeeking`, it draws `.lean` at `min(226, room)` instead, overhanging the trailing edge by about 14pt, with `.transition(reduceMotion ? .opacity : .move(edge: .trailing))` and `.animation(.easeOut(duration: 0.3), value: model.isPeeking)`.
  - **Otherwise:** pass `tail:` with the same pose, so the pose swap crossfades. iPhone always lands here, which is the canvas's "end of scroll"; narrow Mac panes do too (F8).
- **Wake on bookmark:**
  - In the existing `.onReceive(SavedWords.didChange)` (`:78-80`), after `model.refresh()`, add `if SavedWords.contains(model.word) { wakes += 1 }`.
  - Add `.task(id: wakes) { guard wakes > 0 …; awake = true (0.25s ease-out); sleep 2.25s; awake = false (0.4s ease-in) }`. This is the `rollToken` pattern (`SentenceView.swift:48-52,87-91`). It cancels when Home disappears and restarts on a second bookmark.
  - Pose is `isPeeking ? .lean : awake ? .lookup : .asleep`.
  - New state: `@State awake`, `@State wakes`, `@Environment(\.accessibilityReduceMotion)`.

**3.4 Dictionaries.**
- `DictionaryShelf` gains `var bookend = false` (init `:68`). Only `DictionaryPicker` passes `bookend: !isPhone`, so the History sheet keeps its plain shelf.
- In `body` (`:107-112`), when `bookend && drawsCat`, subtract `158 + 18` from `room` so the spines make space.
- `shelfEnd` is `shelfStart` plus the same Σ(spine × height + gap) that `positions` walks (`:87-97`).
- In the `ZStack`:

```swift
CatArt(.bookend, size: 158, idle: .breathe)
    .modifier(CatBeat(t: shakes.values.reduce(0, +), dy: -4))         // hops once per refusal, on refuse's own 0.4s transaction
    .rotationEffect(.degrees(swapping ? -2 : 0), anchor: .bottom)      // leans toward the pulled book
    .animation(.smooth(duration: 0.5), value: swapping)
    .frame(width: 158, height: floor + 7, alignment: .bottom)          // feet on the plank, no image height needed
    .offset(x: shelfEnd + 18)
```

- **iPhone:** in `DictionaryPicker`'s `PremiumBar` inset (`:238-244`), add `.overlay(alignment: .topTrailing) { if isPhone { CatArt(.bookend, size: 122, idle: .breathe).alignmentGuide(.top) { $0[.bottom] - 6 }.padding(.trailing, 18) } }`. When Premium is owned, iPhone shows no Dictionaries cat.

**3.5 Practice.** `SentenceView`:
- **Mac:** `.overlay(alignment: .bottomTrailing) { if !isPhone { CatArt(.tap, size: 132).modifier(CatBeat(t: catTaps, angle: .degrees(-5), dx: -7)).padding(.trailing, 22).padding(.bottom, 14) } }`, attached **before** `.contentShape`/`.onTapGesture` (`:82-86`).
- **iPhone:** the 112pt cat rides inside `hint(_:)` (`:165-178`) above the text, trailing-aligned. The hint already has `allowsHitTesting(false)`.
- **Taps:** add `@State catTaps: CGFloat` and `.onChange(of: rolling) { _, now in if now { withAnimation(.easeInOut(duration: 0.6)) { catTaps += 2 } } }`. That is two taps at 0.3s each. `rolling` is never true under Reduce Motion (`:206`).

**3.6 Premium (not owned).** In `lifetime(t)` (`:193-215`), add `.overlay(alignment: .bottomTrailing) { CatArt(.cushion, size: isPhone ? 118 : 168, idle: .breathe).offset(x: isPhone ? 8 : 30, y: isPhone ? 20 : 34) }`. The overhang is 30pt, not the canvas's 52pt, so it stays inside the 44pt ScrollView padding instead of being clipped. The owned state is in Phase 5.

**3.7 Feedback sent.** In `FeedbackView.thanks` (`:111-129`), put `CatArt(.laptop, size: isPhone ? 240 : 244, idle: .breathe)` first in the VStack. That fits the Mac 430pt sheet at about 290pt in total.

**3.8 Sign-in hero, idle only.** In `SignInView` (`:31-42`), insert `CatArt(.stand, size: isPhone ? 240 : 264, idle: .breathe)` between the first `Spacer()` and the wordmark. The busy state is Phase 4.

**3.9 Suggestion card and the bench.**
- `RootView.suggestionCard` (`:354-388`): `.overlay(alignment: .topTrailing) { CatArt(.peek, size: 78, enter: .settle).alignmentGuide(.top) { $0[.bottom] - 8 }.padding(.trailing, 40) }`.
- In `split` (`:160-165`), put `.environment(\.catBenched, !calloutSeen)` on the detail `NavigationStack`, so pane cats step out while the card shows. The sidebar is not benched. iPhone has no card.

**3.10 Avatars and the Settings badge** (F5, recommended).
- `Profile.swift:37-70`: add 12 cases right after `.account`: `catCloseup, catLookup, catSideEye, catBeret, catAtWork, catGlasses, catMedal, catAsleep, catCurious, catPeeking, catStanding, catGlancingBack`. These raw values are forever. Each gets a face-table row: name ("Close-up", "Looking up", …) and asset `cat_avatar_*`. Add `var isCat: Bool`, taken from a third table column. The existing 13 stay, so stored picks still resolve.
- `ProfileView.picture` (`:305-323`): `ForEach(Avatar.allCases.filter { doodle.appearance.drawsCat || !$0.isCat })`.
- `AvatarFace` (`:537-569`): add `@Environment(\.doodle)`. Under Midnight, a cat avatar draws as `.account`, which honours invariant 2.
- **Default for new profiles:**
  - Where: `AuthViewModel.recordJoinDate` (`:320-326`), inside the first-sighting branch (`joinKey == 0`).
  - What: if `profileAvatar` is unset, write `Avatar.catLookup.rawValue`.
  - Isolation: this stays on the MainActor (the class default), and `AuthViewModel` imports no SwiftUI.
- **Settings badge:** `AppearanceTile` (`:388-393`). On the **Automatic** tile only, and only when `drawsCat`, overlay `AvatarFace(avatar: .catCloseup, …)` at 34pt (Mac) or 20pt (iPhone) with a 2pt `t.surface` ring, bottom-trailing (−8, −8). It sits *outside* the preview's `clipShape` so it isn't cut off.

**Verify (by eye), for each placement above:**
- **Cat light:** the size and position match the table.
- **Cat Night:** the rim reads as a sticker edge, not a glow (R4).
- **Midnight:** no cat, and the fallback marks are unchanged.
- **Reduce Motion:** everything still. On Mac: System Settings → Accessibility → Display. In the iPhone simulator: Settings → Accessibility → Motion.
- **Home:** at 1000×680 the cat goes to the end of the page. With the sidebar folded or the window wide, it moves to the corner. The peek slides in and out. A bookmark wakes the cat for about 2 s.
- **Dictionaries:** the bookend sits on the plank, leans on a pull, and hops on a locked book. Spines don't collide with the caption.
- **Practice:** the clicks still roll the reel.
- **Suggestion card (first launch):** clear the key with `defaults delete … suggestionCalloutSeen`. While the card shows there is no Home cat; after closing the card, the Home cat returns.
- **Profile:** cats appear in the grid under Cat and are hidden under Midnight.

### Phase 4: Components the palette can't reach

**4.1 Signing in.**
- `SignInView`: when `auth.busy && drawsCat`:
  - the stand is replaced in place by `SatchelWalk(size: isPhone ? 220 : 242)`;
  - the buttons block (`:43-73`) is replaced by `VStack { PawTrail(color: t.accent); Text("Signing you in…") }` in muted 13pt, with `.accessibilityElement(children: .ignore).accessibilityLabel("Signing you in")`;
  - on entering busy, post `AccessibilityNotification.Announcement("Signing you in")`. Focus is otherwise lost when the buttons vanish.
- `RootView.swift:107` becomes `.busy(auth.busy && !doodle.appearance.drawsCat, theme: …)`. Midnight keeps its dim and spinner.

**`SatchelWalk`:**
- Holds `@State frames: [CGImage]`, loaded in `.task` with `frames = await Task.detached { Self.decode() }.value`.
- `nonisolated static func decode() -> [CGImage]` uses `Bundle.main.url(forResource: "cat_satchel_walk", withExtension: "webp")`, then `CGImageSourceCreateWithURL`, then `CreateImageAtIndex` for `0..<Count`. Add `assert(!frames.isEmpty)` in Debug.
- Draws `TimelineView(.animation(minimumInterval: 0.034)) { i = Int(t / 0.034) % frames.count }` with `Image(decorative:scale:)`, resizable.
- Shows `CatArt(.satchel)` until the frames land, and always under Reduce Motion.

**`PawTrail`:**
- Five `Image(.catPaw)` at 22pt, spaced 12. Rotation alternates 76°/104° with y offset ∓5, as in the canvas.
- Opacity per print comes from `TimelineView(.animation)`: phase = ((t − i·0.35) mod 1.75) / 1.75. It fades in to 12%, holds to 45%, and fades out by 78%. Scale goes 0.8 → 1.
- Under Reduce Motion, all prints are lit and still.

**4.2 Paws in the shared wait.** `BusyOverlay` (`Doodles.swift:100-116`) gains `@Environment(\.doodle)`. Under Cat it shows `PawTrail(color: theme.accent)` in place of `ProgressView()`; under Midnight it is unchanged. Its only other user is Feedback sending (`FeedbackView.swift:38`).

**4.3 iPhone Feedback sheet (F9).** `FeedbackView.swift:35` becomes `.frame(width: isPhone ? nil : 520, height: isPhone ? nil : 430)`, plus `#if os(iOS) .presentationDetents([.medium, .large]) #endif`. The fixed 520pt box doesn't fit a 390pt phone in *either* look.

**4.4 iPhone header targets (F9).** `PaneHeader.swift:136` changes `isPhone ? 40` to `44` for both `minWidth` and `minHeight`. The strip stays 52pt (D13).

**4.5 No code, verify by eye:**
- Header tiles: `ink 7%` at radius 8 × 1.5.
- Cards: white with a hairline, at radius 10–18 × 1.5.
- Section labels: unchanged.
- Sidebar selection: D10.
- Sheet buttons (Feedback, the History picker's Done): do they pick up the violet tint? `[Unverified]` whether macOS sheets inherit `.tint`. If they come out in the black `AccentColor` (`AccentColor.colorset`), add `.tint(doodle.appearance.drawsCat ? theme.accent : nil)` inside the two sheets. Don't touch `AccentColor`, because that would reach Midnight.

**Verify (by eye):**
- Sign in with Apple and with Google under Cat. The satchel walks at about 0.8 s per loop, the prints light in turn, and VoiceOver announces the sign-in.
- The same flows under Midnight show the dim and spinner.
- Feedback → Send under Cat shows paws over the dim.
- On iPhone, the Feedback sheet is a bottom sheet with no clipping.

### Phase 5: Screens the canvas didn't draw

| State | Decision | Code |
|---|---|---|
| Search, empty query ("Look in every book") | Cat: `CatArt(.study, size: isPhone ? 152 : 160, idle: .breathe)`, fallback `GlyphIcon(.dictionaries, 52, .thin)`. Without a drawing here, a cat stroke icon would sit at 52pt with a ~6pt stroke. | `WordListView.emptyMark:243-246` |
| Learned, no match | `CatArt(.peek, size: 160, enter: .overLine) { hexagon }` | `LearnedListView.swift:248-251` |
| Premium, owned | Cushion on the "Your dictionaries" card, using 3.6's overlay | `PremiumView.owned:306-312` |
| Premium owned tiles; PremiumBar spinner / Try Again / price; PlanTag | Tokens only. The owned tiles keep their SF Symbols, because `flag.checkered` and `square.grid.2x2.fill` have no cat slot. | none |
| Locked word | No cat: it sits in the entry column (invariant 3). `PremiumBar` via tokens. | none |
| Word detail pushed; related expanded | Tokens and Besley. The related-words "yarn spinner" is optional and skipped. | none |
| Search, Bookmarks and Learned non-empty lists | Besley and tokens. No cats in rows. | none |
| History: rail, strayed note, month menu, "Read History In" sheet | Tokens. The sheet's shelf has no bookend (`bookend` defaults to false). | none |
| Practice unrevealed / rolling | Besley, tokens, and 3.5's taps | none |
| Settings: Premium / Practice / Progress / Feedback sections, `InfoButton` popover | Tokens. The popover surface is now opaque white over the background (`SettingsView.swift:335-336`). | none |
| Profile: Mac non-edit view, gender chips, fluency bar | Tokens (the fluency bar uses `accent`, violet) | none |
| Sign-in error line | Tokens. It appears after busy ends, with the buttons back. | none |
| Launch blank | `Theme.of(…).background` (`RootView.swift:95`) gives Cat paper. The iOS system launch screen is left alone. | none |
| Mac capture HUD | Gets Besley and the violet ribbon automatically through `DoodleTheme.current`. `.regularMaterial` stays, because it floats over other apps. | none |

**Verify:** walk every row above in Cat light, Cat Night and Midnight.

### Phase 6: Cleanup and docs

- **Delete the doodle imagesets** (F3): `house_doodle`, `calender_doodle`, `write_doodle`, `bookmark_doodle`, `dictionary_doodle`, `check_doodle`, `wallet_doodle`. First, `grep -rn "_doodle" OneWord` should return nothing. `learning_icon` and `ac_icon` are unused but unrelated, so leave them.
- **Stale comments:** `grep -rni "umber\|hand-drawn\|doodle set\|paintsPalette\|New York stands in" OneWord`, then rewrite or delete what it finds. The `Theme.swift` header and `Font.serif` doc (`:167-171`) now apply only to the widget and the spines.
- **`Docs/00_Context/DESIGN_BRIEF.md`:** replace §3's "Appearances, as built" table with Cat (Automatic / Light / Dark: paper or night, Besley, ×1.5, hairlines, cat icons and drawings) and Midnight. Fix §8's "Midnight and Umber" line.
- **`Docs/00_Context/ARCHITECTURE.md`, "Appearances — adding a theme":**
  - the three switches are `name`, `colorScheme`, `drawsCat`;
  - `Theme.of` maps `.system/.light/.dark` to `.cat`/`.catNight` by scheme;
  - new rule: "a cat drawing is always `CatArt`; it owns Midnight, Reduce Motion, the rim and the bench";
  - add `CatArt` to the Layout list.
- **`Docs/README.md`:** add a Dossiers line: Cat UI, linking this plan.
- Docs in `01`–`06` are left untouched (point-in-time records).

**Verify:** both builds and all six gates.

---

## 7. Data and persistence

| Key | Store | Change |
|---|---|---|
| `appearance` | standard defaults | Values `system`, `light`, `dark` are kept and now mean Cat. `umber` is rewritten once to `dark` (D2). Junk still falls back to `.system`. |
| `doodleIcons` | standard defaults | Orphaned (F3). Ignored and not deleted. |
| `doodleFont` | standard defaults | Unchanged. |
| `profileAvatar` | standard defaults | Gains 12 new raw values. Seeded once with `catLookup` on a profile's first sighting on this device (F5). |
| `suggestionCalloutSeen` | standard defaults | Now also read as `catBenched`. |

No schema, migration framework, network call, App Group key or widget-visible state is involved. The `"appearance"` key string stays duplicated at its three existing sites plus the new migration line, as today.

---

## 8. Concurrency, state and memory

- **Isolation map.**
  - `Appearance` and `DoodleTheme` stay `nonisolated`. `drawsCat` is a `Bool` and must not touch `Theme` (MainActor by the project default).
  - `CatArt`, `SatchelWalk`, `PawTrail`, `CatBeat` and every view are MainActor by default. `CatBeat` mirrors `Shake: GeometryEffect`, which already compiles under this isolation (`DictionaryPicker.swift:214`).
  - `SatchelWalk.decode` is **`nonisolated static`**, so `Task.detached` actually leaves the main actor. A plain static on a View would be MainActor and hop straight back.
  - `[CGImage]` crossing back from the detached task may warn in Swift 5 mode, but it is not an error (`[Unverified]` whether this SDK marks `CGImage` `Sendable`). If the warning is unwanted, decoding 24 frames on main costs about 40 ms once, at sign-in.
  - Generated `ImageResource` statics may be MainActor under default isolation `[Unverified]`. Every reader (`Glyph` and the views) is MainActor, so this is safe either way.
- **Tasks and cancellation.**
  - Home's wake uses `.task(id: wakes)` and cancels when Home disappears. `try? Task.sleep` falls through, so a cancelled wake still settles back to asleep.
  - `SatchelWalk.task` is torn down with the view.
  - `TimelineView` closures don't escape.
  - `WordViewModel.shuffle`'s existing `[weak self]` revert task is unchanged.
- **State ownership.**
  - `@State`: `awake`/`wakes` (`HomeView`), `catTaps` (`SentenceView`), `frames` (`SatchelWalk`), the entrance flag (`CatArt`).
  - Environment: `catBenched`, derived from `RootView`'s existing `@AppStorage`.
  - No `@Observable`, no Combine `sink`, no delegate added.
- **Retain cycles.** None are possible: everything new is a value type. Nothing needs a capture list.
- **Memory.** About 24 MB of decoded frames, alive only while the signing-in view is on screen (464 × 544 × 4 bytes × 24 frames). The posters are 11 PNGs of about 480px, decoded on demand by the asset catalog.
- **Animation clock.** The `phaseAnimator` breathe keeps SwiftUI's frame loop running while a breathing cat is visible (R3).

---

## 9. Test plan

- **No XCTest target**, and none is added: this is the project's convention, and `THEMES_PLAN.md` §9 had the same reasoning. The logic added is a three-line migration, two exhaustive switches and layout arithmetic.
- **The gate that matters is compile time.** D6's asset symbols make a missing or misspelled cat asset a build error. `check_learned.sh` still compiles `Theme.swift`, which must keep naming nothing app-only (invariant 5). Run all six gates every phase.
- **One runtime check:** `assert(!frames.isEmpty)` in `SatchelWalk.decode`, Debug only, so a WebP the decoder refuses fails loudly in development.
- **Hard to test, with the seam to use:** SwiftUI bodies, placement and motion are verified by eye, per the lists in §6. On Mac, `open --env ONEWORD_PANE=<pane>` launches straight into a pane (`RootView.swift:24-30`) for screenshot walks. Use the Xcode run for live testing: don't `open -n` a second copy or kill the debug session.
- **Matrix per phase:** {Mac, iPhone simulator, iPad simulator for the split view} × {Cat light, Cat Night, Midnight} × {Reduce Motion off, on}. Add a VoiceOver spot-check on Sign-in (the Phase 4 announcement) and on a pane with a cat (it should not be read).

---

## 10. Accessibility, localization and project mechanics

- **Accessibility.**
  - Every drawing is `accessibilityHidden`: they are decorative, and the canvas's alt texts are not carried over.
  - Avatars keep `.accessibilityLabel(choice.name)` (`ProfileView.swift:318`) with the new names.
  - `PawTrail` has a label, and sign-in posts an announcement.
  - Reduce Motion is honoured everywhere (invariant 4).
  - Contrast is in §4 and D10. iPhone header targets go to 44pt (F9).
  - Dynamic Type: Besley uses `fixedSize:`, matching `face()` (`DoodleTheme.swift:128-131`). That is a pre-existing gap, not widened here.
- **Localization.** There is no String Catalog. New literals ("Automatic", "Signing you in…", avatar names, the Settings note) follow the existing `Text("…")` convention.
- **Target membership.** No `project.pbxproj` edit. Everything new sits under synchronized groups.
  - The `.webp` at `OneWord/` root is copied as a resource, like `book_pull.mp3` `[Inference]`.
  - **Do not put anything in `Shared/`**: the palettes are edits to an existing Shared file, not new files there.
- **Info.plist.** Two `UIAppFonts` entries. No usage strings, entitlements or capabilities.
- **Availability.** `phaseAnimator`, `ImageResource`, `Label(_:image:)`, `AccessibilityNotification` and `@Entry` all fit iOS 17 / macOS 14, so no `#available` is needed.
- **Widget.** Untouched, and no cat assets go into its target.

---

## 11. Decision forks (the operator's)

**F1: Picker shape.** *Recommended:* four tiles, **Automatic · Light · Dark · Midnight**. The first three are Cat. The cat badge sits on Automatic, and the section note reads: *"Automatic, Light and Dark are the cat's pages; Midnight leaves the cat out."* Umber users land on Dark (D2).
- *Alternative:* exactly three tiles (Cat Light · Cat Dark · Midnight) with no automatic option. This wins if the operator wants the cat's light or dark to be an explicit choice rather than following the device. Cost: `.system` is deleted, and the migration also maps a stored `"system"` (and *no* stored value, i.e. the default) to `.light`. `colorScheme` loses its `nil` case.
- Names are display-only (D1), so they stay cheap to change at any time.

**F2: Midnight empty states.** *Recommended:* keep today's ribbon, book and hexagon marks and SF Symbols. These are passed as `CatArt` fallbacks. *Flips if* the operator wants Midnight to have its own drawn marks, which would be new art.

**F3: Doodle switches.** *Recommended:* remove "Hand-drawn icons" (Cat's set replaces it, and the `*_doodle` assets retire). Keep "Handwritten type". *Alternative:* remove both. That also deletes the Pulpen branch in `face()` (`DoodleTheme.swift:139-143`), the two Pulpen files, `LICENSE.txt`, two `UIAppFonts` lines and the Settings section. It wins if Pulpen over Besley reads as off-brand.

**F4: Art resolution.** *Recommended:* import the canvas art now under the stable names in 3.0, and replace the flagged heroes (`cat_stand`, `cat_satchel`, `cat_satchel_walk.webp`, `cat_laptop`) with 800–1100px sources later. Replacement is drop-in, with zero code. *Flips to* "wait for hi-res" if the operator won't ship soft heroes, even briefly.

**F5: Avatars.** *Recommended:* add the 12 cats and keep the existing 13. A first-time profile on a device defaults to "Looking up". **Under Midnight, cat avatars are not offered, and a stored one draws as the account photo** (invariant 2).
- *Alternative A:* treat a picked face as the user's own and show it in Midnight too. This wins if the operator rules that avatars aren't "drawings". It is a one-line removal in `AvatarFace` and the grid filter.
- *Alternative B:* keep `.account` as the default. This wins if the first-sighting heuristic is unwanted (R12).

**F6: Deferred features** (streak, read-day dots, stickers, milestone and Share, notes, What's New, thank-you, "days in a row"). *Recommended:* deferred, see §14. *Flips* per feature if the operator pulls one forward. Each needs new data first.

**F7: Widget.** *Recommended:* stays plain. *Flips if* the operator wants Cat on the desktop. That is THEMES_SLATE_PLAN's widget-palette work plus bundling art into the widget target, which is its own plan.

**F8: Home cat on narrow Mac panes** (new). At the default 1000×680 window the pane is about 785pt, which leaves no room outside the 776pt column.
- *Recommended:* corner when it fits, end of page otherwise. That is the same rule iPhone gets, with one code path.
- *Alternatives:* (a) hide the cat when the corner doesn't fit, if the operator wants the cat *only* in the corner; (b) let it overlap the column's empty bottom corner, if the strict "never in the column" rule is relaxed.

**F9: Two iPhone fixes that also touch Midnight** (new). The Feedback bottom sheet (4.3) and 44pt header targets (4.4).
- *Recommended:* apply both to both looks. The 520pt box doesn't fit a phone, and 44pt is the HIG minimum.
- *Flips to* Cat-only, or deferred, if the operator holds Midnight pixel-identical without exception.
- The 44pt header *height* from the canvas is declined in both cases (D13).

---

## 12. Risks and exits

| Risk | Severity · confidence | Leading indicator | Cheapest exit |
|---|---|---|---|
| R1: Xcode's SVG renderer mishandles strokes or caps (icons look filled, square-ended or missing) | Med · Med `[Unverified]` | Phase 2 by-eye at 13pt and 52pt | Outline the strokes to filled paths offline once and re-import. Failing that, export the 15 icons as PDF. |
| R2: Besley's variable `wght`/italic isn't honoured via `.custom` + `.weight()` | Med · Low | Headword renders at 400, or the part of speech is upright | Ship static `Besley-Medium.ttf` and `Besley-MediumItalic.ttf` and address them by PostScript name (the Pulpen precedent, `DoodleTheme.swift:105-108`). |
| R3: The perpetual breathe keeps the frame loop running, costing CPU and battery | Med · Med | Activity Monitor shows more than about 2% CPU idle on Home (Mac), or Xcode's Energy gauge on iPhone | Breathe for 3 cycles after appear or interaction, then hold. Or keep breathing only on Hero screens. |
| R4: The shadow rim reads as a glow, not a die-cut edge, or costs frames during the pane crossfade | Low · Med | Cat Night by-eye; dropped frames on pane switch | Tune radius and opacity. Then try `.drawingGroup()` on the art. Final fix: die-cut **Dark** variants in each imageset (no code). |
| R5: `.tint` doesn't drive the macOS sidebar selection fill as the existing comment claims (`RootView.swift:168-170`) | Med · Low `[Unverified]` | The Cat Night selection isn't violet | Accept the system accent there. It is legible because the label sits on a system blue fill. |
| R6: Hero art looks soft on Retina | Low · High (known) | Sign-in at 2× and 3× | F4 drop-in. |
| R7: The bookend's reserved room shrinks the spines too far, or collides with the caption in narrow windows | Med · Med | Dictionaries at the minimum window width | Hide the bookend (and drop the reservation) when `w − shelfStart < spines + 176`. |
| R8: `CatArt`'s `EmptyView` under Midnight still adds VStack spacing (Sign-in, Feedback "thanks") | Low · Low `[Inference]` | Midnight sign-in spacing differs from `4a001e1` | Wrap those two sites in `if doodle.appearance.drawsCat`. |
| R9: The tab bar ignores the template tint or the size of the asset icon | Low · Low | iPhone tabs show black or oversized icons | Tabs use SF Symbols in both looks, and the cat icons stay in-app. |
| R10: The ImageIO WebP decode fails on iOS 17 / macOS 14 (host verified only) | Low · Low | The Debug assert fires | Convert to APNG offline and keep the same name stem; decoding code is unchanged. |
| R11: Practice cat (iPhone SE) or the peek and cushion overhangs collide with text | Low · Med | By-eye on the smallest devices | Shrink the size on compact heights, or drop that placement on iPhone. |
| R12: The first-sighting avatar seed fires for a long-time user whose join date was never recorded | Low · Low | A user reports their photo changed to a cat | Option B in F5: one deleted `if`. |

---

## 13. Sequencing and verification summary

1. **Phase 1.1**, Besley files and plist. This is **the first reversible move**: pure additions, nothing reads them.
2. **Phase 1.2**, collapse and repaint, plus the migration and D10. Unblocks: `drawsCat` and the palettes everything else reads.
3. **Phase 1.3**, Besley in `face()`.
4. **Phase 2**, the icon set. Unblocks: the tab bar, ribbons and today ring. Independent of art.
5. **Phase 3.0**, art import (operator or build session). This gates the rest of Phase 3.
6. **Phase 3.1**, `CatArt` and Learned empty: the thin end-to-end slice. Then 3.2–3.10, any order. Each builds alone.
7. **Phase 4**, signing in, paws, F9. Depends on 3.1 (`CatArt`), 3.8 (the stand) and 2.1 (`cat_paw`).
8. **Phase 5**, undrawn screens. Depends on 3.1.
9. **Phase 6**, cleanup and docs. Last; it deletes only what Phases 2 and 3 orphaned.

**End-to-end confirmation.**
- Both `xcodebuild` builds and all six gates are green after each phase.
- Fresh install: the app opens in Cat, following the device's light or dark. The picker shows Automatic / Light / Dark / Midnight.
- A stored `umber` opens on Dark.
- Every Mac and iPhone screen in §6 shows its cat at the right size and position, with SF Symbols only in header chrome.
- Midnight is identical to `4a001e1` apart from F9.
- Reduce Motion stills every cat.
- Sign-in under Cat walks the satchel and lights the paws.

---

## 14. Follow-ups: deferred features and the data each needs

There are no steps for these here (F6). The common blocker: `LearnedWords` keeps only the **first** sighting per word (`Models/LearnedWords.swift:37-80`, `dictionary → term → Date`), so the app can't tell which *days* you read.

| Feature | Data it needs first |
|---|---|
| Streak (paw and count in the header) | A per-day read log: a set of local `yyyy-MM-dd` keys, written beside `LearnedWords.record` at `WordDetail.swift:134-138`. Streak = consecutive days ending today or yesterday. |
| Read-day dots in History | The same day set, read by `MonthCalendar.dayCell`. |
| "Days in a row" Profile tile | The same day set, counted by `ProfileViewModel`. |
| Stickers, milestone sheet and Share | Milestone definitions (streak and word-count thresholds), an earned-sticker store (id and date), the deferred art, and `ImageRenderer` + `ShareLink`. |
| Missed-day and welcome-back notes | The day set plus a last-open date and a per-gap dismissed flag. |
| What's New sheet | The last-seen `CFBundleShortVersionString` and bundled release notes. |
| Premium thank-you sheet | A one-time flag set on the first `isUnlocked` false→true transition in `PremiumViewModel`, telling a purchase apart from a restore. |

---

## 15. Assumptions and open questions

- `[Verified on host]` The satchel WebP decodes via ImageIO: 24 frames, 0.034 s each. `[Inference]` It decodes the same way on iOS 17 and macOS 14. Resolved by Phase 4's Debug assert on both simulators.
- `[Unverified]` Besley's `wght` axis spans 400–900 and the italic is a separate variable file. Resolved by opening the Google Fonts download in 1.1.
- `[Unverified]` Besley's cap-height ratio, which sets `catScale`. Resolved by measuring with `CTFontGetCapHeight` in 1.3.
- `[Unverified]` Xcode's SVG renderer honours per-element `stroke-linecap`/`linejoin` and arc commands. Resolved by Phase 2's by-eye check (R1).
- `[Unverified]` `.tint` colours the macOS sidebar selection (R5), and macOS sheets inherit `.tint` (4.5). Both are resolved by the first Phase 1 and Phase 4 runs.
- `[Inference]` A `.webp` placed at `OneWord/` root is copied into the bundle, like `book_pull.mp3`. Resolved by `Bundle.main.url` returning non-nil (the Debug assert).
- `[Inference]` A `CatArt` resolving to `EmptyView` adds no VStack spacing (R8). Resolved by the Midnight sign-in comparison.
- `[Assumption]` The cat art PNGs have transparent backgrounds and filled bodies. The one sample seen (Asleep, 480×386) is a full-colour pencil drawing on transparency. Resolved at 3.0 import.
- `[Assumption]` Canvas colours are taken as given (they are hex values from the boards, not sampled), and the contrast in §4 is computed from them.
- **Open (operator):** F1 tile names, F5 avatars under Midnight, F8, F9. Everything else in §11 has a recommended default the build can proceed on.
