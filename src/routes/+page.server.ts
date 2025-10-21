// src/routes/+page.server.ts
import type { Actions, PageServerLoad } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { and, lt, between, eq, asc } from 'drizzle-orm';

function startOfDayMs(d = new Date()) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x.getTime();
}
function endOfDayMs(d = new Date()) {
  const x = new Date(d);
  x.setHours(23, 59, 59, 999);
  return x.getTime();
}

async function rangeQuery(whereClause: any) {
  const { tasks, batches } = schema;
  return await db
    .select({
      id: tasks.id,
      title: tasks.title,
      dueAt: tasks.dueAt,
      durationMin: tasks.durationMin,
      status: tasks.status,
      batchId: tasks.batchId,
      batchName: batches.name
    })
    .from(tasks)
    .leftJoin(batches, eq(tasks.batchId, batches.id))
    .where(whereClause)
    .orderBy(asc(tasks.dueAt))
    .all();
}

export const load: PageServerLoad = async () => {
  const now = Date.now();
  const start = startOfDayMs(new Date(now));
  const end = endOfDayMs(new Date(now));
  const upcomingEnd = end + 48 * 60 * 60_000;

  const overdue = await rangeQuery(and(lt(schema.tasks.dueAt, start), eq(schema.tasks.status, 'open')));
  const dueToday = await rangeQuery(and(between(schema.tasks.dueAt, start, end), eq(schema.tasks.status, 'open')));
  const upcoming = await rangeQuery(and(between(schema.tasks.dueAt, end, upcomingEnd), eq(schema.tasks.status, 'open')));

  return { now, start, end, upcomingEnd, overdue, dueToday, upcoming };
};

export const actions: Actions = {
  complete: async ({ request }) => {
    const form = await request.formData();
    const id = String(form.get('id') ?? '');
    if (!id) return { ok: false };
    await db.update(schema.tasks).set({ status: 'done', updatedAt: Date.now() }).where(eq(schema.tasks.id, id));
    return { ok: true };
  },
  snooze: async ({ request }) => {
    const form = await request.formData();
    const id = String(form.get('id') ?? '');
    const minutes = Number(form.get('minutes') ?? 24 * 60);
    if (!id || !Number.isFinite(minutes)) return { ok: false };
    const t = await db.select().from(schema.tasks).where(eq(schema.tasks.id, id)).get();
    if (!t) return { ok: false };
    await db
      .update(schema.tasks)
      .set({ dueAt: t.dueAt + minutes * 60_000, updatedAt: Date.now(), status: 'open' })
      .where(eq(schema.tasks.id, id));
    return { ok: true };
  }
};
