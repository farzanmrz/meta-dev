---
name: improve-instructions
description: Raise the quality of a project's instruction files (CLAUDE.md, AGENTS.md, references) WITHOUT changing what they commit to. Use when the user asks to clean up, debloat, or tighten CLAUDE.md or AGENTS.md, audit instruction files, or says their constitution is bloated, messy, or hard to read. Fact or guard changes belong to update-instructions; first-time bootstrap belongs to setup-instructions.
model: sonnet
---

# improve-instructions

Same commitments, better file — by one named metric at a time. The contract that makes this safe: no fact or guard is added, removed in meaning, or weakened — only decluttered, deduplicated, and reordered — so verification is about *lossless equivalence*, not new content. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/instruction-files.md` first; together they define every test and shape rule used below.

## Autonomy contract

Improve runs hands-free, end to end. Never consult the user mid-pass — the contract already bounds the outcome, so there is nothing to decide until the result exists: pick the metric, apply it, verify no fact or guard was lost, then report the delta and every choice made as evidence. Users weigh in on operations that change what the file commits to (update-instructions) or its loading shape (a rule re-scope, which is a restructure — core.md's Autonomy split reserves plan approval for that, not for improve).

## Step 1 — Pick the metric

Determine which single criterion this pass targets, from the user's complaint and a quick read of the constitution and its references:

- **Bloat** — lines that restate the model's default, restate what the harness or the code already provides, duplicate another file, or no longer bear on the project (core.md's Per-line quality tests)
- **Format** — voice, heading depth, table-vs-list choice, backtick/fence discipline (core.md's Formatting section)
- **Playbook-conformance** — section order or placement wrong per `instruction-files.md`'s AGENTS.md section playbook and its content rules (facts vs references, one-fact-one-place)

One metric per pass. A file needing several gets sequential passes, run autonomously in order — bloat first, since trimming first means less material to reformat or reorder. If `AGENTS.md` is carrying path-specific detail, or a rule has grown to cover two concerns, that is a re-scope signal, not an improve target: hand it to update-instructions (its Re-scope step executes the move under plan approval) instead of compressing around the problem.

Completion criterion: exactly one metric named, with the one-line reason it was chosen over the others visible in the eventual report.

## Step 2 — Snapshot

`mkdir -p ~/.claude/skill-workspaces/<artifact-name> && cp -r <constitution-and-references> ~/.claude/skill-workspaces/<artifact-name>/skill-snapshot` — baseline for the lossless-diff in Step 4 and for rollback. `<artifact-name>` names the project or instruction-set being improved. Never place the workspace inside `.claude/skills/` or `.claude/`; it is scratch, not canon.

Completion criterion: snapshot directory exists under `~/.claude/skill-workspaces/<artifact-name>/skill-snapshot` and contains every file this pass will touch.

## Step 3 — Apply the metric's procedure

### Bloat branch

Work line by line applying core.md's Per-line quality tests (no-op, relevance, leading words, single source of truth) in that order — do not improvise substitute tests. A line that fails is deleted whole, never word-trimmed. A fact is never deleted for being bloat — only deduplicated down to its single surviving source when the same meaning appears twice; the constitution keeps the pointer, the reference (or hook, if it is a guard) keeps the statement.

### Format branch

Apply core.md's Formatting section mechanically: heading depth, bullets vs numbered lists, bold/italics discipline, backticks and fences, tables where fields repeat. No meaning changes — a fix that would change what a line commits to belongs to update-instructions instead.

### Playbook-conformance branch

Check `AGENTS.md`'s sections against `instruction-files.md`'s section playbook: fixed order, each section optional, content-rule violations (path-specific detail leaking into the surface instead of a rule; a skill or fact the harness/code already provides; a fact restated across files). Check each `.claude/rules/` file matches the rule-file shape — one area, a valid `paths:`, skills-then-info. Move misplaced content to where the playbook says it belongs; do not invent structure the playbook doesn't name.

Completion criterion (all branches): every touched line carries a keep/cut/move verdict traceable to a named test or playbook rule, and no fact or guard's meaning changed.

## Step 4 — Verify

Diff snapshot against result and confirm zero lost facts or guards: for every removed line, name the surviving source that still carries its meaning (a rule, a hook, or a consolidated line elsewhere) — a removed line with no named survivor is a regression, not bloat, and must be restored. Alongside the fact-loss check, report line/word counts before vs after per touched file, and confirm markdown is format-clean per core.md's Formatting section (spawn `meta-dev:reviewer` with artifact_kind: instruction-files, the touched file paths, and standards/instruction-files.md if the diff is non-trivial).

Completion criterion: a per-removed-line table (line → surviving source) exists with no blank survivors, size deltas are recorded, and the reviewer (or self-check, for a purely mechanical formatting pass) raised no formatting objection.

## Step 5 — Report and finish

Report the delta: metric chosen, before/after sizes, the fact-survival table, and any re-scope signal spotted in Step 1 for the user to act on separately. Then run the mandatory cleanup: archive the snapshot and this pass's log to `~/.claude/skill-archive/`, and `rm -rf` the workspace — leave nothing under `~/.claude/skill-workspaces/`.

Completion criterion: report delivered, archive contains snapshot + log, and the workspace directory no longer exists.
