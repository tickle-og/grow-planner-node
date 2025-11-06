# scripts/layout-2col-and-active-nav.sh
#!/usr/bin/env bash
set -euo pipefail

LAYOUT="src/routes/+layout.svelte"
APPCSS="src/app.css"
ts=$(date +%Y%m%d-%H%M%S)

[[ -f "$LAYOUT" ]] && cp -p "$LAYOUT" "$LAYOUT.bak.$ts" && echo "[backup] $LAYOUT -> $LAYOUT.bak.$ts"

# Ensure global CSS still imports Tailwind (safe if already present)
if [[ -f "$APPCSS" ]] && ! grep -q '@import "tailwindcss";' "$APPCSS"; then
  sed -i '1i @import "tailwindcss";\n@source "./src/**/*.{svelte,ts,js,html}";\n@reference "tailwindcss/utilities";\n' "$APPCSS"
fi

cat > "$LAYOUT" <<'SVELTE'
<script>
  import '../app.css';
  import { page } from '$app/stores';

  const nav = [
    { href: '/', label: 'Today' },
    { href: '/batches', label: 'Batches' },
    { href: '/calendar', label: 'Calendar' },
    { href: '/recipes', label: 'Recipes' },
    { href: '/logs', label: 'Logs' },
    { href: '/reports', label: 'Reports' },
    { href: '/settings', label: 'Settings' },
  ];

  $: path = $page.url.pathname;
  const isActive = (href) => href === '/' ? path === '/' : path.startsWith(href);
</script>

<div class="app-shell min-h-screen grid grid-cols-[16rem,1fr] bg-neutral-950 text-neutral-100">
  <aside class="sticky top-0 h-svh bg-neutral-900/70 backdrop-blur border-r border-neutral-800 p-4 z-10">
    <h1 class="text-xl font-semibold mb-4">Grow Planner</h1>
    <nav class="grid gap-1">
      {#each nav as item}
        <a href={item.href}
           class="px-3 py-2 rounded hover:bg-neutral-800 transition
                  {isActive(item.href) ? 'bg-neutral-800 text-white' : 'text-neutral-300'}">
          {item.label}
        </a>
      {/each}
    </nav>
  </aside>

  <main class="min-h-screen p-6 overflow-x-hidden">
    <slot />
  </main>
</div>

<style>
  :global(.app-shell){ position: relative; }
  :global(.app-shell > aside){ position: sticky; top: 0; }
</style>
SVELTE

echo "[ok] wrote $LAYOUT"
echo "Next: pnpm dev  # then refresh http://localhost:5173"
