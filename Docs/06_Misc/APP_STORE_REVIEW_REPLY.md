# App Store Review reply — Guideline 2.1 Information Needed (release/1.0)

Paste the **Reply** block into the rejection thread in App Store Connect, and the same text
into App Information ▸ App Review Information ▸ Notes. Attach the screen recording to the
reply (or a link to it). Recording steps are at the bottom.

---

## Reply

Thank you for the review. Here is the requested information.

**1. Screen recording**
Two recordings are attached, both captured on a MacBook (Apple silicon) running the current
macOS release.

- Recording 1 (app): begins with launching the app and shows the typical user flow: the
  first-launch welcome screen, today's word, switching dictionaries, searching, bookmarking,
  and Settings.
- Recording 2 (widget): adding the One Word desktop widget through Edit Widgets and showing
  it displaying the same word as the app.

The welcome screen asks only for a display name, which is stored on the device and shown in
the sidebar; it creates no account and sends nothing anywhere. The app has no account
registration, login, or account deletion, no user-generated content, and no paid content or
in-app purchases in this version, so none of those flows appear.

**2. Purpose and audience**
One Word is a word-of-the-day app for the Mac. It solves a simple problem: people want to
grow their vocabulary but do not want another app to open or notification to tap. One Word
puts a new word on the Mac desktop every day through a WidgetKit widget, so learning happens
at a glance. Opening the app lets the user read the full entry (definition, part of speech,
example sentence), browse the entire dictionary, search it, and bookmark words.

It ships five themed dictionaries, each with its own daily word: Everyday English, Emotions,
Philosophy, Corporate Slang, and Idioms. The target audience is general: students, non-native
English speakers, writers, and anyone who enjoys words. It is rated for all ages and
contains no objectionable content.

**3. Setting up and accessing the main features**
No login, credentials, sample files, or configuration are needed. Everything works on first
launch, fully offline.

- Launch the app. On first launch, type any name and click Get Started. This is shown once.
- The Home pane shows today's word for the current dictionary.
- Click the dictionary chip in the Home header to open the Dictionaries pane and switch
  between the five dictionaries.
- Press Command-K (or click Search in the sidebar) to browse and search the full word list.
- Click the bookmark icon on any word to save it. Saved words appear under Bookmarks.
- Widget: right-click the desktop, choose Edit Widgets, search for "One Word", and add
  "Word of the Day". The widget and the app always show the same word for the day.
- Services menu: select any text in another app, then choose Services ▸ "Save to One Word"
  to bookmark it.
- Settings (in the sidebar) covers appearance and widget preferences.

**4. External services, tools, and platforms**
None are used to deliver the app's functionality. All word data ships inside the app
bundle as JSON files and is read locally. The app makes no network requests, has no
analytics, no advertising, no authentication service, no payment processor, and no AI
service at runtime. There is no backend.

For completeness: the binary links the Firebase Auth and Google Sign-In SDKs because
sign-in is planned for a later version. In this build that feature is compiled out behind
a flag, the SDK is never initialized, and no network connection is ever made.

**5. Regional differences**
None. The app functions identically in all regions. Content is in English (the daily word
and its definition). Each entry also carries a short Hindi gloss, shown to every user and
switchable off in Settings; it is bundled content, not a regional variant. There are no
region-specific features, pricing, or content.

**6. Regulated industry / protected third-party material**
The app is not in a regulated industry. Dictionary content is either our own original
writing or derived from Princeton WordNet, which is distributed under the open WordNet
License permitting redistribution and commercial use. No copyrighted dictionary or
publisher material is included.

---

## Recording the video (do this on the Mac, not in a VM)

The "physical device" for a Mac app is your Mac. Apple wants to see the shipping build, so
install the TestFlight build or the archived Release .app, not the Xcode debug run.

1. Quit One Word if it is running. Remove the widget from the desktop if it is already there
   (the recording should show it being added).
2. Press Shift-Command-5, choose "Record Entire Screen", click Record.
3. Open One Word from Launchpad or Applications. If the welcome screen appears, type a name
   and click Get Started. (If this Mac has already onboarded it goes straight to Home; that
   is fine, the reply explains the screen.) Let the Home pane settle on today's word.
4. Scroll the word entry so the definition and example are visible.
5. Click the dictionary chip, pick a different dictionary, return Home to show its word.
6. Press Command-K, type a word, open it from the results.
7. Bookmark it. Open Bookmarks to show it saved.
8. Open Settings briefly; toggle Hindi meaning off and on so the gloss is visible.
9. Right-click the desktop ▸ Edit Widgets ▸ search "One Word" ▸ add "Word of the Day" ▸ Done.
   Show the widget on the desktop next to the app so the words match.
10. Stop recording from the menu bar. Keep it under 3 minutes; trim in QuickTime if needed.
11. Export as .mov or .mp4 (QuickTime ▸ File ▸ Export As ▸ 1080p). ASC accepts attachments
    under ~500 MB; if larger, upload to iCloud Drive or Google Drive and paste a share link.
