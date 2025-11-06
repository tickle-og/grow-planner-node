# scripts/fix-today-500.sh
set -euo pipefail
f="src/routes/+page.svelte"
cp -n "$f" "${f}.bak.$(date +%Y%m%d-%H%M%S)" || true

cat > "$f" <<'SVELTE'
<script lang="ts">
  // Minimal, bulletproof Today screen
  // Expects server load to provide: { locationId, statusCounts, nextActions }
  export let data: any;

  const counts = data?.statusCounts ?? {};
  const n = (k: string) => Number(counts?.[k] ?? 0);

  // Next actions: tolerate missing/errored API
  const actions: any[] = Array.isArray(data?.nextActions?.actions)
    ? [...data.nextActions.actions]
    : [];

  // Sort by due time if present
  actions.sort((a, b) => {
    const ta = Date.parse(a?.dueAt ?? a?.when ?? '') || Number.MAX_SAFE_INTEGER;
    const tb = Date.parse(b?.dueAt ?? b?.when ?? '') || Number.MAX_SAFE_INTEGER;
    return ta - tb;
  });
</script>

<div class="today-page">
  <header class="container">
    <h1 class="title">Today</h1>
    <p class="subtitle">Snapshot of your lab: status and upcoming work.</p>

    <!-- KPI band -->
    <section class="kpi-grid" aria-label="Status overview">
      <div class="kpi-card kpi-pending">
        <div class="kpi-label">Pending</div>
        <div class="kpi-value">{n('pending')}</div>
      </div>
      <div class="kpi-card kpi-active">
        <div class="kpi-label">Active</div>
        <div class="kpi-value">{n('active')}</div>
      </div>
      <div class="kpi-card kpi-completed">
        <div class="kpi-label">Completed</div>
        <div class="kpi-value">{n('completed')}</div>
      </div>
      <div class="kpi-card kpi-failed">
        <div class="kpi-label">Failed</div>
        <div class="kpi-value">{n('failed')}</div>
      </div>
    </section>
  </header>

  <main class="container grid gap-4 md:grid-cols-2">
    <!-- Upcoming Tasks -->
    <section class="card">
      <div class="card-head">
        <h2 class="card-title">Upcoming Tasks</h2>
      </div>
      {#if actions.length > 0}
        <ul class="list">
          {#each actions as t}
            <li class="row">
              <span class="name">{t.title ?? t.type ?? 'Task'}</span>
              <span class="meta">{t.dueAt ?? t.when ?? 'soon'}</span>
            </li>
          {/each}
        </ul>
      {:else if data?.nextActions?.message === 'Internal Error'}
        <div class="card-body">Task service isn’t ready yet.</div>
      {:else}
        <div class="card-body">No suggested actions right now.</div>
      {/if}
    </section>

    <!-- First-run tip -->
    <section class="card">
      <div class="card-head">
        <h2 class="card-title">First-run tip</h2>
      </div>
      <div class="card-body">
        <p>If you haven’t created a default location yet, run this once:</p>
        <pre class="mono"><code>curl -X POST http://localhost:5173/api/dev/seed/default-location \
  -H "content-type: application/json" \
  -d '{"owner_user_id":1,"name":"Default Lab","timezone":"America/Denver"}'</code></pre>
        <div class="hint">Then refresh this page.</div>
      </div>
    </section>
  </main>
</div>

<style>
  :root{
    --bg: #0b0d12;
    --panel: #0f172a;
    --muted: #9ca3af;
    --text: #e5e7eb;
    --ring: #1f2937;
    --kpi: #0b1224;
    --kpiLabel: #cbd5e1;
  }

  .today-page { background: var(--bg); color: var(--text); min-height: 100vh; padding-bottom: 3rem; }
  .container { max-width: 72rem; margin: 0 auto; padding: 1.5rem; }
  .title { font-size: 2rem; font-weight: 800; color: #f8fafc; }
  .subtitle { margin-top: .25rem; color: var(--muted); }

  .kpi-grid {
    margin-top: 1rem;
    display: grid;
    gap: .75rem;
    grid-template-columns: repeat(2, minmax(0,1fr));
  }
  @media (min-width: 768px){ .kpi-grid { grid-template-columns: repeat(4, minmax(0,1fr)); } }

  .kpi-card {
    background: var(--kpi);
    border: 1px solid var(--ring);
    border-radius: .75rem;
    padding: .9rem 1rem;
  }
  .kpi-label { color: var(--kpiLabel); font-weight: 600; letter-spacing: .01em; }
  .kpi-value { font-size: 1.75rem; font-weight: 800; margin-top: .1rem; }

  .card {
    background: var(--panel);
    border: 1px solid var(--ring);
    border-radius: .75rem;
    overflow: clip;
  }
  .card-head {
    display: flex; align-items: center; justify-content: space-between;
    padding: .9rem 1rem; border-bottom: 1px solid var(--ring);
    background: #0d1326;
  }
  .card-title { font-weight: 700; color: var(--text); }
  .card-body { padding: 1rem; color: var(--text); }

  .list { display: grid; gap: 8px; padding: 10px; }
  .row {
    display: grid; grid-template-columns: 1fr auto; gap: 12px;
    padding: 10px 12px; border: 1px solid var(--ring); border-radius: 8px;
    background: #0b1224;
  }
  .row .name { font-weight: 600; color: #f3f4f6; }
  .row .meta { color: var(--muted); font-variant-numeric: tabular-nums; }

  .mono {
    margin-top: .5rem;
    padding: .75rem;
    background: #0a0f1f;
    border: 1px solid var(--ring);
    border-radius: .5rem;
    color: #e2e8f0;
    overflow: auto;
  }
  .hint { margin-top: .4rem; font-size: .8rem; color: var(--muted); }
</style>
SVELTE

echo "[ok] Today page reset. Backup saved. Now run: pnpm dev"
