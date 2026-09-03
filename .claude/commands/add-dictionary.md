---
description: Add a new dictionary (Wordbook) to One Word via the full multi-agent workflow
argument-hint: <theme> — e.g. "Dictionary of Cinema" or "words a chef uses"
allowed-tools: Workflow, Bash, Read, Edit
---

Add a new dictionary to One Word, end to end, using the `add-dictionary` workflow.

Theme requested: **$ARGUMENTS**

## What to do

1. If the theme above is empty, ask the user what the dictionary should be about and stop until they answer.
   Anything else — a bare theme, a vague one, a one-liner — is enough to start; the brainstorm phase exists
   precisely to shape it, so do not interview the user first.

2. Run the workflow (this command is the user's explicit opt-in to multi-agent orchestration):

   `Workflow({ name: "add-dictionary", args: "<the theme>" })`

   If the name doesn't resolve, use `{ scriptPath: ".claude/workflows/add-dictionary.js", args: "<the theme>" }`.

   It runs ~28 agents across nine phases: recon → 3 brainstorm lenses → strategy → plan/plan-audit/plan-resolve →
   checklist/checklist-audit → one writer + one editor per word dimension → write the json + wire it up →
   xcodebuild both schemes + both check scripts → code review, findings validation, blocker repair.
   It runs in the background; wait for the notification rather than re-invoking it.

3. When it returns, read the result:

   - `stopped: "wordnet-sourcing"` means the strategy decided this theme needs the WordNet/Argos pipeline in
     `tools/gen_words`, which the workflow does not run. Relay `next` and stop — don't hand-roll it.
   - Otherwise: report the committed identity (`dictionary`), the entry counts (`counts`), the sample entries,
     whether the build gates went green (`build`), and any confirmed blockers and their repair (`review`).
     State failures plainly; don't smooth over a red gate.

4. Offer to save the strategy and plan docs from `docs` as
   `Docs/01_Brainstorm/<ID>_DICTIONARY_BRAINSTORM.md` / `Docs/02_Plan/<ID>_DICTIONARY_PLAN.md`, matching the
   existing docs there — Docs/README.md has the routing table. Ask first — don't assume the
   user wants four more markdown files.

5. **Then hand it to the user to test.** Print the `testBrief` items as a checklist and ask them to run through it.
   Do not commit anything and do not declare the dictionary done until they report back — the widget check in
   particular can only be done by a human looking at their desktop.

If a phase fails hard, the workflow result names the run id: resume with
`Workflow({ scriptPath: ".claude/workflows/add-dictionary.js", resumeFromRunId: "<id>", args: "<theme>" })`
rather than starting over — completed agents come back from cache.
