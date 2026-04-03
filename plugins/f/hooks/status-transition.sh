#!/bin/bash
# PreToolUse hook: enforce verification-before-done status transitions
# Intercepts both Linear MCP calls and Linear CLI commands via Bash
#
# ENFORCEMENT RULE:
#   Moving a task to "Done" requires a verification signal file at:
#     ${SIGNAL_PREFIX}{TASK_ID}
#   This file is written by the orchestrator ONLY after a verifier agent returns PASS/WARN.
#   Without the signal file, the transition is BLOCKED.
#
# FLOW: In Progress → Verification → (verifier runs) → Done
#       On FAIL: → back to In Progress (orchestrator re-spawns implementer)
#
# Configuration (set via environment variables to override defaults):
#   SIGNAL_PREFIX  - directory prefix for verification signal files
#                    (default: /tmp/factory-verified-)
#   AUDIT_LOG      - path to the status transition audit log
#                    (default: /tmp/factory-status-audit.log)
#   TASK_ID_PATTERN - regex for valid task IDs (default: [A-Z]+-[0-9]+)

SIGNAL_PREFIX="${SIGNAL_PREFIX:-/tmp/factory-verified-}"
AUDIT_LOG="${AUDIT_LOG:-/tmp/factory-status-audit.log}"
TASK_ID_PATTERN="${TASK_ID_PATTERN:-[A-Z]+-[0-9]+}"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# --- Helper: extract task ID from a command string ---
extract_task_id() {
  echo "$1" | grep -oE "$TASK_ID_PATTERN" | head -1
}

# --- Helper: extract target state from --state "value" or --state value ---
extract_target_state() {
  # Match: --state "Done", --state 'Done', --state Done
  echo "$1" | grep -oE '\-\-state[= ]+["'"'"']?([^"'"'"' ]+)["'"'"']?' | head -1 | sed 's/--state[= ]*//;s/["'"'"']//g'
}

# --- Check for Linear MCP tool calls ---
case "$TOOL_NAME" in
  mcp__linear*)
    TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')
    echo "[status-transition] $(date -Iseconds) Linear MCP call: $TOOL_NAME" >> "$AUDIT_LOG"

    # Check if this is a save_issue call with state change to Done
    STATE_VALUE=$(echo "$INPUT" | jq -r '.tool_input.state // empty')
    ISSUE_ID=$(echo "$INPUT" | jq -r '.tool_input.id // .tool_input.identifier // empty')

    if [ -n "$STATE_VALUE" ]; then
      echo "[status-transition] $(date -Iseconds) MCP state change: $ISSUE_ID -> $STATE_VALUE" >> "$AUDIT_LOG"

      # Extract task ID from issue identifier
      TASK_ID=$(extract_task_id "$ISSUE_ID")

      if echo "$STATE_VALUE" | grep -qi "^done$"; then
        SIGNAL_FILE="${SIGNAL_PREFIX}${TASK_ID}"
        if [ -n "$TASK_ID" ] && [ ! -f "$SIGNAL_FILE" ]; then
          echo "[status-transition] $(date -Iseconds) BLOCKED: $TASK_ID -> Done (no verification signal)" >> "$AUDIT_LOG"
          echo "BLOCKED: Cannot move $TASK_ID to Done without verification."
          echo "Tasks must go through 'Verification' status first."
          echo "The orchestrator writes the signal file after a verifier agent returns PASS."
          echo ""
          echo "Expected signal file: $SIGNAL_FILE"
          echo "To bypass (emergencies only): touch $SIGNAL_FILE"
          exit 2
        fi
        # Signal file exists — allow and clean up
        if [ -n "$TASK_ID" ] && [ -f "$SIGNAL_FILE" ]; then
          rm -f "$SIGNAL_FILE"
          echo "[status-transition] $(date -Iseconds) ALLOWED: $TASK_ID -> Done (signal verified, file removed)" >> "$AUDIT_LOG"
        fi
      fi
    fi
    exit 0
    ;;
esac

# --- Check for Linear CLI commands via Bash ---
if [ "$TOOL_NAME" = "Bash" ]; then
  COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Only intercept commands that contain "linear"
  case "$COMMAND" in
    *linear\ *|*bin/linear\ *)
      echo "[status-transition] $(date -Iseconds) Linear CLI call: $COMMAND" >> "$AUDIT_LOG"

      # Check for state transitions
      TARGET_STATE=$(extract_target_state "$COMMAND")

      if [ -n "$TARGET_STATE" ]; then
        TASK_ID=$(extract_task_id "$COMMAND")
        echo "[status-transition] $(date -Iseconds) CLI state change: $TASK_ID -> $TARGET_STATE" >> "$AUDIT_LOG"

        # Block direct transition to Done without verification signal
        if echo "$TARGET_STATE" | grep -qi "^done$"; then
          SIGNAL_FILE="${SIGNAL_PREFIX}${TASK_ID}"
          if [ -n "$TASK_ID" ] && [ ! -f "$SIGNAL_FILE" ]; then
            echo "[status-transition] $(date -Iseconds) BLOCKED: $TASK_ID -> Done (no verification signal)" >> "$AUDIT_LOG"
            echo "BLOCKED: Cannot move $TASK_ID to Done without verification."
            echo "Tasks must go through 'Verification' status first."
            echo "The orchestrator writes the signal file after a verifier agent returns PASS."
            echo ""
            echo "Expected signal file: $SIGNAL_FILE"
            echo "To bypass (emergencies only): touch $SIGNAL_FILE"
            exit 2
          fi
          # Signal file exists — allow and clean up
          if [ -n "$TASK_ID" ] && [ -f "$SIGNAL_FILE" ]; then
            rm -f "$SIGNAL_FILE"
            echo "[status-transition] $(date -Iseconds) ALLOWED: $TASK_ID -> Done (signal verified, file removed)" >> "$AUDIT_LOG"
          fi
        fi
      fi
      ;;
  esac
fi

exit 0
