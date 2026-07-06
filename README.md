# meta-dev

Single authority for Claude-config artifacts — skills, agents, hooks, plugins, and project instruction files (CLAUDE.md/AGENTS.md/references).

- `standards/` — the law: `core.md` (all Claude-config markdown + shared policies) + per-artifact modules.
- `skills/` — right-sized lifecycles per artifact. Entry point: `/meta-dev:skill-creation` (routes everything). Currency: `/meta-dev:sync-docs` (user-invoked only).
- `agents/` — shared judges: reviewer, grader, comparator, improvement-analyst, benchmark-analyst.
- `hooks/` — guard v3 (two-tier gates on skills/agents/hook-config) + md-format nudge.
- `skills/skill-creation/` — shared harness: vendored eval scripts (Apache-2.0, byte-identical to anthropics/skills), validators (`tools/`), pipeline references.
- `docs/` — intent, design, vendoring provenance, declined register.

Dev loop when installed via marketplace: edit this repo → `claude plugin marketplace update <marketplace>` → `claude plugin update meta-dev`. Hook/agent changes need `/reload-plugins`.
