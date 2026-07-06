# Vendored measurement harness — provenance

## Source

Copied 2026-07-04 from the installed official plugin:
`~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/`
(upstream: github.com/anthropics/skills, `skills/skill-creator`; Apache-2.0 — `skills/skill-creation/LICENSE.txt` retained).

## What was vendored, byte-identical

Into `skills/skill-creation/`:

- `scripts/` — all 8 Python files + `__init__.py` (quick_validate, run_eval, run_loop, improve_description, generate_report, aggregate_benchmark, package_skill, utils)
- `eval-viewer/` — generate_review.py, viewer.html
- `assets/eval_review.html`
- `references/schemas.md`

## Policy

Keep vendored files **byte-identical to upstream** so re-syncing is a plain diff:

```bash
diff -rq ~/meta-dev/skills/skill-creation/scripts \
  ~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/scripts
```

Customizations go in meta-dev's own SKILL.md files, references, and agents — never in the vendored scripts. If a script must change, fork it under a new name and note it here.

## Known caveats (accepted, not patched — patching would break byte-identity)

1. **`eval-viewer/viewer.html`** loads SheetJS from `cdn.sheetjs.com` — xlsx preview inside the review viewer needs network; offline it degrades (files still listed/downloadable).
2. **`scripts/generate_report.py`** and **`assets/eval_review.html`** reference Google Fonts — cosmetic only offline.
3. **`scripts/run_eval.py`** plants a temporary command file in the project's `.claude/commands/` during trigger measurement and tests the description in isolation (not in competition with the full installed skill list). Treat trigger rates as relative signals, not absolutes.
4. **`scripts/quick_validate.py`** requires PyYAML; `scripts/utils.py` hand-parses frontmatter independently. Two parsers exist upstream; unify only if upstream does.

## Meta-dev-owned additions (NOT vendored — never sync these upstream)

- `skills/skill-creation/tools/validate_skill.py` — wrapper that strips documented Claude-Code-only frontmatter keys (model, disable-model-invocation, …) before delegating to the vendored `scripts/quick_validate.py`, which enforces the portable agentskills.io spec and would otherwise reject them. All meta-dev pipelines validate through this wrapper.

## Not vendored

- `SKILL.md` (486-line monolith) — quarried into the seven operation skills instead.
- `agents/{grader,comparator,analyzer}.md` — promoted into registered agents at `agents/` (analyzer split into improvement-analyst + benchmark-analyst). Their JSON output contracts were preserved exactly; see `references/schemas.md`.
