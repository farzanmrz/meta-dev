---
name: sync-docs
model: sonnet
disable-model-invocation: true
description: >-
  On-demand currency check: diffs meta-dev's standards and lifecycles against current official Claude Code docs and routes drift through the update lifecycles.
---

# sync-docs

meta-dev's anti-rot mechanism: the standards encode claims about Claude Code that the product keeps changing underneath. Nothing else in this plugin re-checks those claims against reality, so without this skill they silently age into fiction. Runs only on explicit `/meta-dev:sync-docs` invocation — never automatically, since a docs check mid-unrelated-task would be a surprise, not a service.

## Step 1 — Verify each module's claims against current docs

1. Read every standards module in `${CLAUDE_SKILL_DIR}/../../standards/` (`core.md` plus each per-artifact module) and extract its factual claims about Claude Code behavior — the things a docs change could falsify (event names, frontmatter fields, loading mechanics, CLI flags, file locations).
2. Group claims by domain: skills, subagents, hooks, plugins, memory/instruction files.
3. Dispatch the `claude-code-docs` agent in parallel, one dispatch per domain (a user-global agent at `~/.claude/agents/` with a docs MCP binding — deliberately not shipped inside meta-dev, since plugin agents cannot carry mcpServers; if it is missing, fall back to fetching code.claude.com/docs pages directly and say so in the report), each carrying that domain's extracted claims to verify. Require each claim come back tagged confirmed / changed / new-capability / deprecated, with the doc URL as evidence — an unsourced verdict isn't a verdict, it's a guess.

Completion criterion: every module's claims have a verdict and a source URL from a domain dispatch.

## Step 2 — Build the drift report

1. For each module, list what changed and which lifecycle skills (create/update/improve/restructure/retire-skill and their agent/hook/plugin counterparts) depend on the now-stale claim.
2. Read the register at `${CLAUDE_PLUGIN_DATA}/declined.md` (persistent across plugin updates); if it doesn't exist yet, seed it by copying the shipped register `${CLAUDE_SKILL_DIR}/../../docs/declined.md`. `~/.claude/skill-workspaces/` is scratch space, not a register; nothing durable is tracked there.
3. Drop any drift item that matches an already-declined entry, unless the doc evidence changed since the decline (re-surface those as new, citing the earlier decline).

Completion criterion: drift report lists only items not already declined, or explicitly re-surfaced with new evidence.

## Step 3 — Present and route

1. Present the drift report to the user before changing anything — this is a scheduled currency check, not a hands-free improve; the user decides what's worth acting on now.
2. For each item the user accepts, route by target:
   - Drift in a lifecycle skill's behavior or instructions → dispatch `meta-dev:update-skill` on that skill (it owns the diff-confirmation and edit; don't duplicate that consultation here).
   - Drift in a standards module itself → edit `standards/<module>.md` directly, with the user's approval on the specific wording (standards have no separate lifecycle skill of their own).
3. For each item the user declines, capture the reason in the same turn — it is the only chance before the report scrolls out of context.

Completion criterion: every accepted item has been routed to its update path or edited; every declined item has a captured reason.

## Step 4 — Record declines

Append each newly-declined item to `${CLAUDE_PLUGIN_DATA}/declined.md` as one entry: what was found, the doc URL, the reason declined, today's date. Skip items already present from Step 2.

Completion criterion: the register contains every decline from this run and no duplicates.

## Step 5 — Finish and report

1. If any routed update touched a skill workspace, run the mandatory cleanup per `${CLAUDE_SKILL_DIR}/../skill-creation/references/eval-pipeline.md` §9: archive snapshot + log to `~/.claude/skill-archive/`, then `rm -rf` the workspace.
2. Report three lists to the user: applied (with what changed), declined (with reasons), deferred (accepted but not yet actioned, with why).

Completion criterion: workspace cleanup done for every touched skill; the applied/declined/deferred report delivered.
