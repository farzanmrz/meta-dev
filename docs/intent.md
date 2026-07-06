# meta-dev — Confirmed Intent (skills domain, phase 1)

*Confirmed by Farzan on 2026-07-04 after research across all installed skill-authoring sources and an interview. This document is the contract for what gets built; specs and implementation consume it.*

## Outcome

One `meta-dev` plugin that owns the **skill lifecycle** with six operation skills — `create-skill`, `update-skill`, `improve-skill`, `restructure-skill`, `review-skill`, `retire-skill` — replacing the monolithic skill-creator that today gets blanket-applied to every operation.

## Invocation model

- **Automatic by default.** Sharp trigger descriptions so Claude picks the right operation skill on its own, plus a bundled guard (`hooks/hooks.json` + `hooks/skill-guard.sh`, shipped inside this plugin) that denies any create/edit/delete of a skill under `.claude/skills/` until a `meta-dev:*` lifecycle skill has run this session. The deny message classifies the operation (create/edit/delete) and routes to `meta-dev:skill-creation`. Enabling the plugin arms the guard; disabling it removes the guard — enforcement is a property of the plugin, not of global settings. The user never tracks or types anything. (Replaced the old `~/.claude/hooks/skill-guard.sh` + `settings.json` blocks that forced skill-creator, on 2026-07-04.)
- **One named entry point.** The router skill `skill-creation` (`/meta-dev:skill-creation`) is manually invocable and routes to the right operation. It is the ONLY skill whose name begins with `skill-`; every other skill ends with `-skill` so slash-menu autocomplete on `skill-` shows exactly one entry.
- **Pipelines run themselves.** Review, grading, comparison, and benchmarking happen in background subagents/workflows once an operation skill is invoked — no manual orchestration.

## Model policy (cost control)

- All seven lifecycle skills pin `model: sonnet` (turn-scoped override on invocation; eval subagents inherit it).
- Judge agents: reviewer, grader, benchmark-analyst on Sonnet; comparator and improvement-analyst on Opus (the two judgment-critical steps).
- The description-optimization loop (`run_loop`) defaults to `claude-sonnet-5`.
- Fable is never used for skill work. Rationale: usage limits.

## Placement

The plugin lives at `~/.claude/skills/meta-dev/` — a "skills-directory plugin" (folder with `.claude-plugin/plugin.json` inside a skills dir), auto-loaded globally in every session as `meta-dev@skills-dir`, no marketplace or install step. SKILL.md edits hot-reload; `agents/` changes need `/reload-plugins`.

## Rigor policy: proportional

- Behavioral changes (steps, rules, triggers) require evidence: micro-test or eval run with baseline.
- Cosmetic/structural changes require static review only.
- This deliberately rejects superpowers' Iron Law ("no edit without a failing test first").
- Full rigor ladder defined in `skills/skill-creation/references/standards.md`.

## What is extracted from where

1. **Measurement** ← skill-creator's scripts, eval-viewer, and JSON schemas — vendored **verbatim, day one** (Apache-2.0; two CDN dependencies — SheetJS, Google Fonts — are documented as accepted offline limitations in docs/vendoring.md to preserve byte-identity with upstream).
2. **Judgment** ← five registered plugin agents: `grader`, `comparator`, `improvement-analyst`, `benchmark-analyst` (from skill-creator's agents/, analyzer split in two), `reviewer` (from plugin-dev's skill-reviewer, with numeric scoring added).
3. **Rules** ← ONE canonical standards file (plugin-dev's numbers + official/spec budgets, written in writing-great-skills vocabulary) cited by every skill and agent — creator and reviewer can never disagree.
4. **Process** ← superpowers' tiered testing ladder (static → micro-test → eval → pressure), Match-the-Form-to-the-Failure doctrine, rationalization engineering, persuasion-principles reference (vendored), CREATION-LOG provenance pattern.
5. **Awareness** ← inventory stage (check existing skills for overlap before creating; find-skills seed) + listing-budget health checks (`/doctor`, 1,536-char cap).

## Success criteria

- Each real operation triggers the right skill without user tracking.
- meta-dev beats skill-creator in skill-creator's own blind A/B comparison.
- Then: uninstall skill-creator + superpowers, repoint skill-guard at meta-dev.
- Deletion gets gated again — by the seconds-cheap `retire-skill` (cross-reference scan → archive → delete), reversing the earlier hook exemption that existed only because the old gate forced a wrong-shaped skill.

## Out of scope (phase 1)

- Agent/hook/command/plugin authoring domains (phase 2 — plugin-dev stays installed until absorbed).
- claude.ai / Cowork portability.
- Automatic obsolescence detection ("model caught up, retire the skill") — v2, wired to benchmarks.

## Naming (locked)

| Thing | Name |
|---|---|
| Plugin | `meta-dev` |
| Router | `skill-creation` |
| Operations | `create-skill`, `update-skill`, `improve-skill`, `restructure-skill`, `review-skill`, `retire-skill` |
| Agents | `reviewer`, `grader`, `comparator`, `improvement-analyst`, `benchmark-analyst` |

Constraint: no skill other than the router may begin with `skill-`.

---

# v2 intent — confirmed 2026-07-05 (interview)

Supersedes the skills-only scope above where they differ. One meta-dev as the single authority for ALL Claude-config markdown: base standard (standards/core.md) + per-artifact modules (instruction-files, skill, agent, hook, plugin), right-sized lifecycles per domain, hook enforcement (guard v2 two-tier + md-format nudge + constitution-size warning), and the docs-currency mechanism. Instruction-files model: AGENTS.md canon + CLAUDE.md=@AGENTS.md, references as pull-only depth, NO rules/ by default, growth ladder (nested CLAUDE.md for folder-shaped / path rules for glob-shaped) with lifecycle-executed graduations. Designed from user needs + current official docs; plugin-inherited shapes re-examined (skills' 6 ops survived the retro). Out of scope: commands, MCP, reverting AGENTS.md canon. Full design: docs/design-v2.md — review-gated, nothing built until approved.
