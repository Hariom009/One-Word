# Asset sourcing

Finds freely-licensed photos and clips on Wikimedia Commons for a dictionary's terms,
and wires the chosen ones into the book's JSON. Nothing in here ships in the app —
only the resized files under `OneWord/Pictures/` and `OneWord/Clips/`, and the
provenance table in `Docs/06_Misc/`.

Licence is checked **twice**, as the Picture Book's 243 photos were: the Commons
licence category on the search, then the file's own `LicenseShortName` at install.
CC BY and CC BY-SA are deliberately refused — free, but they put an attribution
burden inside a shipped app we are not set up to honour.

## Run

```bash
python3 -I search.py pets image          # -> candidates-pets-image.json
# choose one title per term by eye       -> picks-pets.json  {"<term>": "File:…"}
python3 -I install.py pets picks-pets.json image
python3 -I provenance.py pets image      # -> Docs/06_Misc/PETS_IMAGE_SOURCES.md
sh ../check_assets.sh
```

## What we learned the hard way

- **Commons titles media by subject, not behaviour.** Video is therefore unusable for
  a book of animal sounds: a purring cat is filed as "My cat Mittens". Measured on
  the 33 Cats & Dogs terms — `purr`, `meow` and `growl` return zero CC0/PD videos.
  Photos are the exception, because people caption them with the action.
- **Query in gerunds, animal first.** `dog howling` finds the husky; `howl dog` finds
  nothing.
- **`application/ogg` is an audio mime.** Including it made `mew` look like it had 40
  video candidates; they were cat pronunciations and background music.
- **Commons rate-limits hard.** The first sweep spent most of its budget on HTTP 429
  with stderr hidden, and reported a 21% coverage that was entirely false positives
  (`bark` matched a 1945 newsreel — bark as in ship). `api()` now backs off, and a
  run that had any failure says so and refuses to call its number a measurement.

## Knobs

- `FREE_CATEGORIES` — Commons licence categories searched. Adding one costs a round
  trip per term per mime.
- `MIMES` — never put an audio mime in an image or video list.
- `query_terms()` — the phrasings tried per term. This is the highest-leverage knob:
  the yield is mostly a function of guessing how a human captioned the file.

## Ceiling

This finds what someone else already photographed and gave away. For anything nobody
photographs — an abstract term, or a specific behaviour like a *solicitation purr* —
no query will help, and the honest options are to shoot it, draw it, or leave the
entry without an image. `Word.image` is optional and the layout falls back cleanly,
so a partly illustrated book is a normal state, not a broken one.
