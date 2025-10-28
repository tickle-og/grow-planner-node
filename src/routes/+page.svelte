<!-- src/routes/+page.svelte -->
<script lang="ts">
  import { browser } from "$app/environment";
  import { onMount } from "svelte";

  // If your +page.server.ts passes data, we accept it. Fallback to location 1 for dev.
  export let data: { locationId?: number } | undefined;
  let locationId = data?.locationId ?? 1;

  // ---- Utilities -----------------------------------------------------------
  async function fetchJson<T = any>(url: string, init?: RequestInit): Promise<T | null> {
    try {
      if (!browser) return null;
      const res = await fetch(url, init);
      if (!res.ok) return null;
      return (await res.json()) as T;
    } catch {
      return null;
    }
  }
  const nowStamp = () => new Date().toISOString().replace("T", " ").slice(0, 19);

  // ---- Status counts -------------------------------------------------------
  type Counts = {
    pending: number;
    active: number;
    completed: number;
    failed: number;
    allTime?: { pending: number; active: number; completed: number; failed: number };
  };
  let counts: Counts = { pending: 0, active: 0, completed: 0, failed: 0 };
  let loadingCounts = true;

  async function loadCounts() {
    loadingCounts = true;
    const c = await fetchJson<Counts>(`/api/dashboard/status-counts?location_id=${locationId}`);
    if (c) counts = c;
    loadingCounts = false;
  }

  // ---- Expand panels state -------------------------------------------------
  let expanded = {
    active: false,
    lowStock: false,
    yields: false,
    tasks: false,
    activity: false,
    notes: false,
    shelf: false,
    shelfAssets: false
  };

  // ---- Active grows (simple client filter) --------------------------------
  type Grow = {
    id: number;
    status: string | null;
    batchCode: string | null;
    containerType: string | null;
    containerPresetKey: string | null;
    createdAt?: string | null;
  };
  let activeGrows: Grow[] = [];
  let loadingActive = false;
  let activeLoaded = false;

  async function loadMoreActive() {
    if (!browser || activeLoaded || loadingActive) return;
    loadingActive = true;
    const rows = await fetchJson<Grow[]>(`/api/grows?location_id=${locationId}`);
    activeGrows =
      rows?.filter((g) => g?.status && ["incubating", "fruiting", "active"].includes(g.status)) ?? [];
    activeLoaded = true;
    loadingActive = false;
  }

  // ---- Low stock supplies (optional endpoint; safe if missing) ------------
  type Supply = {
    id: number;
    name?: string;
    sku?: string | null;
    inStockQty?: number | null;
    reorderPoint?: number | null;
  };
  let lowStock: Supply[] = [];
  let loadingLowStock = false;
  let lowStockLoaded = false;

  async function loadMoreLowStock() {
    if (!browser || lowStockLoaded || loadingLowStock) return;
    loadingLowStock = true;
    // If you haven't wired a route, this will simply resolve null and keep array empty.
    const rows = await fetchJson<Supply[]>(`/api/supplies?location_id=${locationId}&low_stock=1`);
    lowStock = rows ?? [];
    lowStockLoaded = true;
    loadingLowStock = false;
  }

  // ---- Recent yields (optional; safe if missing) ---------------------------
  type YieldRow = {
    id: number;
    growId?: number | null;
    weightG?: number | null;
    qualityGrade?: string | null;
    createdAt?: string | null;
  };
  let recentYields: YieldRow[] = [];
  let loadingYields = false;
  let yieldsLoaded = false;

  async function loadMoreYields() {
    if (!browser || yieldsLoaded || loadingYields) return;
    loadingYields = true;
    const rows = await fetchJson<YieldRow[]>(`/api/dashboard/recent-yields?location_id=${locationId}`);
    recentYields = rows ?? [];
    yieldsLoaded = true;
    loadingYields = false;
  }

  // ---- Upcoming tasks (previously Next Actions) ----------------------------
  type TaskRow = {
    id: number;
    dueAt?: string | null;
    title?: string | null;
    growId?: number | null;
  };
  let tasks: TaskRow[] = [];
  let loadingTasks = false;
  let tasksLoaded = false;

  async function loadMoreTasks() {
    if (!browser || tasksLoaded || loadingTasks) return;
    loadingTasks = true;
    const rows = await fetchJson<TaskRow[]>(`/api/dashboard/upcoming-tasks?location_id=${locationId}`);
    tasks = rows ?? [];
    tasksLoaded = true;
    loadingTasks = false;
  }

  // ---- Recent activity (optional) -----------------------------------------
  type ActivityRow = {
    id: number;
    at?: string | null;
    kind?: string | null;
    ref?: string | null;
    note?: string | null;
  };
  let activity: ActivityRow[] = [];
  let loadingActivity = false;
  let activityLoaded = false;

  async function loadMoreActivity() {
    if (!browser || activityLoaded || loadingActivity) return;
    loadingActivity = true;
    const rows = await fetchJson<ActivityRow[]>(`/api/dashboard/recent-activity?location_id=${locationId}`);
    activity = rows ?? [];
    activityLoaded = true;
    loadingActivity = false;
  }

  // ---- Recent notes: last 10 entries with note text -----------------------
  type NoteRow = { id: number; at?: string | null; source?: string | null; note?: string | null };
  let recentNotes: NoteRow[] = [];
  let loadingNotes = false;
  let notesLoaded = false;

  async function loadRecentNotes() {
    if (!browser || notesLoaded || loadingNotes) return;
    loadingNotes = true;
    const rows = await fetchJson<NoteRow[]>(`/api/dashboard/recent-notes?location_id=${locationId}`);
    recentNotes = rows ?? [];
    notesLoaded = true;
    loadingNotes = false;
  }

  // ---- Shelf utilization (capacity vs used) --------------------------------
  type ShelfUtil = {
    capacityCm2: number;
    usedCm2: number;
    percent: number; // 0..100
    itemsCounted: number;
    shelvesCount: number;
  };
  let shelfUtil: ShelfUtil | null = null;
  let loadingShelf = false;
  let shelfLoaded = false;

  async function loadShelf() {
    if (!browser || shelfLoaded || loadingShelf) return;
    loadingShelf = true;
    const res = await fetchJson<ShelfUtil>(`/api/dashboard/shelf-utilization?location_id=${locationId}`);
    shelfUtil = res ?? { capacityCm2: 0, usedCm2: 0, percent: 0, itemsCounted: 0, shelvesCount: 0 };
    shelfLoaded = true;
    loadingShelf = false;
  }

  // ---- Asset locations (bins & groups) ------------------------------------
  type BinRow = { id: number; label: string; shelfId: number | null; shelfLabel?: string | null; count?: number };
  type AssignmentRow = { binId: number; growId: number | null; groupLabel?: string | null };
  let bins: BinRow[] = [];
  let assignments: AssignmentRow[] = [];
  let loadingAssets = false;
  let assetsLoaded = false;

  async function loadAssetLocations() {
    if (!browser || assetsLoaded || loadingAssets) return;
    loadingAssets = true;
    const res = await fetchJson<{ bins: BinRow[]; assignments: AssignmentRow[] }>(
      `/api/dashboard/asset-locations?location_id=${locationId}`
    );
    bins = res?.bins ?? [];
    assignments = res?.assignments ?? [];
    assetsLoaded = true;
    loadingAssets = false;
  }

  // ---- Reactive watchers (browser only) -----------------------------------
  $: if (browser && expanded.active) loadMoreActive();
  $: if (browser && expanded.lowStock) loadMoreLowStock();
  $: if (browser && expanded.yields) loadMoreYields();
  $: if (browser && expanded.tasks) loadMoreTasks();
  $: if (browser && expanded.activity) loadMoreActivity();
  $: if (browser && expanded.notes) loadRecentNotes();
  $: if (browser && expanded.shelf) loadShelf();
  $: if (browser && expanded.shelfAssets) loadAssetLocations();

  // ---- Initial load on mount ----------------------------------------------
  onMount(async () => {
    if (!locationId) return;
    await loadCounts();
  });
</script>

<!-- Page -->
<div class="mx-auto max-w-7xl p-6 space-y-8">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-2xl font-semibold tracking-tight">Dashboard</h1>
      <p class="text-sm text-muted-foreground">Location #{locationId} • {nowStamp()}</p>
    </div>
    <div class="flex items-center gap-2">
      <button
        class="rounded-xl border px-3 py-2 text-sm hover:bg-muted"
        on:click={() => loadCounts()}
        aria-label="Refresh"
        title="Refresh">
        Refresh
      </button>
    </div>
  </div>

  <!-- Status cards (high-contrast) -->
  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
    <!-- Pending -->
    <div class="rounded-2xl border bg-amber-50 border-amber-200 p-4 shadow-sm">
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-medium text-amber-900">Pending</h3>
        <span class="px-2 py-0.5 text-xs rounded-full bg-amber-100 text-amber-800">All time</span>
      </div>
      <p class="mt-2 text-3xl font-semibold text-amber-700">
        {loadingCounts ? '—' : counts.pending}
      </p>
    </div>

    <!-- Active -->
    <div class="rounded-2xl border bg-emerald-600 border-emerald-700 p-4 shadow-sm">
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-medium text-white">Active</h3>
        <span class="px-2 py-0.5 text-xs rounded-full bg-white/20 text-white">All time</span>
      </div>
      <p class="mt-2 text-3xl font-semibold text-white">
        {loadingCounts ? '—' : counts.active}
      </p>
    </div>

    <!-- Completed -->
    <div class="rounded-2xl border bg-sky-600 border-sky-700 p-4 shadow-sm">
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-medium text-white">Completed</h3>
        <span class="px-2 py-0.5 text-xs rounded-full bg-white/20 text-white">All time</span>
      </div>
      <p class="mt-2 text-3xl font-semibold text-white">
        {loadingCounts ? '—' : counts.completed}
      </p>
    </div>

    <!-- Failed -->
    <div class="rounded-2xl border bg-rose-600 border-rose-700 p-4 shadow-sm">
      <div class="flex items-center justify-between">
        <h3 class="text-sm font-medium text-white">Failed</h3>
        <span class="px-2 py-0.5 text-xs rounded-full bg-white/20 text-white">All time</span>
      </div>
      <p class="mt-2 text-3xl font-semibold text-white">
        {loadingCounts ? '—' : counts.failed}
      </p>
    </div>
  </div>

  <!-- Expandable panels -->
  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Active Grows -->
    <section class="rounded-2xl border bg-card p-5">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-base font-semibold">Active Grows</h2>
          <p class="text-xs text-muted-foreground">Incubating or fruiting</p>
        </div>
        <button
          class="rounded-lg border px-3 py-1.5 text-sm hover:bg-muted"
          on:click={() => (expanded.active = !expanded.active)}>
          {expanded.active ? "Collapse" : "Expand"}
        </button>
      </div>

      {#if expanded.active}
        <div class="mt-4">
          {#if loadingActive}
            <div class="text-sm text-muted-foreground">Loading…</div>
          {:else if activeGrows.length === 0}
            <div class="text-sm text-muted-foreground">No active grows.</div>
          {:else}
            <ul class="space-y-2">
              {#each activeGrows as g}
                <li class="rounded-lg border p-3 flex items-center justify-between">
                  <div>
                    <div class="text-sm font-medium">{g.batchCode ?? `Grow #${g.id}`}</div>
                    <div class="text-xs text-muted-foreground">
                      {g.status} • {g.containerType ?? g.containerPresetKey}
                    </div>
                  </div>
                  <div class="text-xs text-muted-foreground">{g.createdAt ?? ""}</div>
                </li>
              {/each}
            </ul>
          {/if}
        </div>
      {/if}
    </section>

    <!-- Low Stock -->
    <section class="rounded-2xl border bg-card p-5">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-base font-semibold">Low Stock</h2>
          <p class="text-xs text-muted-foreground">Supplies below reorder point</p>
        </div>
        <button
          class="rounded-lg border px-3 py-1.5 text-sm hover:bg-muted"
          on:click={() => (expanded.lowStock = !expanded.lowStock)}>
          {expanded.lowStock ? "Collapse" : "Expand"}
        </button>
      </div>

      {#if expanded.lowStock}
        <div class="mt-4">
          {#if loadingLowStock}
            <div class="text-sm text-muted-foreground">Loading…</div>
          {:else if lowStock.length === 0}
            <div class="text-sm text-muted-foreground">All stocked up.</div>
          {:else}
            <div class="overflow-x-auto">
              <table class="min-w-full text-sm">
                <thead>
                  <tr class="text-left text-xs text-muted-foreground">
                    <th class="py-2 pr-3">Item</th>
                    <th class="py-2 pr-3">SKU</th>
                    <th class="py-2 pr-3">In Stock</th>
                    <th class="py-2">Reorder Point</th>
                  </tr>
                </thead>
                <tbody>
                  {#each lowStock as s}
                    <tr class="border-t">
                      <td class="py-2 pr-3">{s.name ?? `Supply #${s.id}`}</td>
                      <td class="py-2 pr-3">{s.sku ?? "—"}</td>
                      <td class="py-2 pr-3">{s.inStockQty ?? 0}</td>
                      <td class="py-2">{s.reorderPoint ?? 0}</td>
                    </tr>
                  {/each}
                </tbody>
              </table>
            </div>
          {/if}
        </div>
      {/if}
    </section>

    <!-- Recent Yields -->
    <section class="rounded-2xl border bg-card p-5">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-base font-semibold">Recent Yields</h2>
          <p class="text-xs text-muted-foreground">Latest harvest weights</p>
        </div>
        <button
          class="rounded-lg border px-3 py-1.5 text-sm hover:bg-muted"
          on:click={() => (expanded.yields = !expanded.yields)}>
          {expanded.yields ? "Collapse" : "Expand"}
        </button>
      </div>

      {#if expanded.yields}
        <div class="mt-4">
          {#if loadingYields}
            <div class="text-sm text-muted-foreground">Loading…</div>
          {:else if recentYields.length === 0}
            <div class="text-sm text-muted-foreground">No recent yields.</div>
          {:else}
            <ul class="space-y-2">
              {#each recentYields as y}
                <li class="rounded-lg border p-3 flex items-center justify-between">
                  <div>
                    <div class="text-sm font-medium">Grow #{y.growId ?? "?"}</div>
                    <div class="text-xs text-muted-foreground">{y.qualityGrade ?? "grade: n/a"}</div>
                  </div>
                  <div class="text-sm font-semibold">{y.weightG ?? 0} g</div>
                </li>
              {/each}
            </ul>
          {/if}
        </div>
      {/if}
    </section>

    <!-- Upcoming Tasks -->
    <section class="rounded-2xl border bg-card p-5">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-base font-semibold">Upcoming Tasks</h2>
          <p class="text-xs text-muted-foreground">What’s coming up next</p>
        </div>
        <button
          class="rounded-lg border px-3 py-1.5 text-sm hover:bg-muted"
          on:click={() => (expanded.tasks = !expanded.tasks)}>
          {expanded.tasks ? "Collapse" : "Expand"}
        </button>
      </div>

      {#if expanded.tasks}
        <div class="mt-4">
          {#if loadingTasks}
            <div class="text-sm text-muted-foreground">Loading…</div>
          {:else if tasks.length === 0}
            <div class="text-sm text-muted-foreground">No tasks queued.</div>
          {:else}
            <ul class="space-y-2">
              {#each tasks as t}
                <li class="rounded-lg border p-3 flex items-center justify-between">
                  <div>
                    <div class="text-sm font-medium">{t.title ?? "Task"}</div>
                    <div class="text-xs text-muted-foreground">Grow #{t.growId ?? "—"}</div>
                  </div>
                  <div class="text-xs text-muted-foreground">{t.dueAt ?? ""}</div>
                </li>
              {/each}
            </ul>
          {/if}
        </div>
      {/if}
    </section>

    <!-- Recent Notes -->
    <section class="rounded-2xl border bg-card p-5">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-base font-semibold">Recent Notes</h2>
          <p class="text-xs text-muted-foreground">Notes from the last 10 actions</p>
        </div>
        <button
          class="rounded-lg border px-3 py-1.5 text-sm hover:bg-muted"
          on:click={() => (expanded.notes = !expanded.notes)}>
          {expanded.notes ? "Collapse" : "Expand"}
        </button>
      </div>

      {#if expanded.notes}
        <div class="mt-4">
          {#if loadingNotes}
            <div class="text-sm text-muted-foreground">Loading…</div>
          {:else if recentNotes.length === 0}
            <div class="text-sm text-muted-foreground">No notes found.</div>
          {:else}
            <ul class="space-y-2">
              {#each recentNotes as n}
                <li class="rounded-lg border p-3">
                  <div class="text-xs text-muted-foreground">{n.at ?? ""} • {n.source ?? ""}</div>
                  <div class="text-sm mt-1">{n.note}</div>
                </li>
              {/each}
            </ul>
          {/if}
        </div>
      {/if}
    </section>

    <!-- Shelf Utilization -->
    <section class="rounded-2xl border bg-card p-5">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-base font-semibold">Shelf Utilization</h2>
          <p class="text-xs text-muted-foreground">Capacity vs current usage</p>
        </div>
        <button
          class="rounded-lg border px-3 py-1.5 text-sm hover:bg-muted"
          on:click={() => (expanded.shelf = !expanded.shelf)}>
          {expanded.shelf ? "Collapse" : "Expand"}
        </button>
      </div>

      {#if expanded.shelf}
        <div class="mt-4">
          {#if loadingShelf}
            <div class="text-sm text-muted-foreground">Loading…</div>
          {:else if !shelfUtil}
            <div class="text-sm text-muted-foreground">No data.</div>
          {:else}
            <div class="flex items-center gap-4">
              <div class="flex-1">
                <div class="h-3 w-full rounded-full bg-muted overflow-hidden">
                  <div
                    class="h-3 rounded-full bg-emerald-500"
                    style={`width: ${shelfUtil.percent}%`}
                    aria-label="utilization bar" />
                </div>
                <div class="mt-2 text-xs text-muted-foreground">
                  {shelfUtil.usedCm2} / {shelfUtil.capacityCm2} cm² • {shelfUtil.percent}% used
                </div>
              </div>
              <div class="text-sm text-muted-foreground">
                {shelfUtil.itemsCounted} items • {shelfUtil.shelvesCount} shelves
              </div>
            </div>
          {/if}
        </div>
      {/if}
    </section>

    <!-- Asset Locations -->
    <section class="rounded-2xl border bg-card p-5">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-base font-semibold">Asset Locations</h2>
          <p class="text-xs text-muted-foreground">Bins and groups by shelf</p>
        </div>
        <button
          class="rounded-lg border px-3 py-1.5 text-sm hover:bg-muted"
          on:click={() => (expanded.shelfAssets = !expanded.shelfAssets)}>
          {expanded.shelfAssets ? "Collapse" : "Expand"}
        </button>
      </div>

      {#if expanded.shelfAssets}
        <div class="mt-4">
          {#if loadingAssets}
            <div class="text-sm text-muted-foreground">Loading…</div>
          {:else if bins.length === 0}
            <div class="text-sm text-muted-foreground">No bins created yet.</div>
          {:else}
            <ul class="space-y-2">
              {#each bins as b}
                <li class="rounded-lg border p-3">
                  <div class="flex items-center justify-between">
                    <div>
                      <div class="text-sm font-medium">{b.label}</div>
                      <div class="text-xs text-muted-foreground">
                        Shelf: {b.shelfLabel ?? b.shelfId ?? "—"}
                      </div>
                    </div>
                    <div class="text-sm text-muted-foreground">{b.count ?? 0} items</div>
                  </div>
                  {#if assignments.length}
                    <div class="mt-2">
                      <div class="text-xs text-muted-foreground mb-1">Assignments:</div>
                      <ul class="grid sm:grid-cols-2 gap-2">
                        {#each assignments.filter((a) => a.binId === b.id) as a}
                          <li class="rounded border px-2 py-1 text-xs">
                            {a.groupLabel ?? `Grow #${a.growId ?? "—"}`}
                          </li>
                        {/each}
                      </ul>
                    </div>
                  {/if}
                </li>
              {/each}
            </ul>
          {/if}
        </div>
      {/if}
    </section>
  </div>

  <!-- Dev helper: create default location if missing -->
  {#if !locationId}
    <div class="rounded-xl border bg-amber-50 border-amber-200 p-4">
      <div class="text-sm">
        No location configured. Create one with:
        <pre class="text-xs overflow-auto p-3 bg-white rounded-lg border mt-2"><code>curl -X POST http://localhost:5173/api/dev/seed/default-location \
  -H "content-type: application/json" \
  -d '{"owner_user_id":1,"name":"Default Lab","timezone":"America/Denver"}'</code></pre>
        <div class="mt-2 text-xs text-muted-foreground">Then refresh this page.</div>
      </div>
    </div>
  {/if}
</div>
