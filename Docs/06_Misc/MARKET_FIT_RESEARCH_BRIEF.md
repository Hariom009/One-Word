# One Word — Market-Fit Deep Research Brief

> Paste this entire file into Claude Deep Research. Part 1 is the prompt. Part 2 is the
> project brief the prompt refers to. Written 2026-09-09 from the code on `feat/firebase-auth`.

---

# Part 1 — The research prompt

You are a product researcher. I am building **One Word**, a macOS vocabulary-enrichment
app (full brief below in Part 2). Before I ship version 1, I want an evidence-based answer
to two questions:

1. **Is there a real consumer for this?** Who, specifically, and what do they say they
   want from a word-a-day / vocabulary tool?
2. **Is there a crucial feature I am missing** that those people treat as non-negotiable,
   which must be in v1 rather than later?

## Framing you must hold onto

- This is **not a language-learning app**. It does not teach a language from zero. It is
  for people who **already know some** of a language (English, German, Urdu today) and
  want a **larger, richer vocabulary** so they sound more precise, articulate, and
  natural. Think "logophile" and "I want to stop saying *very good*", not "I want to pass
  A1". Treat Duolingo-style beginner complaints as a different market unless the evidence
  shows overlap.
- The core mechanic is **passive and ambient**: a desktop widget shows one word; it
  rotates daily; there is nothing to open, tap, or keep up with. Judge the app on that
  promise, not on whether it is a good flashcard app.
- The bridge language in the data is **Hindi**: every entry, in every dictionary, carries
  a Hindi gloss. The Urdu dictionary is written in Devanagari for Hindi readers. So the
  most likely early audience is Hindi/Urdu-speaking professionals and students, but
  **test that assumption** rather than accept it.

## Where to look

Search and read actual user discussions, prioritising the last 3 years. At minimum:

- **Reddit:** r/vocabulary, r/logophilia, r/words, r/etymology, r/ENGLISH,
  r/EnglishLearning, r/writing, r/German, r/languagelearning, r/Urdu, r/Hindi,
  r/india, r/macapps, r/MacOS, r/macgaming (widget threads), r/productivity,
  r/GetStudying, r/Anki, r/selfimprovement.
- **Quora:** questions on "improve vocabulary", "sound more articulate", "word of the
  day apps", "best vocabulary app", "learn Urdu words as a Hindi speaker", "German
  vocabulary for intermediate learners".
- **Threads / X / Mastodon:** word-of-the-day accounts and the replies under them,
  "vocabulary app" complaints, "widget" posts.
- **Open vocab and word communities:** Wordnik community, WordReference forums,
  Vocabulary.com community, Merriam-Webster and Dictionary.com word-of-the-day comment
  sections, Hacker News threads about dictionary/word apps, Product Hunt reviews and
  comments for word-of-the-day and vocabulary apps, Lemmy, language Discords where
  logs are public.
- **App Store / Mac App Store reviews** (1-star and 5-star) for: WordUp, Vocabulary.com,
  Merriam-Webster, Wordnik, Knudge.me, Magoosh Vocabulary, Word of the Day widgets
  (any platform), Anki, and any macOS word-of-the-day widget you find.

## Questions to answer, each with evidence

**A. Demand and audience**
1. Who asks for a "word a day" tool and why? Separate the segments you find (e.g. writers,
   non-native professionals, exam takers, logophiles, parents, ESL teachers).
2. Do people actually want the word to be **passive** (on a desktop, no interaction), or
   do they say they forget passive words and want to be tested? Quote both sides.
3. Is there demand from Hindi/Urdu speakers for **Urdu vocabulary in Devanagari**? For
   Hindi speakers who want to sound more "shayarana" or read Urdu poetry? How do they
   currently do it?
4. Is there demand for **German untranslatable / rich-vocabulary words** among people who
   already speak some German (B1+)? What do they complain is missing from their tools?
5. Is a **Mac-only, desktop-widget-first** app a plus, a non-issue, or a dealbreaker?
   Do people explicitly ask for macOS widgets for words? Do they insist on iPhone?

**B. Feature requirements**
6. Rank the features people call **must-have** in a vocabulary app, by how often they
   come up. Specifically test each of these, which One Word does *not* have:
   - spaced repetition / quizzing / "test me on my words"
   - streaks, reminders, notifications
   - iPhone / iPad / Apple Watch companion, or iCloud sync
   - adding your own words with your own notes
   - audio pronunciation by a human (One Word uses system speech)
   - etymology / word origin
   - synonyms and antonyms shown explicitly
   - usage in real sentences from books or news
   - export to Anki / CSV
   - a browser extension or lookup from any app
7. Which of One Word's **existing** features do people actually ask for (see Part 2
   §4), and which look like effort spent on things nobody mentions?
8. Is a **mandatory Google sign-in** on a local, offline word app something people
   reject? Find reviews and threads where forced sign-in caused uninstalls or 1-star
   reviews for similar small utility apps.
9. Is the **Hindi gloss on every entry** a draw or noise for users who don't read Hindi?
   Should it be hideable, switchable to another language, or is it the whole point?

**C. Competition and positioning**
10. What do users of Merriam-Webster WOTD, Wordnik, WordUp, Vocabulary.com, Knudge,
    and Anki complain about most? Which complaints does One Word already answer?
11. What words and phrases do satisfied users use to describe the *feeling* they want
    ("calm", "no pressure", "ritual", "delightful", "nerdy")? I want positioning
    language from real people, not marketing.
12. What do people say they would **pay** for a word-a-day app, if anything? One-time
    vs subscription, and typical price anchors quoted in threads.

## How to work

- Quote real posts verbatim (short), with the source URL and approximate date, and say
  how many similar posts you saw. A theme backed by one post is an anecdote; say so.
- Do not invent quotes, counts, or communities. If a community has no relevant
  discussion, say that; absence of demand is a finding.
- Distinguish **"people say they want X"** from **"people churn without X"**. Reviews
  and uninstall reasons are stronger evidence than wish-lists.
- Keep beginner-language-learner content in a separate bucket so it does not
  contaminate the vocabulary-enrichment findings.

## Deliverable

A report with these sections, in this order:

1. **Verdict** in five sentences: is there a fit, for whom, and how confident are you.
2. **Segments found**, each with: who they are, what they want, where they hang out,
   evidence strength (strong / medium / weak), and whether One Word as described
   serves them today.
3. **Must-have for v1** — the missing features the evidence says will cause churn or
   bad reviews if absent. Ranked. Each with the evidence and a one-line
   recommendation for the smallest version of it.
4. **Defer safely** — features people mention but that the evidence says are
   nice-to-have. Say why they can wait.
5. **Dealbreakers and risks** — things in the current design (forced sign-in, Mac-only,
   Hindi-on-everything, no testing) that the evidence flags, with severity.
6. **What already lands** — existing One Word features that match voiced demand,
   so I know what to lead with in marketing.
7. **Competitor gap map** — one table: competitor, what users love, what they hate,
   whether One Word fills the gap.
8. **Positioning language** — 10–20 verbatim phrases from real users that describe
   the desired experience, grouped by segment.
9. **Pricing signals** with quotes.
10. **Open questions** you could not resolve, and the cheapest way for me to test each
    (e.g. a specific subreddit post, a landing-page test, a beta group).
11. **Sources** — every URL you relied on.

---

# Part 2 — Project brief (what One Word actually is today)

## 1. One paragraph

One Word is a native macOS app (macOS 14+, SwiftUI) whose centre is a **desktop
widget that shows one word each day** from a dictionary you chose. Open the app and
the same word sits large on a calm, mostly monochrome, dictionary-like page with its
part of speech, definition, an example sentence, and a Hindi gloss. Around that core
the app has grown a bookshelf of themed dictionaries, search, a history calendar, a
reading log, bookmarks, on-device "related words", a sentence-practice pane for
German, and a way to catch a word from any other Mac app. Everything ships as bundled
JSON. There is no network for content, no streaks, no quizzes, no notifications.

## 2. What it is for, and what it is not

- **For:** people who already read and speak a language and want to keep widening
  their vocabulary with zero daily effort. The word is simply *there* on the desktop.
  The feeling aimed for is calm, literary, quietly delightful: a beautiful desk
  dictionary or word-a-day calendar, not a productivity app.
- **Not:** a language course, a flashcard system, an exam-prep tool, or a translator.
  It does not teach grammar, does not test you, and does not track a streak.

## 3. Platform and constraints

| | |
|---|---|
| Platform | macOS 14 Sonoma and later. Mac only. No iOS, iPadOS, watchOS, web. |
| Widget | WidgetKit widget for the desktop and Notification Center; refreshes daily; has a "new word" button; the dictionary it shows is configurable per widget. |
| Content | 100% bundled JSON. Offline. Deterministic: the word for a given date is derived from the date, so app and widget always agree. |
| Account | On the current branch, **Google sign-in via Firebase Auth is mandatory** to enter the app (the widget works without it). The account stores only a join date. Whether to keep this gate for v1 is an open question. |
| Price | Undecided. No monetisation built. |
| Dependencies | None for content. Firebase SDK for sign-in and feedback only. |

## 4. Feature inventory (shipped and working)

**Word of the day (Home)**
- Today's word, large, with part of speech, Hindi gloss, English definition, example.
- "New word" advances to another word; the widget follows.
- Pronounce button (system speech synthesis).
- Bookmark ribbon.
- Settings toggles to hide or show each field (e.g. hide Hindi, hide example).

**Dictionaries (a "shelf" of books, each with its own word of the day)**

| Book | Entries | What it is |
|---|---|---|
| Dictionary of Everyday English | 12,000 | General English, WordNet-derived, each with a Hindi gloss |
| Dictionary of Idioms | 1,468 | English idioms and phrases with a plain-English definition and a written example |
| Dictionary of Corporate Slang | 1,347 | Workplace and startup jargon ("circle back", "runway") |
| Dictionary of Emotions | 987 | Words for feelings and moods only |
| Dictionary of Classical English | 165 | Latin and Greek phrases still used in English ("a fortiori", "modus operandi") |
| Dictionary of Philosophy | 138 | Philosophy vocabulary |
| Dictionary of Urdu | 2,435 | Urdu words written in **Devanagari** for Hindi readers, with a Hindi gloss, an English definition, and a Devanagari example sentence with English translation |
| Dictionary of German | 96 | German words with no clean English equivalent ("Abendbrot", "Luftschloss"), English definition, Hindi gloss, English example |
| Bookmarks | user's own | Not a bundled book: every word you bookmarked or captured |

Each dictionary has a per-book shuffled reading order so consecutive days are unrelated.
Word data model per entry: `term`, `partOfSpeech`, `hindi`, `definition`, `example`.

**Search** — searches across every dictionary at once; hover swells the word; row opens
the full detail.

**History** — any past day's word, with a month calendar rail and arrow-key stepping.
History can read a different dictionary from Home without changing Home or the widget.

**Learned log** — every word you have opened in full view is recorded with the
dictionary and date. The Profile shows how far through each shelf you are, plus an
optional 3,000-word "fluency goal" measured against the German shelf.

**Related words ("In the same vein")** — under every word, up to three nearest
neighbours from the same dictionary, computed on-device with Apple's NLEmbedding
(cosine similarity over term + definition). Each opens its own detail, so you can
chain-browse.

**Practice pane** — an English sentence "rolls" in letter by letter; press space to
reveal its German; space again for the next. 1,508 bundled English–German pairs.
Optional auto-speak on reveal.

**Word capture** — "Save to One Word" appears in every Mac app's Services menu (user
binds a shortcut). The selected text is saved to Bookmarks and pinned as today's word
in app and widget until the next day. No accessibility permission needed.

**Profile** — display name, avatar picked from bundled illustrations, learned counts,
account details, sign-out.

**Settings** — light/dark appearance, hand-drawn "doodle" glyph theme, per-field
visibility, pronunciation, fluency goal. Settings live in the App Group so the widget
obeys them too.

**Feedback** — send as an email draft, or file a note straight to Firestore.

**Visual identity** — monochrome reading surface, colour only on the book covers,
painted cover art, serif headword, custom fonts, subtle sounds (a book-pull on the
shelf, a shuffle on practice). A real app icon exists.

## 5. Deliberately absent (as of today)

- Spaced repetition, quizzes, flashcards, "test me".
- Streaks, reminders, push notifications.
- iPhone / iPad / Watch apps, iCloud sync between Macs.
- Human-recorded audio (system TTS only).
- Etymology, explicit synonym/antonym lists.
- User-authored definitions or notes (capture saves the term only).
- Export (Anki, CSV).
- Any online dictionary lookup.
- Localisation of the UI (English only); glosses are Hindi only.

## 6. Assumptions I want tested

1. The primary early user is a **Hindi-speaking professional or student** who reads
   English daily and wants to sound sharper, and who likes that the Urdu book is in
   Devanagari.
2. A secondary user is a **logophile Mac user** anywhere who wants a beautiful,
   quiet word-a-day widget and will simply hide the Hindi line.
3. A tertiary user is an **intermediate German learner** who is past textbooks and
   wants the untranslatable, texture-giving words.
4. Passive exposure with a searchable history and a reading log is *enough*; people
   who want testing already own Anki and will not switch.
5. A mandatory Google sign-in is acceptable for a desktop app. (I am least sure of
   this one.)
6. People would pay a one-time price for this rather than a subscription.

## 7. Open product questions for v1

- Keep or drop the sign-in gate?
- Is 96 German words too thin to ship as a "dictionary", and should German be hidden
  until it is bigger?
- Should the Hindi gloss be a per-user choice at onboarding rather than a toggle
  buried in Settings?
- Is a minimal "revisit" mechanism (e.g. yesterday's words resurfacing in the widget)
  the smallest thing that answers the "I forget passive words" objection without
  becoming a flashcard app?
- Does anyone want the Practice pane, or is it a distraction from the core promise?
