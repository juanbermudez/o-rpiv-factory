# Quality Gates — Verification Guide

This guide defines how the verifier runs and interprets quality gates. The verifier runs all four gates even if one fails — all failures are reported together.

## Setup

Before running gates, ensure you are on the correct branch:

```bash
git checkout {branch-name}
git pull origin {branch-name}
```

Verify the diff:
```bash
git diff main...HEAD --stat
git diff main...HEAD
```

Read the diff completely before running any gate. This prevents misattributing existing failures to the new changes.

## Running All Four Gates

```bash
pnpm lint 2>&1 | tee /tmp/gate-lint.txt
pnpm typecheck 2>&1 | tee /tmp/gate-typecheck.txt
pnpm test 2>&1 | tee /tmp/gate-test.txt
pnpm build 2>&1 | tee /tmp/gate-build.txt
```

Run all four. Do not stop after the first failure.

## Gate Interpretations

### Lint

**Pass**: No output, or only informational messages (not warnings/errors)
**Fail**: Any warning or error line

Common failures and what they mean:
- `no-unused-vars` — Imported type/var not used. Implementation agent missed cleanup.
- `@typescript-eslint/consistent-type-imports` — Should be `import type`. Structural issue, easy fix.
- `no-console` — Debug `console.log` left in. Implementation agent left debug code.

Record the exact rule name and file:line.

### Typecheck

**Pass**: Zero errors (exit code 0)
**Fail**: Any `error TS` line

Common failures:
- `TS2345: Argument of type X is not assignable to parameter of type Y` — Type mismatch
- `TS2339: Property X does not exist on type Y` — Missing property, often a database type not updated
- `TS7006: Parameter has implicitly 'any' type` — Missing type annotation

Record the error code, file:line, and message.

### Tests

**Pass**: All tests pass (exit code 0, summary shows 0 failures)
**Fail**: Any test shows FAIL status

For each failing test, record:
- Test file path
- Test description (the `it()` string)
- Expected vs received values

Determine: Is the test correct and the implementation wrong? Or is the test wrong? Note your assessment — but do NOT fix either. Report it.

### Build

**Pass**: "Route (app)" table appears without errors, exit code 0
**Fail**: Any `Error:` line in output

Common failures:
- `Module not found` — Wrong import path
- `You're importing a component that needs X` — Server/client boundary violation
- `ReferenceError` — Runtime code issue caught at build time

## Reporting Format

Record results for the report:

```
## Quality Gates

| Gate | Result | Notes |
|------|--------|-------|
| lint | PASS | |
| typecheck | FAIL | TS2345 at src/app/api/v1/orders/route.ts:23 |
| test | PASS | |
| build | PASS | |

**Overall**: FAIL — 1 quality gate failed

### Lint Output
(paste relevant lines)

### Typecheck Errors
(paste error lines with file:line)
```

See [report-format.md](report-format.md) for full report structure.
