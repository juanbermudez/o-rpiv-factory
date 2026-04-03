# Security Checklist — Verification Guide

Run this checklist on every changed file. Security issues are automatic FAIL — there are no partial passes.

## Checklist

### 1. Authentication — withPermission Middleware

For every API route file in the diff:

```bash
# Check that withPermission wraps all exported handlers
grep -n "export const" {route-file}
grep -n "withPermission" {route-file}
```

**FAIL if**: Any exported handler (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`) is not wrapped in `withPermission`.

**FAIL if**: `withPermission` is called but the permission scope string is missing or empty.

### 2. Organization Scoping

For every Supabase query in the diff:

```bash
# Find all .from() calls without .eq('organization_id'
grep -n "\.from(" {file}
grep -n "organization_id" {file}
```

**FAIL if**: Any `.from('table')` chain does not include `.eq('organization_id', ctx.organizationId)` before `.select()` or the final operation.

**FAIL if**: `organization_id` is taken from request body or query params instead of `ctx.organizationId`.

### 3. Input Validation — Zod

For every route that accepts a request body:

```bash
grep -n "req.json()" {file}
grep -n "\.parse(" {file}
grep -n "z\.object" {file}
```

**FAIL if**: `await req.json()` is called without being immediately passed to a Zod schema's `.parse()`.

**FAIL if**: User input (query params, headers, body) is used without validation.

### 4. No PII in Logs

```bash
grep -n "console\." {file}
grep -n "logger\." {file}
```

**FAIL if**: SSN, tax ID, full credit card number, driver's license number, or similar PII is logged.

**WARN if**: Email addresses or names are logged (acceptable in some contexts, but review intent).

### 5. No Secrets in Code

```bash
grep -n "sk_" {file}
grep -n "secret" {file}
grep -n "password" {file}
grep -n "key.*=" {file}
```

**FAIL if**: Hardcoded API keys, passwords, or secrets found.

**PASS if**: References are to `process.env.VAR_NAME` only.

### 6. RLS Policies (Database Changes)

See [database-verification.md](database-verification.md) for full RLS policy verification.

**FAIL if**: New table has no RLS policy.

**FAIL if**: RLS policy does not use `organization_id` from JWT.

### 7. Monetary Values

```bash
grep -n "_price\b\|_cost\b\|_amount\b\|_fee\b" {file}
grep -n "DECIMAL\|FLOAT\|NUMERIC" {file}
```

**FAIL if**: Any monetary column or variable lacks the `_cents` suffix.

**FAIL if**: SQL migration uses DECIMAL, FLOAT, or NUMERIC for a money column.

## Reporting Security Issues

Each security issue must include:
- File path and line number
- The specific rule violated
- The exact code that violates it
- What the correct code should look like

Security issues are reported with severity CRITICAL in the verification report and cause an automatic FAIL regardless of other results.
