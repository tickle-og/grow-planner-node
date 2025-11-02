# scripts/merge-style-tags.sh
#!/usr/bin/env bash
set -euo pipefail

f="src/routes/+page.svelte"
[[ -f "$f" ]] || { echo "Missing $f"; exit 1; }

cp -n "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"

perl -0777 -e '
  my $s = do { local $/; <> };

  # Grab the first <style ...> ... </style>
  my ($first_open, $first_css) = ($s =~ m{(<style\b[^>]*>)(.*?)(</style>)}s);
  if (!$first_open) { print $s; exit 0; } # nothing to do

  # Collect ALL style contents (first + subsequent)
  my @all = ($s =~ m{<style\b[^>]*>(.*?)</style>}sg);
  my @others = @all > 1 ? @all[1..$#all] : ();

  # Replace the FIRST style block with a placeholder
  $s =~ s{<style\b[^>]*>.*?</style>}{__STYLE_PLACEHOLDER__}s;

  # Remove any remaining style blocks
  $s =~ s{<style\b[^>]*>.*?</style>}{}sg;

  # Build merged CSS
  my $merged_css = $first_css;
  if (@others) {
    $merged_css .= "\n/* ---- merged from additional <style> tags ---- */\n"
                 . join("\n\n", @others) . "\n";
  }

  # Put back a single style block with original first tag
  $s =~ s{__STYLE_PLACEHOLDER__}{$first_open$merged_css</style>}s;

  print $s;
' "$f" > "$f.tmp" && mv "$f.tmp" "$f"

echo "[ok] Merged duplicate <style> tags in $f"
