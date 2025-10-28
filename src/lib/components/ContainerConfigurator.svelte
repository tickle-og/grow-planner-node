<script lang="ts">
  import { onMount, createEventDispatcher } from "svelte";
  const dispatch = createEventDispatcher();

  export let value: {
    containerType?: string;
    containerPresetKey?: string | null;
    containerConfig?: Record<string, any>;
    jarVariantId?: number | null;
  } = {};

  let presets: Array<{ key: string; containerType: string; label: string; defaults: any }> = [];
  let jars: Array<{ id:number; label:string; sizeMl:number; mouth:string; heightMm:number; diameterMm:number }> = [];

  let selectedType = value.containerType ?? "";
  let selectedPreset: string | null = value.containerPresetKey ?? null;
  let cfg: any = value.containerConfig ?? {};
  let jarVariantId: number | null = value.jarVariantId ?? null;

  async function loadCatalog() {
    const [p, j] = await Promise.all([
      fetch("/api/catalog/container-presets").then(r=>r.json()).then((rows)=>rows.map((r:any)=>({ ...r, defaults: JSON.parse(r.defaultsJson) }))),
      fetch("/api/catalog/jar-variants").then(r=>r.json())
    ]);
    presets = p; jars = j;
  }
  onMount(loadCatalog);

  function emit() {
    dispatch("change", { containerType: selectedType, containerPresetKey: selectedPreset, containerConfig: cfg, jarVariantId });
  }

  $: emit(); // keep parent in sync
</script>

<div class="space-y-3">
  <label class="block text-sm font-medium">Container Type</label>
  <select class="border rounded p-2 w-full" bind:value={selectedType} on:change={() => { selectedPreset = null; cfg = {}; jarVariantId = null; }}>
    <option value="" disabled>Select…</option>
    <option value="monotub">Monotub</option>
    <option value="tray">Tray/Shoebox</option>
    <option value="bag">Filter bag</option>
    <option value="jar">Jar</option>
  </select>

  {#if selectedType && selectedType !== 'jar'}
    <label class="block text-sm font-medium mt-2">Preset</label>
    <select class="border rounded p-2 w-full" bind:value={selectedPreset} on:change={() => {
      const p = presets.find(x => x.key === selectedPreset);
      cfg = p?.defaults ? structuredClone(p.defaults) : {};
    }}>
      <option value={null}>— none —</option>
      {#each presets.filter(p => p.containerType === selectedType && p.active) as p}
        <option value={p.key}>{p.label}</option>
      {/each}
    </select>

    <!-- Dimension fields appear for monotub/tray -->
    {#if selectedType === 'monotub' || selectedType === 'tray'}
      <div class="grid grid-cols-3 gap-3 mt-2">
        <div><label class="text-xs">Length (cm)</label><input class="border p-2 w-full" type="number" bind:value={cfg.length_cm}></div>
        <div><label class="text-xs">Width (cm)</label><input class="border p-2 w-full" type="number" bind:value={cfg.width_cm}></div>
        <div><label class="text-xs">Height (cm)</label><input class="border p-2 w-full" type="number" bind:value={cfg.height_cm}></div>
      </div>
      <div class="mt-2">
        <label class="text-xs">Filter</label>
        <select class="border p-2 w-full" bind:value={cfg.filter}>
          <option value="">—</option>
          <option value="hepa_sticker">HEPA sticker</option>
          <option value="polyfill">Polyfill</option>
          <option value="filter_patch">Filter patch</option>
        </select>
      </div>
    {/if}

    {#if selectedType === 'bag'}
      <div class="grid grid-cols-3 gap-3 mt-2">
        <div><label class="text-xs">Volume (L)</label><input class="border p-2 w-full" type="number" step="0.1" bind:value={cfg.volume_l}></div>
        <div><label class="text-xs">Patch (mm)</label><input class="border p-2 w-full" type="number" bind:value={cfg.filter_patch_size_mm}></div>
        <div><label class="text-xs">Thickness (mil)</label><input class="border p-2 w-full" type="number" bind:value={cfg.thickness_mil}></div>
      </div>
    {/if}
  {/if}

  {#if selectedType === 'jar'}
    <label class="block text-sm font-medium mt-2">Jar Variant</label>
    <select class="border rounded p-2 w-full" bind:value={jarVariantId}>
      <option value={null} disabled>Select jar</option>
      {#each jars as j}
        <option value={j.id}>{j.label} — {j.sizeMl} ml · {j.mouth}</option>
      {/each}
    </select>
    <div class="grid grid-cols-3 gap-3 mt-2">
      <div><label class="text-xs">Lid</label>
        <select class="border p-2 w-full" bind:value={cfg.lid}>
          <option value="">—</option>
          <option>plastic</option><option>aluminum</option><option>stainless</option>
        </select>
      </div>
      <div><label class="text-xs">Mouth</label>
        <select class="border p-2 w-full" bind:value={cfg.mouth}>
          <option value="">auto from variant</option>
          <option>wide</option><option>narrow</option>
        </select>
      </div>
      <div><label class="text-xs">Filter</label>
        <select class="border p-2 w-full" bind:value={cfg.filter}>
          <option value="">—</option>
          <option value="hepa_sticker">HEPA sticker</option>
          <option value="polyfill">Polyfill</option>
          <option value="filter_patch">Filter patch</option>
        </select>
      </div>
    </div>
  {/if}
</div>
