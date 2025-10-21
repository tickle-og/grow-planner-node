<script lang="ts">
  export let data: {
    windowStart: number;
    days: number[];
    groups: Array<{ batchId: string; batchName: string; tasks: any[] }>;
  };

  const DAY = 24 * 60 * 60 * 1000;
  const short = (id: string) => id?.slice(0, 6) ?? '';

  function dayIndex(ts: number) {
    return Math.max(0, Math.floor((ts - data.windowStart) / DAY));
  }

  function spanDays(dueAt: number, durationMin: number) {
    const durMs = Math.max(60_000, (durationMin ?? 60) * 60_000);
    const start = dueAt - durMs;
    const span = Math.max(1, Math.ceil(durMs / DAY));
    return { startIdx: dayIndex(start), span };
  }

  function monthHeaderParts(dayTs: number) {
    const d = new Date(dayTs);
    return {
      month: d.toLocaleString(undefined, { month: 'short' }),
      day: d.getDate()
    };
  }
</script>

<h2 class="text-2xl font-semibold mb-4">Calendar (2-month Gantt)</h2>

<div class="overflow-x-auto border border-neutral-800 rounded">
  <div class="min-w-[1100px]">
    <!-- Month header -->
    <div class="grid sticky top-0 z-10" style={`grid-template-columns: 16rem repeat(${data.days.length}, 40px);`}>
      <div class="px-3 py-2 border-b border-neutral-800 bg-neutral-900 font-medium">
        Batch
      </div>
      {#each data.days as d, i}
        {#if monthHeaderParts(d).day === 1 || i === 0}
          <div class="px-2 py-2 text-xs text-neutral-200 border-b border-neutral-800 bg-neutral-900 col-[span_1]">
            {monthHeaderParts(d).month}
          </div>
        {:else}
          <div class="border-b border-neutral-800 bg-neutral-900"></div>
        {/if}
      {/each}
    </div>

    <!-- Day header -->
    <div class="grid" style={`grid-template-columns: 16rem repeat(${data.days.length}, 40px);`}>
      <div class="px-3 py-2 border-b border-neutral-900 bg-neutral-950 text-xs text-neutral-400">Task timeline</div>
      {#each data.days as d, i}
        <div class="px-2 py-2 text-[11px] text-neutral-500 border-b border-neutral-900 bg-neutral-950 text-center
                    {new Date(d).getDay() === 0 || new Date(d).getDay() === 6 ? 'bg-neutral-900/60' : ''}">
          {monthHeaderParts(d).day}
        </div>
      {/each}
    </div>

    <!-- Grid + Rows -->
    {#each data.groups as g}
      <div class="grid relative" style={`grid-template-columns: 16rem repeat(${data.days.length}, 40px);`}>
        <!-- Left label -->
        <div class="px-3 py-3 border-t border-neutral-900 bg-neutral-950">
          <div class="font-medium">{g.batchName}</div>
          <div class="text-[11px] text-neutral-500 font-mono">{short(g.batchId)}</div>
        </div>

        <!-- Background day grid -->
        {#each data.days as d}
          <div class="border-l border-neutral-900 relative
                      {new Date(d).getDay() === 0 || new Date(d).getDay() === 6 ? 'bg-neutral-900/40' : ''}">
          </div>
        {/each}

        <!-- Bars (placed via CSS grid columns) -->
        {#each g.tasks as t}
          {#key t.id}
            {#await Promise.resolve(spanDays(t.dueAt, t.durationMin)) then p}
              <!-- milestone (0m) as a diamond -->
              {#if t.durationMin === 0}
                <div style={`grid-column: ${p.startIdx + 2} / span 1;`} class="pointer-events-auto">
                  <div class="w-2.5 h-2.5 rotate-45 bg-amber-400 border border-amber-300 shadow
                              mt-2 translate-x-[-6px]" title={`${t.title}`}></div>
                </div>
              {:else}
                <div style={`grid-column: ${p.startIdx + 2} / span ${p.span};`} class="pointer-events-auto">
                  <div
                    class="rounded-md text-[11px] px-2 py-1 truncate border shadow-sm mt-1.5
                           bg-emerald-700/80 border-emerald-500/50 hover:bg-emerald-600/80"
                    title={`${t.title}`}
                  >
                    {t.title}
                  </div>
                </div>
              {/if}
            {/await}
          {/key}
        {/each}
      </div>
    {/each}
  </div>
</div>
