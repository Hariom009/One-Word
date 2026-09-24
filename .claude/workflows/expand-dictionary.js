export const meta = {
  name: 'expand-dictionary',
  description: 'Grow an ALREADY-WIRED One Word dictionary to a target entry count: themed writer fan-out, per-batch editing, mechanical merge, then the build gates',
  whenToUse: 'The Wordbook is already registered and green, you just want more words in it. Pass {id, target, scratch, themes, book, kind, pos}; optional {rules, avoid, blocklist, mustHave, perTheme, root}.',
  phases: [
    { title: 'Survey', detail: 'read what the book already has' },
    { title: 'Write', detail: 'one writer + one editor per theme, each batch on disk' },
    { title: 'Merge', detail: 'deterministic dedupe/validate/sort into the real json' },
    { title: 'Gates', detail: 'both xcodebuild schemes + every check script' },
  ],
}

const cfg = typeof args === 'object' && args ? args : {}
const id = cfg.id
const target = cfg.target || 500          // the FINAL entry count, not the number to add
const scratch = cfg.scratch
const themes = cfg.themes || []
const book = cfg.book                     // display name, e.g. "Dictionary of Idioms"
const kind = cfg.kind                     // one entry, singular, e.g. "idiom"
const POS = cfg.pos || []                 // the only partOfSpeech values this book allows
const avoid = cfg.avoid || []             // other book ids whose terms this run must not take
const blocklist = cfg.blocklist || []     // json files of entries cut before; never bring them back
const root = cfg.root || '/Users/hariom/Desktop/One Word'
const mustHave = cfg.mustHave || []       // terms the run MUST land; the merge prints any that are missing
if (!id || !scratch || !themes.length || !book || !kind || !POS.length)
  throw new Error('expand-dictionary needs {id, target, scratch, themes, book, kind, pos}')
const dst = `${root}/OneWord/Shared/${id}.json`

// ---------------------------------------------------------------- Survey
phase('Survey')
const survey = await agent(
  `Read ${dst} in the One Word repo and report what is already there.

Return: the exact count (count it with python3, don't estimate), every term (verbatim), and the 3 entries you
judge the best examples of the house style so later writers can match them. Do not modify anything.`,
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

const gap = Math.max(0, target - survey.count)
if (!gap) return { id, target, before: survey.count, note: 'already at or past target; nothing written' }
const perTheme = cfg.perTheme || Math.ceil((gap * 1.2) / themes.length)   // headroom for dedupe + editor drops
log(`${id}.json holds ${survey.count}; gap ${gap} → ${perTheme} per theme across ${themes.length} themes`)

// The committed editorial rules for this book, verbatim from its plan.
const RULES = (cfg.rules || []).map(r => `- ${r}`).join('\n')

const SHAPE = `Entry shape — EXACTLY these five string keys, none empty:
  {"term": "", "partOfSpeech": "", "hindi": "", "definition": "", "example": ""}
partOfSpeech must be one of: ${POS.map(p => JSON.stringify(p)).join(', ')}
House exemplars already in the book:
${survey.exemplars.map(e => `  ${e}`).join('\n')}`

const AVOID = avoid.length
  ? `\nOther books own their own terms. Before using a term, check it is not already in ${avoid
      .map(b => `${root}/OneWord/Shared/${b}.json`).join(', ')} — if it is, pick another.`
  : ''

// ---------------------------------------------------------------- Write
phase('Write')
const written = await pipeline(
  themes.map((t, i) => ({ theme: t, n: i })),
  (item) => {
    const file = `${scratch}/${id}-batch-${item.n}.json`
    return agent(
      `Write ${perTheme} ${kind} entries for ONE theme of the "${book}" in the One Word macOS app.

THEME: ${item.theme}

Where it is natural, group entries into near-synonym clusters of 3-5 that mean nearly the same thing. The
related-words feature ranks by embedding similarity over the DEFINITION, so cluster members must share content words.

EDITORIAL RULES (committed by this book's plan — every one is load-bearing):
${RULES}

${SHAPE}

ALREADY IN THE BOOK — do not repeat any of these terms:
${survey.terms.join(', ')}
${AVOID}

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
      `Edit the ${kind} entries in ${file} for the "${book}". You are the editor, not the writer — be strict, and
rewrite the file in place.

Check every entry against these rules and FIX or DELETE:
${RULES}

Mechanical checks you must actually run, not eyeball:
- every entry has exactly the five keys term/partOfSpeech/hindi/definition/example, none empty
- partOfSpeech is exactly one of: ${POS.map(p => JSON.stringify(p)).join(', ')}
- hindi contains Devanagari and is a meaning, never a transliteration of the English
- headword <= 30 characters
- definition >= 8 content words, and NO meaning-bearing word of 3 characters or fewer carrying the sense
  (the index drops tokens of length <= 3 — "die" is invisible, "death"/"dying" are not)
- no duplicate terms inside this file
- the term is real and in use: if you cannot vouch for it, delete it rather than pass it

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
  `Merge the ${kind} batches into the real dictionary. Run EXACTLY this script — do not improvise the merge, and do not
hand-edit entries. It is deterministic on purpose.

Write it to ${scratch}/merge_${id}.py and run it with python3:

import json, re, os
root = ${JSON.stringify(root)}
dst = ${JSON.stringify(dst)}
KEYS = {"term", "partOfSpeech", "hindi", "definition", "example"}
POS = set(${JSON.stringify(POS)})
DEV = re.compile("[\\u0900-\\u097F]")
existing = json.load(open(dst))
taken = {w["term"].strip().lower() for w in existing}
owner = {}
for b in ${JSON.stringify(avoid)}:
    for w in json.load(open(os.path.join(root, "OneWord/Shared/%s.json" % b))):
        owner.setdefault(w["term"].strip().lower(), b)
for f in ${JSON.stringify(blocklist)}:
    for w in json.load(open(os.path.join(root, f))):
        owner.setdefault(w["term"].strip().lower(), "blocklist")
out, rejected, dupes, collide = list(existing), [], 0, {}
batches = []
for path in ${JSON.stringify(ok.map(b => `${scratch}/${id}-batch-${b.n}.json`))}:
    try:
        batches.append(json.load(open(path)))
    except Exception as e:
        rejected.append((path, "unparseable: %s" % e))
# A proper noun is a word the book writes capitalised mid-sentence and never in lowercase.
# ponytail: corpus evidence, not a dictionary. It misses a name the book never repeats
# mid-sentence, and it once kept "State" capitalised; the Idioms run had 1 such case in 3,047.
low, cap = set(), set()
for w in existing + [w for b in batches for w in b if isinstance(w, dict)]:
    for txt in (w.get("definition", ""), w.get("example", "")):
        for t in re.findall(r"[A-Za-z']+", str(txt))[1:]:
            (low if t[0].islower() else cap).add(t)
for batch in batches:
    for w in batch:
        if not isinstance(w, dict) or set(w) != KEYS:
            rejected.append((str(w)[:40], "schema")); continue
        key = w["term"].strip().lower()
        if key in taken: dupes += 1; continue
        if key in owner: collide[owner[key]] = collide.get(owner[key], 0) + 1; continue
        bad = [k for k, v in w.items() if not isinstance(v, str) or not v.strip()]
        if not bad:
            if not DEV.search(w["hindi"]): bad.append("hindi-not-devanagari")
            if len(w["term"]) > 30: bad.append("headword>30")
            if w["partOfSpeech"] not in POS: bad.append("pos:" + w["partOfSpeech"])
        if bad: rejected.append((w["term"], ",".join(bad))); continue
        # House style, enforced not requested: every shipped book has 0 sentence-cased and
        # 0 period-terminated definitions. A third of one run came back sentence-cased.
        # Proper nouns keep their capital: the Idioms run lowercased 35 "British"/"Indian".
        dfn = w["definition"].strip().rstrip(".")
        first = dfn.split()[0]
        word = (re.findall(r"[A-Za-z']+", first) or [""])[0]
        base = re.sub(r"'s$", "", word)
        nxt = dfn.split()[1:2]
        # A name, if the book never writes it lowercase and either writes it capitalised
        # elsewhere ("Heidegger" -> "Heidegger's") or a capital follows ("Derek Parfit's").
        # Philosophy lost 232 capitals to the old test, which missed both shapes.
        proper = base[:1].lower() + base[1:] not in low and (
            base in cap or (bool(nxt) and nxt[0][:1].isupper()))
        if dfn[:1].isupper() and not (len(first) > 1 and first.isupper()) and not proper:
            dfn = dfn[0].lower() + dfn[1:]
        w["definition"] = dfn
        taken.add(key); out.append(w)
out.sort(key=lambda w: w["term"].lower())
json.dump(out, open(dst, "w"), ensure_ascii=False, indent=1)
print("TOTAL", len(out), "| was", len(existing), "| dupes", dupes, "| collisions", collide, "| rejected", len(rejected))
for r in rejected[:25]: print("  REJECT", r)
must = ${JSON.stringify(mustHave)}
final = {w["term"].strip().lower() for w in out}
gap = [m for m in must if m.strip().lower() not in final]
print("MUST-HAVE", len(must) - len(gap), "of", len(must), "present")
for g in gap: print("  MISSING", g)

Then report the printed numbers verbatim, plus the final entry count of ${dst}.
Do not delete the batch files.`,
  { label: 'merge', phase: 'Merge', agentType: 'claude', effort: 'low' },
)

// ---------------------------------------------------------------- Gates
phase('Gates')
const gates = await agent(
  `The "${id}" dictionary in the One Word repo at ${root} just grew by several hundred entries. Working in that
directory (cd into it first), get every gate green:
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
  xcodebuild -project OneWord.xcodeproj -scheme OneWordWidget -destination 'platform=macOS' build
  for s in tools/check_*.sh; do bash "$s" || echo "FAILED $s"; done

check_related.sh asserts >= 99% embedding coverage per book. If "${id}" now fails it, the cause is entry content —
definitions whose meaning-bearing words are all <= 3 characters vectorise to nothing (RelatedWords.swift:63 filters
tokens of count <= 3). Fix the offending DEFINITIONS in ${dst}; report which terms you changed.
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
