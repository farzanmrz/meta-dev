---
name: retire-agent
description: Safely delete, deprecate, or archive an existing Claude Code subagent. Use when the user asks to remove, delete, retire, or uninstall an agent, says an agent is superseded or unused, or wants to clean up unused agents. Not for plugin-shipped agents living only in the plugin cache — this reports and stops for those.
model: sonnet
---

# retire-agent

Deletion is cheap; safe deletion means knowing nothing still points at the agent. This pipeline is a scan, a snapshot, and an `rm` — the two real risks are dangling references (a skill's fork target, a hook keyed to this `agent_type`) and regret (no way back). Mirrors `meta-dev:retire-skill`'s scan/archive/remove shape for the agent artifact type; see `${CLAUDE_SKILL_DIR}/../../standards/agent.md` and `${CLAUDE_SKILL_DIR}/../../standards/core.md` for the underlying rules this pipeline enforces. Per core's autonomy split, retire pauses only on unresolved blockers — do not stop to confirm the plan itself.

## Step 1 — Confirm target and kind

1. Confirm the exact agent file and the reason (superseded / unused / user says so).
2. Determine what kind of agent it is — the removal mechanics differ:
   - **Project or user agent** (a file you own under `.claude/agents/` or `~/.claude/agents/`) -> this pipeline.
   - **Plugin-shipped agent** (lives only in the plugin's cache) -> do NOT delete from the cache — an update resurrects it. Instead remove the agent from the plugin's own source, or disable the plugin. Report which applies and stop here.

Completion criterion: the agent's file path is known, its kind is classified, and either this pipeline proceeds or a plugin-kind report has already been given and the pipeline has stopped.

## Step 2 — Cross-reference scan

Grep before removing — an agent can be named from more places than a skill can, since skills fork into agents and hooks key off `agent_type`:

```bash
grep -rl "<agent-name>" ~/.claude/hooks/ ~/.claude/settings.json ~/.claude/settings.local.json \
  ~/.claude/CLAUDE.md ~/.claude/skills/ ~/.claude/agents/ ~/.claude/commands/ .claude/ \
  2>/dev/null | grep -v "agents/<agent-name>.md"
```

Check each hit against these categories, since a generic name grep will not distinguish them on its own (follow with field-targeted greps to separate real dependencies from prose: `agent: *<agent-name>` in skill frontmatter for fork targets, and the name inside hooks' matcher/agent_type strings):

- **Skills' `agent:` fork field** — a skill with `context: fork` naming this agent as its target loses its execution path if the agent disappears.
- **Dispatch mentions** — prose in other skills/docs that tells an agent to spawn this one by name.
- **Other agents** — an orchestration agent that dispatches to this one.
- **Hooks matching `agent_type`** — a hook that gates or reacts on this agent's `name` (hooks receive it as `agent_type`, per `${CLAUDE_SKILL_DIR}/../../standards/agent.md`).
- **Docs** — CLAUDE.md or README mentions.

Give every hit outside the agent's own file an explicit disposition: *edit it* (repoint or remove the reference first — respecting that hook/settings edits gate on their own rules), *ignore it* (historical mention, no behavioral dependency), or *blocker* (something active still depends on this agent).

Completion criterion: every hit has a recorded disposition; no unresolved blockers remain. An unresolved blocker is the one case where this pipeline pauses — report it and wait rather than forcing the deletion.

## Step 3 — Archive

Copy before deleting so the action is reversible:

```bash
mkdir -p ~/.claude/skill-archive && cp <agent-path> ~/.claude/skill-archive/<name>-$(date +%Y%m%d).md
```

If the agent file is git-tracked, note the last commit touching it as an alternative restore point instead of (or alongside) the copy.

Completion criterion: a restorable copy exists (archive copy or noted commit) and its location is recorded for the final report.

## Step 4 — Remove and verify

1. `rm <agent-path>`.
2. Verify the agent is gone from the @-mention list and from any "available agents" listing — live change detection should drop it within the session; if a stale entry persists, note that `/reload-plugins` (or an equivalent reload) may be needed.
3. If git-tracked, stage and commit the deletion when the user wants it recorded.

Completion criterion: the file no longer exists at its original path, and its absence has been confirmed in the agent listing (or a reload need has been flagged, not silently assumed away).

## Step 5 — Report

Give one short message covering: what was removed (path and name), where the archive lives, every cross-reference edited or flagged with its disposition, and anything the user should still do (e.g. reload plugins, or a hook message that still names the agent in its own text).

Completion criterion: the report names the removed path, the archive location, and the full disposition list — nothing left implicit.
