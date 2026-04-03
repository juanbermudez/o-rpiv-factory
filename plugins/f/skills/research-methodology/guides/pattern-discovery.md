# Pattern Discovery Guide

Use this guide when your research type is `pattern-discovery` — finding reusable code patterns in the codebase for a new feature.

## Goal

Find 2-3 existing implementations that are at least 60% similar to the feature being built. The implementation agent copies the pattern, not invents a new one.

## The 60% Reuse Rule

A pattern is "reusable" if the new feature shares:
- Same architectural layer (API route, UI component, migration, etc.)
- Same data shape (similar schema, similar response structure)
- Same security requirements (same `withPermission` scope type, same RLS pattern)
- At least 3 of the 5 above criteria

If no pattern reaches 60% similarity, note this explicitly and provide the closest available example.

## Discovery Process

### 1. Identify the Feature Type

Determine what kind of thing is being built:
- **New API endpoint**: Find 2-3 existing routes in `src/app/api/v1/` (or your project's API directory)
- **New UI component**: Find 2-3 similar components in `src/components/` (or your project's component directory)
- **New database table**: Find 2-3 recent migrations in `migrations/` (e.g., `supabase/migrations/`)
- **New background job**: Find 2-3 similar jobs in your project's jobs directory
- **New mobile screen**: Find 2-3 similar screens in your project's mobile app directory

### 2. Search Strategy

```bash
# For API routes: find similar resource routes
ls src/app/api/v1/

# For components: search by UI pattern
grep -r "Button\|Dialog\|Table" src/components --include="*.tsx" -l

# For migrations: find the most recent ones
ls -t migrations/ | head -10

# For features: grep for similar business domain
grep -r "user" src/app/api/v1 --include="*.ts" -l
```

### 3. Evaluate Each Candidate

For each candidate pattern, record:
- **File path + line range** of the core implementation
- **Similarity score** (rough %, which criteria match)
- **Key pattern elements**: what to copy (structure, naming, imports)
- **Differences**: what the new feature needs that this pattern doesn't have

### 4. Extract the Pattern

For the best-matching candidate, extract:

```
Pattern: [Name]
Source:  src/app/api/v1/orders/route.ts:1-52
Similarity: ~75%

Structure to copy:
- Import: withPermission from '@/lib/permissions/middleware'
- Import: ok, badRequest, serverError from '@/lib/api/responses'
- Schema: z.object({ field: z.string() }) before export
- Handler: export const GET = withPermission('scope', async (req, ctx) => {...})
- Query: ctx.supabase.from('table').select().eq('organization_id', ctx.organizationId)
- Response: return ok({ data })

Differences for new feature:
- Uses POST not GET
- Needs audit log (see your project's audit log utility)
```

## Output Requirements

Your pattern discovery output must include:
- Top 2-3 pattern candidates with file:line references
- Similarity assessment for each
- The recommended pattern to follow (with reasoning)
- Code structure to copy (imports, function signature, query shape, response format)
- Explicit differences the implementation agent must handle
- Anti-patterns found nearby that should NOT be copied
