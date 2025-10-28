set -euo pipefail
DB="${1:-./dev.db}"

echo "[*] Patching $DB"
sqlite3 "$DB" "PRAGMA foreign_keys=ON;"

add_col_if_missing () {
  local table="$1" col="$2" decl="$3"
  if ! sqlite3 "$DB" "SELECT 1 FROM pragma_table_info('$table') WHERE name='$col';" | grep -q 1; then
    echo "  [+] ALTER TABLE $table ADD COLUMN $col $decl"
    sqlite3 "$DB" "ALTER TABLE $table ADD COLUMN $col $decl"
  else
    echo "  [=] $table.$col already exists"
  fi
}

add_col_if_missing location_shelves label "TEXT"
add_col_if_missing location_shelves levels "INTEGER DEFAULT 1"
add_col_if_missing location_shelves created_at "TEXT DEFAULT (CURRENT_TIMESTAMP)"
