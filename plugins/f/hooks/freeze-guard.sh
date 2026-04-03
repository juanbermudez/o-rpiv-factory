#!/bin/bash
# PreToolUse hook: block Edit/Write outside the frozen directory
# Activated when FACTORY_FREEZE_DIR is set in the environment
# Reads JSON from stdin (Claude Code hook input format)

# Fast path: if freeze mode is not active, allow immediately
FREEZE_DIR="${FACTORY_FREEZE_DIR:-}"
if [ -z "$FREEZE_DIR" ]; then
  exit 0
fi

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Determine the file path being operated on
case "$TOOL_NAME" in
  Edit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  Write)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    ;;
  *)
    exit 0
    ;;
esac

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Resolve absolute path for comparison
ABS_FILE=$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
ABS_FREEZE=$(realpath "$FREEZE_DIR" 2>/dev/null || echo "$FREEZE_DIR")

# Check if file is within the frozen directory
# Add trailing slash to FREEZE_DIR to prevent prefix false-positives (e.g. /foo vs /foobar)
case "$ABS_FILE" in
  "$ABS_FREEZE"/*)
    # File is inside the freeze directory — allow
    exit 0
    ;;
  "$ABS_FREEZE")
    # File IS the freeze directory itself — allow
    exit 0
    ;;
  *)
    echo "BLOCKED: edits restricted to ${FREEZE_DIR} in freeze mode" >&2
    exit 2
    ;;
esac
