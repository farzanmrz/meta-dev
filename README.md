# meta-dev

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg) ![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-000000.svg)

**One authority for every Claude-config artifact.** meta-dev gives skills, agents, hooks, plugins, and project instruction files (`CLAUDE.md`/`AGENTS.md`) a single modular standard, a right-sized lifecycle for each, and enforcement that runs itself — so you stop re-litigating "what goes where, in what format, at what quality" on every project.

It is opinionated on purpose: **loaded text informs, only hooks prevent**; **each rule lives in exactly one place**; **verification scales to the change**. Everything else follows from those.

## Install

```bash
claude plugin marketplace add farzanmrz/meta-dev
claude plugin install meta-dev@farzan-dev
```

Then start a session (or `/reload-plugins`). One entry point routes everything:

```
/meta-dev:skill-creation      # "I want to do <anything> to a skill / agent / hook / plugin / instruction file"
```

You rarely type it — sharp descriptions auto-route to the right operation, and a bundled guard nudges you onto the lifecycle when you edit an artifact directly.

## Skills

The lifecycle operations, each right-sized to how often that artifact actually changes.

**Router**
- **[skill-creation](skills/skill-creation/SKILL.md)** — the entry point; diagnoses which artifact and which operation, then dispatches the matching skill.

**Skill lifecycle**
- **[create-skill](skills/create-skill/SKILL.md)** — build a new Agent Skill from scratch: inventory for overlap → capture intent → draft to standard → static review → proportional empirical verification.
- **[update-skill](skills/update-skill/SKILL.md)** — change an existing skill's behavior for a new requirement without regressing what it already did.
- **[improve-skill](skills/improve-skill/SKILL.md)** — raise quality with zero behavior change (debloat, formatting, description/triggering); runs hands-free.
- **[restructure-skill](skills/restructure-skill/SKILL.md)** — split, merge, or move content between `SKILL.md`, references, and scripts when the shape is wrong.
- **[review-skill](skills/review-skill/SKILL.md)** — read-only scored audit against the standards; routes each fix to the operation that applies it.
- **[retire-skill](skills/retire-skill/SKILL.md)** — safely delete or deprecate a skill: cross-reference scan → archive → remove.

**Agent lifecycle**
- **[create-agent](skills/create-agent/SKILL.md)** — author a Claude Code subagent: least-privilege tools, model-by-task, the battle-tested system-prompt skeleton, and the skill↔agent seam checks.
- **[update-agent](skills/update-agent/SKILL.md)** — change an agent's behavior, tools, model, or preloaded skills without regression.
- **[improve-agent](skills/improve-agent/SKILL.md)** — quality pass on an agent (prompt bloat, description, tool least-privilege); hands-free.
- **[review-agent](skills/review-agent/SKILL.md)** — read-only audit of an agent, including why it isn't being delegated to.
- **[retire-agent](skills/retire-agent/SKILL.md)** — safely remove an agent, scanning for fork targets and hook `agent_type` bindings first.

**Hook lifecycle**
- **[create-hook](skills/create-hook/SKILL.md)** — design and author a hook: narrowest event, right type, correct decision contract, robust script.
- **[review-hook](skills/review-hook/SKILL.md)** — read-only audit of hook config and scripts (why one didn't fire, or isn't safe).

**Plugin lifecycle**
- **[scaffold-plugin](skills/scaffold-plugin/SKILL.md)** — scaffold a plugin, wire its components, and set up skills-dir or marketplace distribution.
- **[validate-plugin](skills/validate-plugin/SKILL.md)** — read-only validation of a plugin or marketplace, wrapping `claude plugin validate` plus a standards audit.

**Instruction-file lifecycle**
- **[setup-instructions](skills/setup-instructions/SKILL.md)** — bootstrap a repo's `AGENTS.md`/`CLAUDE.md`/references at rung 1 of the growth ladder.
- **[update-instructions](skills/update-instructions/SKILL.md)** — change instruction-file content and execute growth-ladder graduations under approval.
- **[improve-instructions](skills/improve-instructions/SKILL.md)** — declutter and reformat instruction files without changing what they commit to; hands-free.

**Currency**
- **[sync-docs](skills/sync-docs/SKILL.md)** — on-demand only (`/meta-dev:sync-docs`): diff every standard against current official Claude Code docs and route the drift. This is what keeps meta-dev from aging into fiction.

## Agents

Shared judges the lifecycles dispatch — read-mostly, single-purpose.

- **[reviewer](agents/reviewer.md)** — read-only scored audit of a skill, agent, or instruction-file artifact against the standards, with routed fixes.
- **[grader](agents/grader.md)** — grades one eval run's assertions against the transcript and outputs, with cited evidence.
- **[comparator](agents/comparator.md)** — blind A/B judge of two outputs without knowing which produced which.
- **[improvement-analyst](agents/improvement-analyst.md)** — unblinds a comparison, explains why the winner won, and proposes prioritized fixes.
- **[benchmark-analyst](agents/benchmark-analyst.md)** — read-only cross-run pattern finder over benchmark data (non-discriminating assertions, flaky evals, cost tradeoffs).

## How it works

- **[standards/](standards/)** — the law, modular: [`core.md`](standards/core.md) governs every `.md` artifact (formatting, per-line quality, model policy, rigor ladder, autonomy split, enforcement doctrine); per-artifact modules ([skill](standards/skill.md), [agent](standards/agent.md), [hook](standards/hook.md), [plugin](standards/plugin.md), [instruction-files](standards/instruction-files.md)) add only what's unique. Every skill and agent cites these, so a creator and a reviewer can never disagree.
- **[hooks/](hooks/)** — enforcement. A two-tier **guard** hard-denies create/delete/large edits of skills and agents (routing them through the lifecycle) while letting a one-line edit through with a nudge, and hard-gates hook-config changes; a **md-format** hook nudges (never blocks) on any `.md` write and warns when a constitution outgrows the ~200-line ladder threshold.
- **[skills/skill-creation/](skills/skill-creation/)** — the shared harness: a vendored eval pipeline (parallel with-skill-vs-baseline runs, grading, benchmarking, blind comparison, an HTML review viewer) plus `tools/` validators for skills and agents.

## Licensing

meta-dev's own code and content are **MIT** (see [LICENSE](LICENSE)). The eval harness under `skills/skill-creation/` (`scripts/`, `eval-viewer/`, `assets/`, `references/schemas.md`) is vendored **byte-identical** from [anthropics/skills](https://github.com/anthropics/skills) under **Apache-2.0**, with its `LICENSE.txt` retained; provenance and the re-sync procedure are in [docs/vendoring.md](docs/vendoring.md).

## Developing

meta-dev develops itself — editing an artifact routes through its own lifecycle. Dev loop when installed from a local marketplace:

```bash
# edit the repo, then:
claude plugin marketplace update farzan-dev
claude plugin update meta-dev
/reload-plugins            # hook/agent changes don't hot-reload
```
