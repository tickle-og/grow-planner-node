#!/usr/bin/env bash
set -euo pipefail

# Files we want to sanitize (relative to repo root)
FILES=(
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

changed=0
for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "[skip] $f (missing)"
    continue
  fi

  # 1) Drop 'detail' from error payloads. Keep only a generic message.
  perl -0777 -pe '
    s/JSON\.stringify\(\{\s*message:\s*["\x27]Internal Error["\x27][^}]*\}\)/JSON.stringify({ message: "Internal Error" })/gs;
    s/JSON\.stringify\(\{\s*ok:\s*false\s*,\s*error:\s*[^,}]+,\s*detail:\s*[^}]+?\}\)/JSON.stringify({ message: "Internal Error" })/gs;
  ' -i "$f"

  # 2) Convert responses that still lack a content-type on 500 to include it.
  perl -0777 -pe '
    s@return new Response\(\s*JSON\.stringify\(\{\s*message:\s*["\x27]Internal Error["\x27]\s*\}\)\s*,\s*\{\s*status:\s*500\s*\}\s*\)
     @return new Response(JSON.stringify({ message: "Internal Error" }), { status: 500, headers: { "content-type": "application/json; charset=utf-8" } })@gsx;
  ' -i "$f"

  # 3) Handle common patterns that return raw e?.message or err?.message
  perl -0777 -pe '
    s/JSON\.stringify\(\{\s*ok:\s*false\s*,\s*error:\s*e\?\.[^,}\n]+(?:,\s*detail:\s*[^}]+)?\}\)/JSON.stringify({ message: "Internal Error" })/gs;
    s/JSON\.stringify\(\{\s*ok:\s*false\s*,\s*error:\s*err\?\.[^,}\n]+(?:,\s*detail:\s*[^}]+)?\}\)/JSON.stringify({ message: "Internal Error" })/gs;
  ' -i "$f"

  # If the file actually changed, mark it
  if ! git diff --quiet -- "$f"; then
    echo "[fix] $f"
    changed=$((changed+1))
  else
    echo "[ok ] $f (no leaks found)"
  fi
done

echo
echo "[scan] re-check for exposure strings (should print nothing):"
rg -n "detail:|error:\s*e\?\.|error:\s*err\?\.|Failed query" "${FILES[@]}" || true

echo
if [[ $changed -gt 0 ]]; then
  echo "[✓] Sanitization complete. Review 'git diff' then:"
  echo "    git checkout -b chore/harden-api-errors"
  echo "    git add -A && git commit -m 'chore(api): sanitize error responses; remove detail/e.message leaks'"
  echo "    git push -u origin chore/harden-api-errors"
else
  echo "[=] Nothing to change; endpoints already sanitized."
fi
