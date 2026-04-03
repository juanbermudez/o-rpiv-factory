# Website (Marketing Site) Deployment

The marketing/public site. Lives in a **separate repository** at `{WEBSITE_ROOT}`.

> **Configure before use**: Replace `{WEBSITE_ROOT}` with the absolute path to your marketing site repo and `{APP_DOMAIN}` with your deployed web app domain (e.g. `https://app.myapp.com`).

## CRITICAL: Deploy Order

**You MUST deploy the web app first before deploying the marketing site.** The marketing site calls the web app's public API endpoints. If the web app is not live yet, any API-dependent pages on the marketing site will break for live users.

Deployment order:
1. Deploy `apps/web` (see [web-deploy.md](web-deploy.md))
2. Confirm web app is live and API endpoints respond
3. Then deploy the marketing site

## Working Directory

The marketing site is NOT inside the main monorepo:

```bash
cd {WEBSITE_ROOT}
```

All commands below assume this working directory.

## Pre-Deploy

```bash
cd {WEBSITE_ROOT}
pnpm install        # ensure deps are up to date
pnpm build          # verify build succeeds locally
```

## Deploy

```bash
cd {WEBSITE_ROOT}
vercel --prod --archive=tgz
```

**CRITICAL**: Use `--archive=tgz` — same rule as the web app deploy.

## Verify API Connectivity

After deploy, verify that marketing site pages that depend on the web app API are working:

1. Check pages that show dynamic data — these call the web API
2. If a page is broken, check browser network tab for failed API requests
3. Confirm the `NEXT_PUBLIC_API_URL` env var in Vercel points to the correct web app URL

## Environment Variables

Managed in Vercel dashboard under the marketing site project. Key vars:

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_API_URL` | URL of the deployed web app (e.g. `{APP_DOMAIN}`) |

To add/update:

```bash
printf 'value' | vercel env add VAR_NAME production
```

## Rollback

```bash
cd {WEBSITE_ROOT}
vercel rollback
```

If rolling back due to a web API change, also rollback the web app to ensure compatibility.
