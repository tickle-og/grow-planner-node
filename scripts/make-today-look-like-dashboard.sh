# scripts/make-today-look-like-dashboard.sh
#!/usr/bin/env bash
set -euo pipefail

f="src/routes/+page.svelte"
[[ -f "$f" ]] || { echo "Missing $f"; exit 1; }

cp -n "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)"

# Skip if already added
if grep -q '<!-- DASH-KPI-BEGIN -->' "$f"; then
  echo "[dash] KPI block already present — skipping insert."
else
  tmp="$(mktemp)"
  awk '
    BEGIN{ins=0}
    {
      print $0
      # Insert KPI grid after the “Snapshot of your lab” line (keeps layout intact)
      if (!ins && $0 ~ /Snapshot of your lab/) {
        print "    <!-- DASH-KPI-BEGIN -->"
        print "    <section class=\x22kpi-grid\x22 aria-label=\x22Status overview\x22>"
        print "      <div class=\x22kpi-card kpi-pending\x22>"
        print "        <div class=\x22kpi-label\x22>Pending</div>"
        print "        <div class=\x22kpi-value\x22>{counts?.pending ?? 0}</div>"
        print "      </div>"
        print "      <div class=\x22kpi-card kpi-active\x22>"
        print "        <div class=\x22kpi-label\x22>Active</div>"
        print "        <div class=\x22kpi-value\x22>{counts?.active ?? 0}</div>"
        print "      </div>"
        print "      <div class=\x22kpi-card kpi-completed\x22>"
        print "        <div class=\x22kpi-label\x22>Completed</div>"
        print "        <div class=\x22kpi-value\x22>{counts?.completed ?? 0}</div>"
        print "      </div>"
        print "      <div class=\x22kpi-card kpi-failed\x22>"
        print "        <div class=\x22kpi-label\x22>Failed</div>"
        print "        <div class=\x22kpi-value\x22>{counts?.failed ?? 0}</div>"
        print "      </div>"
        print "    </section>"
        print "    <!-- DASH-KPI-END -->"
        ins=1
      }
    }' "$f" > "$tmp"
  mv "$tmp" "$f"
  echo "[dash] Inserted KPI grid."
fi

# Add a tiny script block to fetch counts on mount (safe even if you already fetch elsewhere)
if ! grep -q '<!-- DASH-KPI-SCRIPT -->' "$f"; then
cat >> "$f" <<'SVELTE'
<!-- DASH-KPI-SCRIPT -->
<script>
  import { onMount } from 'svelte';
  // Safe default to avoid SSR hiccups
  let counts = {};
  onMount(async () => {
    try {
      const res = await fetch('/api/dashboard/status-counts', { cache: 'no-store' });
      if (res.ok) {
        const data = await res.json();
        // Normalize to numbers if route changes
        counts = {
          pending: Number(data?.pending ?? 0),
          active: Number(data?.active ?? 0),
          completed: Number(data?.completed ?? 0),
          failed: Number(data?.failed ?? 0)
        };
      }
    } catch { /* stay quiet on dashboards */ }
  });
</script>
SVELTE
  echo "[dash] Added onMount counts fetch."
fi

# Add dashboard CSS (contrast + cards + KPI styling). Pure CSS; doesn’t fight Tailwind if you use it later.
if ! grep -q '/* DASH-KPI-STYLES */' "$f"; then
cat >> "$f" <<'CSS'
<style>
  /* DASH-KPI-STYLES */
  :root{
    --ink-strong:#0f172a;   /* slate-900 */
    --ink:#111827;          /* gray-900 */
    --ink-muted:#374151;    /* gray-700 */
    --muted:#4b5563;        /* gray-600 */
    --card:#ffffff;         /* white card */
    --card-border:#e5e7eb;  /* gray-200 */
    --kpi-pending:#eef2ff;  /* indigo-50 */
    --kpi-active:#ecfdf5;   /* emerald-50 */
    --kpi-completed:#f0fdf4;/* green-50 */
    --kpi-failed:#fef2f2;   /* rose-50 */
    --kpi-ink:#0b0f14;
  }

  /* Container cards */
  .today-card{
    background:var(--card);
    border:1px solid var(--card-border);
    border-radius:14px;
    padding:14px 16px;
    box-shadow:0 1px 2px rgba(0,0,0,.04);
  }
  /* Section titles: dark, legible */
  .today-section-title{
    color:var(--ink-strong);
    font-weight:700;
    letter-spacing:.01em;
  }
  /* Kill the washed-out look inside cards */
  .today-card :is(p,li,small,span){
    color:var(--ink);
  }
  .today-card .muted,
  .today-card :is(.text-muted-foreground,.opacity-60,.opacity-70,.text-gray-500,.text-gray-600,.text-slate-500,.text-slate-600){
    color:var(--muted) !important;
    opacity:1 !important;
  }

  /* KPI row */
  .kpi-grid{
    display:grid;
    grid-template-columns:repeat(4,minmax(0,1fr));
    gap:12px;
    margin:12px 0 18px;
  }
  @media (max-width: 900px){
    .kpi-grid{ grid-template-columns:repeat(2,minmax(0,1fr)); }
  }
  @media (max-width: 520px){
    .kpi-grid{ grid-template-columns:1fr; }
  }

  .kpi-card{
    border-radius:14px;
    padding:12px 14px;
    border:1px solid var(--card-border);
    background:var(--card);
  }
  .kpi-label{
    font-size:12px;
    color:var(--muted);
    letter-spacing:.04em;
    text-transform:uppercase;
  }
  .kpi-value{
    color:var(--ink-strong);
    font-size:28px;
    font-weight:800;
    line-height:1;
    margin-top:6px;
  }

  /* Subtle tinted variants for quick scanning */
  .kpi-pending{ background:var(--kpi-pending); }
  .kpi-active{ background:var(--kpi-active); }
  .kpi-completed{ background:var(--kpi-completed); }
  .kpi-failed{ background:var(--kpi-failed); }

  /* Optional: add a tidy grid to your existing sections (if you wrap them in .today-grid) */
  .today-grid{
    display:grid;
    grid-template-columns:repeat(12,minmax(0,1fr));
    gap:14px;
  }
  /* Example slots if you want a 12-col layout:
     .span-4 { grid-column: span 4; } .span-6 { grid-column: span 6; } etc. */
  .span-4{ grid-column: span 4; }
  .span-6{ grid-column: span 6; }
  .span-8{ grid-column: span 8; }
  .span-12{ grid-column: 1 / -1; }

  @media (max-width: 1100px){
    .span-6,.span-8{ grid-column: span 12; }
  }
</style>
CSS
  echo "[dash] Appended dashboard CSS."
fi

echo "[dash] Done. Restart dev server and review the Today page."
