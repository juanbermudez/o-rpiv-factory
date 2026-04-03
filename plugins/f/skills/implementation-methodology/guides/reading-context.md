# Reading Context Guide

This guide defines how to read and use the task context file and file pointers before implementing.

## The Task Context File

The orchestrator provides a path to a JSON file at `.resources/context/{project-slug}/tasks/{task-id}.json`. This file is your map. Read it first.

Key fields to extract:

1. **objective** — One sentence. What you're building and why.
2. **filePointers** — Exact files and line ranges to read before coding.
3. **patternAnchors** — Which file to copy the implementation pattern from.
4. **solutionPointers** — Past learnings that apply to this task.
5. **acceptanceCriteria** — The contract you must satisfy.
6. **verificationMethod** — How the verifier will check your work.

## Reading File Pointers

For each entry in `filePointers`, read the file at the specified line range:

```json
{
  "path": "apps/web/src/app/api/v1/orders/route.ts",
  "lines": "1-52",
  "purpose": "Pattern to follow — matches the shape of the new endpoint"
}
```

When reading, answer these questions:
- What is the overall structure? (imports, schema, handler, response)
- What security pattern is used? (withPermission scope name)
- What query pattern is used? (table name, filters, selects)
- What response shape is used? (ok(), badRequest(), etc.)

Do not guess. Read the actual code.

## Reading Pattern Anchors

Pattern anchors are the files you will copy from. After reading them:

1. Identify the exact import statements to replicate
2. Identify the Zod schema shape
3. Identify the `withPermission` scope
4. Identify the Supabase query structure
5. Identify the error handling pattern

This is your template. Do not deviate from it without a documented reason.

## Reading Solution Pointers

For each `solutionPointers` entry:
1. Read the full solution document
2. Find the WRONG vs CORRECT code comparison
3. Explicitly avoid the WRONG pattern in your implementation
4. Confirm that your implementation matches the CORRECT pattern

If a solution pointer says "never skip ownership/tenant scoping," verify your query includes it before committing.

## Reading the PRD

The PRD pointer leads to the full feature specification. Read:
- **Acceptance Criteria** — These are the tests you must pass
- **Data Model** — The exact column names and types
- **API Specification** — The exact endpoint contract
- **Security Requirements** — The permission scopes and RLS requirements

## Building Your Implementation Plan

After reading all context, write a brief plan before coding:
1. Files to create (new)
2. Files to modify (existing)
3. Test file to write first
4. Order of operations

This plan lives in your head (or as a quick note in the impl log). It prevents starting in the wrong place.
