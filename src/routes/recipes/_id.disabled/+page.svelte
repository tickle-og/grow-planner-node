<script lang="ts">
	export let data: { recipe: any; steps: any[]; media: any };
</script>

<div class="max-w-3xl">
	<div class="flex items-center justify-between mb-3">
		<h2 class="text-2xl font-semibold">
			{data.recipe.name} <span class="text-neutral-500">v{data.recipe.version}</span>
		</h2>
		<a class="px-3 py-2 rounded bg-neutral-800 hover:bg-neutral-700" href="/recipes">Back</a>
	</div>

	{#if data.recipe.description}
		<p class="text-neutral-400 mb-4">{data.recipe.description}</p>
	{/if}

	<h3 class="font-medium mb-2">Media</h3>
	<pre class="bg-neutral-900 border border-neutral-800 rounded p-3 text-sm overflow-auto">
{JSON.stringify(data.media, null, 2)}
  </pre>

	<h3 class="font-medium mt-4 mb-2">Steps</h3>
	<ol class="list-decimal pl-6 space-y-1">
		{#each data.steps as s}
			<li>
				<span class="font-medium">{s.title}</span>
				<span class="text-neutral-400 text-sm"> ({s.duration ?? '0m'})</span>
			</li>
		{/each}
	</ol>
</div>
