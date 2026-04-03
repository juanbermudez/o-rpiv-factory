# API Verification Guide

Use this guide when the task includes new or modified API endpoints.

## Setup

The dev server must be running:

```bash
pnpm dev  # or the project-specific command
# Runs on localhost (port varies by project — check package.json or .env.local)
```

Get a test auth token from `.env.local`:
```bash
cat .env.local | grep TEST_
```

## Verification Checklist

For each API endpoint in the diff:

### 1. Authentication Check
```bash
# Call without auth token → must return 401
curl -s http://localhost:3002/api/v1/{resource} | jq .status
# Expected: 401
```

### 2. Authorization Check
```bash
# Call with a token from a DIFFERENT org → must return 403 or empty data
curl -s -H "Authorization: Bearer {other-org-token}" \
  http://localhost:3002/api/v1/{resource} | jq .
# Expected: 403 or { data: [] }
```

### 3. Org Scoping Check
Verify that the response only contains data from the authenticated org. If you can, create a record in Org A and confirm Org B cannot see it.

### 4. Input Validation Check
```bash
# POST with missing required fields → must return 400
curl -s -X POST \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{}' \
  http://localhost:3002/api/v1/{resource} | jq .
# Expected: 400 with error message describing the missing field
```

### 5. Happy Path Check
```bash
# POST with valid data → must return 200/201 with created resource
curl -s -X POST \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{"field": "value", "amount_cents": 10000}' \
  http://localhost:3002/api/v1/{resource} | jq .
# Expected: { data: { id: "...", ... } }
```

### 6. Monetary Value Check
Verify monetary values in the response are integers (cents), not floats:
- `"listing_price_cents": 24500` — correct
- `"listing_price": 245.00` — wrong (report as FAIL)

## Route Code Review

Read the route file in the diff. Verify:
- `withPermission` wraps every exported handler
- Every Supabase query includes `.eq('organization_id', ctx.organizationId)`
- All input parsing uses Zod (not raw `await req.json()`)
- Error handling uses the response helpers (`ok`, `badRequest`, `serverError`)
- Audit log is emitted for write operations

## Recording Results

For each check:
```
Auth check:     PASS — 401 returned for unauthenticated request
Authz check:    PASS — Different org receives 403
Org scoping:    PASS — Org B cannot see Org A's orders
Input valid:    PASS — 400 returned with "name is required"
Happy path:     PASS — 201 returned with created resource
Money format:   PASS — listing_price_cents is integer
```
