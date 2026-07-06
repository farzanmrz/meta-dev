---
name: retire-skill
description: Safely delete, deprecate, or archive an existing Agent Skill. Use when the user asks to remove, delete, retire, uninstall, or archive a skill, when a skill is superseded, obsolete, or abandoned, or when cleaning up unused skills.
model: sonnet
---

# retire-skill

Deletion is cheap; *safe* deletion means knowing nothing still points at the thing. This whole pipeline is a scan, a snapshot, and an `rm` — seconds, not a project. It exists because the two real risks are dangling references (a hook or skill that still names the deleted skill) and regret (no way back).

## Step 1 — Confirm target and kind

1. Confirm the exact skill folder and the reason (superseded / obsolete / unused / user says so).
2. Determine what kind of skill it is — the removal mechanics differ:
   - **Personal or project skill** (a folder you own under `~/.claude/skills/` or `.claude/skills/`) → this pipeline.
   - **Plugin-provided skill** → do NOT delete from the plugin cache (updates resurrect it). Disable instead: the whole plugin via `claude plugin disable <plugin>` / the enabledPlugins setting, or hide a bundled skill via `skillOverrides`. Report which and stop here.
   - **Symlinked skill** (e.g. into `~/.agents/skills/`) → removing the symlink unregisters it from Claude Code; the target survives. Say so and confirm which side to remove.

## Step 2 — Cross-reference scan

Search for the skill's name before removing it:

```bash
grep -rl "<skill-name>" ~/.claude/hooks/ ~/.claude/settings.json ~/.claude/settings.local.json \
  ~/.claude/CLAUDE.md ~/.claude/skills/ ~/.claude/agents/ ~/.claude/commands/ .claude/ \
  2>/dev/null | grep -v "skills/<skill-name>/"
```

For every hit, record a disposition: *edit it* (reference must be removed/repointed — do that first, respecting that hook/settings edits gate on their own rules), *ignore it* (historical mention), or *blocker* (something active depends on the skill — stop and tell the user).

Completion criterion: every hit outside the skill's own folder has an explicit disposition; no unresolved blockers.

## Step 3 — Archive

- Git-tracked skill → a committed state is already the archive; note the last commit touching it.
- Otherwise → `mkdir -p ~/.claude/skill-archive && cp -r <skill-path> ~/.claude/skill-archive/<name>-$(date +%Y%m%d)/`.

Completion criterion: a restorable copy exists and its location is recorded.

## Step 4 — Remove and verify

1. `rm -rf <skill-path>` (or `rm` the symlink).
2. Verify it's gone from the skill listing — live change detection removes it within the session.
3. If git-tracked, stage and commit the deletion when the user wants it recorded.

## Step 5 — Report

One short message: what was removed, where the archive lives, every cross-reference edited or flagged, and anything the user should do next (e.g. a hook still mentioning the skill by name in a deny message).
