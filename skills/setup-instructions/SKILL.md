---
name: setup-instructions
description: Bootstrap a project's instruction files from scratch. Use when the user asks to set up CLAUDE.md or AGENTS.md, bootstrap instruction files or project memory, or initialize the constitution for a repo that has none. Not for editing an existing constitution's content (update-instructions) or pruning/tightening one already in place (improve-instructions).
model: sonnet
---

# setup-instructions

Bootstrap a repo's instruction files from nothing: gather facts, draft rung 1 of the growth ladder, get plan approval before touching disk, then install and verify. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/instruction-files.md` before drafting — the shape, loading mechanics, and section playbook live there and only there.

## Step 1 — Inspect the repo

1. Read manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, etc.) for stack and pinned versions.
2. Extract runnable commands from package/task-runner scripts, not from memory or convention.
3. Find environment keys from `.env.example`/config templates and note where setup lives.
4. List top-level directories to identify the project's mapped areas (one area = one future reference file).

Record a source for every fact (which file it came from) — a fact without a source is a guess, and guesses in a constitution rot silently since nothing forces a re-check. Completion criterion: facts gathered for stack, commands, environment, and code map, each with a cited source.

## Step 2 — Draft rung 1

Follow the AGENTS.md section playbook exactly (order fixed, sections optional) to draft:

- `AGENTS.md` — the canon, populated from Step 1's facts only, sections included only where the project actually has the content.
- `CLAUDE.md` — exactly `@AGENTS.md`, nothing else; this is what makes the constitution load natively at session start on both tools.
- `.claude/references/<area>.md` skeletons, one per mapped area, each opening with that area's skill pointer (if one exists) before any structure or facts.

Stop at rung 1: no `.claude/rules/`, no nested `CLAUDE.md`. A fresh repo has no graduation signal yet (constitution near 200 lines, a swelling area, repeated misses of pull-only guidance) — rungs 2+ exist to answer a problem this repo does not yet have. Completion criterion: draft constitution and reference skeletons exist in the workspace, rung 1 only.

## Step 3 — Plan approval (mandatory, no exceptions)

Present the full draft — constitution text and the reference-file list with what each will contain — to the user before writing anything to the target repo. Setup is the one instruction-file operation that creates many files at once from a blank slate; the user has not yet seen a single line of it, unlike update (editing something they already reviewed once) or improve (quality-only, no new content). Wait for explicit approval or edits before Step 4.

Completion criterion: user has seen the complete draft and approved it (or approved it with named changes, which are applied before proceeding).

## Step 4 — Install

Write the approved `AGENTS.md`, `CLAUDE.md`, and each `.claude/references/<area>.md` to the repo root. Create parent directories as needed. Do not add rung-2 structure even if it was discussed as a "later" item in Step 3 — approval covered the draft shown, not speculative growth.

Completion criterion: every approved file exists on disk at its intended path, unchanged from what was approved.

## Step 5 — Verify

1. Confirm `AGENTS.md` (and any nested constitution — none expected at setup) is ≤200 lines.
2. Confirm every code-map pointer line in `AGENTS.md` resolves to a reference file that actually exists.
3. Confirm markdown is clean per core.md's formatting rules (structure matches real hierarchy, backticks on paths/identifiers, no bare prose walls).
4. Report to the user: what was created (file list), and the specific growth-ladder triggers to watch for (constitution approaching 200 lines, one area's reference swelling, repeated misses of pull-only guidance) so they know when to invoke update-instructions later (its Graduation step executes the move under plan approval).

Completion criterion: all three checks pass and the report — including named future triggers — has been delivered to the user.
