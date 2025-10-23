#!/usr/bin/env bash
set -euo pipefail

# Create a clean, timestamped source archive using git-archive.
# Requires an initialized git repo.

ts="$(date -u +'%Y%m%dT%H%M%SZ')"
mkdir -p snapshots

# Use current branch name in filename
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
fname="snapshots/repo-${branch}-${ts}.tar.gz"

git ls-files >/dev/null 2>&1 || { echo "[err] Not a git repo"; exit 1; }

echo "[info] Writing ${fname}"
git archive --format=tar.gz -o "${fname}" HEAD

echo "[done] Canned to ${fname}"
