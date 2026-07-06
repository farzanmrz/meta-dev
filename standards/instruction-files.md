# Instruction-files module — CLAUDE.md, AGENTS.md, rules, references

Adds to `core.md`. Governs a project's always-loaded and path-loaded instruction markdown.

## The shape

- `AGENTS.md` at repo root is canon; `CLAUDE.md` contains exactly `@AGENTS.md` (imports load natively at session start; costs one line; keeps cross-tool optionality free).
- `.claude/references/` holds pull-only depth — not a recognized directory, loads only when something explicitly points and reads. That is its job; don't expect auto-load.
- No `.claude/rules/` by default. Rules return only as a rung-2 graduation (below).
- Prevention never rides on any of these files — hooks own it (core: Enforcement doctrine).

## Loading mechanics (verified; design against these, not folklore)

| Mechanism | Loads | Nature |
|---|---|---|
| root CLAUDE.md + `@imports` | session start, always | absolute presence |
| `rules/*.md` without `paths:` | session start, always | absolute presence |
| `rules/*.md` with `paths:` | when Claude READS a matching file | glob-triggered, lazy |
| nested `CLAUDE.md` in a subdir | when Claude reads a file in that subtree | directory-triggered, lazy, recursive |
| skills | description match; `paths` only filters | semantic, never guaranteed |
| references/ | never — explicit Read only | inert |

Post-compaction, path-triggered content is lost until a matching file is read again — one more reason guarantees live in hooks.

## The growth ladder

Same pattern at every scale: always-on summary → on-touch area brief → pull-only depth.

- **Rung 1 (constitution ≤ ~200 lines):** everything critical always-on in AGENTS.md; area detail in references; hard rules in hooks.
- **Rung 2 (outgrown):** graduate an area's summary+rules to on-touch loading — **folder-shaped** content → nested `CLAUDE.md` in that folder; **glob-shaped** content (file-type conventions spanning folders) → `rules/x.md` with `paths:`. The constitution keeps one pointer line per area.
- Rungs recurse: a nested CLAUDE.md is a folder-scoped constitution with its own references beneath it.

**Graduation triggers** (lifecycle-detected, user-approved): constitution nearing 200 lines · one area's section swelling · repeated misses of pull-only guidance. Graduations are restructures — plan approval required.

## AGENTS.md section playbook

Order fixed, every section optional — include only what the project has:

1. Identity line (what the project is, one sentence)
2. `## Stack` — table (layer/tech/version)
3. `### Commands` — fenced block with per-command comments
4. `### Environment` — keys table + where setup lives
5. `## Code map` — one line per top-level area + its reference pointer
6. `## Conventions` — skills-routing table · guards ("never break") · working rules · writing-markdown pointer
7. Cross-tool note (canon/import statement)

Content rules: facts and standing rules only — folder internals go to references; each fact lives once (link, don't restate); guards state the why in half a line.

## References

- One file per area (`app.md`, `lib.md`), named for the folder it covers; open with the area's skill pointer, then structure/facts an agent needs when working there.
- Nest subdirectories/deeper files as the area demands; keep each file's scope one area.
- A reference is info, not law — anything that must be guaranteed belongs in the constitution or a hook.
