import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { tasks } from '$lib/db/schema';
import { and, gte, lte, eq, inArray, isNotNull } from 'drizzle-orm';
import { json, jsonError } from '$lib/utils/json';

function iso(d: Date) {
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 19);
}
function startOfDay(d = new Date()) {
  const x = new Date(d);
  x.setHours(0,0,0,0);
  return x;
}
function addDays(d: Date, n: number) {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
}

export const GET: RequestHandler = async ({ url }) => {
  try {
    // Window control
    const scope = (url.searchParams.get('scope') || 'week').toLowerCase(); // week | 14 | all
    const locationId = Number(url.searchParams.get('location_id') || '1');

    const now0 = startOfDay(new Date());
    let end = addDays(now0, 7);
    if (scope === '14') end = addDays(now0, 14);
    if (scope === 'all') end = addDays(now0, 90); // practical cap for UI

    // pending + active with a due date in window
    const rows = await db.select().from(tasks).where(
      and(
        eq(tasks.locationId, locationId),
        inArray(tasks.status, ['pending','active']),
        isNotNull(tasks.dueAt),
        gte(tasks.dueAt, iso(now0)),
        lte(tasks.dueAt, iso(end))
      )
    ).orderBy(tasks.dueAt);

    // Also pull unscheduled tasks (no due_at), limited to 20 for sidebar lists
    const unscheduled = await db.select().from(tasks).where(
      and(
        eq(tasks.locationId, locationId),
        inArray(tasks.status, ['pending','active']),
        tasks.dueAt.isNull?.() ?? (tasks.dueAt as any).isNull() // compat across drizzle versions
      )
    ).limit(20);

    // Calendar grouping by YYYY-MM-DD
    const calendar: Record<string, typeof rows> = {};
    for (const t of rows) {
      const day = String(t.dueAt).slice(0, 10); // YYYY-MM-DD
      (calendar[day] ||= []).push(t);
    }

    return json({
      ok: true,
      locationId,
      scope,
      range: { start: iso(now0), end: iso(end) },
      list: rows,            // already sorted ASC by due_at
      calendar,              // for grid rendering
      unscheduled            // optional panel
    });
  } catch {
    return jsonError(500);
  }
};
