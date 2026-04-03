---
name: do
description: "Wave-based implementation: dependency graph, parallel agents, verification, atomic commits"
argument-hint: "project-slug"
---

# `/do` — Wave-Based Implementation Orchestrator

You are the **top-level orchestrator** for implementing a full project. You read the
dependency graph, execute tasks in parallel waves, spawn separate verification agents,
and manage status transitions. You do NOT implement or verify anything yourself.

<!-- TASK ID FORMAT: Task IDs follow your project's Linear issue format (e.g., PROJ-123, ENG-456).
     Replace references to "PROJ-XXX" below with your actual task IDs when running commands. -->

---

## Phase 0: Load Project Context

<sequential_tasks>

### Step 0a: Read Manifest

Read `.resources/context/{{project-slug}}/manifest.json`.

Validate the manifest contains:
- `waves` — an ordered array of wave objects, each containing an array of task IDs
- `dependency_graph` — a mapping of task IDs to their `blockedBy` dependencies

If either field is missing, **STOP** and report:
> "Manifest at `.resources/context/{{project-slug}}/manifest.json` is missing required fields (`waves`, `dependency_graph`). Run `/f:planner {{project-slug}}` first."

### Step 0b: Load Critical Patterns

Read `docs/solutions/patterns/critical-patterns.md`. Store the file path — you will pass
this pointer to every spawned agent. Do NOT paste its contents into prompts.

If the file does not exist, note the gap and proceed. Warn the user:
> "Warning: `docs/solutions/patterns/critical-patterns.md` not found. Agents will skip anti-pattern checks."

### Step 0c: Display Wave Plan

Print a summary table to the user:

```
Project: {{project-slug}}
Waves: {{wave_count}}
Total tasks: {{task_count}}

Wave 1: {{task-id-1}}, {{task-id-2}}  (no dependencies)
Wave 2: {{task-id-3}}                 (blocked by: {{task-id-1}})
Wave 3: {{task-id-4}}, {{task-id-5}}  (blocked by: {{task-id-3}})
```

Use the `AskUserQuestion` tool to confirm before proceeding — do NOT output this as plain text:
> "Ready to execute {{wave_count}} waves with {{task_count}} tasks. Continue? (y/n)"

</sequential_tasks>

---

## Phase 1: Pre-Flight Checks

<validation_gate name="pre-flight" blocking="true">

Run all of the following checks. If ANY check fails, **STOP** and report the failure.
Do not proceed to wave execution.

### 1a: Task Context Files Exist

For every task ID in the manifest, verify the file exists:
```
.resources/context/{{project-slug}}/tasks/{{task-id}}.json
```

If any are missing, report which ones and stop.

### 1b: PRD Exists

Verify the PRD exists at:
```
.resources/context/{{project-slug}}/spec/prd.md
```

If missing, stop and report.

### 1c: Git State

```bash
# Must be on your project's default branch (check CLAUDE.md — typically main, dev, or master)
git branch --show-current

# Working tree must be clean
git status --porcelain     # expect: empty output
```

If not on the default branch or working tree is dirty, stop and report.

### 1d: Create Project Worktree

Create ONE worktree for the entire project. All agents will work in this shared directory.

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
# Replace 'main' with your project's default branch (e.g., dev, master) — check CLAUDE.md
git fetch origin main
git worktree add "$REPO_ROOT/.claude/worktrees/{{project-slug}}" -b feat/{{project-slug}} origin/main
WORKTREE_DIR="$REPO_ROOT/.claude/worktrees/{{project-slug}}"
```

### 1e: Quality Gates on Dev

```bash
cd "$WORKTREE_DIR"
pnpm lint
pnpm typecheck
```

Both must exit 0. If either fails, stop and report:
> "Pre-flight failed: quality gates do not pass on current dev. Fix before running `/do`."

</validation_gate>

---

## Phase 2: Wave Execution Loop

For each wave in `manifest.waves` (in order):

---

### Step 2a: Check Dependencies

For each task in the current wave, read `manifest.dependency_graph[task-id].blockedBy`.

For each blocker, verify its status is `"Done"` (check the task context file or your
in-memory tracking of completed tasks from previous waves).

If ANY dependency is not Done:
> **STOP.** Report which task is blocked and by which incomplete dependency.
> Do not proceed with this wave.

---

### Step 2b: Spawn Implementation Agents (Parallel)

<parallel_tasks>

For each task in the wave, spawn an **`implementer`** agent with this prompt:

```
Implement task {{task-id}}.

Working directory: {{WORKTREE_DIR}}
cd to this directory FIRST, before doing anything else.
You are working in a shared project worktree. Other agents may also be
committing to this branch (feat/{{project-slug}}).

Read your task context: .resources/context/{{project-slug}}/tasks/{{task-id}}.json
Read critical patterns: docs/solutions/patterns/critical-patterns.md
Read PRD: .resources/context/{{project-slug}}/spec/prd.md
Follow your implementation-methodology skill.

Git workflow:
- Branch already exists: feat/{{project-slug}} (do NOT create a new branch)
- Commit format: feat(scope): {{task-id}} description
- All commits must reference {{task-id}}
- Run quality gates before pushing
- Pull before pushing: git pull --rebase origin feat/{{project-slug}}
- Push: git push origin feat/{{project-slug}}. Do NOT merge.
```

Each agent:
- Works in the shared project worktree on branch `feat/{{project-slug}}`
- Follows the `implementer` agent definition and `implementation-methodology` skill
- Runs quality gates (lint, typecheck, test, build) before pushing
- Pulls before pushing (rebase) to incorporate other agents' commits
- Does NOT merge or create a PR

</parallel_tasks>

**Wait for ALL implementation agents in this wave to complete.**

If any implementation agent fails (no commits, non-zero exit, reports a blocker):
- Mark that task status as `"Blocked"` in your tracking
- Report to the user which task failed and why
- **STOP** the entire loop — do not proceed to verification

---

### Step 2c: Move Tasks to "Verification" Status

Before spawning verifiers, update each completed task's Linear state:

```bash
linear issue update {{task-id}} --state "Verification"
```

This makes the verification step visible in Linear and triggers the status-transition audit log.

---

### Step 2d: Spawn Verification Agents (Parallel, DIFFERENT Agents)

<critical_requirement>
Verification agents are ALWAYS different agents from the implementers.
They have NO Edit or Write tools (except to write the verification report).
They NEVER fix issues — they only report.
</critical_requirement>

<parallel_tasks>

For each completed implementation in this wave, spawn a **`verifier`** agent with this prompt:

```
Verify task {{task-id}} on branch feat/{{project-slug}}.

Working directory: {{WORKTREE_DIR}}
cd to this directory FIRST, before doing anything else.

Task context: .resources/context/{{project-slug}}/tasks/{{task-id}}.json
Critical patterns: docs/solutions/patterns/critical-patterns.md
Follow your verification-methodology skill.

Write your verification report to:
  .resources/context/{{project-slug}}/tasks/{{task-id}}-verify.md

You did NOT write this code. You are verifying someone else's work.
NEVER fix issues — only report them with file, line, and description.

## Return Format (MANDATORY)
Your FINAL message must include a structured verdict block:

\`\`\`verdict
VERDICT: PASS | WARN | FAIL
TASK: {{task-id}}
BRANCH: feat/{{project-slug}}
ISSUES_COUNT: {number}
ISSUES:
- [CRITICAL|WARNING] {description} ({file}:{line})
- ...
SUMMARY: {one-line summary}
\`\`\`
```

Each verifier:
- Works in the shared project worktree
- Reviews the diff against dev: `git diff origin/dev...HEAD`
- Runs the full verification pipeline (quality gates, anti-patterns, security, acceptance criteria)
- Writes a structured report with verdict: PASS, FAIL, or WARN

</parallel_tasks>

**Wait for ALL verification agents in this wave to complete.**

---

### Step 2e: Process Verification Results (with Auto-Retry)

For each verification report (`.resources/context/{{project-slug}}/tasks/{{task-id}}-verify.md`):

Read the report and extract the verdict.

**If PASS:**
- Write verification signal file: `touch /tmp/verified-{{task-id}}`
- Update Linear to Done: `linear issue update {{task-id}} --state "Done"`
  (The `status-transition.sh` hook will verify the signal file exists and clean it up)
- Update task status to `"Done"` in your in-memory tracking

**If WARN:**
- Treat as PASS for flow purposes (wave continues)
- Surface warnings to the user in the summary
- Same signal file + Done flow as PASS

**If FAIL (1st attempt):**
- Move back to In Progress: `linear issue update {{task-id}} --state "In Progress"`
- Add findings as Linear comment: `linear comment create {{task-id}} --body "..."`
- **Auto re-spawn** an implementer to fix the issues:

```
Agent:
  name: "fix-{{task-id}}"
  subagent_type: "general-purpose"
  mode: "auto"
  prompt: |
    You are FIXING verification failures on {{task-id}}: "{{task-title}}"

    ## Working Directory
    Work in the shared project worktree: {{WORKTREE_DIR}}
    cd to this directory FIRST, before doing anything else.

    ## Verifier Findings (MUST FIX ALL)
    {{paste the full ISSUES list from the verifier verdict}}

    Branch: feat/{{project-slug}} (already checked out in the worktree)
    Your fixes go here — do NOT create a new branch.

    Read CLAUDE.md first. Read docs/solutions/patterns/critical-patterns.md.
    Fix each issue. Run quality gates.
    Pull before pushing: git pull --rebase origin feat/{{project-slug}}
    Push: git push origin feat/{{project-slug}}
```

After the fix agent completes:
- Move back to "Verification": `linear issue update {{task-id}} --state "Verification"`
- Spawn a **new** verifier (attempt 2)
- Process the result again

**If FAIL (2nd attempt):**
- Move back to In Progress: `linear issue update {{task-id}} --state "In Progress"`
- **STOP the entire loop.** Use `AskUserQuestion` to present findings:

> "Verification FAILED twice for task {{task-id}}. Review the report at:
>   `.resources/context/{{project-slug}}/tasks/{{task-id}}-verify.md`
>
> Options:
> 1. Fix manually on branch `feat/{{project-slug}}` and re-run `/do`
> 2. Skip this task and continue the wave
> 3. Abort the project"

Do NOT continue to the next wave or merge any branches from this wave.

---

### Step 2e: Sync Project Branch

Only reached if ALL verifications in this wave passed (PASS or WARN).

All commits already live on the shared project branch (`feat/{{project-slug}}`).
Sync the worktree:

```bash
cd {{WORKTREE_DIR}}
git pull --rebase origin feat/{{project-slug}}
```

No per-task merging needed — the single project branch accumulates all wave commits.
The branch is merged into dev once at project completion (Phase 3).

**Proceed to the next wave.** The next wave starts from the current state of the project branch.

---

## Phase 3: All Waves Complete

When all waves have passed verification:

### Step 3a: Merge Project Branch into Default Branch

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT"
# Replace 'main' with your project's default branch (e.g., dev, master) — check CLAUDE.md
git checkout main
git pull origin main
git merge feat/{{project-slug}} --no-ff -m "feat: merge {{project-slug}} into main"
git push origin main
```

### Step 3b: Clean Up Project Worktree

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
git worktree remove "$REPO_ROOT/.claude/worktrees/{{project-slug}}" --force
git branch -d feat/{{project-slug}}
```

### Summary Table

Print a summary:

```
=== /do {{project-slug}} — Complete ===

| Wave | Task        | Status | Verdict |
|------|-------------|--------|---------|
| 1    | {{task-id}} | Done   | PASS    |
| 1    | {{task-id}} | Done   | PASS    |
| 2    | {{task-id}} | Done   | WARN    |
| ...  | ...         | ...    | ...     |

Branch: feat/{{project-slug}} → merged into dev
All {{task_count}} tasks verified and merged.
```

### Next Steps

Suggest to the user:
> "All tasks verified and merged to dev. Recommended next steps:
> 1. Run full quality gates on dev: `pnpm lint && pnpm typecheck && pnpm test && pnpm build`
> 2. Extract learnings: `/f:compound {{project-slug}}`
> 3. Deploy: `./scripts/deploy-prod.sh` or create PR from dev → main"

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Implementation agent fails (no commits, crash) | Mark task `"Blocked"`, report to user, **STOP loop** |
| Verification FAIL (1st time) | Auto re-spawn implementer with findings, re-verify (no user prompt) |
| Verification FAIL (2nd time) | Mark task `"In Progress"`, report to user with `AskUserQuestion`, **STOP loop** |
| Git merge conflict | **STOP**, list conflicting files, ask user to resolve manually |
| Quality gates fail on pre-flight | **STOP**, report failures, do not start waves |
| Missing manifest or context files | **STOP**, report what is missing, suggest running `/plan` |
| Network/MCP errors on Linear update | Warn but do NOT stop — Linear updates are best-effort |

---

## Key Rules

<critical_requirement>

1. **Implementation and verification are ALWAYS different agents.**
   Never let an implementer verify its own work. The verifier agent definition
   (`.claude/agents/verifier.md`) explicitly excludes Edit and Write tools
   (except for the report file).

2. **Verification agents cannot fix issues.**
   They report with file, line, and description. If verification fails, the
   loop stops for human review. The human (or a new implementer run) fixes.

3. **Dependencies are checked BEFORE spawning agents.**
   Step 2a runs before Step 2b. If a dependency is not Done, agents are never
   spawned — avoiding wasted work.

4. **Each wave must fully pass before the next wave starts.**
   No partial wave progression. All tasks in a wave must be implemented,
   verified, and merged before the next wave begins.

5. **Context is ALWAYS file pointers.**
   Never paste full file contents into agent prompts. Pass paths. Agents
   read files themselves using their Read tool.

6. **Git workflow: one branch per project, commits per task.**
   A single shared worktree is created at `$REPO_ROOT/.claude/worktrees/{{project-slug}}`
   with branch `feat/{{project-slug}}`. All agents commit to this branch.
   Agents pull before pushing (rebase) to avoid conflicts.
   The branch is merged into dev once at project completion.

7. **Verification before Done.**
   Tasks MUST go through "Verification" status before "Done". The `status-transition.sh`
   hook enforces this via signal files. Always: `touch /tmp/verified-{{task-id}}`
   BEFORE updating Linear to Done.

8. **Auto-retry on first verification failure.**
   On the first FAIL, automatically re-spawn an implementer with findings and re-verify.
   Only stop and ask the user after 2 consecutive failures on the same task.

9. **If 2nd verification in a wave fails, the ENTIRE loop stops.**
   No cherry-picking passing tasks from a failed wave. Fix the failure,
   then re-run `/do` — it will resume from the failed wave.

10. **Use `AskUserQuestion` for all user interactions.**
    Whenever you need to ask the user anything — wave confirmation, blocker decisions,
    direction changes — use the `AskUserQuestion` tool. Never output a question as
    plain text and wait; always use the tool so the user gets a proper interactive prompt.

</critical_requirement>
