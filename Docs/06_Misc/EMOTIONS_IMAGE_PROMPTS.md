# Emotions — image generation prompts

100 images, for the 100 most **depictable** entries in `emotions.json` — the ones whose
definition names something a body actually does. The other 400 keep the placeholder, which
is a normal state for this book, not a gap: `Word.image` is optional and the entry draws
cleanly without one. There is no photograph of `emotional stability`, and a generated one
would be a shrug in a frame.

Paste **§1 once**, then feed the scene lines from §3 in batches of five or six. Save each
file under the exact filename in the table and drop them in the folder named in §4 — the
wiring is automatic from there.

> Why these 100: scored on whether the definition names a face, a posture, a gesture or a
> voice. `slack-jawed`, `red-faced`, `careworn` and `white-knuckle` score high. `self-
> recrimination` and `idle curiosity` score bottom, and are rightly out.

---

## 1. Style block — paste this first, verbatim

```text
We are making a set of photographs for a printed dictionary of feelings. They must read
as ONE photo essay, shot by one photographer on one camera over one season.

Hold these fixed for every image in this session:

- Photoreal editorial portraiture. Not stock, not advertising, not an actor pulling a
  face. The feeling should look caught rather than performed.
- Natural available light — a window, a doorway, an overcast afternoon. No flash, no
  studio seamless, no coloured gels.
- Shallow depth of field, 50mm or 85mm look.
- Muted, desaturated palette: warm greys, oatmeal, faded blue, worn wood, skin tones
  left natural. Nothing saturated, nothing glossy.
- Ordinary adults in ordinary clothes, in ordinary rooms. Mixed ages and appearances
  across the set. No models, no styling, no make-up that reads as make-up.
- One person per frame unless the line says otherwise.

Composition, every time:
- 3:4 PORTRAIT, at least 1024 x 1365.
- The face or the gesture that carries the feeling sits in the UPPER TWO THIRDS.
- The LOWER THIRD stays simple, dark and uncluttered. Large type prints over it.
- The subject may be turned away, in profile, or cropped — a feeling does not always
  need a full face, and the set is stronger for the variation.

Never include:
- Any text, letters, numbers, captions or watermarks.
- Logos or brand marks.
- Children in distress. Keep every subject an adult.
- Anything clinical or medical in feel — this is a book about ordinary feeling, not
  about illness.
- Exaggerated "emotion face" acting. Understated beats theatrical every time.

The subject of each photograph is the feeling named, as a real person would carry it:
in the eyes, the jaw, the shoulders, the hands.
```

## 2. Technical

| | |
|---|---|
| Aspect ratio | 3:4 portrait |
| Minimum size | 1024 × 1365 |
| Save as | JPEG, PNG or WebP — I downsample to 800px long edge, q72 |
| File naming | exactly as the table below |
| Bottom 6% | **discarded on install** — it is where the generator stamps its watermark. Keep nothing there. |

## 3. The 100 scene lines

Each line is the entry's own definition, trimmed to a direction. That is deliberate: the
picture is then generated from the same words the reader is reading underneath it.

| # | Term | Save as | Scene line |
|---|---|---|---|
| 1 | poker-faced | `emotions-poker-faced.jpg` | Deliberately showing no emotion in the face so that nobody can guess your reaction |
| 2 | disapprobation | `emotions-disapprobation.jpg` | Strong moral disapproval expressed openly |
| 3 | soft-spoken | `emotions-soft-spoken.jpg` | Speaking in a gentle, quiet voice that suggests a calm and unaggressive nature, never raised even in disagreement |
| 4 | nerves | `emotions-nerves.jpg` | A temporary attack of nervous tension and unease before a test or performance, felt in the stomach and the hands |
| 5 | proprietary | `emotions-proprietary.jpg` | Showing a feeling of ownership over a person or project as though others need your permission to touch it |
| 6 | shaky | `emotions-shaky.jpg` | Trembling and unsteady from nerves or shock, with a voice or hands that will not hold still |
| 7 | lordly | `emotions-lordly.jpg` | Behaving with the grand, commanding pride of someone who expects to be obeyed and served, treating others as inferiors |
| 8 | dead-eyed | `emotions-dead-eyed.jpg` | Having eyes that show no feeling or interest, giving an impression of inner emptiness |
| 9 | operatic | `emotions-operatic.jpg` | Expressing feeling on a grand sweeping scale with loud passionate gestures and voice |
| 10 | blub | `emotions-blub.jpg` | To cry noisily and without restraint, in a childish way that you may later feel embarrassed about |
| 11 | careworn | `emotions-careworn.jpg` | Showing the marks of long worry and sorrow, a tired sadness worn into the face over years |
| 12 | slack-jawed | `emotions-slack-jawed.jpg` | Gaping with the mouth hanging open in dumb astonishment or stupefied wonder |
| 13 | toneless | `emotions-toneless.jpg` | Spoken without any rise or fall of feeling, a flat voice that suggests numbness, exhaustion or hidden distress |
| 14 | stone-faced | `emotions-stone-faced.jpg` | Showing no emotion at all on the face, deliberately blank and unmoved in a way that feels chilly |
| 15 | wide-eyed | `emotions-wide-eyed.jpg` | Showing innocent wonder or surprise with eyes opened wide, often from inexperience |
| 16 | chills | `emotions-chills.jpg` | A sudden shiver through the body caused by a powerful emotional moment rather than cold |
| 17 | teary | `emotions-teary.jpg` | Close to tears because of a tender or sorrowful feeling rather than sharp pain |
| 18 | wintry | `emotions-wintry.jpg` | Cold and unfriendly in expression, a smile or look with the chill of a winter morning in it |
| 19 | red-faced | `emotions-red-faced.jpg` | Visibly flushed with embarrassment or shame after being caught in a blunder, the feeling showing plainly on your face before you can hide it |
| 20 | belly laugh | `emotions-belly-laugh.jpg` | A deep, loud, unrestrained laugh that seems to come from your stomach and shakes your whole body |
| 21 | tendresse | `emotions-tendresse.jpg` | A soft tender fondness expressed in gentle gestures rather than in passion or grand words |
| 22 | kilig | `emotions-kilig.jpg` | The giddy fluttery thrill of romantic excitement, butterflies at a crush's smallest gesture |
| 23 | white-knuckle | `emotions-white-knuckle.jpg` | So frightening and thrilling that you grip the nearest thing tightly, tense with fearful excitement |
| 24 | smother | `emotions-smother.jpg` | To force a strong feeling down and out of sight, pressing back anger, grief or laughter so hard that it is almost extinguished |
| 25 | doubtful | `emotions-doubtful.jpg` | Unsure whether something is true or will happen, leaning toward thinking it will not |
| 26 | purr | `emotions-purr.jpg` | To express deep, sleepy contentment in a low, pleased voice, like a cat being stroked |
| 27 | succour | `emotions-succour.jpg` | Help and comfort given to someone in distress or hardship, the relief that reaches a person at their lowest point |
| 28 | fastidious | `emotions-fastidious.jpg` | So demanding about cleanliness and detail that small imperfections provoke distaste and cannot be tolerated |
| 29 | gruff | `emotions-gruff.jpg` | Rough and abrupt in voice and manner, sounding unfriendly even when the intention is kind |
| 30 | leer | `emotions-leer.jpg` | To look at someone with an unpleasant, knowing smile that shows sexual or malicious interest |
| 31 | gushing | `emotions-gushing.jpg` | Pouring out affection or praise in an excessive, breathless flow that can seem insincere |
| 32 | moved | `emotions-moved.jpg` | Feeling a warm, tender swell of emotion in response to something kind, brave or beautiful, often with a lump in the throat |
| 33 | guffaw | `emotions-guffaw.jpg` | To burst out in a loud, hearty and unrestrained laugh that turns heads and cannot be politely swallowed |
| 34 | composure | `emotions-composure.jpg` | The settled calmness that keeps a person steady and unshaken when a situation pushes them toward panic or anger |
| 35 | stirring | `emotions-stirring.jpg` | Rousing a proud, energetic surge of feeling that makes the chest swell, as a great speech or anthem does |
| 36 | anergia | `emotions-anergia.jpg` | In psychiatry, a marked lack of energy and drive so that even ordinary activities feel beyond reach, often part of depression |
| 37 | jokester | `emotions-jokester.jpg` | A playful person who is always cracking jokes and treats most situations as a chance for laughter |
| 38 | stilted | `emotions-stilted.jpg` | Stiff and unnatural in manner, speaking with an awkward formality that reveals discomfort or self-consciousness |
| 39 | keening | `emotions-keening.jpg` | A loud, wailing lament for the dead, and by extension any high, grief-stricken crying that carries raw sorrow |
| 40 | agog | `emotions-agog.jpg` | Eagerly excited and wide-eyed with curiosity to hear or see what happens next |
| 41 | cavalier | `emotions-cavalier.jpg` | Showing a proud, offhand lack of concern about something serious, as though it were beneath your attention |
| 42 | plotz | `emotions-plotz.jpg` | To collapse or burst from overwhelming emotion, whether excitement, laughter or exasperation |
| 43 | caress | `emotions-caress.jpg` | To touch or stroke someone gently and slowly as a way of showing tender affection |
| 44 | cwtch | `emotions-cwtch.jpg` | A warm sheltering cuddle that makes you feel safe and cared for, more comfort than embrace |
| 45 | harried | `emotions-harried.jpg` | Feeling hounded and worried by constant demands and interruptions that leave no room to breathe |
| 46 | rubberneck | `emotions-rubberneck.jpg` | To stare with curiosity at something such as an accident, often slowing down or turning around to keep looking |
| 47 | misandry | `emotions-misandry.jpg` | Hatred or deep contempt for men simply because they are men, the mirror image of misogyny and just as sweeping in its dislike |
| 48 | wimpy | `emotions-wimpy.jpg` | Feebly timid and unwilling to face even mild discomfort, danger or risk, in a way that invites gentle mockery |
| 49 | wooden | `emotions-wooden.jpg` | Stiff and lacking natural feeling in expression or manner, as if the emotion were being read from a card |
| 50 | dour | `emotions-dour.jpg` | Stern, gloomy and unsmiling by temperament, a hard sadness that never softens into warmth |
| 51 | inscrutable | `emotions-inscrutable.jpg` | Impossible to read, giving no clue in the face or manner about what is being felt or thought |
| 52 | jeer | `emotions-jeer.jpg` | To shout rude, mocking remarks at someone, showing scorn loudly and openly in front of others |
| 53 | scopophobia | `emotions-scopophobia.jpg` | An anxious fear of being looked at or stared at by other people, which makes crowded rooms feel unbearable |
| 54 | tickled | `emotions-tickled.jpg` | Quietly delighted and amused by something small, pleased in a warm private way that makes you smile |
| 55 | ogle | `emotions-ogle.jpg` | To stare at someone with obvious sexual interest, in a way that is rude and uncomfortable to receive |
| 56 | aquiver | `emotions-aquiver.jpg` | Trembling all over with excitement, nervousness or eager anticipation, shaking before something happens |
| 57 | exclaim | `emotions-exclaim.jpg` | To cry out suddenly and loudly because surprise, delight, pain or another strong feeling has caught you unprepared |
| 58 | frightful | `emotions-frightful.jpg` | Causing fear or shock because it seems dreadful, alarming and deeply unpleasant to face |
| 59 | surly | `emotions-surly.jpg` | Bad-tempered and rudely unfriendly in manner, answering people with a scowl rather than an insult |
| 60 | sheepish | `emotions-sheepish.jpg` | Showing mild, slightly comic embarrassment about a small fault, often with a guilty half-smile |
| 61 | bleat | `emotions-bleat.jpg` | To complain in a weak, plaintive, sheep-like voice that invites little sympathy |
| 62 | grimace | `emotions-grimace.jpg` | To twist the face into an ugly expression of pain, disgust or strong disapproval |
| 63 | merrymaking | `emotions-merrymaking.jpg` | Cheerful festivity and lively amusement shared with others, especially with food, music, dancing and laughter |
| 64 | snicker | `emotions-snicker.jpg` | To laugh in a half-hidden, slightly mocking way at someone else's mistake or awkwardness |
| 65 | whoop | `emotions-whoop.jpg` | To give a loud, sudden shout of excitement and delight, often with the arms thrown up in triumph |
| 66 | gape | `emotions-gape.jpg` | To stare with the mouth hanging open in amazement, shock or wonder at something unexpected |
| 67 | spine-tingling | `emotions-spine-tingling.jpg` | Thrilling or frightening in a way that sends a shiver of excitement down your back |
| 68 | blandishment | `emotions-blandishment.jpg` | A flattering, coaxing remark designed to charm someone into doing what you want, honeyed rather than honest |
| 69 | psyched | `emotions-psyched.jpg` | Excited and mentally fired up for something coming, an American eagerness that is already leaning forward |
| 70 | sniffle | `emotions-sniffle.jpg` | To sniff repeatedly and quietly while crying or trying to hold back tears |
| 71 | blubber | `emotions-blubber.jpg` | To weep noisily and messily, sobbing in a way that seems childish or lacking self-control |
| 72 | coo | `emotions-coo.jpg` | To speak in a soft, gentle, murmuring voice full of affection or admiration, as people do over a baby |
| 73 | wail | `emotions-wail.jpg` | To weep loudly with a long, high, drawn-out sound of grief or pain, crying out in raw distress |
| 74 | chortle | `emotions-chortle.jpg` | To give a breathy, gleeful laugh that mixes a chuckle with a snort of satisfaction |
| 75 | starchy | `emotions-starchy.jpg` | Stiffly formal and unbending in manner, correct to the point of coldness like a heavily starched collar |
| 76 | grumble | `emotions-grumble.jpg` | To complain in a low, muttering, bad-tempered voice about something tiresome you have to endure |
| 77 | abreaction | `emotions-abreaction.jpg` | The clinical release of buried emotion by reliving a painful memory and expressing the feeling that was blocked at the time |
| 78 | gallows humour | `emotions-gallows-humour.jpg` | Grim joking in the face of death or disaster, a way of managing fear and dread by laughing at what cannot be escaped |
| 79 | high-handed | `emotions-high-handed.jpg` | Using authority in an arrogant, overbearing way that ignores other people's rights and opinions |
| 80 | reclusive | `emotions-reclusive.jpg` | Habitually avoiding other people and preferring to stay shut away from society by temperament |
| 81 | melodramatic | `emotions-melodramatic.jpg` | Showing feeling in an exaggerated theatrical way that treats a small trouble like a tragedy |
| 82 | procrastination | `emotions-procrastination.jpg` | The habit of putting off tasks you know you should begin, choosing small distractions over the discomfort of starting |
| 83 | subservient | `emotions-subservient.jpg` | Too willing to obey and please others, treating your own wishes as less important than theirs |
| 84 | shrew | `emotions-shrew.jpg` | An irritable, aggressively nagging woman who scolds constantly, an old-fashioned and unkind label |
| 85 | war fever | `emotions-war-fever.jpg` | The feverish, aggressive excitement that grips a population eager for conflict, sweeping doubt aside |
| 86 | nestle | `emotions-nestle.jpg` | To settle in close and comfortably against someone or something, seeking warmth, safety and rest |
| 87 | arousal | `emotions-arousal.jpg` | The state of being physically and emotionally stirred by desire, the body responding before thought |
| 88 | quieten | `emotions-quieten.jpg` | To make an anxious or upset person gradually calmer and stiller, often by gentle words or a steadying presence |
| 89 | mind-numbing | `emotions-mind-numbing.jpg` | So extremely dull and repetitive that it seems to switch off the mind and leave you blank |
| 90 | snide | `emotions-snide.jpg` | Mocking and spiteful in an indirect, sneaky way that lets the speaker deny meaning offence |
| 91 | buttoned-up | `emotions-buttoned-up.jpg` | Emotionally reserved and formal, keeping feelings tightly fastened away behind a correct careful manner |
| 92 | fraternal | `emotions-fraternal.jpg` | Marked by the warm loyalty and affection of brothers, a feeling of kinship among equals |
| 93 | inure | `emotions-inure.jpg` | To harden someone through long exposure until hardship or unpleasantness no longer troubles them |
| 94 | namby-pamby | `emotions-namby-pamby.jpg` | Feeble, sentimental and lacking in backbone, unable to make a firm decision or take a firm stand |
| 95 | well-disposed | `emotions-well-disposed.jpg` | Feeling friendly goodwill toward someone and inclined to help or think well of them before they have earned it |
| 96 | bottled-up | `emotions-bottled-up.jpg` | Describing emotions deliberately kept inside and never expressed, sealed away rather than shared |
| 97 | choked up | `emotions-choked-up.jpg` | Unable to speak steadily because a sudden rush of tender emotion has tightened the throat |
| 98 | loosen up | `emotions-loosen-up.jpg` | To become less tense, stiff or inhibited and behave in a more relaxed, easy way |
| 99 | po-faced | `emotions-po-faced.jpg` | Wearing a prim disapproving expression, humourless and solemn in a slightly self-righteous way |
| 100 | disobliging | `emotions-disobliging.jpg` | Unwilling to do even small favours, refusing help in a cold ungenerous way that makes everything harder |

## 4. Where to put them

Drop the finished files in:

```
tools/fetch_assets/drop/emotions/
```

Named `emotions-<slug>.jpg` exactly as above, and nothing else needs doing — the installer
matches on the filename, converts, writes the `image` field and regenerates the provenance
table. Any file it cannot match to a term it reports rather than guessing.

## 5. Watch for these

- **Acting.** The single biggest failure mode for this book. A person *performing* sadness
  looks like stock; a person who happens to be sad looks like a dictionary. If a frame
  would work as a greetings card, regenerate it.
- **Sameness.** 100 photographs of one kind of person in one kind of room is a worse book
  than 100 varied ones. Vary age, build, room, time of day, and how much of the face you
  see.
- **A busy lower third.** The headword and the Hindi gloss print over it.
- **Drift.** Compare batch 10 against batch 1. If the light or palette has wandered,
  re-paste the style block.
