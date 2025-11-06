#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-.}"
MIGDIR="${ROOT}/drizzle"
NA_ENDPOINT="${ROOT}/src/routes/api/dashboard/next-actions/+server.ts"
DISMISS_ENDPOINT="${ROOT}/src/routes/api/tasks/[id]/dismiss/+server.ts"

ts() { date +%Y%m%d-%H%M%S; }

echo "[1/5] Ensure migrations folder exists"
mkdir -p "$MIGDIR"

echo "[2/5] Create migration to add tasks.dismissed_at (if none exists)"
if ! rg -q 'dismissed_at' "$MIGDIR"/*.sql 2>/dev/null; then
  MIG="$MIGDIR/$(date +%s)_add_tasks_dismissed_at.sql"
  cat > "$MIG" <<'SQL'
-- Persist "dismiss" on tasks
-- idempotent-ish for local dev (SQLite ignores IF EXISTS on ADD COLUMN)
ALTER TABLE tasks ADD COLUMN dismissed_at TEXT;
CREATE INDEX IF NOT EXISTS idx_tasks_dismissed_at ON tasks(dismissed_at);
SQL
  echo "  -> wrote $MIG"
else
  echo "  -> migration referencing dismissed_at already present, skipping file creation"
fi

echo "[3/5] Run migrations"
pnpm drizzle-kit migrate

echo "[4/5] Patch dismiss endpoint to set dismissed_at = current timestamp"
mkdir -p "$(dirname "$DISMISS_ENDPOINT")"
if [ -f "$DISMISS_ENDPOINT" ]; then
  cp -p "$DISMISS_ENDPOINT" "${DISMISS_ENDPOINT}.bak.$(ts)" || true
fi
cat > "$DISMISS_ENDPOINT" <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { sql } from 'drizzle-orm';

export const POST: RequestHandler = async ({ params }) => {
  try {
    const id = Number(params.id);
    if (!Number.isFinite(id)) {
      return new Response(JSON.stringify({ ok: false, error: 'Invalid id' }), {
        status: 400,
        headers: { 'content-type': 'application/json' }
      });
    }

    // Persist the dismissal on the task
    await db.execute(sql`UPDATE tasks SET dismissed_at = CURRENT_TIMESTAMP WHERE id = ${id}`);

    return new Response(JSON.stringify({ ok: true, id, dismissed: true }), {
      status: 200,
      headers: { 'content-type': 'application/json' }
    });
  } catch (e: any) {
    return new Response(JSON.stringify({ ok: false, error: e?.message || String(e) }), {
      status: 500,
      headers: { 'content-type': 'application/json' }
    });
  }
};
TS
echo "  -> wrote $DISMISS_ENDPOINT"

echo "[5/5] Replace next-actions endpoint to exclude dismissed server-side"
mkdir -p "$(dirname "$NA_ENDPOINT")"
if [ -f "$NA_ENDPOINT" ]; then
  cp -p "$NA_ENDPOINT" "${NA_ENDPOINT}.bak.$(ts)" || true
fi
cat > "$NA_ENDPOINT" <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { sql } from 'drizzle-orm';

// GET /api/dashboard/next-actions?days=14
// Returns upcoming (and unscheduled) tasks, EXCLUDING dismissed ones.
export const GET: RequestHandler = async ({ url }) => {
  try {
    const daysParam = url.searchParams.get('days');
    const days = Number.isFinite(Number(daysParam)) ? Number(daysParam) : 14;
    const modifier = `+${days} days`; // e.g. "+14 days"

    // Pull a compact set: id/title/name/due_at/status, filter out dismissed server-side.
    // Keep unscheduled (due_at NULL) but sort them last.
    const res = await db.execute(sql`
      SELECT
        id,
        COALESCE(title, name, 'Untitled task') AS title,
        due_at,
        status
      FROM tasks
      WHERE dismissed_at IS NULL
        AND (
          due_at IS NULL
          OR date(due_at) <= date('now', ${modifier})
        )
      ORDER BY
        CASE WHEN due_at IS NULL THEN 1 ELSE 0 END,
        datetime(due_at) ASC
      LIMIT 200
    `);

    const items = (res.rows as any[]).map((r) => ({
      id: r.id,
      title: r.title,
      // keep both keys for UI compatibility
      due_at: r.due_at ?? null,
      dueAt: r.due_at ?? null,
      status: r.status ?? null
    }));

    return new Response(JSON.stringify({ ok: true, items }), {
      status: 200,
      headers: { 'content-type': 'application/json' }
    });
  } catch (e: any) {
    return new Response(JSON.stringify({ ok: false, error: e?.message || String(e) }), {
      status: 500,
      headers: { 'content-type': 'application/json' }
    });
  }
};
TS
echo "  -> wrote $NA_ENDPOINT"

cat <<'DONE'

All set.

Next steps:
  1) Restart dev server:    pnpm dev
  2) Hit the endpoint:      curl -s 'http://localhost:5173/api/dashboard/next-actions?days=14' | jq .
     - Should show tasks excluding any with non-null dismissed_at
  3) Dismiss one:           curl -s -X POST 'http://localhost:5173/api/tasks/1/dismiss' | jq .
     - Then re-check next-actions; task 1 should disappear.
  4) (Optional) mark done:  curl -s -X POST 'http://localhost:5173/api/tasks/1/complete' | jq .

Your Today page’s compact widget will now hide dismissed tasks permanently (until you add an “undismiss” UX).
DONE
