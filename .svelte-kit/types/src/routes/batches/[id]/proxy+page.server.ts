// @ts-nocheck
// src/routes/batches/[id]/+page.server.ts
import type { Actions, PageServerLoad } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { eq, asc, desc } from 'drizzle-orm';
import { error, redirect } from '@sveltejs/kit';
import { createId } from '@paralleldrive/cuid2';

export const load = async ({ params }: Parameters<PageServerLoad>[0]) => {
  const id = params.id;
  const batch = await db.select().from(schema.batches).where(eq(schema.batches.id, id)).get();
  if (!batch) throw error(404, 'Batch not found');

  const tasks = await db.select().from(schema.tasks).where(eq(schema.tasks.batchId, id)).orderBy(asc(schema.tasks.dueAt)).all();
  const logs = await db.select().from(schema.logs).where(eq(schema.logs.batchId, id)).orderBy(desc(schema.logs.createdAt)).all();
  const yields = await db.select().from(schema.yieldsTbl).where(eq(schema.yieldsTbl.batchId, id)).orderBy(desc(schema.yieldsTbl.createdAt)).all();

  return { batch, tasks, logs, yields };
};

export const actions = {
  add_log: async ({ request, params }: import('./$types').RequestEvent) => {
    const batchId = params.id!;
    const form = await request.formData();
    const kind = String(form.get('kind') ?? 'note');
    const text = String(form.get('text') ?? '').trim();
    const temp = form.get('temp'); const rh = form.get('rh'); const co2 = form.get('co2');
    const payload: any = {};
    if (kind === 'note') payload.text = text;
    if (kind === 'env') {
      if (temp) payload.temp = Number(temp);
      if (rh) payload.rh = Number(rh);
      if (co2) payload.co2 = Number(co2);
    }
    const now = Date.now();
    await db.insert(schema.logs).values({
      id: createId(),
      batchId,
      kind,
      payload: JSON.stringify(payload),
      photo: null as any,
      createdAt: now
    });
    throw redirect(303, `/batches/${batchId}`);
  },

  add_yield: async ({ request, params }: import('./$types').RequestEvent) => {
    const batchId = params.id!;
    const form = await request.formData();
    const flushNo = Number(form.get('flushNo') ?? 1);
    const wetWeightG = Number(form.get('wetWeightG') ?? 0);
    const dryWeightG = form.get('dryWeightG') ? Number(form.get('dryWeightG')) : null;
    const notes = String(form.get('notes') ?? '').trim();
    const now = Date.now();
    await db.insert(schema.yieldsTbl).values({
      id: createId(),
      batchId,
      flushNo: Number.isFinite(flushNo) ? flushNo : 1,
      wetWeightG: Number.isFinite(wetWeightG) ? wetWeightG : 0,
      dryWeightG: dryWeightG && Number.isFinite(dryWeightG) ? dryWeightG : null,
      notes,
      createdAt: now
    });
    throw redirect(303, `/batches/${batchId}`);
  }
};
;null as any as Actions;