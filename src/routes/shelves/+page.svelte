<script lang="ts">
  import { onMount } from 'svelte';

  // For now we target your Default Lab (id=1). You can make this dynamic later.
  let locationId = 1;

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

  let shelves: Shelf[] = [];
  let loading = false;
  let creating = false;
  let error = '';
  let success = '';

  // form model
  let form = {
    label: '',
    lengthCm: 120,
    widthCm: 45,
    heightCm: 200,
    levels: 4
  };

  async function loadShelves() {
    loading = true; error = ''; success = '';
    try {
      const res = await fetch(`/api/locations/${locationId}/shelves`);
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data?.message || 'Failed to load shelves');
      }
      // API returns { ok: true, shelves: [...] }
      shelves = data.shelves ?? [];
    } catch (e: any) {
      error = e?.message ?? String(e);
    } finally {
      loading = false;
    }
  }

  async function createShelf() {
    creating = true; error = ''; success = '';
    try {
      const payload = {
        label: form.label,
        lengthCm: Number(form.lengthCm) || null,
        widthCm: Number(form.widthCm) || null,
        heightCm: Number(form.heightCm) || null,
        levels: Number(form.levels) || 1
      };
      const res = await fetch(`/api/locations/${locationId}/shelves`, {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(payload)
      });
      const data = await res.json();
      if (!res.ok || !data.ok) {
        throw new Error(data?.error || data?.message || 'Create failed');
      }
      success = `Shelf #${data.id} created`;
      form.label = '';
      await loadShelves();
    } catch (e: any) {
      error = e?.message ?? String(e);
    } finally {
      creating = false;
    }
  }

  onMount(() => {
    // Don’t fetch during SSR—only in the browser.
    loadShelves();
  });
</script>

<!-- super lightweight styling via utility classes; works fine without Tailwind too -->
<div class="max-w-3xl mx-auto p-4">
  <h1 class="text-2xl font-semibold mb-4">Shelves @ Location #{locationId}</h1>

  {#if error}
    <div class="mb-3 p-3 rounded border border-red-300 bg-red-50 text-red-800">{error}</div>
  {/if}
  {#if success}
    <div class="mb-3 p-3 rounded border border-green-300 bg-green-50 text-green-800">{success}</div>
  {/if}

  <form class="grid gap-3 mb-6" on:submit|preventDefault={createShelf}>
    <div>
      <label class="block text-sm mb-1" for="label">Label</label>
      <input id="label" class="w-full border rounded px-3 py-2" bind:value={form.label} required />
    </div>

    <div class="grid grid-cols-3 gap-3">
      <div>
        <label class="block text-sm mb-1" for="len">Length (cm)</label>
        <input id="len" type="number" class="w-full border rounded px-3 py-2" bind:value={form.lengthCm} />
      </div>
      <div>
        <label class="block text-sm mb-1" for="wid">Width (cm)</label>
        <input id="wid" type="number" class="w-full border rounded px-3 py-2" bind:value={form.widthCm} />
      </div>
      <div>
        <label class="block text-sm mb-1" for="ht">Height (cm)</label>
        <input id="ht" type="number" class="w-full border rounded px-3 py-2" bind:value={form.heightCm} />
      </div>
    </div>

    <div class="w-32">
      <label class="block text-sm mb-1" for="levels">Levels</label>
      <input id="levels" type="number" class="w-full border rounded px-3 py-2" min="1" bind:value={form.levels} />
    </div>

    <button class="inline-flex items-center gap-2 border rounded px-4 py-2"
            on:click|preventDefault={createShelf}
            disabled={creating || !form.label}>
      {#if creating}…{/if} Create shelf
    </button>
  </form>

  <div class="mb-2 text-sm text-gray-600">{loading ? 'Loading shelves…' : `${shelves.length} shelf(es)`}</div>
  <div class="grid gap-2">
    {#each shelves as s}
      <div class="border rounded p-3">
        <div class="font-medium">{s.label} <span class="text-xs text-gray-500">#{s.id}</span></div>
        <div class="text-sm text-gray-700">
          {s.lengthCm ?? '—'}×{s.widthCm ?? '—'}×{s.heightCm ?? '—'} cm · levels: {s.levels ?? '—'}
        </div>
        <div class="text-xs text-gray-500">Created {s.createdAt}</div>
      </div>
    {/each}
    {#if !loading && shelves.length === 0}
      <div class="text-sm text-gray-600">No shelves yet. Add one above.</div>
    {/if}
  </div>
</div>
