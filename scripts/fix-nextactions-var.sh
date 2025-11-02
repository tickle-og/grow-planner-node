# scripts/fix-nextactions-var.sh
#!/usr/bin/env bash
set -euo pipefail

FILE="src/routes/+page.svelte"
[[ -f "$FILE" ]] || { echo "Error: $FILE not found"; exit 1; }

ts="$(date +%Y%m%d-%H%M%S)"
cp "$FILE" "$FILE.bak.$ts"
echo "[backup] $FILE.bak.$ts"

# If 'let nextActions' is absent, add a safe default right after the opening TS script tag
perl -0777 -i -pe '
  if (index($_, "let nextActions") == -1) {
    s!(<script[^>]*lang="ts"[^>]*>)!$1\n// SSR-safe default so calendar helpers don\u2019t explode\nlet nextActions: any[] = [];\n!;
    print STDERR "[fix] inserted nextActions default\\n";
  } else {
    print STDERR "[ok ] nextActions already defined\\n";
  }
' "$FILE"

echo "[done] Try: pnpm dev  # then refresh Today"
