#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-.}"
PAGE="${ROOT}/src/routes/+page.svelte"

# --- Sanity checks ---
[ -f "$PAGE" ] || { echo "Missing $PAGE"; exit 1; }

ts() { date +%Y%m%d-%H%M%S; }

backup_page() {
  cp -p "$PAGE" "${PAGE}.bak.$(ts)" 2>/dev/null || cp "$PAGE" "${PAGE}.bak.$(ts)"
  echo "[backup] ${PAGE}.bak.$(ts)"
}

# --- Snippets ---

read -r -d '' SNIPPET_SCRIPT <<'TSC'
// --- COMPACT-TASKS: state + helpers (BEGIN) ---
import { onMount } from 'svelte';
import { browser } from '$app/environment';

type NextAction = {
  id: number | string;
  title: string;
  dueAt?: string | null;
  status?: string | null;
};

export let data: any; // should already exist; we use data.locationId

let daysFilter: 7 | 14 | 365 = 14;
let loadingTasks = false;
let loadError: string | null = null;
let rawItems: NextAction[] = [];

const LS_KEY = 'dismissedTasks/v1';

function loadDismissed(): Record<string, number> {
  if (!browser) return {};
  try { return JSON.parse(localStorage.getItem(LS_KEY) || '{}'); } catch { return {}; }
}
function saveDismissed(map: Record<string, number>) {
  if (!browser) return;
  localStorage.setItem(LS_KEY, JSON.stringify(map));
}
function isDismissed(id: number | string): boolean {
  const m = loadDismissed();
  return Boolean(m[String(id)]);
}
function dismissLocal(id: number | string) {
  const m = loadDismissed();
  m[String(id)] = Date.now();
  saveDismissed(m);
}

function normalizeDueAt(item: any): string | null {
  const v = item?.dueAt ?? item?.due_at ?? null;
  if (!v) return null;
  try { return new Date(v).toISOString(); } catch { return null; }
}

async function fetchNextActions() {
  loadingTasks = true;
  loadError = null;
  try {
    const locId = Number(data?.locationId) || 1;
    const url = new URL('/api/dashboard/next-actions', location.origin);
    url.searchParams.set('location_id', String(locId));
    url.searchParams.set('days', String(daysFilter));
    const res = await fetch(url.toString(), { headers: { 'accept': 'application/json' } });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json();
    if (json?.ok !== true) throw new Error(json?.error || 'Unknown error');
    rawItems = (json.items || []).map((it: any) => ({
      id: it.id,
      title: it.title ?? it.name ?? 'Untitled task',
      dueAt: normalizeDueAt(it),
      status: it.status ?? null
    }));
  } catch (e: any) {
    loadError = e?.message || String(e);
    rawItems = [];
  } finally {
    loadingTasks = false;
  }
}

function visibleItems(): NextAction[] {
  const items = rawItems
    .filter((it) => !isDismissed(it.id))
    .sort((a, b) => {
      const da = a.dueAt ? Date.parse(a.dueAt) : Infinity;
      const db = b.dueAt ? Date.parse(b.dueAt) : Infinity;
      return da - db;
    });
  return items.slice(0, 12);
}

function relTime(ts: string | null | undefined): string {
  if (!ts) return '—';
  const d = new Date(ts).getTime();
  const now = Date.now();
  const diff = d - now;
  const abs = Math.abs(diff);
  const mins = Math.round(abs / (60 * 1000));
  const hours = Math.round(abs / (60 * 60 * 1000));
  const days = Math.round(abs / (24 * 60 * 60 * 1000));
  if (abs < 60 * 1000) return diff < 0 ? 'just now' : 'in a moment';
  if (mins < 60) return diff < 0 ? `${mins}m ago` : `in ${mins}m`;
  if (hours < 24) return diff < 0 ? `${hours}h ago` : `in ${hours}h`;
  return diff < 0 ? `${days}d ago` : `in ${days}d`;
}

async function markDone(id: number | string) {
  const prev = rawItems.slice();
  rawItems = rawItems.filter((it) => it.id !== id);
  try {
    const res = await fetch(`/api/tasks/${id}/complete`, { method: 'POST' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
  } catch {
    rawItems = prev;
  }
}

async function dismiss(id: number | string) {
  dismissLocal(id);
  const prev = rawItems.slice();
  rawItems = rawItems.filter((it) => it.id !== id);
  try {
    await fetch(`/api/tasks/${id}/dismiss`, { method: 'POST' });
  } catch {
    // keep local dismissal even if server fails
  }
}

function setDaysFilter(v: 7 | 14 | 365) {
  daysFilter = v;
  fetchNextActions();
}

onMount(fetchNextActions);
// --- COMPACT-TASKS: state + helpers (END) ---
TSM
TSC

read -r -d '' SNIPPET_MARKUP <<'HTML'
<!-- COMPACT-TASKS-WIDGET (BEGIN) -->
<section class="mx-auto max-w-6xl px-4 mt-6">
  <div class="rounded-xl border border-neutral-800 bg-neutral-900/60 backdrop-blur p-4">
    <div class="flex items-center justify-between mb-2">
      <h2 class="text-sm font-semibold tracking-wide text-neutral-200 uppercase">Upcoming Tasks</h2>
      <div class="inline-flex gap-1 text-xs" role="tablist" aria-label="Task window">
        <button
          class="px-2 py-1 rounded border transition
                 {daysFilter===7 ? 'border-primary-500 text-primary-300' : 'border-neutral-700 text-neutral-300 hover:border-neutral-500'}"
          on:click={() => setDaysFilter(7)}
          role="tab" aria-selected={daysFilter===7}>This week</button>
        <button
          class="px-2 py-1 rounded border transition
                 {daysFilter===14 ? 'border-primary-500 text-primary-300' : 'border-neutral-700 text-neutral-300 hover:border-neutral-500'}"
          on:click={() => setDaysFilter(14)}
          role="tab" aria-selected={daysFilter===14}>Next 14 days</button>
        <button
          class="px-2 py-1 rounded border transition
                 {daysFilter===365 ? 'border-primary-500 text-primary-300' : 'border-neutral-700 text-neutral-300 hover:border-neutral-500'}"
          on:click={() => setDaysFilter(365)}
          role="tab" aria-selected={daysFilter===365}>All</button>
      </div>
    </div>

    {#if loadingTasks}
      <div class="text-neutral-400 text-sm">Loading…</div>
    {:else if loadError}
      <div class="text-red-400 text-sm">Error: {loadError}</div>
    {:else if visibleItems().length === 0}
      <div class="text-neutral-300 text-sm">You’re caught up. Hydrate your grains and stretch your wrists.</div>
    {:else}
      <ul class="divide-y divide-neutral-800">
        {#each visibleItems() as it (it.id)}
          <li class="flex items-center gap-3 py-2">
            <input
              type="checkbox"
              class="h-4 w-4 rounded border-neutral-600 bg-neutral-800 text-primary-500 cursor-pointer"
              title="Mark done"
              on:change={() => markDone(it.id)}
            />
            <div class="min-w-0 flex-1">
              <div class="truncate text-sm text-neutral-100">{it.title}</div>
              <div class="text-xs text-neutral-400">{it.dueAt ? relTime(it.dueAt) : 'unscheduled'}</div>
            </div>
            <button
              class="text-xs px-2 py-1 rounded border border-neutral-700 text-neutral-300 hover:border-neutral-500"
              title="Dismiss"
              on:click={() => dismiss(it.id)}
            >Dismiss</button>
          </li>
        {/each}
      </ul>
    {/if}
  </div>
</section>
<!-- COMPACT-TASKS-WIDGET (END) -->
HTML

read -r -d '' SNIPPET_CSS <<'CSS'
/* COMPACT-TASKS-WIDGET styles (BEGIN) */
:root {
  --primary-300: #7dd3fc;
  --primary-500: #0ea5e9;
}
.border-primary-500 { border-color: var(--primary-500); }
.text-primary-300   { color: var(--primary-300); }
/* COMPACT-TASKS-WIDGET styles (END) */
CSS

# --- Patch +page.svelte ---

backup_page

# 1) Inject script helpers inside existing <script lang="ts"> before its closing tag
if grep -q 'COMPACT-TASKS: state \+ helpers' "$PAGE"; then
  echo "[skip] script helpers already present"
else
  awk -v ADD="$SNIPPET_SCRIPT" '
    BEGIN{ins=0; in=0}
    /<script[^>]*lang="ts"[^>]*>/ { in=1; print; next }
    in==1 && /<\/script>/ && ins==0 {
      print ADD;
      print;
      ins=1; in=0; next
    }
    { print }
  ' "$PAGE" > "${PAGE}.tmp" && mv "${PAGE}.tmp" "$PAGE"
  echo "[ok] injected script helpers"
fi

# 2) Inject markup right after the first </header>
if grep -q 'COMPACT-TASKS-WIDGET (BEGIN)' "$PAGE"; then
  echo "[skip] widget markup already present"
else
  awk -v ADD="$SNIPPET_MARKUP" '
    BEGIN{done=0}
    {
      print
      if(done==0 && /<\/header>/){
        print ADD
        done=1
      }
    }
  ' "$PAGE" > "${PAGE}.tmp" && mv "${PAGE}.tmp" "$PAGE"
  echo "[ok] injected widget markup"
fi

# 3) Add CSS into existing <style>, or create one once if none exists
if grep -q 'COMPACT-TASKS-WIDGET styles' "$PAGE"; then
  echo "[skip] widget CSS already present"
else
  if grep -q '<style[^>]*>' "$PAGE"; then
    # insert before the first closing </style>
    awk -v ADD="$SNIPPET_CSS" '
      BEGIN{done=0}
      /<\/style>/ && done==0 { print ADD; print; done=1; next }
      { print }
    ' "$PAGE" > "${PAGE}.tmp" && mv "${PAGE}.tmp" "$PAGE"
    echo "[ok] appended CSS inside existing <style>"
  else
    # create a single style tag at end (Svelte allows one top-level <style>)
    {
      cat "$PAGE"
      printf "\n<style>\n%s\n</style>\n" "$SNIPPET_CSS"
    } > "${PAGE}.tmp" && mv "${PAGE}.tmp" "$PAGE"
    echo "[ok] created <style> with CSS"
  fi
fi

# --- Endpoints ---

COMPLETE_DIR="${ROOT}/src/routes/api/tasks/[id]/complete"
DISMISS_DIR="${ROOT}/src/routes/api/tasks/[id]/dismiss"
mkdir -p "$COMPLETE_DIR" "$DISMISS_DIR"

cat > "${COMPLETE_DIR}/+server.ts" <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { tasks } from '$lib/db/schema';
import { eq } from 'drizzle-orm';

export const POST: RequestHandler = async ({ params }) => {
  try {
    const id = Number(params.id);
    if (!Number.isFinite(id)) {
      return new Response(JSON.stringify({ ok: false, error: 'Invalid id' }), { status: 400 });
    }
    await db.update(tasks).set({ status: 'completed' as any }).where(eq(tasks.id, id));
    return new Response(JSON.stringify({ ok: true, id }), { status: 200 });
  } catch (e: any) {
    return new Response(JSON.stringify({ ok: false, error: e?.message || String(e) }), { status: 500 });
  }
};
TS

cat > "${DISMISS_DIR}/+server.ts" <<'TS'
import type { RequestHandler } from '@sveltejs/kit';

export const POST: RequestHandler = async ({ params }) => {
  const id = Number(params.id);
  if (!Number.isFinite(id)) {
    return new Response(JSON.stringify({ ok: false, error: 'Invalid id' }), { status: 400 });
  }
  // no-op server; UI stores local dismissal
  return new Response(JSON.stringify({ ok: true, id, dismissed: true }), { status: 200 });
};
TS

echo "[ok] endpoints created:"
echo "  - src/routes/api/tasks/[id]/complete/+server.ts"
echo "  - src/routes/api/tasks/[id]/dismiss/+server.ts"

echo
echo "Next:"
echo "  1) pnpm dev"
echo "  2) Open / and try the Upcoming Tasks widget."
echo "  3) Test API quickly:"
echo "     curl -s 'http://localhost:5173/api/dashboard/next-actions?location_id=1&days=14' | jq ."
echo "     # then click checkboxes (POST /api/tasks/:id/complete) or Dismiss (POST /api/tasks/:id/dismiss)"
