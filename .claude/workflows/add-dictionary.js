export const meta = {
  name: 'add-dictionary',
  description: 'Add a new One Word dictionary end to end: brainstorm -> strategy -> plan -> audits -> word writing -> wiring -> build -> review',
  whenToUse: 'Adding a new Wordbook (themed dictionary) to One Word. Pass the theme as args, e.g. "Dictionary of Cinema" or "words a chef uses".',
  phases: [
    { title: 'Recon', detail: 'map every file a new dictionary touches, as the repo stands today' },
    { title: 'Brainstorm', detail: '3 independent lenses on the theme' },
    { title: 'Strategy', detail: 'converge to one committed identity + dimensions' },
    { title: 'Plan', detail: 'file-level plan, adversarial audit, resolution' },
    { title: 'Checklist', detail: 'build checklist + fidelity audit' },
    { title: 'Words', detail: 'one writer + one editor per dimension' },
    { title: 'Wire', detail: 'write the json, register the Wordbook, patch the widget target' },
    { title: 'Build', detail: 'xcodebuild both schemes + the two check scripts' },
    { title: 'Review', detail: 'code review, findings validated, blockers fixed' },
  ],
}

const theme = (typeof args === 'string' ? args : (args && args.theme) || '').trim()
if (!theme) throw new Error('add-dictionary needs a theme, e.g. Workflow({name:"add-dictionary", args:"Dictionary of Cinema"})')

// What the repo looked like when this workflow was written. Recon re-derives it;
// this is here so a stale fact shows up as a contradiction, not as a silent gap.
const KNOWN = `
- Entry shape (OneWord/Shared/Word.swift): exactly term, partOfSpeech, hindi, definition, example — all String, all required.
- A dictionary is: OneWord/Shared/<id>.json + a Wordbook static in OneWord/Wordbook.swift + the id in Wordbook.all.
- The app target is a fileSystemSynchronizedGroup over OneWord/, so a new json under OneWord/Shared/ joins the APP automatically.
  The WIDGET target is NOT synchronized: OneWord.xcodeproj/project.pbxproj needs a PBXFileReference, a PBXBuildFile,
  an entry in the SharedRefs group, and an entry in the widget's PBXResourcesBuildPhase (the one that already lists words.json).
  Missing that = the widget fatalErrors at runtime ("check target membership"). This is THE gotcha.
- tools/WordProviderCheck.swift and tools/RelatedWordsCheck.swift each hardcode a 'books' array of dictionary ids — a new id goes in both.
- Covers must stay dark (low L*) — white title/symbol sits on them. Symbol is an SF Symbol that must exist on macOS 14.
- Precedent: STARTUP_DICTIONARY_BRAINSTORM.md is the house brainstorm format; startup.json / curiosities.json are the house entry quality bar.
`

const RECON = {
  type: 'object',
  required: ['existingIds', 'coversInUse', 'symbolsInUse', 'touchPoints', 'checkCommands', 'contradictions'],
  properties: {
    existingIds: { type: 'array', items: { type: 'string' } },
    coversInUse: { type: 'array', items: { type: 'string' } },
    symbolsInUse: { type: 'array', items: { type: 'string' } },
    touchPoints: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'change'],
        properties: { file: { type: 'string' }, change: { type: 'string' } },
      },
    },
    checkCommands: { type: 'array', items: { type: 'string' } },
    contradictions: { type: 'array', items: { type: 'string' } },
  },
}

const FACTS = {
  type: 'object',
  required: ['id', 'name', 'cover', 'symbol', 'sourcing', 'targetSize', 'rules', 'dimensions'],
  properties: {
    id: { type: 'string' },
    name: { type: 'string' },
    cover: { type: 'string' },
    symbol: { type: 'string' },
    sourcing: { type: 'string', enum: ['curated', 'wordnet'] },
    targetSize: { type: 'integer' },
    rules: { type: 'array', items: { type: 'string' } },
    dimensions: {
      type: 'array',
      items: {
        type: 'object',
        required: ['name', 'count', 'seedTerms'],
        properties: {
          name: { type: 'string' },
          count: { type: 'integer' },
          seedTerms: { type: 'array', items: { type: 'string' } },
        },
      },
    },
  },
}

const ENTRIES = {
  type: 'object',
  required: ['entries'],
  properties: {
    entries: {
      type: 'array',
      items: {
        type: 'object',
        required: ['term', 'partOfSpeech', 'hindi', 'definition', 'example'],
        properties: {
          term: { type: 'string' },
          partOfSpeech: { type: 'string' },
          hindi: { type: 'string' },
          definition: { type: 'string' },
          example: { type: 'string' },
        },
      },
    },
  },
}

const EDIT = {
  type: 'object',
  required: ['drop', 'fix'],
  properties: {
    drop: { type: 'array', items: { type: 'string' } },
    fix: {
      type: 'array',
      items: {
        type: 'object',
        required: ['term', 'field', 'value'],
        properties: { term: { type: 'string' }, field: { type: 'string' }, value: { type: 'string' } },
      },
    },
    notes: { type: 'string' },
  },
}

const BLOCKERS = {
  type: 'object',
  required: ['blockers'],
  properties: {
    blockers: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'problem', 'fix'],
        properties: { file: { type: 'string' }, problem: { type: 'string' }, fix: { type: 'string' } },
      },
    },
  },
}

// ---------------------------------------------------------------- Recon
phase('Recon')
const recon = await agent(
  `You are mapping the One Word macOS repo so later agents don't guess.

Read: OneWord/Wordbook.swift, OneWord/Shared/Word.swift, OneWord/Shared/WordProvider.swift,
OneWord/DictionaryPicker.swift, tools/WordProviderCheck.swift, tools/RelatedWordsCheck.swift,
tools/check_words.sh, tools/check_related.sh, and OneWord.xcodeproj/project.pbxproj
(the PBXResourcesBuildPhase that lists the .json files, the SharedRefs group, and
fileSystemSynchronizedGroups).

Report, from the CODE as it stands right now:
- existingIds: every Wordbook id currently registered
- coversInUse / symbolsInUse: the cover hex values and SF Symbols already taken
- touchPoints: every file a NEW dictionary must change, and exactly what the change is
  (be specific about the pbxproj: which sections, and which target's Resources phase)
- checkCommands: the exact shell commands that verify a dictionary works
- contradictions: anything below that is no longer true of the repo (empty array if all still true)

What was true when this workflow was written:
${KNOWN}`,
  { label: 'recon', phase: 'Recon', schema: RECON, agentType: 'Explore' },
)

const facts = recon || { existingIds: [], coversInUse: [], symbolsInUse: [], touchPoints: [], checkCommands: [], contradictions: [] }
if (facts.contradictions.length) log(`recon contradicts ${facts.contradictions.length} assumption(s): ${facts.contradictions.join(' | ')}`)
log(`existing dictionaries: ${facts.existingIds.join(', ')}`)

const GROUND = `
THEME REQUESTED BY THE OPERATOR: ${theme}

Repo ground truth (verified this run):
- existing dictionary ids: ${facts.existingIds.join(', ')}
- cover hexes already used: ${facts.coversInUse.join(', ')}
- SF Symbols already used: ${facts.symbolsInUse.join(', ')}
- files a new dictionary touches:
${facts.touchPoints.map(t => `  - ${t.file}: ${t.change}`).join('\n')}
- verification commands: ${facts.checkCommands.join(' ; ')}
${KNOWN}`

// ---------------------------------------------------------------- Brainstorm
phase('Brainstorm')
const LENSES = [
  {
    key: 'identity',
    ask: `EDITORIAL IDENTITY. What is this book actually FOR, and who opens it? Name candidates (house pattern: "Dictionary of X").
Its editorial compass: what does the definition field promise, what does the example field do, what tone. The word dimensions
(6-10 categories with 8-15 seed terms each) that together make one coherent book. What to deliberately leave out.
Read STARTUP_DICTIONARY_BRAINSTORM.md first — match that document's rigor and format.`,
  },
  {
    key: 'sourcing',
    ask: `SOURCING AND FEASIBILITY. Can this vocabulary come out of WordNet via the dominant-sense purity gate
(read tools/gen_words/README.md and tools/gen_words/philosophy_extract.py), or must the entries be written by hand the way
startup.json and curiosities.json were? Note that tools/gen_words has NO venv checked in and the Argos translate pass takes ~20 min,
so a WordNet route is a real cost, not a free one. Be honest about the ceiling: how many GENUINE terms this theme can yield
before it starts padding. What the right v1 size is. How the Hindi field should read for this theme (equivalent + short gloss,
never a transliteration), and where offline/naive translation would go wrong here.`,
  },
  {
    key: 'fit',
    ask: `PRODUCT FIT AND FAILURE MODES. Does this book overlap an existing one enough to be redundant? Read a sample of the
existing jsons in OneWord/Shared/ to judge. How does it behave in the actual surfaces: a desktop widget showing ONE word a day,
the alphabetical browse list, and the related-words box (OneWord/RelatedWords.swift — it needs >=99% embedding coverage per book
and multi-word/acronym terms are the weak spot; read tools/RelatedWordsCheck.swift for what is asserted). Which cover hex and
SF Symbol fit, given what's taken. What would make this book feel cheap or padded, and what the failure modes are.`,
  },
]

const briefs = (await parallel(LENSES.map(l => () =>
  agent(`${GROUND}\n\nBrainstorm ONE lens of a proposed new One Word dictionary.\n\n${l.ask}\n\nGround every claim in the actual repo. Return the brainstorm itself, no preamble.`,
    { label: `brainstorm:${l.key}`, phase: 'Brainstorm', agentType: 'brainstormer' }),
))).filter(Boolean)

if (!briefs.length) throw new Error('every brainstorm lens failed — nothing to converge')
log(`${briefs.length}/3 brainstorm lenses returned`)

// ---------------------------------------------------------------- Strategy
phase('Strategy')
const strategy = await agent(
  `${GROUND}

Three independent brainstorms of this proposed dictionary follow. Converge them into ONE committed strategy.

Make the code-dictated calls yourself (entry shape, wiring, id naming, cover darkness, symbol availability).
Commit to: the id, the display name, the cover hex, the SF Symbol, the sourcing route (curated-by-hand vs WordNet extractor),
the v1 size, the editorial rules, and the final list of dimensions with a per-dimension word count and seed terms.
Where the lenses disagree, pick and say why. Surface any genuinely operator-owned fork with a recommended default.

=== LENS: IDENTITY ===
${briefs[0] || '(failed)'}

=== LENS: SOURCING ===
${briefs[1] || '(failed)'}

=== LENS: FIT ===
${briefs[2] || '(failed)'}`,
  { label: 'strategize', phase: 'Strategy', agentType: 'strategize' },
)

const decided = await agent(
  `Extract the committed decisions from this strategy document as structured data. Do not re-decide anything, do not improve it —
transcribe what it commits to. cover must be a 0x-prefixed hex string. id must be lowercase, no spaces (it is also the json filename).
dimensions must carry the per-dimension word count and seed terms the strategy chose.

Already-taken ids: ${facts.existingIds.join(', ')}
Already-taken covers: ${facts.coversInUse.join(', ')}

=== STRATEGY ===
${strategy}`,
  { label: 'decisions', phase: 'Strategy', schema: FACTS, agentType: 'claude', effort: 'low' },
)

if (!decided) throw new Error('could not read the committed decisions out of the strategy')
log(`committed: ${decided.name} (id "${decided.id}", ${decided.cover}, ${decided.symbol}) — ${decided.sourcing}, target ${decided.targetSize}`)

if (decided.sourcing === 'wordnet') {
  log('STOP: the strategy chose the WordNet route. That needs tools/gen_words + a python venv + the ~20min Argos pass, which this workflow does not run.')
  return {
    stopped: 'wordnet-sourcing',
    strategy,
    decided,
    next: 'Set up tools/gen_words/venv per tools/gen_words/README.md, write <id>_extract.py + <id>_translate.py modelled on philosophy_*.py, generate OneWord/Shared/<id>.json, then re-run this workflow (or just the wiring phase) with the json already in place.',
  }
}

// ---------------------------------------------------------------- Plan
phase('Plan')
const WIRING = `Scope is ONLY the wiring for a new dictionary — the word content is generated separately by this same workflow
and lands as OneWord/Shared/${decided.id}.json. Plan: registering Wordbook.${decided.id} (name "${decided.name}", cover ${decided.cover},
symbol ${decided.symbol}) and adding it to Wordbook.all; getting ${decided.id}.json into BOTH targets (app = filesystem-synchronized group,
widget = explicit project.pbxproj entries); adding the id to the books arrays in tools/WordProviderCheck.swift and tools/RelatedWordsCheck.swift;
and the verification gates. Keep it proportionate: this is a small, well-precedented diff, not a new subsystem.`

const plan = await agent(`${GROUND}\n\n${WIRING}\n\nProduce the file-level implementation plan.`,
  { label: 'plan', phase: 'Plan', agentType: 'ios-planner', model: 'sonnet', effort: 'medium' })

const planAudit = await agent(
  `${GROUND}\n\nAdversarially audit this plan for adding the "${decided.name}" dictionary. Re-ground every claim against the real code.
Pay particular attention to: whether the widget target genuinely gets the resource (the pbxproj sections named must actually exist),
whether the check scripts' hardcoded books arrays are covered, whether the RelatedWords >=99% coverage assertion will hold for a book
of this size and term style, and whether the cover/symbol choices are valid and legible.\n\n=== PLAN ===\n${plan}`,
  { label: 'plan-audit', phase: 'Plan', agentType: 'plan-auditor', model: 'sonnet', effort: 'medium' },
)

const resolved = await agent(
  `${GROUND}\n\nResolve this audit into a revised, build-ready plan. Fix the code-dictated findings yourself; for operator-owned forks
take the recommended default and mark it for review.\n\n=== PLAN ===\n${plan}\n\n=== AUDIT ===\n${planAudit}`,
  { label: 'plan-resolve', phase: 'Plan', agentType: 'plan-resolver', model: 'sonnet', effort: 'medium' },
)

// ---------------------------------------------------------------- Checklist
phase('Checklist')
const checklist = await agent(`${GROUND}\n\nTurn this resolved plan into a dependency-ordered build checklist with a real done-when on every item.\n\n=== PLAN ===\n${resolved}`,
  { label: 'checklist', phase: 'Checklist', agentType: 'checklist-writer', model: 'sonnet', effort: 'medium' })

const checklistAudit = await agent(
  `Audit this checklist against the plan it derives from: every plan step represented, nothing invented, every item atomic with a checkable done-when.
\n=== PLAN ===\n${resolved}\n\n=== CHECKLIST ===\n${checklist}`,
  { label: 'checklist-audit', phase: 'Checklist', agentType: 'checklist-auditor', model: 'sonnet', effort: 'medium' },
)

// ---------------------------------------------------------------- Words
phase('Words')
// The strategy may commit to more dimensions than we want writer agents. GROUP the tail
// into the batches instead of slicing it off: a silent `.slice(0, 8)` once shipped 31 of a
// committed 120 entries, because the strategy had chosen 30 families of 4.
const MAX_WRITERS = 8
const wanted = decided.dimensions
const per = Math.ceil(wanted.length / MAX_WRITERS)
const dims = []
for (let i = 0; i < wanted.length; i += per) {
  const group = wanted.slice(i, i + per)
  dims.push({
    name: group.map(g => g.name).join(' + '),
    count: group.reduce((n, g) => n + g.count, 0),
    seedTerms: group.flatMap(g => g.seedTerms),
    parts: group,
  })
}
const targeted = dims.reduce((n, d) => n + d.count, 0)
log(`${wanted.length} dimensions -> ${dims.length} writer batches, ${targeted} entries targeted (strategy asked for ${decided.targetSize})`)
if (targeted < decided.targetSize) log(`WARNING: batching targets ${targeted}, short of the committed ${decided.targetSize}`)

const SHAPE = `Entry shape — EXACTLY these five string keys, no others, none empty:
  { "term": "", "partOfSpeech": "", "hindi": "", "definition": "", "example": "" }
- partOfSpeech: noun / verb / adjective / adverb / idiom / phrase / acronym.
- hindi: the MEANING in Devanagari (equivalent + a short gloss after an em dash), never a transliteration of the English word.
- definition: dictionary-honest, lowercase start, no trailing period needed, does not begin with the term itself.
- example: one natural sentence actually using the term.
House quality bar: read OneWord/Shared/startup.json and OneWord/Shared/curiosities.json before writing.`

const RULES = decided.rules.map(r => `- ${r}`).join('\n')

const drafted = await pipeline(
  dims,
  (d) => agent(
    `Write dictionary entries for ONE dimension of "${decided.name}" (One Word, a macOS word-a-day app).

DIMENSION: ${d.name}
WRITE: ${d.count} entries total${d.parts.length > 1 ? `, covering EVERY sub-dimension below — do not stop after the first one:\n${d.parts.map(p => `  - ${p.name}: ${p.count} entries · seeds: ${p.seedTerms.join(', ')}`).join('\n')}` : `.\nSEED TERMS (a starting point, not a quota — drop weak ones, add better ones that fit): ${d.seedTerms.join(', ')}`}

EDITORIAL RULES (from the committed strategy):
${RULES}

${SHAPE}

Only terms that genuinely belong to this dimension. No padding: ${d.count} strong entries beats ${d.count} slots filled.`,
    { label: `write:${d.name}`, phase: 'Words', schema: ENTRIES, agentType: 'claude', effort: 'medium' },
  ),
  (res, d) => !res ? null : agent(
    `Edit these draft entries for "${decided.name}" / dimension "${d.name}". You are the editor, not the writer — be strict.

Drop a term if: it doesn't belong to this dimension, it's padding, it's a duplicate sense, or it fails the strategy's rules.
Fix a field if: the hindi is a transliteration rather than a meaning, or is missing Devanagari, or the definition restates the term,
or the example doesn't use the term naturally, or partOfSpeech is wrong.

EDITORIAL RULES:
${RULES}

Return only the drops and the field fixes (term + field + corrected value). Empty arrays if it's all clean.

=== DRAFT ===
${JSON.stringify(res.entries, null, 1)}`,
    { label: `edit:${d.name}`, phase: 'Words', schema: EDIT, agentType: 'claude', effort: 'medium' },
  ).then(qa => ({ dim: d.name, entries: res.entries, qa: qa || { drop: [], fix: [] } })),
)

// Merge, apply edits, dedupe, validate — plain code, no agent needed.
const DEVANAGARI = /[ऀ-ॿ]/
const seen = new Set()
const merged = []
const rejected = []
let dropped = 0
let fixed = 0

for (const batch of drafted.filter(Boolean)) {
  const drop = new Set((batch.qa.drop || []).map(t => t.trim().toLowerCase()))
  const fixes = {}
  for (const f of batch.qa.fix || []) {
    const k = f.term.trim().toLowerCase()
    fixes[k] = fixes[k] || {}
    fixes[k][f.field] = f.value
  }
  for (const e of batch.entries) {
    const key = e.term.trim().toLowerCase()
    if (drop.has(key)) { dropped++; continue }
    if (seen.has(key)) { dropped++; continue }
    const patch = fixes[key]
    if (patch) fixed++
    const entry = {
      term: (patch && patch.term) || e.term,
      partOfSpeech: (patch && patch.partOfSpeech) || e.partOfSpeech,
      hindi: (patch && patch.hindi) || e.hindi,
      definition: (patch && patch.definition) || e.definition,
      example: (patch && patch.example) || e.example,
    }
    const bad = Object.entries(entry).filter(([, v]) => typeof v !== 'string' || !v.trim()).map(([k]) => k)
    if (!DEVANAGARI.test(entry.hindi)) bad.push('hindi-not-devanagari')
    if (bad.length) { rejected.push(`${entry.term} (${bad.join(', ')})`); continue }
    seen.add(key)
    merged.push(entry)
  }
}

merged.sort((a, b) => a.term.localeCompare(b.term))
log(`${merged.length} entries kept · ${dropped} dropped by the editors/dedupe · ${fixed} field-fixed · ${rejected.length} rejected by validation`)
if (rejected.length) log(`rejected: ${rejected.slice(0, 12).join(' | ')}${rejected.length > 12 ? ' …' : ''}`)
if (merged.length < 0.7 * targeted) log(`WARNING: shipping ${merged.length} entries against a target of ${targeted} — the writers under-delivered, not the editors`)
if (merged.length < 15) throw new Error(`only ${merged.length} entries survived — too few to ship a dictionary`)

// ---------------------------------------------------------------- Wire
phase('Wire')
const writeJson = await agent(
  `Write this exact JSON array to OneWord/Shared/${decided.id}.json in the One Word repo. VERBATIM — do not rewrite, reword,
reorder, add, or drop a single entry. Use a quoted heredoc so nothing is shell-expanded, keep the Devanagari as UTF-8
(no \\u escapes), and format it like the existing OneWord/Shared/curiosities.json (2-space indent).

Then verify and report: python3 -c "import json;d=json.load(open('OneWord/Shared/${decided.id}.json'));print(len(d), all(set(w)=={'term','partOfSpeech','hindi','definition','example'} for w in d))"
It must print ${merged.length} True.

=== JSON ===
${JSON.stringify(merged, null, 2)}`,
  { label: 'write-json', phase: 'Wire', agentType: 'claude' },
)

const wired = await agent(
  `${GROUND}

Do the WIRING for the new dictionary. OneWord/Shared/${decided.id}.json already exists (${merged.length} entries) — do NOT touch its contents.

Follow this checklist exactly:
${checklist}

Audit findings to respect:
${checklistAudit}

Identity: id "${decided.id}", name "${decided.name}", cover ${decided.cover}, symbol ${decided.symbol}.
Do not run the build — the next agent owns that.`,
  { label: 'wire', phase: 'Wire', agentType: 'implement' },
)

// ---------------------------------------------------------------- Build
phase('Build')
const built = await agent(
  `Get the One Word repo green after adding the "${decided.name}" dictionary (id "${decided.id}").

Gates, all four must pass:
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
  xcodebuild -project OneWord.xcodeproj -scheme OneWordWidget -destination 'platform=macOS' build
  tools/check_words.sh
  tools/check_related.sh

Both check scripts hardcode a books array — "${decided.id}" must be in both, and check_related.sh asserts >=99% embedding
coverage per book, so a failure there is real signal about the entries, not just a script to edit. Fix causes, not assertions:
never weaken or delete an assertion to get green. If the widget build passes but ${decided.id}.json is missing from the widget's
Resources build phase in project.pbxproj, that is a runtime fatalError waiting to happen — check it explicitly and report it.`,
  { label: 'build', phase: 'Build', agentType: 'build-fixer' },
)

// ---------------------------------------------------------------- Review
phase('Review')
const review = await agent(
  `Review the working-tree diff that adds the "${decided.name}" dictionary (git diff / git status against HEAD).
Focus: the Wordbook registration, the project.pbxproj edits (are the widget's PBXFileReference / PBXBuildFile / SharedRefs group /
Resources phase entries all present and internally consistent — no duplicate or dangling UUIDs?), the check-script edits,
and the json's schema/encoding. Flag anything that would fatalError at runtime or ship a broken widget.`,
  { label: 'review', phase: 'Review', agentType: 'code-reviewer' },
)

const validation = await agent(
  `Validate these review findings against the ACTUAL working tree. Re-locate every cited file and line, read the real code,
rule each finding Confirmed / Refuted / Unverifiable with fresh evidence.\n\n=== REVIEW ===\n${review}`,
  { label: 'validate', phase: 'Review', agentType: 'findings-validator' },
)

const confirmed = await agent(
  `From this validation report, list ONLY the findings ruled Confirmed that would break the build or ship a runtime failure
(a missing widget resource, a broken json, a dangling pbxproj reference, a wrong Wordbook id). Cosmetic, stylistic, and
Refuted/Unverifiable findings do not belong here. Empty array if there are none.\n\n=== VALIDATION ===\n${validation}`,
  { label: 'blockers', phase: 'Review', schema: BLOCKERS, agentType: 'claude', effort: 'low' },
)

let repair = null
const blockers = (confirmed && confirmed.blockers) || []
if (blockers.length) {
  log(`${blockers.length} confirmed blocker(s) — repairing`)
  repair = await agent(
    `Fix these confirmed blockers in the One Word repo, then re-run all four gates until green:
  xcodebuild -project OneWord.xcodeproj -scheme OneWord -destination 'platform=macOS' build
  xcodebuild -project OneWord.xcodeproj -scheme OneWordWidget -destination 'platform=macOS' build
  tools/check_words.sh
  tools/check_related.sh

${blockers.map((b, i) => `${i + 1}. ${b.file} — ${b.problem}\n   fix: ${b.fix}`).join('\n')}`,
    { label: 'repair', phase: 'Review', agentType: 'build-fixer' },
  )
} else {
  log('no confirmed blockers')
}

return {
  dictionary: { id: decided.id, name: decided.name, cover: decided.cover, symbol: decided.symbol, entries: merged.length },
  sample: merged.slice(0, 5).map(e => `${e.term} — ${e.definition}`),
  counts: { kept: merged.length, dropped, fixed, rejected: rejected.length, dimensions: dims.length },
  docs: { strategy, plan: resolved, planAudit, checklist, checklistAudit },
  build: built,
  review: { findings: review, validation, blockers, repair },
  writeJson,
  wired,
  testBrief: [
    `Open the app, hit the dictionary picker, and confirm "${decided.name}" is on the shelf with the right cover and symbol.`,
    `Select it — today's word should come from ${decided.id}.json, and the related-words box should show something sane.`,
    `Browse/search the list: ${merged.length} entries, alphabetical, Hindi renders as Devanagari.`,
    `THE REAL TEST: right-click desktop, Edit Widgets, add "Word of the Day", set it to "${decided.name}". If the widget crashes or shows a blank word, the json never made it into the widget target's Resources phase.`,
  ],
}
