<script lang="ts">
  export let form: any;

  // Grain-first defaults
  const exampleSteps = [
    { key: "hydrate_grain",   title: "Hydrate grain",                 duration: "12h" },
    { key: "sterilize_grain", title: "Sterilize grain (PC 120m)",     duration: "2h",  depends_on: ["hydrate_grain"] },
    { key: "cool",            title: "Cool down",                      duration: "8h",  depends_on: ["sterilize_grain"] },
    { key: "inoc",            title: "Inoculate LC → grain",           duration: "0m",  depends_on: ["cool"] },
    { key: "spawn",           title: "Spawn to bulk",                  duration: "14d", depends_on: ["inoc"] },
    { key: "fruit",           title: "Open for fruiting",              duration: "4d",  depends_on: ["spawn"] },
    { key: "harvest",         title: "Harvest (flush #1)",             duration: "0m",  depends_on: ["fruit"] }
  ];
  const exampleMedia = { grain: "milo", bulk_substrate: "coir/verm/gypsum" };
</script>

<div class="max-w-3xl">
  <h2 class="text-2xl font-semibold mb-4">New Recipe</h2>

  {#if form?.error}
    <div class="mb-3 rounded border border-red-700 bg-red-900/40 p-3 text-red-200">{form.error}</div>
  {/if}

  <form method="POST" action="?/create" class="grid gap-4">
    <div>
      <label class="block text-sm text-neutral-400 mb-1">Name</label>
      <input name="name" required class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700" placeholder="Monotub 3.5 lb Flow" />
    </div>

    <div>
      <label class="block text-sm text-neutral-400 mb-1">Description</label>
      <textarea name="description" class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700" rows="2" placeholder="Your SOP notes..."></textarea>
    </div>

    <div class="grid grid-cols-2 gap-4">
      <div>
        <label class="block text-sm text-neutral-400 mb-1">Default Scale</label>
        <input name="defaultScale" type="number" min="1" value="20" class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700" />
      </div>
      <div>
        <label class="block text-sm text-neutral-400 mb-1">Media JSON</label>
        <textarea name="media_json" class="w-full h-[110px] px-3 py-2 rounded bg-neutral-900 border border-neutral-700">{JSON.stringify(exampleMedia, null, 2)}</textarea>
      </div>
    </div>

    <div>
      <label class="block text-sm text-neutral-400 mb-1">Steps JSON</label>
      <textarea name="steps_json" class="w-full h-60 px-3 py-2 rounded bg-neutral-900 border border-neutral-700">{JSON.stringify(exampleSteps, null, 2)}</textarea>
      <p class="text-xs text-neutral-500 mt-1">
        Array of steps with <code>key</code>, <code>title</code>, <code>duration</code> (e.g., "14d", "120m"), and optional <code>depends_on</code>.
      </p>
    </div>

    <div class="flex gap-2">
      <a href="/recipes" class="px-3 py-2 rounded bg-neutral-800 hover:bg-neutral-700">Cancel</a>
      <button class="px-3 py-2 rounded bg-emerald-600 hover:bg-emerald-700" type="submit">Create Recipe</button>
    </div>
  </form>
</div>
