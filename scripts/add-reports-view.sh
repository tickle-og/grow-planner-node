#!/usr/bin/env bash
set -euo pipefail

root="${PWD}"
reports_dir="src/routes/reports"
reports_file="${reports_dir}/+page.svelte"

mkdir -p "$reports_dir"

# Only create if it doesn't already exist
if [[ -f "$reports_file" ]]; then
  echo "[skip] ${reports_file} already exists"
  exit 0
fi

cat > "$reports_file" <<'SVELTE'
<script context="server" lang="ts">
// Reports page: Low Stock, Recent Yields, Shelf Utilization, Upcoming Tasks
// Defensive loader that tolerates different payload shapes.

type Jsonish = Record<string, any> | null;

export async function load({ fetch, url }) {
  const locationId = Number(url.searchParams.get('locationId') ?? 1);

  async function get(path: string): Promise<Jsonish> {
    try {
      const res = await fetch(path, { headers: { 'accept': 'application/json' } });
      if (!res.ok) return null;
      return await res.json();
    } catch {
      return null;
    }
  }

  // Known endpoints in this codebase:
  // - /api/dashboard/low-stock?locationId=…  (shape varied; use items ?? rows ?? [])
  // - /api/dashboard/recent-yields?locationId=… (maybe yields[] or rows[])
  // - /api/dashboard/next-actions?locationId=… (actions[])
  // - /api/locations/:id/shelves ( { ok, shelves: [] } )
  const [low, yields, actions, shelves] = await Promise.all([
    get(`/api/dashboard/low-stock?locationId=${locationId}&limit=100`),
    get(`/api/dashboard/recent-yields?locationId=${locationId}&limit=50`),
    get(`/api/dashboard/next-actions?locationId=${locationId}&limit=50`),
    get(`/api/locations/${locationId}/shelves`)
  ]);

  function asArray(x: any, keys: string[]): any[] {
    if (!x) return [];
    for (const k of keys) {
      if (Array.isArray(x[k])) return x[k];
    }
    if (Array.isArray(x)) return x;
    return [];
  }

  const lowItems     = asArray(low,     ['items','rows','low','data']);
  const yieldItems   = asArray(yields,  ['yields','rows','items','data']);
  const actionItems  = asArray(actions, ['actions','rows','items','data']);
  const shelfItems   = shelves?.shelves ?? asArray(shelves, ['shelves','rows','items','data']);

  return {
    locationId,
    low: lowItems,
    yields: yieldItems,
    actions: actionItems,
    shelves: shelfItems
  };
}
</script>

<script lang="ts">
  export let data: {
    locationId: number,
    low: any[],
    yields: any[],
    actions: any[],
    shelves: any[]
  };

  const { locationId } = data;

  function fmt(n: unknown) {
    if (typeof n === 'number') return n.toLocaleString();
    return String(n ?? '');
  }
</script>

<svelte:head>
  <title>Reports · Myco</title>
</svelte:head>

<div class="page">
  <header class="page-header">
    <h1>Reports</h1>
    <p>Inventory, yields, shelf utilization, and the full task schedule.</p>
    <nav class="crumbs">
      <a href="/">Today</a>
      <span>·</span>
      <span>Reports</span>
    </nav>
  </header>

  <section class="grid">
    <!-- Low Stock -->
    <article class="card">
      <h2>Low Stock</h2>
      {#if data.low.length === 0}
        <p class="muted">Stock looks good.</p>
      {:else}
        <table class="table">
          <thead><tr><th>Item</th><th>Qty</th><th>Min</th></tr></thead>
          <tbody>
            {#each data.low as row}
              <tr>
                <td>{row.name ?? row.item ?? row.sku ?? '—'}</td>
                <td>{fmt(row.qty ?? row.quantity ?? row.onHand)}</td>
                <td>{fmt(row.min ?? row.minQty ?? row.threshold)}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      {/if}
    </article>

    <!-- Recent Yields -->
    <article class="card">
      <h2>Recent Yields</h2>
      {#if data.yields.length === 0}
        <p class="muted">No recent yields.</p>
      {:else}
        <table class="table">
          <thead><tr><th>Batch</th><th>Date</th><th>Wet (g)</th><th>Dry (g)</th></tr></thead>
          <tbody>
            {#each data.yields as y}
              <tr>
                <td>{y.batch_code ?? y.batchCode ?? y.grow_id ?? '—'}</td>
                <td>{(y.harvested_at ?? y.date ?? '').slice(0, 10)}</td>
                <td>{fmt(y.wet_weight_g ?? y.wet)}</td>
                <td>{fmt(y.dry_weight_g ?? y.dry)}</td>
              </tr>
            {/each}
          </tbody>
        </table>
      {/if}
    </article>

    <!-- Shelf Utilization -->
    <article class="card">
      <h2>Shelf Utilization</h2>
      {#if data.shelves.length === 0}
        <p class="muted">No shelves defined for location #{locationId}.</p>
      {:else}
        <ul class="list">
          {#each data.shelves as s}
            <li>
              <strong>{s.label ?? s.name ?? `Shelf #${s.id}`}</strong>
              <span class="muted">
                {fmt(s.levels ?? 1)} levels · {fmt(s.lengthCm ?? s.length_cm)}×{fmt(s.widthCm ?? s.width_cm)}×{fmt(s.heightCm ?? s.height_cm)} cm
              </span>
            </li>
          {/each}
        </ul>
      {/if}
    </article>

    <!-- Upcoming Tasks (full) -->
    <article class="card">
      <h2>Upcoming Tasks</h2>
      {#if data.actions.length === 0}
        <p class="muted">No scheduled tasks.</p>
      {:else}
        <ul class="list">
          {#each data.actions as a}
            <li>
              <div class="row">
                <span class="pill">{(a.due_at ?? a.dueAt ?? a.when ?? '').slice(0, 16).replace('T',' ')}</span>
                <span class="title">{a.title ?? a.name ?? a.kind ?? 'Task'}</span>
              </div>
              {#if a.notes || a.note}
                <div class="muted small">{a.notes ?? a.note}</div>
              {/if}
            </li>
          {/each}
        </ul>
      {/if}
    </article>
  </section>
</div>

<style>
  .page { padding: 1.25rem; }
  .page-header h1 { font-size: 1.5rem; font-weight: 800; margin: 0; color: #0B1220; }
  .page-header p { margin: .25rem 0 .5rem; color: #374151; }
  .crumbs { display: flex; gap: .5rem; color: #6B7280; font-size: .875rem; }

  .grid {
    display: grid;
    grid-template-columns: repeat(12, minmax(0, 1fr));
    gap: 1rem;
  }

  .card {
    grid-column: span 12 / span 12;
    background: #fff;
    border: 1px solid #E5E7EB;
    border-radius: .75rem;
    padding: 1rem;
    box-shadow: 0 1px 2px rgba(0,0,0,.04);
  }
  /* layout: 2-up on medium, 3-up on wide */
  @media (min-width: 900px) {
    .card { grid-column: span 6 / span 6; }
  }
  @media (min-width: 1280px) {
    .card { grid-column: span 4 / span 4; }
  }

  .card h2 { margin: 0 0 .5rem; font-weight: 700; color: #0B1220; }
  .muted { color: #6B7280; }
  .small { font-size: .875rem; }

  .table { width: 100%; border-collapse: collapse; font-size: .9rem; }
  .table th, .table td { text-align: left; padding: .5rem .5rem; border-bottom: 1px solid #F3F4F6; }
  .table thead th { color: #111827; font-weight: 700; background: #F9FAFB; }

  .list { display: grid; gap: .5rem; padding: 0; margin: 0; list-style: none; }
  .row { display: flex; align-items: center; gap: .5rem; }
  .pill {
    display: inline-block; padding: .125rem .5rem; border-radius: 9999px;
    background: #EEF2FF; color: #1E3A8A; border: 1px solid #E0E7FF; font-size: .75rem;
  }
  .title { font-weight: 600; color: #0B1220; }
</style>
SVELTE

echo "[ok ] Created ${reports_file}"
echo
echo "Next:"
echo "  - Visit /reports (append ?locationId=1 if you’ve got multiple locations)."
echo "  - If you want me to auto-comment the four sections on Today, I can generate a follow-up script once we confirm the exact headings present."
