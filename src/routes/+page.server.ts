import type { Actions, PageServerLoad } from './$types';
import { db } from '$lib/db/drizzle';
import { tasks, grows } from '$lib/db/schema';
import { eq, and, lt, gte, lte } from 'drizzle-orm';

const now = () => Date.now();

export const load: PageServerLoad = async () => {
  const n = now();
  const end48h = n + 48 * 60 * 60 * 1000;

  // join tasks -> grows to show batch name
  const base = db
    .select({
      id: tasks.id,
      title: tasks.title,
      dueAt: tasks.dueAt,
      batchId: tasks.batchId,
      batchName: grows.name,
    })
    .from(tasks)
    .leftJoin(grows, eq(grows.id, tasks.batchId))
    .where(eq(tasks.status, 'pending'));

  const [overdue, dueToday, upcoming] = await Promise.all([
    base.clone().where(and(eq(tasks.status, 'pending'), lt(tasks.dueAt, n))).orderBy(tasks.dueAt),
    base.clone().where(and(gte(tasks.dueAt, n), lte(tasks.dueAt, n + 24 * 60 * 60 * 1000))).orderBy(tasks.dueAt),
    base.clone().where(and(gte(tasks.dueAt, n + 24 * 60 * 60 * 1000), lte(tasks.dueAt, end48h))).orderBy(tasks.dueAt),
  ]);

  return { overdue, dueToday, upcoming };
};

export const actions: Actions = {
  complete: async ({ request }) => {
    const form = await request.formData();
    const id = String(form.get('id') ?? '');
    if (!id) return { ok: false, error: 'Missing id' };
    await db.update(tasks).set({ status: 'done', completedAt: Date.now() }).where(eq(tasks.id, id));
    return { ok: true };
  },
  snooze: async ({ request }) => {
    const form = await request.formData();
    const id = String(form.get('id') ?? '');
    const minutes = Number(form.get('minutes') ?? 60);
    if (!id) return { ok: false, error: 'Missing id' };
    await db.update(tasks).set({ dueAt: Date.now() + minutes * 60_000 }).where(eq(tasks.id, id));
    return { ok: true };
  },
};
