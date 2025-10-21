// @ts-nocheck
// src/routes/calendar/+page.server.ts
import type { PageServerLoad } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { and, between, eq, asc, gt } from 'drizzle-orm';

const DAY = 24 * 60 * 60_000;

function startOfToday() {
  const d = new Date();
  d.setHours(0,0,0,0);
  return d.getTime();
}

export const load = async () => {
  const windowStart = startOfToday();
  const windowEnd = windowStart + 60 * DAY; // ~2 months

  const { tasks, batches } = schema;
  const rows = await db
    .select({
      id: tasks.id,
      title: tasks.title,
      dueAt: tasks.dueAt,
      durationMin: tasks.durationMin,
      batchId: tasks.batchId,
      batchName: batches.name
    })
    .from(tasks)
    .leftJoin(batches, eq(tasks.batchId, batches.id))
    .where(and(between(tasks.dueAt, windowStart - 14 * DAY, windowEnd), gt(tasks.durationMin, -1)))
    .orderBy(asc(tasks.dueAt))
    .all();

  // group by batch
  const groupsMap = new Map<string, { batchId: string; batchName: string; tasks: any[] }>();
  for (const r of rows) {
    if (!groupsMap.has(r.batchId)) groupsMap.set(r.batchId, { batchId: r.batchId, batchName: r.batchName, tasks: [] });
    groupsMap.get(r.batchId)!.tasks.push(r);
  }

  const days = Array.from({ length: Math.ceil((windowEnd - windowStart) / DAY) }, (_, i) => windowStart + i * DAY);

  return { windowStart, days, groups: Array.from(groupsMap.values()) };
};
;null as any as PageServerLoad;