<script lang="ts">
	export let data: { recipes: Array<any> };
	export let form: any;
	const today = new Date().toISOString().slice(0, 10);
</script>

<div class="max-w-2xl">
	<h2 class="text-2xl font-semibold mb-4">New Batch</h2>

	{#if form?.error}
		<div class="mb-3 rounded border border-red-700 bg-red-900/40 p-3 text-red-200">
			{form.error}
		</div>
	{/if}

	<form method="POST" action="?/create" class="grid gap-4">
		<div>
			<label class="block text-sm text-neutral-400 mb-1">Batch Name</label>
			<input
				name="name"
				required
				class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700"
				placeholder="Batch #25"
			/>
		</div>

		<div>
			<label class="block text-sm text-neutral-400 mb-1">Recipe</label>
			<select
				name="recipeId"
				class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700"
			>
				{#each data.recipes as r}
					<option value={r.id}>{r.name} (v{r.version})</option>
				{/each}
			</select>
			{#if data.recipes.length === 0}
				<p class="text-sm text-yellow-400 mt-1">
					No recipes yet — create one first at <a class="underline" href="/recipes/new"
						>/recipes/new</a
					>.
				</p>
			{/if}
		</div>

		<div class="grid grid-cols-2 gap-4">
			<div>
				<label class="block text-sm text-neutral-400 mb-1">Quantity (units)</label>
				<input
					type="number"
					min="1"
					name="qtyUnits"
					value="20"
					class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700"
				/>
			</div>
			<div>
				<label class="block text-sm text-neutral-400 mb-1">Start Date</label>
				<input
					type="date"
					name="startDate"
					value={today}
					class="w-full px-3 py-2 rounded bg-neutral-900 border border-neutral-700"
				/>
			</div>
		</div>

		<div class="flex gap-2">
			<a class="px-3 py-2 rounded bg-neutral-800 hover:bg-neutral-700" href="/batches">Cancel</a>
			<button class="px-3 py-2 rounded bg-emerald-600 hover:bg-emerald-700" type="submit"
				>Create Batch</button
			>
		</div>
	</form>
</div>
