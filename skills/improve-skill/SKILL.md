---
name: improve-skill
description: Raise an existing skill's quality against a measurable criterion WITHOUT changing its intended behavior. Use when the user asks to debloat, tighten, shorten, or clean up a skill, fix its formatting or wording, rewrite a description already diagnosed as under-triggering (diagnosing why belongs to review-skill), or run the automated description-optimization loop. Behavior changes belong to update-skill; skills over their size budget belong to restructure-skill.
model: sonnet
---

# improve-skill

Same behavior, better skill — by one named metric at a time. The contract that makes this safe: intended behavior does not change, so verification is about *equivalence and quality*, not new capability. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` first; its Per-line quality section defines every test used below.

## Autonomy contract

Improve runs hands-free, end to end. Never consult the user mid-pass — behavior is preserved by contract, so there is nothing for them to decide: choose the metric, execute, verify, then report the evidence and every choice made. (Users weigh in on operations that change behavior or shape — update and restructure — never on improve.)

## Step 0 — Provenance gate

Before anything, settle whether the target is project-owned or upstream/vendored (`skill.md`'s Provenance section). If the folder carries an `.upstream` marker, the skill is installable via `find-skills` / a known registry, or its SKILL.md reads as upstream package docs rather than project instructions: **stop — do not edit**. Report it as vendored, stamp an `.upstream` marker if one is missing (naming the source + re-sync command), and route the user to re-source or fix it upstream. Only a project-owned skill proceeds.

Completion criterion: target confirmed project-owned, or handed back as vendored with the marker stamped.

## Step 1 — Pick the metric

Determine which single criterion this pass targets, from the user's complaint and a quick scan of the skill:

- **Bloat** — the skill is too long, stale, or repetitive (but still within its size budgets — over-budget skills route to restructure-skill)
- **Description/triggering** — the skill fires on the wrong prompts or not at all
- **Formatting/style** — voice, structure, or frontmatter violate the standards

One metric per pass. A skill needing several gets sequential passes, run autonomously in order (bloat first — no point optimizing the wording of lines about to be deleted). If the real problem is shape (split/merge/move content), hand to restructure-skill.

## Step 2 — Snapshot

`mkdir -p ~/.claude/skill-workspaces/<skill-name> && cp -r <skill-path> ~/.claude/skill-workspaces/<skill-name>/skill-snapshot` — baseline for comparison and rollback. Workspace location and cleanup follow eval-pipeline.md §1/§9; never place it inside `.claude/skills/`.

## Step 3 — Apply the metric's procedure

### Bloat branch

Work line by line, applying the standards' Per-line quality tests (no-op, relevance, duplication, leading words) in that order — do not restate or improvise the tests; the standards file is their single source of truth. Discipline points that live here, not there: a sentence that fails a test is deleted whole, never word-trimmed; nothing is kept "just in case"; detail that only some runs need moves down to references rather than being deleted. Report the delta (lines and words before/after). Completion criterion: every line carries a keep-or-cut verdict traceable to a named test.

### Description branch (the automated loop)

1. Generate 20 realistic trigger-eval queries — 8–10 should-trigger (varied phrasings, cases that don't name the skill, competitive cases) and 8–10 should-NOT-trigger **near-misses** (shared keywords, adjacent domains — never obviously irrelevant softballs). Concrete and specific: file paths, backstory, typos, casual speech.
2. Self-curate the query set against step 1's near-miss discipline and save it as `eval_set.json` in the workspace. Only if the user explicitly asked to review the eval set: COPY the template `${CLAUDE_SKILL_DIR}/../skill-creation/assets/eval_review.html` into the workspace, fill the copy's placeholders (`__EVAL_DATA_PLACEHOLDER__`, `__SKILL_NAME_PLACEHOLDER__`, `__SKILL_DESCRIPTION_PLACEHOLDER__`) — never edit the shared asset in place — open it, and collect the exported `eval_set.json` from `~/Downloads/`.
3. Run the optimizer in the background from `${CLAUDE_SKILL_DIR}/../skill-creation/`:
   ```bash
   python3 -m scripts.run_loop --eval-set <eval_set.json> --skill-path <skill-path> \
     --model claude-sonnet-5 --max-iterations 5 --verbose
   ```
   It splits 60/40 train/test, measures trigger rates (3 runs per query), proposes improvements, and picks the best description **by held-out test score**. Tail the log periodically and report progress.
4. Apply `best_description` to the frontmatter; show the user before/after and the scores.

### Formatting branch

Apply the standards mechanically: frontmatter keys and limits, imperative voice, reference depth, TOCs, file naming. No meaning changes — if a fix would change meaning, it belongs to another branch or to update-skill.

## Step 4 — Verify proportionally

Per `${CLAUDE_SKILL_DIR}/../skill-creation/references/testing-ladder.md`:

- **Formatting** → tier 1: `python3 tools/validate_skill.py <skill-path>` (from `${CLAUDE_SKILL_DIR}/../skill-creation/`) + `meta-dev:reviewer`; confirm the targeted dimension's score rose and none fell.
- **Bloat** → tier 1, plus tier 2 **micro-test** when behavior-shaping wording was cut (5+ fresh-context reps vs the snapshot; deleted lines must prove they were no-ops).
- **Description** → the run_loop scores ARE the verification; also sanity-check the new description against the standards (third person, trigger-only, ≤500 chars).
- **In doubt whether behavior survived** → blind comparison: run 1–2 representative prompts against snapshot and new version, copy outputs to neutral A/B dirs, spawn `meta-dev:comparator`; new version must win or tie.

Completion criterion: the metric measurably improved, no other dimension regressed, evidence shown to the user.

## Step 5 — Finish

Bump `metadata.version`, log the delta and evidence in the workspace, and name the next-highest-value pass if one is apparent (or hand shape problems to restructure-skill). Then run the mandatory workspace cleanup (eval-pipeline.md §9): archive the snapshot if the skill isn't git-tracked, keep the log, and `rm -rf` the workspace — leave nothing in the skills tree.
