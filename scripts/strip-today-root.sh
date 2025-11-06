#!/usr/bin/env bash
set -euo pipefail

FILE="src/routes/+page.svelte"
[ -f "$FILE" ] || { echo "Missing $FILE"; exit 1; }

# Backup
TS="$(date +%Y%m%d-%H%M%S)"
cp -p "$FILE" "$FILE.bak.$TS"
echo "[backup] $FILE.bak.$TS"

# Remove any :root { ... } blocks ONLY inside <style>…</style>
awk '
BEGIN{ inStyle=0; del=0; depth=0 }
{
  # enter/exit <style> context
  if ($0 ~ /<style(\b|>)/) inStyle=1
  if ($0 ~ /<\/style>/) endStyleLine=1; else endStyleLine=0

  if (inStyle) {
    if (!del && $0 ~ /^[[:space:]]*:root[^{]*\{/) {
      # start deleting this :root block
      del=1
      # initialize brace depth from this line
      line=$0
      nopen=gsub(/\{/,"{", line)
      nclose=gsub(/\}/,"}", line)
      depth=nopen - nclose
      if (depth<=0) { del=0; depth=0 }  # one-line block case
      next
    } else if (del) {
      # continue skipping until braces balance back to zero
      line=$0
      nopen=gsub(/\{/,"{", line)
      nclose=gsub(/\}/,"}", line)
      depth+= (nopen - nclose)
      if (depth<=0) { del=0; depth=0 }
      next
    }
  }

  print

  if (endStyleLine) inStyle=0
}
' "$FILE" > "$FILE.tmp"

mv "$FILE.tmp" "$FILE"
echo "[ok] removed local :root block(s) from Today."
echo "Next: pnpm dev  # then verify styling uses global tokens"
