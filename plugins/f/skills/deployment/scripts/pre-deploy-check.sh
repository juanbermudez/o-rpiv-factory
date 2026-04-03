#!/bin/bash
set -e

echo "Running pre-deploy checks..."

pnpm lint || { echo "FAIL: lint errors"; exit 1; }
pnpm typecheck || { echo "FAIL: type errors"; exit 1; }
pnpm test || { echo "FAIL: test failures"; exit 1; }
pnpm --filter "${WEB_FILTER:-@myapp/web}" build || { echo "FAIL: build errors"; exit 1; }

echo "All checks passed!"
