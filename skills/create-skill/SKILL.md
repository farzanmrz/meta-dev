---
name: create-skill
description: Create a brand-new Agent Skill from scratch. Use when the user asks to make, build, or scaffold a new skill, wants to turn a workflow, conversation, or body of knowledge into a skill, or needs a capability no existing skill covers. Not for skills that already exist — route edits to update-skill, improve-skill, or restructure-skill via skill-creation.
model: sonnet
---

# create-skill

Create a new skill: prove it doesn't already exist, capture intent, draft to standard, review statically, then verify empirically in proportion to what the skill does. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/skill.md` before drafting — every formatting and quality rule lives in those two files and only there.

## Step 1 — Inventory (before anything else)

Duplicate skills are how confusion starts; check first, create second.

1. List existing skills: `ls ~/.claude/skills/`, project `.claude/skills/` (and nested ones), and the skills of enabled plugins (`~/.claude/plugins/cache/<marketplace>/<plugin>/*/skills/`).
2. Search their descriptions for the new skill's intended trigger words.
3. Verdict: **no overlap** → proceed. **Overlap** → stop and tell the user; the right operation is probably update-skill (extend the existing skill) or restructure-skill (merge/split), not creation.

Completion criterion: every location checked and an explicit overlap verdict stated.

## Step 2 — Capture intent

If the conversation already contains the workflow ("turn this into a skill"), extract answers from history first and have the user confirm. Otherwise ask:

1. What should the skill enable?
2. When should it trigger — what phrases, contexts, file types?
3. What is the expected output format?
4. Should test cases verify it? Objectively verifiable outputs (file transforms, data extraction, code generation, fixed workflows) benefit from test cases; subjective outputs (writing style, art) usually don't. Suggest a default; the user decides.

Also decide the invocation mode using `standards/skill.md`'s invocation-economics section: model-invoked (agent reaches it alone — write a pushy trigger description) or user-invoked (`disable-model-invocation: true`, human-facing one-liner, zero context load).

Interview further for edge cases, input/output examples, success criteria, and dependencies. Research via MCPs or parallel subagents when useful. Completion criterion: intent, triggers, output format, invocation mode, and test-case decision all confirmed by the user.

## Step 3 — Draft

1. Plan bundled resources from concrete examples: repeated or fragile code → `scripts/`; knowledge re-discovered each run → `references/`; files copied into output → `assets/`.
2. Write resources first, then SKILL.md — imperative voice, checkable completion criteria on steps, why-explanations instead of bare MUSTs, every budget and rule per the standards file. Declare `model:` deliberately per core.md's Model assignment (opus for judgment-heavy, sonnet default, `inherit` when the caller owns the model — e.g. subagent-driven skills; never fable unless the user asks). If the skill bundles or authors an agent, set that agent's `model:` the same way.
3. Revise the draft with fresh eyes before showing it.

Completion criterion: draft exists and self-complies with the standards on a line-by-line pass.

## Step 4 — Static review (free, always)

1. Run the validator from `${CLAUDE_SKILL_DIR}/../skill-creation/`: `python3 tools/validate_skill.py <skill-path>`.
2. Spawn `meta-dev:reviewer` with the skill path and the standards path.
3. Fix critical and major findings; re-review until the rating is Pass.

Completion criterion: validator passes AND reviewer rates Pass.

## Step 5 — Empirical verification (proportional)

Pick the tier from `${CLAUDE_SKILL_DIR}/../skill-creation/references/testing-ladder.md`:

- Skill has verifiable behavior → **full eval run** per `${CLAUDE_SKILL_DIR}/../skill-creation/references/eval-pipeline.md`, baseline = **no skill**. Write 2–3 realistic test prompts, confirm them with the user, then follow the pipeline end to end (runs → grading → benchmark → analyst → viewer → feedback).
- Subjective-output skill → skip assertions; run the prompts and put outputs in front of the user via the viewer.
- Discipline skill (rules an agent will want to break) → add tier-4 pressure scenarios.

Iterate on feedback: generalize rather than overfit, keep the prompt lean, bundle scripts the test runs kept rewriting. Repeat until the user is happy, feedback is empty, or progress stalls.

## Step 6 — Finish

1. Write a short provenance log to `~/.claude/skill-workspaces/<skill-name>/CREATION-LOG.md`: why the skill exists, decisions made, test evidence. (Never inside the skill folder.) Then run the workspace cleanup per eval-pipeline.md §9.
2. Offer description optimization → hand off to `meta-dev:improve-skill` (description branch).
3. If distributing, package from `${CLAUDE_SKILL_DIR}/../skill-creation/`: `python3 -m scripts.package_skill <skill-path>`.

Completion criterion: skill installed where the user wants it, provenance logged, optimization offered.
