# Learnings Integration Guide

This guide defines how to incorporate past solutions from `docs/solutions/` into a planning session.

## Why This Matters

The knowledge base captures hard-won lessons. A PRD that ignores them will send implementation agents into known traps, wasting time and producing defects that were already solved.

## When to Search

### Always Search

Before writing any PRD, search `docs/solutions/` for:
1. The feature area (e.g., "orders", "users", "products")
2. The technical components involved (e.g., "RLS", "migration", "withPermission")
3. The problem category (e.g., "database-issues", "security-issues")

### Always Read Critical Patterns

```bash
cat docs/solutions/patterns/critical-patterns.md
```

This file is short and mandatory. Every planning agent reads it before writing a PRD.

## Search Commands

```bash
# By feature area
grep -r "orders" docs/solutions/ --include="*.md" -l

# By technical component
grep -r "organization_id" docs/solutions/ --include="*.md" -l
grep -r "RLS" docs/solutions/ --include="*.md" -l

# By severity
grep -r "severity: critical" docs/solutions/ --include="*.md" -l

# By category
ls docs/solutions/database-issues/
ls docs/solutions/security-issues/
```

## Integration Points

### In Implementation Notes

Reference specific solution docs in the PRD's "Implementation Notes" section:

```markdown
## Implementation Notes

**Known Issues to Avoid**:
- Do NOT skip `organization_id` scoping on any query — see `docs/solutions/security-issues/missing-org-scope.md`
- Monetary values MUST be stored as BIGINT cents — see `docs/solutions/database-issues/float-money-storage.md`
```

### In Task Descriptions

When creating task context files, include `solutionPointers` for relevant learnings:

```json
{
  "solutionPointers": [
    "docs/solutions/database-issues/rls-missing-grant.md",
    "docs/solutions/api-issues/withpermission-missing.md"
  ]
}
```

### In Acceptance Criteria

Anti-patterns from the knowledge base can become acceptance criteria:

```
5. Organization_id scoping is verified — direct query without org context returns 0 rows
6. No float values in database for monetary amounts
```

## What to Extract From Each Solution Doc

For each matching solution document, extract:
- **Problem summary**: What situation triggers this
- **WRONG pattern**: What not to write
- **CORRECT pattern**: What to write instead
- **Prevention check**: How to verify the PRD avoids this

## When No Learnings Are Found

Explicitly state in the PRD's "Implementation Notes":

```
**Learnings Search**: No directly applicable solutions found in docs/solutions/ for {keywords searched}.
If issues arise during implementation, the implementer should log them for future compounding.
```

This tells future readers the search was done and wasn't skipped.
