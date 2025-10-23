// src/routes/api/dev/seed/+server.ts
import type { RequestHandler } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { generateSchedule } from '$lib/logic/scheduler';
import { createId } from '@paralleldrive/cuid2';

export const GET: RequestHandler = async () => {
  const { recipes, batches, tasks } = schema;

  // If tasks exist, don't re-seed
  const existing = await db.select().from(tasks).limit(1).get();
  if (existing) {
    return new Response('already seeded', { status: 200 });
  }

  const now = Date.now();
  const recipeId = createId();
  const batchId = createId();

  // Grain-first language
  const steps = [
    { key: 'hydrate_grain',   title: 'Hydrate grain',                 duration: '12h' },
    { key: 'sterilize_grain', title: 'Sterilize grain (PC 120m)',     duration: '2h',  depends_on: ['hydrate_grain'] },
    { key: 'cool',            title: 'Cool down',                     duration: '8h',  depends_on: ['sterilize_grain'] },
    { key: 'inoc',            title: 'Inoculate LC → grain',          duration: '0m',  depends_on: ['cool'] },
    { key: 'spawn',           title: 'Spawn to bulk',                 duration: '14d', depends_on: ['inoc'] },
    { key: 'fruit',           title: 'Open for fruiting',             duration: '4d',  depends_on: ['spawn'] },
    { key: 'harvest',         title: 'Harvest (flush #1)',            duration: '0m',  depends_on: ['fruit'] }
  ];

  await db.insert(recipes).values({
    id: recipeId,
    name: 'Monotub 3.5 lb Flow (Demo)',
    version: 1,
    description: 'Demo recipe for development',
    defaultScale: 20,
    media: JSON.stringify({ grain: 'milo', bulk_substrate: 'coir/verm/gypsum' }),
    steps: JSON.stringify(steps),
    createdAt: now,
    updatedAt: now
  });

  // Start 2 days ago so some items appear as overdue/today
  const startMs = now - 2 * 24 * 60 * 60_000;

  await db.insert(batches).values({
    id: batchId,
    name: 'Batch #24 (Demo)',
    recipeId,
    qtyUnits: 20,
    stage: 'plan',
    startDate: startMs,
    targetHarvestDate: null,
    locationId: null,
    notes: 'seed data',
    createdAt: now,
    updatedAt: now
  });

  const schedule = generateSchedule(steps as any, startMs);
  for (const s of schedule) {
    await db.insert(tasks).values({
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

  return new Response('ok', { status: 200 });
};
