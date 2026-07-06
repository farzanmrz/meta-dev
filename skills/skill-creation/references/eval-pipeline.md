# Eval Pipeline — run, grade, benchmark, review

The empirical-verification choreography shared by create, update, improve, and restructure. The vendored scripts in `scripts/` and `eval-viewer/` implement the mechanical parts; run every `python3 -m scripts.<name>` command with the working directory set to this skill's folder (`skills/skill-creation/`) — the `scripts` package only resolves from there. JSON shapes for evals, grading, benchmark, and comparison live in `schemas.md`; `eval_metadata.json` and `feedback.json` shapes are defined inline below.

## Contents

1. Workspace layout
2. Baseline choice per operation
3. Running (spawn everything at once)
4. Grading
5. Benchmark + analyst
6. Human review (viewer first)
7. Iteration
8. Blind comparison

## 1. Workspace layout

The workspace — `<workspace>` throughout — lives at `~/.claude/skill-workspaces/<skill-name>/` for personal/global skills, or `<project-root>/.skill-workspaces/<skill-name>/` for project skills. **Never place it inside `.claude/skills/`**: a `<skill>-workspace` sibling there clutters the skills folder, and its `skill-snapshot/SKILL.md` can register as a stray skill. Both locations sit outside the guarded `.claude/skills/` tree, so workspace writes and cleanup never trip the skill-guard. The layout below is what `aggregate_benchmark.py` actually consumes — eval directories MUST be named `eval-<descriptive-name>` (the script discovers them with an `eval-*` glob) and each config MUST contain `run-N` subdirectories:

```
<workspace>/   (= ~/.claude/skill-workspaces/<skill-name>/)
├── skill-snapshot/                     # baseline copy (update/improve/restructure)
└── iteration-N/
    └── eval-<descriptive-name>/
        ├── eval_metadata.json          # {"eval_id": 0, "eval_name": "...", "prompt": "...", "assertions": []}
        ├── with_skill/
        │   └── run-1/                  # run-2, run-3 … for variance measurement
        │       ├── outputs/            # the run's produced files
        │       ├── timing.json
        │       └── grading.json
        └── without_skill/ | old_skill/ # same run-N shape
```

Create directories as you go, not upfront. Use a descriptive suffix after the mandatory `eval-` prefix (`eval-multipage-extract`, never bare `eval-0`). Test prompts also live in `evals/evals.json` next to the skill (prompts first; assertions added while runs execute).

## 2. Baseline choice

- **create-skill** → baseline is **no skill** (`without_skill/`).
- **update / improve / restructure** → baseline is **the snapshot** (`old_skill/`), taken BEFORE any edit into `<workspace>/skill-snapshot/`.

The baseline is what makes the numbers mean something: the pass-rate difference against it is the skill's measured value (see the delta-sign warning in section 5).

## 3. Running — spawn everything in the same turn

For each test case spawn TWO subagents in the same turn — with-skill and baseline — so all runs finish together. Subagent prompt template:

```
Execute this task:
- Skill path: <path or "none">
- Task: <eval prompt>
- Input files: <files or "none">
- Save outputs to: <workspace>/iteration-N/eval-<name>/<config>/run-1/outputs/
- Outputs to save: <what matters — "the .docx", "the final CSV">
```

While runs execute, draft the assertions: objectively verifiable, descriptively named, discriminating (pass only when the work was genuinely done). Don't force assertions onto subjective outputs. Update `eval_metadata.json` and `evals/evals.json`, and explain the assertions to the user.

As each run's completion notification arrives, immediately write its timing into `run-N/timing.json` — the notification is the only chance to capture it. Include all three fields (`total_duration_seconds` is the one the aggregator reads; `duration_ms` alone yields time=0.0):

```json
{"total_tokens": 84852, "duration_ms": 23332, "total_duration_seconds": 23.3}
```

## 4. Grading

Spawn `meta-dev:grader` per run (or grade inline for trivial cases) → `grading.json` inside each `run-N/` directory (the grader writes it as a sibling of `outputs/`). The expectations array uses exactly `text`, `passed`, `evidence`. Prefer scripts over eyeballing for programmatically checkable assertions.

## 5. Benchmark + analyst

From `skills/skill-creation/`:

```bash
python3 -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>
```

→ `benchmark.json` + `benchmark.md` (pass rate, time, tokens per configuration; mean ± stddev; delta). **Delta-sign warning**: the script computes delta between configurations in alphabetical order. With a create-mode baseline (`with_skill` vs `without_skill`) the sign reads naturally (positive = skill helps). With an update-mode baseline (`old_skill` vs `with_skill`), `old_skill` sorts first, so the reported delta is baseline-minus-new — flip the sign when reporting. (Left unpatched to keep the vendored script byte-identical; see docs/vendoring.md.)

Then spawn `meta-dev:benchmark-analyst` to surface patterns the aggregates hide (non-discriminating assertions, flaky evals, cost tradeoffs) — its notes join `benchmark.json`. Note: `schemas.md` describes viewer color-grouping for the exact strings `with_skill`/`without_skill`; `old_skill` is accepted by the aggregator and displayed generically.

## 6. Human review — generate the viewer BEFORE judging anything yourself

From `skills/skill-creation/`:

```bash
nohup python3 eval-viewer/generate_review.py <workspace>/iteration-N \
  --skill-name "<name>" --benchmark <workspace>/iteration-N/benchmark.json \
  > /dev/null 2>&1 &   # add --previous-workspace <workspace>/iteration-N-1 from iteration 2 on
```

Headless/no-display: use `--static <out.html>` instead; feedback downloads as `feedback.json` — copy it into the workspace. Never hand-write review HTML. Tell the user: Outputs tab for per-case feedback, Benchmark tab for the numbers. When they say done, read `feedback.json` — shape `{"reviews": [{"run_id": "...", "feedback": "..."}], "status": "complete"}`, empty feedback string = that case looked fine — then kill the server.

## 7. Iteration

Improve → rerun ALL evals into `iteration-N+1/` (baselines included) → relaunch viewer with `--previous-workspace` → read feedback → repeat. While improving: generalize from feedback rather than overfitting to the test cases, keep the prompt lean (read the transcripts — cut what wastes the model's time), explain the why instead of stacking MUSTs, and bundle a script when multiple runs independently wrote the same helper. Stop when the user is happy, feedback is all empty, or progress stalls.

## 8. Blind comparison (when "is it actually better?" needs an unbiased answer)

1. Copy the two outputs to neutral dirs: `compare/A/`, `compare/B/` (randomize which side is which; record the mapping privately). Provenance-leaking paths defeat the blindness.
2. Spawn `meta-dev:comparator` → `comparison.json` with winner + rubric scores (use `comparison-N.json` numbering when several comparisons share a directory, per schemas.md).
3. Spawn `meta-dev:improvement-analyst` with both skills, both transcripts, and the comparison → `analysis.json` with prioritized suggestions for the loser.

## 9. Cleanup (mandatory on finish)

An operation leaves nothing behind in the skills tree and no stray workspace:

1. If the edited skill is **not** git-tracked, preserve rollback: `cp -r <workspace>/skill-snapshot ~/.claude/skill-archive/<skill-name>-<date>` (git-tracked skills already have their history as the archive).
2. Keep the one-line evidence log (`IMPROVE-LOG.md` / change log) — copy it into the archive alongside the snapshot.
3. `rm -rf <workspace>`.

Skip cleanup only while an operation is still iterating; run it once the change is applied-and-verified or rolled back.
