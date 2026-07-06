# Agent module — rules unique to Claude Code subagents

Adds to `core.md`. An agent = one markdown file (`agents/<name>.md` in a plugin, `.claude/agents/`, or `~/.claude/agents/`): frontmatter + a system-prompt body.

## Frontmatter

Only `name` and `description` are required; everything else is deliberate choice, not boilerplate.

- `name`: unique, lowercase-hyphens; hooks receive it as `agent_type`; filename need not match (but keep them equal for sanity).
- `description`: what triggers *delegation to* this agent — third person, trigger scenarios in prose, and point to a body "When to invoke" section. Cover proactive and reactive triggering; say when NOT to use it.
- `model`: per core's Model assignment; default `inherit`. Resolution order at dispatch: `CLAUDE_CODE_SUBAGENT_MODEL` env → per-invocation param → this field → main model. Values excluded by an `availableModels` allowlist silently fall back.
- `tools` (allowlist) / `disallowedTools` (denylist; wins when both set; accepts `mcp__server__*` patterns). Omit both → inherits every parent tool. Least privilege: read-only judges get `Read, Grep, Glob`. Do NOT list `Skill` to give skill knowledge — that's `skills:`.
- `skills`: preloads the FULL content of listed skills at startup (not just descriptions). Costs their full bodies every invocation — preload only what every run needs. Cannot preload `disable-model-invocation` skills (silently skipped, debug-log warning).
- `background`: `true` forces background (default behavior is background since v2.1.198); `isolation: worktree` gives an isolated git worktree branched from the default branch — use when parallel agents mutate files.
- Also valid: `permissionMode`, `maxTurns`, `mcpServers`, `hooks`, `memory` (user|project|local), `effort`, `color`, `initialPrompt`. **Plugin-shipped agents ignore `hooks`, `mcpServers`, `permissionMode`** (security) — needing those means the agent belongs in `.claude/agents/`, not a plugin.
- Nesting: subagents may spawn subagents to depth 5; deny `Agent` in tools to stop fan-out.

## System-prompt body

Second person, and structured — the skeleton that survives every model generation:

1. Role sentence ("You are the X: …")
2. `## When to invoke` — 2–4 prose scenario bullets (matches the description's pointer)
3. Core responsibilities (numbered)
4. Process (concrete steps)
5. Output format / return contract
6. Edge cases

Archetypes to start from: analysis (read-only, produces findings), generation (writes artifacts), validation (pass/fail with evidence), orchestration (dispatches others). Keep under ~10k chars.

## Return contract

A subagent's final message is its ENTIRE product — the parent sees only that summary, never the transcript. State explicitly what the agent must return (fields, format, file paths written). For machine consumption, specify exact JSON shapes and file destinations; "be helpful" returns are orchestration bugs.

## Dispatch doctrine (for skills/docs that spawn agents)

- Pass complete context in the dispatch prompt — the agent has none of the conversation.
- Background + parallel for independent work; foreground only when the result gates the next step.
- Model-by-task at dispatch: overrides the frontmatter default when this task's weight differs (a doc-agent asked for exhaustive research runs deeper than its lookup default).
- Never rely on execution order between parallel agents.

## Interplay with skills

Same seam rules as `skill.md` § Interplay: review agent+skill pairs together — preloads exist and are loadable, fork targets fit the skill's task, tool lists can execute what the prompt demands.
