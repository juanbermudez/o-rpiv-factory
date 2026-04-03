---
name: help
description: "Show all f commands, agents, and workflow stages"
---

# /f:help — Product Development Workflow

Display the full reference for the O-RPIV Factory compound engineering workflow.

## Instructions

When the user runs `/f:help`, display the following reference:

---

## O-RPIV Factory — Command Reference

### Core Commands

| Command | What It Does |
|---------|-------------|
| `/f:planner "what you want to build"` | Clarify → Research → Align → PRD + Spec → Task Breakdown |
| `/f:orchestrate` | Team lead mode: manage agents across projects, coordinate parallel work |
| `/f:do project-slug` | Execute all tasks in dependency-aware waves (direct, no teams) |
| `/f:do project-slug/PROJ-XXX` | Execute a single task |
| `/f:compound project-slug` | Extract learnings from completed work into `docs/solutions/` |
| `/f:compound-auto` | Auto-detect un-compounded tasks and extract learnings |
| `/f:status project-slug` | Show project progress, wave table, dependency graph |
| `/f:search-learnings "query"` | Search the knowledge base for past solutions |
| `/f:help` | Show this reference |

### The Compound Loop

```
Plan ──→ Work ──→ Review ──→ Compound
  ↑                              │
  └────── learnings feed ────────┘
```

Each cycle grows `docs/solutions/`. Future cycles are faster because past solutions surface automatically during research and planning.

### How `/f:planner` Works

The plan command takes a **user prompt** — it can be vague or detailed. The orchestrator:

1. **Clarifies** — presents its understanding, asks targeted questions, waits for answers
2. **Searches learnings** — checks `docs/solutions/` for relevant past work
3. **Creates Linear project** — assigned to the appropriate initiative
4. **Researches in parallel** — codebase, patterns, external APIs (3 agents)
5. **Aligns** — presents findings + architecture proposal, waits for approval
6. **Specs** — creates unified PRD + spec with Mermaid diagrams
7. **Stores spec in Linear** — project description IS the spec (source of truth)
8. **Reviews** — presents spec summary, waits for final approval
9. **Creates Linear issues** — all assigned to the project, with dependencies

Three human approval gates ensure nothing proceeds without your sign-off.

### How `/f:orchestrate` Works

The team orchestrator makes the main window a **team lead** that delegates all code work:

1. **Initializes** — creates a team, maps Linear tasks to internal task tracking
2. **Labels** — marks Linear tasks with "🤖 Agent" when claimed (prevents double-claiming)
3. **Spawns agents** — one agent per task, parallel within waves
4. **Coordinates** — monitors progress, syncs Linear ↔ internal tasks
5. **Verifies** — separate agents verify each implementation (never the author)
6. **Merges** — creates PRs, squash-merges after verification passes
7. **Cleans up** — removes labels, shuts down team, suggests compound

### Initiatives

Projects are organized under Linear initiatives. Initiatives are project-specific and should be configured to match your team's structure. Examples:

| Example Initiative | Example Scope |
|-------------------|--------------|
| User Management | Auth, profiles, roles, permissions, onboarding |
| API Integration | Third-party APIs, webhooks, OAuth, data sync |
| Dashboard | Analytics, reporting, charts, KPIs |
| Billing | Subscriptions, payments, invoicing, receipts |
| Public API | External API surface, versioning, auth, docs |
| Mobile | iOS/Android apps, push notifications, offline |
| Admin | Internal tooling, support workflows, ops dashboards |
| Infrastructure | DevOps, CI/CD, monitoring, scaling |

Configure your initiatives in Linear and reference them when running `/f:planner`.

### Agents

| Agent | Model | Role |
|-------|-------|------|
| `learnings-researcher` | haiku | Search `docs/solutions/` for prior art |
| `codebase-researcher` | sonnet | Explore repo structure, find patterns, external research |
| `planner` | opus | PRD + spec creation, task decomposition |
| `implementer` | sonnet | Write code following spec + TDD |
| `verifier` | sonnet | Quality gates (never wrote the code) |
| `context-analyzer` | sonnet | Analyze completed task context |
| `solution-extractor` | sonnet | Extract code patterns from diff |
| `prevention-strategist` | sonnet | Suggest prevention measures |
| `category-classifier` | haiku | Categorize and tag solutions |

### Linear Integration

**Projects**:
- Spec stored as project `description` (markdown with Mermaid diagrams)
- All tasks assigned to the project via `project` field
- Projects assigned to initiatives

**Issue statuses flow**:
```
Backlog → Todo → In Progress → Verification → Done → Archived
                    │              │              │
                    │              │ FAIL(1st)    └── Compound Review
                    │              └──→ auto-retry → re-verify
                    │              │ FAIL(2nd)
                    │              └──→ STOP, ask user
                    └── Canceled
```

**Verification enforcement**:
- The `status-transition.sh` hook blocks direct `In Progress → Done` transitions
- A signal file (`/tmp/verified-{TASK-ID}`) must exist before Done is allowed
- The orchestrator writes this file only after a verifier agent returns PASS/WARN
- First verification FAIL auto-retries; second FAIL stops and asks the user

**Agent coordination labels**:
- `🤖 Agent` — task claimed by an AI agent (do not reassign)

**Approval Gates** (human must approve before proceeding):
- After clarification questions → approve direction
- After alignment → approve architecture
- After spec review → approve task breakdown

### Quality Gates (enforced by `/f:do` and `/f:orchestrate`)

All must pass before a task is marked complete:
- `lint` — zero warnings (use your project's lint command)
- `typecheck` — no errors (use your project's typecheck command)
- `test` — all pass (use your project's test command)
- `build` — succeeds (use your project's build command)

### Knowledge Base

```
docs/solutions/
  build-errors/          test-failures/       runtime-errors/
  performance-issues/    database-issues/     security-issues/
  api-issues/            ui-bugs/             integration-issues/
  workflow-issues/       best-practices/      documentation-gaps/
  patterns/
    critical-patterns.md   ← promoted high-frequency patterns
```

### Quick Start

```bash
# Plan a feature
/f:planner "users need to export their data as CSV"
# → Clarification → Research → Alignment → Spec Review
# → Linear project created under the appropriate initiative

# Execute with team orchestration (recommended)
/f:orchestrate user-data-export

# Or execute directly (no team management)
/f:do user-data-export

# Extract learnings
/f:compound user-data-export
```

---

Present this information in a clean, readable format. Use the tables and code blocks as shown above.
