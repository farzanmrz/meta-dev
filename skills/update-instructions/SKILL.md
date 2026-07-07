---
name: update-instructions
description: Change a project's instruction-file content — AGENTS.md, CLAUDE.md, and .claude/rules/ — and re-scope a rule when its area outgrows it. Use for "add/change X in AGENTS.md", "update a rule's skills or facts", "the stack table is out of date", "split the app rule". Not for quality-only cleanup with unchanged facts (improve-instructions), a fresh repo with no layout yet (setup-instructions), or a full re-derivation of the whole layout (revise-agents-md).
model: sonnet
---

# update-instructions

Change what a project's instruction files say, and — when an area outgrows its rule — re-scope where a fact lives. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/instruction-files.md` before editing; both are canon and are not restated here.

## Step 1 — Capture the contract

1. Read the constitution (`AGENTS.md`/`CLAUDE.md`) and every reference or rule file it points to.
2. Write down the **fact list**: the facts and guards that must survive this edit, as concrete statements ("stack table lists Postgres 16", "never commit `.env`").
3. Confirm this is genuinely a content change or rule re-scope, not a quality-only cleanup (hand to improve-instructions) or a from-scratch bootstrap (hand to setup-instructions).

Completion criterion: fact list written and the update/improve/setup boundary explicitly settled.

## Step 2 — Confirm the diff

State precisely what changes: added fact, changed fact, removed fact, or a rule re-scope firing. Confirm with the user once — skip only when the request already states the diff unambiguously ("add the new env var to AGENTS.md"). This is the only consultation point (core.md's autonomy split: update = confirm once); everything after runs without asking, except a re-scope's plan approval in Step 4.

Completion criterion: diff stated and confirmed (or confirmation explicitly waived).

## Step 3 — Edit minimally

Apply the diff and nothing else. Before writing a fact, locate its correct home and put it there once — `AGENTS.md` for anything always-on, the area's path-scoped rule for path-specific detail — never both; a fact repeated across files is the single-source-of-truth failure this step exists to prevent, and a fact the code already tells you (the promotion test) belongs in neither. Follow the `AGENTS.md` section playbook and the rule-file shape (`instruction-files.md`) for placement. Do not add enforcement prose for anything that must be guaranteed — that belongs in a hook, not markdown (core.md's enforcement doctrine); note the gap for the user instead of writing a rule you can't back.

Completion criterion: every fact in the diff lands at its correct home (`AGENTS.md` or one rule); nothing outside the diff changed.

## Step 4 — Re-scope (only when an area outgrows its rule)

Three triggers (`instruction-files.md`): `AGENTS.md` carrying path-specific detail that belongs in a rule; one rule covering two distinct concerns or grown unwieldy; a path-area that keeps getting missed because no rule scopes it. If none fired, skip to Step 5.

1. Classify: **misplaced altitude** (surface detail that belongs in a rule, or a fact in a rule that should be always-on in `AGENTS.md`), **overloaded rule** (split into two, each with narrower `paths:`), or **missing rule** (a new `.claude/rules/<area>.md` with its `paths:`, skills, and info). A genuinely deep, self-contained subtree may instead warrant a nested `CLAUDE.md`.
2. Propose the change — which content moves to which rule (or up to `AGENTS.md`), and the `paths:` each rule ends with.
3. Get plan approval before moving anything. A re-scope is a restructure of where facts live, not a content edit; core.md reserves restructures for user sign-off even though update-instructions otherwise only confirms-once. Skip only if the request already specified the exact move.
4. Move the content — no pointer line is needed (rules auto-load by path, so `AGENTS.md` gains nothing when detail leaves it). Verify each rule's `paths:` fires the way `instruction-files.md`'s loading-mechanics table says (a `paths:` rule loads only on a matching read — never put a must-always-hold guard in a rule; that is a hook's job).

Completion criterion: content lives at its right home, each rule's `paths:` is valid and scopes to its area, and no rule promises a load behavior the mechanics table contradicts.

## Step 5 — Verify

1. Check sizes: constitution line count, any reference or rule file size, against the ladder thresholds.
2. Check for dangling pointers: every `@import`, reference link, and `paths:` rule resolves to a file that exists.
3. Check for duplicated facts: grep the fact list's key terms across constitution + references + rules; each should hit exactly one file.
4. Confirm the touched files are md-format-clean (heading levels, fenced-code language tags per `core.md`'s Formatting section) — the `md-format` hook nudges on write but does not block, so re-check by eye.
5. Report the fact list, the diff applied, and (if triggered) the re-scope performed, to the user.

Completion criterion: sizes checked, zero dangling pointers, zero duplicated facts, all touched files md-format-clean, report delivered.

## Finish

This skill edits repo instruction files directly and creates no workspace of its own, so it has nothing to archive or clean. (Sibling improve-instructions does snapshot into `~/.claude/skill-workspaces/` — that cleanup belongs to its own final step, not to this skill.)
