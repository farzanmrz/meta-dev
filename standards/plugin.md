# Plugin module — rules unique to Claude Code plugins

Adds to `core.md`. A plugin = a directory whose components Claude Code registers: `.claude-plugin/plugin.json` (manifest — the ONLY thing inside `.claude-plugin/`) + component dirs at plugin ROOT (`skills/`, `agents/`, `hooks/`, `output-styles/`, `bin/`, `.mcp.json`, `.lsp.json`).

## Structure rules

- Skills: `skills/<name>/SKILL.md` (a lone root `SKILL.md` works for single-skill plugins — set frontmatter `name`, else the install-dir basename becomes the unstable invocation name). `commands/` is legacy — do not author new ones.
- A root `CLAUDE.md` in a plugin is NOT loaded — context ships via skills/agents/hooks only.
- A plugin cannot reference files outside its own directory (`../shared` never gets copied into the cache); intra-plugin paths via `${CLAUDE_PLUGIN_ROOT}`, persistent state via `${CLAUDE_PLUGIN_DATA}`.
- Namespacing: `<plugin>:<component>` everywhere; the marketplace entry name (not plugin.json's) wins when they differ.

## Manifest (plugin.json)

- Optional entirely; if present, `name` (kebab-case) is the only required field.
- Useful fields: `displayName`, `version` (setting it PINS updates to version bumps; omitted + git distribution = every commit is a new version), `description`, `author`, `keywords`, `dependencies` (transitively enabled; disable fails while dependents live), `defaultEnabled` (marketplace entry's value beats the plugin's), `userConfig` (enable-time prompts → `${user_config.KEY}`), `channels`.
- Component path overrides: `commands`/`agents`/`outputStyles` REPLACE the default scan; `skills` ADDS to it. Paths relative, start with `./`, never `..`.
- Unrecognized top-level fields are ignored (warnings in validate); WRONG-TYPED fields are hard load errors. `themes`/`monitors` belong under `experimental.*` (top-level already warns).

## Distribution — three mechanisms, pick deliberately

1. **Skills-dir plugin** (`~/.claude/skills/<name>/` with a manifest → `<name>@skills-dir`): dev/personal default — in place, no install, global at personal scope. Project scope adds trust gating, per-server MCP approval, and NO monitors. Scaffold: `claude plugin init <name>`.
2. **Marketplace install**: `.claude-plugin/marketplace.json` in a repo (name, owner, plugins[] with source types github/url/git-subdir/npm; `strict:false` makes the entry the whole definition — a plugin.json that also declares components then HARD-CONFLICTS). Users: `marketplace add` → `plugin install`. Copies into the versioned cache.
3. **Official/community submission**: validate first; community via the submission form; entries pin to a commit SHA.

## Validation

`claude plugin validate <path>` (add `--strict` in CI): plugin dir → manifest schema/types, component frontmatter parse, hooks.json syntax (malformed hooks.json prevents the ENTIRE plugin from loading); marketplace dir → marketplace.json schema, duplicate names, path traversal, per-entry plugin checks, version mismatch warnings. Also `claude plugin details <name>` for the token-cost inventory (always-on vs on-invoke) — audit before shipping; `/reload-plugins` after non-skill component changes.
