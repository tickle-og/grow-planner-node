<script lang="ts">
	export let data: any;

	// Safe destructuring with sane fallbacks
	const sc = data?.statusCounts ?? { pending: 0, active: 0, completed: 0, failed: 0 };
	const actions = data?.nextActions?.items ?? [];
</script>

<div class="today mx-auto px-4 py-6">
	<header class="mb-6">
		<h1 class="text-3xl font-bold text-white">Today</h1>
		<p class="text-sm text-neutral-400">Snapshot of your lab.</p>
	</header>

	<!-- KPI band -->
	<section aria-label="Status overview" class="grid grid-cols-2 md:grid-cols-4 gap-3">
		{#each [{ label: 'Pending', value: sc.pending }, { label: 'Active', value: sc.active }, { label: 'Completed', value: sc.completed }, { label: 'Failed', value: sc.failed }] as k}
			<div class="rounded-lg border border-neutral-800 bg-neutral-900/80 px-4 py-3">
				<div class="text-[11px] uppercase tracking-wide text-neutral-400">{k.label}</div>
				<div class="text-2xl font-semibold text-white">{k.value ?? 0}</div>
			</div>
		{/each}
	</section>

	<!-- Upcoming list -->
	<section class="mt-8">
		<div class="flex items-center justify-between mb-2">
			<h2 class="text-lg font-semibold text-white">Upcoming</h2>
			<div class="text-xs text-neutral-400">auto-sorted by soonest</div>
		</div>

		{#if actions.length === 0}
			<div class="text-neutral-400 text-sm">No suggested actions right now.</div>
		{:else}
			<ul
				class="divide-y divide-neutral-800 rounded-lg border border-neutral-800 bg-neutral-900/80"
			>
				{#each actions as a}
					<li class="flex items-center gap-3 p-3">
						<input
							type="checkbox"
							aria-label="mark done"
							class="size-4 accent-emerald-500"
							on:change={() => console.log('TODO: mark done', a?.id)}
						/>
						<div class="flex-1 min-w-0">
							<div class="truncate text-white">{a?.title ?? a?.kind ?? 'Task'}</div>
							{#if a?.dueAt}
								<div class="text-xs text-neutral-400">due {new Date(a.dueAt).toLocaleString()}</div>
							{/if}
						</div>
						<button
							class="text-xs px-2 py-1 rounded border border-neutral-700 text-neutral-200 hover:bg-neutral-800"
							on:click={() => console.log('TODO: dismiss', a?.id)}>Dismiss</button
						>
					</li>
				{/each}
			</ul>
		{/if}
	</section>

	<!-- First-run tip (encode braces so Svelte doesn't parse them) -->
	<section class="mt-10">
		<div class="rounded-lg border border-neutral-800 bg-neutral-900/80 p-3">
			<div class="text-sm text-white mb-2">First-run tip</div>
			<pre class="text-xs text-neutral-200 overflow-auto"><code
					>curl -X POST http://localhost:5173/api/dev/seed/default-location \
  -H "content-type: application/json" \
  -d '&#123;"owner_user_id":1,"name":"Default Lab","timezone":"America/Denver"&#125;'</code
				></pre>
			<div class="text-[11px] text-neutral-400 mt-1">Then refresh this page.</div>
		</div>
	</section>
</div>

<style>
	/* Keep it simple: rely on global dark shell; only local tweaks here */
	.today {
		max-width: 1200px;
	}
</style>
