# Verification Report Format

The verification report is written to `.resources/context/{slug}/tasks/{task-id}-verify.md`. This is your only deliverable.

## Report Template

```markdown
# Verification Report: {TASK-XXX}

**Task**: {task title}
**Branch**: {branch name}
**Verifier**: {agent ID}
**Date**: {YYYY-MM-DD}
**Result**: PASS | FAIL

---

## Summary

{1-2 sentence summary. If FAIL, state the primary reason immediately.}

---

## Quality Gates

| Gate | Result | Notes |
|------|--------|-------|
| lint | PASS/FAIL | {notes or blank} |
| typecheck | PASS/FAIL | {error count or blank} |
| test | PASS/FAIL | {failure count or blank} |
| build | PASS/FAIL | {notes or blank} |

{If any gate FAILED, include the relevant output below:}

### Lint Output
```
{paste lint output}
```

### Typecheck Errors
```
{paste typecheck errors with file:line}
```

### Test Failures
```
{paste failing test names and expected vs received}
```

---

## Anti-Pattern Check

| Check | Result | Notes |
|-------|--------|-------|
| No missing org scope | PASS/FAIL | |
| No float money storage | PASS/FAIL | |
| withPermission on all routes | PASS/FAIL | |
| No raw req.json() | PASS/FAIL | |
| No @ts-ignore | PASS/FAIL | |
| No disabled tests | PASS/FAIL | |

{If any check FAILED, include file:line and the offending code.}

---

## Security Checklist

| Check | Result | Notes |
|-------|--------|-------|
| withPermission middleware | PASS/FAIL | |
| organization_id scoping | PASS/FAIL | |
| Zod validation | PASS/FAIL | |
| No PII in logs | PASS/FAIL | |
| No secrets in code | PASS/FAIL | |
| RLS policies (if applicable) | PASS/N/A | |
| Monetary values as cents | PASS/FAIL | |

---

## Task-Specific Verification

### {Verification Type: API / E2E / Database / Deployment}

{Results from the applicable guide.}

---

## Acceptance Criteria

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | {criterion text} | PASS/FAIL | {how you verified it} |
| 2 | {criterion text} | PASS/FAIL | {how you verified it} |
| ... | | | |

---

## Issues Found

{List all issues if result is FAIL. Empty if PASS.}

### Issue 1: {Brief description}
- **Severity**: CRITICAL | HIGH | MEDIUM | LOW
- **File**: {file path}:{line}
- **Description**: {what is wrong}
- **Suggested fix**: {what the implementer should change}
- **Reference**: {docs/solutions/ path if applicable}

---

## Recommendation

{APPROVE for merge | REQUEST CHANGES}

{One paragraph explaining the recommendation. If APPROVE, note any minor observations that should be addressed in a follow-up. If REQUEST CHANGES, list the blocking issues that must be resolved.}
```

## Result Determination

**PASS** — All of the following are true:
- All 4 quality gates pass
- No anti-pattern matches
- All acceptance criteria met
- Security checklist clean

**FAIL** — Any of the following is true:
- Any quality gate fails
- Any anti-pattern match found
- Any acceptance criterion not met
- Any security issue found

There is no partial pass. A single FAIL in any category means the overall result is FAIL.
