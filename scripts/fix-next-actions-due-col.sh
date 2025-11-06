# scripts/fix-next-actions-due-col.sh
#!/usr/bin/env bash
set -euo pipefail

f="src/routes/api/dashboard/next-actions/+server.ts"
mkdir -p "$(dirname "$f")"
cp -n "$f" "$f.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

cat >"$f" <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { json } from '$lib/utils/json';
import { createClient } from '@libsql/client';

function intOr(def: number, v: string | null) {
  const n = v ? Number(v) : NaN;
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : def;
}

async function detectDueColumn(client: any): Promise<'due_at'|'dueAt'|null> {
  const res = await client.execute('PRAGMA table_info(tasks)');
  const names = (res.rows ?? []).map((r: any) => r.name ?? r['name']).filter(Boolean);
  if (names.includes('due_at')) return 'due_at';
  if (names.includes('dueAt')) return 'dueAt';
  return null;
}

export const GET: RequestHandler = async ({ request }) => {
  try {
    const url = new URL(request.url);
    const locationId = intOr(1, url.searchParams.get('location_id'));
    const days = intOr(14, url.searchParams.get('days'));

    const dbUrl = process.env.DB_URL ?? 'file:./dev.db';
    const client = createClient({ url: dbUrl });

    const dueCol = await detectDueColumn(client);
    if (!dueCol) {
      // No due column? Return empty list rather than 500 so the UI stays up.
      return json(200, { ok: true, items: [], note: 'tasks table has no due column' });
    }

    const { rows } = await client.execute({
      sql: `
        SELECT id, title, status, ${dueCol} AS due_at
        FROM tasks
        WHERE location_id = ?1
          AND status IN ('pending','scheduled')
          AND ${dueCol} IS NOT NULL
          AND datetime(${dueCol}) <= datetime('now', '+' || ?2 || ' days')
        ORDER BY datetime(${dueCol}) ASC
        LIMIT 50;
      `,
      args: [locationId, days]
    });

    return json(200, { ok: true, items: rows ?? [] });
  } catch (e: any) {
    return json(500, { ok: false, error: e?.message ?? 'Internal Error', stack: e?.stack ?? null });
  }
};
TS

echo "[ok] Patched $f to auto-detect due column (due_at vs dueAt)."
echo "Restart dev (pnpm dev) and try:"
echo "  curl -s 'http://localhost:5173/api/dashboard/next-actions' | jq ."
echo "  curl -s 'http://localhost:5173/api/dashboard/next-actions?location_id=1&days=30' | jq ."
