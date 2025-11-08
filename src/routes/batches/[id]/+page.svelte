<script lang="ts">
	export let data: {
		batch: any;
		tasks: any[];
		logs: any[];
		yields: any[];
	};
	const fmt = (ms: number) => new Date(ms).toLocaleString();
</script>

<div class="max-w-5xl space-y-8">
	<header class="flex items-start justify-between">
		<div>
			<h2 class="text-2xl font-semibold">{data.batch.name}</h2>
			<div class="text-neutral-400 text-sm">
				Stage: {data.batch.stage} · Started {new Date(data.batch.startDate).toLocaleDateString()}
			</div>
		</div>
		<a href="/batches" class="px-3 py-2 rounded bg-neutral-800 hover:bg-neutral-700">Back</a>
	</header>

	<!-- Tasks summary -->
	<section>
		<h3 class="font-medium mb-2">Tasks</h3>
		{#if data.tasks.length === 0}
			<p class="text-neutral-400">No tasks yet.</p>
		{:else}
			<ul class="space-y-1">
				{#each data.tasks as t}
					<li class="border border-neutral-800 rounded p-2 flex items-center justify-between">
						<div>
							<div class="font-medium">{t.title}</div>
							<div class="text-xs text-neutral-500">Due {fmt(t.dueAt)}</div>
						</div>
						<span class="text-xs px-2 py-1 rounded bg-neutral-800">{t.status}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</section>

	<!-- Logs -->
	<section class="grid md:grid-cols-2 gap-6">
		<div>
			<h3 class="font-medium mb-2">Add Log</h3>
			<form method="POST" action="?/add_log" class="grid gap-3">
				<div>
					<label class="block text-sm text-neutral-400 mb-1">Kind</label>
					<select
						name="kind"
						class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700"
					>
						<option value="note">Note</option>
						<option value="env">Environment</option>
					</select>
				</div>
				<div>
					<label class="block text-sm text-neutral-400 mb-1">Text (for Note)</label>
					<textarea
						name="text"
						rows="2"
						class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700"
					></textarea>
				</div>
				<div class="grid grid-cols-3 gap-2">
					<div>
						<label class="block text-xs text-neutral-400 mb-1">Temp (°F/°C)</label>
						<input
							name="temp"
							type="number"
							step="0.1"
							class="w-full px-2 py-1 rounded bg-neutral-900 border border-neutral-700"
						/>
					</div>
					<div>
						<label class="block text-xs text-neutral-400 mb-1">RH (%)</label>
						<input
							name="rh"
							type="number"
							step="0.1"
							class="w-full px-2 py-1 rounded bg-neutral-900 border border-neutral-700"
						/>
					</div>
					<div>
						<label class="block text-xs text-neutral-400 mb-1">CO₂ (ppm)</label>
						<input
							name="co2"
							type="number"
							step="1"
							class="w-full px-2 py-1 rounded bg-neutral-900 border border-neutral-700"
						/>
					</div>
				</div>
				<div class="flex gap-2">
					<button class="px-3 py-2 rounded bg-emerald-600 hover:bg-emerald-700" type="submit"
						>Add Log</button
					>
				</div>
			</form>
		</div>

		<div>
			<h3 class="font-medium mb-2">Logs</h3>
			{#if data.logs.length === 0}
				<p class="text-neutral-400">No logs recorded.</p>
			{:else}
				<ul class="space-y-2">
					{#each data.logs as l}
						<li class="border border-neutral-800 rounded p-2">
							<div class="text-xs text-neutral-500">{fmt(l.createdAt)} · {l.kind}</div>
							<pre
								class="text-sm bg-neutral-900 border border-neutral-800 rounded p-2 overflow-auto">{l.payload}</pre>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	</section>

	<!-- Yields -->
	<section class="grid md:grid-cols-2 gap-6">
		<div>
			<h3 class="font-medium mb-2">Add Yield</h3>
			<form method="POST" action="?/add_yield" class="grid gap-3">
				<div class="grid grid-cols-3 gap-2">
					<div>
						<label class="block text-xs text-neutral-400 mb-1">Flush #</label>
						<input
							name="flushNo"
							type="number"
							min="1"
							value="1"
							class="w-full px-2 py-1 rounded bg-neutral-900 border border-neutral-700"
						/>
					</div>
					<div>
						<label class="block text-xs text-neutral-400 mb-1">Wet Weight (g)</label>
						<input
							name="wetWeightG"
							type="number"
							min="0"
							step="1"
							class="w-full px-2 py-1 rounded bg-neutral-900 border border-neutral-700"
						/>
					</div>
					<div>
						<label class="block text-xs text-neutral-400 mb-1">Dry Weight (g)</label>
						<input
							name="dryWeightG"
							type="number"
							min="0"
							step="1"
							class="w-full px-2 py-1 rounded bg-neutral-900 border border-neutral-700"
						/>
					</div>
				</div>
				<div>
					<label class="block text-sm text-neutral-400 mb-1">Notes</label>
					<textarea
						name="notes"
						rows="2"
						class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700"
					></textarea>
				</div>
				<div class="flex gap-2">
					<button class="px-3 py-2 rounded bg-emerald-600 hover:bg-emerald-700" type="submit"
						>Add Yield</button
					>
				</div>
			</form>
		</div>

		<div>
			<h3 class="font-medium mb-2">Yields</h3>
			{#if data.yields.length === 0}
				<p class="text-neutral-400">No yields recorded.</p>
			{:else}
				<ul class="space-y-2">
					{#each data.yields as y}
						<li class="border border-neutral-800 rounded p-2">
							<div class="text-xs text-neutral-500">{fmt(y.createdAt)}</div>
							<div class="text-sm">
								Flush #{y.flushNo} · Wet: {y.wetWeightG}g {#if y.dryWeightG}· Dry: {y.dryWeightG}g{/if}
							</div>
							{#if y.notes}<div class="text-neutral-400 text-sm">{y.notes}</div>{/if}
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	</section>
</div>
