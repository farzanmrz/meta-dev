# Skill module — rules unique to Agent Skills

Adds to `core.md`; never repeats it. A skill = a folder with `SKILL.md` (frontmatter + body) and optional bundled resources.

## Frontmatter

- `name`: ≤64 chars; lowercase letters, numbers, hyphens; no leading/trailing/double hyphens; MUST equal the folder name.
- `description`: 50–500 chars target, 1,024 hard max; rules per core. For user-invoked skills (`disable-model-invocation: true`) it is human-facing — a one-line summary, trigger lists stripped. Claude Code truncates description(+when_to_use) at 1,536 chars in the listing; `when_to_use` is deprecated — fold into `description`.
- `model`: per core's Model assignment. Semantics: overrides the model for the rest of the current main-session turn, reverting on the next prompt. Inside a subagent the caller's model wins — a pin there is inert, so subagent-driven skills choose `inherit`.
- `paths`: glob list that **filters** description-based auto-activation ("only auto-load when working with matching files"). It is never a trigger — path-matching alone fires nothing. Use to stop a broad skill misfiring outside its territory.
- `context: fork` + `agent:`: runs the skill in an isolated subagent — SKILL.md content becomes the task prompt; the skill sees none of the parent conversation. Only for skills with explicit actionable instructions; a reference-only skill forked this way returns nothing useful. The fork target's own model resolution applies (skill `model:` does not follow into the fork).
- `disable-model-invocation: true`: blocks auto-trigger, blocks preloading into subagents via agents' `skills:` field, and blocks scheduled-task firing. Manual `/name` invocation still works and still applies `model:`.
- Also valid: `allowed-tools`, `disallowed-tools`, `argument-hint`, `arguments`, `user-invocable`, `effort`, `hooks`, `shell`. Version lives in `metadata.version` + git; no first-class version field exists.
- Portable-spec note: the vendored validator rejects Claude-Code-only keys; validate through `tools/validate_skill.py`, which exempts them.

## Body

- ≤200 lines target; **500-line hard cap**. Approaching the cap is a restructure signal, not a license to compress prose.
- Cold-start budget: first activation loads ≤500 lines total (body plus everything it forces a read of).
- Imperative/infinitive voice ("To validate, run…"); never "You should…"/"Claude should…".
- Every step ends on a **checkable completion criterion** — done vs not-done decidable; exhaustive where it matters ("every modified file accounted for").

## Structure

- `references/` one level deep from SKILL.md — nested pointers cause partial reads. Files >100 lines get a TOC. Names say what they hold.
- `scripts/` = executed, not read. `references/` = read on demand. `assets/` = used in output, never loaded.
- Never bundle README/CHANGELOG/install guides inside a skill folder.

## Invocation economics

- **Model-invoked** (keeps a trigger description): pays permanent context load. Choose when the agent must reach the skill alone, or another skill must fire it.
- **User-invoked** (`disable-model-invocation: true`): zero context load; the human is the index. Choose for destructive, rare, or manual-only work.
- Split a skill only when the cut pays for its load: by invocation (a distinct leading word deserves its own trigger) or by sequence (visible later steps tempt premature completion).

## Provenance — upstream vs project-owned

A skill is either **project-owned** (authored in this repo, yours to change) or **upstream/vendored** (installed from a registry or another repo — `npx <name>`, a shadcn-style registry, a marketplace). A vendored skill is documentation-of-record for someone else's package: editing it locally drifts from the source and is silently lost on the next re-sync.

- **Never edit a vendored skill.** update/improve/restructure-skill check provenance as their first step and refuse it; fixes belong upstream (re-source via `find-skills`, or file the change with the source project).
- **Mark it once.** A vendored skill folder carries an `.upstream` marker file (its body may name the source + install command for re-sync). The guard hook hard-denies every mutation under a marked folder — even inside the lifecycle — so an accidental local fork can't happen. Stamping the marker is the lifecycle's job the first time it identifies a skill as vendored.
- **Detecting vendored provenance** (lifecycle step 1): an existing `.upstream` marker; the skill is installable via `find-skills` / a known registry; or SKILL.md carries upstream attribution (a source repo/package link, marketing-style install docs, foreign issue-tracker links) rather than project-specific instructions.
- **To adopt one as project-owned**, remove its `.upstream` marker deliberately (un-vendoring) — then it lives under the normal lifecycle. To build on it, author a NEW skill rather than editing the vendored one.

## Interplay with agents

A forking skill and its `agent:` target are one mechanism from two doors (the inverse of an agent preloading skills). When authoring either, check the seam: the fork skill has an actionable task; any preloaded skill is not `disable-model-invocation`; the agent's tool list can actually execute the skill's process. Review skills and their paired agents together.
