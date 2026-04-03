# Vercel Deploy Fail

## Symptoms

- `vercel --prod` upload hangs or times out
- Build fails on Vercel but passes locally
- 500 errors immediately after a successful deploy
- MCP server deploy fails with `Cannot find module` or `createRequire` errors
- Environment variable not found at runtime despite being set in Vercel dashboard
- `vercel env add` silently stores wrong value (auth failures at runtime)

## Common Causes (ordered by likelihood)

1. Missing `--archive=tgz` flag on Vercel CLI — upload fails on large monorepo
2. Missing or incorrect environment variables in Vercel project settings
3. Build error not caught locally (different Node version or missing package on CI)
4. MCP server: esbuild command missing required flags (`--external:bcrypt`, `createRequire` banner)
5. MCP server: using Node.js transport instead of WebStandard transport
6. Environment variable set with `echo` instead of `printf` — trailing newline stored in secret

## Diagnosis Steps

1. Check the Vercel deployment logs (always start here):
   ```bash
   vercel logs {deployment-url}
   # Or check Vercel dashboard → Deployments → click the failing deploy → Functions tab
   ```

2. Verify `--archive=tgz` is in the deploy command:
   ```bash
   # Your deploy command must look like this:
   vercel --prod --archive=tgz
   ```

3. Compare env vars between local and Vercel:
   ```bash
   # List env vars in Vercel project
   vercel env ls
   # Compare against apps/web/.env.local
   ```

4. For MCP server failures, check the esbuild output:
   ```bash
   ls -la .vercel/output/functions/api/
   # Verify the bundle file exists and has reasonable size (>0 bytes)
   ```

5. Check for trailing newline in env vars:
   ```bash
   # If a secret auth failure, the env var likely has a trailing newline
   vercel env rm VAR_NAME production
   printf 'correct-value' | vercel env add VAR_NAME production
   ```

## Resolution

### Cause 1: Missing --archive=tgz

Always use this exact command for production deploys:

```bash
vercel --prod --archive=tgz
```

Without `--archive=tgz`, the Vercel CLI uploads the project file-by-file which can time out on large monorepos.

### Cause 2: Missing environment variables

Add missing env vars to Vercel:

```bash
# Use printf — NOT echo — to avoid trailing newline
printf 'your-value-here' | vercel env add VAR_NAME production
```

Required env vars for a typical Next.js + Supabase app:
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`
- `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- Any other keys from your local `.env.local`

### Cause 3: Build error not caught locally

Run the full build locally with production settings:

```bash
pnpm lint && pnpm typecheck && pnpm --filter {WEB_FILTER} build
```

If passing locally but failing on Vercel, check:
- Node version mismatch: set `engines.node` in `package.json` or `.nvmrc`
- Package not in dependencies (only devDependencies): move to `dependencies`

### Cause 4: MCP server esbuild command

The MCP server requires a specific esbuild command. Use exactly:

```bash
pnpm dlx esbuild apps/mcp/api/\[\[...path\]\].ts \
  --bundle \
  --platform=node \
  --target=node20 \
  --format=esm \
  --outfile=.vercel/output/functions/api/[[...path]].func/index.mjs \
  --external:bcrypt \
  --banner:js="import{createRequire}from'module';const require=createRequire(import.meta.url);"
```

Critical flags:
- `--external:bcrypt` — bcrypt uses native bindings that can't be bundled
- `--banner:js` with `createRequire` — needed for ESM compatibility with CommonJS modules

### Cause 5: MCP uses Node.js transport

The MCP server MUST use `WebStandardStreamableHTTPServerTransport`, not `StreamableHTTPServerTransport`. The Node.js transport mocks `IncomingMessage`/`ServerResponse` which breaks on Vercel serverless.

```typescript
// CORRECT
import { WebStandardStreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js'

// WRONG — breaks on Vercel
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js'
```

### Cause 6: Trailing newline in env var

Remove and re-add the env var using `printf`:

```bash
vercel env rm VAR_NAME production
printf 'exact-value-no-newline' | vercel env add VAR_NAME production
```

Never use `echo 'value' | vercel env add` — `echo` appends `\n` which becomes part of the stored value.

## Prevention

- Run `scripts/pre-deploy-check.sh` before every production deployment
- Always include `--archive=tgz` in deploy commands — add it to scripts, not just docs
- Use `printf` instead of `echo` for all `vercel env add` calls
- Deploy the web app before the marketing site — the marketing site depends on the web app API
- After MCP deploys, test the OAuth flow end-to-end before marking complete
