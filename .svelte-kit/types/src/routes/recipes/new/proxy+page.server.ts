// @ts-nocheck
// src/routes/recipes/new/+page.server.ts
import type { Actions, PageServerLoad } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { createId } from '@paralleldrive/cuid2';
import { z } from 'zod';
import { redirect } from '@sveltejs/kit';

export const load = async () => ({});

const StepsSchema = z.array(z.object({
  key: z.string().min(1),
  title: z.string().min(1),
  duration: z.union([z.string(), z.number()]).optional(),
  depends_on: z.array(z.string()).optional()
}));

export const actions = {
  create: async ({ request }: import('./$types').RequestEvent) => {
    const form = await request.formData();
    const name = String(form.get('name') ?? '').trim();
    const description = String(form.get('description') ?? '').trim();
    const defaultScale = Number(form.get('defaultScale') ?? 1);
    const media_json = String(form.get('media_json') ?? '{}').trim() || '{}';
    const steps_json_raw = String(form.get('steps_json') ?? '[]').trim() || '[]';

    if (!name) return { ok: false, error: 'Name is required' };

    let steps_json: unknown;
    try {
      steps_json = JSON.parse(steps_json_raw);
      StepsSchema.parse(steps_json);
    } catch (e) {
      return { ok: false, error: 'Invalid steps JSON: ' + (e as Error).message };
    }

    let media: unknown;
    try {
      media = JSON.parse(media_json);
    } catch (e) {
      return { ok: false, error: 'Invalid media JSON: ' + (e as Error).message };
    }

    const now = Date.now();
    const id = createId();
    await db.insert(schema.recipes).values({
      id,
      name,
      version: 1,
      description,
      defaultScale: Number.isFinite(defaultScale) ? defaultScale : 1,
      media: JSON.stringify(media),
      steps: JSON.stringify(steps_json),
      createdAt: now,
      updatedAt: now
    });

    throw redirect(303, '/recipes');
  }
};
;null as any as PageServerLoad;;null as any as Actions;