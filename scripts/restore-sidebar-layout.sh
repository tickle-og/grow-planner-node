# scripts/restore-sidebar-layout.sh
#!/usr/bin/env bash
set -euo pipefail

# Paths
LAYOUT="src/routes/+layout.svelte"
APPCSS="src/app.css"

mkdir -p "$(dirname "$LAYOUT")"

# Backup existing layout if present
ts=$(date +%Y%m%d-%H%M%S)
if [[ -f "$LAYOUT" ]]; then
  cp -p "$LAYOUT" "$LAYOUT.bak.$ts"
  echo "[backup] $LAYOUT -> $LAYOUT.bak.$ts"
fi

# Write a sane two-column shell with a sticky sidebar
cat > "$LAYOUT" <<'SVELTE'
<script>
  // minimal shell; content comes from <slot />
</script>

<div class="app-shell min-h-screen grid grid-cols-[16rem,1fr] bg-neutral-950 text-neutral-100">
  <aside class="sticky top-0 h-svh bg-neutral-900/70 backdrop-blur border-r border-neutral-800 p-4 space-y-2 z-10">
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
  /* Guard against page sections overlapping the sidebar */
  :global(.app-shell){ position: relative; }
  :global(.app-shell > aside){ position: sticky; top: 0; }
</style>
SVELTE

echo "[ok] Wrote $LAYOUT"

# Optional: ensure Tailwind v4 scans your routes and utilities are available
if [[ -f "$APPCSS" ]]; then
  # Add @source if missing (so Tailwind sees /src/**/*)
  if ! grep -qE '^\s*@source\s+' "$APPCSS"; then
    echo "[tailwind] injecting @source into $APPCSS"
    tmp="$(mktemp)"
    {
      echo '@source "./src/**/*.{svelte,ts,js,html}";'
      cat "$APPCSS"
    } > "$tmp"
    mv "$tmp" "$APPCSS"
  fi

  # Add Tailwind v4 bootstrap if you somehow lost it
  if ! grep -q '@import "tailwindcss";' "$APPCSS"; then
    echo "[tailwind] adding @import \"tailwindcss\" to $APPCSS"
    sed -i '1i @import "tailwindcss";' "$APPCSS"
  fi

  # Add utilities reference to quiet “unknown utility class” warnings
  if ! grep -q '@reference "tailwindcss/utilities";' "$APPCSS"; then
    echo '[tailwind] adding @reference "tailwindcss/utilities" to app.css'
    sed -i '1i @reference "tailwindcss/utilities";' "$APPCSS"
  fi
fi

cat <<'NEXT'

Next:
  1) Restart dev server: Ctrl+C then `pnpm dev`
  2) Visit http://localhost:5173 — the sidebar should be back and sticky.
  3) If the grid still collapses, your Tailwind build may reject the arbitrary grid class.
     Try replacing `grid-cols-[16rem,1fr]` with `grid-cols-[260px,1fr]` or a responsive combo
     like `grid-cols-6 md:grid-cols-[16rem,1fr]`.
NEXT
