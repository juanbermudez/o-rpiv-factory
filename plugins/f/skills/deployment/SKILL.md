---
name: deployment-methodology
description: >
  Methodology for deploying applications (web, MCP, mobile, marketing site)
  with quality gates, correct ordering, and rollback procedures. Encodes
  deployment order constraints, platform-specific gotchas, and verification steps.
---

# Deployment Methodology

You are deploying one or more applications. Follow this skill to ensure deployments succeed, respect dependency ordering, and are verifiable.

> **Project configuration**: This skill uses generic placeholders. Replace the following before use:
> - `{PROJECT_ROOT}` — absolute path to your monorepo root (e.g. `/home/user/myapp`)
> - `{WEBSITE_ROOT}` — absolute path to your marketing site repo (e.g. `/home/user/myapp-website`)
> - `{EXPO_ACCOUNT}` — your Expo/EAS account slug
> - `{EXPO_PROJECT}` — your Expo project slug
> - `{GITHUB_ORG}` — your GitHub organization name
> - `{WEB_FILTER}` — your pnpm filter for the web app (e.g. `@myapp/web`)
> - `{MCP_DOMAIN}` — your MCP server domain (e.g. `mcp.myapp.com`)
> - `{APP_DOMAIN}` — your web app domain (e.g. `app.myapp.com`)

## Deployment Order (CRITICAL)

**Always deploy the web app FIRST.** The marketing site depends on the web app's public API. Deploying the marketing site before the web app risks a live mismatch between the marketing site and the API it calls.

```
1. apps/web  (Next.js — main app)
2. apps/mcp  (MCP server — independent of web, can run in parallel with step 1)
3. website   (Marketing site — MUST run after web app is live)
4. mobile    (Expo — independent, submit separately via EAS)
```

## When to Use Each Reference

| Reference | Use When |
|-----------|----------|
| [web-deploy.md](references/web-deploy.md) | Deploying the main Next.js app |
| [mcp-deploy.md](references/mcp-deploy.md) | Deploying the MCP server — has esbuild gotchas |
| [mobile-deploy.md](references/mobile-deploy.md) | Building/submitting the Expo app or pushing OTA updates |
| [website-deploy.md](references/website-deploy.md) | Deploying the marketing site (separate repo) |

## Pre-Deploy Checklist

Run before ANY production deployment:

- [ ] All quality gates pass: `pnpm lint && pnpm typecheck && pnpm test && pnpm --filter {WEB_FILTER} build`
- [ ] No uncommitted changes (`git status` is clean)
- [ ] Branch has been reviewed/merged to main
- [ ] Env vars in Vercel are up to date for any new config keys
- [ ] Database migrations applied (if schema changed): `supabase db push`

Use `scripts/pre-deploy-check.sh` to automate the quality gates.

## Gotchas

- **Always use `--archive=tgz` with Vercel CLI**: Without this flag, the Vercel CLI upload can fail or time out on large monorepos. Every `vercel --prod` call MUST include `--archive=tgz`.
- **MCP transport must be WebStandard, not Node.js**: The Node.js `StreamableHTTPServerTransport` mocks `IncomingMessage`/`ServerResponse` which breaks on Vercel serverless. Always use `WebStandardStreamableHTTPServerTransport`. See: [references/mcp-deploy.md](references/mcp-deploy.md)
- **Use `printf` not `echo` for Vercel env vars**: `echo` adds a trailing newline that gets stored as part of the secret value, causing auth failures. Use `printf 'value' | vercel env add VAR_NAME`.
- **Marketing site is a separate repo**: It lives at `{WEBSITE_ROOT}`, not inside the main monorepo. `cd` there before running any website deploy commands.
- **Deploy web BEFORE marketing site**: The marketing site calls the web app's public API. Deploying out of order causes live breakage.
