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

The grounding is **two-phase on purpose**: a single shared survey (the area-agnostic reads every rule depends on), then one `meta-dev:grounder` subagent per area *in parallel*. Splitting the shared survey per area would just duplicate it; grounding each area serially in this agent wastes wall-clock and burns the caller's (often pricier) model on read-heavy work. So the survey stays here, and the per-area reading fans out to cheap read-only workers.

## Autonomy contract

Runs end to end without consulting the user. The snapshot makes agent-context edits reversible and every change is reported afterward, so nothing needs a mid-run decision. It restructures `AGENTS.md` and `.claude/rules/` freely — that is the job — but never silently edits a user-owned note; those are surfaced in the report, never rewritten.

## Step 1 — Inventory the installed skills

Enumerate every skill actually available *now*, not from memory: project-local (`.claude/skills/`), every installed plugin (`~/.claude/plugins/`), and global (`~/.claude/skills/`). Record each skill's name + one-line purpose. This live menu is what the rules route to — deriving from memory is how a relevant skill (a Postgres reviewer, an OAuth-token skill) silently stays unwired.

Completion criterion: a skill inventory — name + purpose — spanning project, plugins, and global.

## Step 2 — Shared survey + identify path-areas (sequential, once)

This is the area-agnostic grounding every rule depends on, so do it ONCE, here — splitting it per area would only duplicate it. Read: the current `AGENTS.md` (confirm `CLAUDE.md` is exactly `@AGENTS.md`), every `.claude/rules/**` and user-owned note; the top-level directory tree; the manifest versions (`package.json`, etc.); git state; and the canonical rule-file shape from `instruction-files.md`. Classify each markdown file — **agent-context** · **user-owned notes** · **ephemeral/status** · **out-of-bounds** (vendored `.upstream` skills, `.claude/agents` & `.claude/skills` definitions, runtime files like an agent system prompt). From the tree, identify the project's **path-areas** (coherent tech surfaces) with candidate `paths:` globs, plus the **cross-cutting set** (no natural path → `AGENTS.md`).

Completion criterion: a shared-survey digest (inventory + file classification + versions + tree + retiring docs) and a list of path-areas with candidate paths.

## Step 3 — Fan out one grounder per area (parallel)

Dispatch `meta-dev:grounder` once per path-area, **all in a single message so they run concurrently** (batch ≤8; most projects are 3–6 areas — wide fanouts risk rate limits). Give each grounder, in its dispatch prompt: the Step-2 **shared-survey digest** (so it does not re-derive it), its **area + candidate paths**, the **skill inventory**, and the area's **existing reference/doc** to fold and drift-check. Each returns — read-only, on Sonnet — its area's **apply/surface/drop** skill map, the **distilled keepers**, and any **drift**. You do NOT re-read what a grounder covers; its return is the area's grounding.

Completion criterion: one grounder return per area, collected.

## Step 4 — Synthesize the layout (dedup + distill)

Assemble from the grounder returns:

- **`AGENTS.md`** (surface): identity, stack, commands, environment, a *thin* code map (names areas; no pointers — rules auto-load), cross-cutting skill routing, always-on working rules. **No** harness meta-commentary (never document that rules auto-load or that `references/` is gone), and **no** skill the harness already matches by description.
- **`.claude/rules/<area>.md`** per area: `paths:` frontmatter, the apply skills (+ surfaced future-trigger notes), the keepers.

Run two filters before writing a single line:

1. **Dedup** — each fact lives in exactly ONE file (the tightest-scoped one); any other file cross-references by name only, never restates it. Grep candidate facts across the draft; collapse repeats (the "auth-only, no tables"-in-three-places failure).
2. **Distill** — bullet-first (one line of mechanism + one line of consequence), and drop any line a 30-second code read reveals: stack versions (they're in the manifest), quoted config values, restated source comments, transcribed session-reasoning. A rule is the *complement* of the code, not a retelling of it.

Then **delete `.claude/references/`** (keepers folded up; keep it only if the project must serve a non-Claude agent like Codex — the documented exception, say so). Leave user-owned notes untouched; rewrite any `AGENTS.md` pointer that treats a note as input.

Completion criterion: a plan where every fact appears once, every line earns its place, and `references/` is slated for removal.

## Step 5 — Snapshot, apply, verify

1. `mkdir -p ~/.claude/skill-workspaces/<project>-revise/skill-snapshot` and `cp -r` every agent-context file into it (rollback + fact-survival baseline; never inside `.claude/`).
2. Apply the plan to agent-context files only. Never write to a user-owned note; never create tracked status files.
3. Verify: every `paths:` glob is valid and scopes to its area; zero dangling pointers; **zero duplicated facts** (grep key terms — each hits one file). For the standards audit, spawn `meta-dev:reviewer` — but **inline the drafted `AGENTS.md` + rules directly into its dispatch prompt**. A subagent starts with a fresh context and cannot see your reads, so handing it paths forces a full re-read of the whole file set; inline the content instead and tell it to audit *that* (standards-conformance + cross-file dedup), not to re-read the standards or re-ground the code you already grounded. (Reserve a full clean-room re-read only when you deliberately want an adversarial second derivation.)

Completion criterion: snapshot exists; reviewer raises no critical/major on the inlined draft; zero dangling/duplicate; user-owned notes byte-unchanged.

## Step 6 — Report and finish

One report: rules written (each with its `paths:`), `AGENTS.md` delta (before/after size), **surfaced skills** (skill → trigger — the "wire this when X" list), drift corrected, bloat removed, `references/` removed, and — separately — **promotion candidates from your notes** (`file:line` → fact → suggested rule). Then cleanup (eval-pipeline.md §9): archive the snapshot + log to `~/.claude/skill-archive/`, `rm -rf` the workspace.

Completion criterion: report delivered; workspace cleaned; the only files changed are agent-context ones.
