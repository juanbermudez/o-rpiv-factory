---
name: careful
description: "Activate safety guard that blocks destructive operations (rm -rf, DROP TABLE, force-push, hard reset, kubectl delete). Use when working near production systems. Deactivate with /f:careful off."
---

# /f:careful — On-Demand Safety Guard

Activate or deactivate the careful mode safety hook for this session.

## Instructions

### Activating careful mode

When the user runs `/f:careful` (with no argument or any argument other than `off`):

1. Set the environment variable `CLAUDE_FACTORY_CAREFUL_MODE=1` using:
   ```bash
   export CLAUDE_FACTORY_CAREFUL_MODE=1
   ```
2. Tell the user:
   > Safety guard active — destructive operations blocked for this session.
   >
   > The following operations are now blocked:
   > - `rm -rf` — recursive force delete
   > - `DROP TABLE` / `DROP DATABASE` — destructive SQL
   > - `git push --force` / `git push -f` — force push
   > - `git reset --hard` — hard reset
   > - `DELETE FROM` without `WHERE` — unbounded delete
   > - `kubectl delete` — Kubernetes resource deletion
   >
   > The hook enforcing this is `.claude/skills/product-dev-workflow/hooks/careful-guard.sh`.
   > Deactivate with `/f:careful off`.

### Deactivating careful mode

When the user runs `/f:careful off`:

1. Unset the environment variable:
   ```bash
   unset CLAUDE_FACTORY_CAREFUL_MODE
   ```
2. Tell the user:
   > Safety guard deactivated. Destructive operations are no longer blocked.
