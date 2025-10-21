// @ts-nocheck
// src/routes/recipes/+page.server.ts
import type { PageServerLoad } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { asc } from 'drizzle-orm';

export const load = async () => {
  const recipes = await db.select().from(schema.recipes).orderBy(asc(schema.recipes.name)).all();
  return { recipes };
};
;null as any as PageServerLoad;