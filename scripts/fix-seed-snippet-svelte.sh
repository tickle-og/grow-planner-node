# scripts/fix-seed-snippet-svelte.sh
set -euo pipefail
FILE="src/routes/+page.svelte"
cp -n "$FILE" "$FILE.bak.$(date +%Y%m%d-%H%M%S)" || true

# Replace the curl block that targets /api/dev/seed/default-location with a safe template-string version
awk '
  BEGIN { in_block=0 }
  /<pre/ && /seed\/default-location/ { in_block=1 }
  {
    if (in_block && /<\/pre>/) {
      print "  <pre class=\"mono overflow-auto mt-2 p-3 bg-white rounded-lg border\">"
      print "    <code>{`curl -X POST http://localhost:5173/api/dev/seed/default-location \\"
      print "  -H \"content-type: application/json\" \\"
      print "  -d '\''{\"owner_user_id\":1,\"name\":\"Default Lab\",\"timezone\":\"America/Denver\"}'\''`}</code>"
      print "  </pre>"
      in_block=0
      next
    }
    if (!in_block) print $0
  }
' "$FILE" > "$FILE.tmp"

mv "$FILE.tmp" "$FILE"
echo "[ok] Patched $FILE (seed curl snippet now safe for Svelte)."
