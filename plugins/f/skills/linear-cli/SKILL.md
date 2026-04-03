---
name: linear-cli
description: >
  Guide for using the Linear Agent CLI — a Go-based CLI for Linear project management
  designed for AI agent consumption. Covers authentication, configuration, team setup,
  and all commands needed for the factory workflow (issues, projects, documents, labels).
  Loaded by orchestrator, planner, and implementation agents.
---

# Linear Agent CLI

The Linear Agent CLI (`linear`) is a Go-based command-line tool for managing Linear issues, projects, documents, and labels. It outputs JSON by default (no `--json` flag needed) and is designed for AI agent workflows.

**Source**: `github.com/juanbermudez/agent-linear-cli`
**Binary**: Installed at `/usr/local/bin/linear` (or wherever you place it on your `PATH`)

## Setup

### 1. Build from Source

```bash
git clone https://github.com/juanbermudez/agent-linear-cli.git
cd agent-linear-cli
make build
# Binary output: bin/linear
# Copy to PATH:
cp bin/linear /usr/local/bin/linear
# Or: cp bin/linear ~/bin/linear
```

**Requirements**: Go 1.21+

**Cross-platform builds**:
```bash
make build-all
# Outputs: bin/linear-darwin-arm64, bin/linear-darwin-amd64, bin/linear-linux-amd64, etc.
```

### 2. Authentication

The CLI supports three auth methods (checked in priority order):

1. **Environment variables** (CI/automation):
   ```bash
   export LINEAR_API_KEY="lin_api_..."
   ```

2. **System keychain** (recommended for local dev):
   ```bash
   linear auth login
   # Prompts for API key, stores in macOS Keychain / Linux secret-service
   # Keychain service name: "agent-linear-cli"
   ```

3. **Config file** (legacy fallback):
   ```bash
   linear config set api_key "lin_api_..."
   # Stored in ~/.linear.toml or ./.linear.toml
   ```

**Check auth status**:
```bash
linear auth status
# → { "authenticated": true, "method": "api_key", "source": "keychain" }
```

**Get an API key**: Linear Settings → API → Personal API Keys → Create Key

### 3. Team Configuration

Every Linear workspace has teams. Discover yours and configure the one you use for product development:

```bash
# List all teams in your workspace
linear team list
```

**Set the default team** so you don't need `--team` on every command. Replace `YOUR_TEAM_KEY` with your team's key (e.g., `ENG`, `PROD`, `DEV`):

```bash
linear config set team_key YOUR_TEAM_KEY
```

**Or pass per-command**:
```bash
linear issue list --team YOUR_TEAM_KEY
```

> **Configuration tip**: Save your team key to the plugin config (`${CLAUDE_PLUGIN_DATA}/f/config.json`) under `default_team_key` so agents always use the right team without manual setup each session.

### 4. Workflow State IDs

Linear uses UUIDs for workflow states. You need these for `--state` flags:

```bash
# Get all states for your team via GraphQL (replace YOUR_TEAM_KEY with your team key):
LINEAR_KEY=$(security find-generic-password -s "agent-linear-cli" -w | sed 's/^go-keyring-base64://' | base64 -d)
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "{ workflowStates(filter: { team: { key: { eq: \"YOUR_TEAM_KEY\" } } }) { nodes { id name type } } }"}' \
  | python3 -c "import sys,json; [print(n['id'], n['name'], n['type']) for n in json.load(sys.stdin)['data']['workflowStates']['nodes']]"
```

**Common states** (cache these — they don't change):

| State | Type | Usage |
|-------|------|-------|
| Todo | unstarted | New tasks |
| In Progress | started | Agent is working |
| In Review | started | Verification |
| Done | completed | Task complete |
| Canceled | canceled | Won't do |

### 5. Label Setup

The factory workflow uses a "🤖 Agent" label to mark tasks claimed by agents:

```bash
# Check if it exists (replace YOUR_TEAM_KEY with your team key):
linear label list --team YOUR_TEAM_KEY
# Look for: { "id": "...", "name": "🤖 Agent" }

# Create if missing:
linear label create --name "🤖 Agent" --color "#7C3AED" --team YOUR_TEAM_KEY
```

**Important**: The `--label` flag on `issue update` takes **label UUIDs**, not names:
```bash
# WRONG:
linear issue update TASK-123 --label "🤖 Agent"

# RIGHT:
linear issue update TASK-123 --label "b199afb8-e9ba-483f-b274-a8866aa7133e"
```

Similarly, `--state` takes a **state UUID**:
```bash
# WRONG:
linear issue update TASK-123 --state "In Progress"

# RIGHT:
linear issue update TASK-123 --state "7cb0d66a-a254-4454-bceb-0b2353392f4d"
```

## Command Reference

### Issues

```bash
# List issues (default: current team)
linear issue list --team YOUR_TEAM_KEY
linear issue list --team YOUR_TEAM_KEY --state "In Progress"

# View single issue
linear issue view TASK-123

# Create issue
linear issue create --title "Fix bug" --team YOUR_TEAM_KEY --description "Details here"
linear issue create --title "Task" --team YOUR_TEAM_KEY --priority 2 --assignee self

# Update issue
linear issue update TASK-123 --state "<state-uuid>" --label "<label-uuid>"
linear issue update TASK-123 --title "New title" --priority 1
linear issue update TASK-123 --assignee self

# Search
linear issue search "authentication" --team YOUR_TEAM_KEY

# Comments
linear issue comment TASK-123 --body "This is a comment"

# Relationships
linear issue relate TASK-123 TASK-456 --type blocks
linear issue relations TASK-123
```

### Projects

```bash
# List projects
linear project list

# View project
linear project view <project-id>

# Create project
linear project create --name "Feature X" --team YOUR_TEAM_KEY

# Update project (limited — use GraphQL for state changes)
linear project update <project-id> --name "New name"

# Search
linear project search "verification"
```

**Known limitation**: `project list --team YOUR_TEAM_KEY` fails because GraphQL `ProjectFilter` doesn't support `teams` field. Use `project list` without `--team` and filter client-side.

**Project state changes** require GraphQL (CLI doesn't support `--state` on projects):
```bash
LINEAR_KEY=$(security find-generic-password -s "agent-linear-cli" -w | sed 's/^go-keyring-base64://' | base64 -d)
curl -s -X POST https://api.linear.app/graphql \
  -H "Authorization: $LINEAR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query": "mutation { projectUpdate(id: \"<project-id>\", input: { state: \"started\" }) { success } }"}'
```

### Documents

```bash
# List documents
linear document list

# Create document (attached to project)
linear document create --title "PRD: Feature X" --project <project-id> --content "# PRD\n..."

# View document
linear document view <doc-id>

# Update document
linear document update <doc-id> --content "Updated content"

# Search
linear document search "verification"
```

**Note**: Project descriptions are limited to 255 chars. Use `document create --project <id>` for longer content (PRDs, specs).

### Labels

```bash
# List labels
linear label list --team YOUR_TEAM_KEY

# Create label
linear label create --name "Bug" --color "#FF0000" --team YOUR_TEAM_KEY
```

### Teams

```bash
# List teams
linear team list
```

### Initiatives

```bash
# List initiatives
linear initiative list

# View initiative
linear initiative view <initiative-id>
```

## Key Behaviors

### JSON Output
All commands output JSON by default. No `--json` flag needed.
Use `--human` for human-readable output when debugging.

### Assignee
Use `self` as a shorthand for the authenticated user:
```bash
linear issue update TASK-123 --assignee self
```

### Label Replacement
The `--label` flag **replaces all labels** on an issue (not additive):
```bash
# This REMOVES all other labels and sets only this one:
linear issue update TASK-123 --label "<uuid>"
```

### Keychain Access (macOS)
The CLI stores credentials in macOS Keychain under service `agent-linear-cli`. To extract the raw API key programmatically:

```bash
LINEAR_KEY=$(security find-generic-password -s "agent-linear-cli" -w | sed 's/^go-keyring-base64://' | base64 -d)
```

This is needed for direct GraphQL API calls that the CLI doesn't support.

## Factory Workflow Integration

The orchestrator uses the Linear CLI for:

1. **Claiming tasks**: `issue update TASK-XXX --state <in-progress-id> --label <agent-label-id>`
2. **Completing tasks**: `issue update TASK-XXX --state <done-id>`
3. **Creating tasks**: `issue create --title "..." --team YOUR_TEAM_KEY --description "..."`
4. **Viewing task details**: `issue view TASK-XXX`
5. **Adding comments**: `issue comment TASK-XXX --body "Verification result: PASS"`
6. **Creating project docs**: `document create --title "PRD: ..." --project <id>`

### Agent Setup Checklist

Before an agent can use the Linear CLI:

- [ ] Binary is at a known PATH location (e.g., `/usr/local/bin/linear` or `~/bin/linear`)
- [ ] Authentication is configured (`linear auth status` returns authenticated)
- [ ] Default team key is set (`linear config set team_key YOUR_TEAM_KEY`)
- [ ] Agent label UUID is known (check `linear label list --team YOUR_TEAM_KEY`)
- [ ] Workflow state UUIDs are cached (In Progress, Done, etc.)

### Spawned Agent Pattern

When the orchestrator spawns implementation agents, include this in the prompt:

```
## Linear CLI
Use the Linear CLI at `{path-to-linear-binary}` for issue operations.
- All output is JSON (no --json flag needed)
- Labels and states use UUIDs, not names
- Team key: {YOUR_TEAM_KEY}
- Agent label UUID: <uuid>
- In Progress state UUID: <uuid>
- Done state UUID: <uuid>
```
