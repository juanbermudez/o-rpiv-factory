---
name: runbooks
description: >
  Diagnose and resolve common issues: RLS permission denied, migration failures,
  deploy errors, search sync, auth session problems. Symptom-driven playbooks with
  step-by-step resolution.
---

# Runbook Skill

Use this skill when something is broken and you need a structured path to diagnosis and resolution. Each playbook is symptom-driven — find your symptoms in the routing table, then follow the playbook.

## Symptom → Playbook Routing

| Symptom | Playbook |
|---------|----------|
| `permission denied for table X` | [RLS Permission Denied](playbooks/rls-permission-denied.md) |
| Empty results when data exists | [RLS Permission Denied](playbooks/rls-permission-denied.md) |
| 403 from API route | [RLS Permission Denied](playbooks/rls-permission-denied.md) |
| Migration error / `relation does not exist` | [Supabase Migration Fail](playbooks/supabase-migration-fail.md) |
| Type mismatch in migration | [Supabase Migration Fail](playbooks/supabase-migration-fail.md) |
| `pgp_sym_encrypt` / `pgcrypto` not found | [Supabase Migration Fail](playbooks/supabase-migration-fail.md) |
| Vercel build fails | [Vercel Deploy Fail](playbooks/vercel-deploy-fail.md) |
| Deploy timeout / upload hangs | [Vercel Deploy Fail](playbooks/vercel-deploy-fail.md) |
| 500 error after deploy | [Vercel Deploy Fail](playbooks/vercel-deploy-fail.md) |
| Search returns stale or missing results | [Typesense Sync](playbooks/typesense-sync.md) |
| New records not appearing in search | [Typesense Sync](playbooks/typesense-sync.md) |
| Random logouts / 401 errors | [Auth Session Issues](playbooks/auth-session-issues.md) |
| `session expired` on page refresh | [Auth Session Issues](playbooks/auth-session-issues.md) |
| Middleware not forwarding auth | [Auth Session Issues](playbooks/auth-session-issues.md) |

## General Debugging Approach

When symptoms don't match a playbook exactly:

1. **Narrow the layer** — Is this a database issue (RLS, migration), network issue (API, deploy), or client issue (auth, cookies)?
2. **Check logs first** — Vercel function logs, Supabase logs, browser console. Don't guess what broke.
3. **Reproduce minimally** — Isolate the failure to the smallest possible case.
4. **Check recent changes** — `git log --oneline -20` to see what changed recently.
5. **Verify assumptions** — The bug is often in the assumption, not the code.

After 3 failed attempts to diagnose, stop and escalate. Document what you tried.
