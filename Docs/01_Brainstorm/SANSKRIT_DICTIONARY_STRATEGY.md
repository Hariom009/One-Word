# Strategy: Dictionary of Sanskrit

## 1. Header

**Decision under strategy.** This strategy settles what the Sanskrit book is, how it is sourced, how big v1 is, and how it is wired. The wiring covers the id, name, cover, symbol, shelf and widget placement, and the gate lists.

**Brainstorms converged.** Three lenses supplied in the brief: Identity, Sourcing and Fit. There is no file on disk. I re-grounded their load-bearing claims myself.

**Files I read from disk:**
- `/Users/hariom/Desktop/One Word/OneWord/Models/Wordbook.swift:1-66`: the statics, `isLight` at 39-41, `all` at 55, the `named` fallback at 58-60, and the pets placeholder TODO at 31-32.
- `/Users/hariom/Desktop/One Word/OneWord/Shared/Premium.swift:17-54`: `free` at 28, `allows` and `resolve` at 36-41.
- `/Users/hariom/Desktop/One Word/OneWord/Models/Features.swift:10-25`: `premium = false` at 13.
- `/Users/hariom/Desktop/One Word/OneWord/Shared/Word.swift:9-21`: `id == term` at 20.
- `/Users/hariom/Desktop/One Word/OneWord/Models/RelatedWords.swift:55-99`: `sameRoot` at 55-57, tokens counted only when `count > 3` at 64, and the embedding built from `term + " " + definition` at 93.
- `/Users/hariom/Desktop/One Word/OneWord/ViewModels/WordListViewModel.swift:100-121`: the search key is the folded **term only**.
- `/Users/hariom/Desktop/One Word/OneWord/Views/WordDetail.swift:390-399`: Pronounce switches to the hi-IN voice when the term contains Devanagari.
- `/Users/hariom/Desktop/One Word/OneWordWidget/WordWidget.swift:1-50`: the hand-mirrored `WidgetDictionary`, with pets excluded as app-only.
- `/Users/hariom/Desktop/One Word/OneWordWidget/WordWidgetView.swift:140-162`: the small widget shows headword, part of speech and the Hindi line only.
- `/Users/hariom/Desktop/One Word/OneWord/Models/LearnedWords.swift:72-82`: entries are keyed `[dictionaryID][term]`.
- `/Users/hariom/Desktop/One Word/OneWord/Models/DoodleTheme.swift:100-130`: Devanagari falls back to the system face.
- `/Users/hariom/Desktop/One Word/OneWord/Views/DictionaryPicker.swift:285-335`: the cover comes from `Image(book.image)` and the spine is drawn in `cover`.
- `/Users/hariom/Desktop/One Word/tools/WordProviderCheck.swift:11` and `/Users/hariom/Desktop/One Word/tools/RelatedWordsCheck.swift:21-95`: the `books` lists, the full-service list at 61, and the short-term assert.
- `/Users/hariom/Desktop/One Word/.claude/workflows/expand-urdu.js:45-70`: the Urdu RULES block.
- `/Users/hariom/Desktop/One Word/.claude/workflows/add-dictionary.js`: the lines that point at `curiosities.json` (324, 410).
- `/Users/hariom/Desktop/One Word/Docs/01_Brainstorm/STARTUP_DICTIONARY_BRAINSTORM.md:118-124`.
- The commit history for `b93fb90` and `Wordbook.swift`.
- The asset catalog listing. No `Dictionary_of_Sanskrit` exists.
- `DICTIONARY_SOURCES_SCOUT_REPORT.html`: the operator's 2026-10-21 note, "word-a-day pack for Hindi readers, written in Devanagari".

**Probes I ran myself:**
- `character.book.closed.fill.hi` exists from macOS 11.0 and iOS 14.2. Checked in the CoreGlyphs `name_availability.plist` and with `NSImage(systemSymbolName:)`.
- Philosophy already ships `dharma, karma, atman, maya, moksha, rasa, dhvani, pratibha, upamana`. It does not ship `asana, chakra, mudra, yajna, tirtha, sutra, kavya, sandhi, vyakarana`.
- `Wordbook.mark` is not read by any view (grep finds nothing outside `Wordbook.swift`).
- CIELAB and luma for the candidate covers.

**Tiebreaking priority.** The operator did not state one. I optimise for **trust per entry and a distinct identity** over breadth and over reach from a Latin keyboard:
- every Sanskrit form and etymology claim should hold up for a reader who knows Sanskrit;
- the book should teach something Philosophy and Everyday English do not.

The whole strategy depends on this choice. If the operator's real priority is "a book that teaches the Sanskrit language" (breadth, frequency-led), the identity flips to the Learner lens (B) and v1 grows. See §8.

## 2. The decision

Ship the **Dictionary of Sanskrit** as follows:
- **id:** `sanskrit`.
- **Identity:** "the language under your Hindi". It is a curated bridge lexicon for Hindi readers. The headword is in Devanagari, and the `hindi` field names what the word became.
- **v1 size:** about 230 entries across eight dimensions.
- **Sourcing:** written by hand through the house writer/editor workflow under a Sanskrit RULES block, and checked against the public-domain Apte (1890) and Monier-Williams (1899) dictionaries. The WordNet extractor is not used.
- **Placement:** in `Wordbook.all` (before `saved`), `Premium.free`, the widget enum and both gate lists.
- **Look:** cover `0x8C2F1E`, symbol `character.book.closed.fill.hi`, mark `सं`, height `0.95`.

## 3. Why this wins

**Against the Learner's core lexicon (Identity B, the runner-up).** The margin is decisive on the tiebreaker.

B's top-frequency words fall into two groups:
- **Dull particles** (च, तु, एव).
- **Words a Hindi reader already knows, spelled the same.** For these, the `hindi` field either repeats the headword, which the house bans (`expand-urdu.js`, "never a re-spelling of the headword"), or shows a Hindi reader something they already know. The small widget then reads धर्म / NOUN / धर्म — … (`WordWidgetView.swift:144-161`).

B also has the largest surface for grammatical errors, because every example sentence must be correct Sanskrit, and nothing in the repo checks content.

Identity A puts the punchline in the field the house already ships (`hindi`). It also mirrors Urdu, which glosses Persian-Arabic words into Sanskritic Hindi. And it matches the operator's own earlier note: "Sanskrit (word-a-day pack for Hindi readers, written in Devanagari)". This is the strongest grounding any lens produced.

**Against a romanised book (Fit lens B and Identity lens E).** The margin is decisive and set by the code:
- The romanised Indic core already ships in Philosophy (probe above). Cross-book search would show those terms twice.
- Dropping vowel length creates collisions in `Word.id == term` (`Word.swift:20`).
- The romanised Sanskrit "concepts" book this would become is best served by growing Philosophy, not by adding a new shelf.

**Against "build it and hold it with Urdu and German" (Fit lens D).** The margin is thin, and it is the operator's call (Fork F1). The user asked to add it *in the app*, so the default is to ship.

## 4. Decisions ledger

| # | Decision | Kind | Basis |
|---|---|---|---|
| 1 | id `sanskrit`, which is also the json resource name | code-dictated | `Wordbook.swift:15` (id = `<id>.json`); lowercase single-word pattern of `urdu` and `german` (29-30) |
| 2 | Name "Dictionary of Sanskrit", so `shortName` is "Sanskrit" | code-dictated | `Wordbook.swift:49-51`; matches Urdu and German. "Classical Sanskrit" would collide with "Classical English" (28) |
| 3 | Symbol `character.book.closed.fill.hi` | code-dictated | Exists on macOS 11.0+ and iOS 14.2+ (probe). Not used by any book. Secular. There is no Om or dharmachakra symbol |
| 4 | Cover `0x8C2F1E` (deep lac/buckram red): L\*33.4, luma 73, so `isLight` is false and lettering is white | code-dictated for darkness; art intent for hue | `Wordbook.swift:39-41`. Its ΔE76 is at least 30 from every on-shelf cover; its neighbours on the shelf are Pets `0x6B4A2F` and Bookmarks `0x2A4634`. The brown "manuscript" picks sit within ΔE 8-9 of Pets. Re-sample from the painted art when it lands (`Wordbook.swift:9`) |
| 5 | Mark `सं` (not ॐ) | code-dictated as low-stakes | The mark is not read by any view (grep), so it is cosmetic. `सं` avoids a devotional signal if it is ever drawn |
| 6 | Height `0.95` | code-dictated | No other book uses it. It lies between Pets at 0.91 and Bookmarks at 1 |
| 7 | Insert into `all` before `saved`, and add `"sanskrit"` to `Premium.free` | code-dictated | `Wordbook.swift:55`. `Premium.swift:28,36-41`: if the id is missing, the shelf shows the book locked with no way to buy it, and the widget's `resolve` silently swaps it to `words` |
| 8 | Add the id to `WidgetDictionary` as `.sanskrit: "Sanskrit"` | code-dictated | `WordWidget.swift:18-33`. Pets is left out only because it is sound-based and app-only. Sanskrit is text |
| 9 | Make the four pbxproj edits for the widget's Resources phase | code-dictated | The widget target is not synchronized (brief). Without them, the widget calls `fatalError` |
| 10 | Add `"sanskrit"` to both `books` arrays. Do **not** add it to the full-service small-book list in v1 | code-dictated | `WordProviderCheck.swift:11`, `RelatedWordsCheck.swift:21`. The full-service list (61) demands that every entry has a neighbour. A pool of about 230 entries may miss that, as 138-entry Philosophy did `[Inference]`. Measure first |
| 11 | Sourcing: curated by hand with a reference check. WordNet is rejected | code-dictated | WordNet has no Devanagari headwords. The Sourcing lens measured about 7-8 net-new usable lemmas `[Inference-grade parse]`. `tools/gen_words/` has no venv (verified by listing) |
| 12 | Headword script is Devanagari | code-dictated given identity A | Romanised headwords collide with Philosophy (probe). Pronounce already routes Devanagari to hi-IN (`WordDetail.swift:396-399`). Urdu has proved the Devanagari-headword path through the related-words gate |
| 13 | Headword form: nominative singular without the final visarga (धर्म, अग्नि, कर्म, आत्मा, माता). Consonant stems keep their halant (शरद्, जगत्). The scholarly stem goes in the definition's parenthetical | code-dictated by search plus recognition | Search is a substring match on the folded term (`WordListViewModel.swift:111,118-120`). शरद् contains शरद, so keeping the halant costs no findability. A final ः would make typing धर्म miss nothing, but it reads as foreign to Hindi readers and creates twins of the same word |
| 14 | A nasal before a consonant is written as **anusvara** (मंगल, संधि, वसंत, चंद्र), not as the class nasal | code-dictated by search | Search folding leaves Devanagari untouched, and Hindi typists type anusvara. Anusvara for a nasal before a consonant is an accepted Sanskrit spelling variant `[Inference]`. It is irreversible once shipped (`LearnedWords.swift:76-77`) |
| 15 | No verb-root headwords in v1. A root appears only inside parentheticals, as "(from √कृ, to do)" | code-dictated | A bare root never appears verbatim in a conjugated example, which breaks the house check that the term appears in its example. It is hard to search. Its hi-IN pronunciation is unknown. And it is the most irreversible convention of all. This holds back the Identity lens's "root family" dimension |
| 16 | Part of speech is bare: one of the Urdu set, noun / adjective / verb / adverb / prefix / suffix / phrase | code-dictated | `expand-urdu.js` RULES: labels with qualifiers "break three fixed-width layouts". इति goes in as `adverb` |
| 17 | `hindi` is the everyday Hindi word, " — ", then a short Hindi gloss. It must never repeat the headword | code-dictated | `expand-urdu.js` RULES. It can be checked mechanically (the head before " — " must not equal the term) |
| 18 | `definition` is English, starts lowercase, has no final period and at least 8 content words, and ends with an optional grammar/root parenthetical. Words that carry meaning must be longer than 3 letters | code-dictated | `RelatedWords.swift:64,93`. A Devanagari term has no English vector, so the definition alone carries the 99% coverage gate |
| 19 | `example` is a short, simple Sanskrit sentence (about 90 characters or less), " — ", then its English translation. Sandhi is left unapplied around the headword so the term appears verbatim. Examples never quote scripture | house rule; cheap to reverse | This is the convention of Urdu and German. Examples are not keyed, so rewriting them later is cheap |
| 20 | Concept and doctrine terms are excluded. धर्म and कर्म are allowed only *as words*: ordinary sense, root and Hindi descendant | code-dictated | Philosophy owns doctrine. Its strings are romanised, so they cannot collide with Devanagari headwords |
| 21 | Placeholder art `Dictionary_of_ClassicalEnglish`, with a TODO in the pets style, until `Dictionary_of_Sanskrit` is painted | code-dictated | `Image(book.image)` draws the cover (`DictionaryPicker.swift:305-309`), so it must not be blank. Classical is not on the shelf and is neutral. Do **not** borrow the Urdu art: a Sanskrit book with "Urdu" printed on it is a needless provocation `[Inference]` |
| **F1** | **Ship now, or hold until a languages batch with Urdu and German** | **operator-owned fork** | **Default: ship now** (in `all` and `free`), because the request says "in the app". **Hold wins if** the `b93fb90` reasoning still stands: Urdu and German, both finished, were held "for the next release", and the operator wants Sanskrit to arrive with them. Holding means keeping the static, json and pbxproj but leaving the id out of `all`, `free` and the widget enum |
| **F2** | **Release before the painted cover exists** | **operator-owned fork** | **Default: no.** Dev builds use the placeholder; nothing goes to the App Store until the real art lands, because covers print their own titles (`Wordbook.swift:20`). **Releasing with the placeholder wins if** the operator accepts a mis-titled cover, as Pets currently does |
| **F3** | **Who signs off on Sanskrit correctness** | **operator-owned fork** | **Default:** the operator or a Sanskrit-literate reader reviews the 30-entry spike and spot-checks about 10% of v1. **If no reviewer exists**, every headword and every etymology or meaning-shift claim is checked line by line against Apte 1890 and MW 1899, and v1 is capped at about 150 by dropping the weakest dimensions (7, then 6) |
| **F4** | **Cover hue** | **operator-owned, minor** | **Default:** `0x8C2F1E`. **Aubergine `0x4A2E4A`** (L\*23.4, ΔE 21 from Emotions, Startup and German) **wins if** the operator reads the red as sindoor-coded, which is a religious and positioning signal. Changing it costs one hex |

### Dimensions (v1, about 230)

Every seed is `[Unverified]` until checked against Apte 1890 or MW 1899. Spellings follow ledger rows 13-14.

| # | Dimension | Count | Seed terms |
|---|---|---|---|
| 1 | **Words Hindi wore down** (the Sanskrit original of an everyday Hindi word, e.g. अग्नि → आग) | 60 | अग्नि (आग) · हस्त (हाथ) · कर्ण (कान) · दुग्ध (दूध) · ग्राम (गाँव) · चंद्र (चाँद) · सूर्य (सूरज) · अक्षि (आँख) · जिह्वा (जीभ) · निद्रा (नींद) · क्षेत्र (खेत) · घृत (घी) · कर्म (काम) · बुभुक्षा (भूख) · पिपासा (प्यास) |
| 2 | **False friends: senses Hindi changed** | 40 | साहस · मृग · वार्ता · उपन्यास · गवेषणा · पाषंड · उद्घाटन · प्रबंध · व्यवहार · मुहूर्त · संध्या · सूत्रधार · इति · आकाशवाणी · प्रसाद · तीर्थ |
| 3 | **Cousins in English** (cognates, never "comes from") | 30 | माता · पिता · भ्राता · नाम · नव · त्रि · दश · अष्ट · दंत · पद · हृदय · अश्व · गो · सर्प |
| 4 | **Mottos you've seen but never parsed.** Only mottos with verifiable official use; each 30 characters or less | 15 | सत्यमेव जयते · यतो धर्मस्ततो जयः · नभः स्पृशं दीप्तम् · योगक्षेमं वहाम्यहम् · वसुधैव कुटुंबकम् · अतिथिदेवो भव · असतो मा सद्गमय · सत्यं शिवं सुंदरम् · बहुजनहिताय बहुजनसुखाय · विद्या ददाति विनयम् |
| 5 | **The calendar you already live by** (descriptive, never astrology) | 20 | ऋतु · वसंत · ग्रीष्म · वर्षा · शरद् · हेमंत · शिशिर · तिथि · पक्ष · पूर्णिमा · अमावस्या · संवत्सर · नक्षत्र · प्रातः |
| 6 | **Stage, poem and story** (rasa and dhvani stay in Philosophy) | 20 | काव्य · श्लोक · छंद · अलंकार · उपमा · नाटक · विदूषक · नायिका · कथा · सुभाषित · महाकाव्य · प्रहसन |
| 7 | **Courtesy, blessing and ritual words** (descriptive: "in Hindu ritual, …") | 20 | नमस्ते · स्वस्ति · शुभ · मंगल · अतिथि · संकल्प · व्रत · दान · दीक्षा · आशीर्वाद · यज्ञ |
| 8 | **Word-building: prefixes and grammar words** (prefixes written `प्र-`, matching Urdu's `-कार`) | 25 | प्र- · अप- · सम्- · अनु- · निर्- · दुर्- · वि- · अधि- · प्रति- · सु- · उप- · अभि- · संधि · समास · विभक्ति · व्याकरण · सूत्र |

**Held for later:** root families as headwords (ledger row 15), yoga-mat Sanskrit (it overlaps Philosophy's ashtanga terms and serves a different audience), doctrine, proper names, whole verses and myths about Sanskrit.

**Editorial gate:** every entry must have one "aha":
- a Hindi descendant,
- a sense that changed,
- an English cognate, or
- a motto or term the reader sees but cannot parse.

A word that is the same in Hindi and has no story (जल, नदी) is cut. **Do not pad to reach 230**: if the gate leaves 200, ship 200.

## 5. Risks accepted and exits

| Risk | Severity | Confidence | Trigger / leading indicator | Mitigation | Cheapest exit |
|---|---|---|---|---|---|
| Wrong Sanskrit (spelling, inflection, sandhi) or wrong etymology claims undermine trust with exactly the readers who care | High | Medium `[Inference]` | The spike reviewer marks more than about 5% of the 30 entries wrong `[Assumption threshold]` | Reference check against Apte and MW; Fork F3; simple sentence templates; cognates worded as "cousins" | Rewrite content (examples and definitions are not keyed). Shrink v1 by cutting dimensions 6 and 7 |
| A Latin keyboard cannot find the book: typing "dharma" never reaches धर्म | Medium | High (verified at `WordListViewModel.swift:111`) | Users report search misses | Accepted for v1. The audience types Devanagari | Add a romanised search key later. Out of scope here, and Urdu needs it too |
| Devanagari headwords render badly (fallback face, negative tracking, long mottos shrunk by `minimumScaleFactor`). No shipped book has ever had Devanagari headwords | Medium | Low `[Unverified]` | The spike render shows clipping or broken conjuncts in the small widget or in the Doodle and Midnight faces | Render the spike in all three widget families and all three app faces before scaling | Drop tracking for Devanagari terms (a view tweak), or move long mottos out |
| Irreversible conventions are wrong (script, headword form, anusvara) | High | Low-medium | A Hindi typist fails to find spike words; the reviewer objects to anusvara | Settle all three on spike evidence **before** the full run | None after release: terms are keyed by `[book][term]` (`LearnedWords.swift:76-77`) and synced. That is why the spike comes first |
| hi-IN text-to-speech applies Hindi schwa deletion and mishandles ः and ् | Low-medium | Medium `[Unverified]` | Listening during the spike | Accept, since it is the same voice Urdu would use | None needed for v1 |
| About 230 entries looks thin beside books of 3,000 | Low | Medium | The shelf's entry count | Pets ships with 33 | Grow later. The cost is a one-time reshuffle of the day order |
| The "aha" yield runs short in dimensions 2 and 3 | Medium | Medium `[Inference]` | Fewer than half of the drafted candidates pass the gate | Do not pad; rebalance toward dimensions 1 and 4 | Ship a smaller v1 |
| Two placeholder covers (Pets and Sanskrit) on the dev shelf | Low | High | Visible in dev | Fork F2: release waits for the art | Swap one `image` string |

## 6. Success criteria

- Both builds pass, and all seven `tools/check_*.sh` gates pass with `sanskrit` in both `books` lists. Related-words coverage is at least 99%.
- `grep -c 'sanskrit.json' OneWord.xcodeproj/project.pbxproj` returns 4. A widget pinned to Sanskrit, and one set to Follow App Settings while Sanskrit is picked, both show a Sanskrit word, not `words`.
- The shelf shows the book unlocked between Pets and Bookmarks.
- In the spike review, at most about 5% of entries have a Sanskrit or etymology error, and every Devanagari headword renders cleanly in the small, medium and large widgets.
- Mechanical checks over the full json:
  - the `hindi` head never equals the term;
  - no headword contains Latin letters or a nuqta;
  - no single-word headword ends in ः;
  - every example contains its term verbatim;
  - no definition has fewer than 8 words.
- After the review, the related box shows meaningful neighbours on a sample of 20 entries (for example, ऋतु near वसंत), not synonym clones.

## 7. Execution strategy

1. **Unblock the writer stage.** Point `add-dictionary.js:324,410` at `startup.json` and `urdu.json`, because `curiosities.json` was retired and is not on disk. Then write the Sanskrit RULES block, modelled on `expand-urdu.js`, encoding ledger rows 12-20 and the aha gate. This step costs nothing and is reversible.
2. **Spike: 30 entries,** about 4 per dimension, including one long motto, one consonant stem with a halant, one prefix and one false friend.
   - Run the review (Fork F3) and the reference check.
   - Render the spike in all widget families and app faces. Run Pronounce. Have a Hindi typist search for 10 headwords.
   - **This is the gate.** The four irreversible conventions (rows 12-15) are confirmed or changed here, and nowhere later.
3. **Wire it, in parallel with step 4** (the wiring does not depend on content beyond a valid json): the `Wordbook` static, `all`, `Premium.free`, the four pbxproj edits, the widget enum case, both gate lists, and the placeholder art with its TODO. Run the builds and gates against the spike json.
4. **Write the full v1 (about 230)** through the fan-out under the locked rules, then run the mechanical checks, the editor pass and the reference check.
5. **Measure,** then decide whether Sanskrit joins the full-service small-book list (row 10).
6. **Release** only after Forks F1 and F2 are resolved. Commission the painted cover and re-sample `cover` from it.

Dependency direction: step 1 comes before step 2, step 2 before step 4, and step 4 before steps 5 and 6. Step 3 needs only step 2's json.

## 8. What would change this strategy

- **The operator says "I want to learn Sanskrit, not understand Hindi through it."** This flips the identity to the Learner lexicon (B): v1 grows toward the German model, examples become the main risk, and Fork F3 becomes mandatory.
- **The operator says the audience is English-only readers or yoga practitioners.** Then don't build a romanised Sanskrit book: grow Philosophy's Indic coverage instead, and leave the Sanskrit book unbuilt.
- **The spike's error rate is above about 5% and there is no reviewer.** Cap v1 at about 150 by dropping dimensions 7 and 6. If it is still above that threshold, switch examples to short Hindi-context sentences; this is content-only and reversible.
- **Devanagari renders badly in the widget.** Fix the headword styling first, a shared change that Urdu also needs. That pushes toward Fork F1's "hold with Urdu and German" branch, so the Devanagari work is done once for all three.
- **A Hindi typist can't find anusvara or halant forms, or a reviewer rejects anusvara.** Revisit rows 13-14, but only before release. After release they are locked.
- **The aha yield in dimension 2 or 3 is under about 50%.** Shrink those dimensions rather than pad them. A total below about 150 suggests merging Sanskrit into a single "Indian languages" release with Urdu.
