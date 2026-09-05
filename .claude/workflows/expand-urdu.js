export const meta = {
  name: 'expand-urdu',
  description: 'Grow the Dictionary of Urdu: themed writer fan-out in Devanagari lipyantaran, per-batch editing, mechanical merge, then the build gates',
  whenToUse: 'The urdu Wordbook is already registered and green, you just want many more words in it. Pass {target, scratch, themes}.',
  phases: [
    { title: 'Survey', detail: 'read what the book already has' },
    { title: 'Write', detail: 'one writer + one editor per theme, each batch on disk' },
    { title: 'Merge', detail: 'deterministic dedupe/validate/sort into urdu.json' },
    { title: 'Gates', detail: 'both xcodebuild schemes + both check scripts' },
  ],
}

const cfg = typeof args === 'object' && args ? args : {}
const id = 'urdu'
const target = cfg.target || 1000
const scratch = cfg.scratch
const themes = cfg.themes || []
if (!scratch || !themes.length) throw new Error('expand-urdu needs {target, scratch, themes}')

const perTheme = cfg.perTheme || Math.ceil((target * 1.25) / themes.length)   // headroom for dedupe + editor drops

// ---------------------------------------------------------------- Survey
phase('Survey')
const survey = await agent(
  `Read OneWord/Shared/${id}.json in the One Word repo and report what is already there.

Return: the exact count, every term (verbatim Devanagari), and the 3 entries you judge the best examples of the
house style so later writers can match them. Do not modify anything.`,
  {
    label: 'survey',
    phase: 'Survey',
    agentType: 'claude',
    effort: 'low',
    schema: {
      type: 'object',
      required: ['count', 'terms', 'exemplars'],
      properties: {
        count: { type: 'integer' },
        terms: { type: 'array', items: { type: 'string' } },
        exemplars: { type: 'array', items: { type: 'string' } },
      },
    },
  },
)
if (!survey) throw new Error('could not read the existing dictionary')
log(`${id}.json holds ${survey.count} entries; writing ${perTheme} per theme across ${themes.length} themes toward ${target}`)

// The committed identity of this book, verbatim. Every line is load-bearing.
const RULES = `- HEADWORD IS DEVANAGARI, never Latin and never Nastaliq. This is Hindi-Urdu transliteration
  (lipyantaran / लिप्यांतरण): the Urdu word written in Devanagari so a Hindi reader can recite it.
- NUQTA IS MANDATORY and is the single most common failure. Use क़ ख़ ग़ ज़ फ़ wherever the Urdu sound
  demands it: इश्क़ not इश्क, ख़ामोशी not खामोशी, ग़म not गम, ज़िंदगी not जिंदगी, फ़ुर्सत not फुर्सत.
  A missing nuqta is a wrong entry — it makes the word a different word.
- REGISTER: the Persian/Arabic-derived vocabulary that makes Urdu *Urdu*. The reader already knows
  घर, पानी, हाथ, अच्छा. Do NOT ship common Hindustani words they use daily. Ship the word they have
  heard in a ghazal or a courtroom and could not define: मुरव्वत, तशरीह, गुंजाइश, ख़दशा.
- Weight everyday-usable register over pure poetic diction roughly 4:1. A word that changes how the
  reader writes a message tomorrow beats one that only appears in a couplet.
- partOfSpeech is BARE: exactly one of noun / adjective / verb / adverb / prefix / suffix / phrase.
  No etymology parenthetical — "noun (Arabic)" breaks three fixed-width layouts.
- hindi = the plain Hindi equivalent, an em-dash, then a short Hindi gloss:
  "शिष्टाचार — बड़ों के सामने बैठने-बोलने का सलीक़ा". It is a MEANING, never a re-spelling of the headword.
- definition = English, starts lowercase, NO trailing period, >= 8 content words, and earns its place by
  drawing a distinction against the nearest English or Hindi word: "manners are habit, this is obligation".
- example = one natural Devanagari sentence USING the headword, then " — ", then its English translation.
  The headword must literally appear in the Devanagari half.
- No Latin letters anywhere in term, hindi, or the Devanagari half of example.`

const SHAPE = `Entry shape — EXACTLY these five string keys, none empty:
  {"term": "", "partOfSpeech": "", "hindi": "", "definition": "", "example": ""}
House exemplars already in the book:
${survey.exemplars.map(e => `  ${e}`).join('\n')}`

// ---------------------------------------------------------------- Write
phase('Write')
const written = await pipeline(
  themes.map((t, i) => ({ theme: t, n: i })),
  (item) => {
    const file = `${scratch}/${id}-batch-${item.n}.json`
    return agent(
      `Write ${perTheme} Urdu vocabulary entries for ONE semantic theme of the "Dictionary of Urdu" in the
One Word macOS app. The book teaches a Hindi/English reader the Urdu register they cannot yet use.

THEME: ${item.theme}

Structure them as meaning-families: roughly ${Math.round(perTheme / 4)} families of 3-5 words that sit close in
meaning. The related-words feature ranks by embedding similarity over the ENGLISH DEFINITION, so family members
must share content words in their definitions — that sharing is what makes the feature work, and singletons
return noise. Within a family, each definition must still say how that word differs from its siblings.

EDITORIAL RULES (committed by this book's strategy — every one is load-bearing):
${RULES}

${SHAPE}

ALREADY IN THE BOOK — do not repeat any of these terms:
${survey.terms.join(', ')}

Write the JSON array to ${file} — a bare array of ${perTheme} entry objects, UTF-8 Devanagari (no \\u escapes),
1-space indent. Then verify with:
  python3 -c "import json;d=json.load(open('${file}'));print(len(d), len({w['term'] for w in d}))"

Return the count you wrote and every term, nothing else.`,
      {
        label: `write:${item.theme.slice(0, 28)}`,
        phase: 'Write',
        agentType: 'claude',
        effort: 'medium',
        schema: {
          type: 'object',
          required: ['count', 'terms'],
          properties: { count: { type: 'integer' }, terms: { type: 'array', items: { type: 'string' } } },
        },
      },
    )
  },
  (res, item) => {
    if (!res) return null
    const file = `${scratch}/${id}-batch-${item.n}.json`
    return agent(
      `Edit the Urdu entries in ${file}. You are the editor, not the writer — be strict, and rewrite the file in place.

Check every entry against these rules and FIX or DELETE:
${RULES}

THE NUQTA PASS IS YOUR MAIN JOB. Read every term and every example aloud in your head. For each, ask whether the
Urdu original has ق خ غ ز ژ ف — if so the Devanagari MUST carry क़ ख़ ग़ ज़ फ़. Writers get this wrong constantly.
Fix silently; do not delete an otherwise good entry over a nuqta.

Then run these mechanical checks with python3 — actually run them, do not eyeball:
- every entry has exactly the five keys term/partOfSpeech/hindi/definition/example, none empty or whitespace
- no ASCII letter appears in term, in hindi, or before the " — " in example
- term appears verbatim inside the Devanagari half of its own example
- hindi contains Devanagari AND contains " — "
- partOfSpeech is one of noun/adjective/verb/adverb/prefix/suffix/phrase
- definition starts lowercase, has no trailing period, and has >= 8 words
- definition has NO meaning-bearing word of 3 characters or fewer carrying the sense (the index drops
  tokens of length <= 3 — "die" is invisible to it, "death"/"dying" are not)
- no duplicate terms inside this file
- REGISTER CHECK: delete any entry whose headword is an ordinary Hindi word a Delhi ten-year-old already
  uses (घर, दोस्त, पानी, ख़ुशी). This book exists for the words they do NOT know.

Rewrite ${file} with the cleaned array (same format), then verify it still parses with python3.
Return how many you kept, dropped, and fixed.`,
      {
        label: `edit:${item.theme.slice(0, 28)}`,
        phase: 'Write',
        agentType: 'claude',
        effort: 'medium',
        schema: {
          type: 'object',
          required: ['kept', 'dropped', 'fixed'],
          properties: { kept: { type: 'integer' }, dropped: { type: 'integer' }, fixed: { type: 'integer' }, notes: { type: 'string' } },
        },
      },
    ).then(qa => ({ theme: item.theme, n: item.n, wrote: res.count, qa: qa || { kept: res.count, dropped: 0, fixed: 0 } }))
  },
)

const ok = written.filter(Boolean)
const rawKept = ok.reduce((n, b) => n + (b.qa.kept || 0), 0)
log(`${ok.length}/${themes.length} themes survived · ${rawKept} entries after editing, before the merge dedupe`)
if (!ok.length) throw new Error('every theme batch failed')

// ---------------------------------------------------------------- Merge
phase('Merge')
const merge = await agent(
  `Merge the Urdu batches into the real dictionary. Run EXACTLY this script — do not improvise the merge, and do
not hand-edit entries. It is deterministic on purpose.

Write it to ${scratch}/merge_${id}.py and run it with python3:

import json, re, os
root = "/Users/hariom/Desktop/One Word"
dst = os.path.join(root, "OneWord/Shared/${id}.json")
KEYS = {"term", "partOfSpeech", "hindi", "definition", "example"}
DEV = re.compile("[\\u0900-\\u097F]")
LATIN = re.compile("[A-Za-z]")
POS = {"noun", "adjective", "verb", "adverb", "prefix", "suffix", "phrase"}
existing = json.load(open(dst))
taken = {w["term"].strip() for w in existing}
out, rejected, dupes = list(existing), [], 0
for path in ${JSON.stringify(ok.map(b => `${scratch}/${id}-batch-${b.n}.json`))}:
    try:
        batch = json.load(open(path))
    except Exception as e:
        rejected.append((path, "unparseable: %s" % e)); continue
    for w in batch:
        if not isinstance(w, dict) or set(w) != KEYS:
            rejected.append((str(w)[:40], "schema")); continue
        key = w["term"].strip()
        if key in taken: dupes += 1; continue
        bad = [k for k, v in w.items() if not isinstance(v, str) or not v.strip()]
        if bad: rejected.append((key, "empty:" + ",".join(bad))); continue
        if LATIN.search(w["term"]): bad.append("latin-in-term")
        if not DEV.search(w["term"]): bad.append("term-not-devanagari")
        if not DEV.search(w["hindi"]) or LATIN.search(w["hindi"]): bad.append("hindi-bad")
        if w["partOfSpeech"].strip() not in POS: bad.append("pos:" + w["partOfSpeech"][:20])
        head = w["example"].rsplit(" \\u2014 ", 1)[0]
        if " \\u2014 " not in w["example"]: bad.append("example-no-emdash")
        elif LATIN.search(head): bad.append("latin-in-example-head")
        elif key not in head: bad.append("term-absent-from-example")
        if len(w["term"]) > 30: bad.append("headword>30")
        if len(w["definition"].split()) < 8: bad.append("definition-too-short")
        if bad: rejected.append((key, ",".join(bad))); continue
        # House style, enforced not requested: every shipped book has 0 sentence-cased and
        # 0 period-terminated definitions.
        dfn = w["definition"].strip().rstrip(".")
        first = dfn.split()[0]
        if dfn[:1].isupper() and not (len(first) > 1 and first.isupper()):
            dfn = dfn[0].lower() + dfn[1:]
        w["definition"] = dfn
        w["partOfSpeech"] = w["partOfSpeech"].strip()
        taken.add(key); out.append(w)
out.sort(key=lambda w: w["term"])
json.dump(out, open(dst, "w"), ensure_ascii=False, indent=2)
open(dst, "a").write("\\n")
print("TOTAL", len(out), "| was", len(existing), "| dupes", dupes, "| rejected", len(rejected))
reasons = {}
for t, r in rejected: reasons[r.split(",")[0]] = reasons.get(r.split(",")[0], 0) + 1
for r, n in sorted(reasons.items(), key=lambda kv: -kv[1]): print("  REJECT %4d  %s" % (n, r))

Then report the printed numbers verbatim, plus the final entry count of OneWord/Shared/${id}.json.
Do not delete the batch files.`,
  { label: 'merge', phase: 'Merge', agentType: 'claude', effort: 'low' },
)

// ---------------------------------------------------------------- Gates
phase('Gates')
const gates = await agent(
  `The "${id}" dictionary in the One Word repo just grew by many hundreds of entries. Get all four gates green:
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
  xcodebuild -project OneWord.xcodeproj -scheme OneWordWidget -destination 'platform=macOS' build
  tools/check_words.sh
  tools/check_related.sh

check_related.sh asserts >= 99% embedding coverage per book. The headwords are Devanagari and carry NO English
word vector, so the ENGLISH DEFINITION carries the whole gate (RelatedWords.swift:63 filters tokens of count <= 3).
If "${id}" fails it, fix the offending DEFINITIONS in OneWord/Shared/${id}.json — give them more long English
content words; report which terms you changed. Never weaken or delete an assertion to get green.
Report the final entry count and each gate's result.`,
  { label: 'gates', phase: 'Gates', agentType: 'build-fixer' },
)

return {
  id,
  target,
  themes: themes.length,
  perTheme,
  before: survey.count,
  editing: { rawKept, batches: ok.map(b => `${b.theme}: ${b.qa.kept} kept / ${b.qa.dropped} dropped / ${b.qa.fixed} fixed`) },
  merge,
  gates,
}
