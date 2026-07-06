# Testing Ladder — proportional rigor, four tiers

The change decides the tier; when honestly unsure, take the higher tier. Tier definitions match the rigor ladder in `standards/core.md` (plugin root); this file gives each tier's procedure. Cost grows ~100× per rung — spend accordingly.

## Tier 1 — Static review (free, always)

For cosmetic and structural changes: formatting, renames, moving content down the loading ladder.

1. `python3 tools/validate_skill.py <skill-path>` (from the skill-creation directory).
2. Spawn `meta-dev:reviewer` with skill path + standards path.
3. Fix critical/major findings; done when the rating is Pass and no dimension regressed.

## Tier 2 — Micro-test (~cents per sample)

For wording changes to behavior-shaping text: a rule rephrased, a line deleted as a suspected no-op, a description reworded by hand.

1. Isolate the wording variants: old, new, and a **no-guidance control** (the passage removed entirely). The control is non-negotiable — if the control doesn't exhibit the failure the wording targets, the passage was a no-op and the honest fix is deletion.
2. Run 5+ fresh-context reps per variant: subagents (or `claude -p`) given a realistic task where the wording should bite, with no memory of the authoring session.
3. Score programmatically where possible (grep for the target behavior) but **manually read every flagged match** — template echoes and quoted counter-examples masquerade as hits.
4. Read the variance: reps disagreeing with each other under the same wording means the wording isn't binding — rewrite, don't average.

Verdict: keep the variant that passes most; a tie between shorter and longer goes to shorter.

## Tier 3 — Full eval run (~$10+ per iteration)

For new behavior, changed steps, or changed triggers. Follow `eval-pipeline.md` end to end: baseline runs, grading, benchmark, analyst, viewer, feedback. This is the only tier that produces a defensible "the skill is better" claim, because it is the only one with a baseline delta.

## Tier 4 — Pressure testing (for discipline skills only)

For rules an agent will *want* to break under pressure (process discipline, safety gates, "never do X" policies). Plain evals under-test these — compliance when nothing pushes back is not evidence.

1. **Write the scenario before the fix.** A realistic task where breaking the rule is tempting: combine 3+ pressures (time, sunk cost, authority, exhaustion, economic stakes), give a forced A/B/C choice, use real paths and consequences, and frame it as real work, not a quiz.
2. **Baseline without the rule**: run fresh-context subagents; capture their excuses **verbatim** — these rationalizations are the raw material.
3. **Write the minimal rule** addressing only the observed failures.
4. **Re-run the same scenarios with the rule.** Compliance must cite the skill, not coincide with it.
5. **Close loopholes**: each NEW rationalization gets a targeted negation and a red-flags entry; re-test. Prohibitions can backfire on shaping problems ("make it good" tasks) — there, prefer a positive recipe over a longer ban list.
6. **Meta-test on failure**: ask the failing agent how the skill could have made the right choice crystal clear, and route the answer — ignored-it → add the foundational principle; should-have-said-X → add it verbatim; didn't-see-it → reorganize.

Stop when the agent complies under maximum pressure and the meta-test returns "the skill was clear".

## Choosing under mixed changes

A pass that mixes tiers takes the highest tier any part needs — but first ask whether the mix should have been separate passes (improve-skill enforces one metric per pass for exactly this reason).
