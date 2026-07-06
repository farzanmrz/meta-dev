---
name: update-instructions
description: Change a project's instruction-file content — AGENTS.md, CLAUDE.md, .claude/references/, .claude/rules/ — and execute growth-ladder graduations. Use for "add/change X in AGENTS.md", "update the code map", "graduate app/ guidance", "the code map or stack table is out of date". Not for quality-only cleanup with unchanged facts (improve-instructions) or a fresh repo with no constitution yet (setup-instructions).
model: sonnet
---

# update-instructions

Change what a project's instruction files say, and — when the growth ladder demands it — regrade where a fact lives. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/instruction-files.md` before editing; both are canon and are not restated here.

## Step 1 — Capture the contract

1. Read the constitution (`AGENTS.md`/`CLAUDE.md`) and every reference or rule file it points to.
2. Write down the **fact list**: the facts and guards that must survive this edit, as concrete statements ("stack table lists Postgres 16", "never commit `.env`").
3. Confirm this is genuinely a content change or graduation, not a quality-only cleanup (hand to improve-instructions) or a from-scratch bootstrap (hand to setup-instructions).

Completion criterion: fact list written and the update/improve/setup boundary explicitly settled.

## Step 2 — Confirm the diff

State precisely what changes: added fact, changed fact, removed fact, or a graduation trigger firing. Confirm with the user once — skip only when the request already states the diff unambiguously ("add the new env var to AGENTS.md"). This is the only consultation point (core.md's autonomy split: update = confirm once); everything after runs without asking, except a graduation's plan approval in Step 4.

Completion criterion: diff stated and confirmed (or confirmation explicitly waived).

## Step 3 — Edit minimally

Apply the diff and nothing else. Before writing a fact, locate its correct ladder rung and put it there once — the constitution for anything always-on, a reference for pull-only depth — never both; a fact repeated across rungs is the single-source-of-truth failure this step exists to prevent. Follow the AGENTS.md section playbook (`instruction-files.md`) for placement and ordering. Do not add enforcement prose for anything that must be guaranteed — that belongs in a hook, not markdown (core.md's enforcement doctrine); note the gap for the user instead of writing a rule you can't back.

Completion criterion: every fact in the diff lands at its correct rung; nothing outside the diff changed.

## Step 4 — Graduation (only when triggered)

Check the three triggers from `instruction-files.md`: constitution nearing 200 lines, one area's section swelling, or repeated misses of pull-only guidance. If none fired, skip to Step 5.

1. Classify the swelling content: **folder-shaped** (bound to one directory subtree) or **glob-shaped** (a file-type convention spanning folders).
2. Propose the destination — folder-shaped → nested `CLAUDE.md` in that folder; glob-shaped → `.claude/rules/<name>.md` with a `paths:` filter — and draft what the constitution's replacement pointer line reads.
3. Get plan approval before moving anything. A graduation is a restructure of where facts live, not a content edit; core.md reserves restructures for user sign-off even though update-instructions otherwise only confirms-once. Skip only if the request already specified the exact destination and pointer text.
4. Move the content, leave exactly one pointer line in the constitution, and verify the moved file loads the way `instruction-files.md`'s loading-mechanics table says it will (e.g., a `paths:` rule only fires on a matching read — don't promise always-on behavior it can't deliver).

Completion criterion: graduated content lives at the approved destination, the constitution holds one pointer line per graduated area, and no rung promises a load behavior the mechanics table contradicts.

## Step 5 — Verify

1. Check sizes: constitution line count, any reference or rule file size, against the ladder thresholds.
2. Check for dangling pointers: every `@import`, reference link, and `paths:` rule resolves to a file that exists.
3. Check for duplicated facts: grep the fact list's key terms across constitution + references + rules; each should hit exactly one file.
4. Confirm the touched files are md-format-clean (heading levels, fenced-code language tags per `core.md`'s Formatting section) — the `md-format` hook nudges on write but does not block, so re-check by eye.
5. Report the fact list, the diff applied, and (if triggered) the graduation performed, to the user.

Completion criterion: sizes checked, zero dangling pointers, zero duplicated facts, all touched files md-format-clean, report delivered.

## Finish

This skill edits repo instruction files directly and creates no workspace of its own, so it has nothing to archive or clean. (Sibling improve-instructions does snapshot into `~/.claude/skill-workspaces/` — that cleanup belongs to its own final step, not to this skill.)
