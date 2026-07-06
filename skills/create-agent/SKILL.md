---
name: create-agent
description: Create a brand-new Claude Code subagent (registered agent .md) from scratch. Use when the user asks to create, add, or write an agent or subagent, or needs a dedicated worker, reviewer, or judge agent for a task. Not for editing an existing agent — route to update-agent or improve-agent — and not for auditing one, which is review-agent.
model: sonnet
---

# create-agent

Build a new subagent: prove no overlap exists, capture the delegation contract, draft to standard, validate statically, then smoke-test the dispatch. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/agent.md` before drafting — every frontmatter and body rule lives there and only there. Per core's autonomy split, create asks during intake only; the remaining steps run hands-free.

## Step 1 — Inventory existing agents

An overlapping agent is wasted dispatch budget and a confusing @-mention list; check before adding.

1. List agents in `~/.claude/agents/`, project `.claude/agents/`, and every enabled plugin's `agents/` directory.
2. Search their descriptions and `## When to invoke` sections for the new agent's intended task and trigger scenarios.
3. State a verdict: **no overlap** → proceed. **Overlap** → stop and tell the user; the right operation is likely update-agent or improve-agent on the existing agent, not a new one.

Completion criterion: every location checked and an explicit overlap verdict stated.

## Step 2 — Intake

Ask the user (or extract from conversation history and confirm) whatever isn't already settled:

1. **Task and delegation triggers** — what work does this agent own, and what phrases or situations should cause the main session to dispatch it (proactively and reactively)?
2. **Tools** — least privilege: read-only judges get `Read, Grep, Glob` only; writers get what they write with; deny `Agent` unless fan-out is intended.
3. **Model** — per core.md's Model assignment: pin a tier for forced weight, or `inherit` when the caller should own it. If the task's depth varies per dispatch (e.g. doc research), keep the frontmatter default at `sonnet` and note that callers override per-dispatch — never freeze a depth-variable agent to `haiku`.
4. **Background/isolation needs** — does it need `isolation: worktree` (parallel agents mutating files)?
5. **Skills to preload** — listing a skill in `skills:` loads its full body every invocation, not just its description; preload only what every run needs. Warn the user that `disable-model-invocation` skills cannot be preloaded this way (silently skipped).
6. **Memory scope** — `user`, `project`, or `local`.
7. **Target location** — project (`.claude/agents/`), user (`~/.claude/agents/`), or plugin (`agents/` inside a plugin). Warn: a plugin-shipped agent ignores its own `hooks`, `mcpServers`, and `permissionMode` fields (security) — an agent that needs those belongs in `.claude/agents/`, not a plugin.

Completion criterion: all seven points settled and confirmed by the user.

## Step 3 — Draft

Write the agent file per `agent.md`'s frontmatter list and the five-part body skeleton (role sentence, `## When to invoke`, responsibilities, process, return contract, edge cases). State the return contract explicitly and concretely — exact fields, format, file paths — because the agent's final message is its entire product; the parent never sees its transcript. Pick the closest archetype (analysis, generation, validation, orchestration) as the starting skeleton rather than writing from a blank page.

Completion criterion: draft exists, uses the correct target-location frontmatter subset, and self-complies with `agent.md` on a line-by-line pass.

## Step 4 — Seam check when paired with a skill

If this agent is a fork target for a skill, or a skill will preload it (or it will preload a skill), run the Interplay seam checks from `${CLAUDE_SKILL_DIR}/../../standards/agent.md`: the fork skill has an actionable task this agent's tools can execute, any preloaded skill isn't `disable-model-invocation`, and the tool list covers what the paired skill's process demands. Skipping this is how a fork target silently fails on first real dispatch.

Completion criterion: seam checked in both directions, or explicitly marked not-applicable when the agent has no skill pairing.

## Step 5 — Validate

1. Run `python3 ${CLAUDE_SKILL_DIR}/../skill-creation/tools/validate_agent.py <file>`.
2. Spawn `meta-dev:reviewer` with the agent path and the agent standards module.
3. Fix critical and major findings; re-review until the rating is Pass.

Completion criterion: validator passes AND reviewer rates Pass.

## Step 6 — Smoke-test

Dispatch the new agent once on a realistic sample task and check the returned message actually honors the return contract drafted in Step 3 — right fields, right format, no silent "be helpful" prose substituting for the specified shape. A contract that looks right on paper but returns free-form text on first dispatch is a bug caught cheaply now instead of expensively at the next orchestration layer.

Completion criterion: one real dispatch completed and its output checked against the contract, pass or documented fail.

## Step 7 — Report

Give one short report: the agent's path, its delegation triggers, tools granted, and model choice with rationale. If installed into a plugin, note that `/reload-plugins` may be needed before it appears in the @-mention list.

Completion criterion: report covers path, triggers, tools, model rationale, and the reload note when plugin-targeted.
