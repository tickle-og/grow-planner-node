// src/routes/batches/+page.server.ts
import type { PageServerLoad } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { asc } from 'drizzle-orm';

export const load: PageServerLoad = async () => {
  const batches = await db.select().from(schema.batches).orderBy(asc(schema.batches.createdAt)).all();
  return { batches };
};
