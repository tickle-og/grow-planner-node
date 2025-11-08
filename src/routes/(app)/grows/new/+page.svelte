<script lang="ts">
	import ContainerConfigurator from '$lib/components/ContainerConfigurator.svelte';

	let form = {
		locationId: 1,
		cultureId: null as number | null,
		recipeId: null as number | null,
		status: 'planning',
		batchCode: '',
		inoculationMethod: '',
		notes: ''
	};

	let container = {
		containerType: '',
		containerPresetKey: null as string | null,
		containerConfig: {},
		jarVariantId: null as number | null
	};

	async function submit() {
		const res = await fetch('/api/grows', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify({ ...form, ...container })
		});
		const data = await res.json();
		if (data.ok) {
			window.location.href = '/'; // back to dashboard; swap to /grows/[id] when that exists
		} else {
			alert('Failed: ' + (data.error ?? 'unknown'));
		}
	}
</script>

<section class="max-w-3xl mx-auto p-6 space-y-4">
	<h1 class="text-2xl font-bold">New Grow</h1>

	<label class="text-sm font-medium">Batch Code</label>
	<input
		class="border p-2 w-full rounded"
		bind:value={form.batchCode}
		placeholder="e.g. MT-2025-10-01"
	/>

	<label class="text-sm font-medium">Status</label>
	<select class="border p-2 w-full rounded" bind:value={form.status}>
		<option value="planning">Planning</option>
		<option value="incubating">Incubating</option>
		<option value="fruiting">Fruiting</option>
	</select>

	<label class="text-sm font-medium">Container</label>
	<ContainerConfigurator bind:value={container} on:change={(e) => (container = e.detail)} />

	<label class="text-sm font-medium">Notes</label>
	<textarea class="border p-2 w-full rounded" rows="3" bind:value={form.notes} />

	<div class="flex gap-2 pt-2">
		<button
			class="px-4 py-2 rounded bg-emerald-600 text-white hover:bg-emerald-700"
			on:click|preventDefault={submit}
		>
			Create
		</button>
		<a class="px-4 py-2 rounded border hover:bg-gray-50" href="/">Cancel</a>
	</div>
</section>
