<script lang="ts">
	export let data: { batches: Array<any> };
	const fmt = (ms: number) => new Date(ms).toLocaleDateString();
</script>

<div class="max-w-4xl">
	<div class="flex items-center justify-between mb-4">
		<h2 class="text-2xl font-semibold">Batches</h2>
		<a class="px-3 py-2 rounded bg-emerald-600 hover:bg-emerald-700" href="/batches/new"
			>+ New Batch</a
		>
	</div>

	{#if data.batches.length === 0}
		<p class="text-neutral-400">No batches yet. Hit “New Batch”.</p>
	{:else}
		<div class="grid md:grid-cols-2 gap-3">
			{#each data.batches as b}
				<article class="border border-neutral-800 rounded p-3">
					<header class="flex items-center justify-between mb-1">
						<div class="font-medium">{b.name}</div>
						<span class="text-xs px-2 py-1 rounded bg-neutral-800">{b.stage}</span>
					</header>
					<div class="text-neutral-400 text-sm">Started {fmt(b.startDate)}</div>
					{#if b.targetHarvestDate}
						<div class="text-neutral-400 text-sm">Target harvest {fmt(b.targetHarvestDate)}</div>
					{/if}
				</article>
			{/each}
		</div>
	{/if}
</div>
