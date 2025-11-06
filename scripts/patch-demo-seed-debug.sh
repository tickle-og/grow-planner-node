# scripts/patch-demo-seed-debug.sh
#!/usr/bin/env bash
set -euo pipefail

f="src/routes/api/dev/seed/demo-tasks/+server.ts"
if [ ! -f "$f" ]; then
  echo "[err] $f not found (run the earlier wiring script first)"; exit 1
fi

cp -n "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)" || true

# Replace the catch to surface the error
perl -0777 -pe '
  s{return jsonError\(500\);\s*};{return json(500, { ok: false, error: (e as any)?.message ?? "Internal Error", stack: (e as any)?.stack ?? null });}s
' -i "$f"

echo "[ok] Patched $f to return error details"
echo "Restart dev and run:"
echo "  curl -s -X POST http://localhost:5173/api/dev/seed/demo-tasks | jq ."
