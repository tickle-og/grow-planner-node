// src/routes/batches/new/+page.server.ts
import type { Actions, PageServerLoad } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { z } from 'zod';
import { generateSchedule } from '$lib/logic/scheduler';
import { createId } from '@paralleldrive/cuid2';
import { redirect } from '@sveltejs/kit';
import { eq, asc } from 'drizzle-orm';

export const load: PageServerLoad = async () => {
  const recipes = await db
    .select()
    .from(schema.recipes)
    .orderBy(asc(schema.recipes.name))
    .all();

  return { recipes };
};

const CreateBatchSchema = z.object({
  name: z.string().min(1),
  recipeId: z.string().min(1),
  qtyUnits: z.coerce.number().int().min(1),
  startDate: z.string().min(1) // yyyy-mm-dd
});

export const actions: Actions = {
  create: async ({ request }) => {
    const form = await request.formData();
    const payload = {
      name: String(form.get('name') ?? ''),
      recipeId: String(form.get('recipeId') ?? ''),
      qtyUnits: String(form.get('qtyUnits') ?? ''),
      startDate: String(form.get('startDate') ?? '')
    };

    const parsed = CreateBatchSchema.safeParse(payload);
    if (!parsed.success) {
      return { ok: false, error: parsed.error.errors.map(e => e.message).join(', ') };
    }

    const { name, recipeId, qtyUnits, startDate } = parsed.data;
    const startMs = new Date(startDate + 'T00:00:00').getTime();
    const now = Date.now();

    // Fetch recipe
    const recipe = await db
      .select()
      .from(schema.recipes)
      .where(eq(schema.recipes.id, recipeId))
      .get();

    if (!recipe) return { ok: false, error: 'Recipe not found' };

    // Create batch
    const batchId = createId();
    await db.insert(schema.batches).values({
      id: batchId,
      name,
      recipeId,
      qtyUnits,
      stage: 'plan',
      startDate: startMs,
      targetHarvestDate: null,
      locationId: null,
      notes: '',
      createdAt: now,
      updatedAt: now
    });

    // Generate tasks from recipe steps
    const steps = JSON.parse(recipe.steps) as any[];
    const schedule = generateSchedule(steps, startMs);
    for (const s of schedule) {
      await db.insert(schema.tasks).values({
        id: createId(),
        batchId,
        title: s.title,
        dueAt: s.dueAt,
        durationMin: s.durationMin,
        status: 'open',
        stepKey: s.stepKey,
        notes: '',
        createdAt: now,
        updatedAt: now
      });
    }

    throw redirect(303, '/');
  }
};
