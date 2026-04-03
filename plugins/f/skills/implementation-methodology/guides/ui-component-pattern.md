# UI Component Pattern Guide

This guide describes how to implement UI components in a Next.js app using shadcn/ui and Tailwind. Adapt the specifics to your project's component library and styling approach.

> **This is an example pattern, not a fixed requirement.** Your project may use a different component library, CSS approach, or folder structure. Use this as a reference and match your existing codebase conventions.

## Core Rules

1. **Use your project's component library** — Do not reach for raw HTML elements or custom CSS when a shared component exists.
2. **Read your project's design system docs first** — Check `docs/DESIGN_SYSTEM.md` or equivalent for the component inventory and usage patterns.
3. **Server components by default** — Only add `"use client"` when the component needs interactivity (state, events, browser APIs).

## Component File Location

Adapt to your project's conventions. One common structure:

```
src/components/
  {feature}/
    {FeatureName}List.tsx     # List/table view
    {FeatureName}Card.tsx     # Card component
    {FeatureName}Form.tsx     # Create/edit form
    {FeatureName}Dialog.tsx   # Modal/dialog
```

Pages:
```
src/app/(dashboard)/{feature}/
  page.tsx         # Server component, fetches data
  [id]/
    page.tsx       # Detail page
```

## Server Component Pattern (Data Fetching)

```typescript
// page.tsx — server component
import { createServerClient } from '@/lib/supabase/server'
import { OrderList } from '@/components/orders/OrderList'

export default async function OrdersPage() {
  const supabase = createServerClient()
  const { data: orders } = await supabase
    .from('orders')
    .select('id, name, amount_cents, created_at')
    .eq('status', 'active')
    .order('created_at', { ascending: false })

  return <OrderList orders={orders ?? []} />
}
```

## Client Component Pattern (Interactivity)

```typescript
"use client"

import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

interface OrderFormProps {
  onSubmit: (data: CreateOrderInput) => Promise<void>
}

export function OrderForm({ onSubmit }: OrderFormProps) {
  const [isPending, setIsPending] = useState(false)

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    setIsPending(true)
    try {
      // ... handle form submission
    } finally {
      setIsPending(false)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <Input name="name" required />
      <Button type="submit" disabled={isPending}>
        {isPending ? 'Saving...' : 'Save'}
      </Button>
    </form>
  )
}
```

## Monetary Value Display

Never display raw cents. Always format with a utility:

```typescript
// Display price
const displayPrice = (cents: number) =>
  new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(cents / 100)

// Usage
<span>{displayPrice(order.amount_cents)}</span>
```

## Common shadcn/ui Components

| Need | Component |
|------|-----------|
| Data table | `<Table>` from `@/components/ui/table` |
| Modal/dialog | `<Dialog>` from `@/components/ui/dialog` |
| Form inputs | `<Input>`, `<Select>`, `<Textarea>` from `@/components/ui/` |
| Action button | `<Button>` from `@/components/ui/button` |
| Loading state | `<Skeleton>` from `@/components/ui/skeleton` |
| Notifications | `toast()` from `@/components/ui/use-toast` |
| Status badge | `<Badge>` from `@/components/ui/badge` |

**Before importing a component**, verify it is installed:
```bash
ls src/components/ui/
```

If missing, add it:
```bash
npx shadcn@latest add {component}
```

## Loading and Error States

Always handle loading and error states:

```typescript
// In a client component fetching data
if (isLoading) return <Skeleton className="h-48 w-full" />
if (error) return <p className="text-destructive">Failed to load data</p>
if (!data?.length) return <p className="text-muted-foreground">No items found</p>
```

## Type Safety

Define prop types explicitly. Derive from your database types when possible:

```typescript
import type { Database } from '@/types/database'

type Order = Database['public']['Tables']['orders']['Row']

interface OrderCardProps {
  order: Pick<Order, 'id' | 'name' | 'amount_cents' | 'created_at'>
}
```
