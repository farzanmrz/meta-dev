# Hook module — rules unique to Claude Code hooks

Adds to `core.md`. A hook = an event registration (settings.json, plugin `hooks/hooks.json`, or skill/agent frontmatter `hooks:`) + optionally a script it runs.

## Choosing the event

~30 events exist; the working set: `PreToolUse` (gate/modify tool calls), `PostToolUse` (react/nudge), `PostToolUseFailure`, `UserPromptSubmit` (add context/validate), `SessionStart`/`SessionEnd`, `Stop`/`SubagentStop` (completion gates), `PreCompact`/`PostCompact`, `Notification`, `PermissionRequest`/`PermissionDenied`, `TaskCreated`/`TaskCompleted`, `SubagentStart`, `FileChanged` (needs `watchPaths`), `ConfigChange`, `InstructionsLoaded`, `WorktreeCreate`/`WorktreeRemove`, `Setup`, `PostToolBatch`. Pick the narrowest event that sees what you need; check the current docs page for the full list — this catalog grows.

## Choosing the type

- `command` — deterministic checks, scripts, validators (the default; exec-form `command`+`args` avoids shell quoting).
- `prompt` — LLM judgment over the event payload; policy calls hard to script.
- `agent` — an agentic verifier WITH tool access, for multi-step checks.
- `http` / `mcp_tool` — external services / reuse of MCP tool logic.
- Support varies by event (SessionStart/Setup: command+mcp_tool only; prompt/agent only on the decision-bearing events). Verify per event before authoring.

## Config shape

Identical inner shape everywhere: `{"hooks": {"<Event>": [{"matcher": "...", "hooks": [{"type": "command", "command": "..."}]}]}}`. Plugin file: `hooks/hooks.json` at plugin root, script paths via `"${CLAUDE_PLUGIN_ROOT}"/...` (quoted); persistent state in `${CLAUDE_PLUGIN_DATA}`, never in PLUGIN_ROOT (replaced on update).

Matchers: `*`/empty = all; plain names with `|` or `,` separators = exact; anything else = unanchored JS regex (anchor with `^...$`; `Edit.*` also matches `NotebookEdit`).

## Decision contracts (current, not legacy)

- `PreToolUse` → `hookSpecificOutput.permissionDecision`: `allow` | `deny` | `ask` | `defer`, with `permissionDecisionReason`; optional `updatedInput`. Top-level `decision`/`approve`/`block` is deprecated. Multiple hooks: deny > defer > ask > allow; permission RULES still apply over any hook allow.
- `Stop`/`SubagentStop` → top-level `{"decision": "block", "reason": "..."}`; 8-block loop cap.
- Any event → `systemMessage` (shown to Claude) and `continue:false` to halt.

## Exit codes — the classic trap

**Only exit 2 blocks** (stderr fed back to Claude). Exit 0 = success (stdout parsed as JSON; reaches context only for UserPromptSubmit/UserPromptExpansion/SessionStart). Exit 1 and everything else = non-blocking error. Exceptions: `WorktreeCreate` (any non-zero aborts), `StopFailure` (output ignored). Never mix exit-2 with JSON output — JSON is ignored on exit 2.

## Script robustness

- `set -uo pipefail`; quote every variable; parse stdin with `jq`; fail open (`exit 0`) on missing dependencies — never brick tool use over a parsing library.
- Validate inputs (path traversal, injection) before acting on them; set explicit `timeout` (command default 60s, prompt 30s).
- Matching hooks run in PARALLEL — no ordering, no shared state between them; design each independent.
- Stdin gives `session_id`, `cwd`, `hook_event_name`, `permission_mode` + event fields (`tool_name`, `tool_input`, `tool_use_id`…). Never trust more than you validate.

## Reload semantics

settings.json hooks hot-apply in-session (file-watcher delay). Plugin hooks need `/reload-plugins` or restart — say so whenever shipping a plugin-hook change. Debug: `/hooks` (registration), `claude --debug hooks` (execution trace), `claude plugin validate` (hooks.json syntax — a malformed one prevents the whole plugin from loading).
