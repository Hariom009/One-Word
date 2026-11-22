# Entry images — plan

Wire a real, related image onto every word in the **live** dictionaries except Everyday
English, and a short clip onto every Cats & Dogs entry.

Scope, as the shelf actually stands (`OneWord/Shared/Shelves.json`):

| Book | id | Entries | Wants |
|---|---|---|---|
| Dictionary of Emotions | `emotions` | 500 | one image per word |
| Dictionary of Corporate Slang | `startup` | 500 | one image per word |
| Dictionary of Cats & Dogs | `pets` | 33 | one clip per entry (sounds already shipped) |

Everyday English is out of scope by instruction. Idioms, Philosophy, Classical, Urdu,
German, Sanskrit and the Picture Book are `false` in `Shelves.json` and out of scope until
they are switched on.

**1,033 assets.** That number is the whole plan. Everything below is about not paying for
it twice.

---

## 1. What already exists — do not rebuild it

The wiring is done. This was built out during the feed and hero work and is on `main`:

- `Word.image: String?` and `Word.clip: String?` — `OneWord/Shared/Word.swift`, both
  optional with defaults, so every book that has no media decodes unchanged.
- `WordDetail.entry(_:related:)` draws clip → photo → nothing, and `HomeHero` draws
  clip → photo → a placeholder in the book's cover cloth.
- `ClipLoop` — `OneWord/Views/ClipLoop.swift`, silent looping video, plays only on the
  page you are on, stands down for Reduce Motion and Low Power Mode.
- `OneWord/Pictures/` and `OneWord/Clips/` sit inside the synchronized root group, so
  files dropped there join the app target with no `project.pbxproj` edit.

**So this is not a code project.** It is a sourcing project with a small gate at the end.
The only Swift that needs writing is §7.

The format contract is already set by the 243 Picture Book photos, and should not be
re-litigated: JPEG, **≤800px on the long edge, q72, ~65KB**, named `<book>-<term-slug>`.
Clips: H.264/HEVC `.mp4`, **no audio track**, 2–4s cut to loop, 720p long edge.

## 2. The constraint wall

From `Docs/06_Misc/VISUAL_ELEMENTS_PROMPT.md` §2, and non-negotiable:

- **Offline and bundled.** No image API at runtime, no CDN, no fetch-per-word. Whatever we
  use ships inside the app.
- **No stock, no copyrighted imagery.** We told Apple no copyrighted material is included.
  Every asset is CC0, public domain, or made by us, and every one carries a licence we can
  show.

`Docs/06_Misc/PICTURES_IMAGE_SOURCES.md` is the standard to match: Wikimedia Commons,
filtered on the structured licence statement **and** each file's own `LicenseShortName`,
one photo chosen by eye from six candidates, and a table of Term / File / Licence / Author /
Source URL for every single file. That doc is why we can answer a review question in one
minute instead of one week. The new books get the same table or they do not ship.

## 3. The problem this plan exists to solve

The Picture Book worked because its words are **concrete nouns**: acorn, ambulance, bee.
Commons has a photograph of each. Run the same process over the new books and it collapses:

| Book | What the terms are | Commons photo of it? |
|---|---|---|
| `pets` | 20 dog sounds, 12 cat sounds, 1 both | **Yes.** Concrete animals doing concrete things. |
| `emotions` | 244 adjectives, 135 nouns, 79 verbs — `agog`, `acidulous`, `abreaction` | **No.** There is no photograph of *agog*. |
| `startup` | 201 phrases, 185 nouns, 61 idioms — `10-K`, `AARRR`, `accelerated vesting` | **No**, and 358 of 500 are multiword jargon. |

A literal image search over abstract terms returns either nothing or something actively
wrong, and the failure is silent: you end up with 500 files that each look fine alone and
read as noise in the app. **Any plan that treats all three books the same is wrong.**

So: three books, three sources.

## 4. Sourcing, per book

### 4a. Cats & Dogs (33) — photos, not clips

> **Corrected 2026-11-23 after measuring.** This section first said Commons had CC0 video
> of dogs barking and cats trilling. It does not, and the reason is structural rather than
> a gap we can search around: **Commons titles media by subject, not by behaviour.** A video
> of a purring cat is filed as "My cat Mittens", so no query reaches it. Measured over the
> 33 terms: `purr`, `meow` and `growl` return zero CC0/PD videos; only `howl` hits.

Photos are the exception, because people caption a photo with the action it shows —
"A large chained dog howling", "Cat yawning - DSC00577.jpg", "Angry cat by Juliet van Ree".
So this book takes **stills**, queried in gerunds with the animal first (`dog howling` finds
the husky; `howl dog` finds nothing).

`Word.image` and `Word.clip` are independent and the view prefers the clip, so hand-shot
video can be dropped in later, per entry, with no rework. That is the better long-term
answer for this book — a dictionary of animal sounds wants moving pictures — but it is a
filming job, not a sourcing one.

33 photos at ~65KB ≈ **2MB**.

### 4b. Emotions (500 images) — public-domain painting, not photography

The insight that makes this book work: **emotion is the oldest subject in art.** Grief,
longing, contempt, elation and tenderness have been painted for six centuries, and the
museums have released it CC0:

- **The Met Open Access** — ~490k CC0 objects, a clean public API, `isPublicDomain` flag.
- **Rijksmuseum**, **National Gallery of Art**, **Art Institute of Chicago** — all CC0 APIs.
- All are mirrored on Commons, so the existing Commons tooling and licence double-check
  still apply.

This is editorially better than a stock photo of a person frowning, it is licence-clean by
construction, and it gives the book a coherent look rather than 500 unrelated photographs.
It also sidesteps the thing stock photography of faces would have cost us: recognisable
private individuals in an app we sell.

**It will not reach 500.** Painting is rich on `grief`, `rapture`, `tenderness` and thin on
`acidulous` and `abreaction`. That is fine — see §6.

### 4c. Corporate Slang (500 images) — the honest one

This has the lowest yield of the three and I would not promise coverage.

The usable seam is public-domain **documentary and archival photography** of work: the US
National Archives, Library of Congress FSA/OWI collection, NASA, and government record
photography — typing pools, trading floors, assembly lines, boardrooms, filing rooms. It
illustrates `hiring freeze`, `back office`, `headcount`, `war room` and `paper trail` well
and with some wit.

It illustrates `AARRR`, `10b5-1 plan` and `non-GAAP` not at all, and nothing will. Those
terms are not depictable, and a generic photo of a chart under each one is worse than no
image. Expect something like a third of the book to land; measure it in §8 before
committing further.

## 5. The pipeline

A new `tools/fetch_assets/`, shaped exactly like `tools/gen_words/`: a README with
reproduce steps, knobs and an honest ceiling; nothing from it ships in the app.

```
tools/fetch_assets/
├── README.md          reproduce, knobs, ceiling — the gen_words pattern
├── search.py          term -> candidate list (Commons / Met / NARA), licence-filtered
├── shortlist.py       writes candidates/<book>-<slug>/ (6 per term) + a contact sheet
├── install.py         chosen file -> ≤800px q72 JPEG -> OneWord/Pictures/<book>-<slug>.jpg
└── provenance.py      -> Docs/06_Misc/<BOOK>_IMAGE_SOURCES.md
```

Four stages, deliberately split so the slow human step is isolated:

1. **Search** is automated and licence-filtered at the query, never after. A candidate that
   is not CC0/PD never reaches the shortlist, so no one can pick it by accident.
2. **Shortlist** writes six candidates per term to disk as a contact sheet. No judgement.
3. **Pick** is by eye, one per term, and is the only step that cannot be automated. This is
   the real cost of this project — budget for it honestly rather than pretending a script
   chooses well.
4. **Install** downsamples, names, writes the `image` field into the book's JSON, and
   regenerates the provenance table. Idempotent and re-runnable.

Licence verification is **two independent checks**, as the Picture Book did: the structured
licence/copyright-status statement on the search, then the file's own `LicenseShortName` at
install. A file that fails either is dropped, not fixed up.

## 6. Partial coverage is the design, not a failure

`Word.image` is optional and `WordDetail`/`HomeHero` already fall back cleanly — photo, then
clip, then the book's cover placeholder. A book that is 60% illustrated is not broken; it is
a book where 60% of entries have a picture.

This matters more than it sounds. It means:

- We never pick a bad image to fill a hole. The bar is "better than the placeholder," and
  when nothing clears it, nothing ships.
- The work is **resumable**. Ship 150 images, then 150 more, with no migration and no
  release coupling.
- The Picture Book's discipline carries over: record the terms cut for want of a usable
  free image, and the weak keepers worth swapping later. That list is how the next pass
  knows where to start.

## 7. Wiring — the only code in this plan

Two things, both small.

**An eighth gate, `tools/check_assets.sh`**, in the shape of the existing seven. It walks
every live book's JSON and asserts:

- every `image` value resolves to a file in `OneWord/Pictures/`
- every `clip` value resolves to a file in `OneWord/Clips/`
- no file in either folder is unreferenced by any book
- every image is ≤800px on the long edge and every clip has no audio track

Today `pictures.json` has 243 refs, 243 files and zero dangling either way. A gate is what
keeps that true once three more books are writing into the same folders, and it catches the
one failure mode that is invisible in the simulator and fatal in the build: a file that was
renamed but not re-referenced.

**A provenance doc per book**, `Docs/06_Misc/EMOTIONS_IMAGE_SOURCES.md` and
`STARTUP_IMAGE_SOURCES.md` and `PETS_CLIP_SOURCES.md`, generated by `provenance.py` and
checked in beside `PICTURES_IMAGE_SOURCES.md`.

No change to `Word`, `WordDetail`, `HomeHero`, `ClipLoop` or the widget. The widget renders
text only and stays that way — a widget cannot play video and should not carry 65MB of
images into an extension with a tight memory limit.

## 8. Sequence

Each phase ends with something shippable, and phase 2 exists to kill the project cheaply if
the yield is bad.

**Phase 1 — Cats & Dogs, 33 photos.** Smallest set, concrete subjects, and small enough to
redo — which is the point, because its real job is to exercise the pipeline end to end and
find out what it is actually like. It already earned that: it is where we learned video is
unsourceable here, that `application/ogg` is an audio mime, and that Commons rate-limits
hard enough to turn a sweep's numbers into fiction if failures are swallowed. All three
findings cost one afternoon on 33 entries instead of a week on 1,000.

**Phase 2 — the yield measurement. RUN 2026-11-23. Result: stop.**

The bar was ≥70% run it, 40–70% accept partial coverage, <40% come back with a different
answer. Measured, on 40 random terms per book:

| Source | Book | Usable | Note |
|---|---|---|---|
| Commons video | `pets` | ~0% | `purr`, `meow`, `growl` return nothing at all |
| Commons photo | `pets` | 3/33 = **9%** | counted by eye off the contact sheets |
| Art Institute of Chicago | `emotions` | 2/40 = **5%** | 6 title-matched, 4 of those by accident |

The Emotions number is the one that settles it, because art was the strong idea here —
emotion *is* the oldest subject in painting. The measurement says the collections are not
**indexed** by it. Ribera's painting of grief is catalogued as *Penitent Saint Peter*, not
as grief; AIC returned "Self-Portrait" as its best public-domain match for twenty-five
different feeling words, and `madden` matched *Madame* Dugazon.

**The wall is the same one three times over, and it is worth naming once:** free image
collections are catalogued by subject, title and sitter — never by the behaviour or the
feeling depicted. A dictionary of abstract words cannot be illustrated by searching other
people's catalogues, however large or well-licensed they are. No better query fixes this;
it is a property of the metadata, not of the search.

Also worth recording for anyone who tries again: the **Met Open Access API is gone** (HTTP
410 on `collectionapi.metmuseum.org`), and AIC needs an `AIC-User-Agent` header or answers
403.

**Phase 3 — Emotions, generated, ~100 entries not 500.** Phase 2 closed the sourcing route,
so these are made rather than found, the way Cats & Dogs now is (see
`Docs/06_Misc/PETS_IMAGE_PROMPTS.md` for the shape: one fixed style block, one short scene
line per term, generated in small batches so the set does not drift).

Not all 500, and this is the proportionate call rather than a concession. The feeling words
worth a picture are the vivid ones — `disenchantment`, `indignity`, `grievous`. Nobody
needs an illustration of `incurious`, and a generated image for it would be a shrug with a
frame around it. Roughly 100 covers what is worth covering at a fifth of the work, and
`Word.image` is optional with a clean fallback, so the other 400 simply read as they do now.

**Phase 4 — Corporate Slang.** Unchanged in its conclusion and now better evidenced: if
public-domain *painting* yields 5% on emotion, archival photography will not do better on
`non-GAAP`. Leave this book unillustrated unless someone wants to generate it too.

## 9. Size budget

| | Count | Each | Total |
|---|---|---|---|
| Pets photos | 33 | 65KB | 2MB |
| Emotions images | ≤500 | 65KB | ≤33MB |
| Slang images | ≤500 | 65KB | ≤33MB |
| | | | **≤68MB added** |

Against ~16MB of Pictures and ~25MB of asset catalog today. Full coverage of all three is
the worst case and partial coverage is the likely one.

If it gets uncomfortable, **On-Demand Resources** is the right answer rather than
compressing harder: tag each book's images and download them when the reader turns that
dictionary on. The shelf model already gives us the switch to hang it off, and a reader who
never opens Corporate Slang never pays for its 33MB. Do not reach for this until a measured
archive size says we need it — check the App Store cellular download limit at that point
rather than trusting a remembered number.

## 10. Decisions I need from you

1. **Corporate Slang.** I think it is the weak one and I would run phase 2 before promising
   anything. Do you want it attempted regardless?
2. **Emotions as painting.** This gives the book a strong, coherent, slightly literary look.
   If you wanted photography instead, say so now — it changes the source, not the pipeline.
3. **The picking step.** One image per term chosen by eye is ~1,000 judgements. I can do it,
   but it is the bulk of the cost and you may want to do the Emotions pass yourself since it
   is the one that sets the book's character.

## Not doing

- **Everyday English.** Out of scope by instruction, and at 5,566 entries it would dwarf
  everything above.
- **The hidden books.** Idioms, Philosophy, Classical, Urdu, German, Sanskrit, Picture Book
  — not live, not in scope. Note that the Picture Book is a finished 243-entry illustrated
  dictionary sitting at `false`; turning it on is a separate, much cheaper conversation.
- **AI-generated imagery.** It would clear the licence bar faster, but 1,000 images at a
  consistent style is its own project, and "every asset is CC0 or public domain with a
  source URL" is a much stronger thing to be able to say to App Review than "we generated
  them."
- **Images in the widget.** Memory limit, no benefit.
