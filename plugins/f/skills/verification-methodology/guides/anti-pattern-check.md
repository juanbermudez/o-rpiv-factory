# Anti-Pattern Check Guide

This guide defines how to check changed files against known anti-patterns from `docs/solutions/`.

## Why This Matters

The knowledge base in `docs/solutions/` contains patterns that were identified through real incidents. Matching an anti-pattern is an automatic FAIL — not a warning.

## Step 1: Read Critical Patterns

Always read this file first:

```bash
cat docs/solutions/patterns/critical-patterns.md
```

This file lists the most serious recurring patterns with code examples showing WRONG vs CORRECT. Read it completely before reviewing any code.

## Step 2: Search for Related Solutions

Search the knowledge base for topics related to the changed components:

```bash
# By feature area
grep -r "{feature-name}" docs/solutions/ --include="*.md" -l

# By component name
grep -r "{component}" docs/solutions/ --include="*.md" -l

# By severity (always check critical)
grep -r "severity: critical" docs/solutions/ --include="*.md" -l
```

For each matching document, read the WRONG pattern section and grep the changed files for it.

## Step 3: Automated Pattern Checks

Run these checks against every changed file:

### Missing Org Scope

```bash
# Find Supabase queries potentially missing org scope
grep -n "\.from(" {changed-file} | grep -v "organization_id"
```

Manually verify: Does each `.from()` chain include `.eq('organization_id', ...)` or is it on a table that doesn't need org scoping (e.g., `organizations` table itself)?

### Float Money Storage

```bash
# Check for non-integer monetary handling
grep -n "DECIMAL\|FLOAT\|NUMERIC" {changed-files}
grep -n "_price[^_]\|_cost[^_]\|_amount[^_]" {changed-files}
```

Any monetary field should end with `_cents` and be `BIGINT`/`number`.

### Missing withPermission

```bash
# Find exported route handlers not wrapped in withPermission
grep -n "export const GET\|export const POST\|export const PUT\|export const DELETE" {api-files}
grep -n "withPermission" {api-files}
```

Count them: exported handlers should equal withPermission wraps.

### Raw Request Body

```bash
grep -n "await req.json()" {api-files}
grep -n "\.parse(" {api-files}
```

Every `req.json()` should be followed by `.parse()` from a Zod schema.

### TypeScript Ignores

```bash
grep -rn "@ts-ignore\|@ts-nocheck" {changed-files}
```

Any TypeScript suppression is FAIL. Fix the type.

### Disabled Tests

```bash
grep -rn "it\.skip\|test\.skip\|describe\.skip\|xit\|xdescribe" {changed-files}
```

Disabled tests are FAIL. Either fix the test or the code.

## Step 4: Document Findings

For each anti-pattern match:

```
Anti-Pattern: Missing organization_id scope
Severity: CRITICAL
File: src/app/api/v1/orders/route.ts
Line: 23
Code: ctx.supabase.from('orders').select('*')
Expected: ctx.supabase.from('orders').select('*').eq('organization_id', ctx.organizationId)
Reference: docs/solutions/security-issues/missing-org-scope.md
```

Any match is an automatic FAIL in the verification report.
