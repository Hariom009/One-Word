# Word data generation

`OneWord/Shared/words.json` (the ~5.6k word-a-day list) is **generated**, not hand-written.
Source: Princeton **WordNet** (open license) for terms/POS/definitions/examples, filtered to
a "good vocab" frequency band, with **Hindi** produced offline by **Argos Translate**
(no API key, nothing from this pipeline ships in the app).

`hindi` is a translation of the **definition**, not the bare word — single abstract words
mistranslate badly offline (`ephemeral → भैंस`/"buffalo"), but the definition gives the NMT
enough context to be right.

## Reproduce / regenerate

```bash
python3 -m venv venv
./venv/bin/pip install nltk argostranslate wordfreq
./venv/bin/python -c "import nltk; nltk.download('wordnet'); nltk.download('omw-1.4'); nltk.download('stopwords')"
# install the offline en->hi model
./venv/bin/python - <<'PY'
import argostranslate.package as p
p.update_package_index()
pkg = next(x for x in p.get_available_packages() if x.from_code=='en' and x.to_code=='hi')
p.install_from_path(pkg.download())
PY

./venv/bin/python extract.py       # WordNet -> candidates.json (~12k, frequency-banded)
./venv/bin/python translate.py     # candidates.json -> words.gen.json (adds Hindi, ~20 min)

# finalize: blank the ~0.3% entries Argos left with no Devanagari, then install into the app
./venv/bin/python - <<'PY'
import json
d=json.load(open("words.gen.json"))
for w in d:
    if not any('ऀ'<=c<='ॿ' for c in w["hindi"]): w["hindi"]=""
json.dump(d, open("../../OneWord/Shared/words.json","w"), ensure_ascii=False, indent=2)
print(len(d), "words written")
PY
```

## Themed dictionaries (e.g. Emotions)

`emotions.json` is a dictionary of **only** feeling/mood/emotion words. The purity rule: a
word is kept solely if its **dominant WordNet sense** is inside the emotion domain — the
hyponyms of `emotion.n.01` + `feeling.n.01` + `mood.n.01`, their derived adjectives/verbs,
and attribute adjectives (happy ← happiness). Gating on the *dominant* sense (not any sense)
is what drops generic words whose main meaning isn't a feeling ("able", "concentrate",
"dingy"), leaving ~990 genuine emotion words. Reuse this rule for any themed dictionary:
pick the domain's WordNet root(s), keep words whose dominant sense sits under them.

```bash
./venv/bin/python emotions_extract.py     # -> emotions_candidates.json
./venv/bin/python emotions_translate.py   # translates + writes ../../OneWord/Shared/emotions.json
```

Honest ceiling: with the dominant-sense purity gate, WordNet yields ~990 genuine emotion
words. There is no set of 5,000 real emotion words — reaching that needs an emotion-*association*
lexicon (e.g. NRC EmoLex, non-open license) and includes words that merely carry emotional
connotation. To add a themed dictionary: write an extractor like this, then register a
`Wordbook(id: "<name>", name: "…")` in `OneWord/Models/Wordbook.swift` (the `id` is the JSON name).

## Knobs (in `extract.py`)
- `LO, HI` — the wordfreq zipf band (currently `3.0–3.6`): raise `LO` for rarer/harder words,
  raise `HI` to admit more everyday ones. `HI` was `5.6` until the trim; that ceiling is what
  put `cat` (4.8), `give` (5.7), `health` and `music` in a word-*a-day* list, so it came down
  to 3.6 — the band where real vocabulary starts outnumbering words you already speak.
- `TARGET` — how many words (currently `12000`, no longer binding: the 3.0–3.6 band yields ~5.6k).
- `easy_inflection` — drops `-ing/-ed/-s/-ly` forms whose base word is common (`freeing`, `banning`,
  `washed`): rare as a surface form, not vocabulary.
- `BAD` — substrings that drop crude/sensitive glosses.
- Both the selection and the day-order use fixed RNG seeds, so runs are reproducible.

Ceiling: offline NMT occasionally transliterates a rare English word inside the Hindi instead
of translating it. Swap in a higher-quality translator here (e.g. an LLM batch) if that matters.

## Trimming a dictionary (`trim.py`)

`emotions.json` and `startup.json` were cut from ~3,000 entries each to 500 by
`trim.py`, which is reproducible and deterministic (ties break on an md5 of the term,
not alphabetically — an alphabetical tiebreak handed the first attempt 500 entries
covering five letters).

```bash
python3 -I trim.py emotions 500 ../../OneWord/Shared/emotions.json
python3 -I trim.py startup  500 ../../OneWord/Shared/startup.json
```

Two filters, because the books are not alike. **Emotions** carries a scraped WordNet
layer — 652 entries sharing a definition with another, 340 sharing an example, some
still with "- Edmund Burke" hanging off them — and that layer is cut outright.
**Corporate Slang** has none of it, so there the cut is a ranking rather than a rescue:
`idiom` and `phrase` are what a slang book is for, while the `acronym` shelf is mostly
finance and pharma (MLR, MSL, 8-K) and keeps a seat rather than a third of the book.

Emotions also pushes words that are already in Everyday English to the back. A feeling
word you already know teaches nothing and shows up twice in a cross-book search.

**Known cost, unresolved:** the well-formedness filter requires an example, and 98
flagship emotion words are stubs without one — `anger`, `compassion`, `desire`,
`apathy`, `boredom`, `melancholy`, `nostalgia`, `euphoria`. They are therefore cut, so
the trimmed book has no entry for *anger*. `tools/check_related.sh` fails on this
(`emotions has no term melancholy`), and that failure is load-bearing: it is the gate
noticing a real content problem, not a stale fixture. Fixing it means writing examples
for those 98, not re-pinning the gate.
