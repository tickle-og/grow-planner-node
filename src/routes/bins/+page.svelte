<script lang="ts">
	import { onMount } from 'svelte';

	// Minimal, practical screen to stage/organize your lab bins.
	// Targets your "Default Lab" (id=1). You can make this dynamic later.
	let locationId = 1;

	// --- Types (kept simple and aligned with the API you’ve been using) ---
	type Shelf = {
		id: number;
		locationId: number;
		label: string;
		lengthCm: number | null;
		widthCm: number | null;
		heightCm: number | null;
		levels: number | null;
		createdAt: string;
	};

	type Bin = {
		id: number;
		locationId: number;
		shelfId: number | null;
		label: string;
		capacityCm2: number | null;
		createdAt: string;
	};

	// --- State ---
	let shelves: Shelf[] = [];
	let bins: Bin[] = [];

	let loadingShelves = false;
	let loadingBins = false;

	let error = '';
	let success = '';

	// Create-bin form model
	let form = {
		label: '',
		capacityCm2: 3000 as number | null,
		shelfId: null as number | null
	};

	// Per-bin assign form state (keyed by bin.id)
	const assignForm: Record<number, { growId: number | null; groupLabel: string }> = {};

	// --- Helpers ---
	function shelfLabelFor(id: number | null): string {
		if (id == null) return '—';
		const s = shelves.find((x) => x.id === id);
		return s ? s.label : `Shelf #${id}`;
	}

	function fmtDate(s: string | null | undefined): string {
		try {
			return s ? new Date(s).toLocaleString() : '—';
		} catch {
			return s ?? '—';
		}
	}

	async function safeJson(res: Response) {
		try {
			return await res.json();
		} catch {
			return null;
		}
	}

	// Accept either { ok:true, shelves:[...] } or a bare array
	function normalizeShelvesPayload(data: any): Shelf[] {
		if (Array.isArray(data)) return data as Shelf[];
		if (data && Array.isArray(data.shelves)) return data.shelves as Shelf[];
		return [];
	}

	// Accept either { ok:true, bins:[...] } or a bare array
	function normalizeBinsPayload(data: any): Bin[] {
		if (Array.isArray(data)) return data as Bin[];
		if (data && Array.isArray(data.bins)) return data.bins as Bin[];
		return [];
	}

	// --- Loaders ---
	async function loadShelves() {
		loadingShelves = true;
		try {
			const res = await fetch(`/api/locations/${locationId}/shelves`, { cache: 'no-store' });
			const data = await safeJson(res);
			if (!res.ok) throw new Error(data?.message || 'Failed to load shelves');
			shelves = normalizeShelvesPayload(data);
		} catch (e: any) {
			error = e?.message ?? String(e);
		} finally {
			loadingShelves = false;
		}
	}

	async function loadBins() {
		loadingBins = true;
		try {
			const res = await fetch(`/api/locations/${locationId}/bins`, { cache: 'no-store' });
			const data = await safeJson(res);
			if (!res.ok) throw new Error(data?.message || 'Failed to load bins');
			bins = normalizeBinsPayload(data);
			// ensure assign form slots exist
			for (const b of bins) {
				if (!assignForm[b.id]) assignForm[b.id] = { growId: null, groupLabel: '' };
			}
		} catch (e: any) {
			error = e?.message ?? String(e);
		} finally {
			loadingBins = false;
		}
	}

	// --- Actions ---
	async function createBin() {
		error = '';
		success = '';
		try {
			const payload = {
				label: form.label,
				capacityCm2: form.capacityCm2 != null ? Number(form.capacityCm2) : null,
				shelfId: form.shelfId != null ? Number(form.shelfId) : null
			};
			const res = await fetch(`/api/locations/${locationId}/bins`, {
				method: 'POST',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify(payload)
			});
			const data = await safeJson(res);
			if (!res.ok || (data && data.ok === false)) {
				throw new Error(data?.error || data?.message || 'Create failed');
			}
			success = `Bin created${data?.id ? ` (id ${data.id})` : ''}.`;
			form.label = '';
			await loadBins();
		} catch (e: any) {
			error = e?.message ?? String(e);
		}
	}

	async function assignGrow(binId: number) {
		error = '';
		success = '';
		try {
			const f = assignForm[binId] || { growId: null, groupLabel: '' };
			const payload = {
				locationId,
				growId: f.growId != null ? Number(f.growId) : null,
				groupLabel: f.groupLabel || null
			};
			if (!payload.growId) throw new Error('growId is required');

			const res = await fetch(`/api/bins/${binId}/assign`, {
				method: 'POST',
				headers: { 'content-type': 'application/json' },
				body: JSON.stringify(payload)
			});
			const data = await safeJson(res);
			if (!res.ok || (data && data.ok === false)) {
				throw new Error(data?.error || data?.message || 'Assign failed');
			}
			success = `Grow ${payload.growId} assigned to bin #${binId}.`;
			// clear only label, keep growId for quick multi-assigns if desired
			assignForm[binId].groupLabel = '';
		} catch (e: any) {
			error = e?.message ?? String(e);
		}
	}

	function refreshAll() {
		success = '';
		error = '';
		// parallel loads are fine; different endpoints
		loadShelves();
		loadBins();
	}

	onMount(() => {
		refreshAll();
	});
</script>

<div class="max-w-4xl mx-auto p-4">
	<div class="flex items-center justify-between mb-4">
		<h1 class="text-2xl font-semibold">Bins @ Location #{locationId}</h1>
		<button
			class="border rounded px-3 py-2 text-sm"
			on:click={refreshAll}
			aria-label="Refresh bins and shelves"
		>
			Refresh
		</button>
	</div>

	{#if error}
		<div class="mb-3 p-3 rounded border border-red-300 bg-red-50 text-red-800">{error}</div>
	{/if}
	{#if success}
		<div class="mb-3 p-3 rounded border border-green-300 bg-green-50 text-green-800">{success}</div>
	{/if}

	<!-- Create Bin -->
	<form class="grid gap-3 mb-6" on:submit|preventDefault={createBin}>
		<div>
			<label class="block text-sm mb-1" for="label">Bin label</label>
			<input id="label" class="w-full border rounded px-3 py-2" bind:value={form.label} required />
		</div>

		<div class="grid grid-cols-3 gap-3">
			<div>
				<label class="block text-sm mb-1" for="cap">Capacity (cm²)</label>
				<input
					id="cap"
					type="number"
					class="w-full border rounded px-3 py-2"
					bind:value={form.capacityCm2}
					min="0"
				/>
			</div>

			<div class="col-span-2">
				<label class="block text-sm mb-1" for="shelf">Shelf</label>
				<select id="shelf" class="w-full border rounded px-3 py-2" bind:value={form.shelfId}>
					<option value={null}>— None —</option>
					{#each shelves as s}
						<option value={s.id}>{s.label} (#{s.id})</option>
					{/each}
				</select>
				{#if loadingShelves}
					<div class="text-xs text-gray-500 mt-1">Loading shelves…</div>
				{/if}
			</div>
		</div>

		<button
			class="inline-flex items-center gap-2 border rounded px-4 py-2"
			disabled={!form.label}
			on:click|preventDefault={createBin}
		>
			Create bin
		</button>
	</form>

	<!-- Bins list -->
	<div class="mb-2 text-sm text-gray-600">
		{#if loadingBins}
			Loading bins…
		{:else}
			{bins.length} bin{bins.length === 1 ? '' : 's'}
		{/if}
	</div>

	<div class="grid gap-3">
		{#each bins as b}
			<div class="border rounded p-3">
				<div class="flex items-center justify-between">
					<div>
						<div class="font-medium">
							{b.label} <span class="text-xs text-gray-500">#{b.id}</span>
						</div>
						<div class="text-sm text-gray-700">
							Shelf: {shelfLabelFor(b.shelfId)} · Capacity: {b.capacityCm2 ?? '—'} cm²
						</div>
						<div class="text-xs text-gray-500">Created {fmtDate(b.createdAt)}</div>
					</div>
				</div>

				<!-- Inline assign form -->
				<div class="mt-3 border-t pt-3">
					<div class="text-sm font-medium mb-2">Assign grow to this bin</div>
					<div class="grid grid-cols-3 gap-3 items-end">
						<div>
							<label class="block text-sm mb-1" for={'grow-' + b.id}>Grow ID</label>
							<input
								id={'grow-' + b.id}
								type="number"
								class="w-full border rounded px-3 py-2"
								bind:value={assignForm[b.id].growId}
								min="1"
								placeholder="e.g., 1"
							/>
						</div>
						<div class="col-span-2">
							<label class="block text-sm mb-1" for={'group-' + b.id}>Group label (optional)</label>
							<input
								id={'group-' + b.id}
								class="w-full border rounded px-3 py-2"
								bind:value={assignForm[b.id].groupLabel}
								placeholder="Batch A"
							/>
						</div>
					</div>
					<button
						class="mt-3 inline-flex items-center gap-2 border rounded px-3 py-2 text-sm"
						on:click|preventDefault={() => assignGrow(b.id)}
						disabled={!assignForm[b.id]?.growId}
					>
						Assign to bin #{b.id}
					</button>
				</div>
			</div>
		{/each}

		{#if !loadingBins && bins.length === 0}
			<div class="text-sm text-gray-600">No bins yet. Add one above.</div>
		{/if}
	</div>
</div>
