# scripts/fix-location-shelves-mismatch.sh
set -euo pipefail
DB="${1:-./dev.db}"

echo "[*] Backing up $DB → ${DB}.bak.$(date +%Y%m%d%H%M%S)"
cp -f "$DB" "${DB}.bak.$(date +%Y%m%d%H%M%S)"

sqlite3 "$DB" 'PRAGMA foreign_keys=ON;'

HAS_NAME_COL=$(sqlite3 "$DB" "SELECT 1 FROM pragma_table_info('location_shelves') WHERE name='name' LIMIT 1;")

if [ "$HAS_NAME_COL" = "1" ]; then
  echo "[*] Migrating location_shelves schema to use 'label' (and make size fields nullable)..."

  sqlite3 "$DB" <<'SQL'
BEGIN;

-- 1) Create new table in the shape your Drizzle schema expects
CREATE TABLE location_shelves__new (
  id           INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  location_id  INTEGER NOT NULL,
  label        TEXT NOT NULL,
  length_cm    INTEGER,
  width_cm     INTEGER,
  height_cm    INTEGER,
  levels       INTEGER DEFAULT 1,
  created_at   TEXT DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (location_id) REFERENCES locations(id) ON UPDATE NO ACTION ON DELETE CASCADE
);

-- 2) Copy data, mapping name→label when label is missing
INSERT INTO location_shelves__new (id, location_id, label, length_cm, width_cm, height_cm, levels, created_at)
SELECT
  id,
  location_id,
  COALESCE(label, name),
  NULLIF(length_cm, 0),
  NULLIF(width_cm, 0),
  NULLIF(height_cm, 0),
  levels,
  created_at
FROM location_shelves;

-- 3) Swap tables
DROP TABLE location_shelves;
ALTER TABLE location_shelves__new RENAME TO location_shelves;

COMMIT;
SQL

  echo "[✓] location_shelves migrated"
else
  echo "[=] location_shelves already uses 'label' — no migration needed."
fi

echo "[*] Final schema:"
sqlite3 "$DB" ".schema location_shelves"
