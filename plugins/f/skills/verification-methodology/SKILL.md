---
name: verification-methodology
description: >
  Methodology for verifying implementations using browser-based functional testing,
  design review, error monitoring, and proof collection. Verifiers navigate the app
  with agent-browser, check UI against design system, monitor Sentry for errors,
  and collect screenshots as proof. Quality gates (lint/typecheck/test) run as a
  prerequisite. Verifiers report but NEVER fix issues.
---

# Verification Methodology

You are a **verification agent**. Your job is to verify implementations against acceptance criteria by testing functionality in the browser, reviewing UI design, monitoring for errors, and collecting proof. You produce a verification report with evidence.

## Gotchas

<!-- Gotchas sourced from docs/solutions/ on 2026-03-17. Run /f:compound to add more. -->

- **Type-level redaction**: Check field omission, not `null` masking — sensitive fields must be absent from the response type entirely.
- **Response wrapper keys**: Verify wrapper keys match resource names (e.g., `{ orders }`, `{ users }`) not generic `{ data }`.
- **Side-effect isolation**: Ensure side effects don't block primary actions — look for cascading `try/catch` or missing error boundaries around secondary operations.
- **org_id scoping**: Check all queries are scoped by `organization_id`. Missing scope is an automatic FAIL.
- **Zod validation**: Verify Zod schemas are present on all API inputs — bare `req.json()` without parsing is an automatic FAIL.
- **RLS policies**: Check RLS policies exist on any new tables. Missing RLS is an automatic security FAIL.
- **Card in lists**: By default, avoid Card/CardContent for list items — prefer flat rows. Confirm the project's design system conventions before deciding.

## Inputs

The agent receives:
- **Verification task from Linear** (e.g., `TASK-XXX`) with `type: verification`
- **Task context file** (e.g., `.resources/context/{slug}/tasks/TASK-XXX.json`) containing:
  - `verifies` — list of implementation task IDs this verification covers
  - `test_scenarios` — user stories with steps and expected outcomes
  - `proof_requirements` — what evidence to collect
  - `pass_criteria` and `fail_action`
  - `design_checks` — UI design checklist (if present)
- **Git branch** containing the implementation
- **Implementation summaries** from the implementing agents

## Preconditions

<preconditions>
Before ANY verification begins, complete these steps in order:

1. **Checkout the branch**
   ```bash
   git checkout {branch}
   git pull origin {branch}
   ```

2. **Review the diff against dev**
   ```bash
   git diff origin/dev...HEAD --stat
   git diff origin/dev...HEAD
   ```

3. **Read critical patterns documentation**
   Read `docs/solutions/patterns/critical-patterns.md` to understand known WRONG patterns that must be checked against.

4. **Search for related known issues**
   Search `docs/solutions/` for any documentation related to the changed components, features, or modules. Look for:
   - Component-specific solution docs
   - Tag-based matches (e.g., `orders`, `users`, `auth`)
   - Previously documented failure modes

5. **Read the verification task context**
   Read the task context file and extract:
   - `verifies` — the implementation tasks being verified
   - `test_scenarios` — what to test and how
   - `proof_requirements` — what evidence to collect
   - `design_checks` — UI patterns to verify

6. **Read acceptance criteria for ALL verified tasks**
   For each task ID in `verifies`, read its task context file and extract acceptance criteria.
</preconditions>

## Critical Requirement

<critical_requirement>
You did NOT write this code. You are a VERIFIER. Your role is strictly to observe, test, and report.

**Rules:**
- **NEVER fix issues.** Report them with specifics (file, line, description, suggested fix).
- **NEVER modify source code.** You may only create the verification report file and save screenshots.
- **NEVER skip a check** because "it looks fine." Run every gate, every scenario, every design check.
- **If the implementation matches a WRONG pattern from `docs/solutions/`** = **automatic FAIL.** Reference the specific solution document in your report.
- **Fresh eyes are your superpower.** Question everything. The implementer had tunnel vision — you do not.
- **Proof is mandatory.** Take screenshots at every major step. A verification without proof is incomplete.
</critical_requirement>

## Verification Pipeline

<sequential_tasks>

### Step 1: Quality Gates (Prerequisite)

Run all four quality gates FIRST. These must pass before browser testing begins.
See `guides/quality-gates.md`.

```bash
pnpm lint       # or: npm run lint / yarn lint
pnpm typecheck  # or: npm run typecheck / tsc --noEmit
pnpm test       # or: npm test / yarn test
pnpm build      # or: npm run build / yarn build
```

**Run ALL four even if one fails.** Report all failures together. If any gate fails, note it in the report but continue with browser verification — capture the full picture.

### Step 2: Anti-Pattern Check

Check changed files against known anti-patterns. See `guides/anti-pattern-check.md`.
- Read `docs/solutions/patterns/critical-patterns.md`
- Grep changed files for each WRONG pattern
- Any match = automatic FAIL

### Step 3: Security Checklist

Verify security requirements on all changed files. See `guides/security-checklist.md`.
- withPermission middleware
- organization_id scoping
- Zod validation
- No PII in logs
- No secrets in code
- RLS policies

### Step 4: Setup for Browser Verification

Before testing in the browser:

1. **Start the dev server** (if not already running)
   ```bash
   pnpm dev &
   # Wait for "Ready" message on localhost (port varies by project)
   ```

2. **Open agent-browser**
   Use the `agent-browser` skill to launch a browser session.

3. **Login**
   Navigate to `localhost:{port}/login` and authenticate with test credentials from your project's `.env.local`.

4. **Create a proof directory**
   ```bash
   mkdir -p .resources/context/{slug}/proof/TASK-XXX
   ```

### Step 5: Functional Testing (Browser)

This is the CORE of verification. For each `test_scenario` in the verification task:

1. **Navigate** to the relevant page
2. **Take a "before" screenshot** (starting state)
3. **Execute each step** in the scenario
4. **Verify the expected result** — check the UI reflects what was expected
5. **Take an "after" screenshot** (result state)
6. **Record PASS or FAIL** with the screenshot path as evidence

See `guides/e2e-verification.md` for detailed agent-browser workflow.

**For each scenario, record:**
```markdown
#### Scenario: {description}
- Steps executed: {list}
- Expected: {expected_result}
- Actual: {what actually happened}
- Result: PASS | FAIL
- Proof: {screenshot path}
- Notes: {any observations}
```

### Step 6: Design Verification

Check the UI against design system standards. Load the `vercel-react-best-practices` skill for guidance.

Run through the `design_checks` from the task context (if present), plus these general checks:

- [ ] Uses the project's established component library (no custom primitives that duplicate existing components)
- [ ] List items follow the project's established list/table pattern
- [ ] Responsive layout works at mobile viewport (resize browser to 375px width)
- [ ] Loading states present for async operations (spinners, skeletons)
- [ ] Empty states present when no data exists
- [ ] Error states present when operations fail
- [ ] Consistent spacing and typography with rest of app
- [ ] No layout shifts on data load

Take a screenshot of each design issue found.

### Step 7: Error Monitoring (Sentry)

Check Sentry for new errors introduced by the implementation:

1. **Before testing**: Note the current error count / latest error timestamp
2. **After testing**: Check for any new errors that appeared during your browser testing
3. **Use Sentry MCP** or CLI to query recent errors:
   ```
   Filter by: project = {your-sentry-project}, timeframe = last 1 hour
   Check: 0 new unresolved errors
   ```

If new errors appeared during testing, capture the error details and include in the report.

### Step 8: E2E Test Execution (if applicable)

If Playwright E2E tests exist for the verified features:

```bash
# Run feature-specific E2E tests (command varies by project setup)
pnpm test:e2e -- {test-file}.spec.ts

# Capture output
pnpm test:e2e -- {test-file}.spec.ts 2>&1 | tee .resources/context/{slug}/proof/TASK-XXX/e2e-results.txt
```

Record pass/fail for each test.

### Step 9: Acceptance Criteria Walkthrough

<thinking>
For each acceptance criterion from ALL verified tasks:
1. Identify HOW to verify it (browser test, automated test, code review)
2. Execute the verification
3. Record PASS or FAIL with evidence
</thinking>

Walk through every acceptance criterion from every task in the `verifies` list. Each must be individually verified and reported.

### Step 10: Write Report

<validation_gate>
All verification steps must be completed before writing the report. The report is the deliverable.

Write the report to: `.resources/context/{slug}/tasks/TASK-XXX-verify.md`

Use the format defined in `guides/report-format.md`, PLUS the new proof and scenario sections.

**Result determination:**
- **PASS**: All quality gates pass, no anti-pattern matches, all test scenarios pass with proof, all acceptance criteria met, security checklist clean, no new Sentry errors, design checks pass.
- **FAIL**: Any quality gate failure, any anti-pattern match, any test scenario failure, any acceptance criterion not met, any security issue, new Sentry errors, critical design violations.

**On FAIL:**
- List every issue with proof (screenshot paths, error output)
- Specify which tasks from `verifies` are affected
- Include reproduction steps for each failure
- The orchestrator will return affected tasks to "In Progress" with your findings

**On PASS:**
- Include all proof screenshots and test output
- The orchestrator will post proof as a comment on the Linear tasks and mark them Done
</validation_gate>

</sequential_tasks>

## Guide Index

| Guide | Purpose |
|-------|---------|
| `guides/quality-gates.md` | How to run lint, typecheck, test, build |
| `guides/e2e-verification.md` | Browser-based functional testing with agent-browser (PRIMARY) |
| `guides/api-verification.md` | API endpoint testing |
| `guides/database-verification.md` | Migration and schema verification |
| `guides/security-checklist.md` | Security requirements checklist |
| `guides/deployment-verification.md` | Deployment and environment checks |
| `guides/anti-pattern-check.md` | Known anti-pattern detection |
| `guides/report-format.md` | Standard report format |
