# Git Workflow Guide

This guide defines branch naming, commit format, and push rules for implementation tasks.

## Shared Project Worktree

You are working in a **shared project worktree**. The orchestrator has already created:
- **Worktree directory**: `$REPO_ROOT/.claude/worktrees/{project-slug}/`
- **Branch**: `feat/{project-slug}` (already checked out)

Other agents may also be committing to this branch in parallel. Always pull before pushing.

## Branch Naming

Branches are named per **project**, not per task:

```
feat/{project-slug}
```

Examples:
- `feat/order-history`
- `feat/user-profile`

You do NOT create branches — the orchestrator creates the project branch during initialization. Your job is to commit to it.

## Starting Work

```bash
cd $WORKTREE_DIR          # provided in your prompt
git pull --rebase origin feat/{project-slug}
```

Do NOT create a new branch. Do NOT checkout a different branch. Work on the existing project branch.

## Commit Format

```
feat(scope): TASK-XXX brief description of change
```

Examples:
- `feat(api): TASK-150 add order status filter endpoint`
- `feat(db): TASK-150 add status column to orders table`
- `fix(ui): TASK-151 scope order list to authenticated user`
- `test(api): TASK-150 add tests for order status filter`

**Scope options**: `api`, `ui`, `db`, `mobile`, `jobs`, `email`, `auth`, `test`, `types`, `config`

Adapt the task ID prefix to match your project's issue tracker format (e.g. `TASK-XXX`, `GH-123`, `APP-456`).

## Commit Granularity

One commit per RED→GREEN→REFACTOR cycle. Generally:
- Migration → commit
- Tests for API → commit
- API implementation → commit
- Tests for UI → commit (if applicable)
- UI implementation → commit

Never batch unrelated changes into a single commit.

## What Must Never Be Committed

- Secrets, API keys, or credentials (check `.env.local` is in `.gitignore`)
- Disabled tests (`it.skip`, `test.skip`, `describe.skip`)
- `// @ts-ignore` or `// eslint-disable` without a comment explaining why
- `console.log` debug statements in production code
- Files that are not part of the task's scope

## Pushing the Branch

```bash
git pull --rebase origin feat/{project-slug}
git push origin feat/{project-slug}
```

Always pull (rebase) before pushing to incorporate other agents' commits. Push before reporting completion to the orchestrator.

Do NOT merge into dev or main. Do NOT create a pull request. The orchestrator handles the final merge at project completion.

## After Each Commit

Run quality gates to confirm the commit did not break anything:
```bash
pnpm lint
pnpm typecheck
pnpm test
```

See [quality-gates.md](quality-gates.md) for how to run targeted gates efficiently.

## Pre-Commit Hooks

The repository may have pre-commit hooks that run automatically. Never bypass them with `--no-verify`. If a hook fails:
1. Read the error message
2. Fix the underlying issue
3. Stage the fix and commit again

Bypassing hooks is an anti-pattern that will cause quality gate failures later.
