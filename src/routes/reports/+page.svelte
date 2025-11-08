<script lang="ts">
	export let data;
	const { locationId } = data ?? { locationId: 1 };

	// Client fetch helpers (SSR-free) so this page stays responsive
	const j = (r: Response) => r.json();
	const qs = (obj: Record<string, string | number>) =>
		Object.entries(obj)
			.map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
			.join('&');

	let lowStock: any = { rows: [] };
	let recentYields: any = { rows: [], totals: { wetWeightG: 0, dryWeightG: 0 } };
	let shelfUtil: any = { rows: [] };
	let nextActions: any = { actions: [] };

	async function loadAll() {
		const params = `location_id=${locationId}`;
		try {
			lowStock = await fetch(`/api/dashboard/low-stock?${params}`).then(j);
		} catch {}
		try {
			recentYields = await fetch(`/api/dashboard/recent-yields?${params}`).then(j);
		} catch {}
		try {
			shelfUtil = await fetch(`/api/dashboard/shelf-util?${params}`).then(j);
		} catch {}
		try {
			nextActions = await fetch(`/api/dashboard/next-actions?${params}`).then(j);
		} catch {}
	}
	loadAll();
</script>

<div class="reports-page">
	<header class="mx-auto max-w-6xl px-4 pt-8">
		<h1 class="text-3xl font-extrabold tracking-tight text-slate-900">Reports</h1>
		<p class="mt-1 text-base text-slate-700">Inventory, utilization, yields, and upcoming work.</p>
	</header>

	<section class="mx-auto max-w-6xl px-4 mt-6 grid gap-4 md:grid-cols-2">
		<div class="card">
			<h2>Low stock</h2>
			{#if lowStock?.rows?.length}
				<ul>
					{#each lowStock.rows as item}
						<li><strong>{item.name}</strong> — {item.qty} {item.unit}</li>
					{/each}
				</ul>
			{:else}
				<div>No low-stock alerts.</div>
			{/if}
		</div>

		<div class="card">
			<h2>Recent yields</h2>
			{#if recentYields?.rows?.length}
				<ul>
					{#each recentYields.rows as y}
						<li>{y.date}: {y.dryWeightG ?? 0} g dry ({y.wetWeightG ?? 0} g wet)</li>
					{/each}
				</ul>
			{:else}
				<div>No recent yields.</div>
			{/if}
		</div>

		<div class="card">
			<h2>Shelf utilization</h2>
			{#if shelfUtil?.rows?.length}
				<ul>
					{#each shelfUtil.rows as r}
						<li>Shelf {r.shelfLabel}: {r.used}/{r.capacity} used</li>
					{/each}
				</ul>
			{:else}
				<div>No utilization data.</div>
			{/if}
		</div>

		<div class="card">
			<h2>Upcoming tasks</h2>
			{#if nextActions?.actions?.length}
				<ul>
					{#each nextActions.actions as a}
						<li>{a.when ?? a.dueAt ?? 'soon'} — {a.title ?? a.kind}</li>
					{/each}
				</ul>
			{:else}
				<div>No upcoming tasks.</div>
			{/if}
		</div>
	</section>
</div>

<style>
	.reports-page {
		--card-bg: #0b1020;
		--ink: #e6eaf2;
		--muted: #9aa4b2;
	}
	.reports-page {
		background: #070b16;
		color: var(--ink);
		min-height: 100%;
		padding-bottom: 4rem;
	}
	.card {
		background: var(--card-bg);
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 14px;
		padding: 16px 16px 12px;
	}
	h2 {
		font-weight: 700;
		font-size: 14px;
		letter-spacing: 0.04em;
		text-transform: uppercase;
		color: var(--ink);
		opacity: 0.9;
		margin-bottom: 8px;
	}
	ul {
		margin: 0;
		padding-left: 1rem;
	}
	li {
		color: var(--ink);
		opacity: 0.95;
	}
	.mx-auto {
		margin-left: auto;
		margin-right: auto;
	}
	.max-w-6xl {
		max-width: 72rem;
	}
	.px-4 {
		padding-left: 1rem;
		padding-right: 1rem;
	}
	.pt-8 {
		padding-top: 2rem;
	}
	.mt-6 {
		margin-top: 1.5rem;
	}
	.grid {
		display: grid;
	}
	.gap-4 {
		gap: 1rem;
	}
	@media (min-width: 768px) {
		.md\:grid-cols-2 {
			grid-template-columns: repeat(2, minmax(0, 1fr));
		}
	}
</style>
