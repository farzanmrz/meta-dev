---
name: skill-creation
description: Entry point and router for ALL work on Agent Skills. Use whenever the user wants anything done to a skill — make, build, edit, extend, tighten, reorganize, audit, or remove one — especially when the operation is unclear, mixed, or spans several, or when the user invokes skill-creation by name.
model: sonnet
---

# skill-creation — the lifecycle router

Claude-config work is many different operations wearing few words. This router's only job: diagnose which artifact class (skill, agent, hook, plugin, instruction files) and which operation the user is in, then invoke that operation's skill via the Skill tool. It never does the work itself.

## Step 1 — Diagnose artifact + operation

Match the request against the signals. Multiple rows can match; collect all that do.

| Signal | Skill to invoke |
|---|---|
| New skill; no folder exists for it yet | `meta-dev:create-skill` |
| New requirement / behavior change to an existing skill | `meta-dev:update-skill` |
| Same skill behavior, better quality (shorter, tighter, better triggering, formatting) | `meta-dev:improve-skill` |
| Wrong shape — too big, overlapping skills, split/merge/move content | `meta-dev:restructure-skill` |
| "Look at / check / grade / why isn't it triggering" — no edits | `meta-dev:review-skill` |
| Remove / deprecate / archive a skill | `meta-dev:retire-skill` |
| New subagent needed | `meta-dev:create-agent` |
| Behavior/tools/model/preload change to an existing agent | `meta-dev:update-agent` |
| Agent quality pass — prompt bloat, description, least-privilege | `meta-dev:improve-agent` |
| Audit an agent / why isn't it delegated to — no edits | `meta-dev:review-agent` |
| Remove an agent | `meta-dev:retire-agent` |
| New hook / automate-or-block something on an event | `meta-dev:create-hook` |
| Audit hooks / why didn't a hook fire or block — no edits | `meta-dev:review-hook` |
| Bootstrap a repo's CLAUDE.md/AGENTS.md/references | `meta-dev:setup-instructions` |
| Change instruction-file content or graduate an area (growth ladder) | `meta-dev:update-instructions` |
| Audit instruction files / verify documented claims against the codebase / are the docs correct — no edits | `meta-dev:review-instructions` |
| Debloat/format instruction files, no fact changes | `meta-dev:improve-instructions` |
| Scaffold a new plugin / package components for install | `meta-dev:scaffold-plugin` |
| Validate a plugin or marketplace / why doesn't it load — no edits | `meta-dev:validate-plugin` |

(Docs currency is user-invoked only: `/meta-dev:sync-docs` — never routed automatically.)

Two diagnostic questions settle most ambiguity:
- **Does the intended behavior change?** Yes → update. No → improve.
- **Is the problem inside one artifact's content, or in how content is distributed across files?** Inside → update/improve. Distribution → restructure (skills) / graduation (instruction files).

Completion criterion: exactly one operation chosen, or an ordered list when several genuinely apply.

## Step 2 — Confirm only when genuinely ambiguous

If two operations remain plausible after the diagnostic questions, ask the user one short either/or question. Otherwise proceed without asking — the operation skills each re-verify scope as their first step, so a wrong guess is caught cheaply.

Completion criterion: either no question was needed, or the user's answer settled the operation.

## Step 3 — Invoke

Fire the chosen skill(s) via the Skill tool. When several operations apply, run them in this order and finish each before starting the next:

1. review (understand before touching)
2. create (stand up new capability before reshaping or removing old)
3. restructure (fix the shape before the content)
4. update (change behavior)
5. improve (polish what the behavior now is)
6. retire (remove what's left over)

Completion criterion: the operation skill has been invoked and taken over, or the user has been told why no operation applies.

## Autonomy split

How much each operation consults the user — the operations enforce this themselves; route accordingly:

- **improve-*** (skill/agent/instructions): hands-free end to end; never consults; reports evidence afterward.
- **update-*** : consults once, to confirm the requirements diff; everything after runs itself.
- **create-*** / **scaffold-plugin**: asks during intake only.
- **restructure-skill**, **setup-instructions**, and instruction-file **graduations**: pause for plan approval — shape and multi-file writes are user decisions.
- **retire-*** : pauses only on unresolved cross-reference blockers.
- **review-*** / **validate-plugin**: read-only; never modify anything.

## Shared resources (hosted in this folder, used by all operation skills)

- `${CLAUDE_SKILL_DIR}/../../standards/` — the canonical rules, modular: `core.md` (all Claude-config markdown + shared policies: model assignment, rigor ladder, autonomy split) plus per-artifact modules (`skill.md`, `agent.md`, `hook.md`, `plugin.md`, `instruction-files.md`). Single source of truth; no rule lives anywhere else.
- `references/eval-pipeline.md` — the run/grade/benchmark/review choreography for empirical verification.
- `references/testing-ladder.md` — the four proportional-rigor tiers and their procedures.
- `references/schemas.md` — exact JSON contracts (evals, grading, benchmark, comparison) the scripts and viewer expect.
- `scripts/` — vendored measurement harness (validate, trigger evals, description optimization, benchmark aggregation, packaging). Run as `python3 -m scripts.<name>` with this skill's directory as the working directory (the `scripts` package only resolves from there; plain `python` does not exist on this machine).
- `eval-viewer/generate_review.py` — the human review UI. Always use it; never hand-write review HTML.
- `assets/eval_review.html` — trigger-eval curation page for description optimization.

Registered judge agents (spawn via the Agent tool): `meta-dev:reviewer` (static audit), `meta-dev:grader`, `meta-dev:comparator` (blind A/B), `meta-dev:improvement-analyst`, `meta-dev:benchmark-analyst`.

## Model policy (cost control)

Every lifecycle skill pins `model: sonnet` — invoking one switches the turn to Sonnet, and eval-executor subagents inherit it. Judge agents pin their own models: comparator and improvement-analyst run on Opus (final verdicts and improvement planning, the two judgment-critical steps); reviewer, grader, and benchmark-analyst run on Sonnet. Never run skill work on the Fable tier — it exhausts usage limits for work Sonnet handles.
