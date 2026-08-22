# Dictionary of the Startup — Brainstorm

A new Wordbook: the language developers actually swim in at a tech startup (think a
fitness-AI company) — corporate slang, meeting-speak, agile ritual words, VC jargon,
dev-culture idioms. The words nobody teaches you but everyone expects you to know.

**Who it's for:** new grads decoding their first job, non-native English speakers
(the Hindi field earns its keep here — this vocabulary is nowhere in a textbook),
and veterans who'll enjoy seeing "circle back" get the dictionary treatment.

**Why it fits One Word:** every other book teaches words for *understanding the
world*; this one teaches words for *surviving Tuesday*. Same daily-word mechanic,
same entry shape, instantly relatable on a desktop widget at work.

---

## Editorial compass (decide once, apply everywhere)

1. **Definition tells the truth, example carries the wink.** Keep `definition`
   dictionary-honest (what the word actually means in use), and let `example` show
   the lived reality. Satire in the definition gets old by word 30; satire in the
   example stays fresh.
   > **circle back** — *verb (idiom)* — to return to a topic later, often as a polite
   > way of ending a discussion without deciding anything.
   > *"Let's circle back on this after the sprint." (They never did.)*
2. **Sayable-in-a-meeting test.** Include a term only if someone would actually say
   it aloud at work. "Synergy" passes; "race condition" is CS knowledge, not culture —
   it belongs in a future Dictionary of Computing, not here.
3. **The slang sense, not the literal one.** `bandwidth`, `leverage`, `runway` exist
   in Everyday English with their literal senses. Duplication across books is fine by
   design (each book has its own word-of-day) — here they get their office sense.
4. **Phrases and acronyms are first-class terms.** The `Word` model doesn't care.
   Convention for `partOfSpeech`: use `"idiom"` (circle back, boil the ocean),
   `"acronym"` (OKR, MVP), `"noun" / "verb" / "adjective"` for single words.
5. **Hindi renders the meaning, not a transliteration.** Match the eloquence.json
   style: Hindi equivalent + short gloss. e.g. *synergy* → "तालमेल — मिलकर काम करने से
   बढ़ा हुआ असर". For acronyms, expand the idea: *OKR* → "लक्ष्य और मुख्य परिणाम —
   कंपनी की प्रगति नापने का ढांचा".
6. **Durable over trendy.** "Synergy" has survived 30 years; this month's LinkedIn-ism
   won't. Prefer words that will still be said in 5 years.

---

## The dimensions (word categories to fold in)

### 1. Classic corporate buzzwords — the lingua franca
The words that make corporate sound corporate. Highest recognition, funniest examples.
> synergy · leverage (v.) · alignment · bandwidth · circle back · touch base ·
> deep dive · low-hanging fruit · move the needle · boil the ocean · table stakes ·
> north star · ideate · socialize (an idea) · double-click (on a topic) ·
> take it offline · streamline · holistic · paradigm shift · value-add

### 2. Meeting & calendar culture — where the week goes
The ritual vocabulary of how startups spend time.
> standup · sync · one-on-one · all-hands · offsite · retro · post-mortem ·
> pre-mortem · kickoff · war room · hard stop · double-booked · async ·
> office hours · agenda · action item · parking lot (for topics) · huddle

### 3. Agile & process jargon — the ritual layer
Scrum-speak developers are graded by whether they know.
> sprint · backlog · grooming · story points · velocity · epic · spike · blocker ·
> burndown · definition of done · timebox · WIP · kanban · iteration · scope creep ·
> stakeholder · deliverable · milestone

### 4. Developer culture idioms — how engineers talk to each other
The folk language of software teams (culture words, not CS concepts — rule 2).
> ship it · LGTM · nit · bikeshedding · yak shaving · rubber-ducking · tech debt ·
> dogfooding · footgun · greenfield · code smell · happy path · edge case · hotfix ·
> rollback · feature flag · cargo cult · works on my machine · bus factor · deprecate

### 5. Startup & VC jargon — the money layer
What the founders say in all-hands and you nod along to.
> runway · burn rate · product-market fit · pivot · MVP · bootstrap · seed round ·
> unicorn · traction · churn · moat · cap table · term sheet · exit · acqui-hire ·
> hockey stick · flywheel · TAM · land and expand · growth hacking

### 6. Metrics & data-speak — how success is pronounced
The measurement vocabulary of every product review.
> KPI · OKR · north-star metric · funnel · cohort · retention · engagement · DAU ·
> conversion · A/B test · vanity metric · signal vs. noise · dashboard · benchmark ·
> baseline · statistically significant · attribution

### 7. AI-era vocabulary — the words of an AI startup specifically
What a fitness-AI team says daily in 2026; new enough that even seniors learn some.
> model · inference · hallucination · fine-tuning · prompt · embedding · ground truth ·
> human-in-the-loop · drift · overfitting · copilot · agent · guardrails ·
> training data · AI slop · eval

### 8. People & HR speak — the org-chart layer
The vocabulary of careers, reviews, and reorgs — including the euphemisms, defined honestly.
> onboarding · offboarding · IC (individual contributor) · headcount · backfill ·
> attrition · skip-level · comp · equity · vesting · cliff · PIP · culture fit ·
> rightsizing · sunsetting · restructuring · promo cycle · 360 review

### 9. Chat & async shorthand — the Slack dialect
The abbreviations of written office life. Short entries, very high daily utility.
> TL;DR · EOD · EOW · OOO · WFH · FYI · IMO · +1 · nudge · bump · thread ·
> ping · loop in · per my last email · cc · DM · ETA · ASAP

### 10. Domain crossover (optional) — the company's own field
For a fitness-AI startup: the fitness-science words the whole team absorbs.
> rep · set · HIIT · VO2 max · macros · progressive overload · DOMS · wearable ·
> biometrics · recovery score · form check · plateau · zone 2 · resting heart rate

*Recommendation: hold this dimension for v1 — it's a different book ("Dictionary of
Fitness") wearing a costume. The other nine share one identity: workplace language.*

---

## What to leave out

- **Deep CS terminology** (race condition, mutex, idempotent) — knowledge, not slang.
- **Company-specific codenames** — nobody else's "Project Falcon" matters.
- **This-quarter's memes** — anything that will read as dated by next year.
- **Genuinely derogatory workplace slang** — decode euphemisms ("rightsizing"), don't
  add insults.

## Open decisions (with recommendations)

| Decision | Options | Recommendation |
|---|---|---|
| Name | Dictionary of the Startup / of Corporate / of Work / of Jargon | **Dictionary of the Startup** — matches the "Dictionary of X" pattern, widest wink |
| Size (v1) | 20 (house style of curated books) vs. more | **~60** — 6–8 per dimension; 20 can't cover nine dimensions. Grow later; the shuffle handles any count |
| One book or several | One mixed book vs. Corporate/Dev/VC split | **One book** — the daily-word surprise *is* the mix; split only if it outgrows ~150 entries |
| Tone | Straight vs. satirical | **Honest definition + winking example** (compass rule 1) |
| Cover/symbol | — | Next gray in the ramp is `0xA4A4A4` (steps of 0x12); symbol `briefcase.fill` |

## Reality check (wiring, for later — not this doc's job)

- Hand-curated JSON, same shape as `eloquence.json` — WordNet/`tools/gen_words` can't
  produce slang senses, so entries are written, not generated.
- Ship = one `startup.json` in `OneWord/Shared/` (member of **both** app and widget
  targets — the known gotcha) + one `Wordbook` static + add to `Wordbook.all`.

### Sample entries (target quality bar)

```json
[
 {
  "term": "circle back",
  "partOfSpeech": "idiom",
  "hindi": "बाद में लौटना — बिना फ़ैसला किए चर्चा टालने का विनम्र तरीका",
  "definition": "to return to a topic later; often a polite way to end a discussion without deciding anything",
  "example": "Let's circle back on this after the sprint — no one ever did."
 },
 {
  "term": "runway",
  "partOfSpeech": "noun",
  "hindi": "बची हुई पूँजी की अवधि — कंपनी कितने महीने और चल सकती है",
  "definition": "the number of months a startup can operate before its money runs out",
  "example": "After the funding round, we have eighteen months of runway."
 },
 {
  "term": "bikeshedding",
  "partOfSpeech": "noun",
  "hindi": "छोटी बात पर लंबी बहस — बड़े मुद्दे छोड़कर तुच्छ विवरण पर अटकना",
  "definition": "spending disproportionate time debating trivial details while the hard decisions go untouched",
  "example": "Two days of bikeshedding over the button color, and the API design is still unreviewed."
 }
]
```
