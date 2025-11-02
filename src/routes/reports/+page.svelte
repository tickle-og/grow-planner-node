<script lang="ts">
  export let data: {
    locationId: number,
    lowStock: any,
    activeGrows: any,
    recentYields: any,
    nextActions: any,
    activity: any,
    shelves: any
  };

  const err = (obj: any) => obj && obj.message === 'Internal Error';
</script>

<div class="reports-page reports-theme mx-auto max-w-6xl px-4 py-8">
  <header class="mb-6">
    <h1 class="text-3xl font-extrabold tracking-tight">Reports</h1>
    <p class="mt-1 text-base text-muted">Deep-dive into stock, yields, tasks, activity, and shelves.</p>
  </header>

  <!-- Low Stock -->
  <section class="card">
    <div class="card-head">
      <h2 class="card-title">Low stock</h2>
    </div>
    {#if err(data.lowStock)}
      <div class="card-body">Couldn’t load stock right now.</div>
    {:else if data.lowStock?.rows?.length}
      <ul class="list">
        {#each data.lowStock.rows as row}
          <li class="row">
            <span class="name">{row.name ?? row.sku ?? 'Item'}</span>
            <span class="meta">qty: {row.qty ?? row.quantity ?? 0}</span>
          </li>
        {/each}
      </ul>
    {:else}
      <div class="card-body">Stock looks good.</div>
    {/if}
  </section>

  <!-- Recent Yields -->
  <section class="card">
    <div class="card-head">
      <h2 class="card-title">Recent yields (30d)</h2>
    </div>
    {#if err(data.recentYields)}
      <div class="card-body">Couldn’t load yields.</div>
    {:else}
      <div class="card-body grid sm:grid-cols-3 gap-3">
        <div class="pill"><span class="label">Wet</span><span class="val">
          {data.recentYields?.totals?.wetWeightG ?? 0} g</span></div>
        <div class="pill"><span class="label">Dry</span><span class="val">
          {data.recentYields?.totals?.dryWeightG ?? 0} g</span></div>
        <div class="pill"><span class="label">Entries</span><span class="val">
          {data.recentYields?.rows?.length ?? 0}</span></div>
      </div>
      {#if data.recentYields?.rows?.length}
        <ul class="list mt-3">
          {#each data.recentYields.rows as y}
            <li class="row">
              <span class="name">{y.batchCode ?? 'Batch'}</span>
              <span class="meta">{y.date ?? y.ts ?? ''}</span>
              <span class="meta">{(y.dryWeightG ?? y.weightG ?? 0)} g</span>
            </li>
          {/each}
        </ul>
      {/if}
    {/if}
  </section>

  <!-- Upcoming Tasks -->
  <section class="card">
    <div class="card-head">
      <h2 class="card-title">Upcoming tasks</h2>
    </div>
    {#if err(data.nextActions)}
      <div class="card-body">Task service isn’t ready yet.</div>
    {:else if data.nextActions?.actions?.length}
      <ul class="list">
        {#each data.nextActions.actions as t}
          <li class="row">
            <span class="name">{t.title ?? t.type ?? 'Task'}</span>
            <span class="meta">{t.dueAt ?? t.when ?? 'soon'}</span>
          </li>
        {/each}
      </ul>
    {:else}
      <div class="card-body">No suggested actions right now.</div>
    {/if}
  </section>

  <!-- Active Grows -->
  <section class="card">
    <div class="card-head">
      <h2 class="card-title">Active grows</h2>
    </div>
    {#if err(data.activeGrows)}
      <div class="card-body">Couldn’t load grows.</div>
    {:else if data.activeGrows?.rows?.length}
      <ul class="list">
        {#each data.activeGrows.rows as g}
          <li class="row">
            <span class="name">{g.batchCode ?? 'Batch'}</span>
            <span class="meta">{g.containerType ?? '-'}</span>
            <span class="meta">{g.status ?? '-'}</span>
          </li>
        {/each}
      </ul>
    {:else}
      <div class="card-body">No active grows.</div>
    {/if}
  </section>

  <!-- Recent Activity -->
  <section class="card">
    <div class="card-head">
      <h2 class="card-title">Recent activity (14d)</h2>
    </div>
    {#if err(data.activity)}
      <div class="card-body">Activity feed unavailable.</div>
    {:else if data.activity?.items?.length}
      <ul class="list">
        {#each data.activity.items as a}
          <li class="row">
            <span class="name">{a.type ?? 'event'}</span>
            <span class="meta">{a.ts ?? ''}</span>
            <span class="meta">{a.label ?? ''}</span>
          </li>
        {/each}
      </ul>
    {:else}
      <div class="card-body">Nothing new yet.</div>
    {/if}
  </section>

  <!-- Shelf Utilization (first pass: just show shelves until util math lands) -->
  <section class="card">
    <div class="card-head">
      <h2 class="card-title">Shelf utilization</h2>
    </div>
    {#if err(data.shelves)}
      <div class="card-body">Couldn’t load shelves.</div>
    {:else}
      <div class="card-body">
        <div class="pill">
          <span class="label">Shelves</span>
          <span class="val">{Array.isArray(data.shelves?.shelves) ? data.shelves.shelves.length : 0}</span>
        </div>
        {#if Array.isArray(data.shelves?.shelves) && data.shelves.shelves.length}
          <ul class="list mt-3">
            {#each data.shelves.shelves as s}
              <li class="row">
                <span class="name">{s.label ?? 'Shelf'}</span>
                <span class="meta">{s.lengthCm ?? 0}×{s.widthCm ?? 0}×{s.heightCm ?? 0} cm</span>
                <span class="meta">{s.levels ?? 1} level(s)</span>
              </li>
            {/each}
          </ul>
        {/if}
      </div>
    {/if}
  </section>
</div>

<style>
  .reports-theme { color: #e5e7eb; }
  .text-muted { color: #9ca3af; }

  .card {
    background: #0b1020;
    border: 1px solid #1f2937;
    border-radius: 0.75rem;
    margin-bottom: 1rem;
    overflow: clip;
  }
  .card-head {
    display: flex; align-items: center; justify-content: space-between;
    padding: 0.9rem 1rem; border-bottom: 1px solid #1f2937;
    background: #0f172a;
  }
  .card-title { font-weight: 700; color: #e5e7eb; }
  .card-body { padding: 0.9rem 1rem; color: #e5e7eb; }

  .list { display: grid; gap: 8px; padding: 10px; }
  .row {
    display: grid; grid-template-columns: 1fr auto auto; gap: 12px;
    padding: 10px 12px; border: 1px solid #1f2937; border-radius: 8px;
    background: #0b1224;
  }
  .row .name { font-weight: 600; color: #f3f4f6; }
  .row .meta { color: #9ca3af; font-variant-numeric: tabular-nums; }

  .pill {
    display: inline-flex; align-items: center; gap: 10px;
    padding: 8px 12px; border: 1px solid #1f2937; border-radius: 999px;
    background: #0b1224;
  }
  .pill .label { color: #9ca3af; }
  .pill .val { color: #f9fafb; font-weight: 700; }
</style>
