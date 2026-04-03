---
name: plugin-memory
description: >
  Cross-session memory for the factory plugin. Stores project history, failure
  patterns, and user preferences in ${CLAUDE_PLUGIN_DATA}/f/. Skills read and
  write to persistent JSONL logs and config.json.
---

# Plugin Memory Skill

## What is CLAUDE_PLUGIN_DATA?

`CLAUDE_PLUGIN_DATA` is an environment variable provided by Claude Code that points to a stable directory persisting across plugin updates and reinstalls. It is NOT the plugin source directory — it is a separate, user-owned data directory.

Typical value: `~/.claude/plugins/data/`

The factory plugin stores its data under the `f/` subdirectory:

```
${CLAUDE_PLUGIN_DATA}/f/
  config.json              # User preferences
  project-history.jsonl    # Append-only log of completed projects
  failure-patterns.jsonl   # Append-only log of quality gate failures
```

## Setup

Before any read or write, ensure the directory exists:

```bash
mkdir -p "${CLAUDE_PLUGIN_DATA}/f/"
```

Always check that `CLAUDE_PLUGIN_DATA` is set before using it:

```bash
if [ -z "${CLAUDE_PLUGIN_DATA}" ]; then
  echo "CLAUDE_PLUGIN_DATA is not set — skipping plugin memory"
  exit 0
fi
```

## Data Files

### config.json

User preferences read at session start by the planner.

**Schema:**

```json
{
  "default_initiative": "My Initiative",
  "default_team_key": "YOUR_TEAM_KEY",
  "preferred_model_overrides": {
    "implementer": "claude-sonnet-4-6",
    "planner": "claude-opus-4-6"
  },
  "auto_compound": true
}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `default_initiative` | string | Default Linear initiative for new projects |
| `default_team_key` | string | Default Linear team key (e.g., "ENG", "PROD", "DEV") |
| `preferred_model_overrides` | object | Per-agent model overrides (agent name → model ID) |
| `auto_compound` | boolean | Whether to auto-run compound after task verification |

**If config.json is missing**, prompt the user via `AskUserQuestion` and save their answers. Do NOT silently skip or use hardcoded defaults.

Example prompt:
> "Plugin config not found. What are your preferences?
> 1. Default Linear initiative (e.g., 'Q1 Product Work')
> 2. Default team key (e.g., 'ENG', 'PROD', 'DEV')
> 3. Auto-compound after verification? (yes/no)"

---

### project-history.jsonl

Append-only log of projects worked on. One JSON object per line.

**Schema (one line per project):**

```json
{
  "timestamp": "2026-03-17T14:23:00Z",
  "project_slug": "income-verification-enhancements",
  "project_name": "Income Verification Enhancements",
  "task_count": 8,
  "tasks_completed": 8,
  "outcome": "completed",
  "duration_minutes": 142
}
```

**Fields:**

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `timestamp` | string | ISO 8601 | When the entry was written |
| `project_slug` | string | kebab-case | Linear project slug |
| `project_name` | string | | Human-readable project name |
| `task_count` | number | | Total tasks in project |
| `tasks_completed` | number | | Tasks that reached `complete` status |
| `outcome` | string | `completed`, `paused`, `canceled` | Final project outcome |
| `duration_minutes` | number | | Elapsed time from first task start to compound |

**Written by:** compound methodology after successful learning extraction.

---

### failure-patterns.jsonl

Append-only log of quality gate failures during implementation. One JSON object per line.

**Schema (one line per failure):**

```json
{
  "timestamp": "2026-03-17T10:05:00Z",
  "task_id": "TASK-1512",
  "failure_type": "typecheck",
  "error_summary": "Type 'string' is not assignable to type 'number' in Order.amount_cents",
  "resolution": "Changed field type annotation from string to number; amount_cents stores monetary value as integer"
}
```

**Fields:**

| Field | Type | Values | Description |
|-------|------|--------|-------------|
| `timestamp` | string | ISO 8601 | When the failure occurred |
| `task_id` | string | | Linear task ID (e.g., "TASK-1512") |
| `failure_type` | string | `lint`, `typecheck`, `test`, `build` | Which quality gate failed |
| `error_summary` | string | | First line or key part of the error message |
| `resolution` | string | | What fixed it (one sentence) |

**Written by:** implementation methodology when any quality gate fails before it eventually passes.

---

## Gotchas

- **CLAUDE_PLUGIN_DATA may not be set** — Always check with `[ -z "${CLAUDE_PLUGIN_DATA}" ]` before any read or write. If unset, skip gracefully with a log message, never crash.
- **Use append-only JSONL for logs** — Never rewrite `project-history.jsonl` or `failure-patterns.jsonl`. Always `echo '...' >> file`. Rewriting could lose history.
- **config.json is read once at session start** — Do not re-read on every operation. Cache the values from the first read.
- **mkdir -p before any write** — The `f/` subdirectory may not exist on first run. Always create it before writing.
- **Timestamps must be ISO 8601** — Use UTC: `2026-03-17T14:23:00Z`. Avoid local time zones.
- **One JSON object per JSONL line** — No pretty-printing, no trailing commas, no arrays. Each line must be independently parseable.
