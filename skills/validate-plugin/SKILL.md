---
name: validate-plugin
description: Read-only validation and audit of a Claude Code plugin or marketplace — never modifies what it inspects. Use when the user asks to validate a plugin or marketplace, wonders why a plugin won't load, wants the manifest checked, or asks if a plugin is ready to publish.
model: sonnet
---

# validate-plugin

Look, measure, report — never touch. This mirrors `meta-dev:review-skill`'s read-only contract at plugin scope: findings route to the operation that fixes them (skill-creation operations for bundled skills, manual manifest edits for structure issues), and nothing under the plugin path is modified. If the user asks for fixes after the report, hand off — do not apply them here.

## Step 1 — Run the official validator

Run `claude plugin validate <path>` against the target; add `--strict` when the user says this is for CI or a publish gate. Interpret output per plugin-dir vs marketplace-dir mode as defined in `${CLAUDE_SKILL_DIR}/../../standards/plugin.md` — a plugin-dir path checks manifest schema/types, component frontmatter, and `hooks.json` syntax; a marketplace-dir path additionally checks for duplicate names, path traversal, and version mismatches.

Completion criterion: validator exit status and full output captured verbatim for the report.

## Step 2 — Structure audit beyond the validator

The validator catches syntax; it does not catch every structural trap described in `${CLAUDE_SKILL_DIR}/../../standards/plugin.md`. Check each explicitly, since these fail silently rather than erroring:

- Components live at plugin root (`skills/`, `agents/`, `hooks/`), not nested inside `.claude-plugin/` — only the manifest belongs there.
- No new `commands/` directory — it is legacy; flag any recently-added command as a routing miss, not a pass.
- A root-level `SKILL.md` with no `name:` in frontmatter falls back to the install-dir basename as its invocation name — flag this even though it loads, since the name becomes unstable across reinstalls.
- Distinguish severity: wrong-typed manifest fields are hard load errors (the whole plugin fails); unrecognized top-level fields are warnings only — do not conflate the two in the report.
- Any `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}` usage resolves correctly, and no path uses `../` — the cache copy on install breaks any escape outside the plugin directory.
- `hooks.json`, if present, is syntactically valid — a malformed one prevents the entire plugin from loading, not just the hook.

Completion criterion: each check above has a pass/fail verdict, not just "looked fine."

## Step 3 — Standards audit of bundled components

For each bundled skill and agent, sample rather than exhaustively re-review — spawn `meta-dev:reviewer` per sampled component with its path and the standards path so the audit reuses the same scored six-dimension diagnosis the skill lifecycle uses elsewhere, rather than inventing a second rubric here. Sample size scales with plugin size: review every component in a plugin with ≤3, else pick a representative subset and say so in the report.

Completion criterion: each sampled component has a reviewer verdict attached.

## Step 4 — Cost audit

If the plugin is installed, run `claude plugin details <name>` and report the always-on vs on-invoke token load split per `${CLAUDE_SKILL_DIR}/../../standards/plugin.md`. If the plugin is not installed, first try loading it from disk for the inspection (`claude plugin details <name> --plugin-dir <path>`); skip only when that also fails, and say so explicitly rather than omitting it silently — cost is a publish-readiness criterion, not an optional extra.

Completion criterion: token-load figures captured, or an explicit note that the plugin isn't installed to inspect.

## Step 5 — Deliver the report

Combine all steps into one report, most-severe finding first:

```
## Plugin validation: <name>  (<plugin-dir|marketplace-dir>)
**Verdict**: Ready to publish | Needs fixes | Fails to load
**Validator output**: <summary + exit status>
**Structure findings**: CRITICAL / MAJOR / MINOR, each one line + evidence
**Component reviews**: <sampled skills/agents, reviewer verdicts>
**Cost**: <always-on vs on-invoke tokens, or "not installed">
**Routed fixes**:
1. <fix> → <meta-dev:update-skill | meta-dev:improve-skill | manual manifest edit | ...>
```

A finding that traces to a bundled skill's own quality (not plugin structure) routes to the matching skill-lifecycle operation, exactly as `review-skill` routes its findings — this skill only originates plugin-level findings. Completion criterion: report delivered; nothing under the validated plugin's path was created, edited, or deleted.
