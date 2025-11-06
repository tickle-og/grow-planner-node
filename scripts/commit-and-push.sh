#!/usr/bin/env bash
set -euo pipefail

# ---- config you can tweak ----
BR_PREFIX="feat/persist-dismiss-next-actions"
COMMIT_MSG="feat(tasks): persist dismissed_at; exclude in next-actions; compact Today widget + layout/tailwind fixes"
# ------------------------------

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repo. Run: git init && git add -A && git commit -m 'init'"
  exit 1
fi

# Make sure dev DB junk isn't committed
if [ -f ".gitignore" ] && ! rg -q '^dev\.db$' .gitignore; then
  {
    echo "# local sqlite artifacts"
    echo "dev.db"
    echo "dev_test.db"
    echo "*.db-wal"
    echo "*.db-shm"
  } >> .gitignore
  echo "[gitignore] added sqlite files"
fi

# Create a branch if you're on main or detached
CUR_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CUR_BRANCH" = "HEAD" ] || [ "$CUR_BRANCH" = "main" ] || [ "$CUR_BRANCH" = "master" ]; then
  NEW_BRANCH="${BR_PREFIX}-$(date +%Y%m%d-%H%M%S)"
  git switch -c "$NEW_BRANCH"
  echo "[branch] switched to $NEW_BRANCH"
else
  echo "[branch] using existing: $CUR_BRANCH"
fi

# Stage everything (includes drizzle migration and endpoint changes)
git add -A

# Quick status summary
echo "---- git status (short) ----"
git status -s || true
echo "----------------------------"

# Run tests locally to fail fast (pre-push will also run them)
echo "[test] running vitest…"
pnpm test

# Commit
git commit -m "$COMMIT_MSG" || {
  echo "Nothing to commit (working tree clean)."
}

# Ensure a remote exists
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "No 'origin' remote set."
  echo "Add one, e.g.:"
  echo "  git remote add origin git@github.com:<USER>/<REPO>.git"
  echo "Then re-run this script."
  exit 1
fi

# Push (pre-push hook should run here)
echo "[push] pushing to origin (and setting upstream)…"
git push -u origin "$(git rev-parse --abbrev-ref HEAD)"

echo "✅ Done. Your branch is on GitHub."
