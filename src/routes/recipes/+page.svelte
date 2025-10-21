<script lang="ts">
  export let data: { recipes: Array<any> };
</script>

<div class="max-w-3xl">
  <div class="flex items-center justify-between mb-4">
    <h2 class="text-2xl font-semibold">Recipes</h2>
    <a class="px-3 py-2 rounded bg-emerald-600 hover:bg-emerald-700" href="/recipes/new">+ New Recipe</a>
  </div>

  {#if data.recipes.length === 0}
    <p class="text-neutral-400">No recipes yet. Click “New Recipe”.</p>
  {:else}
    <ul class="space-y-2">
      {#each data.recipes as r}
        <li class="border border-neutral-800 rounded p-3">
          <div class="flex items-center justify-between">
            <div>
              <div class="font-medium">{r.name} <span class="text-neutral-500">v{r.version}</span></div>
              {#if r.description}<div class="text-neutral-400 text-sm">{r.description}</div>{/if}
            </div>
            <a class="px-3 py-1 rounded bg-neutral-800 hover:bg-neutral-700" href={"/recipes/" + r.id}>Open</a>
          </div>
        </li>
      {/each}
    </ul>
  {/if}
</div>
