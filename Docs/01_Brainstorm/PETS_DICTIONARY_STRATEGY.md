# Strategy: Dictionary of Cats & Dogs (signals, not translation)

## 1. Header

**The decision.** Whether and how to build a text-only book of cat and dog sounds and body language for One Word. This covers the id, name, cover, symbol, sourcing, size, editorial rules and dimensions.

**Inputs converged.** Three brainstorms (Identity, Sourcing, Fit), passed inline in the brief. None of them is saved under `Docs/01_Brainstorm/`.

**Files I re-read from disk this run:**
- `/Users/hariom/Desktop/One Word/OneWord/Models/Wordbook.swift:1-64`
- `/Users/hariom/Desktop/One Word/OneWord/Shared/Premium.swift:17-50`
- `/Users/hariom/Desktop/One Word/OneWordWidget/WordWidget.swift:15-40`
- `/Users/hariom/Desktop/One Word/OneWordWidget/WordWidgetView.swift:100-120,205-216`
- `/Users/hariom/Desktop/One Word/OneWord/Models/RelatedWords.swift:25-140`
- `/Users/hariom/Desktop/One Word/tools/RelatedWordsCheck.swift:15-75`
- `/Users/hariom/Desktop/One Word/tools/WordProviderCheck.swift:1-47`
- `/Users/hariom/Desktop/One Word/tools/check_premium.sh:40-70`
- `/Users/hariom/Desktop/One Word/OneWord/Views/WordDetail.swift:16-17,260-280,320-321`
- `/Users/hariom/Desktop/One Word/OneWord/Views/WordListView.swift:15-25,120-135`
- `/Users/hariom/Desktop/One Word/OneWord/Views/DictionaryPicker.swift:51-55,135-145`
- `/Users/hariom/Desktop/One Word/OneWord/Models/LearnedWords.swift` (grep: `:18,25,74-77,93-95`)
- `/Users/hariom/Desktop/One Word/Docs/02_Plan/DICTIONARY_3000_PLAN.md:55-60,66-70,86-96,143-152`
- `/Users/hariom/Desktop/One Word/Docs/06_Misc/APP_STORE_REVIEW_REPLY.md:70-77`
- `/Users/hariom/Desktop/One Word/.claude/workflows/add-dictionary.js:55-80,300-410`
- `git show --stat 38d7907`

**Measured, read-only:**
- Every shipped json: entry count, longest POS, empty examples.
- SF Symbol availability, from the system `name_availability.plist`.
- L\*, luma and ΔE of candidate cover hexes against all nine hexes in use.
- British vs American spelling in startup, idioms and emotions.
- Whether `Wordbook.mark` is read anywhere. It is not: grep finds no reader outside `Wordbook.swift`.

**Tiebreaking priority.** **Honesty, both factual and in framing.** I took it from the brief's own words: "Honest framing: sound types and signals, not literal translation." Next comes fit with the house surfaces (widget, list, related box). Delight comes last, and it lives only in the example. Shelf-scale consistency (about 3,000 entries) is not my tiebreaker. That call belongs to the operator and appears as fork F1.

## 2. The decision

Build **"Dictionary of Cats & Dogs"**, id `pets`, as a **hand-curated book of about 150 entries**, through the `sourcing: 'curated'` path of `add-dictionary.js`.

- **Definitions** are hedged ethology.
- **Examples** are usage sentences that use the term and carry the wink as "roughly, ‘…’".
- **POS values** come from a fixed set of six, each ≤12 characters.
- **Signals both species share** become one comparative `cat & dog` entry. Species never appears in a headword.

**Fixed facts:**
- cover `0x6B4A2F`, provisional until resampled from the painted art
- symbol `pawprint.fill`
- mark `&`
- height `0.91`
- image `Dictionary_of_CatsAndDogs`

## 3. Why this wins

| Contest | Winner | Margin | Why |
|---|---|---|---|
| Curated vs WordNet extractor | Curated | **Decisive** | `add-dictionary.js:250-253` stops the workflow outright on `wordnet`. The Sourcing lens measured about 10 surviving headwords. The extractor keeps only `isalpha()` lemmas, so body language can't be produced at all. WordNet's own `purr` definition repeats the "purr = pleasure" myth that the honest framing exists to correct. The philosophy WordNet dump was already thrown away once (`fe8d199`, per the lens). |
| Pocket (about 150) vs widening to "Animal Behaviour" (3,000) | Pocket | **Moderate** | Widening loses the hook, and the startup brainstorm rejected exactly that drift. Padding a cats-and-dogs book to 3,000 is the one path all three lenses call clearly bad, and the 3000 plan says "don't lower the bar to hit 3,000" (`DICTIONARY_3000_PLAN.md:93-95`). The counterweight is real: the house has grown or retired every thin book (`38d7907`). So whether a 150-entry book goes on the shelf is fork F1, not settled here. |
| Usage-sentence example (Fit) vs scene + em-dash translation (Identity) | Usage sentence | **Decisive** | Three things point the same way. (1) The example renders under the label "Used as" (`WordDetail.swift:268`), and a bare animal voice-over there reads as a literal translation. (2) The workflow tells writers the example must be "one natural sentence actually using the term". (3) The workflow tells editors to *fix* any example that doesn't use the term (`add-dictionary.js` SHAPE and editor prompt). Em-dash examples would be "corrected" anyway, so the brainstorm's preference would not survive the pipeline. |
| Shared entry (`cat & dog`) vs species prefix or suffix | Shared entry plus real species-specific names | **Decisive** | The Set check fails duplicate terms (`WordProviderCheck.swift:36-39`). `sameRoot` treats any shared first four characters as the same root (`RelatedWords.swift:55-56`). It hides such terms from each other's related lists (`:123`) and allows only one per result list (`:133`), so a "cat …" prefix would gut the related box. A `(cat)` suffix has almost no precedent, and Pronounce would read it aloud (`WordDetail.swift:321`). |

## 4. Decisions ledger

### Code-dictated

**Id: `pets`.**
- It is the json resource name (`Wordbook.swift:15`), the Swift enum case and its rawValue (`WordWidget.swift:19`), and the key for the stored pick and the learned log (`LearnedWords.swift:25`). All of these are permanent.
- It is not reserved: not `medical` (`check_premium.sh` "no longer ships" assert), not `character`, `eloquence` or `curiosities`.
- I picked `pets` over `catsdogs` because it would still fit if the book ever widens to rabbits or parrots. The display name can change later; the id effectively cannot.

**Name and short name.** `name` = "Dictionary of Cats & Dogs", so `shortName` = "Cats & Dogs" (`Wordbook.swift:47-49`). The widget display string is the same: `.pets: "Cats & Dogs"`. The name itself is fork F2.

**Cover: `0x6B4A2F`.**
- L\* is about 34.5, inside the shelf's dark band (26-36).
- Luma is about 81, so `isLight` is false and the book gets light lettering (`Wordbook.swift:37-39`).
- Nearest shipped cover is emotions at ΔE about 18. The closest shipped pair today (startup and idioms) sits at about 6.
- It fills the warm-brown gap on the shelf.
- It is **provisional**. `cover` is "sampled off the painted cover" (`Wordbook.swift:17`), so resample it from the final art. Keep the result dark: luma < 150, L\* ≤ about 40.

**Symbol: `pawprint.fill`.** Available since macOS 12, verified in the system plist; the deployment target is 14.0. It is species-neutral and unused by any other book. `cat.fill` and `dog.fill` (macOS 14) would each favour one species.

**Mark `&`, height `0.91`, image `Dictionary_of_CatsAndDogs`.**
- The mark is never displayed (grep), so `&` is cosmetic.
- 0.91 is not among the taken heights.
- The image asset name avoids `&`.

**Shelf order.** Insert `pets` into `Wordbook.all` after `idioms` and before `saved` (`Wordbook.swift:53`). This applies only if F1 takes its default.

**POS set: exactly six values, all ≤12 characters.**

| Value | Use |
|---|---|
| `cat sound` | cat vocalisations |
| `dog sound` | dog vocalisations |
| `cat signal` | cat body language |
| `dog signal` | dog body language |
| `cat & dog` | signals both species share |
| `ethology` | concept or observer terms (trigger stacking, ethogram) |

- The list column is 96pt, one line (`WordListView.swift:21,129`). The widget uppercases POS, one line, with no shrinking (`WordWidgetView.swift:110-114`).
- Every book on the v1 shelf has POS ≤12 characters, measured. German's 16 ships only on a held shelf.
- The brief offered "cat body language" as an "e.g.", so changing it is within the brief.

**Rules must override the workflow's generic POS list.** The workflow's SHAPE tells writers the POS is "noun / verb / adjective / adverb / idiom / phrase / acronym", and the editor is told to fix a "wrong" POS (`add-dictionary.js` SHAPE and editor prompt). The rules must say outright that this book's POS set replaces that list. After merging, check that the POS set is a subset of the six values.

**Dimension order: shared signals go first.**
- The merge dedupes on the lowercased term, and the first batch wins (`add-dictionary.js` `seen` loop).
- If the cat-voice batch writes "growl" before the shared batch does, the comparative entry is silently dropped.
- So the shared dimension goes first, and the rules name the terms it alone owns.

**Headword rules:**
- Use the durable English name, not onomatopoeia ("trill", not "mrrp"). Pronounce speaks `word.term` (`WordDetail.swift:321`).
- No species in the term.
- Within a cluster, put the distinguishing word first ("tucked tail", "lashing tail", "question-mark tail"), so a whole cluster doesn't share one four-character prefix.
- The canonical name wins where it is the only term with that prefix ("tail wag", "play bow").
- At most 30 characters, lowercase.

**Definition rules:**
- Name species as "cats", "dogs", "feline", "canine", "kittens" or "puppies". "cat" and "dog" are three characters, and the index drops tokens of three characters or fewer (`RelatedWords.swift:64`).
- At least 8 content words longer than 3 characters. Lowercase start, no final period.
- Put the hedge in the first clause. The medium widget cuts definitions at 3 lines (`WordWidgetView.swift:177`).

**Example rules:**
- One sentence that uses the term, with the wink inside: "…, roughly, ‘…’".
- No outer quotes. The view adds them (`WordDetail.swift:272`, `WordWidgetView.swift:210`).
- About 100 characters or fewer. The large widget allows 2 lines at a 0.8 minimum scale (`WordWidgetView.swift:214-215`); the exact width is `[Inference]`.

**Wording rules:**
- No study names, no years, nothing lifted from ASPCA, RSPCA or other publishers. The App Store reply states that "no copyrighted dictionary or publisher material is included" (`APP_STORE_REVIEW_REPLY.md:73-76`).
- British spelling, matching idioms (37 to 0 for "behaviour"). Startup is mixed.

**Gate wiring.** As the brief lists it, plus `"pets"` in `let shipped` in `check_premium.sh` and in both `books` arrays.

**Small-book related loop: measure before enrolling.**
- Add `pets` to the coverage list unconditionally (≥99%, `RelatedWordsCheck.swift:30-31`).
- Run the all-or-nothing check once.
- If it serves n/n, enrol `pets` in the loop at `:61`, as with german and classical.
- If some entries come back empty because of prefix collisions, rename them before ship. Renaming is free until release.
- If they are genuine isolates, leave `pets` out with a comment, following the philosophy precedent (`:56-60`).

### Operator-owned forks (recommended default first)

**F1: shelf placement for a pocket-size book.**
- **Default:** put it on the v1 shelf, free, as the brief's wiring describes.
- **Hold instead** (bundle, gate and define it, but leave it out of `Wordbook.all`, `Premium.free` and the widget enum, like classical, urdu and german at `Wordbook.swift:52`) if any of these is true:
  - (a) the operator wants every shelved book near 3,000. "150 entries" sits next to "12,000 entries" on the front-book line (`DictionaryPicker.swift:141`).
  - (b) the operator doesn't want to touch the shelf on `release/1.0` while App Store screenshots are in progress. Adding a sixth book probably changes the shelf shot `[Inference]`.
- **Never resolve F1 by padding** to 3,000. If scale is required, the honest move is to hold the book.
- Side question in the same bucket: build on a branch off `release/1.0`, or on `main` for 1.1. The working tree currently has uncommitted changes in `DictionaryPicker.swift` and `WordListView.swift`.

**F2: name**, which is printed on the cover art and so must be settled before the art.
- **Default:** "Dictionary of Cats & Dogs". The shelf names plain domains (`Wordbook.swift:23-30`).
- **Choose "Whiskers & Wags"** if the operator puts delight above plainness.
- **Avoid** "Pet Talk" and "Cat & Dog Language" (they promise translation, against the brief), "Purrs & Barks" (it drops body language) and "Animal Signals" (it over-promises species).

**F3: depth of human review.**
- **Default:**
  - (a) A human spot-check of the roughly 25 dog-safety entries (whale eye, stiff wag, freeze, hard stare, growl, belly-up, tucked tail, lip lick).
  - (b) One native-Hindi read of all about 150 glosses. At this size that takes hours, not days.
- **Use the LLM editor alone** (the startup and idioms bar) only if the operator accepts that the workflow validates nothing in Hindi beyond the presence of Devanagari (`add-dictionary.js` `DEVANAGARI` test), and nothing in the definitions against research.
- **Require a sidecar sources file** (one source per entry, in `Docs/`, never in the json) if the book will be marketed as a safety or decoder resource.

## 5. Risks accepted and exits

| Risk | Severity | Confidence | Trigger / leading indicator | Mitigation | Cheapest exit |
|---|---|---|---|---|---|
| A myth ships as fact ("wag = friendly", "purr = happy", "belly-up = wants a rub", "guilty look = guilt", "dominance") | High (the wag myth bears on dog-bite safety) | Medium. The editor checks only that a term is "real" | The F3 spot-check finds any absolute "means X" in a context-dependent signal | Rules list these myths by name and require "often/usually/can also". Hedges must carry into the Hindi (अक्सर, आमतौर पर) | Rewrite the content. Rewriting fields is safe; only deleting or renaming terms is not (`DICTIONARY_3000_PLAN.md:56-58`) |
| A headword can't change after ship | Medium-high | High (`LearnedWords.swift:25,77`) | The related probe or a reviewer wants a rename after release | Treat the window before release as the only rename window. Run the probe and review before merging | None cheap after ship. Before ship, a plain edit |
| The book reads as thin beside 3,000-entry books | Medium | High that it's visible; taste whether it grates | Operator reaction to the front-book line | Fork F1 | Drop it from `Wordbook.all`, `Premium.free` and the widget enum, and keep it bundled. `Premium.resolve` already maps unknown or locked ids to `words` (`Premium.swift:37`). What a widget pinned to a removed enum case does is `[Unverified]` |
| Hindi glosses are literal or wrong ("play bow" as an archery bow, "loaf" as bread, दुम दबाना read as cowardice, the howl-at-night omen) | Medium | Medium-high (`words.json` already ships "बढ़ने की आवाज़" for growl, per the Sourcing lens) | The native read flags more than ~5% | Rules say: native sound verbs where they exist (गुर्राना, भौंकना, फुफकारना, म्याऊँ), a description for body language, no transliteration, no folklore, बिल्ली/कुत्ता gender agreement | A content edit to the `hindi` field |
| Writers drift to generic POS or quoted examples | Medium | High that the conflict exists in the workflow prompt | The post-merge POS set is not a subset of the six | An explicit override rule plus the post-merge check | Fix by script on the json before wiring |
| Weak related box (prefix collisions, a narrow domain) | Low-medium | High on the mechanism, unknown in size | The all-or-nothing probe returns empties | Headword prefix rule; plural species words in definitions | Rename before ship, or leave the book out of the strict loop |
| The theme's ceiling is lower than 150 | Low | Medium | Merged count below 105 (the workflow's 0.7× warning), or a high editor drop rate | Ship what survives honestly. No top-up runs | Run `expand-dictionary.js` later, only if the drop rate shows headroom |

## 6. Success criteria

- **Shape:**
  - The brief's python check passes.
  - Every POS is one of the six values.
  - Every term is ≤30 characters, with no species in the term.
  - Every example contains its term (case-insensitive) and is ≤ about 110 characters.
  - No example begins with a quote mark.
- **Size and drops:** 120-160 entries survive, and the editor plus dedupe drop rate is ≤ about 20% `[Inference]`. A much higher drop rate means the ceiling has been reached.
- **Gates and builds:**
  - All five gates are green.
  - Both `xcodebuild` builds pass.
  - `grep -c 'pets.json'` on the pbxproj returns 4.
  - `pets.json` exists in both the app bundle and `OneWordWidget.appex` Resources.
- **Related words:**
  - Coverage is ≥99%.
  - The all-or-nothing probe serves n/n, or every unserved entry is explained.
  - On a hand check of about 10 queries, cross-species neighbours make sense (slow blink → soft eyes).
- **Review:** the F3 spot-check finds zero unhedged absolute claims in the safety cluster, and the Hindi read signs off.
- **Live:**
  - The widget can pin "Cats & Dogs" from Edit.
  - A `cat signal` or `cat & dog` entry renders untruncated in small, medium and large.
  - The shelf shows the cover with its foot on the board, not mid-turn: aspect ≤0.69, foot at about 0.936 (`DictionaryPicker.swift:51,55`).

## 7. Execution strategy

1. **Critical first move: settle F1 and F2.** F2 gates the cover art, since the title is printed on it. F1 decides whether the wiring touches `Wordbook.all`, `Premium.free` and the widget enum, or stops at bundle and gates. Both are cheap to decide and block nothing else that is irreversible.
2. **Run the curated workflow with the committed facts.** This is the reversible step: the output is a working-tree diff until it merges. Pass the dimensions in the order below, so the shared batch wins the first-wins dedupe. With `MAX_WRITERS = 8` and 10 dimensions, they group into 5 writer batches of two (`add-dictionary.js:301-312`). The rules carry everything in the ledger: the POS override, headword, definition, example and Hindi rules, the myth list, and the reserved shared terms.
3. **Review gate, before anything merges:**
   - shape and POS checks
   - the related probe, which decides small-book loop enrolment and any renames
   - the F3 spot-check and Hindi read
   
   This is where headwords freeze. After it, treat them as permanent.
4. **Wiring and gates.** Use the brief's file list. The widget Resources phase in the pbxproj is the known trap; the bundle `ls` is the proof it worked.
5. **Cover art.** Create the asset, resample `cover` from the art, and keep it dark. This is independent of steps 2-4, but nothing should be released before it lands: a blank `Image(book.image)` on the shelf is not acceptable.
6. **Live widget test.** Pin the book from the Edit menu. Use the project's live-testing rules, and don't kill the Xcode debug run.
7. **Later, and only on evidence:** grow the book with `expand-dictionary.js` if the drop rate and reader use suggest headroom. Never aim it at 3,000.

**Dimensions, in this order:**

| # | Dimension (POS) | Count | Seed terms (disjoint across dimensions) |
|---|---|---|---|
| 1 | Signals both species share (`cat & dog`), the **only** owner of these terms | 12 | growl, yawn, belly-up, raised hackles (piloerection named inside the definition), freeze, sniff greeting, nose touch, flattened ears, averted gaze, hard stare, greeting stretch, scent rolling |
| 2 | The cat's voice (`cat sound`) | 16 | meow, mew, trill, chirrup, chattering, purr, solicitation purr, hiss, spit, yowl, caterwaul, silent meow, snarl, murmur |
| 3 | The dog's voice (`dog sound`) | 18 | bark, alarm bark, play bark, demand bark, isolation bark, play growl, whine, whimper, yelp, yip, howl, bay, grumble, huff, play pant, snort |
| 4 | Cat body and face (`cat signal`) | 20 | slow blink, question-mark tail, bottlebrush tail, lashing tail, upright tail, thumping tail, airplane ears, dilated pupils, whiskers forward, arched back, loaf, crouch, flehmen response, tucked paws, half-closed eyes, swivelling ears |
| 5 | Dog body and face (`dog signal`) | 22 | play bow, whale eye, lip lick, tongue flick, shake off, paw lift, tucked tail, tail wag, stiff wag, high tail carriage, soft eyes, submissive grin, head tilt, relaxed open mouth, closed mouth, wrinkled muzzle |
| 6 | Touch, scent and bonding (species POS) | 14 | head bunt, allorubbing, kneading, scratch marking, urine spraying, ground scratching, leaning, gift bringing, allogrooming, sleeping in contact, pawing, hip nudge, tail twining |
| 7 | Play and the hunt (species POS) | 12 | butt wiggle, pounce, stalk, bunny kick, zoomies (with "frenetic random activity periods" inside the definition), self-handicapping, role reversal, play bite, bite inhibition, mouthing, predatory sequence, prey toss |
| 8 | Stress, conflict and warning (species POS or `ethology`) | 14 | calming signal (labelled a practitioner concept, not settled science), displacement behaviour, ladder of aggression, trigger stacking, cut-off signal, redirected aggression, petting-induced aggression, stress panting, turning away, appeasement, resource guarding |
| 9 | Talking to humans (species POS) | 10 | puppy-dog eyes, gaze alternation, social referencing, adult meow, greeting ritual, attention seeking, showing behaviour, food solicitation, guilty look (defined as a response to the owner's cues, not guilt) |
| 10 | The observer's vocabulary (`ethology`) | 12 | ethogram, signal, cue, affiliative, agonistic, ritualisation, honest signal, metasignal, arousal, anthropomorphism, intention movement |
| | **Total** | **150** | |

**Out of scope:**
- figurative idioms (Idioms owns them)
- breeds, care and training
- clinical signs (a definition may still say a signal "can also accompany pain")
- internet pet slang (blep, mlem, doggo)
- folklore and omens
- other species

Illustrative bar for one entry. The Hindi is `[Unverified]` pending F3:

```json
{"term":"slow blink","partOfSpeech":"cat signal","hindi":"धीमी पलक झपकाना — बिल्ली का अक्सर भरोसे और सहजता का संकेत","definition":"a slow, deliberate narrowing and closing of the eyes that cats often direct at people or animals they feel relaxed around, usually read as a non-threatening signal","example":"She answered my slow blink with one of her own, roughly, ‘Fine. You may stay.’"}
```

## 8. What would change this strategy

- **The operator requires about 3,000 on every shelved book.** Hold the book under F1. Do not pad. A genuinely wider "Animal Behaviour" book would be a new brainstorm with a new name; the `pets` id could plausibly survive it.
- **The spot-check shows writers can't hold the hedging rule** (several absolute claims in the safety cluster). Shrink v1 to dimensions 1-3 (about 46 sound and shared entries, the lowest factual risk), or hold.
- **The related probe returns many empty entries.** The prefix rule becomes mandatory and the affected terms are renamed before ship. If the empties are domain isolates, accept a weaker related box and stay out of the strict loop.
- **The Hindi reviewer rejects दुम phrasing or most body-language glosses.** Switch to descriptive पूँछ-based glosses and re-run the Hindi field only.
- **A rendered `cat & dog` row reads badly in the widget.** Change that one POS value before ship. It is a content field, not a key, so this stays cheap until release.
- **Survivors fall well below 105.** The theme's honest ceiling is lower than estimated. Ship the smaller count, or fold this into F1's hold branch.
