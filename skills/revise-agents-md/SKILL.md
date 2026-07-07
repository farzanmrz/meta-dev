---
name: revise-agents-md
description: >-
  User-invoked pass that re-derives a project's Claude-native instruction
  layout — a surface AGENTS.md plus path-scoped .claude/rules/ — as a projection
  of the installed skill set and the actual codebase. Enumerates every available
  skill, maps which applies to which path (wiring unwired-but-needed ones,
  dropping inapplicable ones), grounds every claim against the code, discloses
  only non-code-recoverable info per path, and drops the inert references/ layer.
  Read-only toward user-owned notes (roadmaps, scratchpads) — it reports
  promotion candidates, never rewrites them. Invoke as /meta-dev:revise-agents-md.
model: sonnet
disable-model-invocation: true
---

# revise-agents-md

A project's Claude-native instruction layout — surface `AGENTS.md` + path-scoped `.claude/rules/` — should be a **projection of two things: the installed skill set and the actual code**. This user-invoked pass recomputes that projection: it enumerates the skills available *now*, maps which one fires on which path (wiring skills that should apply but don't, dropping ones that no longer do), grounds every documented claim against the code, and discloses only what the code can't tell you — per path, exactly when Claude reaches it. Autonomous once run (snapshot + report), and it never edits a user-owned note. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/instruction-files.md` first — the shape, the skill×path derivation, the promotion test, and the user-vs-agent split are canon there.

## Autonomy contract

Runs end to end without consulting the user. The snapshot makes agent-context edits reversible and every change is reported afterward, so nothing needs a mid-run decision. It restructures `AGENTS.md` and `.claude/rules/` freely — that is the job — but never silently edits a user-owned note; those are surfaced in the report, never rewritten.

## Step 1 — Inventory the installed skills

Enumerate every skill actually available *now*, not from memory: project-local (`.claude/skills/`), every installed plugin (`~/.claude/plugins/`), and global (`~/.claude/skills/`). Record each skill's name and one-line purpose (and any declared `paths`/trigger). This live menu is what the rules route to — deriving rules from memory is exactly how a relevant skill (a Postgres reviewer, an OAuth-token skill) silently stays unwired.

Completion criterion: a skill inventory — name + purpose — spanning project, plugins, and global.

## Step 2 — Map the surface and identify path-areas

1. Read `AGENTS.md` (confirm `CLAUDE.md` is exactly `@AGENTS.md`), every `.claude/rules/**`, and any other markdown that is or could be agent-context.
2. Classify each file: **agent-context** · **user-owned notes** (provenance = human) · **ephemeral/status** · **out-of-bounds** (vendored `.upstream` skills, `.claude/agents` & `.claude/skills` definitions, runtime files like an agent system prompt — never treat as context).
3. From the code structure, identify the project's **path-areas** — its coherent tech surfaces (e.g. routing, auth, UI, the agent, plus a cross-cutting set with no natural path). Areas may overlap; that is expected.

Completion criterion: files classified; a list of path-areas each with candidate `paths:` globs.

## Step 3 — Derive the skill×path mapping (per area)

For each path-area, ground the code (Read/Grep/Glob; Bash for inspection only — never an edit) and, against the Step 1 inventory, produce three buckets:

- **apply** — skills whose technology is genuinely present, each with a `when`.
- **surface** — available-but-unwired skills that *should* apply, each with the **trigger condition** that activates them (a schema skill when the first table lands; an OAuth-token skill when a connector is built). This is a primary output — the point is to catch what a per-folder guess misses.
- **drop** — skills a naive setup might attach but that don't apply, with the reason.

Cross-cutting skills with no natural path (env vars, deploy, lint, a build-a-feature workflow) route to `AGENTS.md`, not a rule.

Completion criterion: a skill×path map — apply/surface/drop per area, plus the cross-cutting set.

## Step 4 — Ground-truth the info (promotion test)

For every existing agent-context claim, verify it against the code and tag **accuracy** (confirmed / drifted [record documented vs actual] / unverifiable) and **altitude** via the promotion test — "would reading the code tell a fresh session this, cheaply?" Yes → **bloat** (drop; the code is its source); No → **keeper** (a why/guard/gotcha/external constraint). The keepers become each area's progressive info. Read user-owned notes only to (a) collect promotion candidates to *report* and (b) catch any pointer that routes agents into them as input (the scratchpad-as-input defect).

Completion criterion: per area, the surviving progressive-info keepers + drift corrections; a separate report-only promotion list.

## Step 5 — Compute the target layout

Write the plan — every skill and fact placed in exactly one home:

- **`AGENTS.md`** (surface): identity, stack, commands, environment, a *thin* code map (names areas, does not point at rules — they auto-load), the cross-cutting skill routing, always-on working rules, and any genuinely-always-needed guard. Playbook order.
- **`.claude/rules/<area>.md`** (path-scoped): `paths:` frontmatter for the area; the apply skills (with `when`) plus surfaced future-trigger notes; the progressive-info keepers. One area per file, every skill/fact single-sourced.
- **Delete `.claude/references/`** — fold its keepers into the rules, drop the code-recoverable bloat. (Keep it only if the project must serve a non-Claude agent like Codex — the documented exception; say so.)
- **User-owned notes**: untouched; rewrite any `AGENTS.md` pointer that treats them as input to name them as the user's notes.

Completion criterion: a written plan; nothing lands in two places; `references/` slated for removal; promotions listed for the user.

## Step 6 — Snapshot, apply, verify

1. `mkdir -p ~/.claude/skill-workspaces/<project>-revise/skill-snapshot` and `cp -r` every agent-context file into it (rollback + fact-survival baseline; never inside `.claude/`).
2. Apply the plan to agent-context files only. Do not write to any user-owned note. Do not create tracked status files.
3. Verify: every surviving claim still resolves against the code; every `paths:` glob is valid and scopes to where the area's tech lives; zero dangling pointers; zero duplicated facts (grep key terms — each hits one file); spawn `meta-dev:reviewer` (`artifact_kind: instruction-files`) over the result; for every deleted line name why (bloat = code is its source, or the surviving single source); user-owned notes byte-unchanged.

Completion criterion: snapshot exists; reviewer raises no critical/major; zero dangling/duplicate; every deletion justified; user-owned notes intact.

## Step 7 — Report and finish

One report: rules written/updated (each with its `paths:`), `AGENTS.md` delta (before/after size), **surfaced skills** (skill → trigger condition — the "wire this when X" list), drift corrected, bloat removed, `references/` removed, and — separately — **promotion candidates from your notes** (`file:line` → fact → suggested rule). Then cleanup (eval-pipeline.md §9): archive the snapshot + log to `~/.claude/skill-archive/`, `rm -rf` the workspace.

Completion criterion: report delivered; workspace cleaned; the only files changed are agent-context ones.
