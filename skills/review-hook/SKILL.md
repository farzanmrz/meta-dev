---
name: review-hook
description: Read-only audit of Claude Code hook configuration and scripts — never modifies them. Use when the user asks to review or audit hooks, asks why a hook didn't fire or didn't block a tool call, or asks whether a hook is safe or correct. Not for authoring or fixing a hook.
model: sonnet
---

# review-hook

Inventory, audit, spot-check, report — never edit. This operation exists so diagnosing a hook is never taxed with authoring machinery: every fix it finds routes to create-hook, and the hook files it inspects are untouched on exit.

## Step 1 — Inventory every registration

List every place a hook could be registered:

1. `settings.json` at all scopes (user, project, local) and any `hooks:` block inside enabled plugins' `hooks/hooks.json`.
2. Skill and agent frontmatter `hooks:` fields for every loaded skill/agent.

Completion criterion: a flat list of hooks, each tagged with its source file and scope — nothing registered is left uninventoried.

## Step 2 — Static audit per hook

Check each hook against `${CLAUDE_SKILL_DIR}/../../standards/hook.md`:

1. **Event fit** — is the registered event the narrowest one that sees what the hook needs, per the working set in hook.md's "Choosing the event"? A hook on a broad event when a narrow one exists is a finding, not a style note — the broad event fires (and costs latency) on cases the hook doesn't care about.
2. **Matcher correctness** — flag unanchored regex that over-matches (e.g. `Edit.*` also matching `NotebookEdit`); flag matchers that look exact but aren't.
3. **Decision contract currency** — flag any `PreToolUse` hook still emitting the deprecated top-level `decision`/`approve`/`block` instead of `hookSpecificOutput.permissionDecision`. This is the single most common reason a hook silently no-ops after an SDK upgrade.
4. **Exit-code correctness** — flag any script that exits 1 (or any non-2 code) intending to block; only exit 2 blocks. This is the classic trap named in hook.md and the most likely answer to "why didn't the hook block."
5. **Script robustness** — quoting of every variable, `jq` for stdin parsing, fail-open (`exit 0`) on missing dependencies, explicit `timeout`.
6. **Portability** — `${CLAUDE_PLUGIN_ROOT}` quoted in every path reference; no persistent state written under `PLUGIN_ROOT` (it is replaced on update — state belongs in `${CLAUDE_PLUGIN_DATA}`).

Completion criterion: every inventoried hook has a per-dimension verdict (pass/flag) against all six checks above, each flag citing the specific hook.md rule it violates.

## Step 3 — Behavioral spot-check

For hooks whose static audit is inconclusive (e.g. matcher intent is ambiguous, or exit-code behavior needs confirming against a real payload), run the hook's script against crafted stdin fixtures in a scratch directory:

- Write fixture JSON matching the event's stdin shape (`session_id`, `cwd`, `hook_event_name`, `permission_mode`, plus event-specific fields like `tool_name`/`tool_input`) to a scratch file, then pipe it into the script and inspect exit code + stdout/stderr.
- Transient writes to the scratch dir are allowed; never write to, or invoke in a mode that could mutate, the hook's own registration or script files.

Completion criterion: every flagged-inconclusive hook has been exercised against at least one crafted fixture, with observed exit code and output recorded.

## Step 4 — Deliver the report

Report per hook, most-severe finding first:

```
## Hook review: <hook name / matcher>  (source: <file>, scope: <scope>)
**Verdict**: Pass | Needs Improvement | Needs Major Revision
**Findings**: CRITICAL / MAJOR / MINOR, each one line + evidence (fixture output where applicable)
**Routed fixes**:
1. <fix> → meta-dev:create-hook
```

Route every fix to create-hook for authoring the corrected version — this skill diagnoses, it does not patch. Completion criterion: report delivered covering every inventoried hook, and zero hook configuration or script files modified (verify with a diff/mtime check against the pre-audit inventory before finishing).
