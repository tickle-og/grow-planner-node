# scripts/fix-next-actions-route.sh
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

export const GET: RequestHandler = async ({ request }) => {
  try {
    const url = new URL(request.url);
    const locationId = intOr(1, url.searchParams.get('location_id'));
    const days = intOr(14, url.searchParams.get('days'));

    const dbUrl = process.env.DB_URL ?? 'file:./dev.db';
    const client = createClient({ url: dbUrl });

    // Normalize to whichever column naming exists (due_at OR dueAt)
    // and return pending/scheduled tasks only, ordered by due date.
    const { rows } = await client.execute({
      sql: `
        WITH t AS (
          SELECT
            id,
            location_id,
            title,
            status,
            COALESCE(due_at, dueAt) AS due_at
          FROM tasks
          WHERE location_id = ?1
        )
        SELECT id, title, status, due_at
        FROM t
        WHERE (status IN ('pending','scheduled'))
          AND (due_at IS NOT NULL)
          AND datetime(due_at) <= datetime('now', '+' || ?2 || ' days')
        ORDER BY datetime(due_at) ASC
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

echo "[ok] Wrote $f"
echo "Restart dev and hit:"
echo "  curl -s 'http://localhost:5173/api/dashboard/next-actions' | jq ."
echo "  curl -s 'http://localhost:5173/api/dashboard/next-actions?location_id=1&days=30' | jq ."
