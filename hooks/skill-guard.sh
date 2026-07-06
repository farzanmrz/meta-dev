#!/bin/bash
# meta-dev guard v3 — two-tier gates routing artifact mutations through the
# meta-dev:skill-creation router. Covers three surfaces:
#   skills  (*.claude/skills/*)  — two-tier: hard-deny create/delete/Write/
#                                  large edits; allow+nudge single small edits
#   agents  (*.claude/agents/*)  — same two-tier
#   hooks   (hooks.json anywhere; settings*.json edits touching hook config)
#                                — hard only: hook config is prevention
#                                  machinery, a wrong edit disables guarantees
# Unlock: any meta-dev:* skill invoked this session (PostToolUse witness).
# meta-dev's own non-skill internals (standards/ hooks/ agents/ docs/ tools/
# + the skill-creation harness) are exempt; its skills/ gate like any skill.
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
# stripped before testing for '>').
if [ "$TOOL" = "Bash" ]; then
  CHECK="$(printf '%s' "$CMD" | sed -E 's@[0-9]*>+[[:space:]]*(/dev/null|/dev/stdout|/dev/stderr|&[0-9])@@g')"
  if ! printf '%s' "$CHECK" | grep -qE '(^|[;&|[:space:]$(])(mkdir|touch|rm|rmdir|mv|cp|tee|rsync|ln|truncate|install|dd|chmod|chown)([[:space:]]|$)|sed[[:space:]]+-[^[:space:]]*i|perl[[:space:]]+-[^[:space:]]*i|>|git[[:space:]]+(checkout|restore|clean|rm|mv)'; then
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

# ---- Surface 1: skills ----
GATE_SKILLS=0
case "$TARGET" in
  *".claude/skills/$PNAME/skills/"*) GATE_SKILLS=1 ;;
  *".claude/skills/$PNAME/"*)        : ;;             # meta-dev internals exempt
  *.claude/skills/*)                 GATE_SKILLS=1 ;;
esac
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
if [ ! -f "$(marker)" ]; then
  case "$TARGET" in
    *.claude/agents/*)
      [ "$TOOL" = "Edit" ] && small_edit "meta-dev guard: small edit to an agent allowed without the lifecycle. If this changed delegation behavior, tools, or the return contract, run meta-dev:review-agent afterward or route substantive work through meta-dev:skill-creation. Standards: ~/.claude/skills/meta-dev/standards/agent.md."
      classify_op
      case "$OP" in
        delete) H="This looks like DELETING an agent — the router dispatches retire-agent." ;;
        create) H="This looks like CREATING an agent — the router dispatches create-agent." ;;
        *)      H="This looks like a substantive agent EDIT — the router dispatches update-agent or improve-agent." ;;
      esac
      deny "meta-dev guard: this operation touches an agent under .claude/agents/. Invoke 'meta-dev:skill-creation' FIRST via the Skill tool, then retry — it will be allowed for the rest of the session. $H"
      ;;
  esac
fi

# ---- Surface 3: hook configuration (hard tier only) ----
if [ ! -f "$(marker)" ]; then
  HOOKISH=0
  BASE="$(basename "$FILE")"
  case "$FILE" in "$PLUGIN_ROOT"/*) BASE="" ;; esac   # meta-dev's own hooks exempt
  [ "$BASE" = "hooks.json" ] && HOOKISH=1
  if printf '%s' "$BASE" | grep -qE '^settings(\.local)?\.json$'; then
    printf '%s %s' "$CONTENT" "$CMD" | grep -qE '"hooks"|PreToolUse|PostToolUse|UserPromptSubmit|SessionStart|SessionEnd|SubagentStop|PreCompact' && HOOKISH=1
  fi
  if [ -n "$CMD" ] && printf '%s' "$CMD" | grep -qE 'hooks\.json|settings(\.local)?\.json.*(hook|PreToolUse|PostToolUse)' && ! printf '%s' "$CMD" | grep -q "$PLUGIN_ROOT"; then
    HOOKISH=1
  fi
  [ "$HOOKISH" = 1 ] && deny "meta-dev guard: this operation modifies hook configuration (hooks.json or a settings.json hooks block). Hook config is prevention machinery, so no small-edit tier applies. Invoke 'meta-dev:skill-creation' FIRST via the Skill tool — it dispatches create-hook (authoring) or review-hook (auditing) — then retry; allowed for the rest of the session."
fi

exit 0
