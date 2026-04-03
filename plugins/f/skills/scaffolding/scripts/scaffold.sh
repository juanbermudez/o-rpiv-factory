#!/usr/bin/env bash
# scaffold.sh — Generate project boilerplate from a template
#
# Usage:
#   ./scaffold.sh <type> <name>
#
# Types:
#   api-route       API route handler
#   migration       Supabase SQL migration
#   ui-component    shadcn/ui React component
#   test            Vitest test file
#   hook            React Query data-fetch hook
#
# Examples:
#   ./scaffold.sh api-route orders
#   ./scaffold.sh migration add_orders_table
#   ./scaffold.sh ui-component OrderCard
#   ./scaffold.sh test OrderCard
#   ./scaffold.sh hook orders
#
# The script copies the template to a temp file, replaces common placeholders
# derived from <name>, and prints the result to stdout. The agent decides where
# to write the final file.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/../templates"

usage() {
  echo "Usage: $0 <type> <name>" >&2
  echo "Types: api-route | migration | ui-component | test | hook" >&2
  exit 1
}

if [[ $# -lt 2 ]]; then
  usage
fi

TYPE="$1"
NAME="$2"

# Derive common name variants using python3 for portability
# (macOS BSD sed lacks \U/\L case modifiers)
PASCAL_NAME="$(python3 -c "
import re, sys
s = sys.argv[1]
parts = re.split(r'[-_]', s)
result = []
for p in parts:
    result.extend(re.sub(r'([A-Z])', r'_\1', p).lstrip('_').split('_'))
print(''.join(w.capitalize() for w in result if w))
" "$NAME")"

SNAKE_NAME="$(python3 -c "
import re, sys
s = sys.argv[1]
s = re.sub(r'([A-Z])', r'_\1', s).lstrip('_')
s = re.sub(r'[-\s]', '_', s)
print(s.lower())
" "$NAME")"

KEBAB_NAME="$(echo "$SNAKE_NAME" | tr '_' '-')"
LOWER_NAME="$(echo "$SNAKE_NAME")"
TIMESTAMP="$(date -u +%Y%m%d%H%M%S)"

case "$TYPE" in
  api-route)
    TEMPLATE="${TEMPLATES_DIR}/api-route.ts.template"
    sed \
      -e "s/{{schemaName}}/${LOWER_NAME}Schema/g" \
      -e "s/{{method}}/POST/g" \
      -e "s/{{permission}}/${LOWER_NAME}.create/g" \
      -e "s/{{table}}/${SNAKE_NAME}/g" \
      -e "s/{{operation}}/insert/g" \
      -e "s/{{operationDescription}}/create ${KEBAB_NAME}/g" \
      "$TEMPLATE"
    ;;

  migration)
    TEMPLATE="${TEMPLATES_DIR}/migration.sql.template"
    sed \
      -e "s/{{timestamp}}/${TIMESTAMP}/g" \
      -e "s/{{description}}/${SNAKE_NAME}/g" \
      -e "s/{{table_name}}/${SNAKE_NAME}/g" \
      "$TEMPLATE"
    ;;

  ui-component)
    TEMPLATE="${TEMPLATES_DIR}/ui-component.tsx.template"
    sed \
      -e "s/{{ComponentName}}/${PASCAL_NAME}/g" \
      -e "s/{{title}}/${PASCAL_NAME}/g" \
      "$TEMPLATE"
    ;;

  test)
    TEMPLATE="${TEMPLATES_DIR}/test-file.test.ts.template"
    sed \
      -e "s/{{testSubject}}/${PASCAL_NAME}/g" \
      -e "s/{{testDescription}}/work correctly/g" \
      "$TEMPLATE"
    ;;

  hook)
    TEMPLATE="${TEMPLATES_DIR}/hook.ts.template"
    sed \
      -e "s/{{ResourceName}}/${PASCAL_NAME}/g" \
      -e "s/{{resourceKey}}/${LOWER_NAME}/g" \
      -e "s/{{table}}/${SNAKE_NAME}/g" \
      "$TEMPLATE"
    ;;

  *)
    echo "Unknown type: ${TYPE}" >&2
    usage
    ;;
esac
