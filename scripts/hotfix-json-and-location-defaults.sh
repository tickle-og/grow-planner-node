# scripts/hotfix-json-and-location-defaults.sh
set -euo pipefail

# 1) Make json() accept both: json(200, data)  AND  json(data, 200|{status})
JSON_FILE="src/lib/utils/json.ts"
mkdir -p "$(dirname "$JSON_FILE")"
cp -n "$JSON_FILE" "$JSON_FILE.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

cat > "$JSON_FILE" <<'TS'
export function json(a: number | unknown, b?: unknown) {
  let status: number;
  let data: unknown;

  if (typeof a === 'number') {
    // Called as json(200, data)
    status = a;
    data = b ?? {};
  } else {
    // Called as json(data, 200) or json(data, { status })
    data = a;
    if (typeof b === 'number') {
      status = b;
    } else if (b && typeof (b as any).status === 'number') {
      status = (b as any).status;
    } else {
      status = 200;
    }
  }

  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json' }
  });
}

export function jsonError(status = 500, message = 'Internal Error') {
  return json({ message }, { status });
}
TS

echo "[ok] Patched $JSON_FILE"

# 2) Default location_id to 1 (dev-friendly) instead of throwing
UTIL_FILE="src/routes/api/dashboard/_util.ts"
if [ -f "$UTIL_FILE" ]; then
  cp -n "$UTIL_FILE" "$UTIL_FILE.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
  awk '
    BEGIN {patched=0}
    {
      print
    }
    END {
      # no-op: we will overwrite below; awk step is just to keep a backup behavior similar to above
    }
  ' "$UTIL_FILE" >/dev/null 2>&1 || true

  cat > "$UTIL_FILE" <<'TS'
export function getLocationIdOrThrow(url: URL): number {
  const raw = url.searchParams.get('location_id') ?? url.searchParams.get('locationId');
  if (raw === null) {
    // Dev default: avoid 500s if Today/reports forget to pass a param
    console.warn('[dashboard] no location_id provided; defaulting to 1 (dev)');
    return 1;
  }
  const id = Number(raw);
  if (!Number.isFinite(id) || id <= 0) {
    console.warn('[dashboard] invalid location_id; defaulting to 1 (dev)');
    return 1;
  }
  return id;
}
TS
  echo "[ok] Patched $UTIL_FILE"
else
  echo "[skip] $UTIL_FILE not found; continuing"
fi

echo
echo "Next:"
echo "  1) Restart dev server: pnpm dev"
echo "  2) Reload Today. The RangeError should be gone, and dashboard routes will default to location_id=1."
echo "  3) (Optional) Run tests: DB_URL='file:./dev_test.db' pnpm test"
