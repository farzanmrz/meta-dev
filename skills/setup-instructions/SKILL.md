---
name: setup-instructions
description: Bootstrap a project's instruction files from scratch — a surface AGENTS.md plus path-scoped .claude/rules/ derived from the installed skills and the actual code. Use when the user asks to set up CLAUDE.md/AGENTS.md, bootstrap instruction files or project memory, or initialize the layout for a repo that has none. Not for editing an existing layout's content (update-instructions), tightening one already in place (improve-instructions), or re-deriving the whole layout of a repo that already has one (revise-agents-md).
model: sonnet
---

# setup-instructions

Bootstrap a repo's Claude-native instruction layout from nothing: a surface `AGENTS.md` plus path-scoped `.claude/rules/`, derived — like `revise-agents-md` — as a projection of the installed skills and the actual code. Gather facts, derive the skill×path mapping, draft, get plan approval before touching disk, then install and verify. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/instruction-files.md` before drafting — the shape, the skill×path derivation, the promotion test, and the section playbook live there and only there.

## Step 1 — Inspect the repo and the skill set

1. Read manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, etc.) for stack and pinned versions.
2. Extract runnable commands from package/task-runner scripts, not from memory or convention.
3. Find environment keys from `.env.example`/config templates.
4. List top-level directories to identify the project's **path-areas** — one coherent tech surface (routing, auth, the agent…) is one candidate rule.
5. **Enumerate the installed skills** — project-local (`.claude/skills/`), every installed plugin, and global — the capability set the rules will route to.

Record a source for every fact (which file it came from); a fact without a source is a guess, and guesses rot silently. Completion criterion: facts gathered for stack, commands, environment, and path-areas — each with a source — plus the skill inventory.

## Step 2 — Derive the layout

Following `instruction-files.md`, draft:

- `AGENTS.md` — the **surface**: identity, stack, commands, environment, a thin code map (names areas, does not point at rules), and always-on working rules. No per-area detail; no commentary about how rules or skills load (the harness owns that); no skill whose description the harness already matches.
- `CLAUDE.md` — exactly `@AGENTS.md`.
- `.claude/rules/<area>.md` — one per path-area: a `paths:` filter, the area's skills (derive the skill×path mapping per `instruction-files.md` — **apply** now, **surface** with a trigger condition, **drop** the inapplicable), and the non-code-recoverable info keepers (promotion test, bullet-first). A fresh repo's rules may be thin; that is fine.

For a repo that already has real code across several areas, dispatch one `meta-dev:grounder` per area in parallel (as `revise-agents-md` does) so each area is grounded and drafted concurrently on a cheap model rather than read serially here; a near-empty fresh repo needs no fan-out.

No nested `CLAUDE.md` — a fresh repo has no deep, self-contained subtree that warrants its own scoped constitution yet. Completion criterion: draft `AGENTS.md` + `CLAUDE.md` + the rule set exist in the workspace.

## Step 3 — Plan approval (mandatory, no exceptions)

Present the full draft — the `AGENTS.md` text and each rule (its `paths:`, skills, and info) — to the user before writing anything to the target repo. Setup is the one instruction-file operation that creates many files at once from a blank slate. Wait for explicit approval or edits before Step 4.

Completion criterion: user has seen the complete draft and approved it (or approved with named changes, applied before proceeding).

## Step 4 — Install

Write the approved `AGENTS.md`, `CLAUDE.md`, and each `.claude/rules/<area>.md` to the repo. Create parent directories as needed. Do not add a nested `CLAUDE.md` even if discussed as a "later" item — approval covered the draft shown.

Completion criterion: every approved file exists on disk at its intended path, unchanged from what was approved.

## Step 5 — Verify

1. `CLAUDE.md` is exactly `@AGENTS.md`; `AGENTS.md` is surface-only (no per-area detail, no rules/skills-loading commentary).
2. Each rule's `paths:` is valid and scopes to where its area's tech actually lives; no fact is stated in two files.
3. Markdown is clean per `core.md`'s Formatting rules.
4. Report to the user: what was created (file list), and the **surfaced** future-trigger skills (the "wire this skill when X happens" list) so they know what to add as the project grows.

Completion criterion: all checks pass and the report — including the surfaced-skill triggers — has been delivered.
