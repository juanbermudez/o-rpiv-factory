#!/bin/bash
# PreToolUse hook: block Edit/Write/Bash if task has unresolved dependencies
# The orchestrator sets FACTORY_TASK_CONTEXT env var pointing to the task's .json file

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only gate write tools
case "$TOOL_NAME" in
  Edit|Write|Bash) ;;
  *) exit 0 ;;
esac

# Check for task context environment variable
TASK_CONTEXT="${FACTORY_TASK_CONTEXT:-}"
if [ -z "$TASK_CONTEXT" ] || [ ! -f "$TASK_CONTEXT" ]; then
  exit 0  # No task context, allow (might be non-task work)
fi

# Get project slug from context
PROJECT_SLUG=$(jq -r '.project_slug // empty' "$TASK_CONTEXT")
if [ -z "$PROJECT_SLUG" ]; then
  exit 0
fi

# Read blockedBy dependencies from task context
DEPS=$(jq -r '.depends_on[]? // empty' "$TASK_CONTEXT" 2>/dev/null)

for DEP in $DEPS; do
  DEP_FILE=".resources/context/${PROJECT_SLUG}/tasks/${DEP}.json"
  if [ -f "$DEP_FILE" ]; then
    DEP_STATUS=$(jq -r '.status // "unknown"' "$DEP_FILE")
    if [ "$DEP_STATUS" != "Done" ] && [ "$DEP_STATUS" != "complete" ] && [ "$DEP_STATUS" != "Archived" ]; then
      echo "BLOCKED: Dependency ${DEP} is not complete (status: ${DEP_STATUS}). This task cannot proceed until all dependencies are resolved." >&2
      exit 2
    fi
  fi
done

exit 0
