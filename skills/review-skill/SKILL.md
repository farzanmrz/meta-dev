---
name: review-skill
description: Read-only audit of an existing Agent Skill — it never modifies the skill under review. Use when the user asks to review, check, grade, audit, or diagnose a skill, asks why a skill isn't triggering or is misbehaving, wants a quality report before deciding what to do, or wants a second opinion on a skill before shipping or sharing it.
model: sonnet
---

# review-skill

Look, measure, report — never touch. This operation exists so that *reading* a skill is never taxed with authoring machinery: it produces a diagnosis whose fixes are routed to update-skill, improve-skill, restructure-skill, or retire-skill, and it never modifies the skill under review — deep checks may write to a scratch workspace and transient eval fixtures, never to the skill itself. If the user asks for fixes to be applied, finish the review, then hand off to the routed operation.

## Step 1 — Scope

Two depths; pick with the user if not obvious from the ask:

- **Quick** (default): static analysis only — free, seconds.
- **Deep**: adds empirical checks — trigger evals and/or a live eval run. Use when the complaint is behavioral ("it doesn't trigger", "it produces the wrong thing").

## Step 2 — Static analysis (both depths)

1. Validate structure: from `${CLAUDE_SKILL_DIR}/../skill-creation/` run `python3 tools/validate_skill.py <skill-path>`.
2. Measure against `${CLAUDE_SKILL_DIR}/../../standards/core.md` + `${CLAUDE_SKILL_DIR}/../../standards/skill.md`: body line count vs budgets, description length and style, reference depth, dangling pointers, duplication.
3. Spawn `meta-dev:reviewer` with the skill path and standards path for the scored six-dimension report and failure-mode diagnosis.

Completion criterion: validator output and reviewer report in hand.

## Step 3 — Deep checks (deep scope only)

- **Triggering complaint** → first check the cheap causes: malformed frontmatter YAML (skill silently loads with empty metadata and stops auto-triggering), `disable-model-invocation: true`, a `skillOverrides` entry, or listing truncation/starvation (`/doctor` shows shortened and dropped descriptions). Then, if wording is the suspect, measure: write 6–10 realistic should/should-not-trigger queries to a scratch eval-set JSON, and from `${CLAUDE_SKILL_DIR}/../skill-creation/` run `python3 -m scripts.run_eval --eval-set <scratch.json> --skill-path <skill-path>`; report the trigger rates. (The script plants a transient file in the project's `.claude/commands/` during measurement — allowed under the scratch-writes exception.)
- **Behavior complaint** → run 1–2 representative prompts per `${CLAUDE_SKILL_DIR}/../skill-creation/references/eval-pipeline.md` (no baseline needed for diagnosis; grade with `meta-dev:grader`) and read the transcripts for where execution diverges from the skill's instructions.

## Step 4 — Deliver the report

Combine everything into one report, ordered most-severe first:

```
## Skill review: <name>  (<quick|deep>)
**Verdict**: Pass | Needs Improvement | Needs Major Revision
**Scores**: <reviewer's six dimensions>
**Failure modes**: <named, with evidence>
**Findings**: CRITICAL / MAJOR / MINOR, each one line + evidence
**What's working**: <genuine positives>
**Routed fixes**:
1. <fix> → meta-dev:<operation>-skill
```

Every finding routes to the operation that fixes it; a skill that looks abandoned or superseded routes to retire-skill. Completion criterion: report delivered; the skill under review untouched — any write outside the scratch workspace and transient fixtures invalidates the review.
