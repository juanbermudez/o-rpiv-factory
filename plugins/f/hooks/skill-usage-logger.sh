#!/bin/bash
# PreToolUse hook: log skill invocations for usage analytics
# Reads JSON from stdin (Claude Code hook input format)
# Always exits 0 — this is a logger, not a guard

# Require CLAUDE_PLUGIN_DATA to be set
if [ -z "${CLAUDE_PLUGIN_DATA:-}" ]; then
  exit 0
fi

INPUT=$(cat)
SKILL_NAME=$(echo "$INPUT" | jq -r '.tool_input.name // empty')

# Only process Skill tool calls with a name
if [ -z "$SKILL_NAME" ]; then
  exit 0
fi

DATA_DIR="${CLAUDE_PLUGIN_DATA}/f"
mkdir -p "$DATA_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"

printf '{"timestamp":"%s","skill_name":"%s","session_id":"%s"}\n' \
  "$TIMESTAMP" "$SKILL_NAME" "$SESSION_ID" \
  >> "${DATA_DIR}/skill-usage.jsonl"

exit 0
