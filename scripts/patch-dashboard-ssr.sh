#!/usr/bin/env bash
set -euo pipefail

FILE="src/routes/+page.svelte"
if [[ ! -f "$FILE" ]]; then
  echo "❌ $FILE not found. Run from repo root."
  exit 1
fi

ts="$(date +%Y%m%d-%H%M%S)"
cp -v "$FILE" "$FILE.bak.$ts"

# 1) Ensure we import the browser flag
if ! grep -q "import { browser } from '\$app/environment';" "$FILE"; then
  # Insert right after <script lang="ts">
  perl -0777 -pe 's|<script lang="ts">|<script lang="ts">\n  import { browser } from '\$app/environment';|s' -i "$FILE"
  echo "✅ Added import { browser } from '\$app/environment';"
else
  echo "ℹ️ browser import already present"
fi

# 2) Guard reactive lazy-fetchers so they only run in the browser
perl -0777 -pe '
  s/\$:\s*if\s*\(\s*expanded\.active\s*\)/$: if (browser && expanded.active)/g;
  s/\$:\s*if\s*\(\s*expanded\.lowStock\s*\)/$: if (browser && expanded.lowStock)/g;
  s/\$:\s*if\s*\(\s*expanded\.yields\s*\)/$: if (browser && expanded.yields)/g;
  s/\$:\s*if\s*\(\s*expanded\.tasks\s*\)/$: if (browser && expanded.tasks)/g;
  s/\$:\s*if\s*\(\s*expanded\.activity\s*\)/$: if (browser && expanded.activity)/g;
  s/\$:\s*if\s*\(\s*expanded\.notes\s*\)/$: if (browser && expanded.notes)/g;
  s/\$:\s*if\s*\(\s*expanded\.shelfAssets\s*\)/$: if (browser && expanded.shelfAssets)/g;
' -i "$FILE"
echo "✅ Added SSR guards to reactive loaders"

# 3) Make the header 'Sort' label a <span> to avoid a11y warnings
#    (only replaces labels whose text is exactly 'Sort')
perl -0777 -pe '
  s{<label(\s+class="([^"]*)")?\s*>\s*Sort\s*</label>}{
    my $cls = defined $2 ? "$2 " : "";
    "<span class=\"${cls}opacity-70\">Sort</span>"
  }ge;
' -i "$FILE"
echo "✅ Replaced header Sort <label> with <span>"

# 4) (Optional) Start panels collapsed by default to avoid eager loads
perl -0777 -pe '
  s/notes:\s*true/notes: false/g;
  s/shelf:\s*true/shelf: false/g;
' -i "$FILE" || true
echo "✅ Set notes/shelf expanded = false (idempotent)"

echo "✨ Patch applied. Backup at $FILE.bak.$ts"
