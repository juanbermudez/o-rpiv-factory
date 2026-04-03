---
name: scaffolding
description: >
  Generate boilerplate code for API routes, database migrations, UI components,
  React Query hooks, and test files following project conventions. Replaces
  placeholders in templates and writes files to the correct target location in
  the project codebase.
---

# Scaffolding Skill

You are generating boilerplate code for a new feature. Your job is to read
the appropriate template, replace all `{{placeholders}}`, and write the file to
the correct target location.

---

## Templates

| Template | When to Use |
|----------|-------------|
| `templates/api-route.ts.template` | New API endpoint (e.g., in `src/app/api/v1/`) |
| `templates/migration.sql.template` | New table or schema change (e.g., in `supabase/migrations/` or your migration directory) |
| `templates/ui-component.tsx.template` | New UI client component (e.g., in `src/components/`) |
| `templates/test-file.test.ts.template` | Vitest unit or integration test alongside the file under test |
| `templates/hook.ts.template` | New React Query data-fetch hook (e.g., in `src/hooks/`) |

---

## Scaffold Process

1. **Identify the type** — determine which template applies based on the feature being built
2. **Read the template** — load the template file from `plugins/f/skills/scaffolding/templates/`
3. **Replace placeholders** — substitute every `{{placeholder}}` with a real value (see table below)
4. **Determine target path** — see Target Locations section
5. **Write the file** — write the scaffolded content to the target path
6. **Annotate TODOs** — after writing, list every `// TODO:` left in the file so the implementer knows what to fill in

### Placeholder Reference

| Placeholder | Replace With |
|-------------|-------------|
| `{{schemaName}}` | camelCase schema variable name, e.g. `createOrderSchema` |
| `{{method}}` | HTTP method export: `GET`, `POST`, `PUT`, `PATCH`, `DELETE` |
| `{{permission}}` | Permission string, e.g. `orders.create` — check `docs/permissions.md` for existing permissions |
| `{{table}}` | Database table name, e.g. `orders` |
| `{{operation}}` | Database operation: `insert`, `update`, `upsert`, `select` |
| `{{operationDescription}}` | Human-readable description for error message, e.g. `create order` |
| `{{timestamp}}` | Current UTC timestamp in `YYYYMMDDHHMMSS` format |
| `{{description}}` | Snake-case description of the migration, e.g. `add_orders_table` |
| `{{table_name}}` | SQL table name (snake_case), e.g. `orders` |
| `{{ComponentName}}` | PascalCase React component name, e.g. `OrderCard` |
| `{{title}}` | Human-readable card title, e.g. `Order Details` |
| `{{testSubject}}` | What is being tested, e.g. `OrderCard` |
| `{{testDescription}}` | Test behaviour description, e.g. `render the order title` |
| `{{ResourceName}}` | PascalCase resource for the hook name, e.g. `Orders` |
| `{{resourceKey}}` | Lowercase query key string, e.g. `orders` |

---

## Target Locations

| Type | Target Path |
|------|-------------|
| API route | `src/app/api/v1/{{resource}}/route.ts` (adjust to your project's API directory) |
| Migration | `migrations/{{timestamp}}_{{description}}.sql` (e.g., `supabase/migrations/`) |
| UI component | `src/components/{{domain}}/{{ComponentName}}.tsx` (adjust to your project's component directory) |
| Test file | Alongside the file under test, same directory, `.test.ts` / `.test.tsx` suffix |
| React Query hook | `src/hooks/use-{{resource}}.ts` (adjust to your project's hooks directory) |

---

## Gotchas

### Common Scaffolding Mistakes

1. **Missing `organization_id` scope** — every API route and hook MUST filter by `organization_id`.
   The template includes this; do not remove it. See: `critical-patterns.md`.

2. **Float money** — never store or pass monetary values as floats. Use cents (BIGINT).
   Column names must end in `_cents`. APR fields end in `_bps`.

3. **Skipping Zod validation** — the API route template uses `schema.parse(...)`. Do not
   replace this with a raw cast or remove it.

4. **Wrong permission string** — the permission string must match an existing
   permission in your project's permissions documentation. If the permission does not exist yet,
   add it there as part of the same task, and use `resource.action` format consistently.

5. **Migration timestamp collision** — always use the exact current UTC time at the moment
   you write the file (`YYYYMMDDHHMMSS`). Never reuse a timestamp from an example.

6. **RLS policy missing `GRANT`** — the migration template includes `GRANT ALL ON ... TO authenticated`.
   Do not remove it; Supabase RLS requires the grant to exist alongside the policy.

7. **Stale `queryKey`** — in the hook template, the `queryKey` array must include
   `organizationId` so queries invalidate correctly per org. The template already does this;
   do not collapse it to a single string key.

8. **`'use client'` on server components** — the UI component template adds `'use client'`.
   Only keep this if the component uses hooks or event handlers. Remove it for pure display
   components that can be server-rendered.

9. **Not listing TODOs after scaffold** — after writing the file, always output a bulleted
   list of every `// TODO:` and `{/* TODO: */}` comment in the scaffolded file so the
   implementer knows exactly what still needs to be filled in.
