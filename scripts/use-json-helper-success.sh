#!/usr/bin/env bash
set -euo pipefail

# Endpoints to normalize (success paths only)
FILES=(
  "src/routes/api/catalog/container-presets/+server.ts"
  "src/routes/api/catalog/jar-variants/+server.ts"
  "src/routes/api/dashboard/active-grows/+server.ts"
  "src/routes/api/dashboard/activity/+server.ts"
  "src/routes/api/dashboard/low-stock/+server.ts"
  "src/routes/api/dashboard/next-actions/+server.ts"
  "src/routes/api/dashboard/recent-notes/+server.ts"
  "src/routes/api/dashboard/recent-yields/+server.ts"
  "src/routes/api/dashboard/status-counts/+server.ts"
  "src/routes/api/dev/seed/default-location/+server.ts"
  "src/routes/api/dev/seed/presets/+server.ts"
  "src/routes/api/locations/[id]/+server.ts"
  "src/routes/api/locations/[id]/shelves/+server.ts"
)

CATALOG_FILES=(
  "src/routes/api/catalog/container-presets/+server.ts"
  "src/routes/api/catalog/jar-variants/+server.ts"
)

ensure_import_json() {
  local f="$1"
  # If file doesn't import json/jsonError yet, add them (idempotent).
  if ! rg -q "\$lib/server/http" "$f"; then
    perl -0777 -pe '
      if ($ARGV eq $ENV{TGT}) {
        if (s/\A((?:\s*import[^\n]*\n)+)/$1 . "import { json, jsonError } from '\''\$lib\/server\/http'\'';\n"/e) {
          $_
        } else {
          $_ = "import { json, jsonError } from '\''\$lib\/server\/http'\'';\n\n" . $_;
        }
      }
    ' -i -- "$f"
  else
    # If it imports the module but not `json`, add it.
    if rg -q "from '\$lib/server/http'" "$f" && ! rg -q "import\s*\{\s*[^}]*\bjson\b" "$f"; then
      perl -0777 -pe '
        s/import\s*\{\s*([^}]*)\}\s*from\s*'\''\$lib\/server\/http'\'';/
          my $list = $1;
          $list =~ s/^\s+|\s+$//g;
          if ($list =~ /\bjsonError\b/ && $list !~ /\bjson\b/) {
            "import { json, $list } from '\''\$lib\/server\/http'\'';"
          } elsif ($list !~ /\bjson\b/) {
            "import { json, $list } from '\''\$lib\/server\/http'\'';"
          } else {
            "import { $list } from '\''\$lib\/server\/http'\'';"
          }
        /egs
      ' -i -- "$f"
    fi
  fi
}

convert_success_to_json() {
  local f="$1"

  # Skip anything that is clearly an error response (we already standardized those)
  # Replace common 200 JSON patterns with json(data, 200)
  perl -0777 -pe '
    # return new Response(JSON.stringify(X), { status: 200, ... })
    s@return\s+new\s+Response\(\s*JSON\.stringify\(\s*([^()]+?)\s*\)\s*,\s*\{\s*status\s*:\s*200\b[^}]*\}\s*\)@return json($1, 200)@gs;

    # return new Response(JSON.stringify(X), { headers: {...} })  (assume 200)
    s@return\s+new\s+Response\(\s*JSON\.stringify\(\s*([^()]+?)\s*\)\s*,\s*\{\s*headers\s*:\s*\{[^}]*\}\s*\}\s*\)@return json($1, 200)@gs;

    # return new Response(JSON.stringify(X)) (implicit 200)
    s@return\s+new\s+Response\(\s*JSON\.stringify\(\s*([^()]+?)\s*\)\s*\)@return json($1, 200)@gs;

    # Normalize trivial 201 creations: return new Response(JSON.stringify(X), { status: 201 })
    s@return\s+new\s+Response\(\s*JSON\.stringify\(\s*([^()]+?)\s*\)\s*,\s*\{\s*status\s*:\s*201\b[^}]*\}\s*\)@return json($1, 201)@gs;
  ' -i -- "$f"
}

apply_catalog_cache_headers() {
  local f="$1"
  # Ensure catalog GETs use a short public cache. Convert json(..., 200) -> json(..., 200, 'public, max-age=60')
  perl -0777 -pe "
    s/return\s+json\(\s*([^,]+)\s*,\s*200\s*\)/return json(\1, 200, 'public, max-age=60')/g;
  " -i -- "$f"
}

changed=0
for f in "${FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "[skip] $f (missing)"
    continue
  fi

  ensure_import_json "$f"
  convert_success_to_json "$f"

  # If it's a catalog file, add cache headers
  for cf in "${CATALOG_FILES[@]}"; do
    if [[ "$f" == "$cf" ]]; then
      apply_catalog_cache_headers "$f"
    fi
  done

  if ! git diff --quiet -- "$f"; then
    echo "[fix] $f"
    changed=$((changed+1))
  else
    echo "[ok ] $f (no success-path changes)"
  fi
done

echo
echo "[scan] Look for leftover raw Response(JSON.stringify(...)) in target files (should be empty):"
rg -n "new\s+Response\s*\(\s*JSON\.stringify" "${FILES[@]}" || true

echo
if [[ $changed -gt 0 ]]; then
  echo "[✓] Success responses normalized in $changed file(s). Review with 'git diff', then:"
  echo "    git checkout -b chore/api-json-success"
  echo "    git add -A && git commit -m 'chore(api): use json() on success; add cache headers to catalog endpoints'"
  echo "    git push -u origin chore/api-json-success"
else
  echo "[=] Already standardized."
fi
