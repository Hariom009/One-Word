# Related Words on the Home Screen — Brainstorm

A box at the bottom of today's word showing a few words in the same vein, each with
its own definition and example — so `warm` opens onto `scorching`, `sultry`, `heated`
without leaving the screen.

**Why it fits One Word:** the app currently teaches one word per day and stops. The
words are already written, already carry a definition and an example, and 12,000 of
them sit unread in `words.json`. This feature costs no new content — it just stops
hiding the ones next door.

---

## The only decision that matters: where do "similar words" come from?

Everything else is layout. I measured four options against the real dictionaries
before writing any UI.

### Option 1 — Hand-author a `related:` field in the JSON

Add `"related": ["sultry", "heated"]` to every entry. Perfect quality, total control.

**Killed on arithmetic.** 18,400 entries across eight books. At even 20 seconds of
thought per entry that's 100+ hours, and it re-opens every time you add a word.
`WordCapture.swift` lets you capture words at runtime — those could never have a
hand-authored list at all. Non-starter.

### Option 2 — `NLEmbedding.neighbors(for:)`, Apple's built-in synonym lookup

One line, no data, system framework. It works:

```
warm       → chilly, cool, warmth, warms, hot, toasty
melancholy → melancholic, wistful, wistfulness, mournful, elegiac, reverie
```

**Killed on the feature's own requirement.** You asked for similar words *with their
use case*. These come from Apple's 57,171-word vocabulary, not ours — `toasty` and
`elegiac` have no definition and no example in this repo, so there is nothing to put
in the box beneath them. A bare list of words is a different, weaker feature.

### Option 3 — Rank our own entries by term-to-term embedding distance

Score every word in the open dictionary against today's term, take the top few. Now
each result is a real `Word` with its definition and example already written.

Fast — 12,000 comparisons in **0.01s**. But two measured problems:

| dictionary | entries | terms with a word-vector |
|---|---|---|
| words | 12,000 | 95.8% |
| emotions | 987 | 69.7% |
| philosophy | 138 | 62.3% |
| startup | 1,506 | **29.9%** |
| medical | 1,736 | **28.8%** |

Apple's vocabulary has no vector for `Weltschmerz`, `10x engineer`, `+1`, or
`tachycardia`. On the medical and startup books, **~70% of days would show an empty
box**. And the results skew morphological: `warm` → `warmed`, `warmer`, `warmth`.

### Option 4 — Rank our own entries by the *meaning* of term + definition ✅

Same as option 3, but the thing we compare isn't the bare term — it's the average of
the word-vectors of the term **and its definition**, normalised. A word we can't
vectorise is still covered, because its definition is ordinary English.

That one change fixes the coverage table outright:

| dictionary | entries | coverage | index build |
|---|---|---|---|
| words | 12,000 | **99.98%** | 2.38s |
| medical | 1,736 | **100%** | 0.41s |
| startup | 1,506 | **100%** | 0.37s |
| emotions | 987 | **100%** | 0.14s |

And the results are the ones you'd actually want:

```
emotions/melancholy → wistful          showing pensive sadness
                      heavyheartedness a feeling of dispirited melancholy

startup/10x engineer → zero to one     creating something genuinely new rather than
                                       improving what already exists
                       network effect  when each new user makes the product more
                                       valuable for everyone else
```

That startup result is the tell: `10x engineer` is a multi-word term with **no word
vector at all**. Option 3 could not have returned anything for it. Ranking on meaning
reaches every entry in every book — including words captured at runtime.

Ranking itself is **sub-10ms** once the index exists.

**Recommendation: option 4.** No new dependency (`NaturalLanguage` is a system
framework), no new content, no build step, one code path for all nine dictionaries.

### What I rejected on the way

`NLEmbedding.sentenceEmbedding` over the definitions has the same 100% coverage and
slightly better semantics — and takes **59 seconds** for 12,000 entries. 2,000× slower
than averaging word vectors, for a marginal quality gain. Not viable.

Precomputing the neighbour lists offline into the JSON would make runtime free, but it
adds a regeneration step you must remember on every dictionary edit, and it structurally
cannot serve "My Words" — that book is generated on the user's machine. Runtime compute
covers it uniformly. Revisit only if the index build becomes a felt cost.

---

## Honest limitations (design around these, don't paper over them)

1. **Embeddings capture relatedness, not synonymy.** Measured: `warm` → `scorching`,
   `heated`, and `dank` ("unpleasantly cool and humid"). Antonyms and siblings sit
   close to synonyms in this vector space. There is no cheap fix — so **don't label
   the box "Similar words"**, which promises synonymy the data can't deliver. "In the
   same vein" or "Related words" is honest about what's actually being shown.
2. **Near-duplicate results.** `melancholy` returns both `wistful` and `wistfulness`.
   Filtering candidates that share the query's first four characters kills
   `warm`/`warmed`/`warmer`, but not siblings of each other — dedupe across results by
   shared stem too, or you spend a slot on the same idea twice.
3. **`NLEmbedding.wordEmbedding(for: .english)` is optional.** It returned a valid
   model on this Mac, but the API can hand back `nil`. The box should hide, not crash
   or show an error — this is a garnish, not the screen.
4. **The index costs memory.** 12,000 × 300 dimensions is ~29MB as `Double`, ~14MB as
   `Float`. Store `Float`. The other books are under 2MB each.
5. **App only — keep it out of the widget.** Widget extensions run under a hard memory
   ceiling; a 14MB index and a 2.4s build have no business in a timeline provider.

---

## Shape of it

**Placement.** Bottom of `WordDetail.swift`, below the existing "Used as" footer, behind
the same hairline-rule idiom the footer already uses. It renders in both the daily view
and the list's detail screen for free, since `WordView` and `WordListView` both go
through `WordDetail`.

**Content.** Three entries. Each row is the term in the serif face, the part of speech
in muted italic, the definition, and — the part you specifically asked for — its
example, since that's where a word's actual use lives. Every one of those fields is
already populated in the JSON.

**Interaction.** Each row is a `NavigationLink` to `WordDetail` for that word. That
navigation pattern already works in `WordListView.swift`, so it's reuse, not new
plumbing — and it turns the feature into a browsable chain: warm → scorching → sultry.

**Where the code goes.** A new app-target file (not `Shared/` — everything in there is
documented as belonging to both targets, and this must not reach the widget). It needs
the open dictionary's `[Word]`, which `WordProvider.allWords` already exposes.

**Threading.** The 2.4s index build must not block the main actor — build it in a
background task on dictionary load and let the box appear when ready. Build **once per
dictionary and keep it**, rather than streaming to O(1) memory: the "New Word" shuffle
button changes the word constantly, and each press must stay instant.

---

## Open questions worth your call

1. **Three results, or five?** Three keeps the daily screen calm; five makes the box a
   real detour. I'd start at three.
2. **Restrict to the same part of speech?** Would tighten `warm` (adjective) toward
   other adjectives and drop `heated`. Cheap to add, but it thins the pool in the small
   books — `character` and `eloquence` have 20 entries each.
3. **Cross-dictionary results?** `melancholy` in Everyday English has better neighbours
   in the Emotions book. Richer, but it muddies "you are reading book X" and multiplies
   the index cost by nine. I'd keep it within the open dictionary.
4. **The 20-entry books.** `character`, `eloquence`, `curiosities` have 20 words each.
   Nearest-neighbour in a 20-word pool returns near-strangers. Consider a minimum
   similarity threshold below which the box simply doesn't render.

---

## Verification, when it gets built

`tools/check_words.sh` already compiles the real `Shared` sources standalone and
asserts on the day→word mapping. The same pattern fits here: a `tools/check_related.sh`
that builds the index for each book and asserts coverage stays ≥99% and that a handful
of known pairs (`melancholy` → `wistful`) still rank in the top three. That's the check
that fails loudly when someone edits a definition and quietly wrecks the neighbours.
