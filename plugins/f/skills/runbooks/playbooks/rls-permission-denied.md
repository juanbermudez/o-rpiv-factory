# RLS Permission Denied

## Symptoms

- `permission denied for table X` error from Supabase
- API returns empty array when data definitely exists
- 403 from an API route that should succeed
- Row-level security violation in Supabase logs
- Query works as service role but not as authenticated user

## Common Causes (ordered by likelihood)

1. RLS is enabled but no policy exists for the operation (INSERT/SELECT/UPDATE/DELETE)
2. Policy uses wrong JWT claim path — check what claims your auth provider actually puts in the JWT
3. Tenant/owner ID not passed in the query or not matching the authenticated user's claims
4. Table was added without RLS policies (migration created table but forgot the policy block)
5. Policy exists but has a typo in the column name or condition

## Diagnosis Steps

1. Check if RLS is enabled and what policies exist:
   ```sql
   SELECT tablename, policyname, cmd, qual, with_check
   FROM pg_policies
   WHERE tablename = '{table}';
   ```

2. Check if RLS is enabled on the table at all:
   ```sql
   SELECT relname, relrowsecurity
   FROM pg_class
   WHERE relname = '{table}';
   ```

3. Inspect the JWT contents to verify claim paths:
   ```sql
   SELECT auth.jwt();
   ```
   Examine the output to find the correct path to your user/tenant identifier in the JWT payload.

4. Verify the query includes the correct ownership filter:
   ```typescript
   // CORRECT — always scope queries to the authenticated user/tenant
   supabase.from('table').select('*').eq('user_id', userId)

   // WRONG — missing ownership scope, will fail RLS or return wrong data
   supabase.from('table').select('*')
   ```

5. Check migration file to see if policies were created for all operations:
   ```bash
   grep -n "CREATE POLICY" supabase/migrations/*_{table}*.sql
   ```

## Resolution

### Cause 1: Missing RLS policy

Add the missing policy in a new migration. The exact JWT claim path depends on your auth setup — inspect `auth.jwt()` to find the correct path to your user or tenant identifier.

**Single-user scoping (by user ID)**:
```sql
-- supabase/migrations/YYYYMMDDHHMMSS_fix_rls_{table}.sql

CREATE POLICY "user_isolation" ON {table} FOR ALL
  USING (user_id = auth.uid());

GRANT ALL ON {table} TO authenticated;
```

**Multi-tenant scoping (by tenant/org ID stored in JWT metadata)**:
```sql
-- Adapt the JWT path to match your actual JWT structure
-- Run `SELECT auth.jwt();` to find the correct claim path

CREATE POLICY "tenant_isolation" ON {table} FOR ALL
  USING (tenant_id = (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid);

GRANT ALL ON {table} TO authenticated;
```

For child tables that reference a parent (e.g., `order_items` → `orders`):

```sql
CREATE POLICY "tenant_isolation" ON {child_table} FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM {parent_table}
      WHERE {parent_table}.id = {child_table}.{parent_id_column}
        AND {parent_table}.tenant_id = (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid
    )
  );
```

### Cause 2: Wrong JWT claim path

Run `SELECT auth.jwt();` in the Supabase SQL editor to see the actual JWT structure. Match the policy claim path exactly to what appears in the output.

```sql
-- Example: if your JWT has user_metadata.tenant_id
(auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid

-- Example: if your JWT has app_metadata.org_id
(auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid

-- Example: simple user ownership
auth.uid()
```

### Cause 3: Missing ownership filter in query

Your server-side code or middleware should provide the authenticated user/tenant context. Always use it:

```typescript
const { data } = await supabase
  .from('table')
  .select('*')
  .eq('user_id', ctx.userId)  // or tenant_id, org_id — whatever your schema uses
```

### Cause 4: Table created without policies

Run the diagnosis SQL above to confirm zero policies exist, then add the full RLS block from Cause 1.

### Cause 5: Typo in policy condition

Drop and recreate the policy:

```sql
DROP POLICY "tenant_isolation" ON {table};

CREATE POLICY "tenant_isolation" ON {table} FOR ALL
  USING (tenant_id = (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid);
```

## Prevention

- Always include the full RLS block in every `CREATE TABLE` migration
- Enable RLS immediately: `ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;`
- Add `GRANT ALL ON {table} TO authenticated;` in every migration
- Run `SELECT auth.jwt();` early in a new project to understand your JWT structure before writing policies
- Test RLS as an authenticated user (not service role) to catch policy gaps
