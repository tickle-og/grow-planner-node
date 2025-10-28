#!/usr/bin/env bash
set -euo pipefail

FILES=(
  "src/routes/api/catalog/container-presets/+server.ts"
  "src/routes/api/catalog/jar-variants/+server.ts"
  "src/routes/api/dashboard/active-grows/+server.ts"
  "src/routes/api/dashboard/activity/+server.ts"
  "src/routes/api/dashboard/low-stock/+server.ts"
  "src/routes/api/dashboard/next-actions/+server.ts"
  "src/routes/api/dashboard/recent-notes/+server.ts"
  "src/routes/api/dashboard/recent-yields/+server.ts"
  "src/routes/api/dashboard/status-counts/+server.ts"
  "src/routes/api/dev/seed/default-location/+server.ts"
  "src/routes/api/dev/seed/presets/+server.ts"
  "src/routes/api/locations/[id]/+server.ts"
  "src/routes/api/locations/[id]/shelves/+server.ts"
)

ensure_imports () {
  local f="$1"
  if ! rg -q "\$lib/server/http" "$f" >/dev/null 2>&1; then
    tmp="$(mktemp)"
    { echo "import { json, jsonError } from '\$lib/server/http';"; echo; cat "$f"; } > "$tmp"
    mv "$tmp" "$f"
  else
    if rg -q "from '\$lib/server/http'" "$f" && ! rg -q "import .*\\bjson\\b" "$f"; then
      tmp="$(mktemp)"
      { echo "import { json } from '\$lib/server/http';"; cat "$f"; } > "$tmp"
      mv "$tmp" "$f"
    fi
  fi
}

fix_file () {
  local f="$1"

  # 500 "Internal Error" (with or without headers) -> jsonError(500)
  perl -0777 -pe "s@return\\s+new\\s+Response\\([\\s\\S]*?\\{\\s*message:\\s*['\"]Internal Error['\"][\\s\\S]*?\\)[\\s\\S]*?status\\s*:\\s*500[\\s\\S]*?\\)@return jsonError(500)@g" -i -- "$f"

  # 404 'not found' -> json(..., 404)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*\\{\\s*ok:\\s*false\\s*,\\s*error:\\s*['\"]not found['\"]\\s*\\}\\s*\\)\\s*,\\s*\\{\\s*status\\s*:\\s*404\\s*\\}\\s*\\)@return json({ ok: false, error: 'not found' }, 404)@g" -i -- "$f"

  # 400 'label required' -> json(..., 400)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*\\{\\s*ok:\\s*false\\s*,\\s*error:\\s*['\"]label required['\"]\\s*\\}\\s*\\)\\s*,\\s*\\{\\s*status\\s*:\\s*400\\s*\\}\\s*\\)@return json({ ok: false, error: 'label required' }, 400)@g" -i -- "$f"

  # Any remaining success with headers or status -> json(payload, 200/201)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*([^\\)]*?)\\s*\\)\\s*,\\s*\\{\\s*status\\s*:\\s*201[\\s\\S]*?\\}\\s*\\)@return json(\\1, 201)@g" -i -- "$f"
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*([^\\)]*?)\\s*\\)\\s*,\\s*\\{\\s*status\\s*:\\s*200[\\s\\S]*?\\}\\s*\\)@return json(\\1, 200)@g" -i -- "$f"
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*([^\\)]*?)\\s*\\)\\s*,\\s*\\{\\s*headers\\s*:\\s*\\{[\\s\\S]*?\\}\\s*\\}\\s*\\)@return json(\\1, 200)@g" -i -- "$f"

  # Bare success -> json(payload, 200)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*([^\\)]*?)\\s*\\)\\s*\\)@return json(\\1, 200)@g" -i -- "$f"

  # Catalog caching for 200s
  case "$f" in
    src/routes/api/catalog/*/+server.ts)
      perl -0777 -pe "s/return\\s+json\\(\\s*([^,]+)\\s*,\\s*200\\s*\\)/return json(\\1, 200, 'public, max-age=60')/g" -i -- "$f"
    ;;
  esac
}

changed=0
for f in "${FILES[@]}"; do
  [[ -f "$f" ]] || { echo "[skip] $f (missing)"; continue; }
  ensure_imports "$f"
  fix_file "$f"
  if ! git diff --quiet -- "$f"; then
    echo "[fix] $f"
    changed=$((changed+1))
  else
    echo "[ok ] $f"
  fi
done

echo
echo "[scan] Leftovers (should be empty):"
rg -n "new\\s+Response\\s*\\(\\s*JSON\\.stringify" "${FILES[@]}" || true

echo
if [[ $changed -gt 0 ]]; then
  echo "[✓] Cleaned $changed file(s). You can commit with:"
  echo "    git checkout -b chore/api-json-leftover-pass2"
  echo "    git add -A && git commit -m 'chore(api): finalize json()/jsonError() normalization (pass 2)'"
  echo "    git push -u origin chore/api-json-leftover-pass2"
else
  echo "[=] Already clean."
fi
