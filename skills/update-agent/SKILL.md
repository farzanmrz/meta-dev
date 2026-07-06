---
name: update-agent
description: Change an existing agent's behavior — its prompt, tools, model, or preloaded skills — for new requirements. Use for "update/extend agent X", "give the agent tool Y", "change what the reviewer agent does". Not for quality-only cleanup with unchanged behavior (improve-agent), read-only auditing (review-agent), or deleting/deprecating an agent (retire-agent).
model: sonnet
---

# update-agent

Change what an agent does without silently breaking what it already did. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/agent.md` before editing.

## Step 1 — Capture the current contract

Read the agent file fully: frontmatter and system-prompt body. Write down the **regression list** — the concrete behaviors that must survive the edit, drawn from two sources: delegation triggers (the scenarios in `description` and the body's "When to invoke" that must still route here) and return-contract behaviors (what the agent's final message must still contain, per the standard's Return contract section).

Completion criterion: regression list written, covering both triggers and return-contract fields.

## Step 2 — Confirm the diff

State precisely what changes: prompt behavior, tools, model, or preloaded `skills:`. Confirm with the user once — the diff, not the whole agent, is the scope. Skip re-asking when the request already states the diff unambiguously ("add tool Y", "also handle X"); this is the only consultation point per `${CLAUDE_SKILL_DIR}/../../standards/core.md`'s autonomy split — everything after this step runs hands-free.

Completion criterion: diff stated and confirmed (or confirmation explicitly waived because the request already stated it).

## Step 3 — Snapshot

`mkdir -p ~/.claude/skill-workspaces/<agent-name> && cp <agent-path> ~/.claude/skill-workspaces/<agent-name>/skill-snapshot` — never inside `.claude/skills/` or `.claude/agents/`; the snapshot is the rollback point and the regression baseline.

Completion criterion: snapshot exists at the workspace path, outside any guarded skills/agents tree.

## Step 4 — Edit minimally

Apply the diff and nothing else. If `model:` is entirely omitted, fix it per core.md's Model assignment (a deliberate `inherit` is valid and stays as-is — only an unconsidered omission gets changed). After any tool or prompt edit, re-check tool least-privilege (drop tools the new prompt no longer exercises, add only what the new behavior requires) and re-check that every `skills:` preload still resolves and isn't `disable-model-invocation` (silently skipped otherwise). Resist drive-by rewording of untouched prompt sections — wording that survived earlier use is load-bearing until proven otherwise.

Completion criterion: every requirement in the diff is implemented; tool list and preloads are re-justified; nothing outside the diff changed.

## Step 5 — Validate and review

Run `python3 ${CLAUDE_SKILL_DIR}/../skill-creation/tools/validate_agent.py <agent-path>` and spawn `meta-dev:reviewer` against the edited agent. Apply behavior-preserving fixes (frontmatter shape, missing "When to invoke" pointer, tool-list formatting, description length) autonomously in the same pass; anything that would change behavior goes back to the user instead of being auto-applied, since this operation's autonomy is confirm-once, not hands-free.

Completion criterion: validator passes clean; reviewer's critical/major findings are resolved or explicitly deferred to the user.

## Step 6 — Smoke regression

Dispatch the agent twice: once on a prompt exercising an OLD behavior from the regression list, once on a prompt exercising the NEW behavior. Both dispatches must pass — an old-behavior failure means the edit regressed something the diff didn't intend to touch; a new-behavior failure means the edit didn't actually land. This is the check that catches an update quietly turning into a rewrite. When it's genuinely unclear whether the edited agent is equivalent-or-better on a shared behavior (not clearly a pass/fail), run `meta-dev:comparator` blind against the snapshot rather than guessing from a single read.

Completion criterion: the old-behavior dispatch and the new-behavior dispatch both pass; any doubtful equivalence is settled by a blind comparison, not asserted.

## Step 7 — Finish

1. Append the change and its evidence (validator output, reviewer findings, the two smoke-dispatch results) to the workspace log.
2. Archive: copy the snapshot and log to `~/.claude/skill-archive/<agent-name>-<date>/` (git-tracked agents already have their history as the archive, but the workspace copy still gets archived for the evidence trail).
3. `rm -rf` the workspace.
4. If the edited agent ships inside a plugin, tell the user to run `/reload-plugins` — plugin-shipped agents don't pick up edits until reloaded.

Completion criterion: workspace archived and removed; reload note given when the agent is plugin-shipped.
