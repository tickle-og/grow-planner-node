#!/usr/bin/env bash
set -euo pipefail

FILE="src/routes/+page.svelte"

if [[ ! -f "$FILE" ]]; then
  echo "[err] $FILE not found. Run from repo root."
  exit 1
fi

# backup
ts="$(date +%Y%m%d-%H%M%S)"
cp -n "$FILE" "$FILE.bak.$ts"
echo "[backup] $FILE.bak.$ts"

# Inject `today-card` on the first <main> (preferred), else the first <section>.
# - If a class= exists, append " today-card".
# - If not, create class="today-card".
# - If already present, do nothing.
perl -0777 -i -pe '
  my $src = $_;
  if (index($src, "today-card") == -1) {
    # Try <main class="...">
    if ($src =~ s|<main(\s+[^>]*?)class="([^"]*)"([^>]*)>|<main$1class="$2 today-card"$3>|s) {
      $_ = $src; exit;
    }
    # Try <main> with no class
    if ($src =~ s|<main([^>]*)>|<main class="today-card"$1>|s) {
      $_ = $src; exit;
    }
    # Fallback: first <section class="...">
    if ($src =~ s|<section(\s+[^>]*?)class="([^"]*)"([^>]*)>|<section$1class="$2 today-card"$3>|s) {
      $_ = $src; exit;
    }
    # Fallback: first <section> with no class
    if ($src =~ s|<section([^>]*)>|<section class="today-card"$1>|s) {
      $_ = $src; exit;
    }
  }
' "$FILE"

# Show what changed (grepped)
if rg -n "today-card" "$FILE" >/dev/null 2>&1; then
  echo "[ok] Inserted .today-card wrapper:"
  rg -n "^\s*<(main|section)[^>]*today-card" "$FILE" || true
else
  echo "[note] .today-card already present or injection not needed."
fi

echo "[done] Restart dev server if running: pnpm dev"
