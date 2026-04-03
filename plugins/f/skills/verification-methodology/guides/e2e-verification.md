# E2E & Browser Verification Guide

This is the **primary verification guide**. Use it for all UI features, browser-based functional testing, design review, and proof collection. The `agent-browser` skill (installed at `.agents/skills/agent-browser/`) is the main tool for navigating the app and taking screenshots.

## Setup

### 1. Start Dev Server

```bash
# Start dev server (in a separate terminal or background)
pnpm dev  # or the project-specific command
# Server starts on localhost (port varies by project — check package.json or .env.local)
```

### 2. Test Credentials

Test credentials are in your project's `.env.local`. Look for:
- `TEST_USER_EMAIL`
- `TEST_USER_PASSWORD`
- `TEST_ORGANIZATION_ID`

### 3. Create Proof Directory

Every verification task collects proof — screenshots and test output:

```bash
mkdir -p .resources/context/{slug}/proof/TASK-XXX
```

### 4. Login

Navigate to `localhost:{port}/login` with agent-browser and authenticate using test credentials.

---

## Agent-Browser Workflow

The core loop for browser-based verification:

### Navigate → Snapshot → Interact → Verify → Screenshot

1. **Navigate**: Go to the target page URL
2. **Snapshot**: Observe the current state of the page (DOM snapshot / visual state)
3. **Interact**: Perform the user action (click, type, submit, etc.)
4. **Verify**: Check the page reflects the expected result (element visible, text matches, redirect occurred)
5. **Screenshot**: Capture the result as proof

### Example Flow

```
1. navigate("http://localhost:{port}/orders")
   → snapshot: verify order list loads with data
   → screenshot: save as "01-order-list-loaded.png"

2. click("Add Order" button)
   → snapshot: verify form opens
   → screenshot: save as "02-add-order-form.png"

3. fill form fields with valid data
   → submit form
   → snapshot: verify success toast + redirect to list
   → screenshot: save as "03-order-created-success.png"

4. verify new order appears in list
   → screenshot: save as "04-order-in-list.png"
```

### Screenshot Naming Convention

Save screenshots to the proof directory with numbered prefixes:
```
.resources/context/{slug}/proof/TASK-XXX/
  01-{page}-loaded.png
  02-{action}-result.png
  03-{scenario}-pass.png
  ...
```

---

## Testing Each Scenario

For each `test_scenario` in the verification task context file:

### 1. Read the Scenario
```json
{
  "description": "User can create a new order",
  "steps": [
    "Navigate to /orders page",
    "Click 'Add Order' button",
    "Fill in required fields",
    "Submit the form",
    "Verify success toast appears",
    "Verify new order appears in list"
  ],
  "expected_result": "Order is created and visible in list",
  "proof": "screenshot"
}
```

### 2. Execute Steps

Walk through each step using agent-browser. At each step:
- Perform the action
- Wait for the UI to settle (loading states, transitions)
- Verify the step completed (element visible, no error)

### 3. Record Result

```markdown
#### Scenario: User can create a new order
- Steps executed: All 6 steps
- Expected: Order is created and visible in list
- Actual: Order created successfully, appears at top of list
- Result: PASS
- Proof: .resources/context/{slug}/proof/TASK-XXX/03-order-created.png
```

### 4. Handle Failures

If a scenario fails:
- Screenshot the failure state
- Note the exact step that failed
- Note the expected vs. actual result
- Check browser console for errors (use agent-browser to capture console output)
- Continue with remaining scenarios (test everything, report all failures together)

---

## Running Playwright E2E Tests

If Playwright E2E tests exist for the feature, run them in addition to browser verification:

```bash
# Run all E2E tests (command varies by project — check package.json)
pnpm test:e2e

# Run a specific test file
pnpm test:e2e -- {feature}.spec.ts

# Run with browser visible (headed mode)
pnpm test:e2e -- --headed

# Debug mode (pauses on failures)
pnpm test:e2e -- --debug

# Save output as proof
pnpm test:e2e -- {feature}.spec.ts 2>&1 | tee .resources/context/{slug}/proof/TASK-XXX/e2e-results.txt
```

---

## Design Verification Checklist

Check the UI against the project's design system. Load any relevant design skill (e.g., `vercel-react-best-practices` for React/Next.js projects) for framework-specific guidance.

### Mandatory Checks

- [ ] **Components**: Uses the project's established component library — no custom primitives that duplicate existing components
- [ ] **List items**: Follows the project's established list/table pattern (check `DESIGN_SYSTEM.md` or equivalent)
- [ ] **Responsive**: Layout works at 375px width (mobile) and 1440px (desktop)
- [ ] **Loading states**: Spinners or skeletons for async data fetching
- [ ] **Empty states**: Meaningful message when no data exists (not a blank page)
- [ ] **Error states**: User-friendly error messages when operations fail
- [ ] **Typography**: Consistent with rest of app (font sizes, weights, colors)
- [ ] **Spacing**: Consistent padding/margins, no cramped or excessively spaced elements
- [ ] **Accessibility**: Interactive elements are keyboard-navigable, form labels present
- [ ] **No layout shifts**: Content doesn't jump when data loads

### How to Check Responsive

Use agent-browser to resize the viewport:
1. Check at 1440px width (desktop)
2. Check at 768px width (tablet)
3. Check at 375px width (mobile)
4. Screenshot any breakage

---

## Sentry Error Monitoring

Check for new errors introduced by the implementation:

### Before Testing
1. Note the current timestamp
2. Optionally check current error count for the project

### After Testing
1. Query Sentry for errors in the last hour:
   - Use Sentry MCP tools to query recent issues
   - Filter by project: `{your-sentry-project}`
   - Filter by timeframe: last 1 hour
   - Filter by environment: `development` or `preview`

2. If new errors found:
   - Capture error title, stack trace, and frequency
   - Include in the verification report as a FAIL item
   - Screenshot the Sentry issue detail

3. Expected result: **0 new unresolved errors**

---

## Org Scoping Verification (Required)

Every browser verification must confirm org isolation:

1. Log in as User A (org 1), perform the action, note the results
2. Log in as User B (org 2)
3. Verify User B cannot see User A's data (empty list, 403, or redirect)

This cannot be skipped. Org scoping is a security requirement, not a nice-to-have.

---

## Common Verification Patterns

### New Page or Route
```
1. Navigate to /path/to/new-page
2. Verify page loads without errors → screenshot
3. Verify data is displayed correctly → screenshot
4. Verify empty state when no data exists → screenshot
5. Verify error state when API fails
6. Check responsive at 375px → screenshot if issues
```

### New Form
```
1. Open the form → screenshot
2. Submit with all fields empty → verify validation errors → screenshot
3. Submit with invalid data → verify specific error messages
4. Submit with valid data → verify success state and redirect → screenshot
5. Verify the created record appears in the list → screenshot
```

### New Filter/Search
```
1. Load the page with existing data → screenshot
2. Apply the filter
3. Verify only matching results are shown → screenshot
4. Verify the URL reflects the filter state (for shareable links)
5. Clear the filter
6. Verify all results return
```

### Delete Operation
```
1. Navigate to list with existing record
2. Initiate delete (click delete button)
3. Verify confirmation dialog appears → screenshot
4. Confirm deletion
5. Verify record removed from list → screenshot
6. Verify deleted record no longer accessible via direct URL
```

---

## Recording Results

For each verification step, record:

| Field | Description |
|-------|-------------|
| Scenario | Which test scenario this covers |
| Step | What action was taken |
| Expected | What should have happened |
| Actual | What actually happened |
| Result | PASS or FAIL |
| Proof | Path to screenshot or test output file |
| Notes | Any observations, warnings, or context |

Screenshots are **mandatory** for browser verification. Every scenario must have at least one proof screenshot. Include the URL visible in the browser for each screenshot.
