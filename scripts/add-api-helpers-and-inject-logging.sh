#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

# 1) Write helpers (idempotent: overwrite with canonical content)
mkdir -p src/lib/server

cat > src/lib/server/http.ts <<'TS'
// Lightweight JSON helpers for consistent responses
export function json(data: unknown, status = 200, cache = 'no-store') {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': cache
    }
  });
}

export function jsonError(status = 500, message = 'Internal Error') {
  return json({ message }, status);
}
TS

cat > src/lib/server/log.ts <<'TS'
// Minimal server-side error logger
export function logError(where: string, err: unknown, extra?: Record<string, unknown>) {
  const e = err as any;
  // Keep it simple and structured for tail -f
  console.error(`[${new Date().toISOString()}]`, where, {
    message: e?.message ?? String(err),
    stack: e?.stack,
    cause: e?.cause?.message ?? e?.cause,
    ...extra
  });
}
TS

# 2) Targeted files to sanitize + instrument
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

  # 3) Ensure imports exist (without duplicating)
  if ! rg -q "\$lib/server/http" "$f"; then
    # Insert helper imports after the last existing import line (or at top if none)
    perl -0777 -pe '
      if ($ARGV eq $ENV{TGT}) {
        if (s/\A((?:\s*import[^\n]*\n)+)/$1 . "import { json, jsonError } from '\''\$lib\/server\/http'\'';\nimport { logError } from '\''\$lib\/server\/log'\'';\n"/e) {
          $_
        } else {
          $_ = "import { json, jsonError } from '\''\$lib\/server\/http'\'';\nimport { logError } from '\''\$lib\/server\/log'\'';\n\n" . $_;
        }
      }
    ' -i -- "$f"
  fi

  # 4) Insert logError at the top of each catch(...) block (only if that catch lacks a logError)
  # We do a conservative pass: if the file already has at least one logError, skip mass insertion.
  if ! rg -q "logError\(" "$f"; then
    perl -0777 -pe '
      s/catch\s*\(\s*(\w+)\s*\)\s*\{\s*/"catch ($1) {\n  logError(import.meta.url, $1);\n"/ge
    ' -i -- "$f"
  else
    # For files with logError somewhere, only add in catch blocks that are missing it
    perl -0777 -pe '
      $_ =~ s{
        catch \s* \( \s* (\w+) \s* \) \s* \{        # catch (err) {
        (                                           # body start
          (?: (?! \} ). )*?                        # lazily consume until the block ends
        )
        \}
      }{
        my ($v,$body) = ($1,$2);
        if ($body !~ /logError\s*\(/) {
          "catch ($v) {\n  logError(import.meta.url, $v);\n$body}"
        } else {
          "catch ($v) {$body}"
        }
      }egsx;
    ' -i -- "$f"
  fi

  # 5) Convert explicit "Internal Error" Response payloads to jsonError(500)
  perl -0777 -pe '
    s@return\s+new\s+Response\(\s*JSON\.stringify\(\{\s*message:\s*["\x27]Internal Error["\x27]\s*\}\)\s*,\s*\{\s*status:\s*500(?:[^}]*)\}\s*\)@return jsonError(500)@gs;
  ' -i -- "$f"

  # 6) Convert other common sanitized patterns to jsonError(500)
  perl -0777 -pe '
    s@return\s+new\s+Response\(\s*JSON\.stringify\(\{\s*message:\s*["\x27]Internal Error["\x27]\s*\}\)\s*\)\s*;@return jsonError(500);@gs;
  ' -i -- "$f"

  # 7) If any raw e?.message payloads still slipped by, neutralize them to jsonError(500)
  perl -0777 -pe '
    s@JSON\.stringify\(\{\s*ok:\s*false\s*,\s*error:\s*(?:e|err)\?\.[^,}]+(?:,\s*detail:\s*[^}]+)?\}\)@JSON.stringify({ message: "Internal Error" })@gs;
  ' -i -- "$f"

  if ! git diff --quiet -- "$f"; then
    echo "[fix] $f"
    changed=$((changed+1))
  else
    echo "[ok ] $f (no changes)"
  fi
done

echo
echo "[scan] Verify no leaks remain in target files (should print nothing):"
rg -n "detail:|error:\s*e\?\.|error:\s*err\?\.|Failed query" "${FILES[@]}" || true

echo
if [[ $changed -gt 0 ]]; then
  echo "[✓] Helper import + logging injection complete in $changed file(s). Review:"
  echo "    git checkout -b chore/api-helpers-logging"
  echo "    git add -A && git commit -m 'chore(api): add json/jsonError helpers; inject logError in catch blocks; standardize error returns'"
  echo "    git push -u origin chore/api-helpers-logging"
else
  echo "[=] Files were already aligned with helpers/logging."
fi
