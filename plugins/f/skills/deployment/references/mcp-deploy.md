# MCP Server Deployment (`apps/mcp`)

The MCP server. Deployed independently via Vercel prebuilt deployment.

> **Configure before use**: Replace `{PROJECT_ROOT}` with your monorepo root path and `{MCP_DOMAIN}` with your MCP server domain (e.g. `mcp.myapp.com`).

## Architecture Notes

- Transport: `WebStandardStreamableHTTPServerTransport` from `@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js`
- **DO NOT** use Node.js `StreamableHTTPServerTransport` — it mocks `IncomingMessage`/`ServerResponse` which breaks on Vercel serverless functions
- Domain: `{MCP_DOMAIN}` (CNAME → `cname.vercel-dns.com`)
- OAuth: Custom login form at `/oauth/authorize` using Supabase JS client-side (`signInWithPassword`), then POST to `/oauth/authorize/complete`

## Build

The MCP server requires an esbuild bundle before deploy. Run from the monorepo root:

```bash
cd {PROJECT_ROOT}

pnpm dlx esbuild \
  "apps/mcp/api/[[...path]].ts" \
  --bundle \
  --platform=node \
  --target=node20 \
  --format=esm \
  --outfile=".vercel/output/functions/api/[[...path]].func/index.mjs" \
  --external:bcrypt \
  --banner:js="import{createRequire}from'module';const require=createRequire(import.meta.url);"
```

**Notes on the build command**:
- The `[[...path]]` filename must be quoted/escaped — the shell will glob-expand it otherwise
- `--external:bcrypt` prevents bcrypt native bindings from being bundled (Vercel provides them)
- The banner injects a CJS `require` shim needed by some transitive dependencies in ESM mode

## Deploy

```bash
cd {PROJECT_ROOT}
vercel deploy --prebuilt --prod
```

Use `--prebuilt` because the build artifact is already in `.vercel/output/`. Do NOT run `vercel --prod --archive=tgz` here — that triggers a Vercel-side build, which won't work for the MCP esbuild setup.

## Environment Variables

Managed in Vercel dashboard under the MCP project. Required vars:

| Variable | Source |
|----------|--------|
| `SUPABASE_URL` | Supabase project settings |
| `SUPABASE_ANON_KEY` | Supabase project settings |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase project settings (secret) |
| `MCP_BASE_URL` | `https://{MCP_DOMAIN}` |

Add project-specific env vars as needed (e.g. third-party API tokens your MCP tools use).

To add/update a var:

```bash
printf 'value' | vercel env add VAR_NAME production
```

Always use `printf` (not `echo`) — `echo` appends a newline that gets stored as part of the secret.

## Verify

1. Check `https://{MCP_DOMAIN}` responds (should return MCP server info or 404 on root)
2. Test OAuth flow: navigate to `https://{MCP_DOMAIN}/oauth/authorize`
3. Confirm MCP tools are callable from Claude.ai

## Rollback

```bash
vercel rollback
```

Or redeploy from a previous build artifact if available.
