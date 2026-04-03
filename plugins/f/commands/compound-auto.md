---
name: compound-auto
description: "Auto-detect completed tasks without learnings extracted"
argument-hint: "project-slug (optional)"
---

# Compound Auto-Detect

Automatically find completed tasks that haven't had their learnings extracted yet.

## Instructions

### 1. Scan for Un-Compounded Tasks

**If `project-slug` is provided:**
- Scan `.resources/context/{slug}/tasks/` for task files.
- Identify tasks with status `Done` or `complete` in their frontmatter.
- For each completed task, check if a corresponding solution exists in `docs/solutions/`.
  - Match by task ID, task title, or project slug reference in solution frontmatter.
  - A task is "compounded" if at least one solution file references it.

**If no `project-slug` is provided:**
- Scan ALL `.resources/context/*/` directories for projects.
- For each project, scan its `tasks/` subdirectory.
- Apply the same completion and compounding checks as above.

### 2. Present Results

Display a table of un-compounded tasks:

| Project | Task ID | Title | Completed Date | Status |
|---------|---------|-------|----------------|--------|
| project-slug | task-001 | Task Title | 2026-01-15 | Not Compounded |

### 3. Offer to Compound

**IMPORTANT**: Use the `AskUserQuestion` tool for this prompt — do NOT output the question as plain text.

If un-compounded tasks are found, use `AskUserQuestion` to ask:
>
> Would you like to run `/compound` on these tasks? This will:
> - Analyze the implementation for patterns, pitfalls, and solutions
> - Extract reusable learnings into `docs/solutions/`
> - Make future similar work faster
>
> Reply with:
> - `yes` or `all` — Compound all listed tasks
> - `{task-id}` — Compound a specific task
> - `no` — Skip for now

If no un-compounded tasks are found:

> All completed tasks have been compounded. The knowledge base is up to date.

## Detection Logic

A task is considered "un-compounded" when ALL of these are true:
1. Task status is `Done`, `complete`, or `completed`
2. No file in `docs/solutions/` references the task ID in its frontmatter
3. The task has implementation artifacts (commits, code changes)
