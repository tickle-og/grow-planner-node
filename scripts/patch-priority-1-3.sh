#!/usr/bin/env bash
set -euo pipefail

echo "[patch] starting Priority 1-3 fixes…"

need() { command -v "$1" >/dev/null || { echo "Missing tool: $1"; exit 1; }; }
need rg
need sed
need awk
need perl
need pnpm
need git

# 1) Canonical JSON helpers to $lib/server/http
mkdir -p src/lib/server
cat > src/lib/server/http.ts <<'TS'
// Canonical JSON helpers for SvelteKit endpoints.
export type JSONValue = unknown;

function toInit(init?: number | ResponseInit): ResponseInit {
  if (typeof init === 'number') return { status: init };
  return init ?? {};
}

export function json(data: JSONValue, init?: number | ResponseInit): Response {
  const base = toInit(init);
  const headers = new Headers(base.headers || {});
  if (!headers.has('content-type')) headers.set('content-type', 'application/json; charset=utf-8');
  if (!headers.has('cache-control')) headers.set('cache-control', 'no-store');
  return new Response(JSON.stringify(data), { ...base, headers });
}

export function jsonError(status = 500, body: JSONValue = { message: 'Internal Error' }): Response {
  const init = toInit(status);
  const headers = new Headers(init.headers || {});
  if (!headers.has('content-type')) headers.set('content-type', 'application/json; charset=utf-8');
  if (!headers.has('cache-control')) headers.set('cache-control', 'no-store');
  return new Response(
    JSON.stringify({
      ok: false,
      ...((body && typeof body === 'object') ? body : { error: String(body) })
    }),
    { ...init, status: typeof init.status === 'number' ? init.status : status, headers }
  );
}
TS

# 1b) Keep $lib/utils/json as a pass-through
mkdir -p src/lib/utils
cat > src/lib/utils/json.ts <<'TS'
export { json, jsonError } from '$lib/server/http';
TS

# 2) Remove unused better-sqlite3 client if it exists
if [ -f src/lib/db/client.ts ]; then
  git rm -q src/lib/db/client.ts || rm -f src/lib/db/client.ts
  echo "[patch] removed src/lib/db/client.ts"
fi

# 3) Fix seed presets endpoint (dedupe imports; add catch if try-without-catch)
TARGET="src/routes/api/dev/seed/presets/+server.ts"
if [ -f "$TARGET" ]; then
  # De-duplicate identical lines
  tmpf="$(mktemp)"
  awk '!seen[$0]++' "$TARGET" > "$tmpf" && cat "$tmpf" > "$TARGET"
  rm -f "$tmpf"

  # If POST handler has try with no catch, add a catch
  if rg -n '^export\s+const\s+POST\s*:' "$TARGET" >/dev/null 2>&1; then
    if rg -n '\btry\b' "$TARGET" >/dev/null 2>&1 && ! rg -n '\bcatch\b' "$TARGET" >/dev/null 2>&1; then
      perl -0777 -pe 's/(export\s+const\s+POST\s*:\s*[^=]*=\s*async\s*\([^)]*\)\s*=>\s*\{\s*.*?)(\n\}\s*;\s*)/$1\n} catch (err) {\n  console.error(err);\n  return jsonError(500, { error: err instanceof Error ? err.message : String(err) });\n}$2/s' \
        -i "$TARGET" || true
      echo "[patch] added catch block to $TARGET"
    fi
  fi
fi

# 4) Re-point imports to the canonical helper (treat $ literally)
changed=0
while IFS= read -r f; do
  sed -i 's#\$lib/utils/json#\$lib/server/http#g' "$f" && changed=1
done < <(rg -l -F '$lib/utils/json' src || true)
[ "$changed" -eq 1 ] && echo '[patch] updated imports to $lib/server/http'

# 5) Format & typecheck
pnpm -s format || true
pnpm -s typecheck

echo "[patch] done."
echo "Next:"
echo "  git add -A && git commit -m 'fix: unify JSON helpers; remove dead db client; seed preset catch'"
echo "  git push"
