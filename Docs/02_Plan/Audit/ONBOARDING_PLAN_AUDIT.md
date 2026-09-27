# Plan audit: ONBOARDING_PLAN.md

> Produced 2026-09-27 by `/plan-audit --report` against [../ONBOARDING_PLAN.md](../ONBOARDING_PLAN.md) on `main` at `675065b`. Verdict: **Ready to build once the four Major corrections are written into the plan** (medium-high confidence). No blockers.

## 1. Header

**Plan audited:** `/Users/hariom/Desktop/One Word/Docs/02_Plan/ONBOARDING_PLAN.md` ("Onboarding: implementation plan", `main` @ `675065b`). Its upstream brief is `plan-onboarding-brief.md` (scratchpad), which I read in full.

**Stack, re-checked from disk. It matches what the plan claims.**
- **Project:** Xcode 27.0 (27A266a), `MacOSX27.0.sdk`. One `OneWord.xcodeproj` with the app `OneWord` and the widget `OneWordWidget`. `OneWord/` is a `PBXFileSystemSynchronizedRootGroup` (`project.pbxproj:97-106`). `Shared/` is also referenced by explicit path (`:62-85`).
- **Build settings:** `MACOSX_DEPLOYMENT_TARGET = 14.0` (`:458,516`). `SWIFT_VERSION = 5.0`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES` and `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` are set on the app target (`:553-557`, `:590-594`). No `SWIFT_STRICT_CONCURRENCY` override.
- **Dependencies:** SPM firebase-ios-sdk and GoogleSignIn-iOS (`:272-273`).
- **App:** sandboxed with an App Group (`OneWord.entitlements`). No test target. Six `tools/check_*.sh` gates, and none of them compiles `Views/` (their compile lines name only `Shared/`, `Models/` and `WordViewModel.swift`).
- **Minor difference:** the widget target has neither `MEMBER_IMPORT_VISIBILITY` nor `APPROACHABLE_CONCURRENCY`. This doesn't matter here because no widget file is touched.

**Files and symbols I opened:**
- `OneWord/Views/`:
  - read in full: `PremiumView.swift` 1-442, `RootView.swift` 1-350, `PremiumBar.swift` 1-129, `SignInView.swift` 1-119
  - read in part: `SentenceView.swift` 40-130, `HistoryView.swift` 40-60, `FeedbackView.swift` 50-60 and 96-130, `HomeView.swift` 8-20, `DictionaryPicker.swift` 40-50 and 326-348, `PaneHeader.swift` 15-124, `WordDetail.swift` 50-70, 112-126 and 240-255, `WordListView.swift` 120-160, `Doodles.swift` 110-140
  - grep only: `SettingsView`, `ProfileView`, `LearnedListView`
- `OneWord/ViewModels/`: `WordViewModel.swift` 1-88, `AuthViewModel.swift` 40-165, `PremiumViewModel.swift` 19-46
- `OneWord/Shared/`: `Word.swift` 1-18, `WordProvider.swift` 1-127, `Premium.swift` 1-49, `Theme.swift` 105-175, `SavedWords.swift` (grep)
- `OneWord/Models/`: `Wordbook.swift` 1-63, `DoodleTheme.swift` 90-170, `LearnedWords.swift` 1-12
- App root: `OneWord/WordCapture.swift` 1-12, `OneWord/OneWordApp.swift` 1-54
- Widget: `OneWordWidget/WordWidget.swift` 1-66, `WordWidgetView.swift` 55-95
- Project and tools: `project.pbxproj` (sections above), the scheme (grep), `OneWord.entitlements`, `tools/check_learned.sh` 188-197
- Docs: `CLAUDE.md` 50-56, `REPO_MAP.md` 23 and 50-54, `ARCHITECTURE.md` 120-175, `DESIGN_BRIEF.md` (§4, §6D, §8), `MARKET_FIT_RESEARCH_BRIEF.md` 262-272, `PREMIUM_PLAN_RESOLVED.md` 500-512
- SDK: the Accessibility `.swiftinterface` 1-20 and 210-262. The import headers of the SwiftUI, SwiftUICore, AppKit and CoreTransferable `.swiftinterface` files. SwiftUI's `module.modulemap` and `SwiftUI.h`. A search of the SwiftUI and SwiftUICore interfaces for `label`, `card`, `bookRow`, `footer`, `heading`, `perk`, `rule` and `tile`. `KeyboardShortcut`/`KeyEquivalent` at SwiftUI `.swiftinterface:27399-27419`.

**Citation accuracy:** nearly every `file:line` in the plan checks out. There are four small misses, listed under nits.

### Brief §(e), claim by claim

| # | Claim | Result |
|---|---|---|
| 1 | PremiumView spans and behaviour preservation | **Holds.** Every span holds what the plan says: fan 105-118, covers/cover 121-148, tile 300-322, card 396-408, label 343-349, bookRow 374-391, free 150-171, lifetime 173-195, price 199-217, action 220-236, footer 325-331, heading 335-340, rule 351-353, perk 356-371, task 63-68. The three `bookRow` callers are at 166, 189 and 290. Changing `private static` to `fileprivate static` is **required**, because Swift's `private` doesn't reach a sibling type, and the plan does it. `fixedSize` is preserved if PlanPair's body root is the HStack with `.fixedSize`, since it gets the same proposal inside the VStack [Inference, high]. |
| 2 | Moving the `.task` onto `owned(t)` | **Legal.** It is a modifier on a `some View` inside a ViewBuilder `if`. Only `owned` (280-281, 290) and `bookRow` read `counts`; `hero` reads only `Self.shelf.count` (91). The concern the plan raises is real: the cache is keyed per resource and written only *after* a decode (`WordProvider.swift:74-86`). That is check-then-act, so two concurrent first decodes both miss. The result is duplicate work, not a data race: `NSCache` is thread-safe and `WordList` is immutable and `Sendable` (`:109-112`). |
| 3 | File-scope `fileprivate` helpers | **No ambiguity found.** The macOS 27 SDK's SwiftUI and SwiftUICore interfaces have no `View` member named `card`, `label` or `bookRow`. The only hits are the tvOS-only `PrimitiveButtonStyle.card` and `label` properties on configuration structs. The module has no top-level functions with those names. The copies in other files are `private` members of their own types, and member lookup finds those first. `FeatureTile` calling a `fileprivate` function from its own file compiles, the same way `PremiumView.body` calls `private` helpers today. Constructing these types from another file follows `PlanTag`, which is built at `RootView.swift:273` despite its `private @Environment` properties. |
| 4 | The gate edit | **Sound.** `$onboardingSeen` is `AppStorage`'s projected `Binding<Bool>`. `.task`/`.busy` keep wrapping the Group. While onboarding shows, `auth.isSignedIn` is short-circuited and never evaluated. |
| 5 | Keyboard pattern | **Sound.** Four buttons, four distinct keys, and UnlockButton/Restore have no shortcuts (`PremiumBar.swift:104-116`, `PremiumView.swift:223-227`), so nothing collides. `.plain` plus a shortcut already works in this app (⌘K at `RootView.swift:240-241`). So `.defaultAction` on a `.plain` button should fire too [Inference]; it just loses the blue default-button look, which the plan replaces with its own drawing anyway. |
| 6 | `-onboardingSeen NO` | **"Will", not "may."** The argument domain outranks the persistent write, so the run stays on onboarding (minor finding m4). |
| 7 | The `forward` flag | **Old value** [Inference, medium-high]. Where the modifiers sit matters more (M1, M2). |
| 8 | Height at 1000×680 | `.safeAreaInset` must wrap the GeometryReader. The hidden title bar reserves extra top height. The buy button falls below the fold too (M4). |
| 9 | Widget facts | **All confirmed:** `WordWidget.swift:55,61-63,46-52`; `WordWidgetView.swift:83-84`. The copy has an accuracy issue for Free users (m1). |
| 10 | Remaining items | `Word` fields are at `Word.swift:10-14`. A fresh install gets Everyday English (`Wordbook.swift:62`, `WordViewModel.swift:30`). OnboardingView names no `Product` and no Combine publisher. `.formatted` already compiles in files that import only SwiftUI (`MonthCalendar.swift`, `HistoryView.swift`). `\.purchase` is used only inside `UnlockButton`. The ARCHITECTURE lines are right (133-137 is exact). |

---

## 2. Verdict

**Ready to build, once the four Major corrections are written into the plan. Confidence: medium-high.**

I found no blockers:
- Nothing I traced fails to compile.
- There is no data race and no persistence risk: one new standard-defaults Bool, no migration.
- Sequencing is reversible-first, and each step compiles on its own.

The Majors are all short edits to the plan text:
- **M1:** state the exact modifier order, so the slide doesn't stack cards inside the ScrollView.
- **M2:** choose a slide pattern that actually changes direction on reversal.
- **M3:** clamp `go(_:)` so it can never index out of range.
- **M4:** correct R3's reasoning and get an answer on card 5's above-the-fold content. The brief locked "keep Restore Purchase visible", and the plan's default quietly relaxes that.

Steps 1-3 can start now. M4 needs the operator's answer before card 5 (step 4) is finalised.

---

## 3. Blocking findings

None found.

---

## 4. Major findings

### M1. Where `.id(page)` / `.transition` / `.safeAreaInset` go is ambiguous, and the natural reading stacks the old and new cards
- **Where in the plan:** Step 4, "Body layout", bullets 1-4 ("Then `.id(page)` and `.transition(...)` on the scrolled body").
- **What's wrong:** "the scrolled body" most naturally means the content *inside* the ScrollView. There, an identity swap leaves the outgoing card in the ScrollView's implicit vertical stack, so the incoming card is pushed down the page during the 0.22s transition. The repo has already hit this bug and documented it:
  - `WordDetail.swift:59-62`: "ponytail: ZStack, so the outgoing word overlaps the incoming one. In the ScrollView's own stack the fading copy keeps its slot and shunts the new word down the page on its way out."
- **Second risk:** if `.safeAreaInset { nav }` lands inside the id'd subtree, the nav is rebuilt on every page and slides with the card. That breaks the plan's own claim in `go(_:)` that VoiceOver focus "stays on the persistent Next button".
- **What works:** the height behaviour holds when the inset wraps the GeometryReader. PremiumView already does this: `.paneHeader`, a top `safeAreaInset` (`PaneHeader.swift:28-30`), wraps `GeometryReader` (`PremiumView.swift:38-62`), and content centres in `geo.size.height`.
- **Fix:** state the order explicitly:
  ```
  GeometryReader { geo in
      ScrollView { current(t)…frame(maxWidth: .infinity, minHeight: geo.size.height) }
          .scrollContentBackground(.hidden)
          .transition(…).id(page)
  }
  .safeAreaInset(edge: .bottom, spacing: 0) { nav(t) }
  .overlay(alignment: .topTrailing) { skip }
  .animation(.easeInOut(duration: 0.22), value: page)
  .paneBackground(t)
  ```
  The alternative is to keep the id on the content but wrap it in `ZStack(alignment: .top)` as WordDetail does. Putting the id on the ScrollView also gives each card a fresh scroll offset.
- **Severity:** Major (a visible glitch in the first-run flow, and the plan's a11y claim breaks). **Confidence:** high on the stacking (repo evidence), medium on the exact visuals.

### M2. The asymmetric slide will likely use the stale `forward` whenever direction reverses
- **Where in the plan:** Step 4 `go(_:)`, §6 "Slide direction", R5, and the matrix row "Slides in the right direction both ways".
- **What's wrong:** `forward` and `page` change in the same action, which is one transaction and one body pass. The subtree being removed (the old id) isn't re-evaluated in that pass, so its removal transition is the one from the *previous* render, with the old `forward` [Inference, medium-high]. On Back after Next, the outgoing card leaves toward the leading edge while the incoming card enters from the leading edge, so the two cross. R5 rates this Low/Medium and "[Unverified]". The failure is likely on every reversal, and the matrix row as written would fail.
- **Fix:** decide it in the plan now. Either:
  - (a) Split it into two phases. In `go`, set `forward`; this doesn't animate, because `.animation` is keyed on `page`. Then apply the page change on the next main-actor turn (`Task { page = next }`), so the outgoing view re-renders with the new removal edge first.
  - (b) Take R5's exit up front: use `.opacity` and delete `forward`.
- **Severity:** Major (visual, first impression). **Confidence:** medium-high.

### M3. `go(_:)` indexes `Self.titles[page]` without a bounds check
- **Where in the plan:** the Step 4 signature: `go(_ step: Int) // forward = step > 0; page += step; announce Self.titles[page]`.
- **What's wrong:** the only bounds are view state:
  - `.disabled(page == Self.titles.count - 1)` on the → twin
  - `.disabled(page == 0)` on Back
  - the Primary switching to `finish()` on the last card

  All of these change only after SwiftUI re-renders. If two key events (a held →, or a double Return) are handled before a re-render, `go(1)` runs from page 4 and `titles[5]` traps. The chance is low [Inference], but a first-launch crash is costly, and M2's option (a) makes queued increments more likely.
- **Fix:** start `go` with `let next = page + step; guard Self.titles.indices.contains(next) else { return }`, and use `next` everywhere after that.
- **Severity:** high impact (crash), low likelihood, so Major. It costs one line.

### M4. R3's reasoning is wrong for onboarding, and the default relaxes a locked requirement
- **Where in the plan:** R3, F4, and matrix row "1000×680".
- **What's wrong:**
  - The brief (e)5 says card 5 "Must stay skippable … and keep Restore Purchase visible." The plan's default instead lets Restore scroll below the fold.
  - R3 justifies this partly because Restore "also lives in Settings and PremiumBar". Both live in the shell, which RootView shows only after onboarding *and* sign-in (`RootView.swift:96-99`, plus the plan's own Step 5 gate). From card 5, a first-time user's only Restore is the scrolled one.
  - My own count agrees with the plan's ~700pt estimate for the Premium card. Visible space is smaller than the plan assumes, because the hidden title bar still reserves its height: panes take it back with `.ignoresSafeArea(.container, edges: .top)` (`PaneHeader.swift:29-30`), and SignInView/OnboardingView don't. Take away that strip, the nav and 2×24 of padding, and roughly 545-560pt is visible [Inference]. That puts **UnlockButton itself**, about 610-660pt down the card, below the fold, not just Restore.
- **Fix:**
  - Correct R3's text.
  - Make F4 an explicit operator decision before card 5 is built, rather than a default that overrides the brief.
  - One extra data point for F4: taking back the top strip the way panes do gains about 28pt. That alone isn't enough.
- **Severity:** Major (drift from a locked requirement; App Review risk itself looks low, since a restore path exists). **Confidence:** high on the drift, medium on the exact pixels.

---

## 5. Minor findings and nits

- **m1. The draft copy (F3) promises Free users what the code sells as Premium.**
  - Card 4 says "⌘K finds any word, with its full entry." A Free user's hit from a premium shelf opens locked: headword plus PremiumBar, and no Hindi in the row (`WordDetail.swift:247`, `WordListView.swift:129,152`, `ARCHITECTURE.md:127-129`). PremiumView sells "every entry opens in full" as Premium (`PremiumView.swift:253-255`), and card 5 would show that two cards later.
  - Card 2 says "choose Edit to give it a dictionary of its own." For a Free user every other choice is labelled "· Premium" and falls back to Everyday English (`WordWidget.swift:22-34,40-41`), and PremiumView sells "Any book on your widget" (`:268-270`).
  - **Fix:** a copy change only (operator-owned; see Q2).
- **m2. The nav has no background of its own.** If card 5's content scrolls under the pinned nav, text will show through behind Back, the dots and Next. PaneHeader exists to paint over exactly this (`PaneHeader.swift:21-23`, `.paneBackground(t)` at `:91`). Don't copy that onto a *bottom* bar, though: PaneGround's Midnight band is pinned to the top of whatever frame draws it (`Theme.swift:118-130`), so it would paint a bright strip at the bottom of the window. **Fix:** check card 5 at 1000×680. If content shows through, give the nav a `t.background` ground.
- **m3. Card 4 probably scrolls at 1000×680 too** [Inference]. It has an intro block plus two rows of three tiles, about 210pt each at roughly 218pt inner width, and the "Save from any app" text runs to about 5 lines. **Fix:** add card 4 to the matrix row "1000×680".
- **m4. R4 should say "will", not "may".** Reads resolve the argument domain first, so after `finish()` the re-read returns NO and the run stays on the cards. `AuthViewModel.swift:59-61` already relies on argument-domain reads. **Fix:** keep the `defaults delete <container plist>` route. [Unverified: I couldn't list the container from this sandbox.]
- **m5. R6 is settled.**
  - `AccessibilityNotification` is `@available(macOS 14.0)` in Accessibility.framework, and `post()` is an extension member there (`.swiftinterface` 220-255), so MemberImportVisibility applies.
  - It is probably visible through SwiftUI → AppKit, whose overlay does `@_exported import Accessibility`.
  - **Fix:** add `import Accessibility` unconditionally, with the repo's comment style (`PremiumView.swift:18`, `HomeView.swift:11`), rather than "only if rejected".
- **m6. Don't attach the hidden → twin to Back.** `.disabled(page == 0)` on Back flows down into its `.background`, which would disable → on card 1 [Inference]. **Fix:** attach the twin to the Primary or to the nav HStack, and say so in the plan.
- **m7. After a purchase on the Premium pane, the owned view's counts arrive one async hop later than today.** Today they are already filled by the root task. The rows show a blank for a moment; cosmetic. Also, `Task.detached` ignores `.task` cancellation, so a PlanPair decode still running at purchase can overlap the owned task's decode. That is harmless duplicate work.
- **m8. `CoverFan(books: Self.shelf)` fans 8 covers.** With an even count, `mid = 3.5`, so there is no upright centre cover, and the two middle covers sit at ±2.5° with the same zIndex (`PremiumView.swift:106-114`). The doc comment's "the centre one upright and on top" is no longer true for this caller. **Fix:** check it in the canvas and mention it in the `ponytail:` note.
- **m9. F2 branch B (only if chosen).** `.onChange(of: auth.restored)` fires after the body has already built OnboardingView once, including `WordViewModel()`'s decode on the main thread [Inference].
- **m10. Existing users who turned Hindi off will still see Hindi on card 1.** The `showHindi` setting lives at `WordListView.swift:27` (App Group). This only matters under F2's default.
- **Nits:**
  - `WordWidgetView.swift:65` should be `:67`.
  - "as `SentenceView.swift:79`" should be `:78`.
  - "Where it's sold" is `ARCHITECTURE.md:133-137`, not 138.
  - The Primary "as `SignInView.swift:103-108`": SignInView uses `t.radius(16)`, not 10.
  - §6 says RootView's body tracks only `restored` and `onboardingSeen` while onboarding shows. It also tracks `auth.busy`, `scheme` and `doodle` through `.busy(...)` (`RootView.swift:107`). Harmless.
  - `CLAUDE.md:54` still lists five gates. This is outside the plan's scope.
  - Optional: compute the transition into a `let` typed `AnyTransition` to keep the ternary cheap for the type-checker.

---

## 6. Coverage gaps

- There is no explicit modifier order for OnboardingView's body (M1), and no decision about a nav background when content scrolls under it (m2).
- The matrix doesn't cover:
  - holding → or pressing Return twice (M3)
  - pressing Back or Esc while a purchase is in flight (§6 reasons about it but never tests it)
  - card 4 at 1000×680 (m3)
  - reversing direction specifically (Next, then Back) (M2)
- R3/F4 don't mention that UnlockButton itself is below the fold (M4).

---

## 7. What the plan got right

- **Grounding is unusually accurate.** I verified nearly every citation: all the PremiumView spans, the RootView gate and task lines, the key-shortcut precedents, the WordProvider cache, and the widget facts.
- **The extractions are behaviour-preserving and correctly scoped.** Moving `books`/`shelf` from `private` to `fileprivate` is the required change, the `counts[...]` to `count:` rewrite hits exactly the three callers, and moving `fixedSize` with the pair keeps the shared card height.
- **Moving the `.task` onto `owned(t)` is correct and legal,** and the NSCache check-then-act analysis behind it is accurate.
- **The concurrency analysis is correct.** The detached closure captures `[String]` and returns `[String: Int]`, it calls the `nonisolated` WordProvider, and it compiles in Swift 5 mode unchanged.
- **Sequencing is right:** reversible-first, each step compiles alone, and the gate is the only switch users see.
- **It reuses the right pieces:** UnlockButton stays the only buy path, `premium.isUnlocked` comes from the environment, it avoids WordDetail's learned side-effect, and it copies the repo's existing hidden-twin key pattern.
- **Its uncertainty labels are mostly well placed.** R4, R5 and R6 were the right things to flag. M2 and m4 above firm two of them up.

---

## 8. Operator questions

1. **Card 5 at 1000×680 (M4).** The brief said "keep Restore Purchase visible." At the default size, both UnlockButton and Restore look to be below the fold. Which do you want: accept the scroll, a taller `.defaultSize`, a quiet Restore in the nav, or taking back the title-bar strip plus one of those?
2. **Copy (m1).** Should cards 2 and 4 avoid promising full search entries and a per-widget dictionary to Free users, since card 5 sells both as Premium?
3. **Slide (M2).** Two-phase directional slide, or the plain crossfade RootView already uses?
4. **F2.** Confirm that existing signed-in users see the cards once (the plan's default).
5. **`CLAUDE.md:54`.** Fix the five-gate list in this PR or separately?

---

## 9. What would change the verdict

- **To Needs rework:** if you require the whole plan pair *and* Restore to be visible without scrolling at 1000×680, with no change to `.defaultSize`. By my estimate (about 700pt of content against about 550pt visible), PlanPair as extracted can't fit. It would need a compact variant, which the plan deliberately avoids.
- **To Fix blockers first:** if step 2's build shows file-scope `label` or `card` shadowed or ambiguous. I think this is unlikely: the macOS 27 SDK interfaces declare no `View` members with those names.
- **To Ready to build with no conditions:** M1-M3 written into the plan (each one or two lines) and F4 answered.
