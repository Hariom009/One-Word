# One Word — Dictionary Sources Scout Prompt

> Run as `/scout research` and paste everything below the line as the brief. Written
> 2026-10-21 on `release/1.0`. Companion to [DICTIONARY_LINEUP_SCOUT_PROMPT.md](DICTIONARY_LINEUP_SCOUT_PROMPT.md),
> which asked *which* dictionaries users want; this one asks *where we can legally get them*.

---

You are Scout, a product researcher. Answer one decision for **One Word**: **for each
dictionary pack we might sell, how many real sources exist, and how many of them can we
legally bundle in a paid app?** Count them, check every licence, and sort them into buckets.

This is a sources census, not a competitor teardown. Use the App Store leg only for
question E (where competitors get their content). Everything else is web research.

## The product (hold this framing)

- **One Word** is a macOS app + desktop widget that shows one word a day from the
  dictionary the user picks. It is offline: every dictionary ships inside the app as a
  bundled file. No API calls at runtime, ever.
- Each entry has: **term, part of speech, a short definition, an example sentence, and a
  Hindi gloss** (a Hindi rendering of the definition).
- We **rewrite and shorten** definitions into our own house style, and we **translate** them
  into Hindi. So any source we use must allow **modification and translation**, not just copying.
- Some packs will be sold behind a **one-time in-app purchase**, worldwide, on the Mac App
  Store. So the licence must allow **commercial use** and **redistribution inside a paid,
  closed-source app**.
- Today our content is our own writing or derived from **Princeton WordNet**. We told Apple
  "no copyrighted dictionary or publisher material is included". Every new source must keep
  that statement true, or come with a licence we can show.

## Packs to research

1. **Sociology** — terms, with the thinker who coined each where there is one (Durkheim, Bourdieu…).
2. **Feelings English has no word for** — *real* words from other languages (saudade, hiraeth,
   toska, Urdu words like intezaar). **Exclude John Koenig's coined words** (*The Dictionary of
   Obscure Sorrows*: sonder, opia, vellichor…). Report that book's copyright/trademark status
   and whether the author offers licensing, but do not treat its words as a source.
3. **Urdu** (written in Devanagari for Hindi readers), including Urdu poetry/shayari vocabulary.
4. **Psychology**, **Economics**, **Law**, **Medicine**, **Literary terms**.
5. **Classical English** (rare/old words), **Philosophy**, **Latin & Greek roots**, **German**.
6. **Anything else** you find with a strong open source behind it. Say what it is and why.

## Questions — answer each with evidence

**A. Census.** For each pack: list every dictionary, glossary, word list or lexical dataset you
can find. Include all kinds:
- published dictionaries (Oxford, Cambridge, Collins, Routledge, SAGE, Bloomsbury, Penguin
  "Dictionary of X")
- open datasets (WordNets, Wiktionary, Wikidata)
- public-domain books (old dictionaries whose copyright has expired)
- government glossaries
- open textbooks with glossaries
- university open courseware
- academic lexicons

Give the total count per pack.

**B. Licence check, per source.**
- the exact licence name, with a link to the licence text
- commercial use allowed? (Y / N / unclear)
- modification and translation allowed? (Y / N / unclear)
- share-alike? If yes, what it would force on us: would our rewritten pack have to be
  released under the same free terms?
- what credit is required, and can a credits screen inside the app satisfy it?
- what the licence actually covers: the word list only, definitions, examples, or all of these
- any **website terms of use on top of the licence**. A public-domain book on a site that
  forbids scraping is still a problem.
- the date you checked

**C. Buckets.** Put every source in exactly one bucket:

| Bucket | Meaning |
|---|---|
| **USE FREELY** | Public domain, CC0, or a permissive licence allowing commercial use + modification with no strings |
| **USE WITH CREDIT** | Allows commercial use + modification; we must credit the source (e.g. CC BY) |
| **USE WITH STRINGS** | Allowed, but with a condition that costs us something: share-alike (CC BY-SA, ODbL), copyleft (GPL), etc. Spell out the cost |
| **LICENSABLE** | All rights reserved, but the owner runs a licensing programme. Give the contact/programme page and any public pricing model |
| **DON'T** | Non-commercial (NC), no-derivatives (ND), all rights reserved with no programme, or a licence you can't find |
| **UNCLEAR** | A licence exists but is ambiguous. Say what a lawyer would need to confirm |

**D. Public domain is country by country.** The app sells worldwide. For each public-domain
source, say on what basis it is public domain. The US cutoff is roughly works published before
1931 as of 2026. Flag the ones that may still be protected elsewhere (India is the author's life
+ 60 years; the EU and UK are life + 70). Also say whether the *digitised* copy we would use
carries its own terms.

**E. How competitors source content.** Which word-a-day and vocabulary apps say where their
definitions come from? Licensed Oxford / Collins / Merriam-Webster data, WordNet, Wiktionary,
their own writing? Look at app listings, credits/about pages and press. Also list any copyright
takedowns, lawsuits or App Store removals involving dictionary apps or scraped dictionary content.

**F. Feelings pack specifics.** Find open sources of real "untranslatable" emotion words: research
lexicons (check the licence of the data, not just the paper), Wiktionary categories, Wikidata.
Note how often popular "untranslatable words" lists get meanings wrong, according to native speakers.

**G. Urdu specifics.** Platts' *Dictionary of Urdu, Classical Hindi and English* (1884) and similar
old works: confirm public-domain status, and check the terms of the digitised editions
(e.g. Digital Dictionaries of South Asia). Check what Rekhta's dictionary allows. Check whether
any IndoWordNet / Hindi WordNet / Urdu WordNet licence permits commercial use.

## Starting points — verify each, don't trust this list

Princeton WordNet · Open English WordNet · Open Multilingual WordNet (licences differ per
language) · Wiktionary · Wikidata lexemes · GCIDE · Webster's 1913 · The Century Dictionary ·
Roget's Thesaurus (1911) · Brewer's Dictionary of Phrase and Fable (1898) · OpenStax textbooks
(check each book's licence) · Platts (1884) · Steingass Persian–English · IndoWordNet ·
US government glossaries (NIH/NCI, US Courts, BLS). Add anything better you find.

## Evidence rules

- Every licence claim needs **the licence page link and a verbatim line (≤15 words) from it**,
  plus the date checked. Never infer a licence from a blog post or from "it's on GitHub".
- Tag every finding **OBSERVED** (you read it at the source) or **INFERRED** (your reasoning).
- Never invent a source, a licence, a count or a quote. If you can't find a licence, the bucket
  is DON'T or UNCLEAR, not a guess.
- This is research, not legal advice. Mark the sources a copyright lawyer should confirm
  before we ship.
- Prioritise current licence pages over old mirrors and forum summaries.

## Output

Lead with the two tables.

1. **Headline numbers per pack:**
   `pack | sources found | USE FREELY | WITH CREDIT | WITH STRINGS | LICENSABLE | DON'T | UNCLEAR | best 2 usable sources | can we build it? (YES / YES WITH WORK / ONLY BY LICENSING / NO)`
   End with a grand total row: how many sources found overall, and how many are usable
   (the first three buckets combined).
2. **Source table**, one row per source:
   `source | pack(s) | kind (open dataset / public-domain book / gov glossary / open textbook / publisher / other) | approx. entries | covers (word list / definitions / examples) | licence | commercial? | modify + translate? | share-alike? | credit needed | bucket | licence link | checked`
3. **Per-pack plan:** for each pack, which sources to build the word list from, which to
   draw meanings from, and what we must write ourselves. Two or three lines each.
4. **Competitor sourcing** from question E, and any disputes found.
5. **Risks:** sources that look free but aren't (website terms, country differences,
   share-alike traps, licences that cover the list but not the definitions).
6. **Gaps:** what you couldn't verify, and the cheapest way to check each.
7. **Sources:** every URL you relied on.

Be blunt. If a pack has no usable source and can only be written from scratch or licensed,
say so plainly.
