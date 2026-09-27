# Onboarding: resolved implementation plan

> Resolved 2026-09-27 by `/plan-resolver --report`. It resolves the audit [ONBOARDING_PLAN_AUDIT.md](../Audit/ONBOARDING_PLAN_AUDIT.md) against [ONBOARDING_PLAN.md](../ONBOARDING_PLAN.md), re-checked against the code on `main` at `675065b`. The code tree is clean; the only changes are untracked docs.
>
> The audit's verdict was *Ready to build once the four Major corrections are written into the plan* (medium-high confidence), with no blockers. It was not *Needs rework*, so this document fixes the plan in place rather than sending it back to `/plan`.

## 1. Header

**What was resolved:**
- **Audit:** `/Users/hariom/Desktop/One Word/Docs/02_Plan/Audit/ONBOARDING_PLAN_AUDIT.md`, read in full.
- **Plan:** `/Users/hariom/Desktop/One Word/Docs/02_Plan/ONBOARDING_PLAN.md`, read in full.
- **Original brief:** `plan-onboarding-brief.md` in the scratchpad, read in full. It records the operator's locked decisions.
- **Resolver brief:** `plan-resolver-onboarding-brief.md`.

**Upstream:** there is no `/brainstorm` or `/strategize` doc. The plan comes from the operator's request, the brief and the code. That is weaker than planning from a committed strategy, so decisions that belong to the operator are marked as such.

**Stack, re-checked against the code.** It matches what both the plan and the audit say.

| | Detected | Evidence |
|---|---|---|
| Build | One `OneWord.xcodeproj` with the app `OneWord` and the widget `OneWordWidget`. `OneWord/` is a file-system-synchronized group, so new `Views/` files join the app target with no pbxproj edit. `Shared/` is also referenced by explicit path for the widget. | `project.pbxproj:97-106` |
| SDK / minimum target | Xcode 27 with `MacOSX27.0.sdk`, building for `MACOSX_DEPLOYMENT_TARGET = 14.0` | `xcrun --show-sdk-path`; `project.pbxproj:458,516` |
| Language and concurrency | Swift 5 mode. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` | `project.pbxproj:553-557` (Debug), `:590-594` (Release) |
| Dependencies | SPM: GoogleSignIn-iOS and firebase-ios-sdk (auth only) | `project.pbxproj:634,642` |
| UI | SwiftUI with one `WindowGroup`, `.defaultSize(1000, 680)` and `.hiddenTitleBar`. Panes draw their own `PaneHeader`; SignInView draws none. | `OneWordApp.swift:35-52`, `PaneHeader.swift:25-32`, `SignInView.swift:25-74` |
| Architecture | MVVM. `@Observable` view models import only `Observation`, and views own them as `@State`. | `WordViewModel.swift:12-16`, `HomeView.swift:17` |
| State and DI | `AuthViewModel`, `PremiumViewModel` and `\.doodle` are injected at the root. `@AppStorage` in standard defaults holds app-only flags. | `OneWordApp.swift:26-47`, `RootView.swift:76` |
| Persistence | UserDefaults, the App Group and bundled JSON. Nothing else. | `Premium.swift:28`, `WordProvider.swift:74-86` |
| Testing | No test target. Verification is `xcodebuild`, the six `tools/check_*.sh` gates and manual runs with `StoreKit/OneWord.storekit`. None of the gates compiles a `Views/` file. | Gate compile paths list only `Shared/`, `Models/` and `WordViewModel.swift`; scheme `StoreKitConfigurationFileReference` |
| Localization | No `.xcstrings` file exists | (as planned) |

**Files and symbols opened for this resolution:**
- **Views:** `PremiumView.swift` 1-442 · `RootView.swift` 1-279 · `PaneHeader.swift` 1-125 · `SignInView.swift` 1-119 · `PremiumBar.swift` 1-129 · `WordDetail.swift` 50-70 and 238-256 · `SentenceView.swift` 40-115 and 160-170 · `SettingsView.swift` 50-68 · `FeedbackView.swift` 54-60 and 120-130 · `HistoryView.swift` 44-56 · `WordListView.swift` 22-30 and 120-160 · `DictionaryPicker.swift` 44-50 · `Doodles.swift` 120-126 · `HomeView.swift` 1-20
- **View models:** `PremiumViewModel.swift` 1-131 · `WordViewModel.swift` 1-88 · `AuthViewModel.swift` 40-70
- **Shared:** `Theme.swift` 100-172 · `Word.swift` 1-18 · `Premium.swift` 1-30 · `WordProvider.swift` 12-16 and 68-90
- **Models:** `Wordbook.swift` 1-63 · `DoodleTheme.swift` 120-192 · `Appearance.swift` (cases, by grep)
- **App root:** `OneWordApp.swift` 1-54 · `WordCapture.swift` 1-12
- **Widget:** `WordWidget.swift` 15-66 · `WordWidgetView.swift` 55-95
- **Project and tools:** `project.pbxproj` (settings and packages, by grep) · the scheme (by grep) · the entitlements (by grep) · the `tools/check_*.sh` compile paths
- **Docs:** `CLAUDE.md` 45-58 · `ARCHITECTURE.md` 118-180 · `REPO_MAP.md` 15-46 and 52 · `DESIGN_BRIEF.md` (headings and the Hindi rows, including `:66`)
- **SDK:** `Accessibility.swiftmodule/arm64e-apple-macos.swiftinterface` 215-257
- **Greps:** every `restore()` caller · every `PremiumBar` embed · the helper names `card`/`label`/`bookRow` · `isMovableByWindowBackground` and `WindowDragGesture`

---

## 2. Resolution summary

The audit has 32 items: 4 Majors, 10 minors, 7 nits, 6 coverage gaps and 5 operator questions.

| Resolution | Count | Items |
|---|---|---|
| **Self-resolved** (the code dictates the fix) | 22 | M1, M3, m2-m10, N1-N5, G1-G6 |
| **Operator decision (recommended default applied)** | 9 items, which are 5 decisions | Q1 (covers M4), Q2 (covers m1), Q3 (covers M2), Q4, Q5 (covers N6) |
| **Not a defect** | 1 | N7 (moot under the Q3 default) |
| **Deferred** | 0 | — |

**Where the plan stands now:**
- There were no blockers.
- All four Majors are now written into the plan. M1 and M3 are fixed outright; M2 and M4 are resolved by the recommended defaults for Q3 and Q1.
- Five operator decisions are waiting for accept or override (§5).
- I found three things the audit didn't raise, listed as A1-A3. A1 is a new risk that the Q1 default itself introduces (window dragging), and it has a one-line exit.
- The plan should pass a re-audit once the operator accepts the defaults [Inference].

---

## 3. Resolution log

| ID · Severity | Resolution | What changed in the plan | Grounding / decision |
|---|---|---|---|
| **M1** · Major | Self-resolved | Step 4 now spells out the exact modifier order:<br>• `.transition(.opacity).id(page)` sit on the **ScrollView** inside the GeometryReader.<br>• `.safeAreaInset(edge: .bottom) { nav }` wraps the reader.<br>• Then the top-strip reclaim (Q1), the Skip overlay, `.animation(…, value: page)` and `.paneBackground(t)`.<br>The nav sits outside the id'd subtree, so VoiceOver focus stays on the Primary button across pages, and each card starts with a fresh scroll offset. | The stacking bug is already documented at `WordDetail.swift:59-61`. The inset wrapping the reader follows `PaneHeader.swift:27-29` over `PremiumView.swift:38-62`. The transition/id/animation shape follows `RootView.swift:123-125`. |
| **M2** · Major | Operator decision: recommended default applied (Q3) | Deleted `forward`, the asymmetric `.move` transition and `accessibilityReduceMotion`; the transition is now `.transition(.opacity)`. With no direction state left, the stale-removal-edge failure can't happen. The two-phase slide is recorded as the upgrade path (F6). | `RootView.swift:123`. See Q3 in §5. |
| **M3** · Major | Self-resolved | `go(_:)` now starts with `let next = page + step; guard Self.titles.indices.contains(next) else { return }` and uses `next` from then on. The Primary also reads `isLast` once, when the nav is drawn, so a Return pressed again before the redraw acts on the card the user actually saw. | Without the guard, a held → or a double Return could make `Self.titles[page]` read index 5 and crash. The view-state guards only take effect after a re-render. |
| **M4** · Major | Self-resolved for the R3 text; operator decision (Q1) for what fits above the fold | R3 is rewritten. Settings and every `PremiumBar` sit behind the gate, so from card 5 a new user's only Restore links are PlanPair's own and the new one in the nav. R3 and F4 now also say that UnlockButton itself is likely below the fold at 1000×680, while "Continue with Free" is always visible. F4 is decided by the Q1 default. | `RootView.swift:96-99` (the shell only shows when signed in). PremiumBar is embedded at `SettingsView.swift:65`, `DictionaryPicker.swift:226` and `WordDetail.swift:80`. See Q1 in §5. |
| **m1** · Minor | Operator decision: recommended default applied (Q2) | Card 2's step 3 and card 4's Search tile are reworded (§4.9 F3). Premium's claims stay on card 5, through PlanPair. | Widget Edit picks are labelled "· Premium" and a locked pick falls back to Everyday English (`WordWidget.swift:22-34,40-42`). A locked search hit opens as headword plus PremiumBar with no Hindi (`WordDetail.swift:247`, `WordListView.swift:129`). Premium sells "on your widget" and "opens in full" (`PremiumView.swift:180,253-255,268-270`). |
| **m2** · Minor | Self-resolved | The nav always gets `.background(t.background)`, not only if content shows through. It must not use `paneBackground`, because Midnight's band would paint at the top of the nav's own frame. | The band is pinned to the top of whatever frame draws it and is 330pt tall (`Theme.swift:119-139`). The header paints over scrolled content for the same reason (`PaneHeader.swift:22-24,90`). |
| **m3** · Minor | Self-resolved | Added matrix row 19: card 4 at 1000×680. The ScrollView body already handles overflow. | Same body as card 5 (M1 stack) |
| **m4** · Minor | Self-resolved | R4 now says **will**. Use the argument only to *look at* the cards. To test the flow, run `defaults delete` on the sandbox container plist, then ⌘R from Xcode. The container path stays [Unverified]. | The app already relies on argument-domain reads (`AuthViewModel.swift:59-62`). The app is sandboxed (entitlements). |
| **m5** · Minor | Self-resolved | `import Accessibility   // AccessibilityNotification.post() — MEMBER_IMPORT_VISIBILITY needs it named` is added unconditionally. R6 is closed. | The SDK interface has `AccessibilityNotification` `@available(macOS 14.0)` at `:220-222` and `post()` in an extension at `:253-255`. The comment style follows `PremiumView.swift:18` and `HomeView.swift:11`. |
| **m6** · Minor | Self-resolved | The hidden → twin goes in the `.background` of the nav's row HStack, never on Back. | Back carries `.disabled(page == 0)`, which would flow into anything in its background. Twin pattern: `SentenceView.swift:103-108`. |
| **m7** · Minor | Self-resolved (note) | Notes added to Step 3 and §4.6. After a purchase on the Premium pane, the owned view's counts land one hop later and the rows briefly show a blank (cosmetic). A PlanPair decode still running at purchase can overlap the owned view's decode; that is harmless duplicate work. | The placeholder is designed for this (`PremiumView.swift:384-385`). `NSCache` is thread-safe (`WordProvider.swift:74-86`). |
| **m8** · Minor | Self-resolved (note) | CoverFan's doc comment is made general, and its `ponytail:` note now says an even count has no upright centre cover. | `mid = 3.5` for 8 books (`PremiumView.swift:106-114`). 8 = `Wordbook.all` minus `.saved` (`Wordbook.swift:52`). |
| **m9** · Minor | Self-resolved (note) | The F2 branch-B row notes the cost: OnboardingView is built once before `onChange` fires. | Branch B only |
| **m10** · Minor | Self-resolved (note) | Card 1 note: Hindi shows even if the reader turned `showHindi` off. This only matters for existing users under F2. The one-line exit is recorded. | `WordListView.swift:27,129` |
| **N1** · Nit | Self-resolved | The citation is now `WordWidgetView.swift:67` | Opened, confirmed |
| **N2** · Nit | Self-resolved | The citation is now `SentenceView.swift:78` | Opened, confirmed |
| **N3** · Nit | Self-resolved | The citation is now `ARCHITECTURE.md:133-137` | Opened, confirmed |
| **N4** · Nit | Self-resolved | The plan now says the Primary's `t.radius(10)` is deliberate. It matches UnlockButton (`PremiumBar.swift:112`) and Free's footer (`PremiumView.swift:330`), which it sits beside on card 5. Only the surface-plus-hairline treatment comes from SignInView, whose buttons use `t.radius(16)` (`SignInView.swift:106-107`). | Opened, confirmed |
| **N5** · Nit | Self-resolved | §4.6 corrected: while onboarding shows, RootView's body also tracks `auth.busy`, `scheme` and `doodle` through `.busy(...)`. | `RootView.swift:107` |
| **N6** · Nit | Operator decision: recommended default applied (Q5) | Step 6 changes `CLAUDE.md:54` to list all six gates | `CLAUDE.md:54` lists five; `REPO_MAP.md:45,52` lists six |
| **N7** · Nit | Not a defect | The suggestion to precompute an `AnyTransition` no longer applies, because there is no ternary under the Q3 default. Reapply it only if the slide comes back. | — |
| **G1** · Gap | Self-resolved | The modifier order is covered by M1, the nav ground by m2 | — |
| **G2** · Gap | Self-resolved | Matrix rows 4-5: held → and double Return | M3 |
| **G3** · Gap | Self-resolved | Matrix row 9: Back or Esc while a purchase or restore is in flight | `PremiumBar.swift:118-128` (the purchase Task isn't tied to the view) |
| **G4** · Gap | Self-resolved | Matrix row 19: card 4 at 1000×680 | m3 |
| **G5** · Gap | Self-resolved | Matrix rows 6-7: Next then Back, and card 5 reopening at the top of its scroll | M1, M2 |
| **G6** · Gap | Self-resolved | R3 and F4 now name UnlockButton as likely below the fold | M4 |
| **Q1** · Question | Operator decision: recommended default applied | Keep the ScrollView body. Add a quiet Restore link and a `problem` line to card 5's nav. PlanPair keeps its own Restore. Take back the title-bar strip. No compact variant and no `.defaultSize` change. | §5 |
| **Q2** · Question | Operator decision: recommended default applied | Reworded copy (F3) | §5 |
| **Q3** · Question | Operator decision: recommended default applied | Crossfade | §5 |
| **Q4** · Question | Operator decision: recommended default applied | Existing signed-in users see the cards once | §5 |
| **Q5** · Question | Operator decision: recommended default applied | `CLAUDE.md:54` is fixed in this PR | §5 |

**Things I found while re-checking the code that the audit didn't raise:**
- **A1. Taking back the top strip may cost window dragging on the cards** [Inference, medium].
  - Nothing in the app sets `isMovableByWindowBackground`.
  - `PaneHeader.swift:112-121` shows that where SwiftUI content fills the strip, the window stops dragging there on macOS 14, and panes only get dragging back on 15+ through a `private` `WindowDragGesture`.
  - With the ScrollView reaching into the strip, the cards may have no drag surface at all.
  - Added as R9 with matrix row 20. The exit is to delete one line, and it goes into Q1's review entry.
- **A2. A failed Restore from the nav would be silent.** At 1000×680, PlanPair's `problem` text is likely below the fold. The nav therefore shows `premium.problem` above its row on card 5, the same pairing as `PremiumBar.swift:48,54` and `PremiumView.swift:228-234`. This is part of the Q1 default.
- **A3. Citation fixes:**
  - The hidden twin is at `SentenceView.swift:103-108`, not 104-109.
  - "Hide an empty Hindi line" is `DESIGN_BRIEF.md:66` (§4), not §8.
  - The resolver brief says SettingsView calls `restore()`. It actually embeds `PremiumBar` (`SettingsView.swift:65`), which does (`PremiumBar.swift:54`). The only two direct callers are `PremiumView.swift:223` and `PremiumBar.swift:54`.

---

## 4. The resolved plan

### 4.1 The change

On a fresh install, the app now opens on five full-window education cards sized for the Mac window, instead of going straight to sign-in. The cards are:
1. welcome
2. the widget
3. the dictionaries
4. your words
5. Free vs Premium

They show once and can be skipped on every card. Finishing or skipping lands where the app lands today: SignInView, then the shell.

### 4.2 Scope and outcome

**Done when:**
- A fresh install (flag absent) opens on OnboardingView after `auth.restored`.
- Skip, Esc, or the last card's primary button sets `onboardingSeen = true` and lands on SignInView, or on the shell if a session exists.
- PremiumView looks and behaves exactly as before.
- `xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build` is green.
- `for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done` is green.

**Scope shape:** a single change (one PR). It has three behaviour-preserving extractions inside `PremiumView.swift`, one new view, one gate edit, and two doc touches. Everything lands and reverts together.

**In scope:**
- Extract `CoverFan`, `FeatureTile` and `PlanPair` from PremiumView.
- Add `OnboardingView.swift` with five cards.
- Add the RootView gate and one `@AppStorage` key.
- Update `ARCHITECTURE.md` and the gate line in `CLAUDE.md`.

**Locked by the brief (not relitigated):**
- Onboarding comes before sign-in.
- It replaces the whole window like SignInView; it is not a sheet.
- Five cards, in this order.
- No OnboardingView view model.
- `@AppStorage("onboardingSeen")` in standard defaults.
- `PlanPair` and `CoverFan` are extracted and reused.
- No change under `Shared/`.
- No new gate.
- Card 5 stays skippable and keeps Restore Purchase visible.

**Not doing:**
- An appearance picker in onboarding.
- A Hindi on/off choice (F5).
- Detecting whether a widget is installed (no API exists).
- A "show welcome again" button in Settings.
- A new `tools/check_*.sh` gate.
- A new view model.
- A stacked layout for very narrow windows. This is the same limit PremiumView has (`PremiumView.swift:46-47`).
- A compact PlanPair variant.
- A `.defaultSize` change.
- A directional slide (F6).
- A `showRestore` parameter on PlanPair.

### 4.3 Architecture fit

Everything goes in the app target under `OneWord/Views/`. `Shared/` is untouched, and no gate compiles a touched file.

| Type | File | New / changed | Responsibility | Mirrors |
|---|---|---|---|---|
| `CoverFan` | `Views/PremiumView.swift` | NEW internal struct | Fans the covers for any `[Wordbook]` and holds the static high-quality cover cache | The old `fan`, `covers` and `cover(_:height:scale:)` (`:103-148`). It sits beside `PlanTag` (`:411-436`). |
| `FeatureTile` | `Views/PremiumView.swift` | NEW internal struct | A symbol in an accent disc, a display-face title and one line of text | The old `tile` (`:299-322`) |
| `PlanPair` | `Views/PremiumView.swift` | NEW internal struct | The Free and Premium cards side by side, with price, UnlockButton, Restore, `problem`, and its own counts `.task` | The old `free`/`lifetime`/`price`/`action`/`footer`/`heading`/`perk`/`rule` (`:150-236,324-371`) and the task (`:63-68`) |
| `card`, `label`, `bookRow(_:count:_:)` | `Views/PremiumView.swift` | Moved to file scope as `fileprivate` | Stateless pieces shared by PremiumView's owned view, PlanPair and FeatureTile | The same bodies (`:343-349,374-408`). Other files keep their own `private` copies (`SettingsView.swift:274`, `ProfileView.swift:433`), which is the repo's norm. |
| `PremiumView` | same file | MODIFIED | Hero, then either the owned view or `PlanPair()` | itself |
| `OnboardingView` | `Views/OnboardingView.swift` | NEW | Full-window cards, page state, the nav, finishing | `SignInView.swift:25-74` (front door); page chrome from `PremiumView.swift:38-62` |
| `RootView` | `Views/RootView.swift` | MODIFIED | Adds the `onboardingSeen` key and the gate branch | `calloutSeen` at `RootView.swift:76` |

**Why the pieces go to file scope:** PremiumView's owned view (`:244-297`) and the plan cards both call `card`, `label` and `bookRow`. `bookRow` reads `counts`, which will now live separately in each struct. Moving the stateless pieces to `fileprivate` file-scope functions leaves every `card(t) {…}` and `label("…", t)` call site unchanged; only `bookRow` gains a `count:` parameter. The macOS 27 SDK's SwiftUI interfaces declare no `View` member named `card`, `label` or `bookRow` (audit), so R2 is unlikely.

No MVVM fallback is needed. The content is static, and the one live value (today's word) comes from the existing `WordViewModel`.

### 4.4 Implementation steps

Every type is MainActor by default isolation (`project.pbxproj:554`), and nothing below changes that.

#### Step 1: extract `CoverFan` (no visible change)
- **File:** MODIFIED `OneWord/Views/PremiumView.swift` (app target).
- **Do:**
  - Add `struct CoverFan: View { let books: [Wordbook]; var height: CGFloat = 100; @Environment(\.displayScale) private var displayScale }`.
    - Its body is the old `fan` (`:105-118`) with `Self.books` → `books` and `100` → `height`.
    - Keep `.padding(.top, 6)` and `.accessibilityHidden(true)` inside it.
  - Move `private static var covers` and `private static func cover(_:height:scale:)` (`:121-148`) into CoverFan unchanged, comments included.
  - Make the doc comment general: "The covers, fanned like a hand of cards, tipping away and settling lower towards the edges."
  - Add this `ponytail:` note: *"tuned at 100pt; scale spacing/offset if a caller changes height. An even count (onboarding's 8) has no upright centre cover — the middle two sit at ±2.5° on the same zIndex."*
  - In PremiumView, `hero` (`:75`) calls `CoverFan(books: Self.books)`.
  - Delete `fan`, `covers`, `cover` and the `displayScale` property (`:24-25`). Nothing else reads it.
- **Isolation:** `covers` stays a MainActor-isolated static, as it is today.
- **Verify:** build. The Premium pane's fan should look identical. Launch with `ONEWORD_PANE=premium` in the scheme's environment, and don't commit that (`RootView.swift:24-30`).

#### Step 2: lift the shared pieces and add `FeatureTile` (no visible change)
- **File:** MODIFIED `PremiumView.swift`.
- **Do:**
  - Move `card(_:emphasized:padding:_:)` (`:396-408`) and `label(_:_:)` (`:343-349`) out of the struct to file scope as `fileprivate func`, bodies unchanged.
  - Move `bookRow` (`:374-391`) to file scope as `fileprivate func bookRow(_ book: Wordbook, count: Int?, _ t: Theme) -> some View`.
    - Replace `counts[book.id]` with `count`.
    - Update its three callers:
      - `:166` becomes `bookRow(.everydayEnglish, count: counts[Wordbook.everydayEnglish.id], t)`
      - `:189` and `:290` become `bookRow($0, count: counts[$0.id], t)`
  - Add `struct FeatureTile: View { let symbol: String; let title: String; let text: String }`.
    - It reads `\.colorScheme` and `\.doodle` from the environment.
    - Its body starts `let t = Theme.of(scheme, doodle)`, followed by the old `tile` body (`:301-321`, including `.accessibilityElement(children: .combine)`).
  - In `owned`, change the six `tile(a, b, c, t)` calls (`:250-270`) to `FeatureTile(symbol: a, title: b, text: c)`, then delete `tile`.
- **Verify:** build. With Premium owned (buy with the StoreKit config), the owned view's tiles, shelf and counts should look identical.

#### Step 3: extract `PlanPair` (no visible change)
- **File:** MODIFIED `PremiumView.swift`.
- **Do:**
  - Change `private static let books/shelf` (`:28,30`) to `fileprivate static` so PlanPair can read `PremiumView.books` and `PremiumView.shelf`.
  - Add `struct PlanPair: View`:
    - Environment: `@Environment(PremiumViewModel.self) premium`, `\.colorScheme`, `\.doodle`.
    - State: `@State private var counts: [String: Int] = [:]`.
    - Body: `let t = Theme.of(scheme, doodle)`, then `HStack(alignment: .top, spacing: 24) { free(t); lifetime(t) }.fixedSize(horizontal: false, vertical: true)`.
    - The `fixedSize` moves in from `:49`, and the ponytail comment at `:45-47` moves with it.
    - Then `.task { … }`, copied verbatim from `:63-68` with `Self.shelf` → `PremiumView.shelf`.
  - Move `free`, `lifetime`, `price`, `action`, `footer`, `heading`, `perk` and `rule` (`:150-236,324-340,351-371`) into PlanPair as `private`, with `Self.books` → `PremiumView.books`.
    - `action` keeps its own Restore Purchase, so PremiumView stays identical.
  - In PremiumView's body, `:48-49` becomes `PlanPair()`.
  - Move PremiumView's own `.task` (`:63-68`) from the root onto the owned branch: `owned(t).task { … }`.
    - This way the two counts tasks never run together.
    - Otherwise both detached tasks would miss `WordProvider`'s cache on a first visit (the check-then-write at `WordProvider.swift:74-86`) and decode all eight books twice.
  - Update the file header comment (`:5-13`) to say PlanPair and CoverFan are reused by the onboarding cards.
- **Isolation:** unchanged. The detached closure captures `ids: [String]`, returns `[String: Int]` (both Sendable), and calls `WordProvider`, which is `nonisolated` (`WordProvider.swift:14`).
- **Note (m7):**
  - After a purchase on the Premium pane, the owned branch's task starts when that branch appears. Its rows show the reserved blank for about one hop before the counts land (cache hit). This is cosmetic, and `PremiumView.swift:384-385` reserves the space for exactly this.
  - `Task.detached` ignores `.task` cancellation, so a PlanPair decode still running at purchase can overlap the owned decode. That is harmless duplicate work.
- **Verify:** build.
  - The Premium pane (not owned) should look identical, with counts in both cards.
  - Buy with the StoreKit config: the pane should swap to the owned view and the counts should appear.
  - Restore and "Try Again" should still work.

#### Step 4: `OnboardingView` (not reachable yet; check it in the canvas)
- **File:** NEW `OneWord/Views/OnboardingView.swift` (app target). The synchronized group picks it up with no pbxproj edit (`project.pbxproj:97-106`).
- **Imports:**
  ```swift
  import SwiftUI
  import Accessibility   // AccessibilityNotification.post() — MEMBER_IMPORT_VISIBILITY needs it named
  ```
- **Shape (signatures only):**
  ```swift
  struct OnboardingView: View {
      @Binding var seen: Bool                         // RootView owns the key
      @State private var page = 0
      @State private var model = WordViewModel()      // today's word, as HomeView.swift:17
      @Environment(PremiumViewModel.self) private var premium
      @Environment(\.colorScheme) private var scheme
      @Environment(\.doodle) private var doodle
      /// One per card: the count, the dots, and what VoiceOver announces.
      private static let titles = ["Welcome", "The widget", "Dictionaries", "Your words", "Plans"]
      private static let shelf = Wordbook.all.filter { $0.id != SavedWords.resource }  // as PremiumView.swift:30

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
      private func skip(_ t: Theme) -> some View
      private func go(_ step: Int)
      private func finish()                           // seen = true
  }
  ```
- **Body, in this exact modifier order (M1, Q1, Q3):**
  ```swift
  let t = Theme.of(scheme, doodle)
  GeometryReader { geo in
      ScrollView {
          current(t)
              .frame(maxWidth: 920)
              .padding(.horizontal, 40)
              .padding(.vertical, 24)
              .frame(maxWidth: .infinity, minHeight: geo.size.height)
      }
      .scrollContentBackground(.hidden)
      // On the ScrollView, not its content: two ScrollViews overlap in the reader,
      // two cards in one ScrollView stack (WordDetail.swift:59-61). A fresh id is
      // also a fresh scroll offset per card.
      .transition(.opacity)
      .id(page)
  }
  // Wraps the reader: geo.size.height excludes the nav, and the nav stays out of
  // the id'd subtree, so VoiceOver focus stays on the Primary across pages.
  .safeAreaInset(edge: .bottom, spacing: 0) { nav(t) }
  // The hidden title bar still reserves its height; take it back (PaneHeader.swift:28-29).
  .ignoresSafeArea(.container, edges: .top)
  .overlay(alignment: .topTrailing) { skip(t) }
  .animation(.easeInOut(duration: 0.22), value: page)   // as RootView.swift:125
  .paneBackground(t)
  ```
- **`go(_:)` (M3):**
  ```swift
  let next = page + step
  guard Self.titles.indices.contains(next) else { return }
  page = next
  AccessibilityNotification.Announcement(Self.titles[next]).post()
  ```
  VoiceOver focus stays on the persistent Primary button, so without this announcement a page change would be silent.
- **Controls.** SwiftUI allows one key per button, so Next can't take both Return and →. The fix already in the code is a hidden twin button (`SentenceView.swift:97-108`).
  - **Skip** (`skip(t)`):
    - A muted 13pt `.plain` text button with `.keyboardShortcut(.cancelAction)` (Esc, as `FeedbackView.swift:58`) that calls `finish()`.
    - `.help("Skip the introduction")`.
    - Padding `.top` 16 and `.trailing` 24, so it sits at the top-right of the reclaimed strip. Tune it in the running app; the canvas has no title bar.
  - **Nav** (`nav(t)`):
    - It reads `let isLast = page == Self.titles.count - 1` and `let selling = isLast && !premium.isUnlocked` once, at render.
    - Its structure is a `VStack(spacing: 8)`:
      - **Problem line:** `if selling, let problem = premium.problem`, a centred muted 12pt `Text(problem)` styled as `PremiumView.swift:229-233` (A2). Add this `ponytail:` note: *"on a tall window PlanPair shows this line too; two of one line beats a silent Restore failure below the fold."*
      - **Row:** `HStack` of three columns, so the dots stay centred when Restore appears on card 5:
        - **Back**, `.frame(maxWidth: .infinity, alignment: .leading)`. A muted text button with `.keyboardShortcut(.leftArrow, modifiers: [])` (as `HistoryView.swift:50`). On page 0 it gets `.disabled(page == 0).opacity(page == 0 ? 0 : 1).accessibilityHidden(page == 0)`. A disabled button's shortcut doesn't fire.
        - **Dots.** Five 6pt circles: `t.ink` for the current card, `t.ink.opacity(0.2)` for the rest. Add `.accessibilityElement(children: .ignore).accessibilityLabel("Page \(page + 1) of \(Self.titles.count)")`.
        - **Trailing** `HStack`, `.frame(maxWidth: .infinity, alignment: .trailing)`:
          - `if selling`: **Restore Purchase**, copied from `PremiumView.swift:223-227`: `Button("Restore Purchase") { Task { await premium.restore() } }` with `.buttonStyle(.plain)`, 12pt, `t.muted`, `.disabled(premium.phase == .purchasing)`.
          - Then the **Primary**.
      - **The → twin**, in the row HStack's `.background`, never on Back (m6):
        - `Button("", action: { go(1) }).keyboardShortcut(.rightArrow, modifiers: []).opacity(0).accessibilityHidden(true).disabled(isLast)`, copied from `SentenceView.swift:103-108`.
        - On the last card → does nothing, and Return finishes.
    - **Ground (m2):** `.padding(.horizontal, 40).padding(.vertical, 16).background(t.background)`, so scrolled content never shows through. It deliberately doesn't use `paneBackground`: Midnight's band pins to the top of whatever frame draws it (`Theme.swift:119-139`). At the default height the band has faded out well above the nav, so plain `t.background` meets the ground without a seam.
  - **Primary:**
    - Action: `Button { isLast ? finish() : go(1) }` with `.keyboardShortcut(.defaultAction)` (Return, as `FeedbackView.swift:126`) and `.buttonStyle(.plain)`.
    - Label: "Next" on pages 0-3. On the last page, `premium.isUnlocked ? "Get started" : "Continue with Free"`.
    - Drawing: 14pt medium `t.ink` text, padding h20/v11, `t.surface` fill plus a `t.hairline` stroke at **`t.radius(10)`**.
    - Why 10: it's deliberate, matching UnlockButton (`PremiumBar.swift:112`) and Free's footer bar (`PremiumView.swift:330`), which it sits beside on card 5. Only the surface-plus-hairline treatment comes from SignInView, whose buttons are `t.radius(16)` (`SignInView.swift:106-107`).
    - It is not an ink pill: UnlockButton is "the one filled control in the app" (`PremiumBar.swift:102-103`).
- **Cards.** The final copy is in F3. Each card uses `intro(...)`, styled like PremiumView's hero (`PremiumView.swift:77-98`):
  - an 11pt bold uppercase eyebrow with tracking 2.5, in muted
  - a `doodle.face(34-44)` title with `doodle.tracking`
  - a 15pt muted body with `lineSpacing(3)`
  1. **welcome:**
     - Layout: `HStack(spacing: 48) { entry(model.word, size: 40, t) in a t.surface/t.hairline card at t.radius(18); intro(...) }`.
     - The entry card gets `.accessibilityElement(children: .combine)`.
     - Hide the Hindi line when `hindi.isEmpty` (`DESIGN_BRIEF.md:66`).
     - Draw it by hand. Do not use `WordDetail`, which records the word as learned (`LearnedWords.swift:7-9`) and carries actions.
     - **Note (m10):** Hindi shows even if an existing reader turned `showHindi` off (`WordListView.swift:27`). That only happens under F2, and the card's copy promises Hindi. The exit is one `@AppStorage("showHindi", store: AppGroup.defaults)` read that hides the line.
  2. **widget:**
     - A mock of the medium widget, about 360×170: the entry lines at a smaller size, with an `arrow.clockwise` glyph at top-right, on `t.surface` plus `t.hairline`, `.accessibilityHidden(true)`.
     - Numbered steps beside it.
     - Facts come from:
       - `WordWidget.swift:55,61-63`: kind `WordWidget`, "Word of the Day", small/medium/large.
       - `WordWidgetView.swift:83-84`: the refresh button.
       - `WordWidget.swift:15-17,50`: the widget follows the app by default.
  3. **dictionaries:**
     - `CoverFan(books: Self.shelf)` beside `intro`. That is 8 covers, and m8's note applies.
     - The premium names are `Self.shelf.filter { !Premium.free.contains($0.id) }.map(\.shortName).formatted(.list(type: .and))`, so the copy can't drift from `Wordbook.all`.
  4. **yourWords:**
     - Two rows of three `FeatureTile`s, each row `.fixedSize(horizontal: false, vertical: true)`, laid out as in `PremiumView.swift:248-272`.
     - The tiles are listed in F3. Pick their symbols from ones the app already uses (`PremiumView.swift:250-268`, `DoodleTheme.swift:52-55`).
  5. **plans:**
     - If `premium.isUnlocked`: the eyebrow "Premium · Unlocked", "Every dictionary is yours." and "Thank you for supporting One Word." (as `PremiumView.swift:77-89`).
     - Otherwise: the eyebrow "Free, or everything", then `PlanPair()`.
- **Preview:** `OnboardingView(seen: .constant(false)).environment(PremiumViewModel()).frame(width: 1000, height: 680)` (as `SignInView.swift:115-119`). To see Midnight or Umber, add `.environment(\.doodle, DoodleTheme(icons: false, handwriting: false, appearance: .midnight))`.
- **Verify:**
  - Build.
  - Walk all five cards in the canvas in Light, Dark, Midnight and Umber.
  - The strip reclaim, Skip's position and window dragging can only be checked in the running app, after Step 5.

#### Step 5: the gate (the only switch users see)
- **File:** MODIFIED `OneWord/Views/RootView.swift`.
- **Do:**
  - Add `@AppStorage("onboardingSeen") private var onboardingSeen = false` beside `calloutSeen` (`:76`), with a one-line doc comment.
  - Change the gate (`:91-100`) to:
    - `!auth.restored` → the ground, unchanged
    - `else if !onboardingSeen` → `OnboardingView(seen: $onboardingSeen)`
    - `else if auth.isSignedIn` → `shell`
    - `else` → `SignInView()`
  - Update the header comment (`:9-11`) to say a first launch shows the cards before the sign-in gate.
  - `.task { auth.restore() }` and `.busy(...)` (`:104,107`) stay where they are, wrapping the Group.
- **Why a binding rather than a second `@AppStorage`:** one key string with one owner (the gate), and OnboardingView never names UserDefaults. `HomeView.swift:16` takes `@Binding var pane` from RootView the same way.
- **Transition:** a hard cut between gate states, the same as SignIn → shell today.
- **Verify:** the build, the six gates, and the §4.7 matrix.

#### Step 6: keep the live docs current
- MODIFIED `Docs/00_Context/ARCHITECTURE.md`:
  - In the layout block (`:152-154`), add `OnboardingView`, and change `PremiumView (+ PlanTag)` to `PremiumView (+ PlanTag, PlanPair, CoverFan, FeatureTile)`.
  - In "Where it's sold" (`:133-137`), add "and the last onboarding card, through `PlanPair`".
- MODIFIED `CLAUDE.md:54` (Q5): add `check_sentences` to the gate loop, so it matches `REPO_MAP.md:52`:
  `for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done`
- Point-in-time docs (`01`-`06`) are not touched. The Dossiers line in `Docs/README.md` is added when the plan is saved (README rule), not in this PR.

### 4.5 Data and persistence
- **One new key:** `onboardingSeen` (Bool) in **standard** defaults.
  - It is app-only; the widget never reads it (the same as `suggestionCalloutSeen`, `RootView.swift:76`).
  - An absent key means false, so the cards show. No migration is needed.
- **Replaying for testing (R4):** the scheme argument `-onboardingSeen NO` **will** pin the value for the whole run, so Skip and finish do nothing visible in that run. Use it only to look at the cards. To test the full flow, delete the key from the sandbox container plist, then run again from Xcode (⌘R).
- No model, schema, API or network change. PlanPair's counts read the bundled JSON through the existing, cached `WordProvider`.

### 4.6 Concurrency, state and memory
- **Isolation map:**
  - OnboardingView, PlanPair, CoverFan, FeatureTile and the `fileprivate` file-scope functions are all MainActor by default isolation.
  - The only work off the main thread is PlanPair's `Task.detached(priority: .utility)`, moved verbatim. It captures `[String]`, returns `[String: Int]` (both Sendable) and calls the `nonisolated` `WordProvider`. It compiles in Swift 5 mode as it does today.
- **Task lifetime:**
  - Each counts `.task` is cancelled when its view disappears.
  - Because of `.id(page)`, returning to card 5 re-runs PlanPair's task. That is a cache hit and cheap.
  - PremiumView's task now runs only on the owned branch, so it never runs alongside PlanPair's (m7 note in Step 3).
  - The purchase `Task` inside `UnlockButton` (`PremiumBar.swift:118-128`) and the Restore `Task` (nav and in-card) are unstructured and not tied to the view. If the reader goes Back or finishes onboarding while either is in flight:
    - the result still reaches `PremiumViewModel` (`handle`/`restore`, `PremiumViewModel.swift:82-113`)
    - the `Transaction.updates` listener catches anything else (`:37-42`)
    - the widget reloads on `isUnlocked` (`OneWordApp.swift:47`)
- **Ownership:**
  - `seen`: RootView owns it through `@AppStorage`; OnboardingView borrows it as a `@Binding`.
  - `page`: OnboardingView `@State`, outside the `.id(page)` subtree, so it isn't reset.
  - `model`: `@State WordViewModel()`, also outside the id'd subtree, so it's built once. `@State`'s initial value is evaluated on every struct init, so a RootView re-render builds and throws away another `WordViewModel` (an NSCache hit); HomeView pays the same cost today. While onboarding shows, RootView's body tracks `auth.restored`, `onboardingSeen`, and, through `.busy(...)`, `auth.busy`, `scheme` and `doodle` (`RootView.swift:107`). `auth.isSignedIn` isn't evaluated. Re-renders should be rare [Inference].
  - `premium`: read from the environment. Views read `premium.isUnlocked`, `premium.phase` and `premium.problem`, never `Premium.isUnlocked` (`ARCHITECTURE.md:124-125`).
- **Retain cycles:** none new.
  - Button closures capture value-type views.
  - The Restore `Task { await premium.restore() }` holds the app-lifetime `PremiumViewModel` only until the call returns, exactly as `PremiumView.swift:223` does.
  - OnboardingView never calls `shuffle`, whose `Task` uses `[weak self]` (`WordViewModel.swift:80-86`).
- **Queued key events (M3):** `go(_:)` bounds-checks before it writes, and the Primary's action reads `isLast` as of the last render. A held → or a double Return can't index past the last card.

### 4.7 Test plan

There is no test target, and no testable seam is added (the pages are static views).
1. **Build** after every step: `xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build`.
2. **Gates** (regression only; none compiles a touched file): `for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done`.
3. **PremiumView regression**, after steps 1-3 and before the gate:
   - Screenshot the Premium pane before and after at a fixed window size, in the Free state and the owned state.
   - The fan, card heights, counts, "Try Again" (StoreKit config off or offline) and Restore should all be identical.
4. **Manual matrix**, after step 5, run from Xcode. Don't `open -n` the app and don't kill the debug run.

| # | Case | Expect |
|---|---|---|
| 1 | Fresh install (key deleted, §4.5) | Ground, then card 1, not SignInView |
| 2 | Skip on card 1 / Esc on card 3 | SignInView (or the shell with a session). Relaunching goes straight past onboarding. |
| 3 | Keyboard only | → and Return advance, ← goes back (and does nothing on card 1), Esc skips, → on card 5 does nothing, Return on card 5 finishes |
| 4 | **Hold → from card 1** (M3) | Steps through the cards and stops on card 5. No crash. |
| 5 | **Return twice quickly on card 4** (M3) | Lands on card 5, then either nothing or finish. Never a crash or an out-of-range card. |
| 6 | **Next, then Back, by mouse** (M1/M2) | A crossfade both ways. The incoming card is never pushed down by the outgoing one. Nav, dots and Skip don't fade or move. |
| 7 | **Card 5 scrolled down, then Back, then Next** (M1) | Card 5 reopens at the top of its scroll |
| 8 | Buy on card 5 (StoreKit config) | Spinner, then the card swaps to the thanks. The primary reads "Get started", the nav's Restore disappears, and the widget reloads (`OneWordApp.swift:47`). |
| 9 | **Back or Esc while a purchase or restore is in flight** (G3) | While the purchase sheet is up it likely owns the keys, so Esc cancels the sheet and UnlockButton returns to the price [Unverified]. If Back or Skip runs mid-flight (by mouse, or during a restore), nothing crashes. Coming back to card 5 shows the spinner or the thanks. After Skip, the purchase still lands. |
| 10 | **Restore from the nav on card 5** (Q1) | Visible without scrolling at 1000×680. The link disables and UnlockButton spins while it runs. Success swaps to the thanks. Failure shows `problem` above the nav row. |
| 11 | Restore inside PlanPair | Works, with the same behaviour as PremiumView |
| 12 | Already owned (restart after buying, key deleted) | Card 5 opens on the thanks, with no plan cards and no nav Restore |
| 13 | Store unreachable | The price reads "Lifetime" and UnlockButton reads "Try Again". "The App Store isn't reachable…" shows in the card and above the nav. Continue with Free still finishes. |
| 14 | Existing signed-in user upgrading (key absent, session present) | Sees the cards once, then the shell (F2) |
| 15 | Light / Dark / Midnight / Umber | Tokens only. Midnight's band shows behind the cards, and the nav's ground meets it with no seam. Covers are the only colour. |
| 16 | Handwriting and doodle switches on | The display face switches; tiles keep SF Symbols (as PremiumView) |
| 17 | Reduce Motion on | The same crossfade: opacity only, nothing moves |
| 18 | 1000×680, card 5 | The plan cards sit side by side and the body scrolls. The nav (Continue with Free, Restore) stays pinned and opaque, with nothing showing through (m2). UnlockButton likely needs a scroll (R3). |
| 19 | **1000×680, card 4** (m3) | Fits, or scrolls with the nav pinned. Each tile row keeps one height. |
| 20 | **Top strip, cards 1 and 5** (A1) | Skip sits top-right, clear of the edge. Dragging the window from the top strip moves it on macOS 14 and on current macOS. If it doesn't, use R9's exit. |
| 21 | Narrow window (about 760 wide) | Cards squeeze but stay side by side (known limit). On card 5 the nav row still fits: Back · dots · Restore + Primary. |
| 22 | VoiceOver | "Page n of 5" on the dots, and the card title announced on change. The widget mock and fan are skipped. The word preview reads as one element. Focus stays on the Primary across pages. |

**Hard to test:** SwiftUI bodies and StoreKit flows. That is accepted: there's no seam to add without a view model, which the brief rules out.

### 4.8 Accessibility, localization and project mechanics
- **Accessibility:**
  - Every button has a visible text label, and Skip has `.help(...)`.
  - The dots are one element labelled "Page n of 5".
  - Decorative visuals (CoverFan, already hidden, and the widget mock) are `accessibilityHidden(true)`.
  - The word preview combines into one element, and FeatureTiles already do (`PremiumView.swift:321`).
  - The page-change announcement is in `go(_:)`.
  - The hidden twin is `accessibilityHidden(true)`.
  - Dynamic Type: the app deliberately uses fixed sizes (`DoodleTheme.swift:128-131`), so there is nothing new to do.
- **Localization:** there is no `.xcstrings`, so there is nothing to register. Literal `Text("…")` strings would become keys automatically if a catalog is ever added. Strings passed as `String` (tile text, titles) would then need `String(localized:)`, as PremiumView's would.
- **Info.plist, entitlements, assets:** none needed.
- **Target membership:** `OnboardingView.swift` joins the app target automatically. Nothing enters `Shared/`, and no pbxproj or gate-script edits are needed.
- **Availability:**
  - `AccessibilityNotification.Announcement` and `post()` are macOS 14.0+ in Accessibility.framework, confirmed in the SDK interface at `:220-257`, and imported explicitly.
  - `.keyboardShortcut` with bare arrows already ships for 14 (`HistoryView.swift:50,53`).
  - No `#available` is needed.
- **Window drag:** SignInView drags from the empty title-bar strip. Onboarding takes that strip back (Q1), which may remove its only drag surface [Inference]; see R9 and row 20.

### 4.9 Decision forks (operator-owned)

| # | Fork | Applied default | The other branch wins when… |
|---|---|---|---|
| F1 | Placement | **Before sign-in.** Locked by the brief. `premium.load()` runs at the root regardless of auth (`OneWordApp.swift:45`). | Locked; not reopened here. After sign-in would mean swapping the two middle gate branches. |
| F2 (Q4) | Existing signed-in users | **They see the cards once.** | …the build goes to current users and you judge the re-education as noise. **Branch B** is one modifier on RootView's Group: `.onChange(of: auth.restored) { if auth.isSignedIn { onboardingSeen = true } }`. m9: it fires after the body has already built OnboardingView once (including `WordViewModel()`'s main-thread decode) and may paint card 1 for a frame [Inference]. `MARKETING_VERSION = 1.0` (`project.pbxproj:549`) suggests no store users yet [Inference]. |
| F3 (Q2) | Card copy | **The drafts below, with card 2 step 3 and card 4 Search reworded so Free readers aren't promised Premium features** | …you have your own voice for it. The structure doesn't depend on the copy. |
| F4 (Q1) | Card 5 at 1000×680 | **Keep the scrolling body. Pin a quiet Restore and the `problem` line in the nav on card 5 only. PlanPair keeps its own Restore (duplicate accepted). Take back the title-bar strip (about 28pt).** No compact variant and no `.defaultSize` change. | …you want the whole plan pair, including UnlockButton, visible without scrolling. The options are a taller `.defaultSize` (`OneWordApp.swift:49`, which affects every first window) or a compact PlanPair (a second shape to keep in sync). |
| F5 | Hindi on/off in onboarding | **Out** (brief) | …research says the Hindi gloss puts off non-Hindi readers. It would be a Toggle bound to `@AppStorage("showHindi", store: AppGroup.defaults)` (`WordListView.swift:27`) on card 1, as a follow-up. |
| F6 (Q3) | Page transition | **A plain crossfade**, as RootView's panes (`RootView.swift:123-125`) | …you want a directional slide. Use a two-phase update: set the direction state first (it doesn't animate, because `.animation` is keyed on `page`), then `Task { page = next }` on the next main-actor turn, so the outgoing card re-renders with the new removal edge. The M3 guard already covers the queued increments this makes more likely. Bring `accessibilityReduceMotion` back with it. |
| F7 (Q5) | `CLAUDE.md:54` gate list | **Fixed in this PR** (Step 6) | …you want doc changes kept out of feature PRs. Then it's a one-line follow-up. |

**Copy (F3), with the reworded lines marked ★:**
1. **Welcome.** Eyebrow "Welcome to", title "One Word". Body: "A new word every day, with nothing to keep up with. Each one comes with its meaning in Hindi, a definition and an example." Visual label "Today's word".
2. **Widget.** Eyebrow "On your desktop", title "Put the word where you'll see it". Steps:
   - "1 Right-click the desktop and choose Edit Widgets."
   - "2 Search for One Word and drag Word of the Day onto the desktop, small, medium or large."
   - ★ "3 ↻ shows another word, and the widget follows the dictionary you pick in the app."
   - This is true for Free and Premium (`WordWidget.swift:15-17,40-42,50`). The per-widget dictionary is sold on card 5 through PlanPair's "…on your widget" (`PremiumView.swift:180`). [Unverified: the exact macOS menu wording.]
3. **Dictionaries.** Eyebrow "The shelf", title "\(n) dictionaries, one shelf". Body: "Everyday English is free. \(premiumNames) come with Premium. Pick one under Dictionaries and your word of the day comes from it." Optional ternary for owners: "All of them are yours."
4. **Your words.** Eyebrow "Beyond today", title "Every word you meet, kept". Tiles:
   - ★ Search: "⌘K looks up a word from anywhere in the app." This makes no promise of full entries; "every entry opens in full" stays Premium's (`PremiumView.swift:253-255`).
   - Bookmarks: "Keep the words worth keeping, in a dictionary of their own."
   - History: "Go back to any past day and read its word."
   - Learned: "Every word you read in full is logged; Profile shows how far you are through each dictionary."
   - Save from any app: "Select a word anywhere, then Services ▸ Save to One Word. Give it a shortcut in System Settings ▸ Keyboard ▸ Keyboard Shortcuts ▸ Services." (`WordCapture.swift:5-9`)
   - Make it yours: "Light, Dark, Midnight or Umber, and hand-drawn icons and type, in Settings."
5. **Plans.** Eyebrow "Free, or everything", then PlanPair. When owned: "Premium · Unlocked", "Every dictionary is yours.", "Thank you for supporting One Word."

### 4.10 Risks and exits

| # | Risk | Severity | Confidence | Early warning | Cheapest fix |
|---|---|---|---|---|---|
| R1 | An extraction changes PremiumView (a missed `Self.` → `PremiumView.`, `fixedSize` lost, counts blank) | Medium | Low-medium | Before/after screenshots differ; the Free and Premium cards stop sharing a height; count rows stay blank | Each extraction is its own step, so revert that step |
| R2 | File-scope `card` or `label` is shadowed or ambiguous | Low | Low (the SDK declares no such `View` members; other files' copies are `private`) | A compile error at a call site | Rename them `planCard` / `planLabel` |
| R3 | Card 5 doesn't fit 680pt. The content is about 700pt against about 575-590pt visible after the strip reclaim and the nav [Inference]. UnlockButton and PlanPair's own Restore are likely below the fold. Settings and every PremiumBar are behind the gate (`RootView.swift:96-99`), so they aren't reachable from here. | Medium | Medium on the pixels | At 1000×680 the card scrolls | Already handled by the default: "Continue with Free" and the nav's Restore (with `problem`) are always visible, and the price is near the top of the Premium card. For no scrolling at all, see F4's other branch. |
| R4 | Replay via `-onboardingSeen NO`: the argument domain outranks the write, so finish **will** leave the run on the cards | Low (testing only) | High | You stay on the cards after Skip in a run with the argument | Use the argument only to view the cards. For the flow: `defaults delete ~/Library/Containers/com.hariom.swift.oneword/Data/Library/Preferences/com.hariom.swift.oneword.plist onboardingSeen`, then ⌘R [Unverified: the exact container path] |
| R5 | The outgoing card overlaps or shunts the incoming one mid-crossfade | Low | Low (the id is on the ScrollView inside the reader, per M1) | During a page change the new card starts lower and jumps up | Wrap `current(t)` in `ZStack(alignment: .top)` and put the id there, as `WordDetail.swift:59-62` does |
| R6 | ~~Accessibility import~~ | — | — | — | **Closed:** `import Accessibility` is in Step 4 |
| R7 | Bare → / ← / Return taken by something with focus | Low | Low (no text input on these cards; key equivalents run before the responder chain, `SentenceView.swift:97-102`) | A key does nothing | This already uses the codebase's key-equivalent pattern |
| R8 | The widget-gallery wording differs by macOS version | Low | Medium | The copy doesn't match the menu on a test Mac | Change the copy only |
| R9 | Taking back the title-bar strip removes the cards' only window-drag surface (A1) | Low-medium (first-run polish) | Medium [Inference: `PaneHeader.swift:112-121`; nothing sets `isMovableByWindowBackground`] | Row 20: the window won't drag from the top on the cards | Delete the one `.ignoresSafeArea(.container, edges: .top)` line. That costs about 28pt; Restore stays visible through the nav regardless. |
| R10 | `.keyboardShortcut(.defaultAction)` on a `.plain` button doesn't fire Return | Low | Low (⌘K on a `.plain` button works, `RootView.swift:240-241`) [Inference] | Return does nothing | Give Return a hidden twin too (`SentenceView.swift:103-108`) |

### 4.11 Sequencing summary and verification
- [ ] **1. `CoverFan`.** The first reversible move, touching `PremiumView.swift` only. Build, then compare the Premium pane.
- [ ] **2. File-scope `card`/`label`/`bookRow(count:)`, plus `FeatureTile`.** Build, then compare the owned view.
- [ ] **3. `PlanPair`**, with PremiumView's task moved onto the owned branch. Build, then compare the Free view and check buy, restore and Try Again. *Unblocks 4.*
- [ ] **4. `OnboardingView.swift`**, with the M1 modifier order, the M3 guard and the Q1 nav. Build, then walk the canvas in four appearances. *Unblocks 5.*
- [ ] **5. The RootView gate and key.** Build, run the six gates, run the §4.7 matrix.
- [ ] **6. `ARCHITECTURE.md`** (layout and "Where it's sold") and the **`CLAUDE.md:54`** gate line.

**End to end:**
1. Build green, then the six gates green.
2. Delete the key (§4.5) and launch from Xcode.
3. Walk: ground → card 1 → the keyboard through all five cards → Restore from the nav → buy (StoreKit config) → "Get started" → SignInView or the shell.
4. Relaunch: onboarding should not appear.

**Files touched (absolute):**
- `/Users/hariom/Desktop/One Word/OneWord/Views/PremiumView.swift` (MODIFIED)
- `/Users/hariom/Desktop/One Word/OneWord/Views/OnboardingView.swift` (NEW)
- `/Users/hariom/Desktop/One Word/OneWord/Views/RootView.swift` (MODIFIED)
- `/Users/hariom/Desktop/One Word/Docs/00_Context/ARCHITECTURE.md` (MODIFIED)
- `/Users/hariom/Desktop/One Word/CLAUDE.md` (MODIFIED, one line)

### 4.12 Open questions and assumptions
- [Inference] Card 5's height is added up from fonts and paddings, not measured. One run at 1000×680 settles it, and the plan works either way (R3).
- [Unverified] The container plist path for replay (R4). `ls ~/Library/Containers/com.hariom.swift.oneword/Data/Library/Preferences/` settles it.
- [Inference] Content filling the reclaimed strip removes window dragging (R9). Row 20 settles it.
- [Unverified] Whether StoreKit's purchase sheet on macOS takes Esc and ← while it's up (row 9). One run settles it; both outcomes are safe.
- [Inference] `.defaultAction` fires on a `.plain` button (R10). One Return press settles it.
- [Unverified] The macOS widget-gallery and widget context-menu wording on 14 and on current releases (R8). A look on a test Mac settles it.
- [Assumption] The widget mock uses `t.surface` so it sits in the app's palette. The real widget paints plain white or black by the Mac's scheme (`WordWidgetView.swift:67`). To match that, use `Theme.of(scheme).background` with a hairline.
- [Assumption] `CoverFan` keeps its `height` parameter even though both callers use 100. Drop it if no card ever changes it.
- [Inference] There are no App Store users yet (`MARKETING_VERSION = 1.0`), so F2 mostly affects testers. App Store Connect's release history settles it.

---

## 5. Operator review queue

| # | Applied default | Why it's recommended | Alternative | Choose the alternative when… |
|---|---|---|---|---|
| **Q1** (M4, F4) | On card 5, keep the scrolling body and add a quiet "Restore Purchase" (same `premium.restore()` call and `.disabled(premium.phase == .purchasing)` as `PremiumView.swift:223-227`) plus the `premium.problem` line (A2) to the pinned nav, on the last card and only while not unlocked. PlanPair keeps its own Restore, so PremiumView stays identical and card 5 shows the link twice. Take back the title-bar strip (`.ignoresSafeArea(.container, edges: .top)`, as `PaneHeader.swift:28-29`). No compact variant and no `.defaultSize` change. | It meets the locked "keep Restore Purchase visible" at 1000×680 with the smallest change. From card 5 no other Restore is reachable, because Settings and PremiumBar are behind the gate. "Continue with Free" is always visible. A `showRestore` parameter would change PremiumView's code path for a cosmetic duplicate. | (a) Raise `.defaultSize` height (every first window). (b) A compact PlanPair (a second shape to keep in sync). (c) A `showRestore: Bool` on PlanPair to drop the duplicate. (d) Keep the title-bar strip. | (a)/(b): you need UnlockButton itself above the fold at the default size, which the default doesn't give (R3). (c): the duplicate link bothers you on a tall window. **(d): row 20 shows the cards can't be dragged (R9, A1). Then delete the one line; the nav Restore keeps the requirement met.** |
| **Q2** (m1, F3) | Reword card 2 step 3 to "↻ shows another word, and the widget follows the dictionary you pick in the app." Reword card 4 Search to "⌘K looks up a word from anywhere in the app." Premium's claims stay on card 5. | Both new lines are true for a Free reader (`WordWidget.swift:22-42`, `WordDetail.swift:247`, `WordListView.swift:129`) and no longer contradict PlanPair two cards later. | The original drafts ("…give it a dictionary of its own", "…with its full entry") | …card 2 and card 4 get owner-specific variants (a ternary on `premium.isUnlocked`), or you accept the overclaim for Free readers. |
| **Q3** (M2, F6) | A plain crossfade: `.transition(.opacity)`, no `forward`, no `accessibilityReduceMotion`. | It removes the stale-removal-edge bug entirely, matches the app's existing pane transition (`RootView.swift:123-125`), and is reduce-motion-safe by itself. | A two-phase directional slide (F6) | …a direction cue matters to you. It costs one `@State`, a deferred `Task { page = next }`, and the reduce-motion branch. |
| **Q4** (F2) | Existing signed-in users see the cards once. | This is the brief's accepted consequence, and it teaches features, Restore included, to people who skipped past them. | Branch B: `.onChange(of: auth.restored) { if auth.isSignedIn { onboardingSeen = true } }` | …the build ships to an existing audience and you judge the cards as noise for them (see the m9 cost note). |
| **Q5** (N6, F7) | Fix `CLAUDE.md:54` in this PR (Step 6). | `CLAUDE.md` is a live instruction file that should stay current. Leaving it at five gates means agents skip `check_sentences`. | A separate one-line PR | …you keep doc-only changes out of feature PRs. |

## 6. Remaining / deferred

- **Deferred:** none.
- **Carried soft spots** (none blocks the build; each is settled by one run or one look):
  - R3: exact card heights
  - R4: the container path
  - R8: widget menu wording
  - R9: dragging in the reclaimed strip
  - R10: `.defaultAction` on a `.plain` button
  - Row 9: how the purchase sheet handles keys
- **Needs you:** accept or override Q1-Q5 in §5. The most likely one to flip is Q1(d), keeping the strip, if row 20 fails. Steps 1-3 don't depend on any of these answers, so they can start now.
