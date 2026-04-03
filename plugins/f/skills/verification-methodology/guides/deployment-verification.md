# Deployment Verification Guide

Use this guide when the task includes deployment changes, environment variable updates, or build configuration changes.

## When to Use This Guide

- Changes to `vercel.json` or deployment config
- New environment variables added
- Changes to build commands or scripts
- Database migrations that require production execution
- Changes to `package.json` scripts

## Pre-Deployment Checks

### Build Verification

The build must succeed locally before any deployment:

```bash
pnpm build  # or the project-specific build command
```

Check the build output:
- No `Error:` lines
- Route table shows all expected routes
- Bundle size is reasonable (note if >50% increase vs baseline)

### Environment Variables

For each new `process.env.VAR_NAME` in the diff:

1. Confirm the variable is documented (in `.env.example` or README)
2. Confirm it is set in Vercel for all environments (preview + production)
3. Confirm it is NOT committed to the repository

```bash
grep -r "process.env" {changed-files} | grep -v ".env.example"
```

**FAIL if**: A new env var is used in code but not listed in `.env.example`.

### Database Migration

For new migration files:

1. Migration runs locally without errors
2. Migration is idempotent (running twice does not fail — use `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`)
3. Migration does not require downtime (no full table locks on large tables)
4. Migration has a rollback strategy (or the change is additive/non-breaking)

```bash
# Check migration syntax by reviewing the file
cat supabase/migrations/{timestamp}_{name}.sql
```

**FAIL if**: Migration uses `DROP TABLE`, `DROP COLUMN`, or renames columns without a documented rollback plan.

**WARN if**: Migration adds a `NOT NULL` column without a default (requires backfill).

## Deployment Steps (Reference)

The orchestrator or human engineer handles actual deployment. This section is for the verifier to confirm the steps are documented:

```bash
# Deploy app — consult project deployment docs for the exact commands
pnpm lint && pnpm typecheck && pnpm build
# Then deploy using your hosting platform (Vercel, Railway, etc.)
```

**FAIL if**: Task description says deployment is required but no deployment instructions are documented.

## Post-Deployment Checks

After deployment (done by orchestrator, not verifier):
- Health check endpoint responds
- Key user flows work in production
- No spike in error rates
- Database migration ran successfully

## Recording Results

```
Build:                  PASS — clean build, no errors
Env vars:               PASS — all new vars documented in .env.example
Migration safety:       PASS — additive only, no destructive changes
Idempotency:            PASS — uses CREATE TABLE IF NOT EXISTS
Deployment docs:        PASS — deployment steps present in task notes
```
