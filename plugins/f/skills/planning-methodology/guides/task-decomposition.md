# Task Decomposition Guide

This guide defines how to break a PRD into discrete Linear tasks that implementation agents can claim and complete independently.

## Decomposition Principles

### 1. One Clear Objective Per Task

A task is correctly sized if an agent can complete it in a single session without needing to ask questions. Signs a task is too large:
- It requires changes in more than 3 unrelated files
- It has more than 5 acceptance criteria
- It involves both a database migration AND a full UI feature

Signs a task is too small:
- It is a single function with no dependencies
- It duplicates work already done in another task
- It has no independently verifiable outcome

### 2. Proper Sizing

Target task sizes:
- **Small**: 1-2 files, 1-2 acceptance criteria, 30-90 min implementation
- **Medium**: 3-5 files, 3-4 acceptance criteria, 90-180 min implementation
- **Large**: 5-8 files, 4-5 acceptance criteria, 180-240 min — consider splitting

Never create tasks larger than "Large". Split by layer (migration + API + UI = 3 tasks).

### 3. Layer Separation

Split tasks by architectural layer when possible:
- Migration task → API task → UI task
- Each can be implemented and verified independently
- Enables parallel work within a wave after the migration is done

## Task Structure

Each task must have:

### Title
Verb-first, specific:
- Good: "Add order status filter to orders API"
- Bad: "Order filtering"
- Bad: "Implement feature"

### Description
Include:
- What to build (not how — that's the implementation agent's job)
- Which files to read as starting points (file pointers)
- Which patterns to follow (with file:line references from the pattern research)
- Any known gotchas from `docs/solutions/`

### Acceptance Criteria
Numbered, independently testable:
```
1. GET /api/v1/orders?status=active returns only active orders
2. Response is scoped by organization_id
3. Missing status param returns all orders (not 400)
4. pnpm lint, pnpm typecheck, pnpm test all pass
```

### Verification Method
How will the verifier check this? Choose one:
- `automated`: All criteria verifiable by lint/typecheck/test
- `e2e`: Requires browser testing (Playwright E2E tests + agent-browser for manual verification)
- `api`: Requires HTTP request to running server
- `database`: Requires checking migration and RLS policies
- `mixed`: Combination of above

## Context File

Every task gets a context JSON file at `.resources/context/{slug}/tasks/{task-id}.json`:

```json
{
  "taskId": "TASK-XXX",
  "title": "Task title",
  "objective": "One sentence — what this task accomplishes",
  "filePointers": [
    {
      "path": "src/app/api/v1/orders/route.ts",
      "lines": "1-52",
      "purpose": "Pattern to follow for the new endpoint"
    }
  ],
  "patternAnchors": ["src/app/api/v1/orders/route.ts"],
  "solutionPointers": ["docs/solutions/api-issues/missing-org-scope.md"],
  "acceptanceCriteria": ["criterion 1", "criterion 2"],
  "verificationMethod": "api",
  "wave": 2,
  "blockedBy": ["TASK-XXX-1"],
  "blocks": ["TASK-XXX-3"]
}
```

See also: [guides/templates/task-template.md](templates/task-template.md)

## Verification Tasks

Every project plan MUST include **verification tasks** as first-class planned work. Verification tasks go in dedicated later waves, after the implementation tasks they verify.

### Principles

1. **Group by feature area, not per-task.** A single verification task covers 3-5 related implementation tasks (e.g., "Verify orders API + UI" covers the migration, API, and UI tasks together).
2. **Place in a later wave.** Verification tasks are blocked by the implementation tasks they verify. They run after those tasks complete.
3. **Specify what to test, not how to test.** Describe user stories and expected outcomes. The verifier agent chooses the tools.
4. **Require proof.** Every verification task must specify what evidence to collect (screenshots, test output, Sentry status).

### Verification Task Structure

Each verification task must include:

- **`type: verification`** — distinguishes it from implementation tasks
- **`verifies`** — list of task IDs this verification covers
- **`verification_method`** — one of: `browser`, `e2e`, `api`, `design`
- **`test_scenarios`** — user stories with steps and expected outcomes
- **`proof_requirements`** — what evidence to collect (screenshots, test output, Sentry check)
- **`pass_criteria`** — conditions for PASS verdict
- **`fail_action`** — what happens on FAIL (return verified tasks to "In Progress" with details)

### Verification Methods

| Method | When to Use | Tools |
|--------|------------|-------|
| `browser` | UI features — navigate the app, test user stories | `agent-browser` skill |
| `e2e` | Critical flows — run Playwright E2E test suite | Playwright CLI |
| `api` | Backend-only features — test endpoints directly | `curl` / HTTP requests |
| `design` | UI polish — check against design system | `vercel-react-best-practices` skill |

Most features need `browser` verification. Use `e2e` when Playwright tests exist. Use `api` for headless API-only work. Use `design` as an add-on method when UI quality matters.

### How Many Verification Tasks?

- **Small project (3-5 impl tasks):** 1 verification task covering everything
- **Medium project (6-10 impl tasks):** 2-3 verification tasks, grouped by feature area
- **Large project (11+ impl tasks):** 1 verification task per 3-5 related impl tasks

### Verification Wave Placement

Verification tasks always go in a wave AFTER all the implementation tasks they verify:

```
Wave 1: Migration tasks
Wave 2: API + UI tasks (blocked by Wave 1)
Wave 3: Verification tasks (blocked by Wave 2)  ← verification wave
```

If a project has multiple groups of features that are independent:

```
Wave 1: Feature A migration, Feature B migration
Wave 2: Feature A API + UI, Feature B API + UI
Wave 3: Verify Feature A (blocked by Wave 2 Feature A tasks)
Wave 3: Verify Feature B (blocked by Wave 2 Feature B tasks)
```

See the verification task template: [guides/templates/task-template.md](templates/task-template.md)

---

## Common Task Splits

### Full CRUD Feature (5 tasks)

```
Wave 1: Database migration (table, indexes, RLS, grants)
Wave 2: API routes (list, get, create, update, delete)
Wave 2: UI list view (table component, filters, pagination)
Wave 3: UI detail/edit view (form, validation, submission)
Wave 4: Verify CRUD feature — browser test all operations, design check
```

### Simple API Endpoint (2-3 tasks)

```
Wave 1: API route with tests
Wave 2: UI integration (if needed)
Wave 3: Verify API endpoint — test responses, error handling
```

### Data Model Change (3-4 tasks)

```
Wave 1: Migration + type update
Wave 2: API changes to use new field
Wave 2: UI changes to display new field
Wave 3: Verify data model change — browser + API verification
```
