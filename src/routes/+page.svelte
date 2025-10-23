<script lang="ts">
  export let data: { overdue: any[]; dueToday: any[]; upcoming: any[] };
  const fmt = (ms: number) => new Date(ms).toLocaleString();
  const short = (id: string) => id?.slice(0, 6) ?? '';
</script>

<h2 class="text-2xl font-semibold mb-4">Today</h2>

{#if data.overdue.length}
<section class="mb-6">
  <h3 class="text-lg font-medium mb-2">Overdue ({data.overdue.length})</h3>
  <ul class="space-y-2">
    {#each data.overdue as t}
      <li class="border border-neutral-800 rounded p-3 flex items-center justify-between">
        <div>
          <div class="font-medium">{t.title}</div>
          <div class="text-xs text-neutral-400">Batch: <span class="font-mono">{short(t.batchId)}</span> · {t.batchName}</div>
          <div class="text-sm text-neutral-500">Due {fmt(t.dueAt)}</div>
        </div>
        <div class="flex gap-2">
          <form method="POST" action="?/complete">
            <input type="hidden" name="id" value={t.id} />
            <button class="px-3 py-1 rounded bg-emerald-600 hover:bg-emerald-700">Done</button>
          </form>
          <form method="POST" action="?/snooze">
            <input type="hidden" name="id" value={t.id} />
            <input type="hidden" name="minutes" value="1440" />
            <button class="px-3 py-1 rounded bg-neutral-700 hover:bg-neutral-600">Snooze 24h</button>
          </form>
        </div>
      </li>
    {/each}
  </ul>
</section>
{/if}

<section class="mb-6">
  <h3 class="text-lg font-medium mb-2">Due Today ({data.dueToday.length})</h3>
  {#if data.dueToday.length === 0}
    <p class="text-neutral-400">No tasks today. Hydrate your planner with grains of wisdom.</p>
  {:else}
    <ul class="space-y-2">
      {#each data.dueToday as t}
        <li class="border border-neutral-800 rounded p-3 flex items-center justify-between">
          <div>
            <div class="font-medium">{t.title}</div>
            <div class="text-xs text-neutral-400">Batch: <span class="font-mono">{short(t.batchId)}</span> · {t.batchName}</div>
            <div class="text-sm text-neutral-500">Due {fmt(t.dueAt)}</div>
          </div>
          <div class="flex gap-2">
            <form method="POST" action="?/complete">
              <input type="hidden" name="id" value={t.id} />
              <button class="px-3 py-1 rounded bg-emerald-600 hover:bg-emerald-700">Done</button>
            </form>
            <form method="POST" action="?/snooze">
              <input type="hidden" name="id" value={t.id} />
              <input type="hidden" name="minutes" value="120" />
              <button class="px-3 py-1 rounded bg-neutral-700 hover:bg-neutral-600">Snooze 2h</button>
            </form>
          </div>
        </li>
      {/each}
    </ul>
  {/if}
</section>

<section class="mb-6">
  <h3 class="text-lg font-medium mb-2">Upcoming (48h) ({data.upcoming.length})</h3>
  <ul class="space-y-2">
    {#each data.upcoming as t}
      <li class="border border-neutral-800 rounded p-3 flex items-center justify-between">
        <div>
          <div class="font-medium">{t.title}</div>
          <div class="text-xs text-neutral-400">Batch: <span class="font-mono">{short(t.batchId)}</span> · {t.batchName}</div>
          <div class="text-sm text-neutral-500">Due {fmt(t.dueAt)}</div>
        </div>
        <form method="POST" action="?/snooze">
          <input type="hidden" name="id" value={t.id} />
          <input type="hidden" name="minutes" value="1440" />
          <button class="px-3 py-1 rounded bg-neutral-700 hover:bg-neutral-600">Snooze 24h</button>
        </form>
      </li>
    {/each}
  </ul>
</section>
