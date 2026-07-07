# Core standard — all Claude-config markdown

The base law for every `.md` artifact meta-dev governs: instruction files, skills, agents, hooks docs, plugin docs. Per-artifact rules live in the sibling module (`skill.md`, `agent.md`, `hook.md`, `plugin.md`, `instruction-files.md`); each module adds to this file, never repeats it.

## Formatting

- Structure only to expose hierarchy that is really there. No heading for one line, no sub-bullet for a single item, no bold on a whole sentence. **Under-structure beats over-structure.**
- Headings `#`→`####` for real depth; never skip a level.
- Bullets (`-`) for unordered points; numbered lists only for real sequences or ranked items.
- Bold the keyword a line turns on; italics rarely, for one emphasized word.
- Backticks for every path, filename, identifier, inline command. Fenced blocks (with a language tag) for any multi-line command or snippet.
- Tables when several items share the same fields; a list otherwise.
- Write directives, not descriptions — in behavioral files a line stays only if it says to DO or NOT-do something; explain the why for rules an agent will be tempted to break. ALWAYS/NEVER in caps is a yellow flag — prefer a reason to a shout.

## Per-line quality

- **No-op test**: does this line change behavior versus the model's default? Fails → delete the whole sentence, don't trim it. Disputes are settled by running the artifact, not by debate.
- **Relevance**: does the line still bear on what the artifact does today?
- **Leading words**: collapse restated qualities into one pretrained token ("fast, deterministic, low-overhead" → *tight*). A weak leading word (*be thorough*) is a no-op — strengthen it, don't pad it.
- **Single source of truth**: each meaning lives in exactly one place. Cross-reference; never restate.

## Descriptions (any artifact that has one)

Third person. **Triggers only — never a workflow summary** (measured failure: agents follow the summary and skip the body). Front-load the leading word; list the phrases the user actually says. Length limits are per-artifact (see modules).

## Model assignment

Every skill and agent — meta-dev's own AND every one it creates or edits — declares `model:` **deliberately**. `inherit` is a valid, explicit choice, not a smell; the sin is an unconsidered omission. Never `fable` unless the user explicitly asks.

- **Pin a tier** (`sonnet`/`opus`/`haiku`) when the artifact should force it regardless of session: `opus` for judgment/planning-critical work; `sonnet` the default for workers and main-session skills; `haiku` only for truly mechanical lookups.
- **Choose `inherit`** when the caller should own the model: orchestrator skills that ride the session, and skills invoked mainly by subagents (a subagent's model resolution ignores the skill's pin — the caller already decided the brain).
- Agents additionally accept per-dispatch model overrides; depth-variable agents (doc research) stay `sonnet` with depth set in the dispatch prompt, never frozen to `haiku`.
- Why: a skill's `model:` switches only the current main-session turn (reverts next prompt); efficiency for subagent work comes from context isolation, not a cheaper brain.

## Failure modes (review diagnoses, all artifacts)

| Mode | Symptom | Cure |
|---|---|---|
| Sediment | stale layers accumulate; adding felt safe, removing felt risky | relevance check per line; prune |
| Sprawl | too long even though every line is live | push detail down the loading ladder; split by shape |
| Duplication | same meaning in 2+ places | restore single source of truth |
| No-op | line restates the model default | delete, or strengthen the leading word |
| Premature completion | steps end before genuinely done | sharpen the completion criterion first |
| Under-triggering | artifact exists but never fires | description rewrite; verify with trigger evals |
| Listing starvation | description truncated/dropped from listings | shorten; check `/doctor` budget |

## Rigor ladder (proportional verification)

The change decides the tier; when honestly unsure, take the higher tier.

1. **Cosmetic/structural** — static review only: validator script + reviewer agent.
2. **Wording of behavior-shaping text** — micro-test: 5+ fresh-context reps per variant vs a no-guidance control; read every flagged match manually; rep-variance means the wording isn't binding.
3. **New behavior / changed steps / changed triggers** — eval run with baseline + grading + benchmark delta *for probabilistic (model-driven) behavior*. **Deterministic** behavior — a script, decoder, or tool whose output is fixed given its input — verifies functionally instead: run it against real fixture data and assert the output. No eval pipeline (trigger evals test model behavior, which a deterministic tool doesn't have).
4. **Discipline rules** (things an agent will want to break under pressure) — pressure scenarios, rationalizations captured verbatim, each closed with a targeted negation.

## Autonomy split (lifecycle operations)

- **improve** — hands-free end to end; never consults; reports evidence afterward.
- **update** — consults once, to confirm the requirements diff; skipped when the request already states it.
- **create** — asks during intake only.
- **restructure / setup / rule re-scopes** — pauses for plan approval; shape changes and many-files-at-once writes are user decisions.
- **retire** — pauses only on unresolved cross-reference blockers.

## Enforcement doctrine

Loaded text informs; only hooks prevent. Anything inviolable rides on a hook (deny or nudge per risk); markdown carries knowledge, pointers, and process — never the guarantee.
