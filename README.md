# RPI Factory

A compound product development workflow plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## What is RPI Factory?

RPI Factory transforms how you build software with AI. It provides a structured, methodology-driven workflow for planning, implementing, and verifying features — turning Claude Code into a full product development partner.

The core loop is:

```
Plan ──→ Work ──→ Review ──→ Compound
  ↑                              │
  └────── learnings feed back ───┘
```

Each cycle grows `docs/solutions/`. Future cycles are faster because past solutions surface automatically during research and planning.

### Key Capabilities

- **Structured Planning** (`/f:planner`) — Research-backed PRDs with three human alignment gates, initiative-aware task decomposition, and Mermaid architecture diagrams
- **Wave-Based Implementation** (`/f:do`) — Dependency-aware parallel execution with separate implementation and verification agents
- **Team Orchestration** (`/f:orchestrate`) — Multi-agent coordination with Linear integration, agent claiming, and cross-project tracking
- **Knowledge Compounding** (`/f:compound`) — Extract structured learnings from completed work into a searchable knowledge base
- **Verification** — Separate verifier agents (never the implementer), automated quality gates, anti-pattern checks, and auto-retry on first failure
- **Learnings Search** (`/f:search-learnings`) — Query past solutions before starting new work
- **Scaffolding** (`/f:scaffold`) — Generate boilerplate following your project's patterns
- **Safety Guards** — Careful mode, freeze mode, dependency gates, and verification-before-done enforcement

## Installation

RPI Factory is installed as a Claude Code plugin. Add it to your project or global Claude Code configuration:

```json
{
  "plugins": [
    {
      "name": "f",
      "path": "/path/to/rpi-factory/plugins/f"
    }
  ]
}
```

Refer to the [Claude Code plugin documentation](https://docs.anthropic.com/en/docs/claude-code/plugins) for the current installation method.

## Quick Start

```bash
# See all available commands
/f:help

# Plan a new feature (starts the clarification → research → alignment → spec workflow)
/f:planner "users need to export their data as CSV"

# Execute implementation with team orchestration (recommended for multi-task projects)
/f:orchestrate user-data-export

# Or execute directly without team management
/f:do user-data-export

# Extract learnings from completed work
/f:compound user-data-export

# Search the knowledge base
/f:search-learnings "CSV export pattern"
```

## Commands

| Command | Description |
|---------|-------------|
| `/f:planner "what you want to build"` | Clarify → Research → Align → PRD + Spec → Task Breakdown in Linear |
| `/f:do project-slug` | Execute all tasks in dependency-aware waves |
| `/f:do project-slug/TASK-XXX` | Execute a single task |
| `/f:orchestrate` | Team lead mode: manage agents across projects, coordinate parallel work |
| `/f:compound project-slug` | Extract learnings from completed work into `docs/solutions/` |
| `/f:compound-auto` | Auto-detect un-compounded tasks and extract learnings |
| `/f:scaffold type name` | Generate project-pattern-aware boilerplate |
| `/f:status project-slug` | Show project progress, wave table, dependency graph |
| `/f:search-learnings "query"` | Search the knowledge base for past solutions |
| `/f:careful` | Enable careful mode (blocks destructive commands) |
| `/f:freeze` | Enable freeze mode (restricts edits to a specific directory) |
| `/f:help` | Show command reference |

## How It Works

### Planning (`/f:planner`)

The planner takes a user prompt — vague or detailed — and produces a fully-specified project with dependency-aware tasks in Linear. The workflow has three mandatory human approval gates:

1. **Clarification** — Presents interpretation, asks targeted questions, waits for answers
2. **Alignment** — Shows research findings and proposed architecture, waits for approval
3. **Spec Review** — Presents the full PRD with wave plan and task breakdown, waits for final approval

Between gates, the planner runs parallel research agents (codebase, patterns, external APIs) and writes results to `.resources/context/{slug}/`. The PRD is stored both locally and in the Linear project body.

### Wave-Based Execution (`/f:do`)

The `/f:do` command reads a project manifest and executes tasks in dependency order:

- Tasks with no dependencies run in parallel in Wave 1
- Tasks blocked by Wave 1 tasks run in Wave 2, and so on
- Each wave: implementation agents run in parallel → verification agents review the work (separate agents, never the implementer) → failures auto-retry once before stopping for human review
- All agents commit to a shared project branch (`feat/{project-slug}`) with rebase before push

### Team Orchestration (`/f:orchestrate`)

`/f:orchestrate` adds full team management on top of the wave execution loop:

- Creates a team worktree and maps Linear tasks to internal tracking
- Claims tasks in Linear with an Agent label before spawning (prevents double-claiming)
- Verification tasks are planned first-class tasks in the wave plan (not reactive post-implementation steps)
- Verification agents can use browser automation, design system checks, and error monitoring
- Updates Linear project status at each milestone (Planned → In Progress → Completed)
- Presents a cross-project dashboard when managing multiple concurrent projects

### Knowledge Compounding (`/f:compound`)

After work completes, `/f:compound` extracts structured learnings:

- Spawns 5 parallel agents: context analyzer, solution extractor, related docs finder, prevention strategist, category classifier
- Assembles a solution document with WRONG vs CORRECT code examples, prevention actions, and cross-references
- Stores in `docs/solutions/{category}/{filename}.md` with YAML frontmatter for searchability
- Promotes high-frequency patterns to `docs/solutions/patterns/critical-patterns.md`
- Future planning and implementation agents read `critical-patterns.md` automatically to avoid known mistakes

## Configuration

RPI Factory uses environment variables for runtime configuration and project-level files for methodology customization.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TASK_ID_PATTERN` | `[A-Z]+-[0-9]+` | Regex pattern for task IDs (e.g., `PROJ-123`, `GH-456`) |
| `SIGNAL_PREFIX` | `/tmp/factory-verified-` | Directory prefix for verification signal files |
| `AUDIT_LOG` | `/tmp/factory-status-audit.log` | Path for status transition audit log |
| `FACTORY_CAREFUL_MODE` | unset | Set to `1` to enable careful mode |
| `FACTORY_FREEZE_DIR` | unset | Set to a directory path to restrict edits to that directory |
| `FACTORY_TASK_CONTEXT` | unset | Path to the current task's JSON context file (set by orchestrator) |

### Project Configuration

Configure the following in your project's `CLAUDE.md` or agent prompts:

- **Linear workspace** — Team IDs, initiative IDs, and project status IDs for your workspace
- **Task ID prefix** — Set `TASK_ID_PATTERN` to match your issue tracker (e.g., `JIRA-[0-9]+`)
- **Initiatives** — Define your project's initiative structure in Linear and reference them during planning
- **Quality gates** — The commands for lint, typecheck, test, and build in your project
- **Tech stack** — Customize library references and implementation patterns for your stack

### Customizing for Your Project

RPI Factory is designed to be adapted:

1. **Task ID Pattern** — Set `TASK_ID_PATTERN` to match your issue tracker format
2. **Initiatives** — Define your team's initiative structure in Linear; the planner will assign projects to initiatives
3. **Tech Stack** — Update `plugins/f/skills/library-references/` with references for your libraries
4. **Deployment** — Add your deployment procedures to `plugins/f/skills/deployment/`
5. **Runbooks** — Add your troubleshooting playbooks to `plugins/f/skills/runbooks/playbooks/`
6. **Scaffolding Templates** — Update `plugins/f/skills/scaffolding/templates/` with your project's boilerplate patterns

## Architecture

```
plugins/f/
├── agents/                     # AI agent definitions
│   ├── implementer.md          # Writes code, runs quality gates
│   ├── verifier.md             # Reviews code (never the implementer)
│   ├── planner.md              # Creates PRDs and task breakdowns
│   ├── codebase-researcher.md  # Explores repo, finds patterns
│   ├── learnings-researcher.md # Searches docs/solutions/
│   ├── context-analyzer.md     # Analyzes completed task artifacts
│   ├── solution-extractor.md   # Extracts WRONG vs CORRECT patterns
│   ├── prevention-strategist.md # Suggests prevention measures
│   └── category-classifier.md  # Tags and categorizes solutions
│
├── commands/                   # User-facing slash commands
│   ├── planner.md              # /f:planner
│   ├── do.md                   # /f:do
│   ├── orchestrate.md          # /f:orchestrate
│   ├── compound.md             # /f:compound
│   ├── compound-auto.md        # /f:compound-auto
│   ├── scaffold.md             # /f:scaffold
│   ├── status.md               # /f:status
│   ├── search-learnings.md     # /f:search-learnings
│   ├── careful.md              # /f:careful
│   ├── freeze.md               # /f:freeze
│   └── help.md                 # /f:help
│
├── hooks/                      # Claude Code PreToolUse hooks
│   ├── hooks.json              # Hook registration
│   ├── status-transition.sh    # Blocks Done without verification signal
│   ├── git-workflow.sh         # Enforces branch naming, commit format
│   ├── careful-guard.sh        # Blocks destructive commands in careful mode
│   ├── freeze-guard.sh         # Restricts edits to frozen directory
│   ├── dependency-gate.sh      # Blocks work if dependencies unresolved
│   └── skill-usage-logger.sh   # Logs skill invocations
│
├── scripts/                    # Automation scripts
│   ├── do-loop.ts              # Standalone wave executor (reference implementation)
│   └── wave-compute.ts         # Dependency graph → wave computation utility
│
└── skills/                     # Methodology guides and references
    ├── compound-methodology/   # Knowledge extraction guides and templates
    ├── deployment/             # Deployment procedures and references
    ├── implementation-methodology/  # TDD workflow, API patterns, quality gates
    ├── library-references/     # Library-specific gotcha guides
    ├── linear-cli/             # Linear CLI usage reference
    ├── planning-methodology/   # PRD creation, task templates
    ├── plugin-memory/          # Session state and memory patterns
    ├── research-methodology/   # Online research guides
    ├── runbooks/               # Troubleshooting playbooks
    ├── scaffolding/            # Boilerplate templates
    └── verification-methodology/  # Quality gates, E2E, design verification
```

## Agents

| Agent | Model | Role |
|-------|-------|------|
| `learnings-researcher` | haiku | Search `docs/solutions/` for prior art before planning |
| `codebase-researcher` | sonnet | Explore repo structure, find patterns, research external APIs |
| `planner` | opus | PRD + spec creation, task decomposition |
| `implementer` | sonnet | Write code following spec and TDD |
| `verifier` | sonnet | Quality gates and acceptance criteria (never wrote the code) |
| `context-analyzer` | sonnet | Analyze completed task artifacts for compounding |
| `solution-extractor` | sonnet | Extract code patterns from diff |
| `prevention-strategist` | sonnet | Suggest prevention measures from failures |
| `category-classifier` | haiku | Categorize and tag solutions for the knowledge base |

## Safety Guards

### Verification Before Done

The `status-transition.sh` hook blocks moving any task to "Done" in Linear without a verification signal file. The orchestrator writes this file (`${SIGNAL_PREFIX}{TASK-ID}`) only after a verifier agent returns PASS or WARN. This prevents unverified work from being marked complete.

### Careful Mode

`/f:careful` (or `FACTORY_CAREFUL_MODE=1`) blocks:
- `rm -rf`
- `DROP TABLE` / `DROP DATABASE`
- Force push
- `git reset --hard`
- `DELETE FROM` without a WHERE clause
- `kubectl delete`

### Freeze Mode

`/f:freeze` (or `FACTORY_FREEZE_DIR=/path/to/dir`) restricts all Edit and Write operations to a specific directory. Useful when agents should only touch a particular area of the codebase.

### Git Workflow Enforcement

The `git-workflow.sh` hook enforces:
- No force push
- No `git reset --hard`
- No commits directly to `main`
- Commit messages must reference a task ID
- Branch names must follow `feat/{TASK-ID}-description` format
- `--no-verify` is blocked

## Knowledge Base

Solutions are stored in `docs/solutions/` with a consistent structure:

```
docs/solutions/
  build-errors/
  test-failures/
  runtime-errors/
  performance-issues/
  database-issues/
  security-issues/
  api-issues/
  ui-bugs/
  integration-issues/
  workflow-issues/
  best-practices/
  documentation-gaps/
  patterns/
    critical-patterns.md    ← promoted high-frequency patterns
```

Each solution document has YAML frontmatter with `problem_type`, `component`, `severity`, `tags`, and `related_solutions` fields. The `learnings-researcher` agent searches these fields before each planning cycle so known solutions automatically surface.

## Scripts

The `plugins/f/scripts/` directory contains two TypeScript utilities:

- **`wave-compute.ts`** — Pure function that converts a dependency graph into an ordered array of waves. Import and use in your own tooling:

  ```typescript
  import { computeWaves } from "./wave-compute";

  const waves = computeWaves({
    "TASK-1": { blocks: ["TASK-3"], blockedBy: [] },
    "TASK-2": { blocks: ["TASK-3"], blockedBy: [] },
    "TASK-3": { blocks: [], blockedBy: ["TASK-1", "TASK-2"] },
  });
  // → [{ wave: 1, tasks: ["TASK-1", "TASK-2"], parallel: true },
  //    { wave: 2, tasks: ["TASK-3"], parallel: false }]
  ```

- **`do-loop.ts`** — Reference implementation of the full wave execution loop using the `@anthropic-ai/claude-agent-sdk`. Reads a project manifest, spawns implementation and verification agents per wave, and updates task status. Useful as a starting point for programmatic integration.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with plugin support
- [Linear](https://linear.app) account (for project and task management)
- `jq` installed (used by hooks)
- `linear` CLI (for issue/comment operations from agents)
- Node.js + `npx tsx` (for running the TypeScript scripts directly)

## Contributing

Contributions are welcome. Areas where the plugin is intentionally generic and benefits from community input:

- Additional scaffolding templates for common tech stacks
- Library reference guides for widely-used packages
- Additional runbook playbooks
- Improvements to the verification methodology
- Alternative Linear integrations or support for other issue trackers

Please open an issue before submitting large changes to discuss the approach.

## License

MIT — see [LICENSE](LICENSE).
