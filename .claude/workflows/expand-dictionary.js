export const meta = {
  name: 'expand-dictionary',
  description: 'Grow an ALREADY-WIRED One Word dictionary to a target entry count: themed writer fan-out, per-batch editing, mechanical merge, then the build gates',
  whenToUse: 'The Wordbook is already registered and green, you just want more words in it. Pass {id, target, scratch, themes}.',
  phases: [
    { title: 'Survey', detail: 'read what the book already has' },
    { title: 'Write', detail: 'one writer + one editor per theme, each batch on disk' },
    { title: 'Merge', detail: 'deterministic dedupe/validate/sort into the real json' },
    { title: 'Gates', detail: 'both xcodebuild schemes + both check scripts' },
  ],
}

const cfg = typeof args === 'object' && args ? args : {}
const id = cfg.id
const target = cfg.target || 500
const scratch = cfg.scratch
const themes = cfg.themes || []
if (!id || !scratch || !themes.length) throw new Error('expand-dictionary needs {id, target, scratch, themes}')

const perTheme = cfg.perTheme || Math.ceil((target * 1.2) / themes.length)   // headroom for dedupe + editor drops
const mustHave = cfg.mustHave || []   // terms the run MUST land; the merge prints any that are missing

// ---------------------------------------------------------------- Survey
phase('Survey')
const survey = await agent(
  `Read OneWord/Shared/${id}.json in the One Word repo and report what is already there.

Return: the exact count, every term (verbatim), and the 3 entries you judge the best examples of the house
style so later writers can match them. Do not modify anything.`,
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
log(`${id}.json currently holds ${survey.count} entries; writing ${perTheme} per theme across ${themes.length} themes toward ${target}`)

// The committed editorial rules for this book, verbatim from its strategy run.
const RULES = (cfg.rules || []).map(r => `- ${r}`).join('\n')

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
      `Write ${perTheme} English idiom entries for ONE semantic theme of the "Dictionary of Idioms" in the One Word macOS app.

THEME: ${item.theme}

Structure them as meaning-families: roughly ${Math.round(perTheme / 4)} families of 3-5 idioms that mean nearly the
same thing. The related-words feature ranks by embedding similarity over the DEFINITION, so family members must share
content words — that sharing is what makes the feature work, and singletons return noise.

EDITORIAL RULES (committed by this book's strategy — every one is load-bearing):
${RULES}

${SHAPE}

ALREADY IN THE BOOK — do not repeat any of these terms:
${survey.terms.join(', ')}

Also avoid workplace/corporate-register idioms: they belong to the existing Corporate Slang book. If unsure whether a
term is already taken, grep OneWord/Shared/startup.json before using it.

Write the JSON array to ${file} — a bare array of ${perTheme} entry objects, UTF-8 Devanagari (no \\u escapes), 1-space
indent. Then verify with:
  python3 -c "import json;d=json.load(open('${file}'));print(len(d))"

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
      `Edit the idiom entries in ${file}. You are the editor, not the writer — be strict, and rewrite the file in place.

Check every entry against these rules and FIX or DELETE:
${RULES}

Mechanical checks you must actually run, not eyeball:
- every entry has exactly the five keys term/partOfSpeech/hindi/definition/example, none empty
- hindi contains Devanagari and is a meaning, never a transliteration of the English
- headword <= 30 characters, no leading article
- partOfSpeech <= 11 characters
- definition >= 8 content words, and NO meaning-bearing word of 3 characters or fewer carrying the sense
  (the index drops tokens of length <= 3 — "die" is invisible, "death"/"dying" are not)
- within a family, members share >= 2 content words, and their first words differ
- no duplicate terms inside this file

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
  `Merge the idiom batches into the real dictionary. Run EXACTLY this script — do not improvise the merge, and do not
hand-edit entries. It is deterministic on purpose.

Write it to ${scratch}/merge_${id}.py and run it with python3:

import json, re, os
root = "/Users/hariom/Desktop/One Word"
dst = os.path.join(root, "OneWord/Shared/${id}.json")
KEYS = {"term", "partOfSpeech", "hindi", "definition", "example"}
DEV = re.compile("[\\u0900-\\u097F]")
existing = json.load(open(dst))
taken = {w["term"].strip().lower() for w in existing}
slang = {w["term"].strip().lower() for w in json.load(open(os.path.join(root, "OneWord/Shared/startup.json")))}
out, rejected, dupes, collide = list(existing), [], 0, 0
for path in ${JSON.stringify(ok.map(b => `${scratch}/${id}-batch-${b.n}.json`))}:
    try:
        batch = json.load(open(path))
    except Exception as e:
        rejected.append((path, "unparseable: %s" % e)); continue
    for w in batch:
        if not isinstance(w, dict) or set(w) != KEYS:
            rejected.append((str(w)[:40], "schema")); continue
        key = w["term"].strip().lower()
        if key in taken: dupes += 1; continue
        if key in slang: collide += 1; continue
        bad = [k for k, v in w.items() if not isinstance(v, str) or not v.strip()]
        if not DEV.search(w["hindi"]): bad.append("hindi-not-devanagari")
        if len(w["term"]) > 30: bad.append("headword>30")
        if len(w["partOfSpeech"]) > 11: bad.append("pos>11")
        if bad: rejected.append((w["term"], ",".join(bad))); continue
        # House style, enforced not requested: every shipped book has 0 sentence-cased and
        # 0 period-terminated definitions. A third of one run came back sentence-cased.
        dfn = w["definition"].strip().rstrip(".")
        first = dfn.split()[0]
        if dfn[:1].isupper() and not (len(first) > 1 and first.isupper()):
            dfn = dfn[0].lower() + dfn[1:]
        w["definition"] = dfn
        taken.add(key); out.append(w)
out.sort(key=lambda w: w["term"].lower())
json.dump(out, open(dst, "w"), ensure_ascii=False, indent=1)
print("TOTAL", len(out), "| was", len(existing), "| dupes", dupes, "| startup-collisions", collide, "| rejected", len(rejected))
for r in rejected[:25]: print("  REJECT", r)
must = ${JSON.stringify(mustHave)}
final = {w["term"].strip().lower() for w in out}
gap = [m for m in must if m.strip().lower() not in final]
print("MUST-HAVE", len(must) - len(gap), "of", len(must), "present")
for g in gap: print("  MISSING", g)

Then report the printed numbers verbatim, plus the final entry count of OneWord/Shared/${id}.json.
Do not delete the batch files.`,
  { label: 'merge', phase: 'Merge', agentType: 'claude', effort: 'low' },
)

// ---------------------------------------------------------------- Gates
phase('Gates')
const gates = await agent(
  `The "${id}" dictionary in the One Word repo just grew by several hundred entries. Get all four gates green:
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
  xcodebuild -project OneWord.xcodeproj -scheme OneWordWidget -destination 'platform=macOS' build
  tools/check_words.sh
  tools/check_related.sh

check_related.sh asserts >= 99% embedding coverage per book. If "${id}" now fails it, the cause is entry content —
definitions whose meaning-bearing words are all <= 3 characters vectorise to nothing (RelatedWords.swift:63 filters
tokens of count <= 3). Fix the offending DEFINITIONS in OneWord/Shared/${id}.json; report which terms you changed.
Never weaken or delete an assertion to get green. Report the final entry count and each gate's result.`,
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
