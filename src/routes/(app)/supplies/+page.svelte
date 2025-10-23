<script lang="ts">
  export let data: { items: Array<{id:number;name:string;unit:string;onHandQty:number;costPerUnit:number}> };
</script>

<h1 class="text-xl font-semibold mb-4">Supplies</h1>

<form method="POST" class="mb-6 flex gap-2">
  <input name="name" placeholder="Name" required class="border px-2 py-1" />
  <input name="unit" placeholder="Unit (g|kg|L|qt)" required class="border px-2 py-1" />
  <input name="onHandQty" placeholder="Qty" type="number" step="any" class="border px-2 py-1" />
  <input name="costPerUnit" placeholder="Cost/Unit" type="number" step="any" class="border px-2 py-1" />
  <button class="border px-3 py-1">Add</button>
</form>

<table class="min-w-full border">
  <thead>
    <tr class="bg-gray-100">
      <th class="text-left px-3 py-2 border-b">ID</th>
      <th class="text-left px-3 py-2 border-b">Name</th>
      <th class="text-left px-3 py-2 border-b">Qty</th>
      <th class="text-left px-3 py-2 border-b">Unit</th>
      <th class="text-left px-3 py-2 border-b">Cost/Unit</th>
    </tr>
  </thead>
  <tbody>
    {#each data.items as s}
    <tr>
      <td class="px-3 py-2 border-b">{s.id}</td>
      <td class="px-3 py-2 border-b">{s.name}</td>
      <td class="px-3 py-2 border-b">{s.onHandQty}</td>
      <td class="px-3 py-2 border-b">{s.unit}</td>
      <td class="px-3 py-2 border-b">${s.costPerUnit?.toFixed?.(2) ?? '0.00'}</td>
    </tr>
    {/each}
  </tbody>
</table>
