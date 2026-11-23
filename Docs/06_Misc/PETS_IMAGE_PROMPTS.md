# Cats & Dogs — image generation prompts

33 images, one per entry in `pets.json`. Paste **§1 once** at the top of the session so the
model holds the style, then paste the scene lines from §3 one at a time (or in batches of
five or six — more than that and most tools start drifting or dropping items).

Save each file under the **exact filename in the table**. Drop them all in
`OneWord/Pictures/`, tell me, and I will write the `image` fields and run the gate — that
part is already built.

---

## 1. Style block — paste this first, verbatim

```text
We are making a set of 33 photographs for a printed dictionary of cat and dog sounds.
They must read as ONE set, shot by one photographer on one camera in one week.

Hold these fixed for every image in this session:

- Photoreal documentary photography. Not illustration, not 3D, not stock-cheerful.
- Natural available light, mostly soft and directional, as if from a window or an
  overcast sky. No flash, no studio seamless, no coloured gels.
- Shallow depth of field, 50mm or 85mm look. The animal is sharp, the background falls
  away into quiet tone.
- Muted, slightly desaturated palette. Warm greys, oatmeal, faded green, worn wood.
  Nothing neon, nothing candy-coloured.
- Quiet domestic settings: a hallway, a kitchen floor, a window ledge, a garden wall,
  a stretch of pavement. Lived-in, never styled.
- One animal per frame unless the line says otherwise. An ordinary mixed-breed animal,
  not a show dog, not a pedigree glamour cat.

Composition, every time:
- 3:4 PORTRAIT, at least 1024 x 1365.
- The animal's head and open mouth in the UPPER TWO THIRDS of the frame.
- The LOWER THIRD must stay simple, dark and uncluttered — floor, shadow, plain
  ground. Large type is printed over it, so nothing important goes there.
- Leave a little air around the subject. Do not crop tight to the face.

Never include:
- Any text, letters, numbers, captions or watermarks.
- Logos, brand marks, or collar tags with writing on them.
- A recognisable human face. A hand, an arm or a body from behind is fine.
- Cartoon exaggeration, speech bubbles, motion lines, or a comedy expression.

The subject of every photograph is a SOUND the animal is making. The open mouth,
the throat, the ears and the body posture are the picture. If the animal's mouth is
shut and its posture is neutral, the photograph has failed.
```

## 2. Technical, if the tool asks

| | |
|---|---|
| Aspect ratio | 3:4 portrait |
| Minimum size | 1024 × 1365 |
| Format to save | JPEG or PNG — I downsample to 800px long edge, q72 |
| File naming | exactly as the table below |
| Bottom 6% | **discarded on install** — it is where the generator stamps its watermark. Keep nothing there. |

## 3. The 33 scene lines

Each line is appended to the style block. Keep them short — the style block is doing the
heavy lifting, and long per-image prompts are what makes a set drift apart.

| # | Term | Save as | Scene line to paste |
|---|---|---|---|
| 1 | alarm bark | `pets-alarm-bark.jpg` | A dog standing rigid at a front window, weight forward, ears pricked hard, mouth open mid-bark at something outside the glass. |
| 2 | bark | `pets-bark.jpg` | A dog in a hallway caught mid-bark, head level, mouth open, ordinary and unremarkable — the plain version of the sound. |
| 3 | bay | `pets-bay.jpg` | A beagle or hound in long grass, head thrown back, long muzzle wide open, neck stretched, calling out on a scent. |
| 4 | caterwaul | `pets-caterwaul.jpg` | A cat on a garden wall at dusk, mouth wide open in a long drawn-out cry, body tense, facing something off-frame. |
| 5 | chattering | `pets-chattering.jpg` | A cat on a window ledge, jaw stuttering half-open, eyes locked on a bird outside the glass. |
| 6 | demand bark | `pets-demand-bark.jpg` | A dog sitting square in front of an empty food bowl, chest up, mouth open, staring straight up and insisting. |
| 7 | groan | `pets-groan.jpg` | A heavy dog collapsing onto a rug, eyes half shut, mouth slightly parted, the whole body letting go at once. |
| 8 | growl | `pets-growl.jpg` | A dog and a cat a short distance apart on a kitchen floor, both low and still, both lips just lifted — a shared warning. |
| 9 | grumble | `pets-grumble.jpg` | A dog half-shifted off a sofa cushion, mouth slightly open, looking put-upon rather than angry. |
| 10 | guarding growl | `pets-guarding-growl.jpg` | A dog lying with a chew between its front paws, head low over it, eyes rolled up watchfully, lip lifted. |
| 11 | hiss | `pets-hiss.jpg` | A cat side-on with its back arched and fur raised, ears flat back, mouth wide open showing teeth. |
| 12 | howl | `pets-howl.jpg` | A dog sitting in a yard, head tipped straight up, muzzle vertical, eyes closed, throat extended in a long howl. |
| 13 | huff | `pets-huff.jpg` | A dog turning its head away, nostrils flared, cheeks pushed out by a sharp exhale through the nose. |
| 14 | isolation bark | `pets-isolation-bark.jpg` | A dog alone in an empty room behind a half-closed door, barking at nothing, the room stretching away unused. |
| 15 | meow | `pets-meow.jpg` | A cat looking straight up at the camera, mouth open mid-meow, front paws together, asking for something. |
| 16 | mew | `pets-mew.jpg` | A small kitten on a blanket, tiny mouth open in a thin soft cry, eyes barely focused. |
| 17 | murmur | `pets-murmur.jpg` | A cat pressing its head into an open human hand, mouth closed, eyes shut, clearly rumbling. Hand only, no face. |
| 18 | play bark | `pets-play-bark.jpg` | A dog in a full play bow — chest and front legs down, rear end up, tail high — mouth open in a bright bark. |
| 19 | play growl | `pets-play-growl.jpg` | Two dogs dragging opposite ends of a knotted rope, both braced, both mock-fierce, nothing serious about it. |
| 20 | play pant | `pets-play-pant.jpg` | A dog stopped after a run, tongue hanging out, chest heaving, mouth wide in an open happy pant. |
| 21 | play sneeze | `pets-play-sneeze.jpg` | A dog mid-sneeze during a game, head shaken sideways, eyes screwed shut, ears flung out. |
| 22 | purr | `pets-purr.jpg` | A cat curled asleep on a lap, eyes closed, chin tucked, utterly settled. Lap and hands only, no face. |
| 23 | shriek | `pets-shriek.jpg` | A cat caught mid-startle, fur standing up along the spine, mouth wide in a sudden cry, body already twisting away. |
| 24 | sigh | `pets-sigh.jpg` | A dog lying with its chin flat on its own front paws, eyes soft and open, mid-exhale, deeply unimpressed. |
| 25 | snarl | `pets-snarl.jpg` | A cat with its lip curled right back off the teeth, ears pinned flat, staring hard at something off-frame. |
| 26 | snort | `pets-snort.jpg` | A dog with its nose pushed into leaf litter, blowing out sharply, loose leaves and dust lifting around its muzzle. |
| 27 | solicitation purr | `pets-solicitation-purr.jpg` | A cat beside an empty bowl, front paws kneading, looking up and holding the stare, mouth closed but clearly working on you. |
| 28 | trill | `pets-trill.jpg` | A cat walking toward the camera with its tail straight up, mouth making a small round chirp, ears forward in greeting. |
| 29 | whimper | `pets-whimper.jpg` | A small dog with its ears folded back and one front paw lifted, mouth barely open, pleading quietly. |
| 30 | whine | `pets-whine.jpg` | A dog pressed against a closed door with its nose at the gap underneath, ears back, mouth slightly open. |
| 31 | yelp | `pets-yelp.jpg` | A dog recoiling sharply, one paw snatched up off the ground, mouth open in a short startled cry, eyes wide. |
| 32 | yip | `pets-yip.jpg` | A small terrier or puppy mid-bounce with all four feet nearly off the ground, mouth open in a sharp little bark. |
| 33 | yowl | `pets-yowl.jpg` | A cat sitting upright on a stair, head raised, mouth held wide open in a long complaining cry. |

## 4. Watch for these

The five barks and three growls are the ones that will come back identical if you let
them. They are different **situations**, not different noises — alert at a window,
demanding at a bowl, alone in a room, bowing in play. If two of them look the same,
regenerate with the situation pushed harder, not the bark.

Other failure modes worth a second look:

- **A closed mouth.** The most common failure. If the animal isn't visibly making a
  noise, the picture is of a pet, not of a word.
- **A busy lower third.** The headword prints over it. Rug patterns, scattered toys and
  bright floor tiles all fight the type.
- **Comedy.** These sit under a serif headword and a Hindi gloss. A meme-grade expression
  breaks the book.
- **Drift.** Generate in small batches and compare batch 4 against batch 1. If the light
  or the palette has wandered, re-paste the style block.

## 5. About "animated"

Generate **stills**. The motion is added afterwards for free: a slow 4-second push-in
and drift, looped, encoded as a silent H.264 `.mp4` — which is exactly what `ClipLoop`
already plays, and what the clip contract in `OneWord/Views/ClipLoop.swift` specifies.

That is better than asking a tool for video here: one still per entry is a third of the
cost, it stays sharp, the loop is seamless by construction rather than by luck, and the
same file works as a plain photo on the entry page where no clip is wanted.

Hand me the 33 stills and I will do that pass.

## 6. Licensing note

These are generated for us, so there is no Commons provenance row to write — but the
`Docs/06_Misc/PETS_IMAGE_SOURCES.md` table still gets written, recording the model and
date instead of an author and a file URL. The point of that table is that any question
about any shipped asset has a one-minute answer, and "where did this come from" is the
question most worth being able to answer.

Worth knowing before you commit: our own `Docs/06_Misc/VISUAL_ELEMENTS_PROMPT.md` §2
says every asset must be "made by us, generated by code, CC0, or come with a licence we
can show," and we told Apple no copyrighted material is included. Generated-for-us
clears that. It is a weaker answer than a CC0 file with a Commons URL, which is why the
plan originally reached for Commons first — but at 3 usable photos out of 33, Commons
isn't an option for this book.
