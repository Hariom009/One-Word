# Website: resolved plan

> Resolves [`WEBSITE_PLAN_AUDIT.md`](../Audit/WEBSITE_PLAN_AUDIT.md) against [`WEBSITE_PLAN.md`](../WEBSITE_PLAN.md). Written 2026-09-27 on `main` at `675065b`. **This plan stands alone** — build from it without the original or the audit.

## 0. Resolution

**Summary.** 20 audit items: **15 self-resolved**, **3 operator decisions** (each taken on the recommended option, asked live), **0 not a defect**, **2 deferred**. The blocker is cleared. Net readiness: build-ready, with two `[Unverified]` facts that a console check settles in Step 1 and Step 6.

**Files re-opened for this resolution** (beyond the audit's list): `SettingsView.swift:41-44, 55-58, 116-122, 189-205` · `SignInView.swift:27-46, 64, 76-82` · `RootView.swift:38-57` · `FeedbackViewModel.swift:26` · `PremiumView.swift:219-224`. Tooling: `brew` at `/opt/homebrew/bin/brew`; `cwebp` absent; `webp` formula not installed.

| # | Sev | Resolution | What changed | Grounding / decision |
|---|---|---|---|---|
| B1 | Blocker | **Self-resolved** | §5b names the profile-picture link and the fetch, counts three connections, adds the link to the deletion list | `AuthViewModel.swift:118` (`photoURL`), `ProfileView.swift:473` (`AsyncImage(url:)`), `RootView.swift:253` |
| M1 | Major | **Operator decision** | Covers ship as WebP with alpha; `webp` added to tooling; §6 commands rewritten | Chosen: WebP (recommended). Alt: PNG at 1× (240 px). Flips if `brew install webp` is unavailable on the build Mac |
| M2 | Major | **Self-resolved** | Region claim removed; §5b says "on Google Cloud"; Step 1 adds a console check that may re-add the region | Firestore region `[Unverified]` — no CLI or console access from here |
| M3 | Major | **Self-resolved** | §5b gains "Who else handles your data" and "How long we keep it" | Guideline 5.1.1(i) retention + third-party items |
| M4 | Major | **Operator decision** | New Step 5: one URL constant, a Settings row, a sign-in link; scope and done-when updated; build + gates now run for real | Chosen: in this PR (recommended). Alt: follow-up PR on the release checklist. Flips if the PR must stay site-only. Insertion points `SettingsView.swift:189-205`, `SignInView.swift:39-64` |
| Min 1 | Minor | Self-resolved | Shelf copy: "12,000 words with Hindi meanings" | 41 of 12,000 `words.json` entries have empty `hindi`; Emotions 18 of 987 |
| Min 2 | Minor | Self-resolved | "up to three related words" | `check_related.sh` guarantees ≥99%, not all |
| Min 3 | Minor | Self-resolved | Local check uses the Hosting emulator; tooling install moved to Step 0 | `cleanUrls` needs Firebase's server, not Python's |
| Min 4 | Minor | Self-resolved | FAQ 4 reads "Profile → Settings → Premium → Restore Purchase" | `SettingsView.swift:53-56` (`PremiumBar()`), `RootView.swift:38-41` |
| Min 5 | Minor | Self-resolved | Stack table names only `OneWord/` as synchronized; Step 7 fixes the same line in `REPO_MAP.md` | `project.pbxproj:97-106` (one `PBXFileSystemSynchronizedRootGroup`) |
| Min 6 | Minor | Self-resolved | Contrast figures corrected (4.6:1, ~7.5:1); `--muted` floor noted | Computed from `Theme.swift:46,58` |
| Min 7 | Minor | Self-resolved | Every `sips` command carries `--out` | — |
| Min 8 | Minor | Self-resolved | Covers found by folder, not filename | `Dicitionary_of_Urdu.png` is misspelled inside a correctly named imageset |
| Min 9 | Minor | Self-resolved | GitHub Pages sentence reworded | — |
| Min 10 | Minor | Self-resolved | OAuth wording softened; Step 6 checks authorized domains before pasting | Scopes at `AuthViewModel.swift:176, 211`; auto-added domains `[Unverified]` |
| Min 11 | Minor | Self-resolved | `<html lang="en">` in §4 | — |
| Min 12 | Minor | Self-resolved | SDK version line added to §1 as R1's hook | `project.pbxproj` requirement `12.18.0` |
| Q1 | Question | **Operator decision** | Price reads "$9.99, once" with a US-price note | Chosen: figure + note (recommended). Alt: no figure. Flips if the price is expected to change soon |
| Q3 | Question | Deferred `[Assumption]` | Cover art assumed the operator's own and cleared for the web | Review queue |
| Q4 | Question | Deferred | Dropping the Google photo fetch is a product change, not this plan's | Review queue |

---

## 1. Header

**The change.** A three-page static website for One Word — landing, privacy policy, support — plus the privacy-policy link inside the app that Apple requires alongside it. The site is the App Store record's Privacy Policy URL and Support URL, which "One Word: Daily Vocabulary" needs before submission. Hand-written HTML and CSS, no framework, no build step, no JavaScript, no webfonts, hosted on Firebase Hosting in the app's existing project.

**Read for this plan** (re-grounded from disk this session):

- `Docs/00_Context/PROJECT_CONTEXT.md`, `DESIGN_BRIEF.md` §2–3, `REPO_MAP.md`.
- `Docs/06_Misc/MARKET_FIT_RESEARCH_BRIEF.md` Part 2 §1–5 — the feature inventory and the "deliberately absent" list the landing page must not contradict.
- `Docs/02_Plan/ONBOARDING_PLAN.md` "Draft copy (F3)" and R8 — the widget steps and their unverified menu wording.
- `OneWord/Shared/Theme.swift:42-64` — the Light and Dark palettes; `:168-170` — headwords use the system serif.
- `OneWord/Models/Wordbook.swift` — eight books, names, cover assets. `OneWord/Shared/Premium.swift` — `words` and Bookmarks free; one non-consumable, `com.hariom.swift.oneword.premium`.
- `StoreKit/OneWord.storekit:16-28` — `displayPrice 9.99`, `familyShareable: false`, `NonConsumable`.
- `OneWord/ViewModels/AuthViewModel.swift:112-118` — `displayName`, `email`, `photoURL` exposed from the Firebase user; `:176` Google via `GIDSignIn`; `:210-225` Apple with `.fullName, .email`; `:305-338` `users/{uid}` created with one field, `joined`, over Firestore REST.
- `OneWord/Views/ProfileView.swift:473` — `AsyncImage(url:)` loads the account photo; `RootView.swift:253` shows it in the sidebar chip.
- `OneWord/ViewModels/FeedbackViewModel.swift:26` — `hi.hariom.swift@gmail.com`; `:92-150` — a `complaints` document carries `userID`, `username`, `email`, `message`, `sentAt`; sent only from the button at `FeedbackView.swift:100`.
- `OneWord.xcodeproj/project.pbxproj:654-664` — FirebaseCore, FirebaseAuth, GoogleSignIn are the only linked products; requirement `upToNextMajor 12.18.0` (CoreDiagnostics pings left the SDK at 9.0 `[Inference from release notes]`). `:97-106` — the one synchronized root group is `OneWord/`.
- `OneWord/GoogleService-Info.plist` — project `one-word-a2f3a`, bundle `com.hariom.swift.oneword`.
- `OneWord/Views/SettingsView.swift:189-205` — the Feedback section with its Email row (the privacy row's neighbour); `:53-56` — Settings' Premium bar carries Restore Purchase. `SignInView.swift:39-64` — the sign-in buttons stack.
- `OneWord/Assets.xcassets/AppIcon.appiconset/` (16–512, @1x/@2x; the 512@2x is 1024×1024, no alpha) and the eight `Dictionary_of_*.imageset` PNGs (552–884 px wide, **all with used transparency**).
- `OneWord/Shared/*.json` — counts as of today: words 12,000 · idioms 3,047 · startup 3,038 · philosophy 3,076 · classical 3,193 · urdu 2,435 · emotions 987 · german 96.

### Detected stack

| | Evidence |
|---|---|
| Site: 3 HTML + 1 CSS, no JS, no build | this plan |
| Type: `ui-serif` (New York in Safari on a Mac, Georgia elsewhere); system sans; Devanagari via the system stack | `Theme.swift:168-170` uses the system serif; no webfont keeps the site free of third-party requests |
| Theme: `Theme.light` / `Theme.dark` via `prefers-color-scheme`; colour only on covers | `Theme.swift:42-64`; `Wordbook.swift` header comment |
| Host: Firebase Hosting, project `one-word-a2f3a`, Spark tier, `https://one-word-a2f3a.web.app` until F1 | `GoogleService-Info.plist` |
| Tooling: `firebase-tools` (npm; `node` at `/opt/homebrew/bin`), `webp` (Homebrew, for `cwebp`), `sips` (macOS) | `which firebase` → absent; `which cwebp` → absent; `brew` present |
| App side: SwiftUI, macOS 14.0 on both targets; `Link` is macOS 11+ | `project.pbxproj` `MACOSX_DEPLOYMENT_TARGET = 14.0` ×4 |
| Repo: `site/` at the root, outside the one synchronized group (`OneWord/`) and outside the widget's explicit file list, so invisible to both targets and to the six gates | `project.pbxproj:97-106`; `tools/check_*.sh` compile by explicit path |

**Why not the alternatives.** GitHub Pages' "/docs" source would not find the repo's `Docs/` folder on a case-sensitive runner, renaming it on a case-insensitive disk is its own trap, and the default URL sits under `/One-Word/`. A framework or generator adds a build, a lockfile and `node_modules` for three pages. The Firebase project already exists, so hosting is one `deploy` command and the site lives next to the backend it describes.

---

## 2. Scope and outcome

**Done when:** `https://one-word-a2f3a.web.app/`, `/privacy` and `/support` return 200 over HTTPS; every page reads correctly at 375, 768 and 1280 px in both colour schemes; every link resolves; every image has alt text; the app opens the live privacy page from Settings and from the sign-in screen; the two URLs are saved in App Store Connect (App Information → Privacy Policy URL; the version's Support URL) and on the Google Cloud OAuth consent screen; `xcodebuild … build` and all six gates are green.

**Scope shape:** single change, one PR. A new `site/` folder; three one-line-ish edits under `OneWord/` (a URL constant, a Settings row, a sign-in link); two `.gitignore` lines; one row and one correction in `REPO_MAP.md`; one dossier line in `Docs/README.md`.

**In scope:** the three pages, the stylesheet, favicon and link-preview image from the app icon, the eight covers as WebP, two hero screenshots, Apple's Mac App Store badge, Firebase Hosting config, deployment, the in-app privacy link, wiring the URLs into App Store Connect and the OAuth consent screen.

**Not doing:** a blog, newsletter, changelog, press kit, analytics or tracking, a cookie banner (nothing to consent to), a dark-mode toggle, a contact form (`mailto:`), a web account-deletion form (email suffices; the in-app flow is fork F2 of the Apple sign-in dossier), a terms page (Apple's standard EULA applies), localisation, sitemap or robots file, JavaScript, a CMS, a framework, a build step, a custom 404, any change to the widget or to `Shared/`, any change to what the app collects (Q4 is a product question, deferred).

---

## 3. Architecture fit

**Site.** No layers: three documents and one stylesheet. Shared header and footer are duplicated three times; a templating step earns its place at six pages, not three.

**App.** Three touches, each mirroring something that exists:

| New / changed | Where | Mirrors |
|---|---|---|
| `static let privacyPolicy = URL(string: "https://one-word-a2f3a.web.app/privacy")!` | `OneWord/ViewModels/FeedbackViewModel.swift`, beside `address` at `:26` | `address` — the app's "how to reach us" constants sit together; `SettingsView.swift:205` already reads `FeedbackViewModel.address` from a view |
| A `row("Privacy Policy", …)` wrapping a `Link` | `SettingsView.swift`, inside `section("Feedback", …)` at `:189`, after the Email row at `:194` | the Email row (`:194-205`) |
| A `Link("Privacy Policy", destination:)` | `SignInView.swift`, under the buttons stack at `:39-64` | the Restore button's quiet style at `PremiumView.swift:221-224` (`.buttonStyle(.plain)`, 12 pt, `t.muted`) |

`FeedbackViewModel` stays `import Foundation` + Observation only; a `URL` constant is Foundation. Views keep loading nothing and touching no persistence.

```
site/
├── firebase.json            hosting config: public dir, clean URLs, ignore list
├── .firebaserc              {"projects": {"default": "one-word-a2f3a"}}
└── public/
    ├── index.html           landing
    ├── privacy.html         → /privacy
    ├── support.html         → /support
    ├── style.css            tokens, type, layout — one file
    ├── favicon.png          AppIcon 32@2x (64 px)
    ├── apple-touch-icon.png AppIcon 256
    ├── og.png               AppIcon 512@2x (1024 px square, no alpha — every preview accepts square)
    ├── badge.svg            Apple's "Download on the Mac App Store" badge, unmodified
    └── img/
        ├── hero-light.jpg   medium widget on a light desktop (opaque capture → JPEG is fine)
        ├── hero-dark.jpg    the same on a dark desktop
        └── covers/*.webp    eight painted covers, 480 px wide, alpha kept
```

`firebase.json`:

```json
{
  "hosting": {
    "public": "public",
    "cleanUrls": true,
    "ignore": ["firebase.json", "**/.*"]
  }
}
```

`.gitignore` gains `.firebase/` and `firebase-debug.log`.

---

## 4. Design

The site is the app's **Light appearance** on a page, and its **Dark appearance** after dark. Not a template with the app's colours dropped in.

**Tokens** (`:root`, then a `prefers-color-scheme: dark` block), from `Theme.swift:42-64`:

| token | light | dark |
|---|---|---|
| `--bg` | `#FFFFFF` | `#000000` |
| `--surface` | `#F4F4F4` | `#1A1A1A` |
| `--ink` | `#000000` | `#FFFFFF` |
| `--muted` | `#757575` | `#9A9A9A` |
| `--definition` | `#1C1C1C` | `#E4E4E4` |
| `--example` | `#4A4A4A` | `#BDBDBD` |
| `--rule` | `#BDBDBD` | `#5E5E5E` |
| `--hairline` | `rgba(0,0,0,.11)` | `rgba(255,255,255,.11)` |

Muted on white is about 4.6:1 — AA for normal text, and the floor for the 13 px captions, so `--muted` must not be lightened. Muted on black is about 7.5:1.

**Type.** `--serif: ui-serif, "New York", Georgia, serif` for headwords and section titles; `--sans: -apple-system, system-ui, sans-serif` for everything else. `<html lang="en">`; Hindi spans carry `lang="hi"` and fall through the system stack (Kohinoor Devanagari on a Mac, Nirmala UI on Windows). One display size for the H1 and the sample headword (clamp 40–88 px), body 17 px, small 13 px. Hairline rules between sections, never boxes inside boxes.

**Layout.** One centred column, max 1040 px, 16 px side gutter on phones. The shelf is a row of eight covers that wraps to two rows on narrow screens. The hero puts the headline beside the widget screenshot on desktop and stacks on phones. No horizontal scroll at 375 px.

**Colour.** None, except the covers and the badge.

**Ponytail:** `ui-serif` gives the app's exact face in Safari on a Mac and Georgia elsewhere. Upgrade if Chrome's Georgia jars: self-host Newsreader (`Theme.swift:12` names it as the intended face) as one variable woff2, about 100 KB, first in `--serif`.

**Build note.** Load the `design-taste-frontend` skill before writing the HTML; the constraints above are its brief.

---

## 5. Pages

### 5a. Landing (`index.html`)

Six sections. Copy is in §9 F2.

1. **Hero.** Eyebrow, H1, one paragraph, the badge, a one-line price note. Beside it the medium widget on a desktop, swapped by scheme: `<picture><source srcset="img/hero-dark.jpg" media="(prefers-color-scheme: dark)"><img src="img/hero-light.jpg" alt="…"></picture>`.
2. **One entry, whole.** One real word laid out as the app's home screen lays it out: term, part of speech, Hindi line, definition, example — in HTML, not a screenshot. Take the entry verbatim from `words.json`; the design brief's `trade` / `global` samples are known-real fallbacks. Caption: the Hindi line can be hidden in Settings.
3. **The shelf.** Eight covers, name and rounded count under each (German: no count, F3). One paragraph: Everyday English is free; the other seven come with Premium.
4. **Also in the app.** Six one-line items: search across every book (⌘K); history, any past day's word; bookmarks; a reading log; save a word from any Mac app; up to three related words under an entry. Nothing from the market brief's §5.
5. **Plans.** Two columns mirroring the app's PlanPair. Free: Everyday English, the widget, search, history, bookmarks. Premium: every dictionary, $9.99 once (US price), no subscription, restores on any Mac signed into the same Apple Account.
6. **Footer.** Badge again, "macOS 14 or later", Privacy · Support, the support email, © 2026.

`<head>`: title "One Word: Daily Vocabulary for Mac", one-sentence description, `og:title`, `og:description`, `og:image` = `/og.png`, `twitter:card` = `summary`, `<meta name="color-scheme" content="light dark">`, `theme-color` for both schemes.

### 5b. Privacy (`privacy.html`)

Grounded in the code; the operator reads it once before it goes live. Not legal advice.

**Draft:**

> **Privacy Policy — One Word: Daily Vocabulary**
> Effective 2026-09-27
>
> **The short version.** Every word in One Word ships inside the app. Nothing you read, search, bookmark or learn leaves your Mac. The app connects to a server for three things only: signing you in, showing your account picture, and sending a message you choose to send from the Feedback screen.
>
> **What stays on your Mac.** Your bookmarks, your reading log, your settings, your profile name and the avatar you pick, words you save from other apps, and which dictionary each widget shows. These live in the app's own storage and are never uploaded. The app has no analytics, no advertising and no crash-reporting service.
>
> **Signing in.** One Word uses Firebase Authentication, a Google service, to sign you in with Google or with Apple. When you sign in, Firebase gives the app a user ID, your email address and your display name. For Google accounts it also passes a link to your profile picture, which the app loads from Google to show on your profile; you can choose a built-in avatar instead. If you sign in with Apple and hide your email, the app receives Apple's relay address instead. The app records one thing about your account on its server: the date you joined. Firebase stores your sign-in record on Google Cloud. *(Step 1: read the Firestore region in the console; if it is worth naming, add "in the United States" or the real region here.)*
>
> **Feedback.** If you send a message from the Feedback screen, the app stores the message together with your user ID, your profile name, your email address and the time you sent it, so we can reply. Nothing is sent unless you press Send. You can also email us instead.
>
> **Purchases.** Premium is a one-time purchase made through the Mac App Store. Apple handles payment; the app never sees your card or your Apple Account details. The app keeps a single "unlocked" flag on your Mac.
>
> **Who else handles your data.** Sign-in and storage are provided by Firebase, a Google service, under Google's privacy terms. We share your data with no one else, and we never sell it.
>
> **How long we keep it.** Your sign-in record, your join date and any feedback you sent are kept until you ask us to delete your account, so we can support you. Nothing expires on its own.
>
> **This website.** It sets no cookies, runs no scripts and loads nothing from third parties. It is served by Firebase Hosting, which keeps ordinary server logs (IP address, page requested, time) for a limited period, as any web host does.
>
> **Deleting your account.** Email `hi.hariom.swift@gmail.com` from the address on your account and we will delete your sign-in record, including your account picture link, your join date and any feedback you sent, within 30 days. *(When in-app deletion ships — F2 in the Apple sign-in dossier — add: "or choose Delete Account in the app's Profile.")*
>
> **Children.** One Word is not directed at children under 13 and does not knowingly collect information from them.
>
> **Changes.** If this policy changes, the date at the top changes with it.
>
> **Contact.** `hi.hariom.swift@gmail.com`

**App Store Connect → App Privacy** must match this page: Contact Info (email address, name) and Identifiers (user ID) linked to identity, used for App Functionality; User Content → Customer Support (the feedback message) linked to identity; the profile-picture link declared under User Content → Other User Content `[Inference: Apple has no category for a photo URL]`; no data used for tracking; no third-party advertising. Fill the label from this page.

### 5c. Support (`support.html`)

A contact line first (App Review opens this URL and looks for a way to reach a human), then the FAQ.

**Contact.** `hi.hariom.swift@gmail.com` as a `mailto:`, plus "or send a note from Feedback inside the app".

**FAQ — eight questions:**

1. *How do I put the word on my desktop?* Right-click the desktop, choose Edit Widgets, search One Word, drag "Word of the Day" out — small, medium or large. *(Verify the menu wording on macOS 14 and current before publishing; ONBOARDING_PLAN R8.)*
2. *Can a widget show a different dictionary?* Right-click the widget, choose Edit, pick the dictionary. Each widget keeps its own.
3. *What is free and what is Premium?* Everyday English, the widget, search, history and bookmarks are free. The other seven dictionaries unlock together for $9.99, once (US price; the App Store shows yours).
4. *I bought Premium on another Mac.* Profile → Settings → Premium → Restore Purchase, signed into the same Apple Account.
5. *Can I hide the Hindi line?* Yes: Settings → The entry → Hindi meaning. The example sentence can be hidden the same way.
6. *Why do I need to sign in?* Sign-in keeps your account on record for support. The widget works without it. The privacy policy says exactly what is stored.
7. *How do I delete my account?* Email us from your account's address. *(Swap for the in-app instructions when F2 ships.)*
8. *What does it need?* macOS 14 Sonoma or later. Mac only.

---

## 6. Assets

| Asset | Source | Command |
|---|---|---|
| `favicon.png` | `AppIcon.appiconset/icon-mac-32x32@2x.png` | copy |
| `apple-touch-icon.png` | `icon-mac-256x256.png` | copy |
| `og.png` | `icon-mac-512x512@2x.png` (1024², no alpha) | copy |
| `img/covers/<Name>.webp` | the one PNG inside each `Dictionary_of_*.imageset` (found by folder — Urdu's file is misspelled) | below |
| `img/hero-light.jpg`, `hero-dark.jpg` | ⌘⇧4 region captures of the medium widget on a desktop, light and dark, from the Xcode-run app | `sips -Z 1600 -s format jpeg -s formatOptions 82 in.png --out site/public/img/hero-light.jpg` |
| `badge.svg` | Apple's App Store marketing guidelines page, "Download on the Mac App Store", black | download; do not edit; keep Apple's clear space |

Covers, alpha kept:

```bash
cd "/Users/hariom/Desktop/One Word" && mkdir -p site/public/img/covers && for d in OneWord/Assets.xcassets/Dictionary_of_*.imageset; do f=$(find "$d" -name '*.png' | head -1); n=$(basename "$d" .imageset); sips -Z 480 "$f" --out "$TMPDIR/$n.png" >/dev/null && cwebp -q 80 "$TMPDIR/$n.png" -o "site/public/img/covers/$n.webp"; done
```

Badge link: `https://apps.apple.com/app/id<APPLE_ID>`, the Apple ID from App Store Connect → App Information → General. It resolves the day the app goes live; a 404 before that costs nothing and leaves no launch-day edit to forget. If the field is blank until a build is attached, leave the badge unlinked and add the `href` when it appears.

Page-weight ceiling: 1 MB transferred for the landing page (one hero variant, eight covers, icons; `og.png` loads only for link previews). Eight WebP covers should land near 400 KB in total `[Inference from the 47 KB JPEG test at the same size]`. The free tier moves 360 MB a day; see R2.

---

## 7. Implementation steps

### Step 0: tools (once)

```bash
npm install -g firebase-tools
```

```bash
brew install webp
```

```bash
firebase login
```

- `firebase login` opens a browser; sign in with the Google account that owns project `one-word-a2f3a`.
- **Done when:** `firebase projects:list` shows `one-word-a2f3a` and `cwebp -version` prints a version. If `brew install webp` fails on this Mac, take the M1 alternative: PNG covers at 240 px (`sips -Z 240`), ~70–90 KB each, and skip `cwebp`.

### Step 1: scaffold and the two required pages

- Create `site/firebase.json`, `site/.firebaserc`, `site/public/style.css` with §4's tokens and type, and the two `.gitignore` lines.
- **Firestore region check:** Firebase console → Firestore → Data; note the database location. Name it in §5b's "Signing in" only if you want to; the draft is correct without it.
- Write `privacy.html` and `support.html` from §5b–c. These are the release blockers; they ship first.
- **Done when:** `cd site && firebase emulators:start --only hosting` serves `http://localhost:5000/privacy` and `/support` with clean URLs; both read correctly in the built-in browser at 375, 768 and 1280 px, light and dark; the `mailto:` opens Mail.

### Step 2: assets

- Copy the icons, convert the covers and the two hero shots per §6, download the badge.
- **Done when:** every file in `img/` opens; the covers show transparent corners on a dark background (open one in Preview with a dark window, or check in Step 3's dark pass); the landing page's transferred weight is under 1 MB (the browser's network panel, or `du -ch site/public/img/covers site/public/img/hero-light.jpg site/public/*.png site/public/style.css`).

### Step 3: the landing page

- Write `index.html` per §5a with F2's copy. Load `design-taste-frontend` first.
- **Done when:** all three pages share a header and footer; every `href` resolves in the emulator (`grep -oh 'href="[^"#]*"' site/public/*.html | sort -u`, then click each); every `<img>` has `alt`; headings run H1 → H2 with no skips; no horizontal scroll at 375 px; the hero swaps images with the scheme; the covers have no white corners in dark mode.

### Step 4: deploy

```bash
cd "/Users/hariom/Desktop/One Word/site" && firebase deploy --only hosting
```

- **Done when:** `curl -sI https://one-word-a2f3a.web.app/privacy | head -1`, and the same for `/support` and `/`, print `200`.

### Step 5: the in-app privacy link

- `FeedbackViewModel.swift`: beside `address` (`:26`), add `static let privacyPolicy = URL(string: "https://one-word-a2f3a.web.app/privacy")!`. Under F1, this is the one line that changes.
- `SettingsView.swift`: inside `section("Feedback", …)` (`:189`), after the Email row (`:194-205`), add `row("Privacy Policy", "What the app keeps, and what it doesn't.", t) { Link(destination: FeedbackViewModel.privacyPolicy) { Image(systemName: "arrow.up.right") } }` — the same `row` shape and glyph style as Email. Give the `Link` `.accessibilityLabel("Open the privacy policy")`.
- `SignInView.swift`: under the buttons stack (`:39-64`), add `Link("Privacy Policy", destination: FeedbackViewModel.privacyPolicy).buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(t.muted)`, the quiet style of `PremiumView.swift:221-224`. In DEBUG it sits below the "Skip sign-in (Debug)" button (`:64`).
- Isolation: `Link` is a SwiftUI view on the main actor; no `Task`, no state, no view model change beyond the constant. `Shared/` and the widget untouched.
- **Done when:** `xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build` is green; `for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done` is green; run from Xcode, both links open the live page in the default browser.

### Step 6: wire the URLs

- App Store Connect → App Information → Privacy Policy URL = `…/privacy`. The version page → Support URL = `…/support`; Marketing URL = `…/`.
- App Store Connect → App Privacy: answer from §5b.
- Google Cloud Console → OAuth consent screen: confirm `one-word-a2f3a.web.app` is listed under Authorized domains (Firebase is believed to add its Hosting domains automatically `[Unverified]`; add it by hand if not), then Application home page = `…/`, Privacy policy link = `…/privacy`. The app's scopes are the basic three (`AuthViewModel.swift:176, 211`), so Google does not require verification, but the consent screen asks for the links before Production.
- **Done when:** all fields are saved and the record no longer flags a missing privacy or support URL.

### Step 7: keep `00_Context` current

- `REPO_MAP.md`: add a `site/` row to the top-level tree ("public website — landing, privacy, support; Firebase Hosting; not part of any Xcode target"); under "Where things get referenced from outside the code" add: the privacy page names the Firestore fields and the photo fetch, so a change to `AuthViewModel.publishJoinDate`, `FeedbackViewModel.send`, `photoURL`'s use, or the linked Firebase products means re-reading `privacy.html`; correct "Adding files" to say only `OneWord/` is a synchronized group (`project.pbxproj:97-106`) and the widget target lists its files explicitly.
- `Docs/README.md`: the dossier line (done with this plan).
- **Done when:** both files mention `site/` and the synchronized-group line is right.

---

## 8. Test plan

No automated tests: the site has no logic and the app change is three declarative lines. The checks are the done-whens above, plus after deploy:

| Check | How |
|---|---|
| Three URLs live over HTTPS | `curl -sI` each → `200` |
| Clean URLs | `/privacy` serves; `/privacy.html` redirects (Firebase's `cleanUrls` behaviour) |
| Both schemes, three widths | built-in browser, `colorScheme` light then dark, at 375 / 768 / 1280 |
| Covers in dark mode | no white corners or spine halo on the black page |
| Link preview | paste the URL into iMessage or Slack: title, description, icon appear |
| Contrast | the palette passes by construction (§4); spot-check with the browser's accessibility panel |
| Keyboard | Tab reaches the badge, every FAQ link and the mailto in order; focus ring visible |
| In-app links | Xcode run: Settings → Feedback → Privacy Policy opens the live page; sign out, the sign-in screen's link does the same; VoiceOver reads "Open the privacy policy" on the Settings row |
| Build + gates | green after Step 5, since `OneWord/` changed |

**Hard to test:** how App Review reads the support page. Mitigation: the contact line is the first thing on it.

---

## 9. Decision forks (operator-owned)

Taken this session, applied in the plan: **M1** WebP covers · **M4** in-app link in this PR · **Q1** "$9.99, once" with a US-price note. Still open:

| # | Fork | Default | Take the other side when… |
|---|---|---|---|
| F1 | Domain | **Ship on `one-word-a2f3a.web.app`**; paste that into App Store Connect and into `FeedbackViewModel.privacyPolicy` | …you own or want a domain now. Firebase Hosting → Add custom domain, two DNS records, SSL automatic. Then update App Store Connect, the consent screen and the one Swift constant; nothing in the site changes because every link is relative. |
| F2 | Copy | **The drafts below** | …you have your own voice for it. The structure does not depend on the words. |
| F3 | German on the shelf | **Show all eight covers; round counts and omit German's** (96 words, MARKET_FIT §7) | …you'd rather hide German from the site until it grows. One cover fewer in §5a-3, one name fewer in the shelf line. |

**Draft copy (F2):**

- **Hero.** Eyebrow "For macOS 14 and later". H1 "One new word a day, on your desktop." Body "A widget that shows a word each morning with its meaning in Hindi, a definition and an example. Nothing to open, nothing to keep up with." Under the badge: "Free. Seven more dictionaries for $9.99, once — US price; the App Store shows yours."
- **One entry, whole.** Eyebrow "Every word, whole". Title "The word, its meaning, and how it's used." Caption "The Hindi line is there for readers who want it. It can be turned off in Settings."
- **The shelf.** Eyebrow "The shelf". Title "Eight dictionaries." Body "Everyday English is free: 12,000 words with Hindi meanings. Idioms, Corporate Slang, Emotions, Philosophy, Classical English, Urdu written in Devanagari, and German come with Premium. Pick one and your word of the day comes from it." Under the covers: Everyday English "12,000 words" · Idioms "3,000+ idioms" · Corporate Slang "3,000+ terms" · Emotions "900+ words" · Philosophy "3,000+ entries" · Classical English "3,000+ phrases" · Urdu "2,400+ words" · German: no count.
- **Also in the app.** Eyebrow "Also in the app". Six items as §5a-4, each one sentence; the last reads "Up to three related words under an entry, so you can keep going."
- **Plans.** Eyebrow "Plans". Columns as §5a-5. Premium footnote "A one-time purchase through the Mac App Store. No subscription. $9.99 is the US price; the App Store shows local pricing."
- **Footer.** "One Word: Daily Vocabulary · macOS 14 or later · Privacy · Support · hi.hariom.swift@gmail.com"

Counts are rounded down so they stay true as books grow. To refresh: `for f in OneWord/Shared/*.json; do printf "%s " "$(basename $f .json)"; python3 -c "import json;print(len(json.load(open('$f'))))"; done`.

---

## 10. Risks and exits

| # | Risk | Likelihood | Impact | Signal | Exit |
|---|---|---|---|---|---|
| R1 | Privacy page drifts from the code: in-app deletion ships, a Firestore field is added, Analytics gets linked, the photo fetch is removed (Q4) | Medium | High | A diff touching `AuthViewModel.swift:112-118, 305-338`, `FeedbackViewModel.swift:92-150`, `ProfileView.swift:473`, or the Firebase products in `project.pbxproj` | The REPO_MAP line from Step 7; re-read `privacy.html` in that PR and bump the effective date |
| R2 | Launch traffic exceeds the free tier's 360 MB/day; Hosting pauses the site and the App Store's privacy link dies for the day | Low | Medium | Firebase console usage graph; a quota page | Keep the page under 1 MB (§6). Before a launch post, switch the project to Blaze: static overage is cents per GB, no minimum |
| R3 | Apple's badge used outside its licence | Low | Low | — | SVG unmodified; link only to `apps.apple.com` |
| R4 | Widget-gallery wording in FAQ 1 differs by macOS version | Medium | Low | Steps don't match a test Mac | Change the copy only (ONBOARDING_PLAN R8) |
| R5 | Support page read before the site is deployed | — | High | — | Step 4 precedes Step 6 |
| R6 | `firebase login` lands on the wrong Google account | Low | Low | `firebase projects:list` lacks the project | `firebase logout`, log in with the account that owns the console |
| R7 | `brew install webp` unavailable or broken on the build Mac | Low | Low | Step 0's done-when fails | PNG covers at 240 px (M1's alternative); the shelf softens on Retina, nothing else changes |
| R8 | The Firestore region turns out to be outside the US and someone re-adds "United States" from habit | Low | Medium | — | §5b's draft names no region; Step 1's check is the only place a region enters |

---

## 11. Sequencing summary and verification

0 (tools) → 1 (scaffold, privacy, support) → 2 (assets) → 3 (landing) → 4 (deploy) → 5 (in-app link, build + gates) → 6 (App Store Connect + consent screen) → 7 (docs). Steps 1–3 are local; Step 0 and Step 4 need the operator's browser; Step 6 needs App Store Connect and Google Cloud Console. The first reversible move is Step 1, and privacy and support are live before the landing page is polished, so the App Store record is never waiting on design.

End to end: three `200`s from `curl`; both schemes at three widths in the built-in browser; the covers clean in dark mode; both in-app links open the live page; the URLs saved in App Store Connect and on the consent screen; `xcodebuild … build` green; the six gates green.

**Files touched (absolute):**

- `/Users/hariom/Desktop/One Word/site/firebase.json`, `site/.firebaserc` — new
- `/Users/hariom/Desktop/One Word/site/public/index.html`, `privacy.html`, `support.html`, `style.css` — new
- `/Users/hariom/Desktop/One Word/site/public/favicon.png`, `apple-touch-icon.png`, `og.png`, `badge.svg`, `img/**` — new
- `/Users/hariom/Desktop/One Word/OneWord/ViewModels/FeedbackViewModel.swift` — one constant beside `:26`
- `/Users/hariom/Desktop/One Word/OneWord/Views/SettingsView.swift` — one row after `:205`
- `/Users/hariom/Desktop/One Word/OneWord/Views/SignInView.swift` — one `Link` under `:64`
- `/Users/hariom/Desktop/One Word/.gitignore` — two lines
- `/Users/hariom/Desktop/One Word/Docs/00_Context/REPO_MAP.md` — one row, one line, one correction
- `/Users/hariom/Desktop/One Word/Docs/README.md` — one dossier line

---

## 12. Operator review queue

Decisions applied on the recommended option, asked and confirmed live this session. Listed so a later reader can see they were choices:

| Decision | Applied | Alternative | Flips when |
|---|---|---|---|
| M1 cover format | WebP with alpha via `cwebp` | PNG at 240 px, no new tools | `brew install webp` unavailable (R7) |
| M4 in-app privacy link | In this PR, Step 5 | Follow-up PR on the release checklist | The PR must stay site-only |
| Q1 price on the page | "$9.99, once" + US-price note | No figure | A price change is expected soon |

## 13. Remaining, deferred, and assumptions

- **Firestore region** `[Unverified]` — the draft names none; Step 1's console look may add it. Nothing else depends on it.
- **OAuth authorized domains** `[Unverified]` — Firebase is believed to add its Hosting domains; Step 6 checks before pasting the links.
- **Cover art rights** `[Assumption]` — the painted covers are taken to be the operator's own and cleared for the web (audit Q3). If any were licensed for the app only, swap the shelf for HTML-drawn spines in the book colours from `Wordbook.swift`.
- **The Google photo fetch** (audit Q4) — deferred; dropping `AsyncImage` in favour of the bundled avatars would remove a connection and a sentence from the policy. A product change for its own plan; R1 covers the policy if it lands.
- **Apple ID for the badge** `[Assumption]` — readable in App Store Connect now; §6 says what to do if not.
- **Family Sharing** — not claimed; `OneWord.storekit:17` is false. Add a line if it is turned on.
- **App Privacy category for the picture link** `[Inference]` — declared under Other User Content; Apple's form may steer it elsewhere.
- **Firestore deletion is manual** — the 30-day promise is a console task: delete the Auth user, `users/{uid}`, and any `complaints` with that `userID`. Nothing automates it and nothing needs to at this scale.
