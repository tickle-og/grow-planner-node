#!/usr/bin/env bash
# scripts/dev-tasks-sanity.sh
set -euo pipefail

# --- safe defaults with `-u` on ---
: "${DB_URL:=file:./dev.db}"
: "${BASE_URL:=http://localhost:5173}"

# Resolve the local sqlite file path from DB_URL
if [[ "$DB_URL" == file:* && "$DB_URL" != file::memory:* ]]; then
  DB_PATH="${DB_URL#file:}"
else
  DB_PATH="./dev.db"
fi

jq_safe() { command -v jq >/dev/null 2>&1 && jq . || cat; }
curl_json() { curl -sS -H 'content-type: application/json' "$@"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "[sanity] missing '$1'"; exit 1; }; }

need sqlite3
mkdir -p "$(dirname "$DB_PATH")" >/dev/null 2>&1 || true
touch "$DB_PATH"

echo "[sanity] Using DB_PATH=$DB_PATH"
echo "[sanity] Using BASE_URL=$BASE_URL"

# --- create tables if missing (dev only) ---
sqlite3 "$DB_PATH" <<'SQL'
PRAGMA foreign_keys=ON;
CREATE TABLE IF NOT EXISTS locations (
  id            INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  owner_user_id INTEGER,
  name          TEXT NOT NULL,
  nickname      TEXT,
  timezone      TEXT NOT NULL,
  is_active     INTEGER DEFAULT 1,
  created_at    TEXT DEFAULT (CURRENT_TIMESTAMP),
  updated_at    TEXT
);
CREATE TABLE IF NOT EXISTS tasks (
  id           INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  location_id  INTEGER NOT NULL,
  title        TEXT NOT NULL,
  status       TEXT NOT NULL CHECK (status IN ('pending','active','completed','failed')),
  due_at       TEXT,
  notes        TEXT,
  created_at   TEXT DEFAULT (CURRENT_TIMESTAMP),
  updated_at   TEXT,
  FOREIGN KEY (location_id) REFERENCES locations(id) ON UPDATE NO ACTION ON DELETE CASCADE
);
SQL

# Ensure location #1 exists
if [[ "$(sqlite3 "$DB_PATH" "select count(*) from locations where id=1;")" -eq 0 ]]; then
  echo "[seed] Seeding default location via API…"
  curl_json -X POST "$BASE_URL/api/dev/seed/default-location" \
    -d '{"owner_user_id":1,"name":"Default Lab","timezone":"America/Denver"}' | jq_safe
else
  echo "[sanity] location id=1 exists"
fi

# Try API tasks seed
echo "[seed] POST /api/dev/seed/tasks {locationId:1}"
SEED_RES="$(curl_json -X POST "$BASE_URL/api/dev/seed/tasks" -d '{"locationId":1}')"
echo "$SEED_RES" | jq_safe

# Fallback: insert demo tasks directly if API still hides the error
if echo "$SEED_RES" | grep -q '"message"\s*:\s*"Internal Error"'; then
  echo "[fallback] API returned Internal Error — inserting demo tasks directly…"
  sqlite3 "$DB_PATH" <<'SQL'
INSERT INTO tasks (location_id,title,status,due_at,notes) VALUES
  (1,'Check colonization (Batch A)','pending',datetime('now','+2 days'),'80–90% → spawn to bulk'),
  (1,'Hydrate CVG substrate','pending',datetime('now','+1 days'),'Prep 3× 5-lb bags'),
  (1,'Dial FAE for monotubs','active',datetime('now','+3 days'),'Aim RH ~92%'),
  (1,'Harvest flush #1 (Rack A)','pending',datetime('now','+5 days'),'AM window'),
  (1,'Record yields & notes','pending',datetime('now','+6 days'),'Dashboard → Recent yields');
SQL
fi

# Show counts
echo "[check] DB counts:"
sqlite3 "$DB_PATH" "select 'locations', count(*) from locations;" | sed 's/^/  /'
sqlite3 "$DB_PATH" "select 'tasks@1', count(*) from tasks where location_id=1;" | sed 's/^/  /'

echo "[done] Reload Today/Calendar. If API seed still 500s, check the dev server logs."
