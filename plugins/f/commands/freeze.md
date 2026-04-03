---
name: freeze
description: "Restrict file edits to a specific directory. Blocks Edit/Write outside the frozen path. Use when debugging to prevent accidental changes. Usage: /f:freeze <dir>. Deactivate with /f:freeze off."
---

# /f:freeze — Directory Edit Lock

Restrict all file edits (Edit and Write) to a specific directory for this session.

## Instructions

### Activating freeze mode

When the user runs `/f:freeze <directory>`:

1. Capture the directory path argument provided by the user.
2. Set the environment variable:
   ```bash
   export CLAUDE_FACTORY_FREEZE_DIR=<path>
   ```
3. Tell the user:
   > Freeze active — edits restricted to `{directory}`.
   >
   > Any attempt to Edit or Write files outside `{directory}` will be blocked.
   >
   > The hook enforcing this is `.claude/skills/product-dev-workflow/hooks/freeze-guard.sh`.
   > Deactivate with `/f:freeze off`.

### Deactivating freeze mode

When the user runs `/f:freeze off`:

1. Unset the environment variable:
   ```bash
   unset CLAUDE_FACTORY_FREEZE_DIR
   ```
2. Tell the user:
   > Freeze deactivated. File edits are no longer restricted to a directory.

### No argument provided

If the user runs `/f:freeze` with no argument and not `off`, ask:
> Which directory should edits be restricted to? Usage: `/f:freeze <path>`
