# scripts/wire-next-actions-and-demo-seed.sh
#!/usr/bin/env bash
set -euo pipefail

root="src/routes/api"
helpers='$lib/utils/json'

backup() { [ -f "$1" ] && cp -n "$1" "$1.bak.$(date +%Y%m%d-%H%M%S)" || true; }

# Robust util already added earlier; we reuse it.
util="$root/dashboard/_util.ts"
if ! grep -q 'getLocationIdOrThrow' "$util"; then
  echo "[warn] $util not found; make sure previous util patch ran."
fi

mkdir -p "$root/dashboard/next-actions"
f1="$root/dashboard/next-actions/+server.ts"
backup "$f1"
cat > "$f1" <<'TS'
import type { RequestHandler } from './$types';
import { json, jsonError } from '$lib/utils/json';
import { getLocationIdOrThrow } from '../_util';
import { db } from '$lib/db/drizzle';
import { sql } from 'drizzle-orm';

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event.url ?? new URL(event.request.url));

    // Try real tasks if the table exists; otherwise fall back to empty.
    try {
      const res = await db.execute(sql`
        SELECT
          id,
          location_id as locationId,
          title,
          COALESCE(due_at, '') as dueAt,
          COALESCE(status, 'pending') as status
        FROM tasks
        WHERE location_id = ${locationId}
        ORDER BY CASE WHEN due_at IS NULL THEN 1 ELSE 0 END, due_at ASC
        LIMIT 50;
      `);
      // libsql client returns { rows: [...] }
      const items = (res as any)?.rows ?? [];
      return json(200, { ok: true, items });
    } catch (_e) {
      // Table probably missing — tolerate
      return json(200, { ok: true, items: [] });
    }
  } catch (e: any) {
    console.error('next-actions error:', e);
    return jsonError(400, { message: e?.message ?? 'Bad Request' });
  }
};
TS
echo "[ok] wrote $f1"

# Dev seed endpoint to create a tasks table and insert demo tasks
mkdir -p "$root/dev/seed/demo-tasks"
f2="$root/dev/seed/demo-tasks/+server.ts"
backup "$f2"
cat > "$f2" <<'TS'
import type { RequestHandler } from './$types';
import { json, jsonError } from '$lib/utils/json';
import { db } from '$lib/db/drizzle';
import { sql } from 'drizzle-orm';

export const POST: RequestHandler = async () => {
  try {
    // Minimal tasks table if it doesn't exist
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        location_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        due_at TEXT NULL,
        status TEXT NOT NULL DEFAULT 'pending'
      );
    `);

    const now = new Date();
    const addDays = (d: number) => {
      const x = new Date(now);
      x.setDate(x.getDate() + d);
      return x.toISOString();
    };

    const demo = [
      { title: 'Sterilize jars', due_at: addDays(0), status: 'pending' },
      { title: 'Shake grain', due_at: addDays(2), status: 'pending' },
      { title: 'Spawn to bulk', due_at: addDays(5), status: 'pending' },
      { title: 'Mist + fan', due_at: addDays(7), status: 'pending' },
    ];

    for (const t of demo) {
      await db.execute(sql`
        INSERT INTO tasks (location_id, title, due_at, status)
        VALUES (1, ${t.title}, ${t.due_at}, ${t.status});
      `);
    }

    return json(200, { ok: true, created: demo.length });
  } catch (e) {
    console.error('demo-tasks seed error:', e);
    return jsonError(500);
  }
};
TS
echo "[ok] wrote $f2"

echo
echo "Done."
echo "Next:"
echo "  1) pnpm dev  (restart if already running)."
echo "  2) Seed some demo tasks:"
echo "     curl -s -X POST http://localhost:5173/api/dev/seed/demo-tasks | jq ."
echo "  3) Visit / — the Today page should list Next actions in ascending due order."
