#!/bin/bash
# meta-dev md-format — nudge-only markdown standards check (PostToolUse on
# Write|Edit|MultiEdit|NotebookEdit). Never blocks: emits a systemMessage
# listing deterministic violations of standards/core.md so the session
# self-corrects, and flags an instruction-file constitution outgrowing the
# ~200-line ladder threshold (standards/instruction-files.md).
set -uo pipefail
command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"
FILE="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // ""' <<<"$INPUT")"

case "$FILE" in
  *.md) : ;;
  *) exit 0 ;;
esac
case "$FILE" in
  */node_modules/*|*/.git/*|*/skill-workspaces/*|*/skill-archive/*) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0

ISSUES=""

# Heading-level jumps (### after #, etc.), ignoring fenced code blocks.
JUMPS="$(awk '
  /^```/ { fence = !fence; next }
  fence { next }
  /^#{1,6} / {
    lvl = 0; for (i = 1; substr($0, i, 1) == "#"; i++) lvl++
    if (prev && lvl > prev + 1) n++
    prev = lvl
  }
  END { print n + 0 }' "$FILE")"
[ "$JUMPS" -gt 0 ] && ISSUES="$ISSUES ${JUMPS} heading-level jump(s);"

# Opening fences without a language tag (closing fences are bare by design).
BAREFENCE="$(awk '
  /^```/ {
    fence = !fence
    if (fence && $0 == "```") n++
  }
  END { print n + 0 }' "$FILE")"
[ "$BAREFENCE" -gt 0 ] && ISSUES="$ISSUES ${BAREFENCE} code fence(s) missing a language tag;"

# Constitution size — the growth-ladder trigger.
BASE="$(basename "$FILE")"
if [ "$BASE" = "AGENTS.md" ] || [ "$BASE" = "CLAUDE.md" ]; then
  LINES="$(wc -l < "$FILE" | tr -d ' ')"
  if [ "$LINES" -gt 200 ]; then
    ISSUES="$ISSUES constitution is ${LINES} lines (>200) — consider graduating an area per the growth ladder (meta-dev standards/instruction-files.md);"
  fi
fi

[ -z "$ISSUES" ] && exit 0

jq -n --arg m "md-format (nudge, non-blocking): $(basename "$FILE"):${ISSUES%%;} — standards: ~/.claude/skills/meta-dev/standards/core.md" \
  '{systemMessage:$m}'
exit 0
