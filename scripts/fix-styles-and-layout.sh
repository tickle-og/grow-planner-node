# scripts/fix-styles-and-layout.sh
#!/usr/bin/env bash
set -euo pipefail

LAYOUT="src/routes/+layout.svelte"
APPCSS="src/app.css"
ts=$(date +%Y%m%d-%H%M%S)

mkdir -p src/routes

# --- 1) Ensure app.css has Tailwind v4 bootstrapped and a dark base ---
touch "$APPCSS"

inject_line() {
  local needle="$1"
  local line="$2"
  if ! grep -qF "$needle" "$APPCSS"; then
    printf '%s\n' "$line" >> "$APPCSS"
  fi
}

# Put Tailwind imports at the very top (without duplicating)
if ! grep -q '@import "tailwindcss";' "$APPCSS"; then
  cp -p "$APPCSS" "$APPCSS.bak.$ts"
  printf '%s\n%s\n%s\n\n' \
    '@import "tailwindcss";' \
    '@source "./src/**/*.{svelte,ts,js,html}";' \
    '@reference "tailwindcss/utilities";' \
    > "$APPCSS.new"
  cat "$APPCSS" >> "$APPCSS.new"
  mv "$APPCSS.new" "$APPCSS"
else
  inject_line '@source ' '@source "./src/**/*.{svelte,ts,js,html}";'
  inject_line '@reference "tailwindcss/utilities";' '@reference "tailwindcss/utilities";'
fi

# Add a global dark base if missing
if ! grep -q 'body.*bg-neutral-950' "$APPCSS"; then
  cat >> "$APPCSS" <<'CSS'

/* --- global dark base --- */
:root { color-scheme: dark; }
html, body { height: 100%; }
body { @apply bg-neutral-950 text-neutral-100; }
CSS
fi

echo "[ok] Tailwind + dark base ensured in $APPCSS"

# --- 2) Write a clean root layout that imports app.css and renders a sticky sidebar ---
if [[ -f "$LAYOUT" ]]; then
  cp -p "$LAYOUT" "$LAYOUT.bak.$ts"
  echo "[backup] $LAYOUT -> $LAYOUT.bak.$ts"
fi

cat > "$LAYOUT" <<'SVELTE'
<script>
  // Import global styles so Tailwind actually ships to the page.
  import '../app.css';
</script>

<div class="app-shell min-h-screen grid grid-cols-1 md:grid-cols-[16rem,1fr] bg-neutral-950 text-neutral-100">
  <aside class="sticky top-0 h-svh bg-neutral-900/70 backdrop-blur border-r border-neutral-800 p-4 z-10">
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

  <main class="min-h-screen p-6 overflow-x-hidden">
    <slot />
  </main>
</div>

<style>
  /* A tiny guard so “sticky” sticks consistently across browsers */
  :global(.app-shell) { position: relative; }
  :global(.app-shell > aside) { position: sticky; top: 0; }
</style>
SVELTE

echo "[ok] Wrote $LAYOUT"

cat <<'NEXT'

Next:
  1) Stop dev server (Ctrl+C) and restart: pnpm dev
  2) Open http://localhost:5173
     - Background should be dark
     - Sidebar should be visible and sticky
  3) If the grid still collapses on small screens, that’s expected — it’s 1 column on mobile
     and becomes [16rem, 1fr] at md and up. Tweak the breakpoint if you want it earlier/later.
NEXT
