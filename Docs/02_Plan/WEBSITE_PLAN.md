# Website: implementation plan

> Plan for One Word's public website. Written 2026-09-27 against `main` at `675065b`.

**The change.** A three-page static website for One Word: a landing page, a privacy policy and a support page. It is the App Store record's Privacy Policy URL and Support URL, which App Store Connect requires before "One Word: Daily Vocabulary" can be submitted, and it is the page the Mac App Store badge points back to. Hand-written HTML and CSS, no framework, no build step, no JavaScript, hosted on Firebase Hosting in the app's existing Firebase project.

**Upstream.** No brainstorm or strategy doc. This plan comes from the operator's request, the App Store record created 2026-09-27, the market-fit brief and the code. §9 marks the calls that belong to the operator.

**Read for this plan** (re-grounded from disk):

- `Docs/00_Context/PROJECT_CONTEXT.md`, `DESIGN_BRIEF.md` §2–3 (the feeling, the Light/Dark appearances), `REPO_MAP.md`.
- `Docs/06_Misc/MARKET_FIT_RESEARCH_BRIEF.md` Part 2 §1–5 — the feature inventory and what is deliberately absent. The landing page must not claim anything in §5.
- `Docs/02_Plan/ONBOARDING_PLAN.md` "Draft copy (F3)" — the widget steps and the shelf line, reused here.
- `OneWord/Shared/Theme.swift:42-64` — the Light and Dark palettes the site copies. `:168-170` — headwords use the system serif (New York).
- `OneWord/Models/Wordbook.swift` — the eight books, their names and cover assets. `OneWord/Shared/Premium.swift` — what is free (`words`, Bookmarks), product id, one non-consumable.
- `OneWord/ViewModels/AuthViewModel.swift:157-330` — Google and Apple sign-in through Firebase Auth; `users/{uid}` holds one field, `joined`.
- `OneWord/ViewModels/FeedbackViewModel.swift:26,92-135` — support address `hi.hariom.swift@gmail.com`; a `complaints` document carries `userID`, `username`, `email`, `message`, a client timestamp.
- `OneWord.xcodeproj/project.pbxproj:654-664` — the only Firebase products linked are FirebaseCore and FirebaseAuth (plus GoogleSignIn). No Analytics, no Crashlytics. The privacy policy can say so.
- `OneWord/GoogleService-Info.plist` — Firebase project `one-word-a2f3a`, bundle `com.hariom.swift.oneword`.
- `OneWord/Assets.xcassets/AppIcon.appiconset/`, `Dictionary_of_*.imageset/` — the icon sizes and the eight painted covers, reused as-is.

### Detected stack (for the site, not the app)

| | |
|---|---|
| Pages | 3 static HTML files + 1 CSS file. No JS. |
| Type | System serif for headwords (`ui-serif` = New York in Safari on a Mac, Georgia elsewhere); system sans for body; Devanagari falls through the system stack. **No webfonts**, so the page makes no third-party request and the privacy page stays trivially true. |
| Theme | Light = `Theme.light`, dark = `Theme.dark` via `prefers-color-scheme`. Colour only on the eight covers, as in the app. |
| Host | Firebase Hosting, project `one-word-a2f3a`, free (Spark) tier. URL `https://one-word-a2f3a.web.app` until a domain is chosen (F1). |
| Tooling | `firebase-tools` from npm (node is at `/opt/homebrew/bin/node`; the CLI is not installed yet). Images resized with `sips`, which ships with macOS. Nothing else installed. |
| Repo | `site/` at the repo root. Xcode's synchronized groups are `OneWord/` and `OneWordWidget/` only, so `site/` is invisible to both targets and to the six gates. |

**Why not the alternatives.** GitHub Pages "from /docs" collides with the existing `Docs/` folder on the case-sensitive runner, and the default URL sits under `/One-Word/`. A framework or static-site generator adds a build, a lockfile and a node_modules for three pages. The Firebase project already exists, so hosting is one `deploy` command and the site lives next to the backend it describes.

---

## 2. Scope and outcome

**Done when:** `https://one-word-a2f3a.web.app/`, `/privacy` and `/support` return 200 over HTTPS, read correctly at phone, tablet and desktop widths in both colour schemes, every link resolves, every image has alt text, and the two URLs are pasted into App Store Connect (App Information → Privacy Policy URL; the version's Support URL) and into the Google Cloud OAuth consent screen for the sign-in client. `xcodebuild … build` and the six gates are untouched and still green.

**Scope shape:** one change (one PR). A new `site/` folder, two `.gitignore` lines, one row in `REPO_MAP.md`, one dossier line in `Docs/README.md`.

**In scope:** the three pages, the stylesheet, favicon and link-preview image from the existing app icon, the eight covers, two hero screenshots, the Mac App Store badge, Firebase Hosting config, deployment, wiring the URLs into App Store Connect and the OAuth consent screen.

**Not doing:** a blog, a newsletter, a changelog page, a press kit, analytics or any tracking, a cookie banner (nothing to consent to), a dark-mode toggle (the system decides), a contact form (`mailto:`), a web account-deletion form (email suffices; the in-app flow is the real fix and is fork F2 of the Apple sign-in dossier), a terms page (Apple's standard EULA applies when none is supplied), localisation of the site, a sitemap or robots file, JavaScript of any kind, a CMS, a framework, a build step, a custom 404 page.

---

## 3. Site structure

```
site/
├── firebase.json            hosting config: public dir, clean URLs, ignore list
├── .firebaserc              {"projects": {"default": "one-word-a2f3a"}}
└── public/
    ├── index.html           landing
    ├── privacy.html         privacy policy         → served at /privacy
    ├── support.html         support + FAQ          → served at /support
    ├── style.css            tokens, type, layout — one file
    ├── favicon.png          AppIcon 32@2x (64 px)
    ├── apple-touch-icon.png AppIcon 256
    ├── og.png               AppIcon 512@2x (1024 px square; every link preview accepts square)
    ├── badge.svg            Apple's "Download on the Mac App Store" badge, unmodified
    └── img/
        ├── hero-light.jpg   medium widget on a light desktop
        ├── hero-dark.jpg    the same on a dark desktop
        └── covers/          eight painted covers, 480 px wide, JPEG q80
```

Shared header and footer are duplicated across the three files. Three copies of eight lines is cheaper than a templating step; revisit if the site passes six pages.

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

Two `.gitignore` lines: `.firebase/` (the CLI's deploy cache) and `firebase-debug.log`.

---

## 4. Design

The site is the app's **Light appearance** on a page, and its **Dark appearance** after dark. Not a marketing template with the app's colours dropped in.

**Tokens** (`:root`, then a `prefers-color-scheme: dark` block), straight from `Theme.swift:42-64`:

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

Muted on white is 4.6:1 and muted on black is 5.9:1, so every text colour passes AA at body size without adjustment.

**Type.** `--serif: ui-serif, "New York", Georgia, serif` for headwords and section titles; `--sans: -apple-system, system-ui, sans-serif` for everything else; Hindi text gets `lang="hi"` and falls through the system stack (Kohinoor Devanagari on a Mac, Nirmala UI on Windows). One display size for the H1 and the sample headword (clamp between 40 and 88 px), one body size at 17 px, one small size at 13 px for eyebrows and captions. Hairline rules between sections, never boxes inside boxes.

**Layout.** A single centred column, max 1040 px, 16 px side gutter on phones, generous vertical space between sections. The shelf is a horizontal row of eight covers that wraps to two rows on narrow screens. The hero puts the headline beside the widget screenshot on desktop and stacks on phones. No horizontal scroll at 375 px.

**Colour.** None, except the covers and the App Store badge. The app spends its only hue on book cloth; so does the site.

**Ponytail:** `ui-serif` gives the app's exact face in Safari on a Mac, which is most of a Mac-only app's visitors, and Georgia elsewhere. Upgrade path if Chrome's Georgia looks wrong beside the app: self-host Newsreader (the face `Theme.swift:12` names as the intended one) as one variable woff2, about 100 KB, and put it first in `--serif`.

**Build note.** Load the `design-taste-frontend` skill before writing the HTML. The constraint set above is the brief it works inside.

---

## 5. Pages

### 5a. Landing (`index.html`)

Six sections, top to bottom. Draft copy is in §9 F2 and belongs to the operator.

1. **Hero.** Eyebrow, H1, one paragraph, the Mac App Store badge, a one-line price note. Beside it the medium widget on a desktop, swapped by scheme with `<picture>` and a `media="(prefers-color-scheme: dark)"` source. Below the fold nothing else competes.
2. **One entry, whole.** One real word laid out exactly as the app's home screen lays it out: term, part of speech, Hindi line, definition, example. Rendered in HTML, not a screenshot, so it is the app's typography and stays crisp at every size. Take the entry verbatim from `words.json`; the design brief's `trade` / `global` samples are known-real fallbacks. A caption says the Hindi line can be hidden in Settings.
3. **The shelf.** Eight covers in a row, name and rounded count under each. One paragraph: Everyday English is free; the other seven come with Premium.
4. **Also in the app.** Six one-line items, no icons needed: search across every book (⌘K); history, any past day's word; bookmarks; a reading log; save a word from any Mac app; three related words under every entry. Nothing from the market brief's §5 "deliberately absent" list.
5. **Plans.** Two columns mirroring the app's PlanPair. Free: Everyday English, the widget, search, history, bookmarks. Premium: every dictionary, $9.99 once, no subscription, restores on any Mac signed into the same Apple Account.
6. **Footer.** Badge again, "macOS 14 or later", Privacy · Support, the support email, © 2026.

`<head>`: title "One Word: Daily Vocabulary for Mac", a one-sentence description, `og:title`, `og:description`, `og:image` = `/og.png`, `twitter:card` = `summary`, `<meta name="color-scheme" content="light dark">`, `theme-color` for both schemes.

### 5b. Privacy (`privacy.html`)

Plain prose under six short headings. Everything below is grounded in the code; the operator reads it once before it goes live because a privacy policy is a promise. Not legal advice.

**Draft:**

> **Privacy Policy — One Word: Daily Vocabulary**
> Effective 2026-09-27
>
> **The short version.** Every word in One Word ships inside the app. Nothing you read, search, bookmark or learn leaves your Mac. The app talks to a server for two things only: signing you in, and sending a message you choose to send from the Feedback screen.
>
> **What stays on your Mac.** Your bookmarks, your reading log, your settings, your profile name and avatar, words you save from other apps, and which dictionary each widget shows. These live in the app's own storage and are never uploaded. The app has no analytics, no advertising and no crash-reporting service.
>
> **Signing in.** One Word uses Firebase Authentication (a Google service) to sign you in with Google or with Apple. When you sign in, Firebase gives the app a user ID, your email address and your display name. If you sign in with Apple and hide your email, the app receives Apple's relay address instead. The app records one thing about your account on its server: the date you joined. Sign-in data is stored by Firebase on Google Cloud in the United States.
>
> **Feedback.** If you send a message from the Feedback screen, the app stores the message together with your user ID, your profile name, your email address and the time you sent it, so we can reply. Nothing is sent unless you press Send. You can also email us instead.
>
> **Purchases.** Premium is a one-time purchase made through the Mac App Store. Apple handles payment; the app never sees your card or your Apple Account details. The app keeps a single "unlocked" flag on your Mac.
>
> **This website.** It sets no cookies, runs no scripts and loads nothing from third parties. It is served by Firebase Hosting, which keeps ordinary server logs (IP address, page requested, time) for a limited period as any web host does.
>
> **Deleting your account.** Email `hi.hariom.swift@gmail.com` from the address on your account and we will delete your sign-in record, your join date and any feedback you sent, within 30 days. *(When in-app deletion ships — F2 in the Apple sign-in dossier — add: "or choose Delete Account in the app's Profile.")*
>
> **Children.** One Word is not directed at children under 13 and does not knowingly collect information from them.
>
> **Changes.** If this policy changes, the date at the top changes with it.
>
> **Contact.** `hi.hariom.swift@gmail.com`

App Store Connect's **App Privacy** answers must match this page: Contact Info (email address, name) and Identifiers (user ID) linked to identity, used for App Functionality; User Content (the feedback message) linked to identity; no data used for tracking; no third-party advertising. Fill the label from this page, not from memory.

### 5c. Support (`support.html`)

A contact line first (App Review opens this URL and looks for a way to reach a human), then the FAQ.

**Contact.** `hi.hariom.swift@gmail.com` as a `mailto:`, plus "or send a note from Feedback inside the app".

**FAQ — eight questions, one short answer each:**

1. *How do I put the word on my desktop?* Right-click the desktop, choose Edit Widgets, search One Word, drag "Word of the Day" out, small, medium or large. *(Verify the menu wording on macOS 14 and current before publishing — ONBOARDING_PLAN R8.)*
2. *Can a widget show a different dictionary?* Right-click the widget, choose Edit, pick the dictionary. Each widget keeps its own.
3. *What is free and what is Premium?* Everyday English, the widget, search, history and bookmarks are free. The other seven dictionaries unlock together for $9.99, once.
4. *I bought Premium on another Mac.* Settings → Premium → Restore Purchase, signed into the same Apple Account.
5. *Can I hide the Hindi line?* Yes: Settings, then turn off Hindi. The example and part of speech can be hidden the same way.
6. *Why do I need to sign in?* Sign-in keeps your account on record for support. The widget works without it. See the privacy policy for exactly what is stored.
7. *How do I delete my account?* Email us from your account's address. *(Swap for the in-app instructions when F2 ships.)*
8. *What does it need?* macOS 14 Sonoma or later. It is Mac only.

---

## 6. Assets

| Asset | Source | Command |
|---|---|---|
| `favicon.png` | `AppIcon.appiconset/icon-mac-32x32@2x.png` | copy |
| `apple-touch-icon.png` | `icon-mac-256x256.png` | copy |
| `og.png` | `icon-mac-512x512@2x.png` | copy |
| `img/covers/*.jpg` | largest PNG in each `Dictionary_of_*.imageset` | `sips -Z 480 -s format jpeg -s formatOptions 80` |
| `img/hero-light.jpg`, `hero-dark.jpg` | screenshots of the medium widget on a desktop, light and dark, from the Xcode-run app | ⌘⇧4 region at 2×, then `sips -Z 1600 -s format jpeg -s formatOptions 82` |
| `badge.svg` | Apple's App Store marketing guidelines page, "Download on the Mac App Store", black | download; do not edit; keep Apple's clear space |

Badge link: `https://apps.apple.com/app/id<APPLE_ID>`, the Apple ID from App Store Connect → App Information → General. It is on the record now and resolves the day the app goes live; a 404 for a few days before launch costs nothing and leaves no launch-day edit to forget.

Page-weight ceiling: 1 MB for the landing page in total. The free tier moves 360 MB a day, so that is about 360 landing-page loads a day before Hosting pauses. See R2.

---

## 7. Implementation steps

### Step 1: scaffold and the two required pages

- Create `site/firebase.json`, `site/.firebaserc`, `site/public/style.css` with the tokens and type from §4, and the two `.gitignore` lines.
- Write `privacy.html` and `support.html` from §5b–c. These are the release blockers; they ship first.
- **Done when:** `python3 -m http.server -d site/public 8000` serves both pages; they read correctly in the built-in browser at 375, 768 and 1280 px, light and dark; the `mailto:` opens Mail.

### Step 2: assets

- Copy the icons, resize the covers and the two hero shots per §6, download the badge.
- **Done when:** `du -sh site/public` is under 1 MB and every file in `img/` opens.

### Step 3: the landing page

- Write `index.html` per §5a with the copy from F2. Load `design-taste-frontend` first.
- **Done when:** all three pages share a header and footer; every `href` resolves locally (`grep -oh 'href="[^"#]*"' site/public/*.html | sort -u` and check each); every `<img>` has `alt`; headings run H1 → H2 with no skips; no horizontal scroll at 375 px; the hero swaps images with the scheme.

### Step 4: deploy

```bash
npm install -g firebase-tools
```

```bash
firebase login
```

```bash
cd "/Users/hariom/Desktop/One Word/site" && firebase deploy --only hosting
```

- `firebase login` opens a browser; sign in with the Google account that owns project `one-word-a2f3a`. If `init` is ever needed, the answers are: existing project `one-word-a2f3a`, public dir `public`, not a single-page app, no GitHub deploys.
- **Done when:** `curl -sI https://one-word-a2f3a.web.app/privacy | head -1` and the same for `/support` and `/` print `200`.

### Step 5: wire the URLs

- App Store Connect → App Information → Privacy Policy URL = `…/privacy`. The version page → Support URL = `…/support`; Marketing URL = `…/`.
- App Store Connect → App Privacy: answer from §5b.
- Google Cloud Console → the project's OAuth consent screen → Application home page = `…/`, Privacy policy link = `…/privacy`. Google asks for these before it will verify the sign-in client.
- **Done when:** all three fields are saved and the record no longer flags a missing privacy or support URL.

### Step 6: keep `00_Context` current

- Add a `site/` row to `REPO_MAP.md`'s top-level tree ("public website — landing, privacy, support; Firebase Hosting; not part of any Xcode target") and a "Where things get referenced from outside the code" line: the privacy page names the Firestore fields, so a change to `AuthViewModel.publishJoinDate` or `FeedbackViewModel.send` means re-reading `privacy.html`.
- Add the dossier line to `Docs/README.md` (done with this plan).
- **Done when:** both files mention `site/`.

---

## 8. Test plan

No automated tests; there is no logic. The checks are the done-whens above, plus once after deploy:

| Check | How |
|---|---|
| Three URLs live over HTTPS | `curl -sI` each → `200` |
| Clean URLs | `/privacy` serves, `/privacy.html` redirects or serves; either is fine |
| Both schemes | built-in browser with `colorScheme` light then dark on each page |
| Phone width | 375 px: no horizontal scroll, hero stacks, shelf wraps |
| Link preview | paste the URL into iMessage or Slack: title, description and the icon appear |
| Contrast | the palette passes by construction (§4); spot-check with the browser's accessibility panel |
| Keyboard | Tab reaches the badge, every FAQ link and the mailto in order; focus ring visible |

**Hard to test:** how App Review reads the support page. Mitigation: the contact line is the first thing on it.

---

## 9. Decision forks (operator-owned)

| # | Fork | Default | Take the other side when… |
|---|---|---|---|
| F1 | Domain | **Ship on `one-word-a2f3a.web.app`**; paste that into App Store Connect | …you own or want a domain now. Firebase Hosting → Add custom domain, two DNS records, SSL is automatic. App Store Connect then needs the URLs updated once; nothing in the site changes because every link is relative. |
| F2 | Copy | **The drafts below** | …you have your own voice for it. The structure does not depend on the words. |
| F3 | German on the shelf | **Show all eight covers; round counts and omit German's** (96 words, MARKET_FIT §7) | …you'd rather hide German from the site until it grows, matching the app decision when it is made. One cover fewer in §5a-3 and one name fewer in the shelf line. |

**Draft copy (F2):**

- **Hero.** Eyebrow "For macOS 14 and later". H1 "One new word a day, on your desktop." Body "A widget that shows a word each morning with its meaning in Hindi, a definition and an example. Nothing to open, nothing to keep up with." Under the badge: "Free. Seven more dictionaries for $9.99, once."
- **One entry, whole.** Eyebrow "Every word, whole". Title "The word, its meaning, and how it's used." Caption "The Hindi line is there for readers who want it. It can be turned off in Settings."
- **The shelf.** Eyebrow "The shelf". Title "Eight dictionaries." Body "Everyday English is free: 12,000 words, each with a Hindi gloss. Idioms, Corporate Slang, Emotions, Philosophy, Classical English, Urdu written in Devanagari, and German come with Premium. Pick one and your word of the day comes from it." Counts under covers: "12,000 words" · "3,000+ idioms" · "3,000+ terms" · "900+ words" · "3,000+ entries" · "3,000+ phrases" · "2,400+ words" · German: no count.
- **Also in the app.** Eyebrow "Also in the app". Items as §5a-4, each a sentence.
- **Plans.** Eyebrow "Plans". Free / Premium columns as §5a-5. Premium footnote "A one-time purchase through the Mac App Store. No subscription."
- **Footer.** "One Word: Daily Vocabulary · macOS 14 or later · Privacy · Support · hi.hariom.swift@gmail.com"

Counts are rounded down so they stay true as books grow. To refresh them: `for f in OneWord/Shared/*.json; do printf "%s " "$(basename $f .json)"; python3 -c "import json,sys;print(len(json.load(open('$f'))))"; done`.

---

## 10. Risks and exits

| # | Risk | Likelihood | Impact | Signal | Exit |
|---|---|---|---|---|---|
| R1 | Privacy page drifts from the code (in-app deletion ships, a new Firestore field, Analytics gets linked) | Medium | High — a policy that is wrong is worse than none | A diff touching `AuthViewModel.swift:305-330`, `FeedbackViewModel.swift:92-135` or the linked Firebase products | The REPO_MAP line from Step 6; re-read `privacy.html` in that PR and bump the effective date |
| R2 | Launch traffic exceeds the free tier's 360 MB/day; Hosting pauses the site and the App Store's privacy link dies for the day | Low | Medium | Firebase console usage graph; a "quota exceeded" page | Keep the page under 1 MB (§6). If a launch post is planned, switch the project to Blaze first: static hosting overage is cents per GB, and Blaze has no minimum |
| R3 | Apple's badge used outside its licence (edited, wrong clear space, linking anywhere but the store) | Low | Low | — | Use the SVG unmodified; link only to `apps.apple.com` |
| R4 | The widget-gallery wording in FAQ 1 differs by macOS version | Medium | Low | The steps don't match a test Mac | Change the copy only (ONBOARDING_PLAN R8) |
| R5 | Support page read before the site is deployed | — | High — the record can't be submitted | — | Step 4 precedes Step 5; the sequencing is the fix |
| R6 | `firebase login` lands on the wrong Google account and can't see `one-word-a2f3a` | Low | Low | `firebase projects:list` doesn't show it | `firebase logout`, log in with the account that owns the Firebase console |

---

## 11. Sequencing summary and verification

Steps 1 → 2 → 3 are local and can land in one sitting; Step 4 needs the operator's browser for `firebase login`; Step 5 needs App Store Connect and Google Cloud Console; Step 6 closes it out. Privacy and support pages ship before the landing page is polished, so the App Store record is never waiting on design.

End to end: three `200`s from `curl`, both schemes at three widths in the built-in browser, the URLs saved in App Store Connect and the consent screen, `xcodebuild … build` still green (nothing under `OneWord/` changes; run it anyway), the six gates untouched.

**Files touched (absolute):**

- `/Users/hariom/Desktop/One Word/site/firebase.json` — new
- `/Users/hariom/Desktop/One Word/site/.firebaserc` — new
- `/Users/hariom/Desktop/One Word/site/public/index.html`, `privacy.html`, `support.html`, `style.css` — new
- `/Users/hariom/Desktop/One Word/site/public/favicon.png`, `apple-touch-icon.png`, `og.png`, `badge.svg`, `img/**` — new
- `/Users/hariom/Desktop/One Word/.gitignore` — two lines
- `/Users/hariom/Desktop/One Word/Docs/00_Context/REPO_MAP.md` — one row, one line
- `/Users/hariom/Desktop/One Word/Docs/README.md` — one dossier line

---

## 12. Open questions and assumptions

- **Apple ID for the badge link.** Assumed readable from App Store Connect now. If the field is blank until the first build is attached, leave the badge unlinked and add the `href` when the ID appears.
- **Google account for Firebase.** Assumed the operator owns `one-word-a2f3a` in the console under the same Google account they will use for `firebase login`.
- **Firestore retention.** The policy promises deletion on request within 30 days; that is a manual step in the Firebase console (delete the Auth user, `users/{uid}`, and any `complaints` with that `userID`). Nothing automates it and nothing needs to at this scale.
- **Family Sharing.** Not claimed on the site because it is a per-product switch in App Store Connect that has not been decided. Add the line if it is turned on.
- **The Hindi gloss on a page most visitors can't read** (MARKET_FIT §B9). The rendered entry in §5a-2 shows it once and the caption says it can be hidden. That is the whole answer for v1.
