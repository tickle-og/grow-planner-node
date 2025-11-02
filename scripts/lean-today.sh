#!/usr/bin/env bash
set -euo pipefail

file="src/routes/+page.svelte"
bak="${file}.bak.$(date +%Y%m%d-%H%M%S)"

if [[ ! -f "$file" ]]; then
  echo "[err] $file not found"
  exit 1
fi

cp -n "$file" "$bak" || true
echo "[backup] $bak"

# Remove heavy Today cards by heading.
# We match each <div class="today-card"> whose section-title equals a target label.
# Case-insensitive, non-greedy, multiline.
perl -0777 -i -pe '
  sub zap {
    my($s,$label)=@_;
    $s =~ s{
      <div\s+class="today-card\b[^>]*>      # card open
      (?:(?!<div\s+class="today-card\b).)*? # anything, not crossing into a nested card
      <h2\s+class="section-title\b[^>]*">\s*$label\s*</h2>
      (?:(?!<div\s+class="today-card\b).)*? # rest of that card block
      </div>                                # card close
    }{<!-- removed: $label -->}gisx;
    return $s;
  }
  $_ = zap($_, "Status");            # duplicate chip card
  $_ = zap($_, "Low stock");
  $_ = zap($_, "Active grows");
  $_ = zap($_, "Recent yields");
  $_ = zap($_, "Upcoming Tasks");
  $_ = zap($_, "This Week");
  $_ = zap($_, "Shelf Utilization");
  $_ = zap($_, "Recent Activity");
  $_ = zap($_, "Recent Notes");
  END{ }
' "$file"

# Strengthen dark theme contrast by injecting CSS into the existing <style> block if present.
insert_css='
/* === TODAY DARK THEME OVERRIDES === */
.today-theme .section-title{color:#E5E7EB !important;}
.today-theme .kpi-card{background:#0f172a;border:1px solid #1f2937;}
.today-theme .kpi-label{color:#E5E7EB !important;}
.today-theme .kpi-value{color:#F8FAFC !important;}
.today-theme .today-card{background:#0b1020;border:1px solid #1f2937;}
.today-theme .today-card .text-slate-900,
.today-theme .today-card .text-slate-700{color:#E5E7EB !important;}
.today-theme .today-card .muted,
.today-theme .today-card .text-slate-500,
.today-theme .today-card .text-slate-600{color:#9CA3AF !important;}
/* lift code samples for visibility */
.today-theme pre, .today-theme code{background:#0b1220;color:#e5e7eb;border-color:#1f2a3a;}
/* end overrides */
'

if grep -q '<style>' "$file"; then
  # insert before the FIRST closing </style>
  perl -0777 -i -pe "s|</style>|${insert_css}\n</style>|s" "$file"
  echo "[style] injected dark-theme overrides into existing <style>"
else
  printf "\n<style>\n%s\n</style>\n" "$insert_css" >> "$file"
  echo "[style] appended new <style> with dark-theme overrides"
fi

echo "[ok] Today trimmed and contrast improved."
echo "Next:"
echo "  1) pnpm dev"
echo "  2) Refresh /. The KPI band should remain; the heavy cards should be gone."
echo "  3) Use /reports for Low Stock, Yields, Utilization, and Upcoming Tasks."
