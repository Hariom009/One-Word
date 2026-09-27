# Onboarding: implementation plan

> Produced 2026-09-27 by `/plan --report` from the operator's request and the code on `main` at `675065b`. No upstream brainstorm or strategy doc exists for this feature.

**The change.** On a fresh install the app opens on five full-window education cards sized for the Mac window, instead of going straight to the sign-in screen. The cards cover welcome, the widget, the dictionaries, your words, and Free vs Premium. They show once and can be skipped on every card. Finishing or skipping goes to wherever the app goes today (SignInView, then the shell).

**Upstream.** There is no `/brainstorm` or `/strategize` doc. This plan comes from the operator's request, the brief (`plan-onboarding-brief.md`) and the code. That is weaker than planning from a committed strategy, so §9 marks which calls belong to the operator.

**Read for this plan** (on `main` at `675065b`, re-grounded from disk):
`OneWord/Views/RootView.swift:1-350` · `OneWord/OneWordApp.swift:1-54` · `OneWord/Views/SignInView.swift:1-119` · `OneWord/Views/PremiumView.swift:1-442` · `OneWord/Views/PremiumBar.swift:1-129` · `OneWord/ViewModels/PremiumViewModel.swift:1-131` · `OneWord/ViewModels/AuthViewModel.swift:1-200` · `OneWord/ViewModels/WordViewModel.swift:1-88` · `OneWord/Views/HomeView.swift:1-73` · `OneWord/Shared/{Theme,Word,Premium}.swift` (full) · `OneWord/Shared/WordProvider.swift:1-80` · `OneWord/Models/{DoodleTheme,Appearance,Wordbook}.swift` (full) · `OneWord/Views/PaneHeader.swift:1-154` · `OneWord/Views/HistoryView.swift:1-70` · `OneWord/Views/SentenceView.swift:45-120,185-215` · `OneWord/Views/FeedbackView.swift:50-130` · `OneWord/Views/DictionaryPicker.swift:26-51,328-348` · `OneWord/Views/{SettingsView,ProfileView,LearnedListView}.swift` (headers) · `OneWord/Models/LearnedWords.swift:1-30` · `OneWord/WordCapture.swift:1-140` · `OneWordWidget/WordWidget.swift` (grep) · `OneWordWidget/WordWidgetView.swift:1-120` · `OneWord/OneWord.entitlements` · `OneWord.xcodeproj/project.pbxproj:85-106,271-273,458,516,540-597` · `OneWord.xcodeproj/xcshareddata/xcschemes/OneWord.xcscheme` (LaunchAction) · `tools/check_*.sh` (compile lines) · `CLAUDE.md` · `Docs/README.md` · `Docs/00_Context/{ARCHITECTURE,REPO_MAP,DESIGN_BRIEF,PROJECT_CONTEXT}.md` · `Docs/02_Plan/PREMIUM_PLAN.md:1-40` · `Docs/02_Plan/Resolved/PREMIUM_PLAN_RESOLVED.md:500-512` · `Docs/06_Misc/MARKET_FIT_RESEARCH_BRIEF.md:255-285`.

### Detected stack (confirmed against the brief)

| | Detected | Evidence |
|---|---|---|
| Build | One `.xcodeproj` with two targets, app `OneWord` and widget `OneWordWidget`. `OneWord/` is an Xcode 16 file-system-synchronized root group, so new files join the target automatically. `Shared/` is also referenced by explicit path for the widget. | `project.pbxproj:97-106` (sync group), `:62-84` (`Shared/` explicit refs) |
| Dependencies | SPM: firebase-ios-sdk, GoogleSignIn-iOS (auth only) | `project.pbxproj:271-273` |
| Platform | macOS 14.0 | `project.pbxproj:458,516` |
| UI | SwiftUI, one `WindowGroup`, `.hiddenTitleBar`, no toolbar. Each pane draws `PaneHeader`; SignInView draws none. | `OneWordApp.swift:35-52`, `RootView.swift:186-190`, `SignInView.swift:25-74` |
| Architecture | MVVM. `@Observable` view models import `Observation` only, and views own them with `@State`. Exemplar: `WordViewModel` held as `@State private var model = WordViewModel()`. | `WordViewModel.swift:12-16`, `HomeView.swift:17` |
| Concurrency | Swift 5 mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` | `project.pbxproj:553-557` (app, Debug), `:590-594` (Release) |
| State / DI | `AuthViewModel`, `PremiumViewModel` and `\.doodle` are injected at the app root. `@AppStorage` in standard defaults for app-only flags. | `OneWordApp.swift:26-47`, `RootView.swift:69,76` |
| Persistence | UserDefaults, the App Group and bundled JSON. Nothing else. | `Premium.swift:28`, `WordProvider.swift:72-80` |
| Testing | No test target. Verification is `xcodebuild` plus the `tools/check_*.sh` gates (`swiftc` over named `Shared/` and `Models/` files) plus manual runs with `StoreKit/OneWord.storekit`. | `tools/check_learned.sh:191-196`, scheme `StoreKitConfigurationFileReference` |
| Localization | `SWIFT_EMIT_LOC_STRINGS = YES` and `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`, but no `.xcstrings` exists in the repo | `project.pbxproj:457,555`; `find -name '*.xcstrings'` finds nothing |

---

## 2. Scope and outcome

**Done when:** a fresh install (flag absent) opens on OnboardingView after `auth.restored`. Skip (or Esc) on any card, or the last card's primary button, sets `onboardingSeen = true`, and the window lands on SignInView (or the shell if a session exists). PremiumView looks and behaves the same as before. `xcodebuild … build` is green and all six gates are green.

**Scope shape:** a single change (one PR). Three behaviour-preserving extractions inside `PremiumView.swift`, one new view, and one gate edit. Everything lands and reverts together.

**In scope:** `CoverFan`, `FeatureTile` and `PlanPair` extracted from PremiumView. `OnboardingView.swift` with five cards. The RootView gate plus one `@AppStorage` key. Keeping `ARCHITECTURE.md` current.

**Not doing:** an appearance picker in onboarding; a Hindi on/off choice in onboarding (follow-up fork F5); detecting whether a widget is installed (no API exists); a "show welcome again" button in Settings; a new `tools/check_*.sh` gate; a new view model; a stacked layout for very narrow windows (same limit as PremiumView, `PremiumView.swift:46-47`).

---

## 3. Architecture fit

Everything goes in the app target under `OneWord/Views/`. `Shared/` is untouched, and no gate compiles any file this change touches (checked: the `check_*.sh` compile lines name only `Shared/`, `Models/` and `WordViewModel.swift`).

| Type | File | New / changed | Responsibility | Mirrors |
|---|---|---|---|---|
| `CoverFan` | `Views/PremiumView.swift` | NEW internal struct | The fanned covers for any `[Wordbook]`, plus the static high-quality cover cache | old `PremiumView.fan` + `covers` + `cover(_:height:scale:)` (`:103-148`); lives beside `PlanTag` (`:411-436`) |
| `FeatureTile` | `Views/PremiumView.swift` | NEW internal struct | Symbol in an accent disc, display-face title, one line | old `PremiumView.tile` (`:299-322`) |
| `PlanPair` | `Views/PremiumView.swift` | NEW internal struct | The Free + Premium cards side by side, with price, UnlockButton, Restore, `problem`, and its own counts `.task` | old `free`/`lifetime`/`price`/`action`/`footer`/`heading`/`perk`/`rule` (`:150-236,324-371`) and the task (`:63-68`) |
| `card`, `label`, `bookRow(_:count:_:)` | `Views/PremiumView.swift` | Moved to file scope, `fileprivate` | Stateless pieces shared by PremiumView's owned view, PlanPair and FeatureTile | same bodies (`:342-349,373-408`); other views keep their own private copies (`SettingsView.swift:274`, `ProfileView.swift:433`), which is the repo's norm |
| `PremiumView` | same file | MODIFIED | Hero + (owned or `PlanPair()`) | itself |
| `OnboardingView` | `Views/OnboardingView.swift` | NEW | Full-window cards, page state, nav, finish | `SignInView.swift:25-74` (front door); page chrome from `PremiumView.swift:38-61` |
| `RootView` | `Views/RootView.swift` | MODIFIED | Adds the `onboardingSeen` key and gate branch | `calloutSeen` at `RootView.swift:76` |

Why the pieces go to file scope: PremiumView's owned view (`:244-297`) and the plan cards both call `card`, `label` and `bookRow`. `bookRow` reads `counts`, which will now live separately in each struct. Moving the stateless pieces to `fileprivate` file-scope functions leaves every `card(t) {…}` / `label("…", t)` call site unchanged. Only `bookRow` gains a `count:` parameter.

No MVVM fallback is needed. The content is static, and the one live value (today's word) comes from the existing `WordViewModel` (brief e3).

---

## 4. Implementation steps

Every type is MainActor by default isolation (`project.pbxproj:554`), and nothing below changes that.

### Step 1: extract `CoverFan` (no visible change)
- **File:** MODIFIED `OneWord/Views/PremiumView.swift` (app).
- **Do:**
  - Add `struct CoverFan: View { let books: [Wordbook]; var height: CGFloat = 100; @Environment(\.displayScale) private var displayScale }`. Its body is the old `fan` (`:105-118`) with `Self.books` → `books` and `100` → `height`. Keep `.padding(.top, 6)` and `.accessibilityHidden(true)` inside it.
  - Move `private static var covers` and `private static func cover(_:height:scale:)` (`:121-148`, comments included) into CoverFan unchanged.
  - In PremiumView, `hero` (`:75`) calls `CoverFan(books: Self.books)`. Delete `fan`, `covers`, `cover`, and the `displayScale` environment property (`:24-25`), which nothing else reads.
- **Isolation:** `covers` stays a MainActor-isolated static, exactly as it is today on PremiumView.
- **Note:** the spacing −20, rotation 5° and offset ×1.8 were tuned at height 100. Onboarding also uses 100, so no scaling code is needed. Add a `ponytail:` note: "tuned at 100pt; scale spacing/offset if a caller changes height".
- **Verify:** build. The Premium pane fan looks identical (launch with `ONEWORD_PANE=premium` set in the scheme's environment, not committed; `RootView.swift:24-30`).

### Step 2: lift the shared pieces and add `FeatureTile` (no visible change)
- **File:** MODIFIED `PremiumView.swift`.
- **Do:**
  - Move `card(_:emphasized:padding:_:)` (`:396-408`) and `label(_:_:)` (`:343-349`) out of the struct to file scope as `fileprivate func`, with bodies unchanged.
  - Move `bookRow` (`:374-391`) to file scope as `fileprivate func bookRow(_ book: Wordbook, count: Int?, _ t: Theme) -> some View`. Replace `counts[book.id]` with `count`. Update its three callers: `:166` `bookRow(.everydayEnglish, count: counts[Wordbook.everydayEnglish.id], t)`, `:189` and `:290` `bookRow($0, count: counts[$0.id], t)`.
  - Add `struct FeatureTile: View { let symbol: String; let title: String; let text: String }` reading `scheme` and `doodle` from the environment. The body starts `let t = Theme.of(scheme, doodle)` and is the old `tile` body (`:301-321`, including `.accessibilityElement(children: .combine)`).
  - In `owned` (`:250-270`), change the six `tile(a, b, c, t)` calls to `FeatureTile(symbol: a, title: b, text: c)` and delete `tile`.
- **Verify:** build. With Premium owned (buy in the StoreKit config), the owned view's tiles, shelf and counts look identical.

### Step 3: extract `PlanPair` (no visible change)
- **File:** MODIFIED `PremiumView.swift`.
- **Do:**
  - Change PremiumView's `private static let books/shelf` (`:28,30`) to `fileprivate static`, so PlanPair can read `PremiumView.books` and `PremiumView.shelf` without copying the filters.
  - Add `struct PlanPair: View` with the `premium`, `scheme` and `doodle` environment values and `@State private var counts: [String: Int] = [:]`.
    - Body: `let t = Theme.of(scheme, doodle)`, then `HStack(alignment: .top, spacing: 24) { free(t); lifetime(t) }.fixedSize(horizontal: false, vertical: true)`. The `fixedSize` moves in from `:49`, and the ponytail comment from `:46-47` moves with it.
    - Then `.task { … }`, copied verbatim from `:63-68` with `Self.shelf` → `PremiumView.shelf`.
  - Move `free`, `lifetime`, `price`, `action`, `footer`, `heading`, `perk` and `rule` (`:150-236,324-340,351-371`) into PlanPair as `private`, with `Self.books` → `PremiumView.books`.
  - In PremiumView's body, `:48-49` becomes `PlanPair()`. Move PremiumView's own `.task` (`:63-68`) from the root onto the `owned(t)` branch (`owned(t).task { … }`). That way the two counts tasks never run together. Otherwise both detached tasks would miss `WordProvider`'s cache (`WordProvider.swift:72-77`) on a first visit and decode all eight books twice.
  - Update the file header comment (`:5-13`): PlanPair and CoverFan are reused by the onboarding cards.
- **Isolation:** unchanged. The detached closure captures `ids: [String]` and returns `[String: Int]`, both Sendable, and calls `WordProvider`, which is `nonisolated` (`WordProvider.swift:14`).
- **Verify:** build. The Premium pane (not owned) looks identical. Counts appear in both cards. Buy with the StoreKit config: the pane swaps to the owned view and counts appear immediately (cache hit). Restore and "Try Again" still work.

### Step 4: `OnboardingView` (not reachable yet; verify in the canvas)
- **File:** NEW `OneWord/Views/OnboardingView.swift` (app). It joins the target through the synchronized group with no pbxproj edit (`project.pbxproj:97-106`).
- **Imports:** `SwiftUI`. Add `import Accessibility` only if MEMBER_IMPORT_VISIBILITY rejects `.post()` (see R6).
- **Shape (signatures only):**
  ```swift
  struct OnboardingView: View {
      @Binding var seen: Bool                         // RootView owns the key
      @State private var page = 0
      @State private var forward = true               // slide direction
      @State private var model = WordViewModel()      // today's word, as HomeView.swift:17
      @Environment(PremiumViewModel.self) private var premium
      @Environment(\.colorScheme) private var scheme
      @Environment(\.doodle) private var doodle
      @Environment(\.accessibilityReduceMotion) private var reduceMotion
      /// One per card: the count, the dots, and what VoiceOver announces.
      private static let titles = ["Welcome", "The widget", "Dictionaries", "Your words", "Plans"]
      private static let shelf = Wordbook.all.filter { $0.id != SavedWords.resource }  // as DictionaryPicker.swift:47

      var body: some View
      @ViewBuilder private func current(_ t: Theme) -> some View   // switch page { 0…3; default: plans }
      private func welcome(_ t: Theme) -> some View
      private func widget(_ t: Theme) -> some View
      private func dictionaries(_ t: Theme) -> some View
      private func yourWords(_ t: Theme) -> some View
      private func plans(_ t: Theme) -> some View
      private func intro(_ eyebrow: String, _ title: String, _ text: String, _ t: Theme) -> some View
      private func entry(_ word: Word, size: CGFloat, _ t: Theme) -> some View  // term / POS / hindi? / definition
      private func nav(_ t: Theme) -> some View
      private func go(_ step: Int)      // forward = step > 0; page += step; announce Self.titles[page]
      private func finish()             // seen = true
  }
  ```
- **Body layout.** Mirror PremiumView `:38-61` and SignInView `:71-73`:
  - `GeometryReader { ScrollView { current(t).frame(maxWidth: 920).padding(.horizontal, 40).padding(.vertical, 24).frame(maxWidth: .infinity, minHeight: geo.size.height) }.scrollContentBackground(.hidden) }`.
  - Then `.id(page)` and `.transition(...)` on the scrolled body.
  - `.safeAreaInset(edge: .bottom, spacing: 0) { nav(t) }` (as `RootView.swift:163`), which keeps the free exit visible without scrolling.
  - `.overlay(alignment: .topTrailing) { Skip }` (as `SentenceView.swift:79`).
  - `.animation(.easeInOut(duration: 0.22), value: page)` (as `RootView.swift:125`), then `.paneBackground(t)`.
  - Transition: `reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: forward ? .trailing : .leading), removal: .move(edge: forward ? .leading : .trailing)).combined(with: .opacity)`.
- **Controls.** SwiftUI allows one key per button, so Next cannot take both Return and →. The fix is already in the code: a hidden twin button (`SentenceView.swift:97-109`).
  - **Skip:** muted 13pt `.plain` text button, `.keyboardShortcut(.cancelAction)` (Esc, as `FeedbackView.swift:58`) → `finish()`.
  - **Back:** muted text button, `.keyboardShortcut(.leftArrow, modifiers: [])` (as `HistoryView.swift:50`). On page 0 it gets `.disabled(page == 0).opacity(page == 0 ? 0 : 1).accessibilityHidden(page == 0)`; a disabled button's shortcut does not fire.
  - **Dots:** five 6pt circles, `t.ink` for the current card and `t.ink.opacity(0.2)` for the rest, with `.accessibilityElement(children: .ignore).accessibilityLabel("Page \(page + 1) of \(Self.titles.count)")`.
  - **Primary:** `.keyboardShortcut(.defaultAction)` (Return, as `FeedbackView.swift:126`). It reads "Next" on pages 0-3. On the last page it reads `premium.isUnlocked ? "Get started" : "Continue with Free"` and calls `finish()`. It is drawn as surface + hairline at `t.radius(10)` (as `SignInView.swift:103-108`), not an ink pill: `PremiumBar.swift:102-103` makes UnlockButton "the one filled control in the app", and on page 5 the two sit side by side.
  - **→ key:** `.background { Button("", action: { go(1) }).keyboardShortcut(.rightArrow, modifiers: []).opacity(0).accessibilityHidden(true).disabled(page == Self.titles.count - 1) }`, copied from `SentenceView.swift:104-109`. On the last card → does nothing; Return finishes.
- **Cards.** Draft copy is in F3 and belongs to the operator. Each card uses `intro(...)`, styled like PremiumView's hero: 11pt bold uppercase eyebrow with tracking 2.5, a `doodle.face(34-44)` title with `doodle.tracking`, and 15pt muted body with `lineSpacing(3)` (`PremiumView.swift:77-98`).
  1. **welcome:** `HStack(spacing: 48) { entry(model.word, size: 40, t) in a t.surface/t.hairline card at t.radius(18); intro(...) }`. The entry card gets `.accessibilityElement(children: .combine)`. Hide the Hindi line when `hindi.isEmpty` (DESIGN_BRIEF §8). Draw it by hand. Do not use `WordDetail`, which records the word as learned (`LearnedWords.swift:7-9`) and carries actions.
  2. **widget:** a mock of the medium widget, about 360×170 (DESIGN_BRIEF §6D): the entry lines at a smaller size plus an `arrow.clockwise` glyph top-right, on `t.surface` + `t.hairline`, `.accessibilityHidden(true)`. Beside it, numbered steps. The facts come from `WordWidget.swift:55-63` (kind `WordWidget`, "Word of the Day", small/medium/large), `WordWidgetView.swift:83` (refresh button) and `SelectDictionaryIntent` (own dictionary).
  3. **dictionaries:** `CoverFan(books: Self.shelf)` beside `intro`. The premium names come from `Self.shelf.filter { !Premium.free.contains($0.id) }.map(\.shortName).formatted(.list(type: .and))`, so the copy cannot drift from `Wordbook.all`.
  4. **yourWords:** two rows of three `FeatureTile`s with `.fixedSize(horizontal: false, vertical: true)`, laid out as in `PremiumView.swift:248-272`. Tiles: Search (⌘K, `RootView.swift:227,241`), Bookmarks, History, Learned/Profile, Save from any app (Services, `WordCapture.swift:5-9`), Make it yours (Settings, reached from Profile, `RootView.swift:247-248`).
  5. **plans:** if `premium.isUnlocked`, show an eyebrow "Premium · Unlocked" and "Every dictionary is yours." plus a one-line thanks (copy as `PremiumView.swift:77-89`). Otherwise show a one-line eyebrow and `PlanPair()`.
- **`go(_:)`** sets `forward` before `page` changes, then posts `AccessibilityNotification.Announcement(Self.titles[page]).post()`. VoiceOver focus stays on the persistent Next button, so without the announcement a page change is silent.
- **Preview:** `OnboardingView(seen: .constant(false)).environment(PremiumViewModel()).frame(width: 1000, height: 680)` (as `SignInView.swift:115-119`).
- **Verify:** build. In the canvas, walk all five cards in Light, Dark, Midnight and Umber (`\.doodle` override in the preview if needed).

### Step 5: the gate (the only user-visible switch)
- **File:** MODIFIED `OneWord/Views/RootView.swift`.
- **Do:**
  - Add `@AppStorage("onboardingSeen") private var onboardingSeen = false` beside `calloutSeen` (`:76`), with a one-line doc comment.
  - Change the gate (`:91-100`) to: `!auth.restored` → ground (unchanged); `else if !onboardingSeen` → `OnboardingView(seen: $onboardingSeen)`; `else if auth.isSignedIn` → `shell`; `else` → `SignInView()`.
  - Update the header comment (`:9-11`).
  - `.task { auth.restore() }` and `.busy` (`:104,107`) stay where they are.
- **Why a binding and not a second `@AppStorage`:** one key string, one owner (the gate), and OnboardingView never names UserDefaults. `HomeView.swift:16` already takes `@Binding var pane` from RootView the same way.
- **Transition:** a hard cut between gate states, the same as SignIn → shell today.
- **Verify:** see §7.

### Step 6: keep `00_Context` current
- **File:** MODIFIED `Docs/00_Context/ARCHITECTURE.md`.
  - Layout block `:152-154`: add `OnboardingView`, and change `PremiumView (+ PlanTag)` to `PremiumView (+ PlanTag, PlanPair, CoverFan, FeatureTile)`.
  - "Where it's sold" `:133-138`: add "and the last onboarding card, through `PlanPair`".
- Point-in-time docs (`01`-`06`) are not touched. The Dossiers line in `Docs/README.md` is added when the plan is saved (README rule).

---

## 5. Data and persistence
- **One new key:** `onboardingSeen` (Bool) in **standard** defaults. It is app-only; the widget never reads it (same as `suggestionCalloutSeen`, `RootView.swift:76`). An absent key means false and the cards show. There is no migration.
- **Replay for testing:** see R4. The argument domain may pin the value for the whole run.
- No model, schema, API or network change. PlanPair's counts read the bundled JSON through the existing, cached `WordProvider`.

---

## 6. Concurrency, state and memory

- **Isolation map:** OnboardingView, PlanPair, CoverFan, FeatureTile and the `fileprivate` pieces are all MainActor by default isolation. The only work off the main thread is PlanPair's `Task.detached(priority: .utility)`, moved verbatim. It captures a `[String]` and returns `[String: Int]` (both Sendable), and calls the `nonisolated` `WordProvider`. In Swift 5 mode it compiles exactly as it does today.
- **Task lifetime:**
  - Each counts `.task` is cancelled when its view disappears.
  - Because of `.id(page)`, going back to card 5 re-runs PlanPair's task. It is a cache hit and cheap.
  - PremiumView's task now runs only on the owned branch, so it never runs together with PlanPair's.
  - The purchase `Task` inside `UnlockButton` (`PremiumBar.swift:118-128`) is unchanged. If the reader finishes onboarding while the sheet is up, the view goes, the system sheet still owns the outcome, and the `Transaction.updates` listener picks it up (`PREMIUM_PLAN_RESOLVED.md:505-506`, `PremiumViewModel.swift:37-42`).
- **Ownership:**
  - `seen`: RootView owns it through `@AppStorage`; OnboardingView borrows it as a `@Binding`.
  - `page` and `forward`: OnboardingView `@State`. They live outside the `.id(page)` subtree, so they are not reset.
  - `model`: `@State WordViewModel()`, also outside the id'd subtree, so it is built once. `@State`'s initial value is evaluated on every struct init, so a RootView re-render builds (and throws away) another `WordViewModel` that reads from the NSCache. HomeView has the same cost today. While onboarding shows, RootView's body only tracks `auth.restored` and `onboardingSeen`, so re-renders are rare [Inference].
  - `premium`: environment; views read `premium.isUnlocked`, never `Premium.isUnlocked` (ARCHITECTURE "Premium").
- **Retain cycles:** none new. Button closures capture value-type views. The only escaping `Task`s with class captures are existing ones (`WordViewModel.shuffle` `[weak self]`, `WordViewModel.swift:80-86`; PremiumViewModel listener `[weak self]`). OnboardingView never calls `shuffle`.
- **Slide direction:** `forward` must change before `page`, in the same action. See R5 for the known failure where the outgoing card keeps its old removal edge.

---

## 7. Test plan

There is no test target and no testable seam is added, since the pages are static views. Verification:

1. **Build:** `xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build`, after every step.
2. **Gates (regression only; none compiles a touched file):**
   `for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done`
   `CLAUDE.md:54` lists five and omits `check_sentences`, while `REPO_MAP.md:52` and the brief list six. Run all six.
3. **PremiumView regression (after steps 1-3, before the gate):** screenshot the Premium pane before and after at a fixed window size, in Free state and in owned state (buy in the StoreKit config). Fan, card heights, counts, "Try Again" (StoreKit config disabled or offline) and Restore should all be identical.
4. **Manual matrix (after step 5)**, run from Xcode. Per saved memory: don't `open -n` the app and don't kill the debug run.

| Case | Expect |
|---|---|
| Fresh install (flag deleted, R4) | Ground, then card 1, not SignInView |
| Skip on card 1 / Esc on card 3 | SignInView (or the shell if a session exists); relaunch goes straight past onboarding |
| Keyboard only | → and Return advance, ← goes back (does nothing on card 1), Esc skips, → on card 5 does nothing, Return on card 5 finishes |
| Back/Next by mouse | Slides in the right direction both ways (R5) |
| Buy on card 5 (StoreKit config) | Spinner, then the card swaps to the thanks and the primary reads "Get started"; the widget reloads (`OneWordApp.swift:47`) |
| Restore on card 5 | Works; `problem` shows on failure |
| Already owned (restart after buying, flag deleted) | Card 5 opens on the thanks, no plan cards |
| Store unreachable | Price reads "Lifetime", UnlockButton reads "Try Again", "The App Store isn't reachable…" shows, Continue with Free still finishes |
| Existing signed-in user upgrading (flag absent, session present) | Sees the cards once, then the shell (F2) |
| Light / Dark / Midnight / Umber | Tokens only; Midnight's band shows behind the cards; covers are the only colour |
| Handwriting and doodle switches on | Display face switches; tiles keep SF Symbols (as PremiumView) |
| Reduce Motion on | Crossfade only |
| 1000×680 | Width fits the plan cards side by side; card 5 likely scrolls with the nav pinned (R3) |
| Narrow window (about 760 wide) | Cards squeeze but stay side by side (known limit); nothing overlaps the nav |
| VoiceOver | "Page n of 5" on the dots; the card title is announced on change; the widget mock and fan are skipped; the word preview reads as one element |

**Hard to test:** SwiftUI bodies and StoreKit flows. That is accepted: there is no seam to add without a view model the brief rules out.

---

## 8. Accessibility, localization and project mechanics
- **Accessibility:**
  - Every button has a visible text label.
  - Skip gets `.help("Skip the introduction")`.
  - Dots are one element labelled "Page n of 5".
  - Decorative visuals (`CoverFan` already, the widget mock) are `accessibilityHidden(true)`.
  - The word preview uses `.accessibilityElement(children: .combine)`.
  - FeatureTiles already combine (`PremiumView.swift:321`).
  - The page-change announcement is in `go(_:)`.
  - Dynamic Type: the app deliberately uses fixed sizes (`DoodleTheme.swift:128-131`), so there is nothing new to do.
- **Localization:** there is no `.xcstrings`, so there is nothing to register. Literal `Text("…")` strings become keys automatically if a catalog is ever added. Strings passed as `String` (tile text, titles) would need `String(localized:)` then, as PremiumView's would.
- **Info.plist / entitlements / assets:** none. There is no new capability, and covers and symbols already exist.
- **Target membership:** `OnboardingView.swift` joins the app target automatically. Nothing enters `Shared/`, and no pbxproj or gate-script edits are needed.
- **Availability:** everything used is available on macOS 14: `.keyboardShortcut` with arrows, `AccessibilityNotification` [Unverified: macOS 14.0+], `accessibilityReduceMotion`. No `#available` is needed.
- **Window drag:** like SignInView, onboarding has no PaneHeader. On macOS 14 the window drags only from the title-bar strip (`PaneHeader.swift:112-121`). This is not a regression.

---

## 9. Decision forks (operator-owned)

| # | Fork | Default | The other branch wins when… |
|---|---|---|---|
| F1 | Placement | **Before sign-in** (brief e1). Educate first; `premium.load()` already runs at the root regardless of auth (`OneWordApp.swift:45`); a StoreKit purchase belongs to the Apple Account, not the Firebase session, so buying before sign-in is fine. | …you want only committed (signed-in) users to see the price, or the sign-in gate is being reconsidered (`MARKET_FIT_RESEARCH_BRIEF.md` §7 "Keep or drop the sign-in gate?"). After sign-in means swapping the two middle branches, one line. |
| F2 | Existing signed-in users see it once | **Yes** (brief e1, accepted) | …the build goes to people already using the app and you judge the re-education as noise. Branch B is one modifier on RootView's Group: `.onChange(of: auth.restored) { if auth.isSignedIn { onboardingSeen = true } }`, so returning sessions never see it and a later sign-out doesn't bring it back. `MARKETING_VERSION = 1.0` / build 1 suggests no store users yet [Inference], which makes this mostly about testers. |
| F3 | Final card copy | The drafts below | …you have your own voice for it. Copy is yours; the structure doesn't depend on it. |
| F4 | Card 5 at 1000×680 | **Scroll the card body, nav pinned** (R3) | …you want the whole plan pair visible without scrolling. Options: raise `.defaultSize` height (`OneWordApp.swift:49`, affects every first window), or add a quiet "Restore Purchase" to card 5's nav so it is always above the fold. Avoid a `compact:` flag on PlanPair; it creates a second shape to keep in sync. |
| F5 | Hindi on/off choice in onboarding (`MARKET_FIT_RESEARCH_BRIEF.md:268`) | **Out** (brief d) | …research says the Hindi gloss puts off non-Hindi readers. That would be a Toggle bound to `@AppStorage("showHindi", store: AppGroup.defaults)` (as `WordListView.swift:27`) on card 1, as a follow-up. |

**Draft copy (F3):**
1. Eyebrow "Welcome to", title "One Word". Body: "A new word every day, with nothing to keep up with. Each one comes with its meaning in Hindi, a definition and an example." Visual label "Today's word".
2. Eyebrow "On your desktop", title "Put the word where you'll see it". Steps: "1 Right-click the desktop and choose Edit Widgets. 2 Search for One Word and drag Word of the Day onto the desktop, small, medium or large. 3 ↻ shows another word; right-click it and choose Edit to give it a dictionary of its own." [Unverified: the exact macOS menu wording on 14 and on current macOS.]
3. Eyebrow "The shelf", title "\(n) dictionaries, one shelf". Body: "Everyday English is free. \(premiumNames) come with Premium. Pick one under Dictionaries and your word of the day comes from it." Optional ternary for owners: "All of them are yours."
4. Eyebrow "Beyond today", title "Every word you meet, kept". Tiles:
   - Search: "⌘K finds any word, with its full entry."
   - Bookmarks: "Keep the words worth keeping, in a dictionary of their own."
   - History: "Go back to any past day and read its word."
   - Learned: "Every word you read in full is logged; Profile shows how far you are through each dictionary."
   - Save from any app: "Select a word anywhere, then Services ▸ Save to One Word. Give it a shortcut in System Settings ▸ Keyboard ▸ Keyboard Shortcuts ▸ Services."
   - Make it yours: "Light, Dark, Midnight or Umber, and hand-drawn icons and type, in Settings."
5. Eyebrow "Free, or everything", then PlanPair. When owned: "Premium · Unlocked", "Every dictionary is yours.", "Thank you for supporting One Word."

---

## 10. Risks and exits

| # | Risk | Severity | Confidence | Early warning | Cheapest fix |
|---|---|---|---|---|---|
| R1 | The extraction changes PremiumView (a missed `Self.` → `PremiumView.`, `fixedSize` lost, counts blank) | Medium | Low-medium | Before/after screenshots differ; the Free and Premium cards stop sharing a height; count rows stay blank | Each extraction is its own step; revert that step's commit |
| R2 | `fileprivate` file-scope `card` or `label` is shadowed or ambiguous | Low | Low (no `View` extension in the module defines them; other files' copies are `private`) | Compile error at a call site | Rename to `planCard` / `planLabel` |
| R3 | Card 5 doesn't fit 680pt: by adding up the layout, the Premium card alone is about 700pt tall [Inference]; Restore sits below the fold | Medium | Medium-high | At 1000×680 the card scrolls | Already handled: ScrollView body plus pinned nav keeps Continue with Free visible. Restore is reachable by scrolling and also lives in Settings and PremiumBar (App Review 3.1.1 is met by a restore mechanism existing, `PREMIUM_PLAN_RESOLVED.md` D12). F4 if you want it above the fold. |
| R4 | Replay via the scheme argument `-onboardingSeen NO`: the argument domain outranks the persistent write, so "finish" may not dismiss within that run [Inference] | Low (testing only) | Medium | You stay on onboarding after Skip in a run with the argument | Use the argument only to look at the cards. To test the flow, stop the run and `defaults delete ~/Library/Containers/com.hariom.swift.oneword/Data/Library/Preferences/com.hariom.swift.oneword.plist onboardingSeen` [Unverified path; the app is sandboxed, `OneWord.entitlements`] |
| R5 | The asymmetric slide gives the outgoing card the previous direction's removal edge on Back [Unverified] | Low | Medium | Going Back, the old card exits the "wrong" way or overlaps | Drop to `.opacity`, exactly RootView's pane crossfade (`RootView.swift:123-125`), and delete `forward` |
| R6 | Under MEMBER_IMPORT_VISIBILITY, `AccessibilityNotification…post()` needs its module named | Low | Medium | Error "member not visible" | Add `import Accessibility`, following the pattern at `HomeView.swift:11` and `PremiumView.swift:18` |
| R7 | Bare → / ← / Return get taken by something with focus | Low | Low (no text input on these cards; key equivalents run before the responder chain, `SentenceView.swift:97-103`) | A key does nothing | Already using the codebase's key-equivalent pattern; no focus needed |
| R8 | Widget-gallery wording differs by macOS version | Low | Medium | Copy doesn't match the menu on a test Mac | Change the copy only |

---

## 11. Sequencing summary and verification

- [ ] **1. `CoverFan`** (first reversible move, `PremiumView.swift` only). Build, then compare the Premium pane.
- [ ] **2. File-scope `card`/`label`/`bookRow(count:)` plus `FeatureTile`.** Build, then compare the owned view.
- [ ] **3. `PlanPair`**, with PremiumView's task moved onto the owned branch. Build, then compare the Free view and check buy/restore/Try Again. *Unblocks 4.*
- [ ] **4. `OnboardingView.swift`.** Build, then walk the canvas in four appearances. *Unblocks 5.*
- [ ] **5. RootView gate plus key.** Build, run the six gates, run the §7 matrix.
- [ ] **6. `ARCHITECTURE.md`** layout and "Where it's sold".

End to end: build green, then the six gates green. Then delete the flag (R4) and launch from Xcode: ground → card 1 → keyboard through all five → buy (StoreKit config) → "Get started" → SignInView or the shell. Relaunch, and onboarding does not appear.

**Files touched (absolute):**
- `/Users/hariom/Desktop/One Word/OneWord/Views/PremiumView.swift` (MODIFIED)
- `/Users/hariom/Desktop/One Word/OneWord/Views/OnboardingView.swift` (NEW)
- `/Users/hariom/Desktop/One Word/OneWord/Views/RootView.swift` (MODIFIED)
- `/Users/hariom/Desktop/One Word/Docs/00_Context/ARCHITECTURE.md` (MODIFIED)

---

## 12. Open questions and assumptions
- [Inference] Card 5's height is added up from PremiumView's fonts and paddings, not measured. Running at 1000×680 settles it. The plan works either way.
- [Inference] `@AppStorage` reading through the argument domain (R4) is not checked against SwiftUI's implementation. One run settles it.
- [Unverified] The asymmetric-transition direction behaviour (R5). One Back press settles it.
- [Unverified] `AccessibilityNotification.Announcement` is available on macOS 14 and whether it needs an explicit import (R6). The compiler settles it.
- [Unverified] The macOS widget-gallery and widget context-menu wording on 14 and current releases (R8). A look on a test Mac settles it.
- [Assumption] The widget mock uses `t.surface` so it sits in the app's palette. The real widget paints plain white or black by the Mac's scheme (`WordWidgetView.swift:65`). If you want the mock to match that exactly, use `Theme.of(scheme).background` with a hairline instead.
- [Assumption] Keeping `CoverFan`'s `height` parameter (brief e5) even though both callers use 100. Drop it if no card ever changes it.
- [Inference] No App Store users yet (`MARKETING_VERSION = 1.0`, build 1), so F2 mainly affects testers. App Store Connect's release history settles it.
