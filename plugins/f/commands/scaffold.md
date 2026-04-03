---
name: scaffold
description: "Generate boilerplate from a template (api-route, migration, ui-component, test, hook)"
argument-hint: "<type> <name>"
---

# `/f:scaffold` — Code Scaffolding

Generate boilerplate code for a feature by reading a template, substituting
placeholders, and writing the file to the correct target location in the project.

---

## Instructions

### Step 1: Parse Arguments

The user provides: `/f:scaffold <type> <name>`

- `type` — one of: `api-route`, `migration`, `ui-component`, `test`, `hook`
- `name` — the resource/component name (e.g. `users`, `UserCard`, `add_orders_table`)

If either argument is missing, print:

```
Usage: /f:scaffold <type> <name>

Types:
  api-route      → {detected API routes directory}/<name>/route.{ext}
  migration      → {detected migrations directory}/<timestamp>_<name>.sql
  ui-component   → {detected components directory}/<domain>/<Name>.{ext}
  test           → <same directory as file under test>/<name>.test.{ext}
  hook           → {detected hooks directory}/use-<name>.{ext}
```

### Step 2: Load the Skill

Read `plugins/f/skills/scaffolding/SKILL.md` to understand placeholder rules, target
locations, and gotchas before proceeding.

### Step 3: Detect Project Structure

Before reading the template, determine where files should go by inspecting the project:

1. **Read `CLAUDE.md`** — it should specify the project structure, tech stack, and
   file naming conventions. Use this as the primary source for target paths.

2. **If CLAUDE.md doesn't specify paths**, auto-detect by looking for common patterns:
   - API routes: look for `src/app/api/`, `src/pages/api/`, `app/api/`, `routes/api/`
   - Migrations: look for `supabase/migrations/`, `db/migrations/`, `migrations/`, `prisma/migrations/`
   - Components: look for `src/components/`, `components/`, `app/components/`
   - Hooks: look for `src/hooks/`, `hooks/`, `lib/hooks/`

3. **If still ambiguous**, ask the user which directory to use before proceeding.

### Step 4: Read the Template

Based on `type`, read the appropriate template file from
`plugins/f/skills/scaffolding/templates/`:

| type | template file |
|------|--------------|
| `api-route` | `api-route.ts.template` |
| `migration` | `migration.sql.template` |
| `ui-component` | `ui-component.tsx.template` |
| `test` | `test-file.test.ts.template` |
| `hook` | `hook.ts.template` |

### Step 5: Replace Placeholders

Substitute every `{{placeholder}}` in the template using the name provided by the user.
Derive variants automatically:

- `PascalCase` — for component names, hook resource names
- `snake_case` — for table names, migration description
- `camelCase` — for schema variable names, query keys
- `kebab-case` — for hook file names, error messages
- `YYYYMMDDHHMMSS` timestamp — for migrations, use current UTC time

See the full placeholder reference in `SKILL.md`.

### Step 6: Determine Target Path

Use the detected project structure from Step 3 and the Target Locations table from
`SKILL.md` to determine where to write the file.

For `ui-component`, ask the user which domain subdirectory to use if it is not obvious
from the name (e.g. `users`, `orders`, `products`).

### Step 7: Write the File

Write the scaffolded content to the determined target path.

### Step 8: List Remaining TODOs

After writing, print a bulleted list of every `// TODO:` and `{/* TODO: */}` comment
left in the scaffolded file so the implementer knows exactly what still needs filling in.

Example output:

```
Scaffolded: src/app/api/users/route.ts

Remaining TODOs:
- Line 6: Define schema fields in usersSchema
- Line 12: Confirm the correct database operation (currently: insert)
```

---

## Example

```
/f:scaffold api-route users
```

Reads `api-route.ts.template`, replaces placeholders:
- `{{schemaName}}` → `usersSchema`
- `{{method}}` → `POST`
- `{{permission}}` → `users.create`
- `{{table}}` → `users`
- `{{operation}}` → `insert`
- `{{operationDescription}}` → `create users`

Writes to: the detected API routes directory (e.g., `src/app/api/v1/users/route.ts`)

---

## Gotchas

Refer to the Gotchas section in `plugins/f/skills/scaffolding/SKILL.md` for common
mistakes to avoid when scaffolding code.
