# Website plan: audit

> Audit of [`WEBSITE_PLAN.md`](../WEBSITE_PLAN.md) on `main` at `675065b`, 2026-09-27. Read-only: nothing under `OneWord/` or `site/` was touched. One cover PNG was converted in the session scratchpad to test the plan's asset pipeline.

## Header

**Stack as re-verified.** The plan targets a static site, not the app, so the iOS checklist reduces to: three HTML files and one CSS file, no build, no JS; Firebase Hosting on project `one-word-a2f3a` (`OneWord/GoogleService-Info.plist`, PROJECT_ID); `firebase` CLI absent, `node`/`npm` at `/opt/homebrew/bin`; `sips` present. App facts the site describes: Firebase products linked are FirebaseCore, FirebaseAuth and GoogleSignIn only (`project.pbxproj:654-664`), SDK `upToNextMajor 12.18.0`; `MACOSX_DEPLOYMENT_TARGET = 14.0` on both targets, Debug and Release; one non-consumable at `displayPrice 9.99`, `familyShareable: false` (`StoreKit/OneWord.storekit:16-28`). **No discrepancy with the plan's claimed stack**, one wording slip (Minor 5).

**Files opened.** `WEBSITE_PLAN.md` (full) · `Theme.swift:42-64, 168-170` · `Wordbook.swift`, `Premium.swift` (full) · `AuthViewModel.swift:84-118, 136-160, 176, 210-225, 266, 278-279, 300-338` · `FeedbackViewModel.swift:26, 92-150` · `FeedbackView.swift:100` · `ProfileView.swift:93, 276, 473, 490` · `RootView.swift:139-145, 253` · `SettingsView.swift:26, 50-65, 119, 128` · `PremiumView.swift:217-232` · `WordListView.swift:27, 129` · `OneWordWidget/WordWidget.swift:58-62` and a grep of the whole widget target · `project.pbxproj:97-106, 631-664` · `OneWord.storekit:16-28` · `Info.plist:13-21` · `AppIcon.appiconset/` listing and `icon-mac-512x512@2x.png` (1024×1024, no alpha) · the eight `Dictionary_of_*.imageset` PNGs (dimensions, alpha, a decoded alpha histogram of one) · every `OneWord/Shared/*.json` (counts, empty-field counts) · `Docs/README.md`, `REPO_MAP.md`, `PROJECT_CONTEXT.md`, `DESIGN_BRIEF.md`, `MARKET_FIT_RESEARCH_BRIEF.md`, `ONBOARDING_PLAN.md` (F3 copy, R8) · a grep of `OneWord/Views` and `OneWordApp.swift` for any privacy link.

## Verdict

**Fix blockers first** — confidence high on the blocker (code contradicts the plan), medium overall.

The approach is sound and the scope is right: static, no framework, hosted in the project that already exists, with the two App Store-required pages first. What fails is the plan's own standard for the privacy page. It says the page must be true before it is the App Store's privacy URL, and as drafted it is not: the app receives and loads the Google account photo, which the draft neither names nor counts among the app's connections. Two sentences fix it. Around that sit one confirmed asset-pipeline defect (the covers lose their transparency), one region claim that needs a console check, two guideline items the draft omits, and an in-app requirement the plan does not mention.

## Blocking findings

### B1 — The privacy draft understates what sign-in collects and how often the app connects

- **Where:** §5b, "Signing in" and "The short version".
- **What's wrong:** The draft says Firebase gives the app "a user ID, your email address and your display name", and that the app "talks to a server for two things only". The app also receives the account's photo link and fetches the picture from Google's servers to show it.
- **Evidence:** `AuthViewModel.swift:118` exposes `photoURL` from the Firebase user; `ProfileView.swift:473` loads it with `AsyncImage(url:)`; `RootView.swift:253` passes it to the sidebar chip's `AccountAvatar`. That is a third network connection, made on every launch where a Google photo exists, and a fourth data item stored on the Firebase user record.
- **Fix:** In "Signing in", add: "For Google accounts, Firebase also passes a link to your profile picture, which the app loads from Google to show on your profile; you can pick a built-in avatar instead." In "The short version", change "two things only" to "three things only: signing you in, showing your account picture, and sending a message you choose to send". Add "your account picture link" to the deletion list.
- **Why a blocker:** The page's whole purpose is to be the App Store's privacy URL (§2 "Done when" pastes it into App Store Connect), and Guideline 5.1.1(i) requires it to identify what is collected. The plan already names an inaccurate policy as its worst risk (R1); this ships that risk on day one.

## Major findings

### M1 — The cover pipeline flattens real transparency onto white, which breaks the dark page

- **Where:** §6 asset table (`sips … -s format jpeg`), Step 2, and the 1 MB budget.
- **What's wrong:** All eight cover PNGs carry transparency that is used, not vestigial. Philosophy, resized to 480 px, has 9.0% of pixels below full alpha and all four corners at alpha 0. JPEG cannot hold alpha; `sips` fills it white (verified on the scratchpad conversion). On the dark page (`--bg #000000`) every cover gets white corners and a white halo along the spine.
- **Evidence:** `sips -g hasAlpha` = yes on all eight files; decoded alpha of `Dictionary_of_Philosophy.png` at 480 px; the converted JPEG viewed. PNG at 480 px is ~284 KB per cover, so eight PNGs ≈ 2.3 MB against the plan's 1 MB page ceiling; JPEG q80 is ~47 KB.
- **Fix (pick one, say which in the plan):** (a) WebP with alpha, `cwebp -q 80`, from Homebrew's `webp`. Roughly JPEG-sized, alpha kept, every current browser. This contradicts the plan's "nothing else installed"; amend that line. (b) PNG at 1× only, 240 px wide, about 70–90 KB each, and accept a softer cover on Retina. (c) Flatten twice, white and black, and swap per scheme with `<picture>`: sixteen files, the most work. Recommend (a).
- **Severity rationale:** The shelf is a headline section and the defect is visible on first look in dark mode. Confidence high: measured, not inferred.

### M2 — "Stored … in the United States" is unverified for Firestore `[Unverified]`

- **Where:** §5b, "Signing in".
- **What's wrong:** Firebase Authentication's storage region is documented as US-only `[Unverified, from memory of Firebase's data-location page]`, but Firestore's `(default)` database region is chosen when the database is created and could be `asia-south1` or a multi-region. The `users/{uid}` and `complaints` documents live in that database (`AuthViewModel.swift:321-323`, `FeedbackViewModel.swift:110-111`).
- **Fix:** Open Firebase console → Firestore → Data and read the location. Either name the real region or drop the region and say "on Google Cloud, under Google's Firebase terms". Add this as a Step 1 sub-item so the draft is right before it is written.
- **Severity rationale:** High if wrong, one look to check. Verify-first, not a defect yet.

### M3 — Two Guideline 5.1.1(i) items are missing from the draft

- **Where:** §5b.
- **What's wrong:** The guideline asks a policy to state data retention and deletion, and to confirm that third parties handling the data protect it equivalently. The draft covers deletion-on-request but says nothing about how long the join date and feedback are kept (today: until deletion is requested; nothing expires them), and never says that Google, through Firebase, is the third party processing sign-in and storage.
- **Fix:** Two sentences. Under "Signing in" or a new "Who else handles it": "Sign-in and storage are provided by Firebase, a Google service, under Google's privacy terms; we share your data with no one else." Under "Deleting your account": "Until you ask, your join date and any feedback you sent are kept so we can support you."
- **Severity rationale:** Reviewers rarely reject on policy wording, but the site exists to pass review, and the fix is cheaper than a rejection cycle.

### M4 — Coverage gap: Apple also requires the privacy link inside the app, and there is none

- **Where:** §2 "Not doing" / the plan's premise that nothing under `OneWord/` changes.
- **What's wrong:** Guideline 5.1.1(i) requires a privacy-policy link "within the app in an easily accessible manner", not only in App Store Connect. No view or the app entry point links to one today (grep of `OneWord/Views` and `OneWordApp.swift` for `privacy` and `Link("` returns nothing). The plan does not mention this, so the URL it creates has nowhere to go in the app.
- **Fix:** Name it. Smallest version: one `Link("Privacy Policy", destination:)` in `SettingsView.swift` next to the Feedback entry, and the same on `SignInView` under the buttons. Either fold it into this PR (touches `OneWord/`, so the build and gates run for real) or open a follow-up and add it to the release checklist. Operator's call (Q2).
- **Severity rationale:** Not a website defect, but the website's stated reason to exist is submission, and this is a submission requirement it leaves unmet.

## Minor findings and nits

1. **Copy claims every word has a Hindi gloss; 41 don't.** `words.json` has 41 of 12,000 entries with an empty `hindi`; Emotions has 18 of 987. F2's shelf line "12,000 words, each with a Hindi gloss" is false. Say "with Hindi meanings" or "nearly every one".
2. **"Three related words under every entry"** → "up to three". `check_related.sh` guarantees ≥99% coverage, not all, and the app shows up to three.
3. **Local check contradicts clean URLs** (Step 1 and Step 3 done-whens). `python3 -m http.server` serves `privacy.html`, not `/privacy`, so hrefs written clean 404 locally, while hrefs written with `.html` earn a 301 on the deployed site. Either install `firebase-tools` in Step 1 and check with `firebase emulators:start --only hosting`, which honours `cleanUrls`, or write hrefs as `privacy.html` and accept the redirect. As written, Step 1's done-when cannot be met with clean hrefs.
4. **FAQ 4 path.** Restore Purchase lives in Settings' Premium bar (`SettingsView.swift:53-56`, `PremiumBar()`) and under the Unlock button (`PremiumView.swift:221`); Settings is reached from Profile. "Settings → Premium → Restore Purchase" is right; "Profile → Settings → Premium" is easier to follow.
5. **Synchronized groups.** Only `OneWord/` is a `PBXFileSystemSynchronizedRootGroup` (`project.pbxproj:97-106`); the widget target is an explicit-file group. The plan's conclusion (`site/` is invisible to Xcode) holds. `REPO_MAP.md` makes the same claim; fix it in the same Step 6 edit.
6. **Contrast figure.** Muted on black is about 7.5:1, not 5.9:1 (passes either way). Muted on white at 4.6:1 is the floor for 13 px captions; the build must not lighten `--muted`.
7. **`sips` needs `--out`.** Every command in §6 omits it; the first run fails.
8. **Urdu's cover file is misspelled** `Dicitionary_of_Urdu.png` inside a correctly named imageset. A `find` by folder catches it; a glob on the filename won't.
9. **GitHub Pages sentence.** "/docs" would not collide with `Docs/`; the source option would not find it, and renaming on a case-insensitive disk is its own trap. Reword.
10. **OAuth wording.** With only `openid`, `email` and `profile` (`AuthViewModel.swift:176, 211`), Google does not require verification; the consent screen still asks for the links before Production. Soften "before it will verify". Also `[Unverified]`: Firebase is believed to add `<project>.web.app` and `<project>.firebaseapp.com` to the consent screen's authorized domains automatically; confirm in Step 5 rather than assume the privacy URL is accepted.
11. **`<html lang="en">`** is not mentioned; only the `lang="hi"` spans are.
12. **SDK telemetry.** Firebase iOS SDK ≥ 9.0 dropped the CoreDiagnostics usage pings; at `12.18.0` the "no analytics" claim holds for the SDK itself `[Inference from release notes]`. Worth one line in the plan's "Read for this plan" so R1 has a hook.

## Coverage gaps

- The in-app privacy link (M4).
- Retention and third-party statements (M3).
- No decision on **which cover format** survives transparency (M1); the plan has one command for all image types.
- Nothing states who owns the painted covers or that they are cleared for web use `[Assumption: operator-made]` (Q3).

## What the plan got right

- **Sequencing.** Privacy and support before the landing page, deploy before App Store Connect, and the correct identification that these two URLs gate submission.
- **The data inventory is otherwise exact.** `users/{uid}` holds `joined` only (`AuthViewModel.swift:329-331`); a complaint carries `userID`, `username`, `email`, `message`, `sentAt` (`FeedbackViewModel.swift:126-137`); only FirebaseCore, FirebaseAuth and GoogleSignIn are linked; only two `URLSession` calls exist in the app, both Firestore REST; send is behind a button (`FeedbackView.swift:100`).
- **FAQ facts check out.** The widget target references neither Firebase nor Auth, so it works signed-out; Settings has the "Hindi meaning" toggle (`SettingsView.swift:119`) and reloads the widget on change (`:128`); each widget picks its own dictionary through `AppIntentConfiguration` with `SelectDictionaryIntent` (`WordWidget.swift:58`); the Services item is "Save to One Word" (`Info.plist:21`); seven premium books; 14.0 on both targets.
- **Assets.** The 1024 px icon has no alpha and is a good square link-preview image; the favicon sizes exist as-is.
- **No webfonts** makes the site's own privacy claim true by construction and keeps the page under budget.
- **Rounded counts** so the page does not rot; the refresh one-liner is real.
- **Does not claim Family Sharing**, which `OneWord.storekit:17` sets false.
- **Scopes account deletion honestly** to the Apple sign-in dossier's F2 instead of pretending a web form satisfies 5.1.1(v).

## Operator questions

- **Q1 — Price on the page.** The App Store prices Premium per storefront (rupees in India, the likely first audience). Show "$9.99" as drafted, "$9.99 (US)", or "a one-time purchase" with no figure?
- **Q2 — Where does the in-app privacy link go (M4)?** In this PR, so the build and gates run once for both, or a separate two-line follow-up on the release checklist?
- **Q3 — Cover art.** The painted covers are yours to publish on the web? The plan assumes so.
- **Q4 — Keep loading the Google photo at all?** Dropping `AsyncImage` in favour of the bundled avatars removes the third connection and a sentence from the policy. A product change, not the plan's business, but it is the cheapest way to make the policy shorter.

## What would change the verdict

- **To Ready to build:** B1's two sentences added to §5b, M2 checked against the console, and M1's format chosen. M3 and M4 can be resolved in the same edit; they do not gate the site's build, only its purpose.
- **To Needs rework:** nothing found. The approach, host and scope stand.
