# Codebase Exploration Guide

Use this guide when your research type is `codebase-exploration` — understanding existing code, architecture, and data flow.

## Goal

Map the existing code so that implementation agents have exact file paths and line numbers to work with. You are building a navigational guide, not writing new code.

## Exploration Strategy

### 1. Start From the Entry Points

The orchestrator provides file pointers. Begin there and fan out:
- Read the file at the specified line range
- Identify what it imports, calls, or exports
- Follow each dependency one level deep

Do NOT try to read the entire codebase. Depth-first from entry points, not breadth-first.

### 2. Map the Architecture

For each major component, identify:
- **Layer**: API route / service / repository / UI component / migration / job
- **File path and line range** for the core logic
- **Data flow**: What goes in, what comes out, what side effects occur

Example mapping:
```
Order listing API
  Route:      src/app/api/v1/orders/route.ts:1-45
  Permission: withPermission('orders.list', ...) at line 8
  Query:      src/lib/orders/queries.ts:12-38
  Response:   ok({ data: orders }) at line 31
```

### 3. Identify Pattern Anchors

Find 2-3 implementations that closely match the feature being researched. These become pattern anchors for the implementation agent. Record:
- File path + line range
- What the pattern does
- Why it is the right model to follow

### 4. Trace Data Models

For database-related work:
- Locate the table definition in `supabase/migrations/`
- Locate the TypeScript type in `apps/web/src/types/database.ts`
- Locate any RLS policies
- Locate any related API routes that touch the table

### 5. Surface Anti-Patterns

Note code you find that should NOT be copied:
- Queries missing `organization_id` scoping
- Routes missing `withPermission`
- Monetary values stored as floats
- Raw `req.json()` without Zod validation

## Tools and Commands

```bash
# Find all files matching a pattern
find src -name "*.ts" | xargs grep -l "orders"

# Find usages of a function or type
grep -r "withPermission" src/app/api --include="*.ts" -l

# Find migration files for a table
ls migrations/ | grep order

# Find TypeScript type definitions
grep -n "orders" src/types/database.ts
```

Use the Read tool for file contents, Grep for pattern searches, Glob for file discovery.

## Output Requirements

Your codebase exploration output must include:
- Architecture diagram (text or Mermaid) showing component relationships
- File:line references for every code location mentioned
- Pattern anchors: 2-3 similar implementations the implementer should follow
- Anti-patterns found (with file:line)
- Data model summary (table schema, TypeScript type, RLS policy locations)
- Gaps: anything you could not determine from the code alone
