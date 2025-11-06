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
