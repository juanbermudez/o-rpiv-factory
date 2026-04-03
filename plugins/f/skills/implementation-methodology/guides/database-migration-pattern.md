# Database Migration Pattern Guide

This guide describes how to write database migration files. It uses Supabase/PostgreSQL as the example database — adapt the specifics to your project's database setup.

> **This is an example pattern, not a fixed requirement.** Your project may use a different database, ORM, or migration tool. Use this as a reference and match your existing codebase conventions. If your project uses Prisma, Drizzle, Flyway, or another tool, follow that tool's patterns instead.

## File Naming (Supabase / SQL migrations)

```
supabase/migrations/YYYYMMDDHHMMSS_description.sql
```

Example: `supabase/migrations/20240115120000_create_orders.sql`

Generate the timestamp: `date +%Y%m%d%H%M%S`

## Standard Migration Template

The example below shows a single-tenant table (scoped by `user_id`). For multi-tenant applications, replace `user_id` with your tenant identifier column (e.g. `org_id`, `account_id`) and adapt the RLS policy accordingly.

```sql
-- supabase/migrations/YYYYMMDDHHMMSS_description.sql

-- Table
CREATE TABLE resource_name (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- ownership column — use user_id for single-tenant, or a tenant ID for multi-tenant
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- business columns
  name TEXT NOT NULL,
  amount_cents BIGINT NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  -- timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index on the ownership column (required for all user/tenant-scoped tables)
CREATE INDEX idx_resource_name_user ON resource_name(user_id);

-- Additional indexes for common query patterns
CREATE INDEX idx_resource_name_status ON resource_name(user_id, status);

-- Enable RLS
ALTER TABLE resource_name ENABLE ROW LEVEL SECURITY;

-- RLS Policy — adapt the claim path to match your JWT structure
-- Run `SELECT auth.jwt();` to inspect your JWT and find the correct path
CREATE POLICY "user_isolation" ON resource_name FOR ALL
  USING (user_id = auth.uid());

-- Grant to authenticated role
GRANT ALL ON resource_name TO authenticated;

-- Updated_at trigger
CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON resource_name
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Rules

### 1. Every table SHOULD have:
- `id UUID PRIMARY KEY DEFAULT uuid_generate_v4()` (or your preferred ID strategy)
- An ownership column (`user_id`, `tenant_id`, etc.) with a foreign key constraint
- `CREATE INDEX` on the ownership column
- `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` (if using Supabase RLS)
- `CREATE POLICY` that scopes access to the owner
- `GRANT ALL ON ... TO authenticated`

### 2. Monetary Values

Always use `BIGINT` for money, suffix with `_cents`:
```sql
price_cents BIGINT NOT NULL DEFAULT 0,
deposit_cents BIGINT,  -- nullable if optional
```

Never use `DECIMAL`, `FLOAT`, `NUMERIC` for money.

### 3. Rates and Percentages

Store as basis points (`_bps` suffix) to avoid floating point issues:
```sql
rate_bps INTEGER,  -- 599 = 5.99%
```

### 4. RLS for Child Tables

When a child table has a parent FK, use an EXISTS subquery rather than duplicating the ownership column:

```sql
CREATE POLICY "user_isolation" ON child_table FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM parent_table
      WHERE parent_table.id = child_table.parent_id
        AND parent_table.user_id = auth.uid()
    )
  );
```

### 5. Compliance / Audit Tables (No DELETE)

For audit or compliance tables, use separate policies and omit DELETE:
```sql
CREATE POLICY "insert_only" ON audit_log FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "read_own" ON audit_log FOR SELECT
  USING (user_id = auth.uid());
-- No UPDATE or DELETE policy — intentional
```

## TypeScript Type Update (if using Supabase-generated types)

After adding a migration, update your database types file. If you use `supabase gen types`, regenerate:

```bash
supabase gen types typescript --local > src/types/database.ts
```

Or update manually. Tables are typically in alphabetical order. Add to all three sections (Row, Insert, Update):

```typescript
resource_name: {
  Row: {
    id: string
    user_id: string
    name: string
    amount_cents: number
    status: string
    created_at: string
    updated_at: string
  }
  Insert: {
    id?: string
    user_id: string
    name: string
    amount_cents?: number
    status?: string
    created_at?: string
    updated_at?: string
  }
  Update: {
    id?: string
    user_id?: string
    name?: string
    amount_cents?: number
    status?: string
    created_at?: string
    updated_at?: string
  }
}
```

## Adding a Column to an Existing Table

```sql
-- Prefer nullable new columns (no backfill needed)
ALTER TABLE resource_name ADD COLUMN new_field TEXT;

-- Or with a safe default
ALTER TABLE resource_name ADD COLUMN new_field BOOLEAN NOT NULL DEFAULT false;
```

Also update all 3 sections (Row, Insert, Update) in your types file.
