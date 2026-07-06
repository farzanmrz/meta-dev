---
name: improve-agent
description: Raise an existing subagent's quality against a measurable criterion WITHOUT changing its delegation behavior or return contract. Use when the user asks to debloat or tighten an agent, says an agent's prompt is bloated, wants its description or triggering fixed, or asks to audit its tool list. Behavior changes (what the agent does or returns) belong to update-agent.
model: sonnet
---

# improve-agent

Same delegation behavior, better agent — by one named metric at a time. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/agent.md` first; both are cited, never restated, below.

## Autonomy contract

Run hands-free end to end: pick the metric, apply it, verify, then report. Never consult mid-pass — per core.md's autonomy split, improve never consults because behavior is preserved by contract, leaving nothing for the user to decide. Users weigh in only on operations that change behavior (update-agent) or shape (restructure).

## Step 1 — Pick the metric

Choose exactly one from the user's complaint and a quick scan of the agent file:

- **Prompt bloat** — the system-prompt body is long, stale, or repetitive.
- **Description/triggering** — the agent is delegated to on the wrong tasks, or not delegated to at all.
- **Tool least-privilege** — the `tools` allowlist grants more than the agent's actual process uses.

A single pass targets one metric; an agent needing several gets sequential passes, bloat first (no point trimming tools a bloat pass is about to reshuffle). If the actual ask changes what the agent *does* or *returns*, stop and route to update-agent — this skill's contract only holds while the return contract and delegation behavior are frozen.

Completion criterion: one metric named, and a one-line reason it's the highest-value pass right now.

## Step 2 — Snapshot

Run `mkdir -p ~/.claude/skill-workspaces/<agent-name>/ && cp <agent-path> ~/.claude/skill-workspaces/<agent-name>/skill-snapshot` — the baseline for rollback and blind comparison. Never place the workspace inside `.claude/skills/` or `.claude/agents/`; it is scratch, not a shipped artifact.

Completion criterion: `skill-snapshot` exists and is byte-identical to the pre-edit agent file.

## Step 3 — Apply the metric

Test every line against `${CLAUDE_SKILL_DIR}/../../standards/core.md`'s Per-line quality section (no-op, relevance, duplication, leading words) — apply those tests as written, don't improvise variants. Hold the agent.md skeleton (role sentence, When to invoke, responsibilities, process, output format, edge cases) fixed; a bloat or formatting pass reorders prose within it, never removes a section outright.

- **Prompt bloat**: delete lines that fail a test whole, never word-trim a line into a weaker no-op. Keep the role sentence, the "When to invoke" bullets, and the return-contract statement verbatim in meaning — only their wording may tighten.
- **Description/triggering**: rewrite `description` to delegation triggers only — third person, scenario phrases the orchestrator or user's request would match, explicit NOT-use carve-outs. Drop any sentence that summarizes the agent's workflow instead of naming when to call it; per core.md, a workflow summary in the description is a measured failure mode (agents route on it and skip the body).
- **Tool least-privilege**: list the concrete steps the agent's process actually performs, then trim `tools` (or set `disallowedTools`) to exactly what those steps invoke. Removing an unused tool is safe by definition — the agent's documented process never called it — so this branch does not require behavioral re-verification beyond Step 4's dispatch smoke test.

Completion criterion: every changed line traces to a named test or to the metric's specific procedure above; the skeleton section order is unchanged.

## Step 4 — Verify

1. Run `python3 ${CLAUDE_SKILL_DIR}/../skill-creation/tools/validate_agent.py <agent-path>` and dispatch `meta-dev:reviewer` (read-only audit) against the new file. Fix anything either flags before proceeding.
2. Smoke-test: dispatch one representative task to the new agent and, separately, to the snapshot. Save both transcripts, then hand both — unlabeled — to `meta-dev:comparator` for a blind A/B verdict.
3. The new version must win or tie. A loss means the "improvement" changed behavior the contract promised to hold; roll back (`cp` the snapshot over the working file) and either narrow the edit or re-route to update-agent.

Completion criterion: validator clean, reviewer's flagged issues resolved, and comparator's verdict is win-or-tie for the new version — recorded before Step 5.

## Step 5 — Report and finish

Report the delta: what changed, which test or procedure justified each cut, and the comparator verdict. If the agent ships inside a plugin, note that the user must run `/reload-plugins` (or restart) to pick up the change — plugin agents don't hot-reload. Then run cleanup: copy the snapshot and the evidence log to `~/.claude/skill-archive/<agent-name>-<date>/`, and `rm -rf` the workspace so nothing lingers under `~/.claude/skill-workspaces/`.

Completion criterion: delta reported, archive written, workspace directory no longer exists.
