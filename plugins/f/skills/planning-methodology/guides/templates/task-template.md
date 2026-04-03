# Task Context Template

Every task gets a context JSON file at `.resources/context/{project-slug}/tasks/{task-id}.json`.

This file is the primary input for the implementation agent. Fill in every field.

## Template

```json
{
  "taskId": "TASK-XXX",
  "title": "Verb-first task title",
  "objective": "One sentence — what this task accomplishes and why.",

  "filePointers": [
    {
      "path": "src/app/api/v1/orders/route.ts",
      "lines": "1-52",
      "purpose": "Pattern to follow — matches the shape of the new endpoint"
    },
    {
      "path": "migrations/20240115120000_create_orders.sql",
      "lines": "1-35",
      "purpose": "Reference migration structure for RLS and index patterns"
    }
  ],

  "patternAnchors": [
    "src/app/api/v1/orders/route.ts"
  ],

  "solutionPointers": [
    "docs/solutions/security-issues/missing-org-scope.md",
    "docs/solutions/database-issues/rls-missing-grant.md"
  ],

  "acceptanceCriteria": [
    "GET /api/v1/resource returns paginated list scoped by organization_id",
    "POST /api/v1/resource creates record with valid Zod-validated body",
    "POST with missing required fields returns HTTP 400",
    "pnpm lint, pnpm typecheck, pnpm test all pass"
  ],

  "verificationMethod": "api",

  "wave": 2,
  "blockedBy": ["TASK-XXX-1"],
  "blocks": ["TASK-XXX-3"],

  "notes": "Optional. Specific gotchas or context the implementer needs."
}
```

## Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `taskId` | Yes | Linear task ID (e.g., "TASK-123") |
| `title` | Yes | Verb-first task title |
| `objective` | Yes | Single sentence describing the outcome |
| `filePointers` | Yes | Existing code to read before implementing (with purpose) |
| `patternAnchors` | Yes | Which files to copy the pattern from |
| `solutionPointers` | No | Relevant `docs/solutions/` entries |
| `acceptanceCriteria` | Yes | Testable criteria list (minimum 3) |
| `verificationMethod` | Yes | `automated` \| `e2e` \| `api` \| `database` \| `mixed` |
| `wave` | Yes | Execution wave number (1 = no dependencies) |
| `blockedBy` | Yes | Task IDs that must complete first (empty array if none) |
| `blocks` | Yes | Task IDs that depend on this one (empty array if none) |
| `notes` | No | Freeform context for the implementer |

## Verification Methods

- `automated` — All criteria verifiable by lint/typecheck/test/build alone
- `e2e` — Requires browser testing on localhost (Playwright E2E + agent-browser for manual verification)
- `api` — Requires HTTP requests to running dev server
- `database` — Requires inspecting migration files and RLS policies
- `mixed` — Combination; specify which parts need what in `notes`

---

## Verification Task Template

Verification tasks are **planned as part of the PRD task breakdown**, not spawned reactively. Each verification task covers a GROUP of related implementation tasks and tests functionality in the browser.

### Template

```json
{
  "taskId": "TASK-XXX",
  "title": "Verify {feature} — {area}",
  "type": "verification",
  "objective": "Verify that {feature area} works correctly end-to-end by testing in the browser and collecting proof.",

  "verifies": ["TASK-AAA", "TASK-BBB", "TASK-CCC"],

  "verification_method": "browser",

  "test_scenarios": [
    {
      "description": "User can create a new {resource}",
      "steps": [
        "Navigate to /{resource} page",
        "Click 'Add {resource}' button",
        "Fill in required fields with valid data",
        "Submit the form",
        "Verify success toast appears",
        "Verify new {resource} appears in the list"
      ],
      "expected_result": "Resource is created and visible in list",
      "proof": "screenshot"
    },
    {
      "description": "User sees validation errors on invalid input",
      "steps": [
        "Navigate to /{resource} creation form",
        "Submit with empty required fields",
        "Verify validation error messages appear"
      ],
      "expected_result": "Form shows inline validation errors",
      "proof": "screenshot"
    }
  ],

  "proof_requirements": [
    "Screenshot of {feature} page loaded with data",
    "Screenshot of successful create/edit/delete operation",
    "E2E test results output (if Playwright tests exist)",
    "Sentry error check — 0 new errors after testing"
  ],

  "pass_criteria": "All test scenarios pass with collected proof. No new Sentry errors. UI follows design system.",
  "fail_action": "Return all tasks in 'verifies' to 'In Progress' with detailed failure comments including screenshots.",

  "design_checks": [
    "Uses shadcn/ui components (no custom primitives)",
    "List items use flat rows with bg-muted/30, not Card/CardContent",
    "Responsive layout works on mobile viewport",
    "Loading states present for async operations",
    "Empty states present when no data exists"
  ],

  "wave": 3,
  "blockedBy": ["TASK-AAA", "TASK-BBB", "TASK-CCC"],
  "blocks": [],

  "notes": "This is a verification task. The agent uses agent-browser to navigate the app, vercel-react-best-practices for design review, and Sentry CLI for error monitoring."
}
```

### Verification Task Field Reference

| Field | Required | Description |
|-------|----------|-------------|
| `type` | Yes | Must be `"verification"` |
| `verifies` | Yes | Array of task IDs this verification covers |
| `verification_method` | Yes | `browser` \| `e2e` \| `api` \| `design` |
| `test_scenarios` | Yes | Array of scenarios with steps, expected results, and proof type |
| `proof_requirements` | Yes | List of evidence to collect |
| `pass_criteria` | Yes | Conditions for PASS verdict |
| `fail_action` | Yes | What happens on FAIL — which tasks to return and how |
| `design_checks` | No | UI design checklist items (recommended for `browser` and `design` methods) |

### Verification Methods

| Method | When to Use | Agent Tools |
|--------|------------|-------------|
| `browser` | UI features — navigate, interact, screenshot | `agent-browser` skill, `vercel-react-best-practices` skill |
| `e2e` | Critical flows — execute Playwright test suite | Playwright CLI (`pnpm test:e2e` or project equivalent) |
| `api` | Backend-only — test endpoints with HTTP requests | `curl`, dev server on localhost |
| `design` | UI polish — audit against design system patterns | `vercel-react-best-practices` skill, `agent-browser` for screenshots |
