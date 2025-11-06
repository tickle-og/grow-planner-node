#!/usr/bin/env bash
set -euo pipefail

root="src/routes"

# --- 1) Reports page: +page.svelte ---
mkdir -p "$root/reports"
if [ ! -f "$root/reports/+page.svelte" ]; then
  cat > "$root/reports/+page.svelte" <<'SVELTE'
<script lang="ts">
  export let data: {
    locationId: number;
    lowStock: { ok: boolean; rows: any[] } | { message: string };
    recentYields: {
      ok?: boolean;
      locationId?: number;
      days?: number;
      totals?: { wetWeightG: number; dryWeightG: number };
      rows?: any[];
      message?: string;
    };
    shelfUtil: { ok: boolean; rows: any[] } | { message: string };
    upcomingTasks: { ok: boolean; items: any[] } | { message: string };
  };
</script>

<section class="mx-auto max-w-6xl px-4 py-8 space-y-6">
  <header class="space-y-1">
    <h1 class="text-3xl font-extrabold tracking-tight text-slate-900">Reports</h1>
    <p class="text-slate-700">Deep-dive: stock, yields, shelf utilization, and upcoming tasks.</p>
  </header>

  <div class="grid gap-6 lg:grid-cols-2">
    <!-- Low Stock -->
    <div class="card">
      <h2 class="card-title">Low Stock</h2>
      {#if 'rows' in data.lowStock && Array.isArray(data.lowStock.rows) && data.lowStock.rows.length}
        <ul class="list">
          {#each (data.lowStock as any).rows as row}
            <li class="li">
              <span class="name">{row.name ?? row.item ?? 'Item'}</span>
              <span class="muted">qty: {row.qty ?? row.quantity ?? '—'}</span>
            </li>
          {/each}
        </ul>
      {:else}
        <div class="muted">No low-stock items.</div>
      {/if}
    </div>

    <!-- Recent Yields -->
    <div class="card">
      <h2 class="card-title">Recent Yields</h2>
      {#if data.recentYields?.rows?.length}
        <div class="totals">
          <div>Wet: <strong>{data.recentYields.totals?.wetWeightG ?? 0} g</strong></div>
          <div>Dry: <strong>{data.recentYields.totals?.dryWeightG ?? 0} g</strong></div>
        </div>
        <ul class="list">
          {#each data.recentYields.rows as r}
            <li class="li">
              <span class="name">{r.batchCode ?? 'Batch'}</span>
              <span class="muted">{r.harvestedAt ?? r.ts ?? ''}</span>
            </li>
          {/each}
        </ul>
      {:else}
        <div class="muted">No yields in the selected window.</div>
      {/if}
    </div>

    <!-- Shelf Utilization -->
    <div class="card lg:col-span-2">
      <h2 class="card-title">Shelf Utilization</h2>
      {#if 'rows' in data.shelfUtil && Array.isArray(data.shelfUtil.rows) && data.shelfUtil.rows.length}
        <div class="grid grid-cols-2 md:grid-cols-3 gap-3">
          {#each (data.shelfUtil as any).rows as s}
            <div class="pill">
              <div class="name">{s.shelf ?? s.name ?? 'Shelf'}</div>
              <div class="muted">used {s.used ?? 0} / cap {s.capacity ?? 0}</div>
            </div>
          {/each}
        </div>
      {:else}
        <div class="muted">No shelf data yet.</div>
      {/if}
    </div>

    <!-- Upcoming Tasks -->
    <div class="card lg:col-span-2">
      <h2 class="card-title">Upcoming Tasks</h2>
      {#if 'items' in data.upcomingTasks && Array.isArray((data.upcomingTasks as any).items) && (data.upcomingTasks as any).items.length}
        <ul class="list">
          {#each (data.upcomingTasks as any).items as t}
            <li class="li">
              <span class="name">{t.title ?? t.type ?? 'Task'}</span>
              <span class="muted">{t.dueAt ?? t.when ?? ''}</span>
            </li>
          {/each}
        </ul>
      {:else}
        <div class="muted">No upcoming tasks.</div>
      {/if}
    </div>
  </div>
</section>

<style>
  .card { @apply bg-white rounded-xl border border-slate-200 shadow-sm p-4; }
  .card-title { @apply text-lg font-semibold text-slate-900 mb-2; }
  .list { @apply divide-y divide-slate-200; }
  .li { @apply flex items-center justify-between py-2; }
  .name { @apply text-slate-900; }
  .muted { @apply text-slate-600 text-sm; }
  .pill { @apply bg-slate-50 border border-slate-200 rounded-lg p-3; }
  .totals { @apply flex gap-6 text-sm text-slate-700 mb-2; }
</style>
SVELTE
  echo "[ok] wrote $root/reports/+page.svelte"
else
  echo "[skip] $root/reports/+page.svelte exists"
fi

# --- 2) Reports loader: +page.server.ts ---
cat > "$root/reports/+page.server.ts" <<'TS'
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, url }) => {
  const locationId = Number(url.searchParams.get('location_id') ?? 1);
  const qs = (p: string) => `${p}?location_id=${locationId}`;

  const [lowStockRes, yieldsRes, utilRes, tasksRes] = await Promise.all([
    fetch(qs('/api/dashboard/low-stock')),
    fetch(qs('/api/dashboard/recent-yields')),
    fetch(qs('/api/dashboard/shelf-util')),
    fetch(qs('/api/dashboard/next-actions'))
  ]);

  const lowStock = lowStockRes.ok ? await lowStockRes.json() : { message: 'Internal Error' };
  const recentYields = yieldsRes.ok ? await yieldsRes.json() : { message: 'Internal Error' };
  const shelfUtil = utilRes.ok ? await utilRes.json() : { message: 'Internal Error' };
  const upcomingTasks = tasksRes.ok ? await tasksRes.json() : { message: 'Internal Error' };

  return { locationId, lowStock, recentYields, shelfUtil, upcomingTasks };
};
TS
echo "[ok] wrote $root/reports/+page.server.ts"

# --- 3) Stub shelf-util endpoint if missing ---
mkdir -p "$root/api/dashboard/shelf-util"
if [ ! -f "$root/api/dashboard/shelf-util/+server.ts" ]; then
  cat > "$root/api/dashboard/shelf-util/+server.ts" <<'TS'
import type { RequestHandler } from './$types';
import { json, jsonError } from '$lib/utils/json';
import { getLocationIdOrThrow } from '../_util';

export const GET: RequestHandler = async ({ url }) => {
  try {
    const locationId = getLocationIdOrThrow(url);
    // TODO: real computation once shelves are modeled. For now, return empty structure.
    return json(200, { ok: true, locationId, rows: [] });
  } catch (e) {
    console.error('shelf-util error', e);
    return jsonError(500);
  }
};
TS
  echo "[ok] created stub $root/api/dashboard/shelf-util/+server.ts"
else
  echo "[skip] $root/api/dashboard/shelf-util/+server.ts exists"
fi

# --- 4) Trim Today loader to only light calls ---
if [ -f "$root/+page.server.ts" ]; then
  cp -n "$root/+page.server.ts" "$root/+page.server.ts.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
fi

cat > "$root/+page.server.ts" <<'TS'
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, url }) => {
  const locationId = Number(url.searchParams.get('location_id') ?? 1);
  const qs = (p: string) => `${p}?location_id=${locationId}`;

  const [statusRes, nextRes] = await Promise.all([
    fetch(qs('/api/dashboard/status-counts')),
    fetch(qs('/api/dashboard/next-actions'))
  ]);

  const statusCounts = statusRes.ok
    ? await statusRes.json()
    : { pending: 0, active: 0, completed: 0, failed: 0, total: 0 };

  const nextActions = nextRes.ok ? await nextRes.json() : { ok: true, items: [] };

  return { locationId, statusCounts, nextActions };
};
TS
echo "[ok] rewrote $root/+page.server.ts (lightweight Today loader)"

echo
echo "Next:"
echo "  1) pnpm dev"
echo "  2) Visit /reports (deep-dive sections) and / (Today stays lean)."
echo "  3) If any section shows 'Internal Error', check the server console for the specific endpoint."
