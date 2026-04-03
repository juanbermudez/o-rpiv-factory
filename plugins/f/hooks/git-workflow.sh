#!/bin/bash
# PreToolUse hook: enforce git workflow rules for implementation agents
# Reads JSON from stdin (Claude Code hook input format)
#
# Configuration (set via environment variables to override defaults):
#   TASK_ID_PATTERN  - regex pattern for valid task IDs (default: [A-Z]+-[0-9]+)
#                      e.g. export TASK_ID_PATTERN="PROJ-[0-9]+" for a single prefix

TASK_ID_PATTERN="${TASK_ID_PATTERN:-[A-Z]+-[0-9]+}"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only process git commands
if ! echo "$COMMAND" | grep -qE '^\s*git\s'; then
  exit 0
fi

# Block force push
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force'; then
  echo "Blocked: Force push is not allowed. Use regular push." >&2
  exit 2
fi

# Block reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  echo "Blocked: Hard reset is not allowed. Use git stash or git checkout for specific files." >&2
  exit 2
fi

# Block clean -f
if echo "$COMMAND" | grep -qE 'git\s+clean\s+-f'; then
  echo "Blocked: Force clean is not allowed." >&2
  exit 2
fi

# Block commits directly to main
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$BRANCH" = "main" ] && echo "$COMMAND" | grep -qE 'git\s+commit'; then
  echo "Blocked: Cannot commit directly to main. Create a feature branch: git checkout -b feat/PROJ-XXX-description" >&2
  exit 2
fi

# Enforce commit message references task ID
if echo "$COMMAND" | grep -qE 'git\s+commit'; then
  if ! echo "$COMMAND" | grep -qE "$TASK_ID_PATTERN"; then
    echo "Blocked: Commit message must reference a task ID (e.g. PROJ-123). Format: feat(scope): PROJ-123 description" >&2
    exit 2
  fi
fi

# Enforce branch naming on checkout -b
if echo "$COMMAND" | grep -qE 'git\s+checkout\s+-b'; then
  BRANCH_NAME=$(echo "$COMMAND" | grep -oP 'checkout\s+-b\s+\K\S+')
  if [ -n "$BRANCH_NAME" ] && ! echo "$BRANCH_NAME" | grep -qE "^feat/${TASK_ID_PATTERN}-"; then
    echo "Blocked: Branch name must follow pattern: feat/PROJ-XXX-description (e.g., feat/PROJ-101-user-auth-api)" >&2
    exit 2
  fi
fi

# Block --no-verify
if echo "$COMMAND" | grep -qE '--no-verify'; then
  echo "Blocked: --no-verify is not allowed. Fix the issue that's causing the hook to fail." >&2
  exit 2
fi

exit 0
