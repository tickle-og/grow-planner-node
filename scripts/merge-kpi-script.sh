# scripts/merge-kpi-script.sh
#!/usr/bin/env bash
set -euo pipefail

f="src/routes/+page.svelte"
[[ -f "$f" ]] || { echo "Missing $f"; exit 1; }

cp -n "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"

# 1) Extract the KPI <script>…</script> following our marker and remove it from the file
kpi_js="$(awk '
  BEGIN{grab=0;inside=0}
  /<!--[[:space:]]*DASH-KPI-SCRIPT[[:space:]]*-->/ {grab=1; next}
  grab==1 && /<script([^>]*)>/ {inside=1; next}
  grab==1 && inside==1 && /<\/script>/ {grab=0; inside=0; next}
  grab==1 && inside==1 {print}
' "$f" | sed -E "/^[[:space:]]*import\\b/d")"

# If nothing was captured, bail (nothing to merge)
if [[ -z "${kpi_js//[[:space:]]/}" ]]; then
  echo "[note] No KPI script block found; nothing to merge."
  exit 0
fi

# Remove the entire KPI marker+script block from the file
tmp="$(mktemp)"
awk '
  BEGIN{skip=0;inblock=0}
  /<!--[[:space:]]*DASH-KPI-SCRIPT[[:space:]]*-->/ {skip=1; next}
  skip==1 && /<script([^>]*)>/ {inblock=1; next}
  skip==1 && inblock==1 && /<\/script>/ {skip=0; inblock=0; next}
  skip==1 {next}
  {print}
' "$f" > "$tmp"
mv "$tmp" "$f"

# 2) Splice KPI JS before the FIRST closing </script> (the top instance script)
tmp="$(mktemp)"
awk -v payload="$kpi_js" '
  BEGIN{done=0}
  {
    if(done==0 && /<\/script>/){
      print "  // --- merged from DASH-KPI-SCRIPT ---"
      n = split(payload, lines, "\n")
      for(i=1;i<=n;i++) print lines[i]
      print "  // --- end merged KPI ---"
      done=1
    }
    print
  }
' "$f" > "$tmp"
mv "$tmp" "$f"

# 3) Ensure onMount import exists once
if ! grep -qE 'import[[:space:]]*\{[^}]*onMount[^}]*\}[[:space:]]*from[[:space:]]*[\"\x27]svelte[\"\x27]' "$f"; then
  tmp="$(mktemp)"
  awk '
    BEGIN{added=0}
    {
      print
      if(added==0 && $0 ~ /<script([^>]*)>/){
        print "  import { onMount } from '\''svelte'\'';"
        added=1
      }
    }
  ' "$f" > "$tmp"
  mv "$tmp" "$f"
fi

echo "[ok] Merged KPI script into top-level <script> and normalized imports in $f"
