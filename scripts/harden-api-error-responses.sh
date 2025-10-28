# scripts/harden-api-error-responses.sh
#!/usr/bin/env bash
set -euo pipefail

# Find endpoints that leak error details
files="$(rg -l 'Internal Error|detail:\s|error:\s*e\?\.' src/routes || true)"

if [ -z "${files}" ]; then
  echo "[=] No candidate files found. You're already clean."
  exit 0
fi

for f in ${files}; do
  # 1) Strip "detail" payloads from error responses that already say "Internal Error"
  perl -0777 -pe '
    s/JSON\.stringify\(\{\s*message:\s*["\x27]Internal Error["\x27][^}]*\}\)/JSON.stringify({ message: "Internal Error" })/gs
  ' -i "$f"

  # 2) Replace `{ ok:false, error:e?.message, detail:... }` with generic message
  perl -0777 -pe '
    s/JSON\.stringify\(\{\s*ok:\s*false\s*,\s*error:\s*[^,}]+,\s*detail:\s*[^}]+?\}\)/JSON.stringify({ message: "Internal Error" })/gs
  ' -i "$f"

  # 3) Make sure the 500 response has content-type
  perl -0777 -pe '
    s@return new Response\(\s*JSON\.stringify\(\{\s*message:\s*["\x27]Internal Error["\x27]\s*\}\)\s*,\s*\{\s*status:\s*500\s*\}\s*\)@return new Response(JSON.stringify({ message: "Internal Error" }), { status: 500, headers: { "content-type": "application/json; charset=utf-8" } })@gs
  ' -i "$f"
done

# NOTE: Do not interpolate $lib here; escape the $ to avoid set -u complaining.
echo "[✓] Sanitized error responses. Consider importing helpers: import { json, jsonError } from '\$lib/server/http' and logging with logError()."
