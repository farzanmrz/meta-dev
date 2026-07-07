# Instruction-files module — AGENTS.md + path-scoped rules

Adds to `core.md`. Governs a project's always-loaded and path-loaded instruction markdown. The default shape is **Claude-native**: a surface `AGENTS.md` plus path-scoped `.claude/rules/` — no `.claude/references/`.

## The shape

- `AGENTS.md` at repo root is the **surface canonical**: identity, stack, commands, environment, a thin code map, always-on working rules, and the cross-cutting skill routing that has *no natural path*. `CLAUDE.md` contains exactly `@AGENTS.md` (imports load at session start; one line; keeps `AGENTS.md` the single canonical file).
- `.claude/rules/*.md` is the **primary scoped layer**: one file per path-area, each carrying a `paths:` filter so it **auto-loads the moment Claude reads a matching file**. A rule holds that area's skill routing + the non-code-recoverable info that area needs — disclosed exactly when relevant, at zero always-on cost.
- **No `.claude/references/`.** References are *inert* — they never auto-load; the model must be told to read them, so they rot unread. Path-scoped rules replace them: same progressive disclosure, but *guaranteed to fire* on the files they describe. (References survive only as a legacy escape hatch for a project that must serve an agent which can't read `.claude/rules/` — e.g. Codex. That is the exception, not the shape.)
- `docs/` (or anywhere) may hold **user-owned notes** — the human's plans, deferrals, scratch. These are never agent-context (see below).
- Prevention never rides on any of these files — hooks own it (core: Enforcement doctrine). A path-triggered rule is *documentation that reliably fires*, not a guarantee; a hard guard that must never break belongs in a hook.
- Edits are **nudged, not blocked**: the guard hook reminds and allows. The enforcement that matters is **periodic and user-invoked** — `revise-agents-md` re-derives the whole layout in one pass.

## Loading mechanics (verified; design against these, not folklore)

| Mechanism | Loads | Role |
|---|---|---|
| root `CLAUDE.md` + `@AGENTS.md` | session start, always | the surface canonical |
| `rules/*.md` **with** `paths:` | when Claude READS a matching file | **the scoped layer — auto, lazy, precise** |
| `rules/*.md` without `paths:` | session start, always | rare — that content belongs in `AGENTS.md` instead |
| nested `CLAUDE.md` in a subdir | when Claude reads a file in that subtree | folder-scoped constitution (recurses) |
| skills | description match; `paths` only filters | the capability layer the rules route to |
| references/ | never — explicit Read only | **inert; deprecated in this module** |

Post-compaction, path-triggered content is lost until a matching file is read again — one more reason guarantees live in hooks, not rules.

### Don't restate the harness

Claude Code already loads path-scoped rules on matching reads and surfaces every installed skill by its description. Instruction files therefore **never document these mechanisms**: no "detail lives in `.claude/rules/`", no "this rule auto-loads", no "skills are available for X" — such lines only restate the harness's own behavior and are pure bloat (core.md's no-op test). List a skill in `AGENTS.md` or a rule ONLY when the harness won't surface it correctly on its own: to **disambiguate** the blessed skill among several that match an area, to establish **invoke-first** enforcement, or to name a **user-invoked** skill (`disable-model-invocation` — its description isn't even loaded, so nothing else can reveal it exists). A skill whose description already reliably matches its trigger needs no mention anywhere; a fact a rule already owns is never restated in `AGENTS.md`.

Path-scoped rules beat both references (which never auto-load) and nested `CLAUDE.md` (which scatters across the tree and fires only on its exact subtree). A rule is one flat file with an explicit, greppable `paths:` glob — one visible place per area.

## Rules are a projection of (available skills × actual code)

A rule file is not hand-authored lore; it is **derived**. For each path-area of a project:

1. **Enumerate the installed skills** — project-local (`.claude/skills/`), every installed plugin, and global. This is the capability set actually available *now*, not from memory.
2. **Ground the code** under the area — what tech and patterns are really there.
3. **Map skill → path**, three buckets:
   - **apply** — available skills whose technology is genuinely present, each with a `when`.
   - **surface** — available-but-unwired skills that *should* apply, each with the **trigger condition** that activates them (a Postgres-best-practices skill the moment a schema lands; an OAuth-token skill when a connector is built). Surfacing these is a primary output, not an afterthought.
   - **drop** — skills a naive setup might attach but that don't apply (a schema skill with no tables), with the reason.
4. **Extract the progressive info** — the non-code-recoverable keepers for that path (promotion test, below).

The rule = the surviving skills + that info, scoped to the area's `paths:`. Because it is *derived*, it is **maintained by re-derivation**: `revise-agents-md` recomputes the mapping each run against the *current* installed skill set and *current* code — new skills get wired, removed tech gets dropped, drift gets corrected, with no hand-maintenance. That is how the rules stay current as a project evolves: they are recomputed, not edited.

## Path-areas overlap; skills recur; keep content single-sourced

Real areas are not a clean partition: an auth route is under `app/**` (routing) *and* is Supabase (auth); a component is both `components/**` (UI) and a route's client island under `app/**`; a skill can cross folders (a client component that imports an agent-framework's React hooks pulls that framework's skill into a *routing* file). Overlapping `paths:` are fine — several rules firing on one file is the mechanism working. What must not happen is the **same fact or skill-pointer stated twice**. Single-source rule: a skill or fact belongs to the ONE area whose concern it is (routing owns the framework-routing skill; auth owns the auth skill), and other areas that touch the file rely on their own concern's rule. A cross-cutting skill with *no natural path* (env vars, deploy, lint, a build-a-feature workflow) is not a rule at all — it lives in `AGENTS.md`'s always-on routing.

## Information altitude — the promotion test

Every fact competes for a home, and the wrong home is the main way instruction files rot. Sort each fact by one test:

> **Would reading the code tell a fresh session this, cheaply?**

- **Yes** → it does NOT belong in agent-context. A path a glob reveals, a component a file listing shows, an implemented behavior visible in the source — documenting it is bloat, and it goes stale the moment the code moves. Delete it; let the code be its own source.
- **No** → it is a keeper: the *why*, the *guard*, the *gotcha*, the *external constraint* — knowledge that cost a burned session, a failed call, or a production incident to learn and that the source never states (e.g. a route is frozen because a dashboard email template hardcodes its URL; a model id is retired, use its successor; two config blocks are near-duplicates by history, not intent).

Promotion is **subtractive by default**: the burden is on a fact to earn agent-context, not to be excluded. A rule's info section is the *complement* of the code — everything load-bearing that reading the code would NOT teach you. Three destinations by the fact's nature:

- **Durable + action-affecting + non-recoverable from code** → agent-context: `AGENTS.md` if always-needed, the area's **path-rule** if area-scoped.
- **Fast-changing status / plan / active slice** → the issue tracker + branch, never a tracked instruction file.
- **The user's own thinking, deferrals, scratch** → user-owned notes (below), never routed as agent input.

## User-owned notes vs agent-context

Not every markdown file in a repo is agent-context. A project may keep **user-owned notes** — a roadmap, a deferral list, a scratchpad — whose provenance is the *human*, not the agent:

- **Never rewritten, restructured, or deleted by any lifecycle skill.** The user owns them; a skill may only read them.
- **Never routed as agent input.** `AGENTS.md` (or a rule) must not point Claude at them as a source to "consider" or plan from — a mention of them, if any, states plainly that they are the user's notes, not instruction. An instruction file that tells agents to treat a human scratchpad as input is a **defect** — flag it (the "roadmap IS a slice source" class of bug).
- **Surface, never fold.** If a user-note holds a fact that passes the promotion test, a skill *reports* it as a candidate for the user to promote — it never copies it into agent-context on its own.

The signal that a file is user-owned: it carries the user's undecided questions, plans, or deferrals (provenance = user), versus settled, load-bearing knowledge an agent needs to act (provenance = the system).

## The canonical skeleton — fixed slots, adaptive fill

The arrangement is a schema reconciling a fixed structure with per-project diversity through three zones. A file or tree is on-standard when every part lands in one zone:

1. **Required slots** — fixed name and position: root `AGENTS.md` (surface canonical); root `CLAUDE.md` = exactly `@AGENTS.md`; each `.claude/rules/*.md` opens with a `paths:` filter and its area's skills.
2. **Optional canonical slots** — a fixed vocabulary with fixed order, included only when the project has that content (the `AGENTS.md` section playbook and the rule-file shape below). Adaptivity is in *which* appear and *what* fills them — never their naming or order.
3. **Project-extension zone** — genuinely project-specific structure no canonical slot covers (a bespoke `docs/` notes system, a domain glossary). First-class, not a violation — but still bound by the universal rules: one-fact-one-home, verified-against-code, purpose-per-file, and the user-vs-agent split.

The skeleton fixes **slots, order, naming, markdown standards**; the project fills them. Enforcement is a placement question ("is this fact in the right zone and file?"), never a content question ("is this fact allowed?").

## AGENTS.md section playbook

Order fixed, every section optional — include only what the project has:

1. Identity line (what the project is, one sentence)
2. `## Stack` — table (layer/tech/version)
3. `### Commands` — fenced block with per-command comments
4. `### Environment` — keys table + where setup lives
5. `## Code map` — one line per top-level area, naming what it is. **Thin**: it does NOT point at rules (rules auto-load by path — no pointer needed); it orients, it does not index.
6. `## Conventions` (or `## Working rules`) — always-on working rules and guards not tied to any path. A cross-cutting skill goes here ONLY when it needs invoke-first enforcement or is user-invoked; a skill the harness already matches by description is not listed. Per-area skills live in their rule, never here.

Content rules: surface facts and standing rules only — area detail goes to the area's rule; each fact lives **once** (a fact a rule owns is never restated here); guards state the why in half a line. No section documents the rules/skills loading mechanism (see "Don't restate the harness"). A `CLAUDE.md` = `@AGENTS.md` cross-tool note is optional and only for a project that actually serves another agent — a Claude-only project omits it.

## Rule-file shape

A `.claude/rules/<area>.md`:

- **Frontmatter** — `paths:` globs scoping the area to where its tech actually lives (the trigger). Scope precisely: too broad fires on unrelated files, too narrow misses the area.
- **Skills first** — the area's apply-now skills (with `when`), then any *surfaced* future-trigger skills noted as "when X, add Y." This is the enforcement half — invoke-before-working guidance for the area.
- **Progressive info** — the non-code-recoverable keepers only: guards, gotchas, external constraints. No code-map listing, no restating a source file's own comments.
- One area per file; every skill and fact single-sourced across all rules and `AGENTS.md`.
