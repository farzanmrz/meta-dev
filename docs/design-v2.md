# meta-dev v2 — Holistic Design (for review, nothing built)

*Confirmed intent: one meta-dev as the single authority for every Claude-config markdown artifact — base standard + per-artifact modules, right-sized lifecycles, hook enforcement, docs-currency. Designed from user needs + current official docs; plugin-inherited shapes explicitly re-examined. 2026-07-05.*

## Problem statement

How might we make every Claude-config artifact — instruction files, skills, agents, hooks, plugins — follow one coherent, current, enforced standard, so no project ever re-litigates "what goes where, in what format, at what size" again?

## Principles (the design's constitution)

1. **Enforcement wants determinism; info wants thrift.** Hooks prevent; loaded text only informs. Anything inviolable rides on hooks, never on prose placement.
2. **Single source of truth.** Each rule lives in exactly one module; creators and reviewers cite the same file.
3. **Right-sized lifecycles.** Operation count scales with churn × consequence, not symmetry.
4. **Proportional rigor.** Verification tier matches the change (static → micro → eval → pressure).
5. **Autonomy split.** Improve = hands-free; update = confirm-the-diff only; create = intake only; restructure/setup = plan approval; retire = blockers only.
6. **Deliberate model pinning.** Every skill/agent declares `model:` on purpose; `inherit` is a valid choice; the caller owns the model for subagent-driven skills; never fable unless asked.
7. **Currency over snapshot.** The system re-grounds itself against official docs; drift is surfaced, not discovered by failure.

## Architecture overview

```
meta-dev (skills-dir plugin, ~/.claude/skills/meta-dev)
├── standards/                      ← the law, modular
│   ├── core.md                     base markdown standard (ALL .md)
│   ├── instruction-files.md        AGENTS.md playbook + growth ladder
│   ├── skill.md · agent.md · hook.md · plugin.md
├── skills/                         ← the lifecycles (per artifact, right-sized)
├── agents/                         ← shared judges (reviewer, grader, comparator, analysts)
├── hooks/                          ← enforcement (guard v2, md-format nudge)
└── tools/                          ← validators (skill, agent) wrapping vendored/official checks
```

## Standards system

`standards/core.md` (evolved from today's standards.md): formatting rules (headings expose real hierarchy, under-structure beats over-structure, one directive per bullet, backticks/fences/tables usage), per-line quality (no-op, relevance, duplication, leading words), description discipline, model-assignment policy, failure modes. Applies to **every** markdown artifact.

Per-artifact modules add only what's unique. Every lifecycle cites core + its module — creator and reviewer can never disagree.

| Module | Unique content |
|---|---|
| instruction-files | the growth ladder, AGENTS.md section playbook, graduation triggers |
| skill | frontmatter fields incl. `paths` filter/`context: fork`, body budgets, invocation economics |
| agent | modern frontmatter (skills preload, background, isolation, memory, effort), system-prompt skeleton, When-to-invoke-in-body rule, model-by-task |
| hook | events catalog, type selection (command/prompt/http/mcp_tool/agent), decision contracts, exit-code semantics, security patterns |
| plugin | manifest fields, component discovery, skills-dir vs marketplace, validation path |

## Module: instruction files (the new domain)

**The shape** (verified against docs): `AGENTS.md` canon + `CLAUDE.md` = `@AGENTS.md` (costs one line; keeps the 0.00001% cross-tool option free). References = pull-only depth at every size. No `rules/` by default.

**The growth ladder** — same pattern at every scale (always-on summary → on-touch area brief → pull-only depth):

- **Rung 1 (≤ ~200-line constitution):** everything critical always-on in AGENTS.md; area detail in `.claude/references/`; hard rules in hooks. *(oparax today — conformant.)*
- **Rung 2 (outgrown):** graduate an area's summary+rules to on-touch auto-load — folder-shaped → nested `CLAUDE.md` in that folder (lazy-loads on read, recursive); glob-shaped → `.claude/rules/x.md` with `paths:` (the only glob-triggered loader). Constitution keeps one pointer line per area.
- **Always:** prevention lives in hooks, independent of rungs.

**Graduation triggers** (detected by the lifecycle, executed with user approval): constitution nearing 200 lines · one area's section swelling · observed misses of pull-only guidance.

**AGENTS.md section playbook:** identity line → Stack (table) → Commands (fenced) → Environment → Code map (one line per area + reference pointer) → Conventions (skills table, guards, working rules, writing-markdown) → cross-tool note. Sections optional; order fixed.

**Lifecycle (3 ops):** `setup-instructions` (bootstrap a repo: generate constitution from repo inspection + wire references; plan-approval), `update-instructions` (content changes + graduations; confirm-diff), `improve-instructions` (debloat/format/audit; hands-free, like improve-skill).

## Module: skills — the unbiased retro-verdict

Re-examined against actual usage, not skill-creator's shape: **the 6 ops survive** (create/update/improve/restructure/review/retire each fired in real use within days). What the rethink changes:

- **Two-tier guard** (see Enforcement) — the heavyweight-gate-on-one-liner problem.
- **Trivial-edit fast lane** stated prominently in update/improve.
- Add modern-capability content the plugin sources missed: `paths` filter, `context: fork` + `agent:`, skill-scoped hooks, `disable-model-invocation` interactions.
- Model policy v2 wording (deliberate pin; inherit valid; subagent-driven skills → inherit).

## Module: agents (new domain — the one you co-develop with skills)

**Lifecycle (5 ops, no restructure):** create / update / improve / review / retire. Same autonomy split as skills.

**Content foundation:** plugin-dev's still-good prompt-craft (system-prompt skeleton, 4 archetypes, prose triggering doctrine, triggering-debug rubric, least-privilege presets) + the modern layer it entirely lacks: context forking, skill preloading (`skills:` injects full content; can't preload `disable-model-invocation` skills), background/parallel/worktree isolation, per-dispatch model override, memory scopes, structured return contracts, plugin-agent limitations (no hooks/mcpServers/permissionMode), nesting depth cap.

**Model-by-task standard:** narrow lookup agents → cheap-capable (sonnet default; haiku only for truly mechanical); worker agents → sonnet; judgment agents → opus; depth-variable agents (your doc-query trio) → sonnet + dispatch-prompt depth control, never frozen to haiku.

**Skill↔agent interplay (first-class):** creating a `context: fork` skill offers its paired agent; create-agent wires preloads; review audits the **pair** for seam bugs (preloading disabled skills, fork skills with no actionable task, tool lists that can't do the stated process). Guard gate for `.claude/agents/` returns with this phase.

**Judges:** reviewer extended artifact-aware; `tools/validate_agent.py` (adapted from plugin-dev's script minus its two now-wrong checks: `<example>` blocks, required-model/color).

## Module: hooks (new domain)

**Lifecycle (2 ops):** `create-hook` (design + author: event choice from the current ~30-event catalog, type selection, decision contracts, security patterns) and `review-hook` (validate + audit: schema, exit-code semantics — only exit 2 blocks, matcher correctness, `${CLAUDE_PLUGIN_ROOT}` portability). Editing routes through create-hook's guidance + review; deletion is trivial (no retire ceremony).

**Grounding corrections over plugin-dev:** settings.json hooks hot-reload (no restart); plugin hooks need `/reload-plugins`; new events (PermissionRequest, PostToolBatch, FileChanged, WorktreeCreate…); new types (http/mcp_tool/agent); `hookSpecificOutput.permissionDecision` is the current PreToolUse contract. Vendor plugin-dev's 3 validation scripts only after updating them to these facts.

## Module: plugins (new domain)

**Lifecycle (2 ops):** `scaffold-plugin` (structure + manifest + component wiring; skills-dir vs marketplace guidance) and `validate-plugin` (wrap official `claude plugin validate` + standards audit). Commands and MCP: **not doing** (commands superseded by skills; MCP integration low-churn reference, point at official docs).

## Enforcement layer (hooks meta-dev ships)

1. **skill-guard v2 — two-tier:** hard-deny create/delete/Write/multi-hunk edits of skills (as now, routed via router); single small Edit → **allow + systemMessage nudge** ("skill edited directly; run review-skill if behavior changed"). Same pattern extends to `agents/` (phase C) and hook-config (phase D).
2. **md-format hook (new):** PostToolUse on `*.md` writes → validate against core.md → **nudge-only** (never blocks prose work; annotates violations for self-correction).
3. **Constitution-size hook (new, tiny):** on instruction-file writes, warn when AGENTS.md crosses ~200 lines → suggests `update-instructions` graduation.

## Currency mechanism (anti-rot)

`sync-docs` skill + the claude-code-docs agent: pulls current official docs for skills/agents/hooks/plugins/memory, diffs against the standards modules, produces a drift report (new capabilities · changed contracts · deprecations), and routes accepted changes through each module's update lifecycle. Run on demand and/or scheduled; keeps a *tested-and-declined* register so rejected suggestions don't resurface. This is what stops meta-dev from becoming the next plugin-dev.

## Routing & autonomy

Extend the existing `skill-creation` router table to all artifact classes (instruction-files, agents, hooks, plugins) — one manual entry point, zero new context entries; op-skill descriptions still auto-route directly. Optional later rename if the name feels narrow. Autonomy split table lives in the router and is enforced by each op skill.

## Alternatives considered (not doing, and why)

- **Separate plugins per domain** — rejected: multiplies the confusion meta-dev exists to kill.
- **6 ops for every artifact** — rejected: ceremony beyond skills' churn; right-sizing per domain.
- **`rules/` as default instruction layer** — rejected: docs recommend root-file-first under ~200 lines; enforcement belongs to hooks; rules return only as a rung-2 graduation for glob-shaped content.
- **Reverting AGENTS.md canon to CLAUDE.md-only** — rejected: costs one import line, buys optionality; churn came from content-splitting, not the alias.
- **Commands + MCP modules** — dropped (superseded / low-churn).
- **Blocking md-format enforcement** — rejected: formatting nudges; only structural artifact mutations hard-gate.
- **Freezing doc-agents to haiku** — rejected: depth varies per request; isolation (not a cheaper brain) is the efficiency lever.

## Assumptions to validate

- [ ] Two-tier guard's "small edit" heuristic separates trivial from substantive reliably → validate on real sessions before hard-committing thresholds.
- [ ] Nudge-only md-format hook actually improves files (vs. being ignored) → measure on oparax for a week.
- [ ] ~200-line graduation trigger is the right threshold → treat as tunable, not law.
- [ ] Currency runs actually happen → decide on-demand vs scheduled after first manual run.
- [ ] `setup-instructions` can bootstrap a scruffy repo well → pilot on a second, non-conformant repo.

## Build phases (each ends with verification + a retirement)

| Phase | Build | Verify | Retires |
|---|---|---|---|
| **A** | standards restructure (core + 5 modules) · md-format nudge hook · guard v2 | validators pass; guard matrix re-run; nudge observed on oparax | — |
| **B** | instruction-files lifecycle (setup/update/improve) | oparax conformance diff = clean; scruffy-repo bootstrap pilot | claude-md-management |
| **C** | agents domain (5 ops + modern content + validate_agent + pair-review) | dogfood on meta-dev's own judges + oparax agents; agents gate returns | plugin-dev agent slice |
| **D** | hooks + plugins domains (create/review · scaffold/validate) | scripts pass on meta-dev's own hooks; `claude plugin validate` green; hooks gate returns | plugin-dev fully |
| **E** | currency mechanism | first drift report reviewed; declined-register seeded | (keeps everything retired) |

## Open questions — ANSWERED 2026-07-05

1. Guard v2 → **approved**; shipped in Phase A.
2. Currency cadence → **on-demand only**, via a user-invoked skill (`disable-model-invocation: true`); no schedule.
3. Router rename → **keep `skill-creation`** (muscle memory + `/skill-` constraint preserved; descriptions do the routing; rename buys nothing).

## Phase A — SHIPPED 2026-07-05

standards/ (core + skill + agent + hook + plugin + instruction-files) · guard v2 two-tier · md-format nudge hook · constitution-size warning (inside md-format) · all lifecycle skills + reviewer repointed to the modular standards · model policy v2 wording throughout · monolithic standards.md retired. Requires `/reload-plugins` for the hook changes.
