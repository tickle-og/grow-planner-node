<script lang="ts">
  import "../app.css";
  let { children } = $props();
</script>

<div class="min-h-screen grid grid-cols-[16rem_1fr] bg-neutral-950 text-neutral-100">
  <aside class="border-r border-neutral-800 p-4 space-y-2">
    <h1 class="text-xl font-semibold mb-4">Grow Planner</h1>
    <nav class="grid gap-1">
      <a class="px-3 py-2 rounded hover:bg-neutral-800" href="/">Today</a>
      <a class="px-3 py-2 rounded hover:bg-neutral-800" href="/batches">Batches</a>
      <a class="px-3 py-2 rounded hover:bg-neutral-800" href="/calendar">Calendar</a>
      <a class="px-3 py-2 rounded hover:bg-neutral-800" href="/recipes">Recipes</a>
      <a class="px-3 py-2 rounded hover:bg-neutral-800" href="/logs">Logs</a>
      <a class="px-3 py-2 rounded hover:bg-neutral-800" href="/reports">Reports</a>
      <a class="px-3 py-2 rounded hover:bg-neutral-800" href="/settings">Settings</a>
    </nav>
  </aside>

  <main class="p-6">
    {@render children()}
  </main>
</div>

<svelte:head>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='64' height='64'%3E%3Crect width='64' height='64' rx='12' fill='%2300e29f'/%3E%3Ctext x='50%25' y='56%25' text-anchor='middle' dominant-baseline='middle' font-size='40' fill='%230b0b0b'%3EG%3C/text%3E%3C/svg%3E" />
</svelte:head>
