# API Route Pattern Guide

This guide describes a standard pattern for Next.js API routes. It uses Supabase + a permission middleware as a concrete example — adapt the specifics to your project's auth and database setup.

> **This is an example pattern, not a fixed requirement.** Your project may use a different folder structure, ORM, or auth library. Use this as a reference and match your existing codebase conventions.

## Example: Next.js App Router API Route (Supabase + Permission Middleware)

The example below assumes:
- Next.js App Router at `src/app/api/`
- A `withPermission` middleware that provides an authenticated Supabase client and user context
- Zod for input validation

```typescript
import { withPermission } from '@/lib/permissions/middleware'
import { ok, badRequest, serverError } from '@/lib/api/responses'
import { z } from 'zod'

// 1. Define Zod schema before the handler
const createSchema = z.object({
  name: z.string().min(1),
  amount_cents: z.number().int().positive(),
})

// 2. Export named method handler wrapped in withPermission
export const POST = withPermission('resource.create', async (req, ctx) => {
  try {
    // 3. Parse and validate body with Zod
    const body = createSchema.parse(await req.json())

    // 4. Query database using ctx.supabase
    const { data, error } = await ctx.supabase
      .from('table_name')
      .insert({ ...body })
      .select()
      .single()

    if (error) throw error

    // 5. Return typed response
    return ok({ data })
  } catch (error) {
    if (error instanceof z.ZodError) return badRequest({ error: error.message })
    return serverError({ error: 'Failed to create resource' })
  }
})
```

## Context Object (`ctx`)

The `withPermission` middleware typically provides:
- `ctx.supabase` — database client authenticated as the current user
- `ctx.userId` — the authenticated user's ID
- Other fields depending on your auth setup (e.g. `ctx.tenantId`, `ctx.roles`)

Never read user identity from the request body. Always use the authenticated context object.

## List Endpoint Pattern

```typescript
export const GET = withPermission('resource.list', async (req, ctx) => {
  try {
    const { searchParams } = new URL(req.url)
    const status = searchParams.get('status')

    let query = ctx.supabase
      .from('table_name')
      .select('id, name, amount_cents, created_at')
      .order('created_at', { ascending: false })

    if (status) {
      query = query.eq('status', status)
    }

    const { data, error } = await query
    if (error) throw error

    return ok({ data })
  } catch (error) {
    return serverError({ error: 'Failed to list resources' })
  }
})
```

## Audit Logging for Write Operations

If your project uses audit logging, emit a log after successful write operations:

```typescript
import { createAuditLog } from '@/lib/audit/log'

// After successful write:
await createAuditLog({
  event: 'resource.created',
  userId: ctx.userId,
  resourceId: data.id,
  metadata: { name: body.name },
})
```

## Common HTTP Response Helpers

| Helper | HTTP Status | Use When |
|--------|-------------|----------|
| `ok({ data })` | 200 | Success with data |
| `created({ data })` | 201 | Resource created |
| `badRequest({ error })` | 400 | Validation failed |
| `unauthorized()` | 401 | Not authenticated |
| `forbidden()` | 403 | Authenticated but no permission |
| `notFound()` | 404 | Resource does not exist |
| `serverError({ error })` | 500 | Unexpected error |

## File Location Convention (Example)

This is one way to organize API routes in a Next.js App Router project:

```
src/app/api/{resource}/
  route.ts        # GET list, POST create
  [id]/
    route.ts      # GET single, PUT update, DELETE
```

Adapt to match your project's existing structure.

## Security Checklist (Adapt to Your Project)

- [ ] Every handler is protected by authentication middleware
- [ ] All user input is validated before use (Zod or similar)
- [ ] Monetary values are received and stored as integers (cents)
- [ ] No secrets, tokens, or PII in logs or error messages
- [ ] Audit log emitted for all write operations (if your project requires this)
- [ ] Authorization checked (does this user have permission for this resource?)
