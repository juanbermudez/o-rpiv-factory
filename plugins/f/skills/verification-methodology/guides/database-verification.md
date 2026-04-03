# Database Verification Guide

Use this guide when the task includes new migrations or schema changes.

## What to Verify

1. Migration file structure
2. RLS policies
3. TypeScript type updates
4. Index coverage

## Migration File Review

Read each new migration file in the diff. Verify:

### Required Elements Checklist

- [ ] `organization_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE`
- [ ] `CREATE INDEX idx_{table}_{suffix} ON {table}(organization_id)` — index on org_id
- [ ] `ALTER TABLE {table} ENABLE ROW LEVEL SECURITY`
- [ ] `CREATE POLICY "org_isolation" ON {table} FOR ALL USING (organization_id = (auth.jwt() -> 'user_metadata' ->> 'organization_id')::uuid)`
- [ ] `GRANT ALL ON {table} TO authenticated`
- [ ] Monetary columns use `BIGINT` (not DECIMAL, FLOAT, NUMERIC) with `_cents` suffix
- [ ] APR/rate columns use `INTEGER` with `_bps` suffix (if applicable)

### RLS Policy Verification

The standard policy must match this exact pattern:
```sql
(auth.jwt() -> 'user_metadata' ->> 'organization_id')::uuid
```

Common wrong patterns (report as FAIL):
- `auth.uid()` — This is user ID, not org ID
- `current_user` — Wrong context
- Missing `::uuid` cast
- Using column that isn't `organization_id`

### Child Table RLS

If the new table has a parent FK, verify it uses the EXISTS subquery pattern:
```sql
EXISTS (
  SELECT 1 FROM parent_table
  WHERE parent_table.id = child_table.parent_id
    AND parent_table.organization_id = (auth.jwt() -> 'user_metadata' ->> 'organization_id')::uuid
)
```

### Index Coverage

Verify there is an index on `organization_id`. Without it, every query will do a full table scan as the table grows.

For tables with common filter patterns (e.g., status, created_at), verify composite indexes exist:
```sql
-- Example: filtering by org + status is common
CREATE INDEX idx_table_org_status ON table(organization_id, status);
```

## TypeScript Types Verification

Verify your project's TypeScript database types file (e.g., `src/types/database.ts`) was updated:

1. New table appears in alphabetical order in the `Tables` section
2. All three sections (Row, Insert, Update) are present
3. Column types match the migration SQL
4. Nullable columns are `string | null` (not just `string`)
5. `BIGINT` columns are `number` in TypeScript
6. `TIMESTAMPTZ` columns are `string` in TypeScript

### Column Type Mapping

| SQL Type | TypeScript Type |
|----------|----------------|
| `UUID` | `string` |
| `TEXT` | `string` |
| `BOOLEAN` | `boolean` |
| `INTEGER`, `BIGINT` | `number` |
| `TIMESTAMPTZ` | `string` |
| `JSONB` | `Json` (from database.ts) |
| `TEXT NOT NULL` | `string` |
| `TEXT` (nullable) | `string \| null` |

## Recording Results

```
Migration structure:    PASS — all required elements present
RLS policy:             PASS — org_isolation policy matches expected pattern
Index coverage:         PASS — idx_orders_org present
TypeScript types:       FAIL — orders.Row missing new_column field
Money columns:          PASS — all BIGINT with _cents suffix
```
