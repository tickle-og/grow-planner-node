# scripts/dedupe-onmount-import.sh
#!/usr/bin/env bash
set -euo pipefail

f="src/routes/+page.svelte"
[[ -f "$f" ]] || { echo "Missing $f"; exit 1; }

cp -n "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"

awk '
  BEGIN { keep=1 }
  {
    line=$0
    # match: import { ... onMount ... } from "svelte";
    if (line ~ /^[[:space:]]*import[[:space:]]*\{[^}]*onMount[^}]*\}[[:space:]]*from[[:space:]]*["'\''"]svelte["'\''"][[:space:]]*;?[[:space:]]*$/) {
      if (keep==1) { print; keep=0 }  # keep first
      next                              # drop any subsequent
    }
    print
  }
' "$f" > "$f.tmp" && mv "$f.tmp" "$f"

echo "[ok] Deduped onMount import in $f"
