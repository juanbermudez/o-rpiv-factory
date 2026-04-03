# Auth Session Issues

## Symptoms

- Users get randomly logged out without taking any action
- 401 errors on API routes despite being logged in
- `session expired` message on page refresh even with a recent login
- `getUser()` returns null when user is clearly authenticated
- Auth works in browser but fails in SSR (server-side rendered pages show logged-out state)
- Cookie not being sent with API requests
- Infinite redirect loop on protected routes

## Common Causes (ordered by likelihood)

1. Using deprecated `@supabase/auth-helpers-nextjs` instead of `@supabase/ssr`
2. Token refresh not working — server-side Supabase client not set up to forward the refreshed token to the browser
3. Middleware not running on all protected routes (missing route matcher pattern)
4. Cookie domain or path misconfiguration — cookie set on wrong domain/path
5. `getSession()` used instead of `getUser()` on the server (session can be stale, user requires re-auth)
6. Multiple Supabase client instances causing conflicting cookie state

## Diagnosis Steps

1. Check browser cookies to see if auth cookies are present:
   ```
   Browser DevTools → Application → Cookies → look for sb-{project-ref}-auth-token
   ```

2. Verify which Supabase auth package is in use:
   ```bash
   grep -r "auth-helpers\|@supabase/ssr" {PROJECT_ROOT}/apps/web/package.json
   ```

3. Check the middleware file for route coverage:
   ```bash
   cat {PROJECT_ROOT}/apps/web/src/middleware.ts
   ```

4. Test if the issue is SSR-specific by comparing:
   - Client-side navigation (no reload): stays logged in?
   - Hard refresh: logged out?
   - If hard refresh logs out, the issue is in SSR session handling.

5. Check for multiple Supabase client files:
   ```bash
   grep -rn "createClient\|createServerClient\|createBrowserClient" \
     {PROJECT_ROOT}/apps/web/src/lib/ \
     --include="*.ts"
   ```

6. Verify the Supabase URL and anon key are set correctly:
   ```bash
   grep "NEXT_PUBLIC_SUPABASE" {PROJECT_ROOT}/apps/web/.env.local
   ```

## Resolution

### Cause 1: Deprecated auth-helpers package

Migrate to `@supabase/ssr`:

```bash
pnpm --filter {WEB_FILTER} remove @supabase/auth-helpers-nextjs
pnpm --filter {WEB_FILTER} add @supabase/ssr
```

Update client creation to use the SSR package:

```typescript
// Server component / Route handler
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

const cookieStore = await cookies()
const supabase = createServerClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  {
    cookies: {
      getAll() { return cookieStore.getAll() },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value, options }) =>
          cookieStore.set(name, value, options)
        )
      },
    },
  }
)

// Browser component
import { createBrowserClient } from '@supabase/ssr'

const supabase = createBrowserClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)
```

### Cause 2: Token refresh not forwarding cookies

The middleware must call `supabase.auth.getUser()` (not `getSession()`) and must write the refreshed cookies back to the response:

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() { return request.cookies.getAll() },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // IMPORTANT: getUser() triggers token refresh, getSession() does not
  const { data: { user } } = await supabase.auth.getUser()

  if (!user && isProtectedRoute(request.nextUrl.pathname)) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return supabaseResponse
}
```

### Cause 3: Middleware not covering route

Check the `matcher` in `middleware.ts`:

```typescript
export const config = {
  matcher: [
    // Must include all protected paths
    '/((?!_next/static|_next/image|favicon.ico|login|auth).*)',
  ],
}
```

If a route is not matched, the middleware doesn't run and auth tokens don't refresh.

### Cause 4: Cookie domain/path issue

Check that cookies are set without an explicit domain (let the browser infer it):

```typescript
// Let Supabase SSR handle cookie options — don't override domain/path
// unless you have a specific reason
```

For local development vs production, ensure `NEXT_PUBLIC_SUPABASE_URL` points to the right project.

### Cause 5: Using getSession() instead of getUser()

On the server, always use `getUser()`:

```typescript
// CORRECT — re-validates token against Supabase Auth server
const { data: { user } } = await supabase.auth.getUser()

// WRONG — reads session from cookie without re-validation, can be stale
const { data: { session } } = await supabase.auth.getSession()
```

### Cause 6: Multiple client instances

Ensure there is exactly one browser client instance (use a singleton pattern) and one server client created per request:

```bash
# Find all places creating a Supabase client
grep -rn "createBrowserClient\|createClient" \
  {PROJECT_ROOT}/apps/web/src/ \
  --include="*.ts" --include="*.tsx"
```

Consolidate to a single `lib/supabase/client.ts` (browser) and `lib/supabase/server.ts` (server) module.

## Prevention

- Use `@supabase/ssr` exclusively — remove `@supabase/auth-helpers-nextjs` if present
- Always call `getUser()` (not `getSession()`) in middleware and server components
- Ensure middleware covers all protected routes via the `matcher` config
- Test auth flow (login → refresh → protected route) after any auth-related changes
- Test with hard refresh (Cmd+Shift+R) to catch SSR session handling issues
