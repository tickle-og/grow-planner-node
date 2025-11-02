# scripts/fix-today-kpi-structure.sh
#!/usr/bin/env bash
set -euo pipefail

f="src/routes/+page.svelte"
[[ -f "$f" ]] || { echo "Missing $f"; exit 1; }

cp -n "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"

tmp="$(mktemp)"
awk '
  BEGIN {
    insertedCloseP = 0
    removeOnePAfterKpi = 0
  }
  {
    # 1) Ensure the Snapshot paragraph closes BEFORE the KPI section
    if (!insertedCloseP && $0 ~ /Snapshot of your lab/) {
      print $0
      print "    </p>"
      insertedCloseP = 1
      next
    }

    # 2) After KPI ends and before </header>, drop the first stray </p>
    if ($0 ~ /<!-- DASH-KPI-END -->/) {
      removeOnePAfterKpi = 1
    }

    if (removeOnePAfterKpi == 1 && $0 ~ /^[[:space:]]*<\/p>[[:space:]]*$/) {
      # skip this single orphan </p>
      removeOnePAfterKpi = 2
      next
    }

    if ($0 ~ /<\/header>/) {
      removeOnePAfterKpi = 0
    }

    print $0
  }
' "$f" > "$tmp"

mv "$tmp" "$f"

echo "[ok] Fixed paragraph/KPI structure in $f"
echo "Next: pnpm dev"
