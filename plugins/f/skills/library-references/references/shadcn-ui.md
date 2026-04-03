# shadcn/ui Reference

Common mistakes Claude makes with shadcn/ui and Tailwind. Read this before writing any UI component code.

---

## Tailwind v4

If your project uses **Tailwind CSS v4**, be aware that it has a fundamentally different configuration model from v3.

**WRONG** — `tailwind.config.js` does not exist in v4:
```javascript
// tailwind.config.js  -- WRONG: not used in Tailwind v4
module.exports = {
  theme: { extend: { colors: { brand: '#...' } } }
}
```

**CORRECT** — Configuration lives in CSS using `@theme` directive:
```css
@import "tailwindcss";

@theme {
  --color-brand: #...;
  --font-sans: "Inter", sans-serif;
}
```

**Class changes in v4**:
- No more `className` string concatenation for responsive variants — use CSS layers
- `bg-opacity-*` is gone — use `bg-black/50` syntax
- `divide-*` utilities work differently — check v4 docs

---

## Component Import Paths

All shadcn/ui components live in `@/components/ui/{component}`:
```typescript
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardContent, CardTitle } from '@/components/ui/card'
import { Dialog, DialogTrigger, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
```

**Before importing a component**, check if it is installed:
```bash
ls src/components/ui/
```

If missing, add it:
```bash
npx shadcn@latest add {component}
```

Do NOT import from `@shadcn/ui` or `shadcn-ui` directly — those are not the correct packages.

---

## Composition Patterns

shadcn/ui uses compound component patterns. Always use the full compound:

**Card**:
```tsx
<Card>
  <CardHeader>
    <CardTitle>Title</CardTitle>
    <CardDescription>Description</CardDescription>
  </CardHeader>
  <CardContent>
    {/* content */}
  </CardContent>
  <CardFooter>
    {/* actions */}
  </CardFooter>
</Card>
```

**Dialog** — always include `DialogDescription` for accessibility:
```tsx
<Dialog>
  <DialogTrigger asChild>
    <Button>Open</Button>
  </DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Title</DialogTitle>
      <DialogDescription>Description of what this dialog does.</DialogDescription>
    </DialogHeader>
    {/* content */}
  </DialogContent>
</Dialog>
```

Use `asChild` on `DialogTrigger`, `DropdownMenuTrigger`, etc. when wrapping a custom element to avoid extra DOM nodes.

---

## Form Patterns

Forms work best with **react-hook-form + zod + shadcn Form components**.

**WRONG** — Controlled inputs with useState:
```tsx
const [name, setName] = useState('')
<Input value={name} onChange={e => setName(e.target.value)} />  // WRONG
```

**CORRECT** — react-hook-form with shadcn Form:
```tsx
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { Form, FormField, FormItem, FormLabel, FormControl, FormMessage } from '@/components/ui/form'

const schema = z.object({ name: z.string().min(1) })

const form = useForm({ resolver: zodResolver(schema) })

<Form {...form}>
  <form onSubmit={form.handleSubmit(onSubmit)}>
    <FormField
      control={form.control}
      name="name"
      render={({ field }) => (
        <FormItem>
          <FormLabel>Name</FormLabel>
          <FormControl>
            <Input {...field} />
          </FormControl>
          <FormMessage />
        </FormItem>
      )}
    />
    <Button type="submit">Submit</Button>
  </form>
</Form>
```

---

## cn() Utility

Use the `cn()` utility for conditional classnames (already installed at `@/lib/utils`):

```typescript
import { cn } from '@/lib/utils'

<div className={cn('base-class', isActive && 'active-class', className)} />
```

Do NOT use `clsx` or `classnames` directly — `cn()` wraps both `clsx` and `tailwind-merge`.

---

## Design System

Check your project's design system documentation (e.g. `docs/DESIGN_SYSTEM.md`) for the full component inventory, spacing scales, and color tokens. Always check there before inventing custom styles.
