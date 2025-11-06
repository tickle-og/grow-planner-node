# scripts/fix-tailwind-apply.sh
#!/usr/bin/env bash
set -euo pipefail

FILE="src/app.css"
[ -f "$FILE" ] || { echo "Missing $FILE"; exit 1; }

TS="$(date +%Y%m%d-%H%M%S)"
cp -p "$FILE" "$FILE.bak.$TS"
echo "[backup] $FILE.bak.$TS"

# Ensure Tailwind v4 bootstrap is present near the top
# - @import "tailwindcss";
# - @reference "tailwindcss/utilities";
# - @source for your Svelte/TS/JS files so scanning is guaranteed
awk '
BEGIN { inserted=0 }
NR==1 && $0 !~ /@import "tailwindcss";/ {
  print "@import \"tailwindcss\";"
  print "@reference \"tailwindcss/utilities\";"
  print "@source \"./src/**/*.{html,svelte,ts,js}\";"
  print ""
  inserted=1
}
{ print }
' "$FILE" > "$FILE.tmp.1"

# If the imports weren’t at line 1, make sure they’re present at all
# (idempotent insertion if missing).
if ! rg -q '@import "tailwindcss";' "$FILE.tmp.1"; then
  sed -i '1i @import "tailwindcss";\n@reference "tailwindcss/utilities";\n@source "./src/**/*.{html,svelte,ts,js}";\n' "$FILE.tmp.1"
fi

# Replace problematic @apply of max-w-6xl with plain CSS
perl -0777 -pe 's/@apply\s+max-w-6xl\s*;/max-width: 72rem;/g' "$FILE.tmp.1" > "$FILE.tmp.2"

mv "$FILE.tmp.2" "$FILE"
rm -f "$FILE.tmp.1"

echo "[ok] Tailwind v4 bootstrap ensured; replaced '@apply max-w-6xl;' with 'max-width: 72rem;'."
echo "Next: restart dev server (Ctrl+C, then 'pnpm dev')."
