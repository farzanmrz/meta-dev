---
name: restructure-skill
description: Reorganize skill architecture — split one skill into several, merge overlapping skills, or move content between SKILL.md, references, and scripts. Use when a skill exceeds its size budgets, when skills overlap or their descriptions collide, when content sits at the wrong loading level, or when the user asks to split, merge, rename, or reorganize skills. Content edits within one healthy skill belong to update-skill or improve-skill.
model: sonnet
---

# restructure-skill

Change the shape, preserve the behavior. Restructuring spends one of two currencies — every new model-invoked skill adds permanent context load; every new user-invoked skill adds cognitive load on the human — so a cut must earn its cost. The economics live in `${CLAUDE_SKILL_DIR}/../../standards/skill.md` (invocation economics section); read it and `core.md` before planning.

## Step 0 — Provenance gate

Before anything, settle whether the targets are project-owned or upstream/vendored (`skill.md`'s Provenance section). Any folder carrying an `.upstream` marker, installable via `find-skills` / a known registry, or whose SKILL.md reads as upstream package docs rather than project instructions is **out of bounds — do not split, merge, move, or rename it**. Report it as vendored, stamp an `.upstream` marker if one is missing, and exclude it from the restructure plan. Only project-owned skills proceed.

Completion criterion: every target confirmed project-owned, or excluded as vendored with the marker stamped.

## Step 1 — Map the current shape

1. Inventory every skill involved: line counts (`wc -l`), description lengths, bundled-file tree, and trigger descriptions side by side.
2. Build the overlap map: which descriptions compete for the same prompts; which content is duplicated across skills.
3. Gather usage evidence where it exists: reference files the transcripts show are always read (candidates to inline), never read (candidates to delete or demote), and any skill-listing truncation (`/doctor`).

Completion criterion: a written map — sizes, overlaps, evidence — the plan can cite.

## Step 2 — Plan the target shape

Apply the standards' split rules:

- **Split by invocation** only where a distinct leading word deserves its own trigger, or another skill must reach the piece independently.
- **Split by sequence** only where visible later steps demonstrably tempt premature completion.
- **Merge** when two skills share a trigger surface and one description could serve both without a workflow summary.
- **Move down the ladder** (inline → reference → script) what only some runs need; move up what every run reads.

Write the plan as: resulting skills with their one-line descriptions, what content lands where, and which currency each cut spends. **Present the plan and get explicit confirmation** — restructuring touches multiple artifacts and is the one lifecycle operation that should never proceed on a guess.

## Step 3 — Snapshot everything

`mkdir -p ~/.claude/skill-workspaces/<primary-skill>/skill-snapshot`, then `cp -r` every affected skill into it (workspace location per eval-pipeline.md §1 — never inside `.claude/skills/`). The name matters: `skill-snapshot/` is the directory the eval pipeline treats as the baseline, and it doubles as the rollback.

## Step 4 — Execute

1. Create/rename folders (names must match frontmatter `name`).
2. Move content; keep each meaning single-sourced through the move — the transitional state where a rule exists in two places is where restructures rot.
3. Rewrite descriptions for the new trigger boundaries; update every cross-pointer.
4. Delete emptied files and folders.

Completion criterion: every content block from the map is accounted for in exactly one destination.

## Step 5 — Verify each result and the whole

1. **Each resulting skill**: from `${CLAUDE_SKILL_DIR}/../skill-creation/` run `python3 tools/validate_skill.py <skill-path>`, plus `meta-dev:reviewer` (tier 1).
2. **The behavioral surface**: pick 2–3 prompts that exercised the OLD arrangement, run them against the NEW arrangement per `${CLAUDE_SKILL_DIR}/../skill-creation/references/eval-pipeline.md` with baseline = the snapshot. Same tasks must still succeed — a restructure that loses capability failed regardless of how clean it looks.
3. **Blind compare** old vs new outputs (`meta-dev:comparator` on neutral A/B copies) when quality equivalence is in doubt.
4. **Listing health**: with the new skills in place, check the descriptions don't collide and none get truncated (`/doctor`).

Completion criterion: every new skill passes review, old capabilities demonstrably survive, listing is healthy.

## Step 6 — Finish

Bump versions, log the restructure (what moved where, and why) in the workspace, and route leftovers: orphaned content nobody claimed → retire-skill; descriptions that now under-trigger → improve-skill. Then run the mandatory workspace cleanup (eval-pipeline.md §9): archive each snapshot if untracked, keep the log, and `rm -rf` the workspace.
