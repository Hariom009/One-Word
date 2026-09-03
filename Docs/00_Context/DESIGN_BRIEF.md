# One Word — UI Design Brief

> Paste this whole file into Claude (or any design tool) as context, then ask it to design
> the screens. It describes what the app is, every screen, the real content, and the
> constraints — everything needed to design the UI without seeing the code.

---

## 1. Snapshot

| | |
|---|---|
| **App** | One Word — a "word a day" vocabulary app |
| **Platform** | macOS 14+ (Sonoma). Native desktop app **+ a desktop/Notification-Center widget**. |
| **Tech** | SwiftUI, MVVM (design in SwiftUI-friendly terms — system materials, SF Symbols, toolbars). |
| **Languages** | Bilingual: **English + Hindi (Devanagari)**. Every word shows a Hindi meaning. |
| **Current look** | Plain, unstyled native SwiftUI. **No visual identity yet — that's what needs designing.** |

## 2. What it is & who it's for

Learn one new word every day with zero effort. A **widget sits on the Mac desktop** showing
the word of the day; it rotates automatically each day. Opening the app shows the same
word larger, and lets you **browse and search the full vocabulary**. Each word carries its
part of speech, an English definition, an example sentence, and a **Hindi translation** —
so it doubles as an English↔Hindi learning aid.

Audience: self-learners and Hindi-speaking English learners who want passive, ambient
vocabulary growth — the word is just *there* on their desktop, no app to open.

Feeling to aim for: **calm, literary, quietly delightful.** It should feel like a beautiful
desk dictionary / word-of-the-day calendar, not a busy productivity app. One word, given
room to breathe.

## 3. Brand direction (open — suggestions only)

- Name **One Word** is literal and unhurried — one word, one day, nothing else on screen.
  A **serif, editorial "dictionary"** feel (cream paper, ink, a fine serif for the headword)
  is the natural direction; a warmer ambers/golds palette is the other.
- Needs: an **app icon**, an accent color, a type pairing (a display face for the headword
  + a readable body face + a Devanagari face for Hindi), and a light **+** dark theme.

## 4. Content model — what every "word" contains

Each entry has 5 fields (this is the exact data you're laying out):

| field | meaning | notes |
|---|---|---|
| `term` | the word/headword | e.g. "ephemeral" |
| `partOfSpeech` | noun / verb / adjective / adverb | short label |
| `hindi` | Hindi translation of the **meaning** | Devanagari; can be **empty** (hide the line) |
| `definition` | English definition | 1 sentence; can be long |
| `example` | example sentence | can be **empty** (hide the line) |

**Real sample content** (use this actual data in mockups):

```
term: trade            (noun)
hindi: वस्तुओं और सेवाओं के वाणिज्यिक विनिमय
definition: the commercial exchange (buying and selling on domestic or international markets) of goods and services
example: Venice was an important center of trade with the East

term: global           (adjective)
hindi: पूरे पृथ्वी को शामिल करना; सीमित या प्रांतीय क्षेत्र में नहीं
definition: involving the entire earth; not limited or provincial in scope
example: global war

term: validate         (verb)
hindi: कानूनी रूप से मान्य घोषित या बनाना
definition: declare or make legally valid
example: (none — line hidden)

term: stab             (noun)        [from the Emotions dictionary]
hindi: अचानक तेज भावना
definition: a sudden sharp feeling
example: pangs of regret

term: lightheaded      (adjective)   [Emotions]
hindi: कमजोर और चेतना खोने की संभावना
definition: weak and likely to lose consciousness
```

## 5. Dictionaries (multiple word sets)

The app has a **dictionary switcher**. Two dictionaries today, more planned:

- **Everyday English** — 12,000 general words.
- **Emotions** — ~990 feeling/mood/emotion words only.

The user picks a dictionary; it changes what you **browse/search** (the daily word stays
from Everyday English for now). Design the picker so it scales to more dictionaries later
(e.g. a menu/segmented control showing the active dictionary's name).

## 6. Screens

### A. Word of the Day  (the home screen)
- **Purpose:** show today's single word, beautifully.
- **Content:** `term` (hero), `partOfSpeech`, `hindi`, `definition`, `example`.
- **Current layout:** left-aligned vertical stack — big bold term, italic part of speech,
  Hindi line, definition, quoted example. Plain.
- **Toolbar (top):** a **Search button** (magnifying-glass) and a **Dictionary picker**
  (book icon + name) beside it.
- **Design goal:** this is the signature screen. Make one word feel special — strong
  typographic hierarchy, generous space, maybe a subtle date ("Word for July 25"). The
  Hindi should feel like a first-class part of the entry, not an afterthought.

### B. All Words  (browse + search)
- **Purpose:** browse the whole selected dictionary alphabetically; search it.
- **Top bar:** a **search field on the left** and the **dictionary picker directly beside
  it on the right** (they must read as two separate controls).
- **List:** alphabetical rows, each showing `term` (bold) + `partOfSpeech` (small, muted).
  Up to 12,000 rows — must stay fast and scannable (consider A–Z section index / sticky
  letter headers).
- **Row tap →** Word Detail.
- **States:** empty search result ("No words match '…'"); the count in the field ("Search
  12,000 words").

### C. Word Detail
- **Purpose:** full view of one word (same 5 fields as the home screen), pushed from the list.
- Reuses the same word layout as the home screen. Scrollable for long definitions.

### D. Widget  (desktop / Notification Center)  — **high priority**
- **Purpose:** glanceable word of the day, always on the desktop.
- **Three sizes** (macOS families, approx points):
  - **Small** ~170×170: `term`, `partOfSpeech`, `hindi`, definition (≈2 lines).
  - **Medium** ~360×170: adds the example line.
  - **Large** ~360×380: everything, roomy.
- **Interactive:** a **refresh button** (circular-arrow, currently top-right) — tapping it
  shows a **new word** on demand.
- **Design goal:** must look great sitting on a desktop wallpaper — legible at a glance,
  strong term, tasteful use of the accent color, works on light & dark walls. Design all
  three sizes + where the refresh control sits.

## 7. Navigation / information architecture

```
Word of the Day (home)
   ├─ [toolbar] Search ───────────► All Words (list + search + dictionary picker)
   │                                     └─ tap a word ──► Word Detail
   └─ [toolbar] Dictionary picker (shared with the list)

Widget (separate, on desktop) ── Word of the Day + refresh button
```

Single-window macOS app, `NavigationStack` (push/back). The dictionary selection is shared
between the home toolbar and the list.

## 8. Constraints & specifics

- **macOS-native conventions:** window toolbar, SF Symbols, system materials
  (`.regularMaterial`, `.fill.tertiary` for the widget background), standard control sizes.
- **Bilingual typography:** English (Latin) **and** Hindi (Devanagari) must both look good.
  Pick/pair fonts that render Devanagari well; mind line-height and vertical rhythm when the
  two scripts sit together.
- **Light & dark mode** both required (the widget especially — it sits on arbitrary wallpaper).
- **Empty fields:** `hindi` and `example` can be empty → the line is hidden; design must not
  leave a gap or dangling label.
- **Long content:** some definitions are long (see "trade"); some Hindi is long. Handle
  wrapping/truncation gracefully (widget truncates; detail scrolls).
- **Accessibility:** support Dynamic Type / larger text, sufficient contrast, VoiceOver labels.
- **Scale:** the list can hold 12,000 items — lazy, performant, with a fast way to jump.

## 9. What I'd love designed (deliverables)

1. **Word of the Day** screen (light + dark).
2. **Widget** in all three sizes (light + dark) with the refresh control placed.
3. **All Words** list with the search + dictionary-picker bar, a row style, and empty/results states.
4. **Word Detail**.
5. A small **style foundation:** accent color, type pairing (headword / body / Devanagari),
   and the **app icon**.

Keep it **calm, editorial, and word-first** — the content is the hero; chrome stays quiet.
