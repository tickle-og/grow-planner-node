#!/usr/bin/env bash
set -euo pipefail

FILE="src/routes/+page.svelte"
[[ -f "$FILE" ]] || { echo "Error: $FILE not found. Run from project root."; exit 1; }

# --- 0) Timestamped backup (no cp -n portability issues) ---
ts="$(date +%Y%m%d-%H%M%S)"
cp "$FILE" "$FILE.bak.$ts"
echo "[backup] $FILE.bak.$ts"

#############################################
# 1) Inject <script> calendar helpers/state #
#############################################
perl -0777 -i -pe '
  BEGIN {
    $helpers = q{
  // [CAL-HELPERS-BEGIN]
  // --- Today page calendar view state & helpers ---
  type CalView = "week" | "14" | "all";
  let calView: CalView = "week";

  function calSafeDate(v: any): Date | null {
    if (!v && v !== 0) return null;
    const d = new Date(v);
    return isNaN(d.getTime()) ? null : d;
  }
  function calTaskDueAt(t: any): Date | null {
    for (const k of ["dueAt","due_at","due","dueDate","due_date","scheduledAt","scheduled_at"]) {
      const d = calSafeDate(t?.[k]);
      if (d) return d;
    }
    return null;
  }
  function calSortBySoonest(a: any, b: any) {
    const da = calTaskDueAt(a), db = calTaskDueAt(b);
    if (da && db) return da.getTime() - db.getTime();
    if (da && !db) return -1;
    if (!da && db) return 1;
    return 0;
  }
  function calGroupByDay(ts: any[]) {
    const map = new Map<string, any[]>();
    for (const t of ts) {
      const d = calTaskDueAt(t);
      const key = d ? new Date(d.getFullYear(), d.getMonth(), d.getDate()).toISOString().slice(0,10) : "unscheduled";
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push(t);
    }
    return map;
  }
  function calNextNDates(n = 7) {
    const out: string[] = [];
    const now = new Date();
    for (let i = 0; i < n; i++) {
      const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i);
      out.push(d.toISOString().slice(0,10));
    }
    return out;
  }
  function calDaysForRange(view: CalView, groups: Map<string, any[]>) {
    if (view === "week") return calNextNDates(7);
    if (view === "14") return calNextNDates(14);
    const keys = [...groups.keys()].filter(k => k !== "unscheduled")
      .sort((a,b) => new Date(a).getTime() - new Date(b).getTime());
    return keys.length ? keys : calNextNDates(7);
  }
  function calFmt(iso: string) {
    const d = new Date(iso);
    return d.toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" });
  }

  // Assumes Today page provides nextActions[] already
  $: calTasks  = (nextActions ?? []).slice().sort(calSortBySoonest);
  $: calGroups = calGroupByDay(calTasks);
  $: calDays   = calDaysForRange(calView, calGroups);
  // [CAL-HELPERS-END]
};
  }
  # avoid regex on the marker; use index()
  if (index($_, "[CAL-HELPERS-BEGIN]") == -1 && $_ =~ /<script[^>]*lang="ts"[^>]*>.*?<\/script>/s) {
    s#(<script[^>]*lang="ts"[^>]*>)(.*?)</script>#$1$2\n$helpers\n</script>#s;
    print STDERR "[inject] script helpers inserted\n";
  }
' "$FILE"

#############################################
# 2) Inject calendar filter + grid markup   #
#############################################
perl -0777 -i -pe '
  BEGIN {
    $markup = q{
<!-- [CAL-MARKUP-BEGIN] -->
<div class="today-cal-header">
  <h3 class="today-section-title">Upcoming Tasks</h3>
  <div class="filter-row" role="tablist" aria-label="Calendar range">
    <button role="tab" aria-selected={calView === "week"} class="filter-btn" class:active={calView === "week"} on:click={() => (calView = "week")}>
      This week
    </button>
    <button role="tab" aria-selected={calView === "14"} class="filter-btn" class:active={calView === "14"} on:click={() => (calView = "14")}>
      Next 14 days
    </button>
    <button role="tab" aria-selected={calView === "all"} class="filter-btn" class:active={calView === "all"} on:click={() => (calView = "all")}>
      All
    </button>
  </div>
</div>

<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-3">
  {#each calDays as d}
    <div class="cal-cell">
      <div class="cal-date">{calFmt(d)}</div>
      <ul class="mt-2 space-y-1">
        {#each (calGroups.get(d) ?? []) as t}
          <li class="task-line">• {t.title ?? t.action ?? t.type ?? "Task"}</li>
        {/each}
        {#if (calGroups.get(d) ?? []).length === 0}
          <li class="task-empty">—</li>
        {/if}
      </ul>
    </div>
  {/each}
</div>

{#if calView === "all" && (calGroups.get("unscheduled") ?? []).length}
  <div class="unscheduled mt-4">
    <div class="unsched-title">Unscheduled</div>
    <ul class="mt-2 space-y-1">
      {#each calGroups.get("unscheduled") as t}
        <li class="task-line">• {t.title ?? t.action ?? t.type ?? "Task"}</li>
      {/each}
    </ul>
  </div>
{/if}
<!-- [CAL-MARKUP-END] -->
};
  }
  # idempotent: skip if marker exists
  if (index($_, "[CAL-MARKUP-BEGIN]") != -1) { next }
  # insert right after the Upcoming Tasks heading (first occurrence)
  if (s#(<h3[^>]*>[^<]*Upcoming Tasks[^<]*</h3>)#$1\n$markup#s) {
    print STDERR "[inject] today calendar markup inserted\n";
  }
' "$FILE"

#############################################
# 3) Add high-contrast styles               #
#############################################
perl -0777 -i -pe '
  BEGIN {
    $styles = q{
/* [CAL-STYLES-BEGIN] */
:root {
  --ink: #0b1220;
  --muted-ink: #374151;
  --line: #e5e7eb;
  --card: #ffffff;
}
.today-cal-header {
  display:flex; align-items:center; justify-content:space-between; gap:.75rem;
}
.today-section-title { color: var(--ink); font-weight: 800; }

.filter-row {
  display:inline-flex; gap:.4rem; padding:.25rem;
  border:1px solid var(--line);
  border-radius:.75rem; background:var(--card);
}
.filter-btn {
  appearance:none; border:0; padding:.35rem .7rem; border-radius:.55rem;
  font-weight:700; color:var(--ink); background:transparent; cursor:pointer;
}
.filter-btn:hover { background:#f1f5f9; }
.filter-btn.active { background:var(--ink); color:#fff; }

.cal-cell {
  background:var(--card); border:1px solid var(--line);
  border-radius:.5rem; padding:.6rem .7rem;
}
.cal-date { font-weight:800; color:var(--ink); }
.task-line { color:var(--ink); font-size:.95rem; }
.task-empty { color:var(--muted-ink); font-size:.9rem; }

.unscheduled {
  background:var(--card); border:1px solid var(--line);
  border-radius:.5rem; padding:.75rem .9rem;
}
.unsched-title { font-weight:800; color:var(--ink); }
/* [CAL-STYLES-END] */
};
  }
  if (index($_, "[CAL-STYLES-BEGIN]") != -1) { next }
  if (s#(<style[^>]*>)(.*?)(</style>)#$1$2\n$styles\n$3#s) {
    print STDERR "[inject] styles merged into existing <style>\n";
  } else {
    $_ .= "\n<style>\n$styles\n</style>\n";
    print STDERR "[inject] styles appended in new <style> block\n";
  }
' "$FILE"

############################################################
# 4) Escape the seed JSON braces in the code sample (Svelte)
############################################################
perl -0777 -i -pe '
  my $n = s/\{"owner_user_id":1,"name":"Default Lab","timezone":"America\/Denver"\}/&#123;"owner_user_id":1,"name":"Default Lab","timezone":"America\/Denver"&#125;/g;
  if ($n) { print STDERR "[fix] escaped braces in seed code sample ($n)\n"; }
' "$FILE"

echo "[done] Patched Today calendar filters + grid + styles into $FILE"
echo "Run: pnpm dev   # then refresh Today page"
