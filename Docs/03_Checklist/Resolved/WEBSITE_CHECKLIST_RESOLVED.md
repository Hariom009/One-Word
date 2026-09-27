# Website — Checklist (Resolved)

The build checklist for
[`../../02_Plan/Resolved/WEBSITE_PLAN_RESOLVED.md`](../../02_Plan/Resolved/WEBSITE_PLAN_RESOLVED.md).

> A revision of [`../WEBSITE_CHECKLIST.md`](../WEBSITE_CHECKLIST.md) that answers
> [`../Audit/WEBSITE_CHECKLIST_AUDIT.md`](../Audit/WEBSITE_CHECKLIST_AUDIT.md).
> **Tick this one; it stands alone.** The changes:
> - **M1 / Q1 (operator: split):** deploy is two items. **4a** goes live as soon as privacy and
>   support pass their local check; **4d** redeploys after the landing page. Steps 5 and 6
>   hang off 4a, so the App Store record and the in-app link never wait on design.
> - **m1:** 1c counts token *definitions*, so a missing dark block fails it.
> - **m2:** G1 greps added lines only, not diff context.
> - **m3 / Q2 (operator: last in the card):** 5b's placement is now a marked call, `n3`.
> - **m4:** 1d no longer blocks writing the privacy page; it blocks the first deploy instead.
> - **m5:** 3a is ticked in the same sitting as 3b, before its first line.
> - **m6:** G3 says what to do if Xcode rewrote the project file on its own.
> - **m7, m8:** the live-testing note in 2d and the `<section>` instrument in 3b are marked as
>   the checklist's calls, `n4` and `n5`.

**About the plan it comes from:**
- It has been **audited and resolved**:
  [plan](../../02_Plan/WEBSITE_PLAN.md) →
  [audit](../../02_Plan/Audit/WEBSITE_PLAN_AUDIT.md) (fix blockers first; one blocker, the
  privacy draft) → resolved plan (blocker cleared; three operator calls taken: WebP covers, the
  in-app privacy link in this PR, "$9.99, once" with a US note).
- It is a single change: one PR, one ordered list. Written 2026-09-27 on `main` at `675065b`.
- This checklist transforms that plan and nothing more. It does not re-audit it. The plan's
  `[Unverified]` / `[Assumption]` / `[Inference]` tags are carried onto the items they touch.
  Where the checklist, not the plan, made a call, the item says `n<k>:`.

**Stack:** a static site — three HTML files, one CSS file, no JS, no webfonts, no build — on
Firebase Hosting in project `one-word-a2f3a` (free tier), at `https://one-word-a2f3a.web.app`
until DECIDE F1. Tooling: `firebase-tools` (npm), `webp` (Homebrew, for `cwebp`), `sips`
(macOS). App side: three small SwiftUI edits under `OneWord/`, macOS 14.0, no change to
`Shared/` or the widget.

**Files peeked to size the items** (sizing only, not re-grounding):
- `SettingsView.swift:189-212` — the Feedback section: rows are `Button { } label: { row(...) }`
  inside `card(t)`, separated by `rule(t)`, with `.contentShape(Rectangle())` so the whole row is
  the target.
- `SignInView.swift:60-72` — the `#if DEBUG` skip button sits last in the buttons stack.
- `FeedbackViewModel.swift:14-17, 24-26` — imports Foundation, Observation, FirebaseCore,
  FirebaseAuth; `static let address` and its comment.
- `tools/` — six `check_*.sh` on disk (`REPO_MAP.md` says six; `CLAUDE.md` lists five).

## How to use

| Mark | Meaning |
|---|---|
| `- [ ]` | to do |
| `- [x]` | done |
| `blocked-by:` | must wait for that item |
| `⏸` | deferred on purpose; leave unchecked |
| `DECIDE:` | a call that's yours to make |

**Rule:** don't tick an item until its **done-when** holds.

Two commands recur in the done-whens. They are the project's gates:

```bash
xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
```

```bash
for s in check_words check_related check_learned check_capture check_sentences check_premium; do bash tools/$s.sh; done
```

If Xcode has a debug run of One Word open, add `-derivedDataPath /tmp/oneword-site-build` to
the build command so the build never touches the running app.

`$SITE` below means `/Users/hariom/Desktop/One Word/site`.

---

## Open operator decisions (DECIDE)

The plan's defaults apply until you say otherwise. Nothing below blocks Steps 0–4.

- [ ] **DECIDE F1 — Domain.** Default: ship on `one-word-a2f3a.web.app`. Flip if you own or want a domain now: Firebase Hosting → Add custom domain, two DNS records, SSL automatic; then update the App Store Connect fields (6a), the consent screen (6c) and the one Swift constant (5a). Nothing in `site/` changes — every link is relative (gate G6).
- [ ] **DECIDE F2 — Copy.** Default: the plan's drafts in §9. Flip if you want your own voice; the structure does not depend on the words. Affects 1e, 1f, 3b.
- [ ] **DECIDE F3 — German on the shelf.** Default: show all eight covers, round the counts, omit German's (96 words). Flip to hide German until it grows: one cover fewer in 3b's shelf, one name fewer in the shelf line.

---

## Step 0 — Tools (once)

- [ ] **0a** Install the Firebase CLI — `npm install -g firebase-tools` · **done-when:** `firebase --version` prints a version.
- [ ] **0b** Install `webp` for `cwebp` — `brew install webp` · **done-when:** `cwebp -version` prints a version. **If this fails** (plan R7): tick 0b anyway, note "fallback", and take the PNG variant in 2c.
- [ ] **0c** Sign in the CLI — `firebase login` (browser; the Google account that owns the Firebase console) · **done-when:** `firebase projects:list` shows `one-word-a2f3a`. If not (plan R6): `firebase logout`, then log in with the owning account.
- [ ] **0d** `n1:` Branch off `main` — e.g. `git switch -c feat/website` · **done-when:** `git branch --show-current` is not `main`. *(The plan says one PR; the branch name is the checklist's call.)*

## Step 1 — Scaffold and the two required pages

- [ ] **1a** Create `$SITE/firebase.json` and `$SITE/.firebaserc` — files: `site/firebase.json`, `site/.firebaserc` (NEW) · content exactly as plan §3 (`public: "public"`, `cleanUrls: true`, `ignore: ["firebase.json", "**/.*"]`; `{"projects": {"default": "one-word-a2f3a"}}`) · **done-when:** `cd "$SITE" && firebase emulators:start --only hosting` boots and serves `public/` on `http://localhost:5000`. blocked-by: 0a, 0c.
- [ ] **1b** Add `.firebase/` and `firebase-debug.log` to `.gitignore` — files: `.gitignore` (MODIFIED) · **done-when:** `grep -cE '^(\.firebase/|firebase-debug\.log)$' .gitignore` prints `2`.
- [ ] **1c** Write `style.css` — files: `site/public/style.css` (NEW) · the eight tokens from plan §4 in `:root` and again under `@media (prefers-color-scheme: dark)`; `--serif: ui-serif, "New York", Georgia, serif`; `--sans: -apple-system, system-ui, sans-serif`; display clamp 40–88 px, body 17 px, small 13 px; one column max 1040 px, 16 px gutter; hairline rules · **done-when:** `grep -cE '^\s*--(bg|surface|ink|muted|definition|example|rule|hairline):' site/public/style.css` prints `16` (eight definitions in `:root`, eight in the dark block); `--muted` is `#757575` / `#9A9A9A` and nothing lighter (plan §4 contrast floor); no hex colour appears outside the two token blocks.
- [ ] **1d** Read the Firestore region — Firebase console → Firestore → Data; note the database location · **done-when:** the region is written into the PR description (or a comment in 1e), and 1e's "Signing in" paragraph either names it or stays region-free as drafted. `[Unverified]` until read. *(Blocks the first deploy, 4a, not the writing of 1e — the plan says the draft is correct without it.)*
- [ ] **1e** Write `privacy.html` from plan §5b — files: `site/public/privacy.html` (NEW) · `<html lang="en">`; shared header and footer; the drafted sections in order: short version · what stays on your Mac · signing in · feedback · purchases · who else handles your data · how long we keep it · this website · deleting your account · children · changes · contact · **done-when:** the page contains "three things", "profile picture", "Firebase", "until you ask", "within 30 days", `hi.hariom.swift@gmail.com` and an effective date; `grep -c '<script' site/public/privacy.html` prints `0`; it reads correctly in the emulator at `/privacy`. blocked-by: 1a, 1c.
- [ ] **1f** Write `support.html` from plan §5c — files: `site/public/support.html` (NEW) · contact line first (`mailto:` + "or send a note from Feedback inside the app"), then the eight FAQ items in the plan's order and wording (FAQ 3 and 4 carry the US-price note and the "Profile → Settings → Premium → Restore Purchase" path) · **done-when:** the `mailto:` opens Mail from the emulator; eight `<h3>` (or equivalent) FAQ headings; FAQ 1's widget steps have been checked against the Edit Widgets menu on a macOS 14 or current Mac and corrected if the wording differs (plan R4, ONBOARDING R8 `[Unverified]`). blocked-by: 1a, 1c.
- [ ] **1g** Local pass on the two pages — **done-when:** in the built-in browser against the emulator, `/privacy` and `/support` serve with clean URLs, read correctly at 375, 768 and 1280 px, in light and in dark (`colorScheme` both ways), with no horizontal scroll at 375. blocked-by: 1e, 1f.

## Step 2 — Assets

Items 2a–2d are independent of each other and of Step 1; pick them up in parallel.

- [ ] **2a** Copy the icons — files: `site/public/favicon.png` ← `AppIcon.appiconset/icon-mac-32x32@2x.png`; `apple-touch-icon.png` ← `icon-mac-256x256.png`; `og.png` ← `icon-mac-512x512@2x.png` · **done-when:** `sips -g pixelWidth` prints `64`, `256`, `1024` respectively, and `sips -g hasAlpha site/public/og.png` prints `no`.
- [ ] **2b** Download Apple's badge — files: `site/public/badge.svg` (NEW) from the App Store marketing guidelines page, "Download on the Mac App Store", black · **done-when:** the file exists and is byte-identical to the download (do not open it in an editor that rewrites SVG); its `href` is `https://apps.apple.com/app/id<APPLE_ID>` with the Apple ID from App Store Connect → App Information → General, or **no `href`** if that field is still blank (plan §6 `[Assumption]`).
- [ ] **2c** Convert the eight covers, alpha kept — files: `site/public/img/covers/<Name>.webp` ×8 (NEW) · run plan §6's loop verbatim (it finds each cover by folder, which catches the misspelled `Dicitionary_of_Urdu.png`; `sips -Z 480 … --out`, then `cwebp -q 80 … -o`) · **done-when:** `ls site/public/img/covers/*.webp | wc -l` prints `8`; one opened over a black background shows transparent corners, no white. **Fallback if 0b failed:** `sips -Z 240 "$f" --out site/public/img/covers/$n.png` instead, and the shelf `<img>`s point at `.png`. blocked-by: 0b.
- [ ] **2d** Capture the two hero shots — files: `site/public/img/hero-light.jpg`, `hero-dark.jpg` (NEW) · from the Xcode-run app with the medium widget on the desktop, light then dark, ⌘⇧4 region at 2× · `n4:` never `open -n` a second copy of the app and never kill the Xcode run — the operator's live-testing note, not the plan · `sips -Z 1600 -s format jpeg -s formatOptions 82 in.png --out …` · **done-when:** both files exist, `sips -g pixelWidth` ≤ `1600`, each under ~300 KB, and the widget in each is legible at 50% zoom.
- [ ] **2e** Page-weight check — **done-when:** `du -ch site/public/img/covers site/public/img/hero-light.jpg site/public/favicon.png site/public/style.css | tail -1` is under `1M` (`og.png` and `hero-dark.jpg` do not load with the light page; the dark page swaps one hero for the other). Plan §6's WebP estimate is `[Inference]`; this measurement replaces it. blocked-by: 2a, 2c, 2d.

## Step 3 — The landing page

- [ ] **3a** Load the `design-taste-frontend` skill in the build session before writing HTML (plan §4 build note; the §4 constraints are its brief) · **done-when:** the skill is loaded, and this box and 3b are ticked in the same sitting — 3a before 3b's first line is written, since nothing observable remains afterwards.
- [ ] **3b** Write `index.html` — files: `site/public/index.html` (NEW) · six sections in plan §5a's order with §9 F2's copy (or yours, DECIDE F2):
  - **3b-1** Hero: eyebrow, H1, one paragraph, badge, the price line with the US note; `<picture>` with a `media="(prefers-color-scheme: dark)"` source for `hero-dark.jpg` and `hero-light.jpg` as the `<img>`.
  - **3b-2** One entry, whole: term / part of speech / Hindi line (`lang="hi"`) / definition / example, laid out as the app's home screen; the entry copied verbatim from `OneWord/Shared/words.json` (`trade` or `global` if you don't pick another).
  - **3b-3** The shelf: eight covers (seven if DECIDE F3 flips), names, rounded counts as §9 (German: none); the shelf line reads "12,000 words with Hindi meanings", not "each".
  - **3b-4** Also in the app: the six items, the last "Up to three related words…".
  - **3b-5** Plans: Free / Premium columns; the Premium footnote with "$9.99 is the US price; the App Store shows local pricing."
  - **3b-6** Footer: badge, "macOS 14 or later", Privacy · Support, the email, © 2026.
  · **done-when:** `n5:` six `<section>` elements, one per §5a section, so `grep -c '<section' site/public/index.html` prints `6` (the plan says six sections; the element is the checklist's instrument — if you use another element, count that instead); `grep -c '<picture'` prints `1`; the sample entry's `term` and `definition` both `grep` in `words.json`; the words "each with" do not appear; `grep -c '<script'` prints `0`. blocked-by: 1c, 2a–2d, 3a, DECIDE F2/F3 (defaults apply).
- [ ] **3c** The `<head>` on all three pages — title "One Word: Daily Vocabulary for Mac" (landing; page-specific on the others), one-sentence description, `og:title`, `og:description`, `og:image` = `/og.png`, `twitter:card` = `summary`, `<meta name="color-scheme" content="light dark">`, two `theme-color` metas (one per scheme), `<link rel="icon">` and `apple-touch-icon` · **done-when:** `grep -l 'og:image' site/public/*.html | wc -l` prints `3`; the same for `color-scheme`.
- [ ] **3d** Header and footer identical across the three files (duplicated by design, plan §3) · **done-when:** the header block and the footer block, extracted from each file, `diff` clean against each other.
- [ ] **3e** Links, alt text, headings — **done-when:** every path in `grep -oh 'href="[^"#]*"' site/public/*.html | sort -u` resolves in the emulator (click each), the only absolute `http` links are `https://apps.apple.com/…` (and `mailto:`); every `<img` carries `alt=`; each page has one `<h1>` and headings step without skipping a level.
- [ ] **3f** Responsive and dark pass — **done-when:** in the built-in browser against the emulator, at 375 / 768 / 1280 px, light and dark: no horizontal scroll at 375; the hero stacks on phones and sits beside the headline on desktop; the hero image swaps with the scheme; the shelf wraps to two rows on narrow screens; the covers show no white corners or spine halo on the black page; `--muted` text is readable in both schemes. blocked-by: 3b–3e.

## Step 4 — Deploy

Two deploys on purpose (plan §11): the two required pages go live first, so Steps 5 and 6 can start while the landing page is still in progress.

- [ ] **4a** First deploy — privacy and support live — `cd "$SITE" && firebase deploy --only hosting` with `index.html` absent or a one-line placeholder · **done-when:** `curl -sI https://one-word-a2f3a.web.app/privacy | head -1` and the same for `/support` each print `HTTP/2 200` (or `HTTP/1.1 200`); `/` may 404 or show the placeholder until 4d. blocked-by: 1d, 1g.
- [ ] **4b** Clean URLs live — **done-when:** `curl -sI https://one-word-a2f3a.web.app/privacy.html | head -1` prints a `301` and its `location:` header ends in `/privacy`. blocked-by: 4a.
- [ ] **4c** Link preview — **done-when:** pasting `https://one-word-a2f3a.web.app/` into iMessage or Slack shows the title, the description and the icon. blocked-by: 4d.
- [ ] **4d** Second deploy — the landing page — the same command · **done-when:** `curl -sI` for `/`, `/privacy` and `/support` each print `200`; `/` renders the six sections; 3f's pass holds against the live site at one width in each scheme. blocked-by: 3f, 4a.

## Step 5 — The in-app privacy link

- [ ] **5a** Add the URL constant — files: `OneWord/ViewModels/FeedbackViewModel.swift` (MODIFIED, app target) · beside `static let address` (`:26`): `static let privacyPolicy = URL(string: "https://one-word-a2f3a.web.app/privacy")!` (the domain from DECIDE F1) · isolation: a `static let` on the `@Observable` class; no actor change · **done-when:** the build is green; `grep -n 'privacyPolicy\|static let address' OneWord/ViewModels/FeedbackViewModel.swift` shows the two lines adjacent; `grep -c 'import SwiftUI' OneWord/ViewModels/FeedbackViewModel.swift` prints `0`. blocked-by: DECIDE F1 (default applies).
- [ ] **5b** The Settings row — files: `OneWord/Views/SettingsView.swift` (MODIFIED) · inside `section("Feedback", …)` (`:189`), a "Privacy Policy" row with subtitle "What the app keeps, and what it doesn't." and an `arrow.up.right` glyph at 14 pt in `t.muted`, mirroring the Email row · `n3:` placed **last in the card**, after the "Write a message" button's block with a `rule(t)` before it, so the two ways of reaching you stay adjacent and the policy reads as their footnote; the plan put it after the Email row (`:194-205`) · `n2:` wrap the whole row in `Link(destination: FeedbackViewModel.privacyPolicy) { row(...).contentShape(Rectangle()) }.buttonStyle(.plain)` so the whole row is the target, as Email's `Button` is (`:193-203`); the plan put the `Link` on the glyph only · `.accessibilityLabel("Open the privacy policy")` on the `Link` · isolation: main-actor SwiftUI view; no `Task`, no state · **done-when:** the build is green; run from Xcode, Profile → Settings → Feedback shows the row last in the card, under "Write a message"; clicking anywhere on the row opens the live page in the default browser; VoiceOver reads "Open the privacy policy". blocked-by: 4a, 5a.
- [ ] **5c** The sign-in link — files: `OneWord/Views/SignInView.swift` (MODIFIED) · inside the buttons stack (`:39-64`), after the `#endif` of the Debug skip button: `Link("Privacy Policy", destination: FeedbackViewModel.privacyPolicy).buttonStyle(.plain).font(.system(size: 12)).foregroundStyle(t.muted)` — the quiet style of the Restore button (`PremiumView.swift:221-224`) · isolation: as 5b · **done-when:** the build is green; sign out (Profile → sign out) and the sign-in screen shows "Privacy Policy" under the buttons (below "Skip sign-in (Debug)" in a debug run); clicking it opens the live page. blocked-by: 4a, 5a.
- [ ] **5d** Build and gates — **done-when:** the `xcodebuild` command above ends in `** BUILD SUCCEEDED **`, and the six-gate loop prints every gate green with no red line. Report any red gate with its output; never tick past one. blocked-by: 5a–5c.

## Step 6 — Wire the URLs

- [ ] **6a** App Store Connect fields — App Information → Privacy Policy URL = `https://one-word-a2f3a.web.app/privacy`; the version page → Support URL = `…/support`, Marketing URL = `…/` (the domain per DECIDE F1) · **done-when:** all three saved; reloading the pages shows them. blocked-by: 4a (the Marketing URL may point at a 404 until 4d; App Store Connect does not check it).
- [ ] **6b** App Privacy answers — from plan §5b: Contact Info (email, name) and Identifiers (user ID) linked to identity, App Functionality; User Content → Customer Support (the feedback message) linked to identity; the profile-picture link under User Content → Other User Content (`[Inference]` — Apple's form may steer it elsewhere); no tracking; no third-party advertising · **done-when:** the App Privacy section is published in App Store Connect and matches the live `/privacy` page item for item. blocked-by: 4a.
- [ ] **6c** OAuth consent screen — Google Cloud Console → the project's OAuth consent screen · first confirm `one-word-a2f3a.web.app` is under Authorized domains (`[Unverified]` that Firebase adds its Hosting domains itself; add it by hand if absent), then Application home page = `…/`, Privacy policy link = `…/privacy` · **done-when:** the consent screen saves without a domain error and shows both links. blocked-by: 4a.
- [ ] **6d** Record status — **done-when:** App Store Connect no longer flags a missing Privacy Policy URL or Support URL on the record. blocked-by: 6a.

## Step 7 — Keep `00_Context` current

- [ ] **7a** `REPO_MAP.md` — files: `Docs/00_Context/REPO_MAP.md` (MODIFIED) · (i) a `site/` row in the top-level tree: "public website — landing, privacy, support; Firebase Hosting; not part of any Xcode target"; (ii) under "Where things get referenced from outside the code": the privacy page names the Firestore fields and the photo fetch, so a change to `AuthViewModel.publishJoinDate`, `FeedbackViewModel.send`, the use of `photoURL`, or the linked Firebase products means re-reading `site/public/privacy.html`; (iii) correct "Adding files": only `OneWord/` is a synchronized group (`project.pbxproj:97-106`); the widget target lists its files explicitly · **done-when:** `grep -c 'site/' Docs/00_Context/REPO_MAP.md` is at least `2`, and the "synchronized" sentence no longer names `OneWordWidget/`.
- [x] **7b** `Docs/README.md` dossier line — done 2026-09-27: the "Website" dossier links the plan, audit, resolved plan, checklist, checklist audit and this resolved checklist.

---

## Pre-merge gates

- [ ] **G1** No new concurrency — **done-when:** `git diff main -- OneWord | grep '^+' | grep -c 'Task {\|@State\|async'` prints `0` (added lines only, so diff context cannot trip it); the only Swift additions are one `static let` and two `Link`s.
- [ ] **G2** `Shared/` and the widget untouched — **done-when:** `git diff --stat main -- OneWord/Shared OneWordWidget` is empty.
- [ ] **G3** No project-file edit — the three app files already sit in the synchronized group · **done-when:** `git diff --stat main -- OneWord.xcodeproj` is empty. If it is not, and the diff names no new file, Xcode rewrote it on open: `git checkout -- OneWord.xcodeproj` and re-check. A diff that names a new file means a file landed outside the synchronized group — stop and look.
- [ ] **G4** View-model seam intact — **done-when:** `grep -rc 'import SwiftUI' OneWord/ViewModels | grep -v ':0'` prints nothing (it prints nothing today).
- [ ] **G5** Privacy page parity with the code (plan R1's first check) — re-read `AuthViewModel.swift:112-118, 305-338`, `FeedbackViewModel.swift:126-137`, `ProfileView.swift:473` once more · **done-when:** every stored or fetched item there (user ID, email, display name, photo link and its fetch, `joined`, `userID`/`username`/`email`/`message`/`sentAt`) has a sentence on the live `/privacy` page, and nothing on the page names data the code doesn't touch.
- [ ] **G6** Relative links only, so DECIDE F1 stays free — **done-when:** `grep -c 'one-word-a2f3a\|web\.app' site/public/*.html site/public/style.css` prints `0` for every file.
- [ ] **G7** No scripts, no third-party requests — **done-when:** `grep -c '<script\|<link rel="stylesheet" href="http\|fonts.googleapis' site/public/*.html` prints `0` for every file; `grep -oh 'https\?://[^"]*' site/public/*.html | sort -u` lists only `https://apps.apple.com/…`.
- [ ] **G8** Badge licence — **done-when:** `badge.svg` is unmodified (2b) and every `<a>` around it points only at `apps.apple.com`; the badge is rendered at least 40 px tall with clear space around it.
- [ ] **G9** Accessibility on the site — **done-when:** Tab reaches the badge, every FAQ link and the `mailto:` in order with a visible focus ring; every image has alt text (3e); `lang="en"` on `<html>` and `lang="hi"` on the Devanagari spans; the browser's accessibility panel reports no contrast failure on the palette.
- [ ] **G10** Cover art rights `[Assumption]` — **done-when:** you confirm the painted covers are yours to publish on the web. If any is not, replace the shelf with HTML-drawn spines in the `cover` colours from `Wordbook.swift` (plan §13).

---

## ⏸ Deferred / evidence-gated — not now

- ⏸ **In-app account deletion** — fork F2 of the Apple sign-in dossier. Gate: when it ships, add "or choose Delete Account in the app's Profile" to `/privacy` "Deleting your account", rewrite FAQ 7, bump the effective date (plan §5b–c).
- ⏸ **Dropping the Google photo fetch** (audit Q4) — a product change for its own plan. Gate: if it lands, remove the picture sentences from `/privacy` and re-run G5 (plan R1).
- ⏸ **Naming the Firestore region on the page** — gate: 1d's reading, if you want it named.
- ⏸ **Self-hosted Newsreader** — gate: Chrome's Georgia looks wrong beside the app (plan §4 ponytail note). One variable woff2, ~100 KB, first in `--serif`.
- ⏸ **Blaze plan before a launch post** — gate: a planned launch post or a Hosting quota warning (plan R2).
- ⏸ **Family Sharing line** — gate: turning it on in App Store Connect (`OneWord.storekit:17` is false today).
- ⏸ **Badge `href`** — gate: the Apple ID appearing in App Store Connect, if it was blank at 2b.
- ⏸ **PNG fallback for covers** — only if 0b failed; see 2c.

---

## Definition of done

Checking every box here means shippable per the resolved plan.

- [ ] `/privacy` and `/support` went live first (4a); `/`, `/privacy` and `/support` all return 200 over HTTPS after the second deploy (4d); `/privacy.html` redirects (4b).
- [ ] Every page reads correctly at 375, 768 and 1280 px in both schemes, with the covers clean in dark mode (1g, 3f, 4d).
- [ ] Every link resolves, every image has alt text, headings are in order (3e).
- [ ] The app opens the live privacy page from Settings and from the sign-in screen (5b, 5c).
- [ ] The privacy page names the profile-picture fetch and counts three connections — the plan audit's blocker B1, cleared (1e, G5).
- [ ] The URLs are saved in App Store Connect and on the OAuth consent screen; the App Privacy answers match the page (6a–6d).
- [ ] `xcodebuild … build` green and all six gates green, after the app-side edits (5d).
- [ ] Gates G1–G10 ticked.
- [ ] `REPO_MAP.md` and `Docs/README.md` mention `site/` and the checklist (7a, 7b).
- [ ] Nothing committed until asked; when asked, one PR from the branch in 0d.
