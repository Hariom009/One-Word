# Dictionary 3000 — Plan

Grow four premium books to **at least 3,000 entries each**: Corporate Slang (`startup`), Philosophy,
Classical English, Idioms. Content only: no new views and no model changes. One workflow gets
generalised, one book gets a reset first, and then there are four runs.

*Assumption: "3,000" means each book, not the four combined. The combined reading is already met
(3,118 today), so it can't be what was asked for.*

## 0. The gap

| Book (`id`) | Today | Target | To add | State of what's there |
|---|---:|---:|---:|---|
| Idioms (`idioms`) | 1,468 | 3,000 | 1,532 | house style, clean |
| Corporate Slang (`startup`) | 1,347 | 3,000 | 1,653 | house style; already pruned once (159 cut, see `Docs/06_Misc/STARTUP_DICTIONARY_REMOVED.json`) |
| Philosophy (`philosophy`) | 138 | 3,000 | 2,862 | **not house style.** WordNet definitions, machine-translated Hindi, 120/138 empty examples, stray non-philosophy senses (`interchangeable`: "(mathematics, logic) such that…") |
| Classical English (`classical`) | 165 | 3,000 | 2,835 | house style, clean |
| **Total** | | | **~8,900** | |

Measured 2026-09-24 against `OneWord/Shared/*.json`.

## 1. What already exists (reuse it, don't rebuild it)

- **`.claude/workflows/expand-dictionary.js`** is the machine: survey → one writer + one editor per
  theme (each batch on disk) → deterministic Python merge (dedupe, schema, Devanagari check,
  definition case-fold, alpha sort) → build gates. It was built for, and has only run on, Idioms.
- **Adding entries needs no Swift change.** `Wordbook.all` already lists all four books, and the JSONs
  are already members of both targets. `WordProvider` shuffles `words.indices` for any `n`.
- **The gates hold at any size.** `WordProviderCheck` asserts the full cycle for any `n`.
  `RelatedWordsCheck` bar 3 (every word in `classical` has a neighbour) gets *easier* as the pool
  grows. Nothing in `tools/` pins a book's count.
- **Size is fine.** At about 300 bytes an entry, the four books add ~2.7 MB of JSON. The widget already
  decodes the 3.8 MB `words.json`. The related-words index builds in "~2.4s at 12,000 words"
  (`WordDetail.swift:195`), and no one book here passes 3,000.

### Where the workflow falls short (fix in Step 1)

1. **The writer and editor prompts only know about idioms.** They say *"Write N English idiom entries for
   … the Dictionary of Idioms"* and *"Edit the idiom entries"*, and they hard-code *"avoid
   workplace/corporate-register idioms … grep startup.json"*.
2. **The merge rejects collisions with `startup.json` only.** Nothing stops the four books from
   swallowing each other's terms. `classical` already holds `a priori` and `ad hominem`.
3. **`target` gets treated as the number to add, not the final count.** `perTheme = ceil(target *
   1.2 / themes)` runs *before* the survey. `target: 3000` on Idioms would write 3,600 new
   entries, not 1,532.
4. **`partOfSpeech ≤ 11` rejects `Latin phrase`** (12 characters). That value already ships in
   `classical` (17 entries). A length cap also does nothing to stop 30 parallel writers from
   inventing 30 part-of-speech labels.
5. **The Gates phase runs 2 of the 5 check scripts** that CLAUDE.md requires.
6. **The idioms-only editor rule** ("within a family … first words differ") sits in the shared
   editor prompt when it belongs in that book's `rules`.

## 2. Decisions

### Made (the code or the house style dictates these)

- **One generalised workflow, not four.** Five new args (Step 1). Nothing else changes shape.
- **Never delete a shipped term.** `LearnedWords` keys sightings by `[book][term]`
  (`LearnedWords.swift:72`). If a term disappears, `count(in:)` still counts it while `log` silently
  drops it. Rewriting an entry's *content* is safe; removing its *term* is not.
- **Cross-book ownership, enforced by the merge.** For each run, the terms of every book in the
  run's `avoid` list are rejected. Boundaries:
  - logic, fallacies, doctrines, Latin logic terms → **Philosophy** (except what `classical`
    already ships, which stays: see above)
  - rhetoric, poetics, loan phrases, mythological/eponymous words → **Classical**
  - emotion words → the existing **Emotions** book (Classical avoids `emotions`)
  - workplace register → **Corporate Slang**; everything figurative and general → **Idioms**
- **Allowed part-of-speech values per book, replacing the length cap.** Every value is ≤ 12 characters
  (`Latin phrase` is the longest, and it already ships in the fixed-width POS column).
- **Run order: Idioms → Corporate Slang → Philosophy → Classical.** Idioms goes first because its
  rules are proven, so a regression in the generalised workflow shows up on a known book.
  Philosophy runs before Classical so the contested terms land in Philosophy. Classical's
  vocabulary is the deepest of the four, so it can afford to lose them.
- **Top up by re-running, not with new code.** The survey re-reads the file and `perTheme` now comes
  from the remaining gap, so a short run is fixed by re-running with fresh themes.
- **Branch: `feat/dictionaries-3000` off `main`**, one commit per book. The branch touches only JSON,
  the workflow, and the README dossier line, so it neither depends on nor conflicts with the unmerged
  `feat/premium`.
- **Accepted side effect:** growing a book reshuffles its day→word order (`WordProvider.swift:33`).
  Today's word changes once, for everyone, in the app and the widget alike. Nothing desyncs.

### Forks (yours to change; the defaults are marked)

| # | Question | Default | Alternative |
|---|---|---|---|
| F1 | May a word sit in Everyday English (`words.json`) **and** one of these books? | **Yes**: precedent is 193 in `startup`, 31 in `classical`. Different book, different daily draw, and here it gets its register-specific sense. | Forbid it: Classical loses much of its best-known vocabulary (`ephemeral`, `ubiquitous`…) |
| F2 | How does Philosophy reach 3,000? | **Every tradition + eponymous concepts**: Indian, Buddhist, Chinese, Islamic and African philosophy, plus `Cartesian dualism`, `Hegelian dialectic`, `Hume's fork`. No bare biographies. | Western analytic canon only. Realistically that tops out near 2,000–2,200 genuine terms before padding starts. |
| F3 | Rewrite Philosophy's 138 existing entries to house style? | **Yes**, before the run (Step 2). Terms kept, content rewritten. | Leave them. Philosophy then ships 138 WordNet-style entries next to 2,862 house-style ones. |
| F4 | Proverbs in Idioms (*actions speak louder than words*)? | **No.** Most break the 30-char headword cap, and the book has none today. | Add a `proverb` part of speech and a theme. |

**The honest risk:** Philosophy (under F2's default) and Corporate Slang are the two books where
3,000 *genuine* entries is near the ceiling. Corporate Slang already covers Indian corporate
English, SaaS metrics, VC and HR (checked: `do the needful`, `prepone`, `ARR`, `garden leave`,
`RACI` are all in). If two top-ups can't close the gap without the editor passing filler, **stop
and report the count**. Don't lower the bar to hit 3,000.

## 3. Step 1: generalise `expand-dictionary.js`

File: `.claude/workflows/expand-dictionary.js` (the only code change in this plan).

New `args` fields:

| Arg | Type | Replaces |
|---|---|---|
| `book` | e.g. `"Dictionary of Philosophy"` | the hard-coded "Dictionary of Idioms" |
| `kind` | singular noun for one entry, e.g. `"philosophy term"` | the hard-coded "idiom" in writer + editor prompts |
| `avoid` | book ids, e.g. `["classical","idioms","startup"]` | the hard-coded `startup.json` grep line (writer) and `slang` set (merge) |
| `blocklist` | JSON paths of previously-cut entries | nothing (new): `startup` passes `Docs/06_Misc/STARTUP_DICTIONARY_REMOVED.json` so the 159 cuts don't come back |
| `pos` | allowed `partOfSpeech` values | `len(partOfSpeech) > 11` |

Edits:

1. Compute `perTheme` **after** the survey: `ceil(max(0, target - survey.count) * 1.2 /
   themes.length)`. When the gap is 0, `return` early with the count.
2. Writer prompt: fill in `book`, `kind`, `pos` and the `avoid` files (`grep OneWord/Shared/<id>.json
   before using a term`). Keep the meaning-family instruction for every book, since related words
   need it everywhere, and phrase it neutrally as "near-synonym clusters".
3. Editor prompt: fill in `kind`, and move "first words differ" out of the shared checks into
   Idioms' `rules`. Replace the POS length check with "partOfSpeech is one of `pos`".
4. Merge script: build the `avoid` set as the union over `cfg.avoid` books plus every `term` in
   `cfg.blocklist` files. Reject when `w["partOfSpeech"] not in POS`. Print the collisions per
   avoided book, not just the single `startup-collisions` total.
5. Gates agent: run CLAUDE.md's full list, `for s in tools/check_*.sh; do bash "$s"; done`, plus
   both xcodebuild schemes.

**Done when:** a dry run with `{id: "idioms", target: 1468, …}` hits the early return (gap 0) and
prints the count, and `node --check` passes on the file.

## 4. Step 2: Philosophy reset (F3)

One agent rewrites `OneWord/Shared/philosophy.json` in place, before the Philosophy run:

- keep **every term** (see "never delete a shipped term")
- rewrite `definition` / `hindi` / `example` to the Philosophy rules (§5.3), and fill all 120
  empty examples
- give off-sense entries their philosophical sense: `interchangeable` becomes the logic sense in plain
  English, with no "(mathematics, logic)" prefix
- **done when:** 138 entries, 0 empty fields, 0 definitions starting with `(`, and
  `check_words` + `check_related` green

## 5. The four runs

All books share these rules (put them in every run's `rules`):

- exactly the five keys, none empty; headword ≤ 30 characters, lowercase unless it's a proper noun or
  acronym, no leading article
- **definition:** plain English that a curious 16-year-old can follow; lowercase start, no final
  period; ≥ 8 content words; the meaning-bearing words must be > 3 characters (the index drops
  tokens of length ≤ 3, `RelatedWords.swift:63`)
- **example:** one full sentence in an ordinary modern setting that uses the term and shows the
  meaning without restating the definition; never a quotation from a real person
- **hindi:** `हिन्दी शब्द — छोटी व्याख्या`, giving the meaning and never a transliteration; use
  established terminology where it exists
- the term must be in real use: if a writer can't vouch for it, drop it. Durable beats trendy.

Batch size is ~110 entries per writer, which keeps list quality from degrading. Writing volume is
the gap × 1.2.

### 5.1 Idioms: 18 themes, ~102 each

`book: "Dictionary of Idioms"`, `kind: "idiom"`, `avoid: ["startup","classical"]`,
`pos: ["verb phrase","noun phrase","adjective","adverbial","simile","exclamation"]`

Rules: the book's committed rules from its last run (recover the `rules` array from that run's
session transcript if possible), plus the family rule moved out of the editor: *members share ≥ 2
content words in their definitions, and their first words differ.* No proverbs (F4).

Themes are **semantic, not lexical**. A scan shows body-part idioms are already saturated (180 of
1,468), and meaning themes are what produce related-word families:

success & triumph · failure & ruin · effort & persistence · idleness & avoidance · anger &
quarrels · fear & courage · delight & excitement · sadness & regret · honesty, deceit & secrets ·
wealth & poverty · haste & delay · trouble & predicaments · ease & simplicity · understanding &
confusion · talk, gossip & silence · love, friendship & family · power & control · risk, luck &
chance

`mustHave` (checked missing today): `steal someone's thunder`, `bark up the wrong tree`,
`rain on someone's parade`, `devil's advocate`, `get cold feet`, `take with a pinch of salt`,
`ugly duckling`, `your guess is as good as mine`

### 5.2 Corporate Slang: 18 themes, ~110 each

`book: "Dictionary of Corporate Slang"`, `kind: "workplace term"`, `avoid: ["idioms"]`,
`blocklist: ["Docs/06_Misc/STARTUP_DICTIONARY_REMOVED.json"]`,
`pos: ["noun","verb","adjective","adverb","acronym","phrase","idiom"]`

Rules: the editorial compass from `Docs/01_Brainstorm/STARTUP_DICTIONARY_BRAINSTORM.md`, verbatim:
honest definition with a winking example; the *sayable-in-a-meeting* test (no deep computer-science terms like
`mutex`); the office sense rather than the literal one; durable beats trendy; decode euphemisms and never
add insults. Also: **no plain dictionary words.** "basic" is the most common `_reason` in the cut
file (`agenda` was cut for it). Indian corporate English is defined as usage and never mocked.

Themes go deeper where the book is thin, because its original nine dimensions are covered:

consulting & strategy decks · finance & accounting floor-talk · banking & markets slang ·
fundraising & cap tables · sales org & pipeline · marketing & growth · product management &
design · engineering culture & on-call · AI-era workplace · careers, reviews & HR euphemism ·
legal, contracts & procurement · operations, supply chain & lean · customer success & support ·
leadership fads & frameworks · boardroom & governance · remote/hybrid & chat shorthand · Indian
corporate English (top-up) · meeting & calendar culture (top-up)

`mustHave`: `EBITDA`, `MECE`, `JTBD`, `blameless postmortem`, `kaizen`, `fiduciary duty`,
`out of station` (all checked missing today)

### 5.3 Philosophy: 32 themes, ~108 each (after Step 2)

`book: "Dictionary of Philosophy"`, `kind: "philosophy term"`,
`avoid: ["classical","idioms","startup"]`,
`pos: ["noun","adjective","verb","adverb","phrase","Latin phrase"]`

Rules:
- concepts, doctrines, schools, arguments, fallacies, thought experiments and technical terms from
  **any tradition** (F2). Eponymous *concepts* are fine; people alone are not.
- neutral about contested views: "the view that …", never "the truth that …"
- non-English terms take the spelling that English-language philosophy writing uses: `advaita`,
  `wu wei`, `Übermensch`. Drop the scholarly transliteration marks (no `ā`/`ṣ`), but keep a
  language's own letters. Search is unaffected either way, since `canon()` folds diacritics.
- **hindi:** established Hindi/Sanskrit *darshan* vocabulary (ज्ञानमीमांसा, तत्त्वमीमांसा,
  नीतिशास्त्र). Indian concepts get their original Devanagari term plus a gloss (`धर्म — …`).
  This is where the Hindi field earns its keep most.

Themes:

metaphysics: being & substance · metaphysics: causation, time & modality · epistemology &
scepticism · formal logic · informal logic & fallacies · normative ethics · metaethics · applied
ethics & bioethics · political philosophy · social philosophy & critical theory · philosophy of
mind · philosophy of language · philosophy of science · philosophy of mathematics · aesthetics ·
philosophy of religion · free will, action & personal identity · ancient Greek terms ·
Hellenistic & Roman schools · medieval & scholastic · rationalism & empiricism · Kant & German
idealism · existentialism & phenomenology · analytic philosophy & pragmatism · continental &
postmodern · Vedanta & Samkhya · Nyaya, Mimamsa & Indian logic · Buddhist & Jain philosophy ·
Chinese & Japanese philosophy · Islamic, African & Latin American philosophy · thought
experiments & paradoxes · eponymous principles & razors

`mustHave`: `ontology`, `a posteriori`, `categorical imperative`, `deontology`, `virtue ethics`,
`eudaimonia`, `stoicism`, `absurdism`, `qualia`, `free will`, `Occam's razor`, `ship of Theseus`,
`trolley problem`, `veil of ignorance`, `cogito ergo sum`, `tabula rasa`, `is-ought problem`,
`social contract`, `dharma`, `karma`, `moksha`, `advaita`, `maya`, `anatta`, `dukkha`, `wu wei`

### 5.4 Classical English: 30 themes, ~114 each

`book: "Dictionary of Classical English"`, `kind: "classical English word or phrase"`,
`avoid: ["philosophy","emotions","idioms","startup"]`,
`pos: ["noun","adjective","verb","adverb","interjection","Latin phrase","loan phrase"]`

Rules:
- **scope:** the elevated, Latinate and literary register: the words you meet in Johnson, Gibbon,
  Austen, the King James Bible and a good op-ed page. That includes loan phrases, mythological and
  eponymous words, archaisms, and rhetorical and poetic terms.
- out of scope: logic and doctrine (Philosophy), feeling-words (Emotions), figurative phrases
  (Idioms)
- archaic words open their definition with `archaic:`
- French, Greek, Italian and other loan phrases take `loan phrase`; Latin keeps `Latin phrase`
- the example carries the house wink, as in the book's own exemplar: *"Shipping on Friday with no
  rollback plan is hubris, and Monday collects the bill."*

Themes:

character & temperament · speech & eloquence · reasoning & argument (non-technical) · power, law
& governance · wealth, thrift & excess · conflict & war · body, health & decay · time & change ·
nature, landscape & weather · rank & manners · religion & ritual · praise & blame · size, number
& degree · learning & scholarship · deceit & truth · love, friendship & enmity · food & feasting ·
manner & movement · art & beauty · sound & silence · Latin phrases in everyday prose · Latin legal
& scholarly phrases · Greek loanwords · French loan phrases · Italian & other loan phrases ·
mythological & eponymous words · biblical words · Shakespearean & archaic English · rhetorical
devices · poetry & prosody

`mustHave`: `quixotic`, `pyrrhic victory`, `laconic`, `loquacious`, `sesquipedalian`,
`perspicacious`, `obsequious`, `magnanimous`, `pusillanimous`, `raison d'être`, `fait accompli`,
`noblesse oblige`, `hoi polloi`, `forsooth`, `zeugma`, `litotes`, `jeremiad`, `shibboleth`,
`philippic`, `halcyon`

## 6. Running it

For each book, in order:

1. Invoke the workflow with the args above, `target: 3000`, and a scratch directory.
2. Read the merge line. If `TOTAL < 3000`, **top up**: re-invoke with the same args and 4–8 *new*
   themes aimed at the gap. The survey re-reads the book, so `perTheme` sizes itself.
3. Stop after **two** top-ups. If the book is still short, report the count and the editor's drop
   reasons, and don't pad (see §2, the honest risk).
4. Spot-read 30 random entries yourself before the commit (by eye; no script judges wit or accuracy):
   `python3 -c "import json,random;[print(json.dumps(w,ensure_ascii=False)) for w in random.sample(json.load(open('OneWord/Shared/<id>.json')),30)]"`
5. Commit the one book, then move to the next.

**Scale.** ~96 batches × 2 agents + 12 survey/merge/gates agents ≈ **200 agents**, 40–70 per run,
roughly 6–8M tokens across all four. That is well past this session's default workflow size
(<10 agents), so each run needs your explicit go.

## 7. Done when

- each of the four JSONs holds ≥ 3,000 entries (or a reported, reasoned shortfall under §6.3)
- every `mustHave` is present (the merge prints `MUST-HAVE n of n`)
- cross-book check: no term appears in two of {idioms, startup, philosophy, classical} beyond
  the 3 overlaps that ship today
- both builds green: `xcodebuild … -scheme OneWord` and `-scheme OneWordWidget`
- all five gates green: `check_words check_related check_learned check_capture check_premium`
  (`check_premium` exists only once `feat/premium` merges; before that, four)
- 0 empty fields across the four books (Philosophy's 120 empty examples gone)

## 8. Out of scope

- **UI copy with counts:** none exists today (grepped). If the premium bar later quotes "N words",
  it reads these numbers.
- **Adding Philosophy to `RelatedWordsCheck` bar 3:** its "136/138 by nature" exclusion reason
  goes away at 3,000, but tightening a gate is a separate change. Try it after.
- **The other books** (Everyday English, Emotions, Urdu, German): Urdu has its own `expand-urdu`
  workflow.
