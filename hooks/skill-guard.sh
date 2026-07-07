#!/bin/bash
# meta-dev guard v6 — gates routing artifact mutations through the
# meta-dev:skill-creation router. Covers five surfaces:
#   skills  (*.claude/skills/*)  — two-tier: hard-deny create/delete/Write/
#                                  large edits; allow+nudge single small edits
#   agents  (*.claude/agents/*)  — same two-tier
#   hooks   (hooks.json anywhere; settings*.json edits touching hook config)
#                                — hard only: hook config is prevention
#                                  machinery, a wrong edit disables guarantees
#   instr   (CLAUDE.md / AGENTS.md anywhere)
#                                — soft nudge: a reminder that the lifecycle and
#                                  /meta-dev:revise-agents-md exist, then the edit
#                                  is allowed. A constitution is living docs, not
#                                  prevention machinery; keep it low-friction.
#   upstream(any skill folder carrying an .upstream marker)
#                                — hard AND unlock-independent: vendored skills
#                                  are never edited locally (edits drift from
#                                  source, vanish on re-sync). Escape: remove the
#                                  .upstream marker (deliberate un-vendoring).
# Unlock: any meta-dev:* skill invoked this session (PostToolUse witness) —
# lifts surfaces 1-3 and silences surface 4's nudge; the upstream surface
# ignores it by design.
# Bash matching is operand-adjacency based (cmd_mutates): a path/file is gated
# only when it is a redirect target or the operand of a create/delete/move verb,
# never a bare mention (a commit message naming AGENTS.md must not trip).
# meta-dev's own non-skill internals (standards/ hooks/ agents/ docs/ tools/
# + the skill-creation harness) are exempt via PLUGIN_ROOT; its skills/ gate.
set -uo pipefail

MODE="${1:-guard}"
INPUT="$(cat)"

# Fail open if jq is missing — never brick tool use over a parsing dependency.
command -v jq >/dev/null 2>&1 || exit 0

SESSION_ID="$(jq -r '.session_id // "unknown"' <<<"$INPUT")"
STATE_DIR="/tmp/meta-dev-guard"
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
marker() { printf '%s/%s.skills' "$STATE_DIR" "$SESSION_ID"; }

if [ "$MODE" = "record" ]; then
  SKILL="$(jq -r '.tool_input.skill // ""' <<<"$INPUT")"
  case "$SKILL" in meta-dev:*) touch "$(marker)" ;; esac
  exit 0
fi

# ---- guard mode ----
printf '%s\n' "$SESSION_ID" > "$STATE_DIR/last-session" 2>/dev/null

TOOL="$(jq -r '.tool_name // ""' <<<"$INPUT")"
FILE="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$INPUT")"
CMD=""
[ "$TOOL" = "Bash" ] && CMD="$(jq -r '.tool_input.command // ""' <<<"$INPUT")"
CONTENT="$(jq -r '(.tool_input.content // "") + " " + (.tool_input.new_string // "") + " " + (.tool_input.old_string // "")' <<<"$INPUT")"

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." 2>/dev/null && pwd)"
PNAME="$(basename "$PLUGIN_ROOT")"

# Read-only Bash passes freely; only mutating Bash is gated (discard-redirects
# stripped first; a bare '>' counts only as a real redirect with a target, so
# the '>' inside <email>, '->', '=>' don't misclassify a non-mutating command).
if [ "$TOOL" = "Bash" ]; then
  CHECK="$(printf '%s' "$CMD" | sed -E 's@[0-9]*>+[[:space:]]*(/dev/null|/dev/stdout|/dev/stderr|&[0-9])@@g')"
  if ! printf '%s' "$CHECK" | grep -qE '(^|[;&|[:space:]$(])(mkdir|touch|rm|rmdir|mv|cp|tee|rsync|ln|truncate|install|dd|chmod|chown)([[:space:]]|$)|sed[[:space:]]+-[^[:space:]]*i|perl[[:space:]]+-[^[:space:]]*i|(^|[^-=<>&|])[0-9]?>>?[[:blank:]]*[^[:space:]&|;<>()]|git[[:space:]]+(checkout|restore|clean|rm|mv)'; then
    exit 0
  fi
fi

TARGET="$FILE $CMD"

deny() {
  jq -n --arg r "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

# Small-Edit tier-2: allow with a nudge (used by skills and agents surfaces).
small_edit() {  # $1 = nudge text; call only for TOOL=Edit
  local rall elen
  rall="$(jq -r '.tool_input.replace_all // false' <<<"$INPUT")"
  elen="$(jq -r '((.tool_input.old_string // "") | length) + ((.tool_input.new_string // "") | length)' <<<"$INPUT")"
  if [ "$rall" != "true" ] && [ "${elen:-9999}" -lt 600 ] 2>/dev/null; then
    jq -n --arg m "$1" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"allow",permissionDecisionReason:"meta-dev guard: small edit allowed (tier 2)"},systemMessage:$m}'
    exit 0
  fi
}

# True if CMD actually mutates a path matching ERE $1 — a redirect target, the
# first non-flag operand of a create/delete/move verb, or a git rm/mv operand —
# not a bare mention. Reads are already filtered out above for Bash.
cmd_mutates() {  # $1 = ERE for the path/filename to protect
  [ -n "$CMD" ] || return 1
  local p="$1"
  printf '%s' "$CMD" | grep -qE "(>>?[[:blank:]]*[^[:space:]|;&()]*${p}|(^|[;&|]|[[:space:]])(rm|rmdir|mv|cp|shred|mkdir|touch|install|tee|ln|dd)([[:space:]]+-[^[:space:]]+)*[[:space:]]+[^[:space:]|;&()]*${p}|git[[:space:]]+(rm|mv)([[:space:]]+-[^[:space:]]+)*[[:space:]]+[^[:space:]|;&()]*${p})"
}

classify_op() {  # sets OP from tool/command shape
  OP="edit"
  if [ "$TOOL" = "Bash" ]; then
    local del
    del="$(printf '%s' "$CMD" | sed -E 's@[0-9]*>+[[:space:]]*(/dev/null|/dev/stdout|/dev/stderr|&[0-9])@@g')"
    if printf '%s' "$del" | grep -qE '(^|[;&|[:space:]$(])(rm|rmdir)([[:space:]]|$)|git[[:space:]]+rm'; then
      OP="delete"
    elif printf '%s' "$del" | grep -qE '(^|[;&|[:space:]$(])mkdir([[:space:]]|$)'; then
      OP="create"
    fi
  elif [ "$TOOL" = "Write" ] && [ -n "$FILE" ] && [ ! -f "$FILE" ]; then
    OP="create"
  fi
}

# ---- Surface 5 (runs first): upstream / vendored skills — hard & unlock-independent ----
# A skill folder carrying an `.upstream` marker is vendored and never edited
# locally. Deterministic: only marked folders block. The marker file itself may
# be touched (deliberate un-vendoring); a new skill folder is never blocked here.
US_HIT=""
US_CANDS="$FILE"
[ -n "$CMD" ] && cmd_mutates '\.claude/skills/' && US_CANDS="$US_CANDS $CMD"
for pth in $(printf '%s\n' "$US_CANDS" | grep -oE '[^[:space:]"'"'"']*\.claude/skills/[^[:space:]"'"'"'/]+' 2>/dev/null); do
  case "$pth" in "$PLUGIN_ROOT"/*) continue ;; esac
  us_pfx="${pth%%.claude/skills/*}.claude/skills/"
  us_nm="${pth#*.claude/skills/}"; us_nm="${us_nm%%/*}"
  [ -n "$us_nm" ] && [ -f "${us_pfx}${us_nm}/.upstream" ] && US_HIT="${us_pfx}${us_nm}"
done
if [ -n "$US_HIT" ]; then
  case "$TARGET" in
    *"/.upstream"*) : ;;   # allow touching the marker itself (un-vendor / stamp)
    *) deny "meta-dev guard: '$US_HIT' is a vendored upstream skill (.upstream marker present). Vendored skills are never edited locally — changes drift from the source and are lost on re-sync. Re-source or update it upstream (meta-dev:skill-creation routes to find-skills). To adopt it as a project-owned skill, delete its .upstream marker first (a deliberate un-vendoring); to build on it, author a new skill instead." ;;
  esac
fi

# ---- Surface 1: skills ----
GATE_SKILLS=0
case "$FILE" in
  *".claude/skills/$PNAME/skills/"*) GATE_SKILLS=1 ;;
  *".claude/skills/$PNAME/"*)        : ;;             # meta-dev internals exempt
  *.claude/skills/*)                 GATE_SKILLS=1 ;;
esac
[ "$GATE_SKILLS" = 0 ] && cmd_mutates '\.claude/skills/' && GATE_SKILLS=1
if [ "$GATE_SKILLS" = 1 ] && [ ! -f "$(marker)" ]; then
  [ "$TOOL" = "Edit" ] && small_edit "meta-dev guard: small edit to a skill allowed without the lifecycle. If this changed behavior (steps, rules, triggers), run meta-dev:review-skill afterward or route substantive work through meta-dev:skill-creation. Standards: ~/.claude/skills/meta-dev/standards/."
  classify_op
  case "$OP" in
    delete) H="This looks like DELETING a skill — the router dispatches retire-skill." ;;
    create) H="This looks like CREATING a skill — the router dispatches create-skill." ;;
    *)      H="This looks like a substantive skill EDIT — the router dispatches update-skill, improve-skill, or restructure-skill." ;;
  esac
  deny "meta-dev guard: this operation touches a skill under .claude/skills/. Invoke 'meta-dev:skill-creation' FIRST via the Skill tool, then retry — it will be allowed for the rest of the session. $H"
fi

# ---- Surface 2: agents ----
GATE_AGENTS=0
case "$FILE" in *.claude/agents/*) GATE_AGENTS=1 ;; esac
[ "$GATE_AGENTS" = 0 ] && cmd_mutates '\.claude/agents/' && GATE_AGENTS=1
if [ "$GATE_AGENTS" = 1 ] && [ ! -f "$(marker)" ]; then
  [ "$TOOL" = "Edit" ] && small_edit "meta-dev guard: small edit to an agent allowed without the lifecycle. If this changed delegation behavior, tools, or the return contract, run meta-dev:review-agent afterward or route substantive work through meta-dev:skill-creation. Standards: ~/.claude/skills/meta-dev/standards/agent.md."
  classify_op
  case "$OP" in
    delete) H="This looks like DELETING an agent — the router dispatches retire-agent." ;;
    create) H="This looks like CREATING an agent — the router dispatches create-agent." ;;
    *)      H="This looks like a substantive agent EDIT — the router dispatches update-agent or improve-agent." ;;
  esac
  deny "meta-dev guard: this operation touches an agent under .claude/agents/. Invoke 'meta-dev:skill-creation' FIRST via the Skill tool, then retry — it will be allowed for the rest of the session. $H"
fi

# ---- Surface 3: hook configuration (hard tier only) ----
if [ ! -f "$(marker)" ]; then
  HOOKISH=0
  BASE="$(basename "$FILE")"
  case "$FILE" in "$PLUGIN_ROOT"/*) BASE="" ;; esac   # meta-dev's own hooks exempt
  [ "$BASE" = "hooks.json" ] && HOOKISH=1
  if printf '%s' "$BASE" | grep -qE '^settings(\.local)?\.json$'; then
    printf '%s' "$CONTENT" | grep -qE '"hooks"|PreToolUse|PostToolUse|UserPromptSubmit|SessionStart|SessionEnd|SubagentStop|PreCompact' && HOOKISH=1
  fi
  if [ -n "$CMD" ] && ! printf '%s' "$CMD" | grep -q "$PLUGIN_ROOT"; then
    cmd_mutates 'hooks\.json' && HOOKISH=1
    cmd_mutates 'settings(\.local)?\.json' && printf '%s' "$CMD" | grep -qE 'hook|PreToolUse|PostToolUse' && HOOKISH=1
  fi
  [ "$HOOKISH" = 1 ] && deny "meta-dev guard: this operation modifies hook configuration (hooks.json or a settings.json hooks block). Hook config is prevention machinery, so no small-edit tier applies. Invoke 'meta-dev:skill-creation' FIRST via the Skill tool — it dispatches create-hook (authoring) or review-hook (auditing) — then retry; allowed for the rest of the session."
fi

# ---- Surface 4: instruction files (soft nudge — never blocks) ----
# CLAUDE.md / AGENTS.md are living documentation, not prevention machinery, so a
# hard gate here made keeping them current a chore. On a direct edit we only
# remind that the lifecycle (and the full-surface /meta-dev:revise-agents-md
# tune-up) exists, then let the edit through — no deny, no permission override
# (systemMessage only, so normal permission flow still applies). Silent once any
# meta-dev:* skill has unlocked the session. Basename match catches Write/Edit
# anywhere; Bash gated by cmd_mutates so a commit-message mention won't trip.
if [ ! -f "$(marker)" ]; then
  INSTR=0
  IBASE="$(basename "$FILE")"
  case "$FILE" in "$PLUGIN_ROOT"/*) IBASE="" ;; esac
  case "$IBASE" in CLAUDE.md|AGENTS.md) INSTR=1 ;; esac
  if cmd_mutates '(CLAUDE|AGENTS)\.md' && ! printf '%s' "$CMD" | grep -q "$PLUGIN_ROOT"; then
    INSTR=1
  fi
  if [ "$INSTR" = 1 ]; then
    jq -n --arg m "meta-dev: editing a project instruction file (CLAUDE.md / AGENTS.md) — allowed; this is a nudge, not a block. For a full correctness + de-dup + format tune-up of the whole context surface against the codebase, run /meta-dev:revise-agents-md. For one scoped change, meta-dev:skill-creation routes to update- or improve-instructions." \
      '{systemMessage:$m}'
  fi
fi

exit 0
