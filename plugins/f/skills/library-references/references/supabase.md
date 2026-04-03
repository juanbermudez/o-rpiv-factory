# Supabase Reference

Common mistakes Claude makes with Supabase. Read this before writing any migration, RLS policy, or Supabase client code.

---

## RLS Policies

**WRONG** — `auth.uid()` is the user's UUID, NOT a tenant/org ID:
```sql
CREATE POLICY "org_isolation" ON orders FOR ALL
  USING (tenant_id = auth.uid());  -- WRONG if tenant_id is not the user's own UUID
```

**CORRECT for single-user ownership** — use `auth.uid()` to match the user's own rows:
```sql
CREATE POLICY "user_isolation" ON orders FOR ALL
  USING (user_id = auth.uid());
```

**CORRECT for multi-tenant** — extract the tenant/org ID from JWT metadata:
```sql
-- First, run `SELECT auth.jwt();` to find the correct claim path in your JWT
CREATE POLICY "tenant_isolation" ON orders FOR ALL
  USING (tenant_id = (auth.jwt() -> 'user_metadata' ->> 'tenant_id')::uuid);
```

**Child tables** use an EXISTS subquery referencing the parent table (avoids duplicating the ownership column):
```sql
CREATE POLICY "user_isolation" ON order_items FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
        AND orders.user_id = auth.uid()
    )
  );
```

**Compliance tables** (audit_logs, etc.): NO DELETE policy. Allow only INSERT and SELECT:
```sql
CREATE POLICY "insert_only" ON audit_logs FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "read_own" ON audit_logs FOR SELECT
  USING (user_id = auth.uid());
-- No UPDATE or DELETE policy — intentional
```

---

## Vault Secrets (PII Encryption)

**WRONG** — Custom GUCs are blocked for non-superuser in PG17:
```sql
-- WRONG: PG17 blocks custom settings for non-superuser
SELECT current_setting('app.encryption_key');
```

**CORRECT** — Store the key in Supabase Vault, read from `vault.decrypted_secrets`:
```sql
SELECT decrypted_secret FROM vault.decrypted_secrets
WHERE name = 'PII_ENCRYPTION_KEY';
```

**pgcrypto** lives in the `extensions` schema on Supabase (not `public`):
```sql
-- WRONG:
SELECT pgp_sym_encrypt('data', 'key');

-- CORRECT:
SELECT extensions.pgp_sym_encrypt('data', 'key');
```

**DB functions for PII** should always use `SECURITY DEFINER` and read the key from Vault.

If your project has TypeScript helpers for encryption (e.g. `src/lib/encryption.ts`), use those rather than calling pgcrypto directly.

---

## Service Role vs Anon Key

| Key | Where Used | RLS |
|-----|-----------|-----|
| `SUPABASE_ANON_KEY` | Client-side (browser, mobile) | Enforced |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-side only | **Bypassed** |

**NEVER** expose the service role key to the client. It bypasses all RLS policies.

In API routes, use a properly scoped Supabase client provided by your auth middleware — do not create your own with the service role key unless you have a specific bypass reason and document it.

---

## Database Access

**WRONG** — Direct DB host has DNS issues:
```
db.{project-ref}.supabase.co  -- WRONG: DNS resolution issues
```

**CORRECT** — Use the Management API or connection pooler:
```bash
# Management API for SQL queries
POST https://api.supabase.com/v1/projects/{ref}/database/query

# Connection pooler (Transaction mode)
postgresql://postgres.{ref}:password@aws-0-{region}.pooler.supabase.com:6543/postgres
```

**Supabase CLI token** is stored in macOS keychain (base64-encoded with `go-keyring-base64:` prefix). Do not hard-code it.

---

## Auth SSR (Next.js)

**WRONG** — `auth-helpers-nextjs` is deprecated:
```typescript
import { createServerSupabaseClient } from '@supabase/auth-helpers-nextjs'  // WRONG: deprecated
```

**CORRECT** — Use `@supabase/ssr`:
```typescript
import { createServerClient } from '@supabase/ssr'
```

Cookie-based session handling is required for Next.js middleware. Use a shared auth middleware module for all API routes rather than creating Supabase clients ad hoc.

---

## Migration File Naming

Migrations live in `supabase/migrations/` with format: `YYYYMMDDHHMMSS_description.sql`

Always include:
1. `CREATE INDEX idx_{table}_{column} ON {table}({column});` for foreign keys and filter columns
2. `ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;`
3. RLS policy using the correct JWT claim path for your app (run `SELECT auth.jwt();` to verify)
4. `GRANT ALL ON {table} TO authenticated;`
