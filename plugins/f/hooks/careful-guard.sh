#!/bin/bash
# PreToolUse hook: block destructive Bash commands in careful mode
# Activated when FACTORY_CAREFUL_MODE=1 is set in the environment
# Reads JSON from stdin (Claude Code hook input format)

# Fast path: if careful mode is not active, allow immediately
if [ "${FACTORY_CAREFUL_MODE:-}" != "1" ]; then
  exit 0
fi

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block rm -rf
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*f[a-zA-Z]*r[a-zA-Z]*|-[a-zA-Z]*r[a-zA-Z]*f[a-zA-Z]*)\s|rm\s+-rf|rm\s+-fr'; then
  echo "BLOCKED: rm -rf is blocked in careful mode" >&2
  exit 2
fi

# Block DROP TABLE or DROP DATABASE (case-insensitive)
if echo "$COMMAND" | grep -qiE 'DROP\s+(TABLE|DATABASE)'; then
  echo "BLOCKED: DROP is blocked in careful mode" >&2
  exit 2
fi

# Block force push
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*(-f\b|--force)'; then
  echo "BLOCKED: force push is blocked in careful mode" >&2
  exit 2
fi

# Block git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "BLOCKED: hard reset is blocked in careful mode" >&2
  exit 2
fi

# Block DELETE FROM without WHERE
if echo "$COMMAND" | grep -qiE 'DELETE\s+FROM\s+\S+\s*;' && ! echo "$COMMAND" | grep -qiE 'DELETE\s+FROM.*WHERE'; then
  echo "BLOCKED: DELETE without WHERE is blocked in careful mode" >&2
  exit 2
fi

# Block kubectl delete
if echo "$COMMAND" | grep -qE 'kubectl\s+delete'; then
  echo "BLOCKED: kubectl delete is blocked in careful mode" >&2
  exit 2
fi

exit 0
