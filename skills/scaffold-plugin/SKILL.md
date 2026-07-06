---
name: scaffold-plugin
description: Scaffold a new Claude Code plugin and wire its components. Use when the user asks to create or scaffold a plugin, package skills, agents, or hooks as a plugin, or make a workflow installable/shareable. Not for auditing an existing plugin — route that to validate-plugin.
model: sonnet
---

# scaffold-plugin

Scaffold a new plugin directory, wire its components, and hand off for validation. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/plugin.md` before drafting — directory layout, manifest fields, and distribution mechanics live there and only there.

## Step 1 — Intake

This is create-class work: per core.md's autonomy split, ask during intake only, then proceed hands-free.

1. Ask for the plugin name (kebab-case) and which component kinds it needs (skills, agents, hooks, MCP servers).
2. Ask the distribution intent: **skills-dir plugin** — a folder in `~/.claude/skills/` carrying a `.claude-plugin/plugin.json`, loading as `<name>@skills-dir` — for dev/personal use with no install step; or **standalone repo + marketplace** — for shareable installs across machines/users. The choice changes which later steps run (marketplace.json only applies to the second).

Completion criterion: name, component list, and distribution intent all confirmed by the user.

## Step 2 — Scaffold the manifest and layout

1. For skills-dir intent, scaffold with the official command instead of hand-authoring: `claude plugin init <name> --with <skills|agents|hooks...>` (writes to `~/.claude/skills/<name>/`), then adjust the generated manifest. Hand-author only for standalone-repo intent, where init's target directory is wrong: create `.claude-plugin/plugin.json` with at minimum `name`. Set `version` if the user wants updates pinned to explicit bumps (per plugin.md: omitting it under git distribution means every commit counts as a new version).
2. Create component directories at the plugin ROOT, never inside `.claude-plugin/` — `skills/`, `agents/`, `hooks/` as needed. Do not create a `commands/` directory; it is legacy and this skill authors skills only.
3. Do not rely on a root `CLAUDE.md` for context — plugin.md states it is not loaded; any knowledge the plugin needs must ship through skills, agents, or hooks content instead.

Completion criterion: `.claude-plugin/plugin.json` exists with valid `name`, and every requested component directory exists at plugin root with nothing but the manifest under `.claude-plugin/`.

## Step 3 — Wire components

1. For each skill: create `skills/<name>/SKILL.md` with correct frontmatter (name matches folder, description is triggers-only per core.md, model set deliberately).
2. For each agent: create `agents/<name>.md`, and check the plugin-agent field limits in plugin.md/agent conventions before assuming full parity with standalone agents.
3. For hooks: create `hooks/hooks.json`, referencing any bundled scripts via `${CLAUDE_PLUGIN_ROOT}` rather than a hardcoded path — a plugin cannot reach files outside its own directory, and hardcoding breaks the moment the plugin is installed to a different cache location.

Completion criterion: every component named in Step 1 exists in its correct root-level directory, and all intra-plugin paths use `${CLAUDE_PLUGIN_ROOT}`.

## Step 4 — Distribution setup (only if marketplace intent)

Skip this step entirely for skills-dir plugins — they load in place with no marketplace involved.

1. Create `.claude-plugin/marketplace.json` with `name`, `owner`, and `plugins: [{name, source: "."}]`.
2. Register and install for a local smoke test: `claude plugin marketplace add <path>` then `claude plugin install <plugin>@<marketplace>`.

Completion criterion: marketplace.json validates and the plugin installs successfully from it.

## Step 5 — Hand off and report

1. Dispatch `validate-plugin` against the scaffolded directory for the authoritative structural/manifest check — this skill builds the plugin, it does not certify it; a second, focused pass catches what drafting attention misses.
2. Report to the user: the plugin's install path, the exact reload/activation instruction (`/reload-plugins` for skills-dir, or the marketplace install command from Step 4), and any findings validate-plugin returned.

Completion criterion: validate-plugin has run against the final layout and the user has the install/reload instructions in hand.
