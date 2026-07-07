---
name: review-instructions
description: Read-only audit of a project's instruction files (AGENTS.md, CLAUDE.md, .claude/rules) — never edits them. Use to review, check, audit, or diagnose instruction files, verify every documented claim against the actual codebase, find stale or wrong facts, spot cross-file contradictions or bloat, or get a quality report before deciding what to change. Not for applying fixes (update-instructions / improve-instructions) or first-time bootstrap (setup-instructions).
model: sonnet
---

# review-instructions

Look, verify, report — never touch. Instruction files are the one artifact class that makes checkable claims about a real codebase, so this review does what no other review can: it holds every documented fact against ground truth. It produces a diagnosis whose fixes route to update-instructions (drift / wrong facts), improve-instructions (bloat / format), or setup-instructions (missing bootstrap); it never edits the files under review — deep checks may write only to a scratch workspace, never to the files themselves.

Read `${CLAUDE_SKILL_DIR}/../../standards/core.md` and `${CLAUDE_SKILL_DIR}/../../standards/instruction-files.md` first; both are canon and are not restated here.

## Step 1 — Inventory the files and their claims

1. Read the constitution (`AGENTS.md`; confirm `CLAUDE.md` is exactly `@AGENTS.md`) and EVERY reference or rule file it points to. A pointer to a missing file is a critical finding.
2. Extract the **claim list**: every checkable assertion the files make about the project — a named file/dir/route exists, a stack version, a command, an env var, a guard ("never move `app/auth/confirm`"), a code-map entry. Record each claim with the `file:line` it comes from.

Completion criterion: claim list written, each item traced to its source `file:line`.

## Step 2 — Ground-truth audit (the step unique to this review)

For each claim, verify it against the actual repo. This is read-only reconnaissance — Read/Grep/Glob, and Bash only for inspection (`ls`, `cat`, `jq` over `package.json`, `git`) — never an edit:

- **Path / route claims** → the file or directory exists at the stated location (e.g., `app/auth/confirm/route.ts`).
- **Version claims** → match `package.json` (or the lockfile) — flag a stack table that says React 18 when the dep is 19.
- **Command claims** → the script exists in `package.json`'s `scripts`, or is a real binary on `PATH`.
- **Env-var claims** → the key is referenced in code or an `.env.example`.
- **Guard claims** → the guarded thing still exists and the stated reason still holds.

Classify each claim: **confirmed** · **drifted** (documented ≠ reality — record both sides) · **unverifiable** (state why). Drift is the highest-value output: it is exactly what a reader cannot catch from the file alone.

Completion criterion: every claim carries confirmed / drifted / unverifiable with cited repo evidence.

## Step 3 — Standards and cross-file consistency

1. Spawn `meta-dev:reviewer` with `artifact_kind: instruction-files`, the constitution + reference paths, and the two standards paths — for the scored six-dimension report, playbook-order check, and failure-mode diagnosis.
2. **Cross-file consistency**: the same fact must not be stated two ways across constitution and references (single source of truth); every code-map pointer must agree with the reference it names; no reference may contradict the constitution.
3. **Bloat / format**: note no-op lines, duplication, heading-level jumps, bare fences (per `core.md`) — these route to improve-instructions, never fixed here.

Completion criterion: reviewer report in hand; consistency and bloat findings listed with evidence.

## Step 4 — Deliver the report

One report, ordered most-severe first:

```
## Instruction-file review: <repo>
**Verdict**: Pass | Needs Improvement | Needs Major Revision
**Scores**: <reviewer's six dimensions>
**Ground truth**: N claims — X confirmed, Y drifted, Z unverifiable
**Drift** (each: claim → documented vs actual → source file:line)
**Standards / consistency / bloat**: CRITICAL / MAJOR / MINOR, one line + evidence each
**What's accurate**: <genuine positives — always include>
**Routed fixes**:
1. <drifted fact> → meta-dev:update-instructions
2. <bloat / format> → meta-dev:improve-instructions
```

Every drifted fact routes to update-instructions (a fact change — confirm-once); every bloat/format item routes to improve-instructions (hands-free); a missing constitution routes to setup-instructions. Rating rule: any critical (dangling pointer, contradiction, a guard that no longer holds) → Needs Major Revision; any major (drift on a load-bearing fact, playbook violation, duplication) → at most Needs Improvement; Pass requires zero drift and all dimensions ≥4.

Completion criterion: report delivered; the files under review untouched — any write outside the scratch workspace invalidates the review.
