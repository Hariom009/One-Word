# Onboarding: Build Checklist

> Produced 2026-09-27 by `/checklist --report` from the resolved plan. One editorial correction was made on save: items 6d and D10 as returned assumed the `Docs/README.md` dossier line was still to be added; it was added when the plan was saved (README rule), so both now say so.

Derived from [ONBOARDING_PLAN_RESOLVED.md](../02_Plan/Resolved/ONBOARDING_PLAN_RESOLVED.md). That plan was resolved on 2026-09-27 against `main` at `675065b`. Section 4 is the resolved plan, §5 is the operator review queue and §6 is what remains.

The plan is **audited and resolved**. The audit verdict was *Ready to build once the four Majors are written in*, with no blockers. The resolver wrote in all 32 findings: 22 self-resolved, 5 operator decisions set to their recommended defaults, 1 not a defect and 0 deferred. This checklist only turns that plan into steps. It adds no scope and does not re-check any of the plan's claims. The raw plan and the audit are kept for provenance only.

**Stack (per the plan):**
- **Project:** one `OneWord.xcodeproj` with the app target `OneWord` and the widget target `OneWordWidget`.
- **Target membership:** `OneWord/` is an Xcode 16 synchronized group, so new files under `Views/` join the app target without a pbxproj edit.
- **Build settings:** macOS 14.0 deployment target, Swift 5 mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `MEMBER_IMPORT_VISIBILITY = YES`.
- **App:** SwiftUI with `@Observable` MVVM.
- **Verification:** there is no test target. You verify with the build, the six gates, grep checks and the manual matrix.

**Sizing peek (not an audit):**
- Symbol grep of `OneWord/Views/PremiumView.swift`, lines 20–413.
- Grep of `OneWord/Views/RootView.swift`, lines 69–316.
- `CLAUDE.md` lines 50–56.
- `HEAD` is `675065b`.

Every line number the plan cites for these files matches the code, so nothing is tagged `[Unverified]` for drift. **Line numbers below are from `main` before any edit and will move as you work.**

**Soft spots carried from the plan (§6, §4.12).** None of them blocks the build. Each one is settled by one run or one look:
- R3: card heights [Inference]
- R4: the container path [Unverified]
- R8: the widget menu wording [Unverified]
- R9/A1: dragging in the reclaimed strip [Inference]
- R10: `.defaultAction` on a `.plain` button [Inference]
- Row 9: how the purchase sheet handles keys [Unverified]

Steps 1–3 don't depend on any `DECIDE:` item, so they can start now.

## How to use

`- [ ]` todo · `- [x]` done · `blocked-by:` finish that item first · `DECIDE:` operator call · `⏸` deferred or evidence-gated, don't build now.

**One rule: don't check an item until its done-when holds.**

**Shorthand:**
- **B** means this command is green:
  ```bash
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
  ```
- **6G** means this command is green:
  ```bash
  for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done
  ```
- **"Premium pane identical"** means a screenshot taken at the S2 window size matches the S2 baseline for that state by eye. That covers the fan, the card heights (the Free and Premium cards share one height), the counts, "Try Again" and Restore.

**Running the app:** run everything from Xcode with ⌘R. Never `open -n` the app and never kill the Xcode debug run.

## Open operator decisions (DECIDE)

Each decision below has a default already applied, but none is settled. The build goes ahead on the defaults. An override changes the items listed under it.

F1 (placement before sign-in) and F5 (no Hindi toggle) are locked by the brief and are not open.

- [ ] **DECIDE-Q1: card 5 at 1000×680 (M4, F4, A2).**
  - **Default applied:**
    - Keep the scrolling body.
    - Add a quiet "Restore Purchase" and the `premium.problem` line to card 5's pinned nav. Restore makes the same `premium.restore()` call and uses the same `.disabled(premium.phase == .purchasing)` as `PremiumView.swift:223-227`. Both appear on the last card only, and only while Premium isn't unlocked.
    - PlanPair keeps its own Restore, so PremiumView stays identical and card 5 shows the link twice.
    - Take back the title-bar strip with `.ignoresSafeArea(.container, edges: .top)`.
    - No compact PlanPair and no `.defaultSize` change.
  - **Alternatives:**
    - (a) Raise the `.defaultSize` height. This affects every first window.
    - (b) Add a compact PlanPair, which is a second shape to keep in sync.
    - (c) Add `showRestore: Bool` to PlanPair to drop the duplicate link.
    - (d) Keep the title-bar strip.
  - **Flip when:**
    - (a) or (b): you need UnlockButton itself above the fold at the default size (R3).
    - (c): the duplicate link bothers you on a tall window.
    - **(d): row M20 shows the cards can't be dragged (R9, A1). Then delete the one `.ignoresSafeArea` line; the nav Restore still meets the requirement.**
  - The plan says Q1(d) is the most likely to flip. It is evidence-gated by M20, so build on the default and reopen Q1 after M20.
  - **Gates:** 4i (strip line), 4k2, 4k5.
  - **Done-when:** the operator has accepted the default or named the override letter, and any override is re-scoped into 4i/4k before those items are built. (d) is re-decided after M20.
- [ ] **DECIDE-Q2: card copy (m1, F3).**
  - **Default applied:**
    - Card 2 step 3 reads "↻ shows another word, and the widget follows the dictionary you pick in the app."
    - Card 4's Search tile reads "⌘K looks up a word from anywhere in the app."
    - Premium's claims stay on card 5.
  - **Alternative:** the original drafts ("…give it a dictionary of its own" and "…with its full entry").
  - **Flip when:** cards 2 and 4 get owner-specific variants (a ternary on `premium.isUnlocked`), or you accept the overclaim for Free readers.
  - **Gates:** 4e, 4g.
  - **Done-when:** the operator has accepted the default or overridden it before 4e and 4g are written.
- [ ] **DECIDE-Q3: page transition (M2, F6).**
  - **Default applied:** a plain crossfade, `.transition(.opacity)`. No `forward` state and no `accessibilityReduceMotion`.
  - **Alternative:** a two-phase directional slide (F6). It costs one `@State`, a deferred `Task { page = next }` and the reduce-motion branch. N7's precomputed `AnyTransition` comes back with it.
  - **Flip when:** a direction cue matters to you.
  - **Gates:** 4i, M6, M17.
  - **Done-when:** the operator has accepted the default or overridden it before 4i.
- [ ] **DECIDE-Q4: existing signed-in users (F2).**
  - **Default applied:** they see the cards once.
  - **Alternative (branch B):** `.onChange(of: auth.restored) { if auth.isSignedIn { onboardingSeen = true } }` on RootView's Group.
  - **Flip when:** the build ships to an existing audience and you judge the cards to be noise for them.
  - **Cost of B (m9):** OnboardingView, including `WordViewModel()`'s decode, is built once before `onChange` fires, and card 1 may paint for a frame [Inference].
  - [Inference] `MARKETING_VERSION = 1.0` suggests there are no store users yet.
  - **Gates:** 5f, M14.
  - **Done-when:** the operator has accepted the default or overridden it before 5f is resolved.
- [ ] **DECIDE-Q5: the `CLAUDE.md:54` gate list (N6, F7).**
  - **Default applied:** fix it in this PR (Step 6).
  - **Alternative:** a separate one-line PR.
  - **Flip when:** you keep doc-only changes out of feature PRs.
  - **Gates:** 6c.
  - **Done-when:** the operator has accepted the default or overridden it before 6c.

## Checklist

### Setup (feeds the "Premium pane identical" checks in 1f, 2f and 3h)

- [ ] **S1** Set `ONEWORD_PANE=premium` in the scheme's environment so the app launches on the Premium pane (`RootView.swift:24-30`). **Don't commit it** (per plan Step 1).
  - **Done-when:** ⌘R from Xcode opens on the Premium pane, and DoD-7 will check that it wasn't committed.
- [ ] **S2** Take baseline screenshots of the Premium pane before any edit, at one fixed window size, in the Free state and the owned state. For the owned state, buy with `StoreKit/OneWord.storekit`. Also capture "Try Again" with the StoreKit config off or offline (plan §4.7 item 3).
  - blocked-by: S1
  - **Done-when:** the Free, owned and Try Again screenshots exist, kept out of the repo, and the window size is written down.

### Step 1: extract `CoverFan` (no visible change; plan's first reversible move)

- [ ] **1a** Add `struct CoverFan: View { let books: [Wordbook]; var height: CGFloat = 100; @Environment(\.displayScale) private var displayScale }`. Its body is the old `fan` (`:105-118`) with `Self.books` → `books` and `100` → `height`. Keep `.padding(.top, 6)` and `.accessibilityHidden(true)` inside it.
  - files: `OneWord/Views/PremiumView.swift` (MODIFIED · app target) · isolation: MainActor (default)
  - **Done-when:** the struct is present with both modifiers inside its body.
  - [Assumption] Per plan §4.12, `height` is kept even though both callers use 100. See ⏸ D8.
- [ ] **1b** Move `private static var covers` and `private static func cover(_:height:scale:)` (`:121-148`) into CoverFan unchanged, comments included. `covers` stays a MainActor-isolated static.
  - blocked-by: 1a
  - **Done-when:** `grep -n "static var covers\|static func cover(" OneWord/Views/PremiumView.swift` hits only inside `CoverFan`.
- [ ] **1c** Change CoverFan's doc comment to: "The covers, fanned like a hand of cards, tipping away and settling lower towards the edges." Add this `ponytail:` note: *"tuned at 100pt; scale spacing/offset if a caller changes height. An even count (onboarding's 8) has no upright centre cover — the middle two sit at ±2.5° on the same zIndex."* (m8)
  - **Done-when:** `grep -n "hand of cards\|ponytail: tuned at 100pt" OneWord/Views/PremiumView.swift` returns both lines.
- [ ] **1d** Make `hero` (`:75`) call `CoverFan(books: Self.books)`.
  - blocked-by: 1a
  - **Done-when:** `grep -n "CoverFan(books: Self.books)"` returns one hit.
- [ ] **1e** Delete `fan`, `covers`, `cover` and PremiumView's `displayScale` property (`:24-25`). Nothing else reads it.
  - blocked-by: 1b, 1d
  - **Done-when:** `grep -n "var fan\|displayScale" OneWord/Views/PremiumView.swift` hits only inside CoverFan, and **B** is green.
- [ ] **1f** Check that Step 1 leaves the Premium pane unchanged.
  - blocked-by: 1e
  - **Done-when:** **B** is green and the fan is **Premium pane identical** to S2 in the Free state and the owned state. If it differs, revert Step 1 (R1).

### Step 2: move the shared helpers to file scope and add `FeatureTile` (no visible change)

- [ ] **2a** Move `card(_:emphasized:padding:_:)` (`:396-408`) and `label(_:_:)` (`:343-349`) out of the struct to file scope as `fileprivate func`, with bodies unchanged.
  - files: `PremiumView.swift` · isolation: MainActor (default)
  - blocked-by: 1f
  - **Done-when:** both are `fileprivate func` at file scope and no `card(t) {…}` or `label("…", t)` call site changed (check with `git diff`).
  - A compile error at a call site means ⏸ D1 (R2).
- [ ] **2b** Move `bookRow` (`:374-391`) to file scope as `fileprivate func bookRow(_ book: Wordbook, count: Int?, _ t: Theme) -> some View`, replacing `counts[book.id]` with `count`.
  - blocked-by: 2a
  - **Done-when:** the signature matches, and `counts` no longer appears in bookRow's body.
- [ ] **2c** Update bookRow's three callers:
  - `:166` becomes `bookRow(.everydayEnglish, count: counts[Wordbook.everydayEnglish.id], t)`
  - `:189` and `:290` become `bookRow($0, count: counts[$0.id], t)`
  - blocked-by: 2b
  - **Done-when:** `grep -n "bookRow(" OneWord/Views/PremiumView.swift` shows the definition plus 3 callers, all with `count:`, and **B** is green.
- [ ] **2d** Add `struct FeatureTile: View { let symbol: String; let title: String; let text: String }`. It reads `\.colorScheme` and `\.doodle`. Its body is `let t = Theme.of(scheme, doodle)` followed by the old `tile` body (`:301-321`), including `.accessibilityElement(children: .combine)`.
  - isolation: MainActor (default)
  - **Done-when:** the struct is present with `.accessibilityElement(children: .combine)` inside it.
- [ ] **2e** In `owned`, change the six `tile(a, b, c, t)` calls (`:250-270`) to `FeatureTile(symbol: a, title: b, text: c)`, then delete `tile`.
  - blocked-by: 2d
  - **Done-when:** `grep -c "FeatureTile(symbol:" OneWord/Views/PremiumView.swift` = 6, `grep -n "func tile\|[^e]tile(" OneWord/Views/PremiumView.swift` finds nothing, and **B** is green.
- [ ] **2f** Check that Step 2 leaves the Premium pane unchanged.
  - blocked-by: 2c, 2e
  - **Done-when:** **B** is green. With Premium owned (bought with the StoreKit config), the owned view's tiles, shelf and counts are **Premium pane identical** to S2 (per plan). The Free state's count rows are identical too, since callers `:166` and `:189` changed here.

### Step 3: extract `PlanPair` and move the counts task (no visible change; unblocks Step 4)

- [ ] **3a** Change `private static let books` and `private static let shelf` (`:28,30`) to `fileprivate static`.
  - blocked-by: 2f
  - **Done-when:** `grep -n "fileprivate static let books\|fileprivate static let shelf"` returns 2 hits.
- [ ] **3b** Add `struct PlanPair: View`:
  - Environment: `@Environment(PremiumViewModel.self) premium`, `\.colorScheme` and `\.doodle`.
  - State: `@State private var counts: [String: Int] = [:]`.
  - Body: `let t = Theme.of(scheme, doodle)`, then `HStack(alignment: .top, spacing: 24) { free(t); lifetime(t) }.fixedSize(horizontal: false, vertical: true)`.
  - The `fixedSize` moves in from `:49`, and the `ponytail:` comment at `:45-47` moves with it.
  - isolation: MainActor (default)
  - **Done-when:** the struct is present, and that ponytail comment appears once in the file, inside PlanPair.
- [ ] **3c** Give PlanPair a `.task { … }` copied verbatim from `:63-68`, with `Self.shelf` → `PremiumView.shelf`. See gate G2.
  - blocked-by: 3b
  - **Done-when:** a diff of the task body against main's `:63-68` shows only that substitution.
- [ ] **3d** Move `free`, `lifetime`, `price`, `action`, `footer`, `heading`, `perk` and `rule` (`:150-236, 324-340, 351-371`) into PlanPair as `private`, with `Self.books` → `PremiumView.books`. `action` keeps its own Restore Purchase, so PremiumView stays identical.
  - blocked-by: 3a, 3b
  - **Done-when:**
    - no `Self.books` or `Self.shelf` remains inside PlanPair (R1 early warning)
    - `grep -c 'Button("Restore Purchase")' OneWord/Views/PremiumView.swift` = 1, and it sits in `PlanPair.action`
- [ ] **3e** In PremiumView's body, replace `:48-49` with `PlanPair()`.
  - blocked-by: 3d
  - **Done-when:** `grep -n "PlanPair()"` hits in PremiumView's body.
- [ ] **3f** Move PremiumView's own `.task` (`:63-68`) off the root and onto the owned branch as `owned(t).task { … }`. This keeps the two counts tasks from ever running together, which would otherwise decode all eight books twice on a first visit. See gate G3.
  - blocked-by: 3e
  - **Done-when:** the only `.task` inside `struct PremiumView` is attached to `owned(t)`, and **B** is green.
- [ ] **3g** Update the file header comment (`:5-13`) to say PlanPair and CoverFan are reused by the onboarding cards.
  - **Done-when:** the header names both types and "onboarding".
- [ ] **3h** Check that Step 3 leaves the Premium pane unchanged.
  - blocked-by: 3c, 3f, 3g
  - **Done-when:** **B** is green and all of the following hold:
    - [ ] the Premium pane (not owned) is **Premium pane identical** to the S2 Free baseline, with counts in both cards and both cards the same height (R1)
    - [ ] buying with the StoreKit config swaps the pane to the owned view and the counts appear. A blank lasting about one hop before the counts land is expected (m7, cosmetic, `PremiumView.swift:384-385`).
    - [ ] Restore still works
    - [ ] "Try Again" still works (StoreKit config off or offline) and matches S2
  - If any of these fail, revert Step 3 (R1).

### Step 4: `OnboardingView` (not reachable yet; check it in the canvas; unblocks Step 5)

- [ ] **4a** Create the file with these imports:
  ```swift
  import SwiftUI
  import Accessibility   // AccessibilityNotification.post() — MEMBER_IMPORT_VISIBILITY needs it named
  ```
  - files: `OneWord/Views/OnboardingView.swift` (NEW · app target through the synchronized group, no pbxproj edit) · isolation: MainActor (default)
  - blocked-by: 3h
  - **Done-when:** the file exists with both imports, and `git status` shows no `project.pbxproj` change (G6).
- [ ] **4b** Declare the state and statics from the plan's shape:
  - `@Binding var seen: Bool`
  - `@State private var page = 0`
  - `@State private var model = WordViewModel()`
  - `@Environment(PremiumViewModel.self) private var premium`, `\.colorScheme` and `\.doodle`
  - `private static let titles = ["Welcome", "The widget", "Dictionaries", "Your words", "Plans"]`, with its doc comment
  - `private static let shelf = Wordbook.all.filter { $0.id != SavedWords.resource }`

  Accepted cost, per §4.6: `@State`'s initial value is re-evaluated on every RootView re-render, which is an NSCache hit, as in HomeView. Re-renders should be rare [Inference].
  - blocked-by: 4a
  - **Done-when:** every declaration is present exactly as listed.
- [ ] **4c** Add `intro(_ eyebrow:_ title:_ text:_ t:)`, styled like PremiumView's hero (`:77-98`):
  - an 11pt bold uppercase eyebrow with tracking 2.5, in muted
  - a `doodle.face(34-44)` title with `doodle.tracking`
  - a 15pt muted body with `lineSpacing(3)`
  - **Done-when:** in the canvas, intro's type matches the Premium hero by eye.
- [ ] **4d** Add `entry(_ word: Word, size:_ t:)`, drawn by hand: term, POS, Hindi only when non-empty, and the definition. Hide the Hindi line when `hindi.isEmpty` (`DESIGN_BRIEF.md:66`). **Don't** use `WordDetail`, which records the word as learned and carries actions.
  - **Done-when:** `grep -n "WordDetail" OneWord/Views/OnboardingView.swift` finds nothing, and `hindi.isEmpty` is present.
- [ ] **4e** Build card 1, `welcome`, and card 2, `widget`:
  - [ ] **4e1** `welcome`: `HStack(spacing: 48) { entry(model.word, size: 40, t) in a t.surface/t.hairline card at t.radius(18); intro(...) }`. The entry card gets `.accessibilityElement(children: .combine)`. Copy is F3.1: eyebrow "Welcome to", title "One Word", the body, and the visual label "Today's word".
    - m10 note: Hindi shows even if the reader turned `showHindi` off. The exit is ⏸ D6.
    - **Done-when:** the canvas shows today's word beside the copy.
  - [ ] **4e2** `widget`: a mock of the medium widget, about 360×170. It has the entry lines at a smaller size and an `arrow.clockwise` glyph at top-right, on `t.surface` plus `t.hairline`, with `.accessibilityHidden(true)`. Beside it go the F3.2 eyebrow ("On your desktop"), the title ("Put the word where you'll see it") and the three numbered steps, including ★ step 3 from DECIDE-Q2.
    - [Assumption] `t.surface` for the mock (see ⏸ D7). [Unverified] the exact macOS menu wording (R8).
    - blocked-by: DECIDE-Q2
    - **Done-when:** the canvas matches F3.2, and `grep -n "the widget follows the dictionary you pick in the app"` returns one hit.
- [ ] **4f** Build card 3, `dictionaries`: `CoverFan(books: Self.shelf)` beside `intro`. That is 8 covers, and m8's note applies. The premium names are `Self.shelf.filter { !Premium.free.contains($0.id) }.map(\.shortName).formatted(.list(type: .and))`. The title is "\(n) dictionaries, one shelf" and the body is from F3.3. The owner line "All of them are yours." is an optional ternary per the plan.
  - **Done-when:** the canvas shows 8 fanned covers and the generated names list, and `.formatted(.list(type: .and))` is present.
- [ ] **4g** Build card 4, `yourWords`: two rows of three `FeatureTile`s, each row `.fixedSize(horizontal: false, vertical: true)`, laid out as `PremiumView.swift:248-272`. The six F3.4 tiles include ★ Search from DECIDE-Q2. Take symbols from ones the app already uses (`PremiumView.swift:250-268`, `DoodleTheme.swift:52-55`).
  - blocked-by: DECIDE-Q2
  - **Done-when:** `grep -c "FeatureTile(" OneWord/Views/OnboardingView.swift` = 6, `grep -n "looks up a word from anywhere in the app"` returns one hit, and in the canvas each row has one height.
- [ ] **4h** Build card 5, `plans`:
  - If `premium.isUnlocked`: eyebrow "Premium · Unlocked", then "Every dictionary is yours." and "Thank you for supporting One Word." (as `:77-89`).
  - Otherwise: eyebrow "Free, or everything", then `PlanPair()`.

  Then add `@ViewBuilder current(_ t:)` as a `switch page` over 0…3, with `default:` → plans.
  - **Done-when:** the canvas shows PlanPair on card 5. The owned branch is checked at M8 and M12.
- [ ] **4i** Write `body` **in this exact modifier order** (M1, Q1, Q3). Gate G9 re-checks it.
  ```
  let t = Theme.of(scheme, doodle)
  GeometryReader { geo in
      ScrollView { current(t).frame(maxWidth: 920).padding(.horizontal, 40).padding(.vertical, 24)
                            .frame(maxWidth: .infinity, minHeight: geo.size.height) }
      .scrollContentBackground(.hidden)
      .transition(.opacity)      // on the ScrollView, not its content
      .id(page)
  }
  .safeAreaInset(edge: .bottom, spacing: 0) { nav(t) }
  .ignoresSafeArea(.container, edges: .top)
  .overlay(alignment: .topTrailing) { skip(t) }
  .animation(.easeInOut(duration: 0.22), value: page)
  .paneBackground(t)
  ```
  Keep the plan's three explanatory comments: the ScrollView/`WordDetail.swift:59-61` stacking note, the inset wrapping the reader, and the strip reclaim citing `PaneHeader.swift:28-29`.
  - blocked-by: 4h, DECIDE-Q1, DECIDE-Q3
  - **Done-when:** reading the body top to bottom matches the order above.
- [ ] **4j** Write `go(_ step: Int)` (M3):
  ```swift
  let next = page + step
  guard Self.titles.indices.contains(next) else { return }
  page = next
  AccessibilityNotification.Announcement(Self.titles[next]).post()
  ```
  Also write `finish()`, which sets `seen = true`.
  - **Done-when:** the guard is the first check in `go`, the announcement indexes `[next]`, and `grep -c "seen = true"` = 1.
- [ ] **4k** Build `nav(t)`:
  - [ ] **4k1** Read `let isLast = page == Self.titles.count - 1` and `let selling = isLast && !premium.isUnlocked` once, at the top of `nav`. Wrap everything in a `VStack(spacing: 8)`.
    - **Done-when:** both are `let`s at the top of `nav(t)` (G12).
  - [ ] **4k2** Problem line (A2): `if selling, let problem = premium.problem` shows a centred muted 12pt `Text(problem)`, styled as `PremiumView.swift:229-233`. Add this `ponytail:` note: *"on a tall window PlanPair shows this line too; two of one line beats a silent Restore failure below the fold."*
    - blocked-by: DECIDE-Q1
    - **Done-when:** the line and the note are present above the row. Behaviour is checked at M10 and M13.
  - [ ] **4k3** Back goes in the left column with `.frame(maxWidth: .infinity, alignment: .leading)`. It is a muted text button with `.keyboardShortcut(.leftArrow, modifiers: [])` and `.disabled(page == 0).opacity(page == 0 ? 0 : 1).accessibilityHidden(page == 0)`.
    - **Done-when:** the canvas shows no Back on card 1 and Back on card 2.
  - [ ] **4k4** The dots: five 6pt circles, `t.ink` for the current card and `t.ink.opacity(0.2)` for the rest. Add `.accessibilityElement(children: .ignore).accessibilityLabel("Page \(page + 1) of \(Self.titles.count)")`.
    - **Done-when:** the canvas dots track the page, and the label string is present.
  - [ ] **4k5** A trailing `HStack` with `.frame(maxWidth: .infinity, alignment: .trailing)`:
    - `if selling`: Restore Purchase, copied from `:223-227`: `Button("Restore Purchase") { Task { await premium.restore() } }` with `.buttonStyle(.plain)`, 12pt, `t.muted` and `.disabled(premium.phase == .purchasing)`.
    - Then the Primary.
    - blocked-by: DECIDE-Q1
    - **Done-when:** in the canvas, card 5 (not unlocked) shows Restore beside the Primary, cards 1–4 don't, and the dots stay centred.
  - [ ] **4k6** The Primary: `Button { isLast ? finish() : go(1) }` with `.keyboardShortcut(.defaultAction)` and `.buttonStyle(.plain)`.
    - Label: "Next" on pages 0–3. On the last page, `premium.isUnlocked ? "Get started" : "Continue with Free"`.
    - Drawing: 14pt medium `t.ink` text, padding h20/v11, a `t.surface` fill plus a `t.hairline` stroke at **`t.radius(10)`**. That radius is deliberate; don't use 16, and don't make it an ink pill.
    - [Inference] R10: `.defaultAction` fires on a `.plain` button. M3a settles it.
    - **Done-when:** the canvas labels read correctly per page, and `radius(10)` is on the Primary.
  - [ ] **4k7** The → twin goes in the **row HStack's `.background`, never on Back** (m6): `Button("", action: { go(1) }).keyboardShortcut(.rightArrow, modifiers: []).opacity(0).accessibilityHidden(true).disabled(isLast)`, copied from `SentenceView.swift:103-108`.
    - **Done-when:** `.rightArrow` appears once, inside the row's `.background`. See G11.
  - [ ] **4k8** The nav's ground (m2): `.padding(.horizontal, 40).padding(.vertical, 16).background(t.background)`. It deliberately doesn't use `paneBackground`, because Midnight's band would paint at the top of the nav's own frame.
    - **Done-when:** `grep -c "paneBackground" OneWord/Views/OnboardingView.swift` = 1 (the root only). See G10.
- [ ] **4l** Build `skip(t)`: a muted 13pt `.plain` text button with `.keyboardShortcut(.cancelAction)` that calls `finish()`, plus `.help("Skip the introduction")`. Pad it `.top` 16 and `.trailing` 24; the position is tuned in the running app at M20a, because the canvas has no title bar.
  - **Done-when:** the canvas shows Skip top-right, and `.help("Skip the introduction")` is present.
- [ ] **4m** Add the preview: `OnboardingView(seen: .constant(false)).environment(PremiumViewModel()).frame(width: 1000, height: 680)`. For Midnight or Umber, add `.environment(\.doodle, DoodleTheme(icons: false, handwriting: false, appearance: .midnight))`, or `.umber`.
  - **Done-when:** the canvas renders the preview.
- [ ] **4v** Build and walk the canvas.
  - blocked-by: 4a–4m
  - **Done-when:** **B** is green and all five cards have been walked in the canvas in:
    - [ ] Light
    - [ ] Dark
    - [ ] Midnight
    - [ ] Umber

  The strip reclaim, Skip's position and window dragging can only be checked in the running app, at M20.

### Step 5: the RootView gate (the only switch users see)

- [ ] **5a** Add `@AppStorage("onboardingSeen") private var onboardingSeen = false`, with a one-line doc comment, beside `calloutSeen` (`:76`).
  - files: `OneWord/Views/RootView.swift` (MODIFIED)
  - blocked-by: 4v
  - **Done-when:** the declaration sits next to `calloutSeen`.
- [ ] **5b** Change the gate (`:91-100`) to:
  - `!auth.restored` → the ground, unchanged
  - `else if !onboardingSeen` → `OnboardingView(seen: $onboardingSeen)`
  - `else if auth.isSignedIn` → `shell`
  - `else` → `SignInView()`

  Use a hard cut between states, as SignIn → shell does today; don't add a transition.
  - blocked-by: 5a
  - **Done-when:** the four branches are in this order, `git diff` adds no `.transition` or `.animation` to the gate, and **B** is green.
- [ ] **5c** Update the header comment (`:9-11`) to say a first launch shows the cards before the sign-in gate.
  - **Done-when:** the header mentions onboarding before sign-in.
- [ ] **5d** Leave `.task { auth.restore() }` and `.busy(...)` (`:104,107`) where they are, wrapping the Group.
  - **Done-when:** `git diff OneWord/Views/RootView.swift` leaves those two lines untouched.
- [ ] **5e** Run the build and the gates.
  - blocked-by: 5b–5d
  - **Done-when:** **B** and **6G** are both green, with output kept. Then run the matrix below.
- [ ] **5f** Only if DECIDE-Q4 flips to branch B: add `.onChange(of: auth.restored) { if auth.isSignedIn { onboardingSeen = true } }` to RootView's Group.
  - blocked-by: DECIDE-Q4
  - **Done-when:** either Q4 is accepted as default and nothing is added, or the modifier is present, **B** is green and M14 passes with branch B's expectation.

### Manual matrix (plan §4.7): after Step 5, run from Xcode

Never `open -n` the app and never kill the debug run. All rows are blocked-by 5e. Re-run M0 before any row that needs a fresh install.

- [ ] **M0** Delete the flag with `defaults delete ~/Library/Containers/com.hariom.swift.oneword/Data/Library/Preferences/com.hariom.swift.oneword.plist onboardingSeen`, then press ⌘R. [Unverified] R4: the container path; `ls ~/Library/Containers/com.hariom.swift.oneword/Data/Library/Preferences/` settles it. Use the scheme argument `-onboardingSeen NO` **only to look at the cards**, because it pins the value for the whole run and Skip or finish then do nothing visible (R4).
  - **Done-when:** `ls` has confirmed the path (record it), and `defaults read <that plist> onboardingSeen` reports the key doesn't exist.
- [ ] **M1** Fresh install (key deleted).
  - **Done-when:** the app shows the ground, then card 1, not SignInView.
- [ ] **M2a** Skip on card 1.
  - **Done-when:** the app lands on SignInView (or the shell with a session), and relaunching goes straight past onboarding.
- [ ] **M2b** Esc on card 3 (re-run M0 first).
  - **Done-when:** the same as M2a.
- [ ] **M3a** Keyboard only: → and Return advance.
  - **Done-when:** both keys advance a card. If Return does nothing, that settles R10 against the plan, so apply ⏸ D4.
- [ ] **M3b** ← goes back.
  - **Done-when:** ← goes back a card and does nothing on card 1.
- [ ] **M3c** Card 5 keys.
  - **Done-when:** → on card 5 does nothing, and Return on card 5 finishes.
- [ ] **M3d** Esc skips.
  - **Done-when:** Esc on any card finishes onboarding.
- [ ] **M4** Hold → from card 1 (M3).
  - **Done-when:** it steps through the cards and stops on card 5, with no crash.
- [ ] **M5** Press Return twice quickly on card 4 (M3).
  - **Done-when:** it lands on card 5, then either nothing happens or it finishes. Never a crash or an out-of-range card.
- [ ] **M6** Next, then Back, by mouse (M1/M2).
  - **Done-when:** there's a crossfade both ways, the incoming card is never pushed down by the outgoing one, and the nav, dots and Skip don't fade or move. If the new card starts lower and jumps up, apply ⏸ D2 (R5).
- [ ] **M7** Scroll card 5 down, then press Back, then Next (M1).
  - **Done-when:** card 5 reopens at the top of its scroll.
- [ ] **M8** Buy on card 5 with the StoreKit config.
  - **Done-when:** a spinner shows, then the card swaps to the thanks. The primary reads "Get started", the nav's Restore disappears, and the widget reloads (`OneWordApp.swift:47`).
- [ ] **M9a** Press Esc while the purchase sheet is up (G3).
  - **Done-when:** Esc cancels the sheet and UnlockButton returns to the price. [Unverified] Whether the sheet owns the keys; record what actually happens. Both outcomes are safe.
- [ ] **M9b** Press Back mid-flight, by mouse or during a restore.
  - **Done-when:** nothing crashes, and coming back to card 5 shows the spinner or the thanks.
- [ ] **M9c** Skip mid-flight.
  - **Done-when:** nothing crashes, and the purchase still lands.
- [ ] **M10** Restore from the nav on card 5 (Q1).
  - **Done-when:** Restore is visible without scrolling at 1000×680, the link disables and UnlockButton spins while it runs, success swaps to the thanks, and failure shows `problem` above the nav row.
- [ ] **M11** Restore inside PlanPair.
  - **Done-when:** it works and behaves the same as on PremiumView.
- [ ] **M12** Already owned (restart after buying, key deleted).
  - **Done-when:** card 5 opens on the thanks, with no plan cards and no nav Restore.
- [ ] **M13** Store unreachable.
  - **Done-when:** the price reads "Lifetime" and UnlockButton reads "Try Again". "The App Store isn't reachable…" shows in the card **and** above the nav. Continue with Free still finishes.
- [ ] **M14** Existing signed-in user upgrading (key absent, session present).
  - blocked-by: DECIDE-Q4
  - **Done-when:** under the Q4 default they see the cards once, then the shell (F2). Under branch B they go to the shell instead, and card 1 may paint for a frame (m9 [Inference]).
- [ ] **M15** Appearances. In every one, only tokens are used and the covers are the only colour.
  - [ ] **M15a** Light. **Done-when:** as above.
  - [ ] **M15b** Dark. **Done-when:** as above.
  - [ ] **M15c** Midnight. **Done-when:** the band shows behind the cards, and the nav's ground meets it with no seam (m2).
  - [ ] **M15d** Umber. **Done-when:** as above.
- [ ] **M16** Turn on the handwriting and doodle switches.
  - **Done-when:** the display face switches, and the tiles keep SF Symbols, as on PremiumView.
- [ ] **M17** Turn on Reduce Motion.
  - **Done-when:** it's the same crossfade, opacity only, and nothing moves.
- [ ] **M18** Card 5 at 1000×680.
  - **Done-when:**
    - the plan cards sit side by side and the body scrolls
    - the nav (Continue with Free, Restore) stays pinned and opaque, with nothing showing through (m2)
    - you've recorded whether UnlockButton needs a scroll. This settles R3 [Inference], and if it's a problem it means DECIDE-Q1 (a)/(b).
- [ ] **M19** Card 4 at 1000×680 (m3).
  - **Done-when:** it fits, or it scrolls with the nav pinned, and each tile row keeps one height.
- [ ] **M20** The top strip on cards 1 and 5 (A1, R9 [Inference]).
  - [ ] **M20a** **Done-when:** Skip sits top-right, clear of the edge. Tune 4l's padding here.
  - [ ] **M20b** **Done-when:** dragging the window from the top strip moves it on macOS 14.
  - [ ] **M20c** **Done-when:** dragging the window from the top strip moves it on current macOS.
  - If either drag fails, go to DECIDE-Q1(d) and ⏸ D3.
- [ ] **M21** Narrow window, about 760 wide.
  - **Done-when:** the cards squeeze but stay side by side (known limit), and on card 5 the nav row still fits Back · dots · Restore + Primary.
- [ ] **M22** VoiceOver.
  - **Done-when:**
    - the dots read "Page n of 5"
    - the card title is announced on each page change
    - the widget mock and the fan are skipped
    - the word preview reads as one element
    - focus stays on the Primary across pages

### Step 6: keep the live docs current

These can run alongside the matrix.

- [ ] **6a** In the layout block of `ARCHITECTURE.md` (`:152-154`), add `OnboardingView`, and change `PremiumView (+ PlanTag)` to `PremiumView (+ PlanTag, PlanPair, CoverFan, FeatureTile)`.
  - files: `Docs/00_Context/ARCHITECTURE.md` (MODIFIED)
  - blocked-by: 5b
  - **Done-when:** grep finds both strings.
- [ ] **6b** In "Where it's sold" (`ARCHITECTURE.md:133-137`), add "and the last onboarding card, through `PlanPair`".
  - **Done-when:** grep finds "last onboarding card".
- [ ] **6c** Change the gate loop at `CLAUDE.md:54` to `for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done`.
  - files: `CLAUDE.md` (MODIFIED, one line)
  - blocked-by: DECIDE-Q5
  - **Done-when:** `grep -n "check_capture check_sentences check_premium" CLAUDE.md` returns one hit, and it matches `REPO_MAP.md:52`.
- [ ] **6d** Leave the point-in-time docs alone. Nothing under `Docs/01`–`06` is modified. The Dossiers line in `Docs/README.md` was already added when the plan was saved (README rule); the only further README touch allowed is flipping that dossier's status from "planned, not built" to shipped once this lands.
  - **Done-when:** `git diff --stat main -- Docs/01_Brainstorm Docs/02_Plan Docs/03_Checklist Docs/04_PR Docs/05_Thoughts Docs/06_Misc` shows no modified tracked file, and `git diff main -- Docs/README.md` touches only the Onboarding dossier entry. New dossier files, including this one, aren't counted.

## iOS rigor gates (pre-merge)

- [ ] **G1 Isolation.** OnboardingView, PlanPair, CoverFan, FeatureTile and the `fileprivate` file-scope functions all stay MainActor by default isolation, with no annotation added. `CoverFan.covers` stays a MainActor static.
  - **Done-when:** `git diff main -- OneWord/Views | grep -E '^\+.*(nonisolated|@MainActor|\bactor\b)'` → empty.
- [ ] **G2 Sendable boundary.** PlanPair's `Task.detached(priority: .utility)` is moved verbatim. It captures only `ids: [String]`, returns `[String: Int]` and calls the `nonisolated` `WordProvider` (`WordProvider.swift:14`). It compiles in Swift 5 mode as it does today.
  - **Done-when:** nothing inside the detached closure names `counts`, `premium` or `self`, and **B** is green.
- [ ] **G3 One counts task at a time (m7).** PremiumView's task runs on `owned(t)` only, and PlanPair has its own.
  - **Done-when:** there are exactly two `.task` blocks in `PremiumView.swift`, one on `owned(t)` and one on PlanPair's body.
- [ ] **G4 No new retain cycles or orphaned work.** Button closures capture value-type views. The only new `Task` is the nav Restore, which holds the app-lifetime `PremiumViewModel` until the call returns. There is no `shuffle`.
  - **Done-when:** `grep -c "Task {" OneWord/Views/OnboardingView.swift` = 1, `grep -n "shuffle\|Task.detached" OneWord/Views/OnboardingView.swift` → empty, and M9a–c pass.
- [ ] **G5 `Shared/` untouched.**
  - **Done-when:** `git diff --stat main -- OneWord/Shared` → empty.
- [ ] **G6 Target membership through the synchronized group.**
  - **Done-when:** `git diff --stat main -- OneWord.xcodeproj tools` → empty (no pbxproj edit, no gate-script edit, scheme environment and arguments not committed), and **B** is green with RootView naming `OnboardingView`.
- [ ] **G7 `import Accessibility`** is present, with the plan's comment.
  - **Done-when:** `grep -n "^import Accessibility" OneWord/Views/OnboardingView.swift` returns one hit.
- [ ] **G8 Bounds guard (M3).** `go(_:)` guards `Self.titles.indices.contains(next)` before it writes `page`.
  - **Done-when:** the code matches 4j, and M4 and M5 pass.
- [ ] **G9 Modifier order (M1).** `.transition(.opacity)` and `.id(page)` sit on the **ScrollView inside** the GeometryReader. `.safeAreaInset(edge: .bottom, spacing: 0) { nav }` **wraps the reader**. Then come `.ignoresSafeArea(.container, edges: .top)`, the Skip overlay, `.animation(…, value: page)` and `.paneBackground(t)`.
  - **Done-when:** the body matches 4i line for line, and M6 and M7 pass.
- [ ] **G10 Nav ground (m2).** The nav uses `.background(t.background)`, never `paneBackground`.
  - **Done-when:** `grep -c paneBackground OneWord/Views/OnboardingView.swift` = 1, and M15c and M18 show no seam and nothing showing through.
- [ ] **G11 → twin placement (m6).** The twin is on the row HStack's `.background`, never on Back.
  - **Done-when:** the code matches 4k7, and M3a and M3c pass.
- [ ] **G12 `isLast` read once at render (M3).** The Primary's action uses the `let isLast` from `nav(t)`.
  - **Done-when:** the code matches 4k1 and 4k6, and M5 passes.
- [ ] **G13 Accessibility.** Dynamic Type needs nothing, because the app uses fixed sizes by design (`DoodleTheme.swift:128-131`).
  - [ ] **G13a** Every button has a visible text label except the hidden twin, and Skip has `.help`. **Done-when:** a code read confirms it.
  - [ ] **G13b** The dots are one element reading "Page n of 5". **Done-when:** M22.
  - [ ] **G13c** The widget mock is `.accessibilityHidden(true)`, and CoverFan is already hidden (1a). **Done-when:** M22 skips both.
  - [ ] **G13d** The word preview is `.accessibilityElement(children: .combine)`, and FeatureTile keeps its `.combine`. **Done-when:** M22.
  - [ ] **G13e** The announcement is in `go(_:)`, the twin is hidden, and Back is hidden on card 1. **Done-when:** in M22, VoiceOver never lands on the twin or on card 1's Back.
- [ ] **G14 Premium only through the view model.** OnboardingView reads `premium.isUnlocked`, `premium.phase` and `premium.problem`, never `Premium.isUnlocked`. UnlockButton appears only inside PlanPair.
  - **Done-when:** `grep -n "Premium.isUnlocked\|import StoreKit\|UnlockButton" OneWord/Views/OnboardingView.swift` → empty.
- [ ] **G15 Defaults ownership and migration.** There is one key, in standard defaults, owned by RootView. OnboardingView never names UserDefaults. An absent key means false, so no migration is needed.
  - **Done-when:** `grep -rn '"onboardingSeen"' OneWord` → one hit (RootView.swift), `grep -n "AppStorage\|UserDefaults" OneWord/Views/OnboardingView.swift` → empty, and M1 passes.
- [ ] **G16 Availability.** No `#available` is needed; `AccessibilityNotification` is macOS 14.0+.
  - **Done-when:** `grep -n "#available" OneWord/Views/OnboardingView.swift` → empty, **B** is green at deployment target 14.0, and M20b ran on macOS 14.
- [ ] **G17 Scope fence** (§4.2 "Not doing"; §4.8: no Info.plist, entitlements, assets or `.xcstrings`).
  - **Done-when:**
    - `git diff --stat main` lists only the five files in §4.11 (plus new dossier docs)
    - `grep -nE "accessibilityReduceMotion|\.move\(edge|showRestore" OneWord/Views/OnboardingView.swift OneWord/Views/PremiumView.swift` → empty
    - there's no new file under `OneWord/ViewModels/` or `tools/`

## ⏸ Deferred / evidence-gated (not now)

Per §6 the plan defers nothing. These are its evidence-gated exits (§4.10) and named follow-ups. Build one only if its gate fires.

- ⏸ **D1 (R2)** Rename the file-scope `card`/`label` to `planCard`/`planLabel`. *Gate:* 2a hits a shadowing or ambiguity compile error at a call site.
- ⏸ **D2 (R5)** Wrap `current(t)` in `ZStack(alignment: .top)` and move the id there, as `WordDetail.swift:59-62` does. *Gate:* in M6 the new card starts lower and jumps up.
- ⏸ **D3 (R9, A1)** Delete the one `.ignoresSafeArea(.container, edges: .top)` line. That costs about 28pt, and the nav Restore still keeps the requirement met. *Gate:* M20b or M20c fails, **and** DECIDE-Q1 flips to (d).
- ⏸ **D4 (R10)** Give Return a hidden twin too (`SentenceView.swift:103-108`). *Gate:* in M3a, Return does nothing.
- ⏸ **D5 (R8)** Change only the card 2 copy. *Gate:* the widget-gallery or context-menu wording on a test Mac differs from F3.2 [Unverified].
- ⏸ **D6 (m10)** Add one `@AppStorage("showHindi", store: AppGroup.defaults)` read that hides card 1's Hindi line. *Gate:* the plan names this exit but no trigger. It only matters under the Q4 default, for an existing reader with `showHindi` off.
- ⏸ **D7** [Assumption] The widget mock sits on `t.surface`. To match the real widget, which paints plain white or black by scheme (`WordWidgetView.swift:67`), use `Theme.of(scheme).background` with a hairline. *Gate:* the operator wants the mock to match the real widget.
- ⏸ **D8** [Assumption] Drop CoverFan's `height` parameter. *Gate:* no card ever changes it from 100.
- ⏸ **D9 (F5)** Add a Hindi on/off Toggle on card 1, bound to `@AppStorage("showHindi", store: AppGroup.defaults)`, as a follow-up. *Gate:* research says the Hindi gloss puts off non-Hindi readers.
- ⏸ **D10** The Dossiers line in `Docs/README.md` — already added when the plan was saved (README rule). Nothing to do here; 6d covers the status flip when the feature ships.
- The alternative branches of Q1 (a–d), Q3 (the slide) and Q4 (branch B) live in the DECIDE items above and aren't repeated here.

## Definition of done

Checking every box here means the change is shippable per the plan.

- [ ] **DoD-1** Items S1–S2, 1a–1f, 2a–2f, 3a–3h, 4a–4v, 5a–5e and 6a–6d are all checked, plus 5f if Q4 flipped.
- [ ] **DoD-2** DECIDE-Q1 through Q5 are each accepted or overridden, and every override is built and re-verified. Q1(d) has been re-decided after M20.
- [ ] **DoD-3** M0–M22 all pass. A row that failed had its ⏸ exit applied and was re-run.
- [ ] **DoD-4** G1–G17 are all checked.
- [ ] **DoD-5** The plan's §4.2 criteria hold:
  - [ ] a fresh install (flag absent) opens on OnboardingView after `auth.restored` (M1)
  - [ ] Skip, Esc or the last card's primary sets `onboardingSeen = true` and lands on SignInView, or the shell with a session (M2a, M2b, M3c, M3d)
  - [ ] PremiumView looks and behaves exactly as before (1f, 2f, 3h)
- [ ] **DoD-6** The end-to-end check (§4.11) passes:
  1. **B** is green, then **6G** is green.
  2. Delete the key (M0) and launch from Xcode.
  3. Walk ground → card 1 → the keyboard through all five cards → Restore from the nav → buy (StoreKit config) → "Get started" → SignInView or the shell.
  4. Relaunch, and onboarding doesn't appear.
- [ ] **DoD-7** The S1 environment variable `ONEWORD_PANE=premium` and any `-onboardingSeen NO` argument are removed and not committed.
  - **Done-when:** `git status -- OneWord.xcodeproj` is clean.
- [ ] **DoD-8** All four audit Majors are built as written: M1 (G9), M2 (the Q3 crossfade), M3 (G8, G12) and M4 (the Q1 nav Restore and M10). The audit had no blockers.
- [ ] **DoD-9** Each carried soft spot has its outcome written down: R3 (M18), R4 (the M0 path), R8 (D5), R9 (M20), R10 (M3a) and row 9 (M9a).
- [ ] **DoD-10** Both commands are green on the final commit, with output reported and no red gate glossed over:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done
```
