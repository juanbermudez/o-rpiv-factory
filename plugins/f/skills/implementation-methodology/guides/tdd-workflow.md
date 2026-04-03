# TDD Workflow Guide

This guide defines the test-driven development approach for implementation tasks.

## The Cycle

```
RED → GREEN → REFACTOR → COMMIT → REPEAT
```

Never skip the RED phase. If you write code before the test, you have no confidence the test is meaningful.

## RED: Write the Failing Test

Write the test first. The test should:
- Describe the behavior, not the implementation
- Use the acceptance criteria from the task context as your test cases
- Fail for the right reason (not "module not found" but "expected X, got Y")

```typescript
// Example: testing a new API endpoint
describe('GET /api/orders', () => {
  it('returns orders for the authenticated user', async () => {
    // Arrange: set up user + orders
    // Act: call the endpoint
    // Assert: response contains only the user's orders
  })

  it('returns 401 when unauthenticated', async () => {
    // Act: call without auth
    // Assert: 401
  })
})
```

Run the test. Confirm it fails. If it passes, your test is wrong or the feature already exists.

## GREEN: Minimal Implementation

Write the minimum code to make the test pass. Do not:
- Add extra features not in the acceptance criteria
- Handle edge cases not covered by tests yet
- Refactor for elegance (that's the next phase)

Just make the test pass.

## REFACTOR: Clean Up

With tests passing, improve the code:
- Extract shared logic into helpers if used 3+ times
- Improve naming for clarity
- Remove duplication
- Run linter and fix any warnings

Tests must still pass after refactoring.

## COMMIT: Atomic Commit

Each RED→GREEN→REFACTOR cycle gets one commit. See [git-workflow.md](git-workflow.md).

## Test File Locations

Co-locate test files with the source files they test:

| Code Location | Test Location |
|---------------|---------------|
| `src/app/api/orders/route.ts` | `src/app/api/orders/route.test.ts` |
| `src/lib/orders/queries.ts` | `src/lib/orders/queries.test.ts` |
| `src/components/OrderCard.tsx` | `src/components/OrderCard.test.tsx` |

Alternatively, use a `__tests__/` directory — follow whatever convention your project already uses.

## Test Framework

Use the test framework your project already has configured. Common choices:

- **Next.js / Node.js**: Vitest (`vitest.config.ts`) or Jest
- **React Native / Expo**: Jest with `jest-expo` preset
- **E2E**: Playwright or Cypress

Do not mix frameworks. Do not introduce a new test framework without project approval.

## Running Tests

Adapt these commands to your package manager and project structure:

```bash
# Run all tests
pnpm test
# or: npm test, yarn test, npx vitest

# Run tests for a specific package (monorepo)
pnpm --filter {PACKAGE_NAME} test

# Run a specific test file
pnpm test -- src/app/api/orders/route.test.ts

# Watch mode during development
pnpm test -- --watch
```

## What Not to Test

- Implementation details that could change without breaking behavior
- Framework internals — trust the framework
- Database schema (test the migration runs, not the database client)

## What Must Be Tested

- Authentication enforcement (unauthenticated returns 401)
- Authorization enforcement (wrong user returns 403 or empty)
- Input validation (missing fields return 400 with correct error)
- Business logic (calculations, state transitions, filtering)
- Error paths (what happens when the database returns an error)
