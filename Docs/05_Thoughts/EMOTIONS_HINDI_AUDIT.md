# Emotions Hindi audit

2026-10-22. An audit of the `hindi` field in `OneWord/Shared/emotions.json` (3,199 entries).
It was prompted by option 5C, "Match the Hindi", in the visual-elements brainstorm, which
would show the Hindi to the reader as the answer. **Nothing under `OneWord/` was changed.**
The fixes below are proposals. Applying them is the user's call.

## Bottom line

- **The bad glosses all come from one batch.** 987 entries (31%) are an older
  machine-translated batch: WordNet definitions run through MT. In that batch, synonyms share
  one gloss, and no gloss has a Hindi headword. The other 2,212 entries are hand-written in the
  house style `हेडवर्ड — व्याख्या`, and they are clean. A random sample of 150 had 0
  mistranslations.
- **Reading all 987 machine glosses by hand gave this split:**

  | Verdict | Entries | What it means |
  |---|---|---|
  | **W: wrong** | **256** | Says something other than the English: the wrong word sense, a dropped negation, the opposite meaning, or nonsense. It would teach the reader a wrong meaning. |
  | **E: empty** | **24** | Blank, or only punctuation or a citation (`; ; ; ; ; ।`, `- मार्क ट्वेन`). |
  | **P: broken** | **225** | The meaning can be recovered, but the Hindi is broken: untranslated English (`liking की सकारात्मक भावना`), sentence fragments, citation residue, or near-miss senses. |
  | OK | 482 | A correct but literal translation of a WordNet definition. It has no headword, so it doesn't match the house style. |

- **Estimate of how many entries need fixing:**
  - 280 entries (W + E, 8.8% of the file) must be fixed before any feature presents the Hindi as an answer.
  - 505 entries (adding P) should be fixed for the Hindi to read as Hindi.
  - All 987 need rewriting if "Match the Hindi" shows the headword before the `—`, because
    machine glosses have no headword to cut. That last option is the clean one: one writer
    pass over the whole batch in the house style.

## How the flagging worked

A scratch script (not committed) checked each entry against these flags:

| Flag | Rule | Emotions | Hand-written entries hit |
|---|---|---|---|
| NO_DASH | gloss has no `—` | 969 | 0 (by definition) |
| EMPTY | blank gloss | 18 | 0 |
| LATIN | contains A–Z | 126 | 0 |
| SEMICOLON | contains `;` (MT keeps source punctuation) | 119 | 0 |
| SHORT | ≤ 6 characters | 30 | 0 |
| LONG | ≥ 90 characters | 11 | 0 |
| STARTS_NAHIN | starts with `नहीं` ("not X" translated word by word) | 4 | 0 |
| DUP | same gloss on terms whose definitions differ | 4 | 0 |

NO_DASH turned out to be the signal that matters. The machine batch and the hand-written batch
separate perfectly on it: every surface flag falls only inside the machine batch, and no
hand-written entry trips any of them.

The surface flags do **not** find the meaning errors. **192 of the 256 wrong glosses carry no
flag except NO_DASH.** `wistful → दंडात्मक उदासी दिखा` has no English, no semicolon and
a normal length. It is simply the wrong word ("pensive" was read as "punitive").

I did the back-translation step by reading, not by running a translator. Nothing offline was
available, and the app is offline by design. To speed this up, the 987 entries were grouped
into 573 distinct (gloss, definition) pairs, because WordNet synonym sets share both. Each pair
was read against its English definition.

## Spot-check of the hand-written 2,212

I read 150 entries drawn at random. None was mistranslated. Three had a part-of-speech
mismatch in the headword:

- `madden` (verb) → `आक्रोश` (noun)
- `indecisive` (adj) → `निर्णयहीनता` (noun)
- `welcomed` (adj) → `स्वागत` (noun)

The meaning is right in all three. Expect roughly 2% of hand-written entries to have nits like
these, and no real errors.

## The worst 50, with proposed fixes

I chose these 50 for how badly they mislead and how common the word is. Each proposal follows
the house style (`हेडवर्ड — व्याख्या`) and matches the entry's part of speech. Where a bad
gloss is shared, the other terms are listed in the appendix and need their own headwords. For
a matching game, synonyms must not end up with the same answer.

| # | Term | POS | Current `hindi` | Reads as | Proposed |
|---|---|---|---|---|---|
| 1 | wistful | adj | दंडात्मक उदासी दिखा | "showing punitive sadness" | हसरत-भरा — खोई या अनपाई चीज़ को याद करके उदास-सा |
| 2 | serene | adj | नहीं; आत्म-स्थिति खोए बिना | "no; without losing self-state" | प्रशांत — भीतर से स्थिर, बिना विचलित हुए शांत |
| 3 | fearless | adj | खतरों या खतरों के बारे में अप्रिय या शांतिपूर्वक उन्हें सा… | "unpleasant about dangers… help face them" · same gloss on 1 other term | निडर — ख़तरे से बेपरवाह, शांत दृढ़ता से सामना करने वाला |
| 4 | fearlessness | n | कोई डर लग रहा है | "some fear is felt" (opposite) | निर्भयता — मन में किसी डर का न होना |
| 5 | intrepid | adj | डर या डरावना | "fear or scary" (opposite) · same gloss on 3 other terms | दिलेर — डर या धमकी से ज़रा भी न डिगने वाला |
| 6 | inspire | v | ऊंचाई या तीव्रता | "height or intensity" · same gloss on 3 other terms | प्रेरित करना — मन में जोश भरकर भावना को ऊँचा कर देना |
| 7 | abhor | v | पाना | "to get" · same gloss on 3 other terms | घृणा करना — किसी चीज़ से गहरी नफ़रत और घिन महसूस करना |
| 8 | displease | v | देना | "to give" | नाराज़ करना — किसी को अप्रसन्न या असंतुष्ट कर देना |
| 9 | infuriate | v | खूबसूरत | "beautiful" · same gloss on 1 other term | आगबबूला करना — किसी को बेहद क्रोधित कर देना |
| 10 | gaiety | n | समलैंगिक भावना | "homosexual feeling" · same gloss on 1 other term | मौज-मस्ती — रंगीन, चहकती खुशमिज़ाजी |
| 11 | mirth | n | महान सिंचाई | "great irrigation" · same gloss on 4 other terms | हँसी-ख़ुशी — ठहाकों-भरी मौज |
| 12 | hilarious | adj | द्वारा चिह्नित या boisterous merriment या convulsive वध | "…boisterous merriment or convulsive slaughter" | हँसा-हँसाकर लोटपोट करने वाला — ज़ोरदार ठहाके जगाने वाला |
| 13 | friendliness | n | किसी अन्य व्यक्ति के लिए झूठ बोलने की भावना; उनकी कंपनी मे… | "feeling of lying to another person" | मैत्रीभाव — किसी के प्रति अपनापन और उसके साथ में आनंद |
| 14 | athirst | adj | (आमतौर पर 'for') के बाद बेहद शर्मनाक | "(usually 'for') after, extremely shameful" | लालायित — किसी चीज़ के लिए बेहद उत्सुक |
| 15 | amiable | adj | कृपया निपटान करें; - Hal Hinson | "please dispose of; - Hal Hinson" | सुशील — दूसरों को ख़ुश रखने वाला, सौम्य स्वभाव का |
| 16 | nirvana | n | (Hinduism and Buddhism) एक पिटाई जो पुनर्जन्म के चक्र को प… | "a beating that transcends the cycle of rebirth" | निर्वाण — जन्म-मरण के चक्र से मुक्ति की परम शांति |
| 17 | nostalgia | n | कुछ देर तक | "for a while" | अतीत की कसक — बीते दिनों को फिर जीने की मीठी-सी तड़प |
| 18 | homesick | adj | घर लौटने के लिए लंबे समय तक | "for a long time to return home" | घर की याद में बेचैन — घर लौटने को तरसता हुआ |
| 19 | sadness | n | जब अच्छी तरह से किया जा रहा है की स्थिति में नहीं | "when not in the state of being done well" · same gloss on 1 other term | उदासी — मन का दुखी और बुझा होना |
| 20 | satisfaction | n | जब कोई इच्छा, आवश्यकता या उम्मीद को पूरा करता है, तो किसी … | "…then one feels a condition/bet" | संतोष — इच्छा या ज़रूरत पूरी होने पर मिलने वाली तृप्ति |
| 21 | desire | n | ऐसा लग रहा है कि असंतुष्ट राज्य के साथ | "it seems that with the dissatisfied state (nation)" | इच्छा — किसी कमी के अहसास के साथ उठने वाली चाह |
| 22 | sentiment | n | निविदा, रोमांटिक, या उदासीन भावना या भावना | "tender (as in a bid), romantic or indifferent feeling" | भावना — कोमल, रूमानी या यादों से भरा भाव |
| 23 | apathetic | adj | कोई भावना या एनीमेशन | "any emotion or animation" | निरुत्साही — भावना या उत्साह से लगभग ख़ाली |
| 24 | phlegmatic | adj | भावना | "feeling" (opposite) · same gloss on 1 other term | ठंडे मिज़ाज का — जिसके चेहरे पर कोई भाव न झलके |
| 25 | unfeeling | adj | दूसरों के लिए महसूस करना | "feeling for others" (opposite) · same gloss on 1 other term | बेदर्द — दूसरों के लिए कोई भावना न रखने वाला |
| 26 | joyless | adj | अनुभव या प्रेरणादायक खुशी | "experiencing or inspiring joy" (opposite) | नीरस — न ख़ुशी महसूस करने वाला, न जगाने वाला |
| 27 | dissatisfy | v | संतुष्ट होना | "to be satisfied" (opposite) | असंतुष्ट करना — किसी की उम्मीद पूरी न कर पाना |
| 28 | heartfelt | adj | कमाई | "earnings" | हार्दिक — दिल से निकला, सच्चा |
| 29 | sincerity | n | सबसे अमीर और ईमानदार भावना | "the richest and honest feeling" · same gloss on 2 other terms | सच्चाई — मन और बात में कोई दिखावा न होना |
| 30 | fidgety | adj | तंत्रिका और आराम करने में असमर्थ | "nerve (anatomical) and unable to relax" · same gloss on 3 other terms | बेचैन — घबराहट में चैन से न बैठ पाने वाला |
| 31 | aloof | adj | दूरस्थ रूप से | "remotely (as in distance)" | अलग-थलग — व्यवहार में रूखी दूरी बनाए रखने वाला |
| 32 | conceited | adj | झूठी गौरव की विशेषता; आत्म-आयात की अतिरंजित भावना होना | "…an exaggerated sense of self-import (as in trade)" · same gloss on 1 other term | दंभी — ख़ुद को बहुत बड़ा समझने वाला |
| 33 | arrogant | adj | अति प्रिय गौरव से अप्राप्य महत्व की भावनाओं को व्यक्त करना… | "…feelings of unattainable importance out of very-dear pride" | अहंकारी — दबंग घमंड में ख़ुद को बेवजह बड़ा समझने वाला |
| 34 | smug | adj | अत्यधिक संगतता या आत्म-संवेदन द्वारा चिह्नित | "excessive consistency or self-sensation" | इतराता हुआ — ख़ुद से ज़रूरत से ज़्यादा संतुष्ट |
| 35 | animosity | n | बीमार की भावना सक्रिय शत्रुता पैदा करेगी | "the sick man's feeling will create active hostility" · same gloss on 1 other term | बैर — खुली दुश्मनी जगाने वाला द्वेष |
| 36 | resentment | n | गहरे और कड़वे क्रोध और अवैध इच्छा की भावना | "…deep and bitter anger and illegal desire" · same gloss on 3 other terms | रोष — मन में बैठी गहरी, कड़वी नाराज़गी |
| 37 | malice | n | दूसरों को देखने की जरूरत महसूस करना | "feeling the need to see others" · same gloss on 3 other terms | द्वेष — दूसरों को दुख में देखने की चाह |
| 38 | contrition | n | पाप के लिए दुर्बलता | "weakness for sin" · same gloss on 1 other term | पश्चाताप — अपने पाप पर सच्चा, गहरा पछतावा |
| 39 | repentant | adj | गलतफहमी के लिए याद करना या व्यक्त करना | "remembering for a misunderstanding" | पछताता हुआ — अपने गलत कामों पर पश्चाताप करने वाला |
| 40 | ungrateful | adj | नहीं लग रहा है या ग्रेविटी दिखा; - शेक्सपियर | "not seeming, or showing gravity; - Shakespeare" · same gloss on 2 other terms | कृतघ्न — एहसान न मानने वाला |
| 41 | grateful | adj | भावना या दिखावा | "feeling or pretence" · same gloss on 1 other term | कृतज्ञ — आभार मानने और जताने वाला |
| 42 | scary | adj | भयभीत आतंकवाद | "frightened terrorism" · same gloss on 2 other terms | भयानक — डर और दहशत पैदा करने वाला |
| 43 | terrify | v | आतंकी; भयंकर | "terrorist; fierce" · same gloss on 1 other term | दहलाना — किसी को बुरी तरह डरा देना |
| 44 | venerate | v | सम्मान और सम्मान की भावनाओं के बारे में; मधुमक्खियों या बह… | "…consider bees or boycotts" · same gloss on 1 other term | श्रद्धा रखना — किसी को पूज्य मानकर गहरा सम्मान देना |
| 45 | thrill | n | प्रभावशाली बल के एक स्टोर की तेजी से रिलीज | "fast release of a store (shop) of impressive force" | रोमांच — अचानक दौड़ जाने वाली उत्तेजना की लहर |
| 46 | suspense | n | क्या हो रहा है | "what is happening" | उत्कंठा — आगे क्या होगा, इसकी बेचैन प्रतीक्षा |
| 47 | ecstatic | adj | आकर्षक लगना | "to look attractive" · same gloss on 3 other terms | हर्षविभोर — अपार ख़ुशी में डूबा हुआ |
| 48 | exasperate | v | exasperate या irritate | "exasperate or irritate" (untranslated) | खिझाना — बार-बार परेशान करके झुंझला देना |
| 49 | bashful | adj | Self-consciously timid; - Ezra पाउंड | "Self-consciously timid; - Ezra Pound" (untranslated) | शर्मीला — झिझक और संकोच से भरा |
| 50 | mad | adj | - मार्क ट्वेन | "- Mark Twain" (citation only) | भड़का हुआ — गुस्से से तमतमाया |

Six of these headwords already head hand-written entries:

- inspire / spur → `प्रेरित करना`
- gaiety / carousing, craic → `मौज-मस्ती`
- amiable / good-natured → `सुशील`
- sadness / sadden → `उदासी`
- conceited / snob, snobbish → `दंभी`
- thrill / goosebumps → `रोमांच`

I kept them because each is the right word. Shared headwords aren't new, though. **The
hand-written set already gives 135 headwords to 303 entries.** So "Match the Hindi" needs a
rule never to put two entries with the same headword in one round, whatever happens here.

## How the machine translation went wrong

These are the failure modes, as grep targets for the apply pass. Search only inside the
machine batch: `उदासीन`, `बीमार` and `लंबे समय तक` also appear, used correctly, in
hand-written entries.

- **Wrong word sense** (the biggest group):
  - ill will → `बीमार` (sick)
  - tense → `सामयिक` (topical)
  - interest → `ब्याज` (bank interest)
  - strike → `हड़ताल` (labour strike)
  - nervous → `तंत्रिका` (the nerve)
  - gay → `समलैंगिक`
  - states → `राज्य` (nations)
  - spirits → `आत्माओं` (souls)
  - longing → `लंबे समय तक` (for a long time)
  - aversion → `संस्करण` (version)
  - warmth → `गर्मी` (heat)
  - melancholy → `उदासीन` (indifferent; उदास vs उदासीन recurs)
- **Negation dropped or inverted:**
  - joyless → "experiencing or inspiring joy"
  - unfeeling → "feeling for others"
  - fearlessness → "some fear is felt"
  - dissatisfy → "to be satisfied"
  - phlegmatic → "feeling"
  - audacious, dauntless, intrepid → "fear or scary"
- **The verb lost, leaving one word:** abhor → `पाना`, displease → `देना`, disturb →
  `गहराई से`, infuriate → `खूबसूरत`.
- **Untranslated English or transliteration:** `exasperate या irritate`, `दीप-सीटित रीसेंटमेंट`,
  `ग्रेविटी`, `फोल्ली`.
- **WordNet citation residue:** `; - Hal Hinson`, `- एडमंड बर्क`, `- प्रोवरब 14: 13`.

## Things noticed outside the `hindi` field

These were out of scope and left alone. They matter for the apply pass, because rewriting the
Hindi from these definitions would carry their problems over.

- Of the 987 machine-batch entries, **486 have an empty `example`**, against 0 in the
  hand-written set. **276 more have an example that doesn't contain the word**, for instance
  serene → "Spoke in a calm voice." The hand-written set has 5 of those.
- 42 machine-batch definitions carry citation residue
  (`unequivocally detestable; ; ; ; - Edmund Burke`).
- Some definitions are circular: agonize → "cause to agonize".
- Some definitions use the wrong sense: placid and tranquil are defined "(of a body of water)
  free from disturbance by heavy waves", and barmy is grouped with zestful.

The likely fix is to rewrite the 987 machine entries as whole entries (definition, Hindi and
example) in the house style, not to patch the Hindi alone.

## Other dictionaries (counts only)

**`words.json`** (12,000 entries): every entry is in the machine style, and the file has no dash
convention, so NO_DASH means nothing there. 3,220 entries carry at least one surface flag:

| Flag | Entries |
|---|---|
| SEMICOLON | 1,512 |
| LONG | 1,381 |
| LATIN | 1,031 |
| SHORT | 164 |
| DUP | 109 |
| citation residue | 106 |
| EMPTY | 41 |
| STARTS_NAHIN | 17 |

In a random sample of 25 entries, 4 were wrong and 6 were broken. The wrong ones were
capitalist → "conservative lawyer", flamingo, textile and misconduct (garbled). Given that the
emotions batch showed 75% of wrong glosses to be invisible to the flags, the surface counts
understate the problem.

**`idioms.json`** (3,047 entries) is clean. 60 entries lack the `—`, but they are hand-written
Hindi idiom equivalents (`पाँचों उँगलियाँ घी में`, `फूट डालो और राज करो`), not machine output.
The 6 DUP hits are idioms that share an equivalent on purpose (heart sinks and heart in your
boots → `दिल बैठ जाना`). No action needed.

## Appendix: every machine-batch entry by verdict

This is for the apply pass, so it doesn't have to redo the review. Terms are listed
alphabetically. Each list includes the matching terms from the top 50.

**W, wrong (256):** abhor, abhorrence, abhorrent, abominate, affect, afraid, aggravation, agonal, aloof, aloofness, ambivalent, amiable, amicability, amicableness, animate, animosity, animus, anticipate, antipathetic, antipathetical, antsy, apathetic, appal, appall, arrogant, aspire, athirst, attaint, audacious, averse, bashful, bathetic, begrudge, bitterness, blitheness, buoyancy, carefreeness, cheerlessness, comical, conceited, contriteness, contrition, dauntless, daze, deadpan, deject, dejectedness, depress, depressed, depressing, desire, despond, detestable, detestation, diffident, disapproval, disapprove, discomfit, discompose, discontent, discontentedness, discontentment, dispirit, dispirited, dispiritedness, displease, dissatisfy, disturb, downhearted, downheartedness, dudgeon, earnestness, ecstasy, ecstatic, edgy, emotionlessness, empathetic, empathic, enchant, enliven, enrapture, enraptured, enthral, enthrall, enviousness, envy, euphoric, exaltation, exasperate, exasperation, execrate, execration, expect, expressionless, fainthearted, faintness, fearless, fearlessness, fidgety, fretful, friendliness, gaiety, glee, gleefulness, gloat, gloating, grateful, grievance, grudge, hackles, hankering, heartburning, heartfelt, hearty, hesitance, hesitancy, hesitant, hilarious, hilarity, hokey, homesick, homesickness, huffy, impassiveness, impassivity, indifferent, indignant, infuriate, infuriated, insouciance, inspire, inspirit, intrepid, invigorate, itchy, jitteriness, jocularity, jocundity, joyless, joylessness, jumpiness, jumpy, kindhearted, kitschy, lightheartedness, lightsomeness, lividity, loathe, loathing, lovesickness, mad, malice, malicious, maliciousness, maudlin, mawkish, meek, meekness, mercilessness, merriment, mirth, mirthfulness, moroseness, mournfulness, nervousness, nervy, nirvana, nostalgia, nostalgic, outraged, overstrung, penance, penitence, penitential, perkiness, phlegm, phlegmatic, phlegmatical, pitilessness, presage, rancor, rancorous, rancour, rapt, rapture, rapturous, repentance, repentant, repugnance, repugnant, repulsive, resentment, restive, restiveness, reverential, revulsion, rhapsodic, risible, ruthfulness, sadness, satisfaction, scandalise, scandalize, scarey, scary, schmaltzy, schmalzy, scrupulous, scunner, sentiment, serene, seriousness, shamed, shock, shuddery, sicken, sickening, sincerity, smug, spite, spitefulness, stolidity, stonyhearted, stupor, sullenness, suspense, terrified, terrify, terrorise, terrorize, thankful, thankless, thrill, touchy, unafraid, unalarming, unassertiveness, uncheerfulness, unemotionality, unexpressive, unfearing, unfeeling, ungrateful, unhappiness, unthankful, untune, uptight, vain, venerate, venerating, warpath, willies, wistful, wistfulness, woefulness, yen

**E, empty or punctuation only (24):** abominable, agonise, agonising, agonize, agonizing, bedaze, despisal, despising, emotionless, excite, grieve, hapless, irk, mawkishness, misfortunate, morose, odious, offend, pathetic, piteous, sadomasochistic, sullen, tempt, wishfulness

**P, broken but recoverable (225):** abase, acerbate, admire, affection, affectionate, affectionateness, alarming, algolagnic, alienate, ambition, amiability, annoy, antagonize, appetence, appetency, appetite, barmy, bask, beatify, befuddle, belligerence, belligerency, belonging, benevolence, bewilder, blithesome, boding, boredom, cark, casual, cheerless, choleric, complacence, complacency, compunction, confound, contemn, coolness, covetous, crave, desolate, despise, despiteful, detest, disaffect, disgruntlement, disinclination, dolefulness, dolor, dolour, dreaded, dreamy, dumbfound, ebullient, elate, elated, embitter, embitterment, empathise, empathize, emulation, enjoy, ennui, envenom, envious, estrange, euphoria, euphory, exhilarate, exuberant, exult, exulting, fear, fearfulness, feeling, fervency, fervidness, fervor, fidget, fidgetiness, flummox, fond, fondness, foreboding, forlornness, forsake, fright, gladden, gleeful, glum, hangdog, happiness, harassment, hardhearted, heartless, heavyheartedness, homicidal, horrify, huffish, huffishness, humiliate, humiliated, humour, idolise, idolize, impassive, imperturbability, imperturbable, indifference, infatuate, infatuated, insouciant, intimidate, intoxicate, irksome, irritate, jealous, jocund, jolliness, jollity, jovial, joviality, kindheartedness, lackadaisical, languid, languorous, lighthearted, listless, listlessness, loathsome, longing, lovesick, lovesome, loving, maleficence, maleficent, malevolent, merciful, merry, mirthful, misgiving, misogynic, mood, moodiness, murderous, murderousness, mystify, nauseous, noisome, nonchalant, nonplus, oppressiveness, optimism, oversensitive, painful, pall, partiality, penchant, pensiveness, perplex, perturb, philia, pining, placid, placidity, placidness, pleasant, pleasantness, please, prefer, preference, premonition, presentiment, qualm, queasy, remorse, revengeful, rile, sad, sadomasochism, sanguineness, sanguinity, sensuousness, sentimental, shamefaced, slaphappy, softhearted, solemn, sorrowful, spiteful, stolid, stupefaction, sulk, sulkiness, surprise, swivet, tedious, tedium, tend, throes, tiresome, tranquil, traumatise, traumatize, trepidation, tyrannical, tyrannous, uncheerful, uncomfortable, unflappable, unfriendliness, unhinge, unpleasant, unpleasantness, velleity, vengeful, vex, vindictive, warmness, wearisome, whimsical, woeful, worried, yearning, zestful

The remaining 482 machine-batch entries read as acceptable. They still lack the house-style
headword.
