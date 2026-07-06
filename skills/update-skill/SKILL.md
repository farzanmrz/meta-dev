---
name: update-skill
description: Extend or change an EXISTING skill's behavior to meet new requirements. Use when the user asks to add functionality, cover a new case, change what a skill does, or fold new knowledge into a skill — any behavioral edit. Not for quality-only cleanups with unchanged behavior (improve-skill) and not for reorganizing files across skills (restructure-skill).
model: sonnet
---

# update-skill

Change what a skill does without silently breaking what it already did. The two failure modes this pipeline exists to prevent: regressions in preserved behavior, and updates that quietly turn into rewrites. Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/skill.md` before editing.

## Step 0 — Provenance gate

Before anything, settle whether the target is project-owned or upstream/vendored (`skill.md`'s Provenance section). If the folder carries an `.upstream` marker, the skill is installable via `find-skills` / a known registry, or its SKILL.md reads as upstream package docs rather than project instructions: **stop — do not edit**. Report it as vendored, stamp an `.upstream` marker if one is missing (naming the source + re-sync command), and route the user to re-source or fix it upstream. Only a project-owned skill proceeds.

Completion criterion: target confirmed project-owned, or handed back as vendored with the marker stamped.

## Step 1 — Capture the current contract

1. Read the skill completely: SKILL.md and every bundled file.
2. Write down the **regression list**: the behaviors that must survive the update, as concrete statements ("extracts tables from multi-page PDFs", "never sends without confirmation").
3. Confirm the operation is genuinely an update: intended behavior changes. If only quality changes, hand to improve-skill; if the shape is the problem, hand to restructure-skill.

Completion criterion: regression list written and the update/improve/restructure boundary explicitly settled.

## Step 2 — Diff the requirements

State precisely what is new: added capability, changed behavior, removed behavior. Ask the user to confirm the diff — the diff, not the whole skill, is the scope of this edit. This is the ONLY consultation in the pipeline; when the request itself already states the diff unambiguously ("add this example", "also handle X"), treat it as confirmed and don't re-ask. Everything after this step runs without asking.

## Step 3 — Snapshot

`mkdir -p ~/.claude/skill-workspaces/<skill-name> && cp -r <skill-path> ~/.claude/skill-workspaces/<skill-name>/skill-snapshot` (workspace location per eval-pipeline.md §1 — never inside `.claude/skills/`).

The snapshot is the eval baseline and the rollback point. Never edit without it.

## Step 4 — Edit minimally

Apply the diff and nothing else. Keep each meaning single-sourced; put new detail at the right level of the loading hierarchy (inline only what every run needs). Resist drive-by rewording of tuned content — wording that survived earlier testing is load-bearing until proven otherwise. If the skill's frontmatter omits `model:` entirely, or uses `fable` the user didn't choose, fix it per core.md's Model assignment — a deliberate `inherit` is valid and stays. This is a safe, in-scope correction.

Completion criterion: every requirement in the diff is implemented; nothing outside the diff changed.

## Step 5 — Static review

1. `python3 tools/validate_skill.py <skill-path>` (run from `${CLAUDE_SKILL_DIR}/../skill-creation/`).
2. Spawn `meta-dev:reviewer`; fix critical/major findings.

This step is mandatory even for one-line additions — it is how the standards apply uniformly instead of only when someone remembers. Apply behavior-preserving fixes the review surfaces (formatting, model pin, description length, duplication introduced by the diff) autonomously in the same pass; only behavior-changing findings go back to the user.

## Step 6 — Verify: new behavior AND old

Behavioral change means tier 3 of `${CLAUDE_SKILL_DIR}/../skill-creation/references/testing-ladder.md` — run the eval pipeline per `${CLAUDE_SKILL_DIR}/../skill-creation/references/eval-pipeline.md` with baseline = **the snapshot** (`old_skill/`), and evals of BOTH kinds:

- **New-behavior evals**: 1–2 prompts exercising the added capability. Expected: new version passes, snapshot fails — proof the update does something.
- **Regression evals**: 1–2 prompts from the regression list. Expected: both versions pass — proof nothing broke.

Grade with `meta-dev:grader`, aggregate the benchmark, and put results in front of the user with the viewer. A regression eval failing on the new version blocks completion — fix before proceeding. For a close call on whether the new version is actually better overall, run a blind comparison (`meta-dev:comparator`, then `meta-dev:improvement-analyst`).

Completion criterion: new-behavior evals pass on the new version; every regression eval passes; user has reviewed.

## Step 7 — Finish

1. Bump `metadata.version` in frontmatter; commit if the skill is git-tracked (the diff message is the changelog).
2. Append the change and its evidence to the workspace log.
3. Run the mandatory workspace cleanup (eval-pipeline.md §9): archive the snapshot if the skill isn't git-tracked, keep the log, and `rm -rf` the workspace.
4. If the update grew the skill near its budgets, recommend restructure-skill; if the description no longer covers the new triggers, recommend improve-skill's description branch.
