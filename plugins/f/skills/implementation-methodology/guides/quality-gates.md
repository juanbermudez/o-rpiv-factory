# Quality Gates Guide

All four quality gates must pass before an implementation is considered complete. Run them after each commit and again at the end.

## The Four Gates

### 1. Lint

```bash
pnpm lint
```

Zero warnings. Zero errors. If it produces output, it has not passed.

Common issues:
- Unused imports
- Missing `import type` for type-only imports
- ESLint rule violations

Fix them. Do not add `eslint-disable` comments.

### 2. Typecheck

```bash
pnpm typecheck
```

No TypeScript errors. If you see `TS2345` or any other TS error, fix the type.

Do not use `// @ts-ignore`. Fix the type.

**Note**: Full typechecks on large apps can take several minutes. For faster targeted checks during development:

```bash
# Check just the files you changed
cd apps/web && npx tsc --noEmit --incremental

# Check a specific package
pnpm --filter {PACKAGE_NAME} typecheck
```

### 3. Tests

```bash
pnpm test
```

All tests pass. Zero failures.

For faster targeted runs during development:

```bash
# Run tests for a specific package
pnpm --filter {PACKAGE_NAME} test

# Run a specific test file
pnpm --filter {PACKAGE_NAME} test -- src/app/api/orders/route.test.ts

# Run in watch mode
pnpm --filter {PACKAGE_NAME} test -- --watch
```

Never skip failing tests. Never use `.skip`. Fix the test or fix the code.

### 4. Build

```bash
pnpm --filter {WEB_FILTER} build
```

Build must succeed. If it fails after lint and typecheck pass, it is usually a runtime import issue.

For non-web packages:
```bash
pnpm --filter {MOBILE_FILTER} build
pnpm --filter {JOBS_FILTER} build
```

## Running All Four

```bash
pnpm lint && pnpm typecheck && pnpm test && pnpm --filter {WEB_FILTER} build
```

Run this sequence before reporting completion. All four must pass.

## Interpreting Failures

### Lint failure
Read the rule name (e.g., `@typescript-eslint/no-unused-vars`). Fix the specific issue.

### Typecheck failure
The error includes file:line. Read the error message. The fix is usually:
- Add a missing type annotation
- Fix an incorrect type cast
- Add a null check for potentially undefined value
- Use `import type` instead of `import`

### Test failure
The test output includes the expected vs received values. Fix the implementation (not the test) unless the test expectation is wrong.

### Build failure
Usually caused by:
- Missing import
- Incorrect default export
- Environment variable used in server component (prefix with `NEXT_PUBLIC_` for client)

## Before Reporting Done

Run the full gate sequence and include the output in your implementation log if any required fixes:

```
Quality gates: lint ✓ | typecheck ✓ | test ✓ | build ✓
```
