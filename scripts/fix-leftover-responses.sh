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

CATALOG_FILES=(
  "src/routes/api/catalog/container-presets/+server.ts"
  "src/routes/api/catalog/jar-variants/+server.ts"
)

ensure_imports () {
  local f="$1"
  if ! rg -q "\$lib/server/http" "$f" >/dev/null 2>&1; then
    # Prepend the import (idempotent because of the check above)
    tmp="$(mktemp)"
    {
      echo "import { json, jsonError } from '\$lib/server/http';"
      echo
      cat "$f"
    } > "$tmp"
    mv "$tmp" "$f"
  else
    # If the module is imported but `json` is missing, add a small import line (safe duplication)
    if rg -q "from '\$lib/server/http'" "$f" && ! rg -q "import .*\\bjson\\b" "$f"; then
      tmp="$(mktemp)"
      {
        echo "import { json } from '\$lib/server/http';"
        cat "$f"
      } > "$tmp"
      mv "$tmp" "$f"
    fi
  fi
}

convert_file () {
  local f="$1"

  # 500 → jsonError(500)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*\\{\\s*message:\\s*[\"']Internal Error[\"']\\s*\\}\\s*\\)\\s*,\\s*\\{[^}]*?\\bstatus\\s*:\\s*500\\b[^}]*\\}\\s*\\)@return jsonError(500)@gs" -i -- "$f"

  # 4xx → json(payload, status)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*(\\{(?:[^{}]|\\{[^{}]*\\})*\\))\\s*\\)\\s*,\\s*\\{\\s*status\\s*:\\s*(4\\d{2})\\b[^}]*\\}\\s*\\)@return json(\\1, \\2)@gs" -i -- "$f"

  # Success explicit 201 → json(payload, 201)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*([^()]+?)\\s*\\)\\s*,\\s*\\{\\s*status\\s*:\\s*201\\b[^}]*\\}\\s*\\)@return json(\\1, 201)@gs" -i -- "$f"

  # Success explicit 200 → json(payload, 200)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*([^()]+?)\\s*\\)\\s*,\\s*\\{\\s*status\\s*:\\s*200\\b[^}]*\\}\\s*\\)@return json(\\1, 200)@gs" -i -- "$f"

  # Success with headers only (assume 200) → json(payload, 200)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*([^()]+?)\\s*\\)\\s*,\\s*\\{\\s*headers\\s*:\\s*\\{[^}]*\\}\\s*\\}\\s*\\)@return json(\\1, 200)@gs" -i -- "$f"

  # Bare success → json(payload, 200)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*([^()]+?)\\s*\\)\\s*\\)@return json(\\1, 200)@gs" -i -- "$f"

  # Any straggler Internal Error without explicit status → jsonError(500)
  perl -0777 -pe "s@return\\s+new\\s+Response\\(\\s*JSON\\.stringify\\(\\s*\\{\\s*message:\\s*[\"']Internal Error[\"']\\s*\\}\\s*\\)\\s*\\)@return jsonError(500)@gs" -i -- "$f"
}

apply_catalog_cache () {
  local f="$1"
  # Add public short cache to catalog 200s that don't already pass a cache arg
  perl -0777 -pe "s/return\\s+json\\(\\s*([^,]+)\\s*,\\s*200\\s*\\)/return json(\\1, 200, 'public, max-age=60')/g" -i -- "$f"
}

changed=0
for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "[skip] $f (missing)"
    continue
  fi

  ensure_imports "$f"
  convert_file "$f"

  for cf in "${CATALOG_FILES[@]}"; do
    if [[ "$f" == "$cf" ]]; then
      apply_catalog_cache "$f"
    fi
  done

  if ! git diff --quiet -- "$f"; then
    echo "[fix] $f"
    changed=$((changed+1))
  else
    echo "[ok ] $f"
  fi
done

echo
echo "[scan] Any leftover raw Response(JSON.stringify(...))? (should show nothing)"
rg -n "new\\s+Response\\s*\\(\\s*JSON\\.stringify" "${FILES[@]}" || true

echo
if [[ $changed -gt 0 ]]; then
  echo "[✓] Normalized $changed file(s). Review with 'git diff', then:"
  echo "    git checkout -b chore/api-json-leftover-fixes"
  echo "    git add -A && git commit -m 'chore(api): finalize json()/jsonError() usage and catalog caching'"
  echo "    git push -u origin chore/api-json-leftover-fixes"
else
  echo "[=] Already clean."
fi
