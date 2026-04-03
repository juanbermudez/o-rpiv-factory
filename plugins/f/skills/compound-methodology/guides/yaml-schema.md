# YAML Schema — Solution Documents

Every solution document in `docs/solutions/` must have valid YAML frontmatter. This is a blocking validation gate — do not write the document without valid frontmatter.

## Required Fields

```yaml
---
title: "Short descriptive title"
linear_task: "TASK-XXX"
date: "YYYY-MM-DD"
category: "database-issues"
severity: "critical"
resolution_type: "code-fix"
component: "component-name"
tags:
  - "relevant-tag"
symptoms:
  - "observable symptom string"
related_solutions: []
---
```

## Field Definitions

### `title` (string, required)
Short, descriptive title. Describes the problem, not the solution.
- Good: "Missing organization_id scope in orders query"
- Bad: "Fixed orders query"
- Bad: "org_id bug"

### `linear_task` (string, required)
The originating Linear task ID. Format: `{TEAM_KEY}-{number}` (e.g., your team key, hyphen, number).
- Good: `"TASK-150"` (or whatever your team key is, e.g., `"ENG-150"`)
- Bad: `"task-150"`, `"TASK150"`, `"#150"`

### `date` (string, required)
ISO 8601 date when the solution was compounded. Format: `YYYY-MM-DD`.
- Good: `"2024-01-15"`
- Bad: `"January 15, 2024"`, `"01/15/2024"`

### `category` (string, required)
Must be exactly one of the 12 valid values:
```
build-errors
test-failures
runtime-errors
performance-issues
database-issues
security-issues
api-issues
ui-bugs
integration-issues
workflow-issues
best-practices
documentation-gaps
```

### `severity` (string, required)
Must be exactly one of:
```
critical   — data loss, security breach, production outage
high       — significant functionality broken, blocked users
medium     — degraded experience, workaround exists
low        — minor issue, cosmetic, or edge case
```

### `resolution_type` (string, required)
Must be exactly one of:
```
code-fix              — changed application code
config-change         — changed configuration file or env var
architecture-change   — changed structural design
dependency-update     — updated or replaced a library
documentation         — added or corrected documentation only
workflow-change       — changed a process or procedure
```

### `component` (string, required)
The module, feature, or layer where the problem occurred. Use kebab-case.
Examples: `orders-api`, `settings-form`, `rls-policies`, `auth-middleware`, `product-search`

### `tags` (array of strings, required, min 1)
Searchable keywords. Include:
- The feature area (e.g., `orders`, `users`, `products`)
- The technical layer (e.g., `api`, `database`, `ui`, `migration`)
- The problem type (e.g., `rls`, `org-scope`, `validation`, `money`)

### `symptoms` (array of strings, required, min 1)
Observable symptoms that led to discovering this issue. Written as what the developer or user experienced:
- "GET /api/v1/orders returns data from other organizations"
- "500 error when creating an order with price field"
- "TypeScript error TS2345 on organization_id assignment"

### `related_solutions` (array of strings)
Relative paths to related solution documents. Empty array if none.
```yaml
related_solutions:
  - "database-issues/rls-missing-grant.md"
  - "security-issues/missing-org-scope.md"
```

## Validation Rules

Before writing the document, validate:
1. All required fields are present
2. `category` is one of the 12 exact values
3. `severity` is one of the 4 exact values
4. `resolution_type` is one of the 6 exact values
5. `date` matches `YYYY-MM-DD` format
6. `linear_task` matches `{TEAM_KEY}-\d+` format (e.g., `TASK-123`, `ENG-456`)
7. `tags` array has at least one entry
8. `symptoms` array has at least one entry

If validation fails, fix the frontmatter before writing the file.
