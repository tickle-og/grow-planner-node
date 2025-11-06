# scripts/sqlite-seed-demo-tasks.sh
#!/usr/bin/env bash
set -euo pipefail

DB_FILE="${DB_FILE:-dev.db}"   # override if your dev DB filename is different
if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3 not found. On Ubuntu: sudo apt-get update && sudo apt-get install -y sqlite3"
  exit 1
fi

echo "[seed] using DB file: $DB_FILE"

sqlite3 "$DB_FILE" <<'SQL'
PRAGMA journal_mode=WAL;

BEGIN;

CREATE TABLE IF NOT EXISTS tasks (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  location_id INTEGER NOT NULL,
  title       TEXT NOT NULL,
  due_at      TEXT NULL,
  status      TEXT NOT NULL DEFAULT 'pending'
);

-- insert 4 demo rows only if table is currently empty
WITH cnt(x) AS (SELECT COUNT(*) FROM tasks)
INSERT INTO tasks (location_id, title, due_at, status)
SELECT 1, 'Sterilize jars', datetime('now'), 'pending'
WHERE (SELECT x FROM cnt)=0;

WITH cnt(x) AS (SELECT COUNT(*) FROM tasks)
INSERT INTO tasks (location_id, title, due_at, status)
SELECT 1, 'Shake grain', datetime('now','+2 days'), 'pending'
WHERE (SELECT x FROM cnt)=1;

WITH cnt(x) AS (SELECT COUNT(*) FROM tasks)
INSERT INTO tasks (location_id, title, due_at, status)
SELECT 1, 'Spawn to bulk', datetime('now','+5 days'), 'pending'
WHERE (SELECT x FROM cnt)=2;

WITH cnt(x) AS (SELECT COUNT(*) FROM tasks)
INSERT INTO tasks (location_id, title, due_at, status)
SELECT 1, 'Mist + fan', datetime('now','+7 days'), 'pending'
WHERE (SELECT x FROM cnt)=3;

COMMIT;
SQL

echo "[seed] done. Try:"
echo "  curl -s 'http://localhost:5173/api/dashboard/next-actions' | jq ."
