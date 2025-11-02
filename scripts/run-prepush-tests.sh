#!/usr/bin/env bash
set -euo pipefail

# Use an isolated DB so we never collide with dev server DB
export DB_URL="${DB_URL:-file:./dev_prepush.db}"
rm -f ./dev_prepush.db || true

echo "[pre-push] Using DB_URL=$DB_URL"

# Ensure deps (idempotent)
if [ ! -d node_modules ]; then
  echo "[pre-push] Installing dependencies…"
  pnpm install --frozen-lockfile || pnpm install
fi

pnpm -s test
