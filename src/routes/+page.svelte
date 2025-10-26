<!-- src/routes/+page.svelte -->
<script lang="ts">
  /** This page expects data from +page.server.ts which calls the dashboard APIs.
   *  Everything is defensive so missing endpoints won't crash the UI.
   */
  export let data: {
    locationId: number | null;
    statusCounts?: {
      locationId: number;
      total: number;
      breakdown: Record<string, number>;
      message?: string;
      detail?: string;
    };
    activeGrows?: { locationId: number; rows: any[]; message?: string; detail?: string };
    lowStock?: { locationId: number; rows: any[]; message?: string; detail?: string };
    recentYields?: {
      locationId: number;
      days: number;
      totals: { wetWeightG: number; dryWeightG: number };
      rows: any[];
      message?: string;
      detail?: string;
    };
    activity?: { locationId: number; days: number; count: number; items: any[]; message?: string; detail?: string };
    nextActions?: { locationId: number; count: number; actions: any[]; message?: string; detail?: string };
    shelfUtil?: {
      locationId: number;
      capacityCm2: number;
      usedCm2: number;
      percent: number;
      itemsCounted: number;
      shelvesCount: number;
      message?: string;
      detail?: string;
    };
  };

  // ---- helpers ----
  const fmtDate = (s?: string | null) => (s ? new Date(s).toLocaleDateString() : "—");
  const grams = (n?: number | null) => `${(n ?? 0).toLocaleString()} g`;
  const pct = (n?: number | null) => `${Math.max(0, Math.min(100, Math.round(n ?? 0)))}%`;
  const cm2 = (n?: number | null) => `${(Math.round((n ?? 0) * 10) / 10).toLocaleString()} cm²`;
  const hasError = (o: any) => o && o.message === "Internal Error";

  // Destructure with fallbacks
  const sc = data.statusCounts ?? { total: 0, breakdown: {} as Record<string, number> };
  const ag = data.activeGrows ?? { rows: [] as any[] };
  const ls = data.lowStock ?? { rows: [] as any[] };
  const ry = data.recentYields ?? { days: 30, totals: { wetWeightG: 0, dryWeightG: 0 }, rows: [] as any[] };
  const act = data.activity ?? { days: 14, count: 0, items: [] as any[] };
  const na = data.nextActions ?? { count: 0, actions: [] as any[] };
  const su = data.shelfUtil ?? { capacityCm2: 0, usedCm2: 0, percent: 0, itemsCounted: 0, shelvesCount: 0 };

  // Avoid Svelte interpreting JSON braces inside markup: render this via a string variable.
  const quickStartCmd =
    `curl -X POST http://localhost:5173/api/dev/seed/default-location ` +
    `-H "content-type: application/json" ` +
    `-d '{"owner_user_id":1,"name":"Default Lab","timezone":"America/Denver"}'`;
</script>

<svelte:head>
  <title>Dashboard</title>
</svelte:head>

{#if !data.locationId}
  <section class="p-6 max-w-4xl mx-auto">
    <h1 class="text-2xl font-bold mb-2">Welcome to Grow Planner</h1>
    <p class="opacity-70 mb-6">
      No location found yet. Create a location to light up your dashboard.
    </p>
    <div class="rounded-xl border p-4 bg-gray-50">
      <p class="mb-2 font-medium">Quick start (dev):</p>
      <pre class="text-sm overflow-auto p-3 bg-white rounded-lg border"><code>{quickStartCmd}</code></pre>
      <p class="mt-3 text-sm opacity-70">Then refresh this page.</p>
    </div>
  </section>
{:else}
  <section class="p-6 space-y-8">
    <!-- Header -->
    <div class="flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold">Dashboard</h1>
        <p class="text-sm opacity-70">Location ID: {data.locationId}</p>
      </div>
      <!-- Placeholder for a future Location switcher -->
      <div class="flex items-center gap-2">
        <span class="text-sm opacity-70">Switch location</span>
        <select class="border rounded-lg px-3 py-2 text-sm opacity-70 pointer-events-none">
          <option selected>Coming soon</option>
        </select>
      </div>
    </div>

    <!-- Status summary cards -->
    <div class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
      <div class="rounded-xl border p-4">
        <div class="text-sm opacity-70">Total Grows</div>
        <div class="text-3xl font-semibold">{sc.total ?? 0}</div>
        {#if hasError(data.statusCounts)}
          <div class="mt-2 text-xs text-red-600">{data.statusCounts?.detail}</div>
        {/if}
      </div>

      {#each Object.entries(sc.breakdown ?? {}) as [status, count]}
        <div class="rounded-xl border p-4">
          <div class="text-sm opacity-70 capitalize">{status.replaceAll('_',' ')}</div>
          <div class="text-3xl font-semibold">{count}</div>
        </div>
      {/each}

      {#if Object.keys(sc.breakdown ?? {}).length === 0}
        <div class="rounded-xl border p-4 col-span-full">
          <div class="text-sm opacity-70">No grows yet. Create your first grow to see status breakdown.</div>
        </div>
      {/if}
    </div>

    <!-- Two-column: Active grows & Low stock -->
    <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
      <section class="rounded-xl border">
        <header class="p-4 border-b flex items-center justify-between">
          <h2 class="font-semibold">Active Grows</h2>
          <span class="text-xs opacity-70">{ag.rows?.length ?? 0} showing</span>
        </header>
        <div class="divide-y">
          {#if hasError(data.activeGrows)}
            <div class="p-4 text-sm text-red-600">{data.activeGrows?.detail}</div>
          {:else if (ag.rows?.length ?? 0) === 0}
            <div class="p-4 text-sm opacity-70">No active grows.</div>
          {:else}
            {#each ag.rows as g}
              <div class="p-4 flex items-start justify-between gap-4">
                <div>
                  <div class="font-medium">{g.batchCode || `Grow #${g.id}`}</div>
                  <div class="text-xs opacity-70 capitalize">{g.status || 'unknown'}</div>
                  <div class="text-xs opacity-70">Start: {fmtDate(g.startDate)} • Fruiting: {fmtDate(g.movedToFruitingAt)}</div>
                </div>
                <div class="text-xs opacity-70 text-right">
                  <div>Container: {g.containerType || '—'}</div>
                  <div>Updated: {fmtDate(g.updatedAt)}</div>
                </div>
              </div>
            {/each}
          {/if}
        </div>
      </section>

      <section class="rounded-xl border">
        <header class="p-4 border-b flex items-center justify-between">
          <h2 class="font-semibold">Low Stock</h2>
          <span class="text-xs opacity-70">{ls.rows?.length ?? 0} items</span>
        </header>
        {#if hasError(data.lowStock)}
          <div class="p-4 text-sm text-red-600">{data.lowStock?.detail}</div>
        {:else if (ls.rows?.length ?? 0) === 0}
          <div class="p-4 text-sm opacity-70">No low-stock items.</div>
        {:else}
          <div class="overflow-auto">
            <table class="min-w-full text-sm">
              <thead>
                <tr class="text-left border-b">
                  <th class="px-4 py-2">Name</th>
                  <th class="px-4 py-2">SKU</th>
                  <th class="px-4 py-2">In Stock</th>
                  <th class="px-4 py-2">Reorder @</th>
                  <th class="px-4 py-2">Supplier</th>
                </tr>
              </thead>
              <tbody>
                {#each ls.rows as s}
                  <tr class="border-b">
                    <td class="px-4 py-2">{s.name}</td>
                    <td class="px-4 py-2 opacity-70">{s.sku || '—'}</td>
                    <td class="px-4 py-2">{s.inStockQty ?? 0}</td>
                    <td class="px-4 py-2">{s.reorderPoint ?? 0}</td>
                    <td class="px-4 py-2 opacity-70">{s.preferredSupplier || '—'}</td>
                  </tr>
                {/each}
              </tbody>
            </table>
          </div>
        {/if}
      </section>
    </div>

    <!-- Recent yields + Shelf utilization -->
    <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
      <section class="rounded-xl border">
        <header class="p-4 border-b flex items-center justify-between">
          <h2 class="font-semibold">Recent Yields (last {ry.days} days)</h2>
          <div class="text-xs opacity-70">
            Total: {grams(ry.totals?.wetWeightG)} wet • {grams(ry.totals?.dryWeightG)} dry
          </div>
        </header>
        {#if hasError(data.recentYields)}
          <div class="p-4 text-sm text-red-600">{data.recentYields?.detail}</div>
        {:else if (ry.rows?.length ?? 0) === 0}
          <div class="p-4 text-sm opacity-70">No harvests recorded.</div>
        {:else}
          <div class="divide-y">
            {#each ry.rows as y}
              <div class="p-4 flex items-center justify-between">
                <div class="text-sm">
                  <div class="font-medium">Grow #{y.growId} — Flush {y.flushNumber ?? '—'}</div>
                  <div class="text-xs opacity-70">Harvest: {fmtDate(y.harvestDate)}</div>
                </div>
                <div class="text-right text-sm">
                  <div>{grams(y.wetWeightG)}</div>
                  <div class="opacity-70">{grams(y.dryWeightG)}</div>
                </div>
              </div>
            {/each}
          </div>
        {/if}
      </section>

      <section class="rounded-xl border">
        <header class="p-4 border-b">
          <h2 class="font-semibold">Shelf Utilization</h2>
        </header>
        {#if hasError(data.shelfUtil)}
          <div class="p-4 text-sm text-red-600">{data.shelfUtil?.detail}</div>
        {:else}
          <div class="p-4">
            <div class="flex items-center justify-between text-sm mb-2">
              <span class="opacity-70">Capacity</span>
              <span>{cm2(su.capacityCm2)}</span>
            </div>
            <div class="flex items-center justify-between text-sm mb-2">
              <span class="opacity-70">Used</span>
              <span>{cm2(su.usedCm2)}</span>
            </div>
            <div class="w-full h-3 bg-gray-200 rounded-full overflow-hidden">
              <div class="h-full bg-emerald-500" style={`width:${su.percent ?? 0}%`}></div>
            </div>
            <div class="mt-2 text-sm">{pct(su.percent)} utilized</div>
            <div class="mt-1 text-xs opacity-70">
              {su.itemsCounted} items across {su.shelvesCount} shelves
            </div>
          </div>
        {/if}
      </section>
    </div>

    <!-- Next actions -->
    <section class="rounded-xl border">
      <header class="p-4 border-b flex items-center justify-between">
        <h2 class="font-semibold">Next Actions</h2>
        <span class="text-xs opacity-70">{na.count ?? na.actions?.length ?? 0} suggestions</span>
      </header>
      {#if hasError(data.nextActions)}
        <div class="p-4 text-sm text-red-600">{data.nextActions?.detail}</div>
      {:else if ((na.actions?.length ?? 0) === 0)}
        <div class="p-4 text-sm opacity-70">No suggested actions right now.</div>
      {:else}
        <ul class="divide-y">
          {#each na.actions as a}
            <li class="p-4 flex items-start justify-between gap-4">
              <div class="text-sm">
                <div class="font-medium">{a.action}</div>
                <div class="opacity-70 text-xs">{a.reason}</div>
              </div>
              <div class="text-xs opacity-70">Grow #{a.growId}</div>
            </li>
          {/each}
        </ul>
      {/if}
    </section>

    <!-- Activity -->
    <section class="rounded-xl border">
      <header class="p-4 border-b flex items-center justify-between">
        <h2 class="font-semibold">Recent Activity (last {act.days} days)</h2>
        <span class="text-xs opacity-70">{act.count ?? act.items?.length ?? 0} events</span>
      </header>
      {#if hasError(data.activity)}
        <div class="p-4 text-sm text-red-600">{data.activity?.detail}</div>
      {:else if ((act.items?.length ?? 0) === 0)}
        <div class="p-4 text-sm opacity-70">No recent activity.</div>
      {:else}
        <ul class="divide-y">
          {#each act.items as it}
            <li class="p-4 flex items-center justify-between">
              <div class="text-sm">
                <span class="font-medium capitalize">{it.type.replaceAll('_',' ')}</span>
                {#if it.label} <span class="opacity-70">— {it.label}</span> {/if}
                <span class="opacity-70"> • Grow #{it.growId}</span>
              </div>
              <div class="text-xs opacity-70">{fmtDate(it.ts)}</div>
            </li>
          {/each}
        </ul>
      {/if}
    </section>
  </section>
{/if}
