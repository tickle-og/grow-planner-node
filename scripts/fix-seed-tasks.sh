# scripts/fix-seed-tasks.sh
set -euo pipefail

# backup old file if present
mkdir -p backups
if [ -f src/routes/api/dev/seed/tasks/+server.ts ]; then
  cp -n src/routes/api/dev/seed/tasks/+server.ts "backups/dev-seed-tasks.$(date +%Y%m%d-%H%M%S).ts" || true
fi

# ensure folders
mkdir -p src/routes/api/dev/seed/tasks

# write new endpoint
cat > src/routes/api/dev/seed/tasks/+server.ts <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { tasks } from '$lib/db/schema';
import { json, jsonError } from '$lib/utils/json';
import { sql } from 'drizzle-orm';

function isoLocal(d: Date) {
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0,19);
}
function at(h: number, m=0) { const d = new Date(); d.setHours(h,m,0,0); return d; }
function addDays(d: Date, n: number) { const x = new Date(d); x.setDate(x.getDate()+n); return x; }

export const POST: RequestHandler = async ({ request }) => {
  try {
    const body = await request.json().catch(() => ({}));
    const locationId = Number(body.locationId ?? 1);

    // Quick sanity: verify tasks table exists (no throw if it doesn't, just logs)
    try {
      await db.execute(sql`SELECT 1 FROM tasks LIMIT 1`);
    } catch (e) {
      // dev-only hint in server logs, response still generic
      console.error('[seed/tasks] tasks table missing or not migrated:', e);
      return jsonError(500);
    }

    const sample = [
      { title: 'Check monotub FAE filters', status: 'active',   dueAt: isoLocal(at(17)),           notes: 'Quick visual check' },
      { title: 'Inoculate grain jars',      status: 'pending',  dueAt: isoLocal(addDays(at(10),1)), notes: 'Use LC A1' },
      { title: 'Harvest shoebox A',         status: 'active',   dueAt: isoLocal(addDays(at(12),2)), notes: 'Weigh wet yield' },
      { title: 'Tidy SAB workspace',        status: 'pending',  dueAt: isoLocal(addDays(at(19),-1)),notes: 'Overdue cleanup' }
    ] as const;

    // Insert one-by-one so we can log the exact row on error (friendlier for FK issues)
    for (const s of sample) {
      try {
        await db.insert(tasks).values({
          locationId,
          title: s.title,
          status: s.status as any, // matches schema $type
          dueAt: s.dueAt,
          notes: s.notes
        });
      } catch (rowErr) {
        console.error('[seed/tasks] insert failed for', s, '->', rowErr);
        // Still return generic response
        return jsonError(500);
      }
    }

    return json({ ok: true, inserted: sample.length, locationId });
  } catch (e) {
    console.error('[seed/tasks] top-level error:', e);
    return jsonError(500);
  }
};

// Tiny helper to check count quickly without exposing details
export const GET: RequestHandler = async ({ url }) => {
  try {
    const locationId = Number(url.searchParams.get('locationId') ?? 1);
    const rows = await db.execute(sql`SELECT COUNT(*) as c FROM tasks WHERE location_id = ${locationId}`);
    const count = Number((rows as any)?.rows?.[0]?.c ?? 0);
    return json({ ok: true, locationId, count });
  } catch (e) {
    console.error('[seed/tasks] GET check error:', e);
    return jsonError(500);
  }
};
TS

echo "[ok] Patched src/routes/api/dev/seed/tasks/+server.ts"
echo "Next:"
echo "  1) Restart dev server if running (so code reloads)."
echo "  2) Re-run seed and watch the server console for any logged cause:"
echo "     curl -s -X POST http://localhost:5173/api/dev/seed/tasks -H 'content-type: application/json' -d '{\"locationId\":1}' | jq ."
echo "  3) Check count:"
echo "     curl -s 'http://localhost:5173/api/dev/seed/tasks?locationId=1' | jq ."
