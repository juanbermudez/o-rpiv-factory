# Supabase Migration Fail

## Symptoms

- `supabase db push` fails with an error
- `relation "{table}" does not exist` during migration
- Type mismatch errors (e.g., `cannot cast type text to uuid`)
- `function pgp_sym_encrypt(text, text) does not exist`
- `schema "public" does not contain extension "pgcrypto"`
- Migration applies locally but fails on remote
- `supabase db reset` fails midway

## Common Causes (ordered by likelihood)

1. Column types don't match — e.g., referencing a UUID column with a TEXT foreign key
2. Referenced table or column doesn't exist yet (wrong migration order)
3. `pgcrypto` functions called in `public` schema instead of `extensions` schema
4. Vault access issue — `vault.decrypted_secrets` not accessible from migration context
5. Missing `uuid-ossp` extension for `uuid_generate_v4()`
6. Duplicate migration timestamp causing conflicts

## Diagnosis Steps

1. Check the exact error from Supabase:
   ```bash
   supabase db push 2>&1 | tail -30
   ```

2. Verify the referenced table/column exists in a prior migration:
   ```bash
   grep -rn "CREATE TABLE {referenced_table}" supabase/migrations/
   ```

3. For pgcrypto errors, check how the function is being called:
   ```bash
   grep -n "pgp_sym_encrypt\|pgp_sym_decrypt\|pgcrypto" supabase/migrations/{failing_migration}.sql
   ```

4. Check extension schema on Supabase:
   ```sql
   SELECT extname, extnamespace::regnamespace FROM pg_extension WHERE extname = 'pgcrypto';
   -- Expected: pgcrypto | extensions  (NOT public)
   ```

5. Test locally first:
   ```bash
   supabase db reset   # applies all migrations from scratch
   ```

## Resolution

### Cause 1: Wrong column type

Fix the migration SQL before pushing. Common mismatches:

```sql
-- WRONG: TEXT column referencing UUID primary key
user_id TEXT REFERENCES users(id)

-- CORRECT: UUID column
user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE
```

If migration was already pushed to remote, create a new migration that alters the column:

```sql
ALTER TABLE {table} ALTER COLUMN {column} TYPE UUID USING {column}::uuid;
```

### Cause 2: Missing referenced table

Ensure the migration that creates the referenced table has a **lower timestamp** than the migration that references it. Rename files if needed:

```
20240101000001_create_users.sql    ← must exist before
20240101000002_create_orders.sql   ← this one
```

If the table was created in the same migration batch, reorder the `CREATE TABLE` statements within the file.

### Cause 3: pgcrypto in wrong schema

On Supabase, `pgcrypto` lives in the `extensions` schema, not `public`. Always prefix:

```sql
-- WRONG
SELECT pgp_sym_encrypt('data', 'key');

-- CORRECT on Supabase
SELECT extensions.pgp_sym_encrypt('data', 'key');
```

If your project has encrypt/decrypt helper functions in a shared library, use those rather than calling pgcrypto directly — they should already handle the schema prefix.

### Cause 4: Vault access in migration

Migration SQL runs as the migration user which may not have Vault access. Do NOT read from `vault.decrypted_secrets` in migration SQL. Vault reads belong in PL/pgSQL functions with `SECURITY DEFINER`.

If you need to set up a Vault secret during migration, do it via the Supabase Management API or Supabase Dashboard, not in the migration file.

### Cause 5: Missing uuid-ossp extension

Add this at the top of the migration:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA extensions;
```

Or reference `extensions.uuid_generate_v4()` if the extension is already installed.

### Cause 6: Duplicate timestamp

Check for timestamp conflicts:

```bash
ls supabase/migrations/ | sort | uniq -d
```

Rename the conflicting file to the next available second:

```bash
mv supabase/migrations/20240101000000_foo.sql supabase/migrations/20240101000001_foo.sql
```

## Prevention

- Always use a consistent migration template that includes RLS, correct UUID types, and proper constraints
- Test with `supabase db reset` locally before `supabase db push`
- Use `extensions.pgp_sym_encrypt` / `extensions.pgp_sym_decrypt` — never bare `pgp_sym_encrypt`
- Foreign key columns must match the type of the referenced primary key (UUID NOT NULL is common)
- Check that the migration timestamp is unique before creating a file: `ls supabase/migrations/ | grep {YYYYMMDD}`
