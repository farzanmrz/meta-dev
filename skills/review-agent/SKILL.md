---
name: review-agent
description: Read-only audit of an existing Claude Code subagent — never modifies it. Use when the user asks to review, check, or audit an agent, asks why an agent isn't getting picked or delegated to, wants its tool list checked, or wants a second opinion on an agent before shipping it. Not for applying fixes — route those to update-agent or improve-agent.
model: sonnet
---

# review-agent

Look, measure, report — never touch. Mirrors `meta-dev:review-skill`'s read-only contract at agent scope: every finding routes to the lifecycle operation that fixes it, and the agent under review is byte-identical on exit. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/agent.md` before auditing — the checks below cite those rules, they don't restate them.

## Step 1 — Scope

Pick with the user if not obvious from the ask:

- **Quick** (default): static analysis only.
- **Deep**: adds one live sample dispatch. Use when the complaint is behavioral ("it doesn't get delegated to", "it returns the wrong thing") rather than structural.

Completion criterion: scope chosen and stated before analysis starts.

## Step 2 — Static analysis (both depths)

1. Run `python3 ${CLAUDE_SKILL_DIR}/../skill-creation/tools/validate_agent.py <agent-path>` for frontmatter and body-skeleton validity.
2. Measure against `${CLAUDE_SKILL_DIR}/../../standards/agent.md`: the skeleton sections are present (role sentence, "When to invoke", responsibilities, process, output format, edge cases); `description` reads as delegation triggers, not a workflow summary (the same measured failure core.md names for skill descriptions applies here — an orchestrator routes on the trigger phrase, not on a paraphrase of what happens after); `model:` was a deliberate choice, not an unconsidered omission; `tools`/`disallowedTools` reflect least privilege for the process the body actually describes; and, if this agent ships inside a plugin, note the plugin-agent field limitations (`hooks`, `mcpServers`, `permissionMode` are ignored there per agent.md).
3. Spawn `meta-dev:reviewer` with artifact_kind: agent, the agent's file path, and the agent standards module for the scored dimension report.

Completion criterion: validator output and reviewer report both in hand, covering every skeleton section and frontmatter field.

## Step 3 — Seam check (only when paired with a skill)

When this agent is a fork target or a preload for one or more skills, check the seam from both sides — the same seam agent.md and skill.md both name:

- Every skill that lists this agent as a `context: fork` target has an actionable task the agent can execute — a reference-only skill forked this way returns nothing useful.
- Every skill this agent preloads via its own `skills:` field actually exists, loads, and is not `disable-model-invocation: true` (silently skipped otherwise, leaving the agent quietly under-informed).
- The agent's `tools` list can execute what the paired skill's process demands — a preloaded skill that tells the agent to run a script the tool list can't invoke is a finding here, not a mystery later.

Completion criterion: every skill pairing found for this agent has an explicit pass/fail on all three checks, or an explicit note that no pairing exists.

## Step 4 — Deep check (deep scope only)

Dispatch one sample task representative of the agent's stated purpose. Containment: synthesize the task so every input and output lives under a scratch directory (`~/.claude/skill-workspaces/review-<agent>/`), never a real repo path — a generation-archetype agent WILL write artifacts, so aim it somewhere disposable. Judge the returned final message against the standard's Return contract section — does it actually state what it was asked to state (fields, format, file paths), or is it a "be helpful" summary that would leave an orchestrator guessing. Read the transcript for divergence between the system-prompt's process and what the agent actually did.

Why one sample and not more: a structural mismatch (wrong tools, missing skeleton section) is cheaper and more reliably caught by Step 2's static checks than by hoping a single dispatch happens to exercise it — the dispatch exists to catch what only shows up at runtime, not to replace the static pass.

Completion criterion: one sample dispatch judged against the return contract, with the verdict tied to a specific contract clause it met or missed.

## Step 5 — Deliver the report

Combine everything into one report, ordered most-severe first:

```
## Agent review: <name>  (<quick|deep>)
**Verdict**: Pass | Needs Improvement | Needs Major Revision
**Scores**: <reviewer's dimensions>
**Seam findings**: <skill pairings checked, or "no pairing found">
**Findings**: CRITICAL / MAJOR / MINOR, each one line + evidence
**What's working**: <genuine positives>
**Routed fixes**:
1. <fix> → meta-dev:update-agent | meta-dev:improve-agent
```

Route behavior or contract changes to `update-agent`; route quality-only cleanups (bloat, wording, tool-list trimming, description rewrite) to `improve-agent`. An agent that looks abandoned or superseded routes to `retire-agent` instead of either. Completion criterion: report delivered, every finding carries a routed destination, and the agent file's mtime and content are unchanged from Step 2's baseline — any write outside a scratch workspace or transient dispatch fixture invalidates the review.
