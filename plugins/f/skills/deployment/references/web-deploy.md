# Web App Deployment (`apps/web`)

The main Next.js application. Deploy this FIRST before the marketing site.

> **Configure before use**: Replace `{PROJECT_ROOT}` with your monorepo root path and `{WEB_FILTER}` with your pnpm package filter (e.g. `@myapp/web`).

## Pre-Deploy Quality Gates

```bash
cd {PROJECT_ROOT}
pnpm lint
pnpm typecheck
pnpm test
pnpm --filter {WEB_FILTER} build
```

All four must pass with zero errors. Do not deploy if any gate fails.

Shortcut: use `plugins/f/skills/deployment/scripts/pre-deploy-check.sh`

## Deploy

```bash
cd {PROJECT_ROOT}
vercel --prod --archive=tgz
```

**CRITICAL**: Always include `--archive=tgz`. Without it, the CLI upload can fail on large monorepos.

## Verify

1. Check the deployment URL printed by the CLI — open it in a browser.
2. Test critical paths:
   - Login flow works
   - Main data list loads
   - Core feature renders correctly
3. Check Vercel dashboard for function errors in the first 2 minutes post-deploy.

## Rollback

If the deployment is broken:

```bash
# Option 1: Rollback via CLI
vercel rollback

# Option 2: Redeploy previous commit
git log --oneline -5
git checkout <previous-sha>
vercel --prod --archive=tgz
git checkout main
```

Prefer `vercel rollback` for speed — it does not require a new build.

## Environment Variables

Config is managed in Vercel dashboard under your web project. If a new env var was added:

```bash
printf 'value' | vercel env add VAR_NAME production
```

Use `printf` (not `echo`) to avoid a trailing newline being stored in the secret.

## Database Migrations

If this deploy includes schema changes, apply migrations before deploying:

```bash
cd {PROJECT_ROOT}
supabase db push
```

Always run migrations before the code deploy, never after — the old code must be compatible with the new schema.
