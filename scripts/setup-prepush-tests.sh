
# scripts/setup-prepush-tests.sh
#!/usr/bin/env bash
set -euo pipefail

# 1) Require a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[pre-push-setup] Not a git repo. Run: git init && git add -A && git commit -m 'init'"
  exit 1
fi

# 2) Tell git to use .husky/ as hooks directory (no Husky runtime needed)
git config core.hooksPath .husky

# 3) Ensure hooks dir exists
mkdir -p .husky

# 4) Create the reusable test runner (isolated DB to avoid locks)
mkdir -p scripts
cat > scripts/run-prepush-tests.sh <<'SH'
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
SH
chmod +x scripts/run-prepush-tests.sh

# 5) Wire the actual pre-push hook (pure Git hook, no husky.sh)
cat > .husky/pre-push <<'SH'
#!/usr/bin/env bash
set -euo pipefail

# Make sure we run from repo root
cd "$(git rev-parse --show-toplevel)"

echo "[pre-push] Running tests… (bypass with: git push --no-verify)"
scripts/run-prepush-tests.sh || {
  echo "[pre-push] Tests failed. Push aborted."
  exit 1
}
SH
chmod +x .husky/pre-push

echo "[✓] Pre-push hook installed without husky init. Try a push; it will block on failing tests."
