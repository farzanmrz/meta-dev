---
name: create-hook
description: Design and author a Claude Code hook for event automation or enforcement. Use when the user asks to add or create a hook, block an action automatically, run something on every edit or session start, or enforce a rule with a hook. Not for auditing or debugging an existing hook — that routes to review-hook.
model: sonnet
---

Design and author a new hook end to end: pick the event, choose the type and placement, write the config and script to the robustness bar, validate against fixtures, then register. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/hook.md` before drafting — the event catalog, decision contracts, exit-code semantics, and script-robustness rules live there and only there. This is create-only (intake, no hands-free autonomy per core.md); auditing an already-registered hook is `review-hook`'s job, not this one.

## Step 1 — Requirement to event

1. Ask what must happen and at what moment ("block X", "run on every edit", "enforce Y at session start") if not already stated in the conversation.
2. Map the moment to the narrowest event in `hook.md`'s catalog that actually sees the data needed (e.g. a tool-input check is `PreToolUse`, not `PostToolUse` — `PostToolUse` can only react, never block the call that already ran).
3. Verify the chosen event supports the intended type before committing (`hook.md`: SessionStart/Setup are command+mcp_tool only; prompt/agent only exist on decision-bearing events) — picking an unsupported combination wastes the whole draft.

Completion criterion: one named event chosen, with the type-support check for it stated explicitly.

## Step 2 — Choose type and placement

1. Default to `command` (deterministic, cheapest). Escalate to `prompt` only for policy judgment too fuzzy to script, `agent` only when the check needs multiple tool-using steps, `http`/`mcp_tool` only for an external service or existing MCP logic. A `command` does everything a heavier type does at lower latency and zero LLM cost, so justify any escalation.
2. Choose placement: `settings.json` for this-machine/this-project behavior, plugin `hooks/hooks.json` for distributable enforcement, skill/agent frontmatter `hooks:` when the rule only applies while that skill/agent is active.
3. Note the reload semantics for the chosen placement (`hook.md`) so the user isn't left waiting on a hook that silently isn't live yet.

Completion criterion: type and placement both chosen with a stated reason, reload semantics noted.

## Step 3 — Author

1. Write the config using the exact wrapper shape from `hook.md` (`hooks.<Event>[].matcher` + `.hooks[].type`/`.command`); anchor regex matchers (`^...$`) unless intentionally broad.
2. Write the script to every rule in `hook.md`'s script-robustness section: `set -uo pipefail`, parse stdin via `jq`, quote every variable, fail open (`exit 0`) on a missing dependency, set an explicit `timeout`, and use the correct decision contract for the event (`hookSpecificOutput.permissionDecision` for `PreToolUse`, top-level `decision:"block"` for `Stop`/`SubagentStop`) — these are the rules an agent is tempted to skip under "it's just a quick script" pressure, and skipping any one of them turns a hook into a flaky gate or an outage when a dependency is absent.
3. Get the exit-code contract right: only exit 2 blocks and feeds stderr back to Claude; exit 0 is success with stdout parsed as JSON; never emit JSON on an exit-2 path since it is ignored there.

Completion criterion: config and script both written, every robustness rule in `hook.md` addressed line by line (not just glanced at).

## Step 4 — Validate

1. Syntax-check the script: `bash -n <script>`.
2. Syntax-check the config: `jq . <config-file>`.
3. Build 2-3 stdin fixtures covering the real branches (an allow case, a deny/block case, and a nudge/warn case if the hook has one) and pipe each through the script, confirming the decision contract and exit code match what step 3 intended.

Completion criterion: `bash -n` and `jq` both clean, and every fixture's actual output matches its expected decision.

## Step 5 — Register

1. Place the config at the chosen location from step 2 and tell the user the exact reload requirement for it (`hook.md`: settings.json hot-applies with a file-watcher delay; plugin hooks need `/reload-plugins` or a restart).
2. Point the user to `claude --debug hooks` for a live execution trace and `/hooks` to confirm registration, so a silent misfire is diagnosable without re-opening this skill.

Completion criterion: hook registered at the intended location, reload requirement and debug commands both stated to the user.
