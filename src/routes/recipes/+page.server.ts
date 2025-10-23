import type { PageServerLoad } from './$types';
import { db } from '$lib/db/drizzle';
import { recipes } from '$lib/db/schema';
import { sql } from 'drizzle-orm';

export const load: PageServerLoad = async () => {
  // ORDER BY name, case-insensitive (SQLite)
  const list = await db
    .select({
      id: recipes.id,
      name: recipes.name,
      type: recipes.type,
      version: recipes.version,
      isDefault: recipes.isDefault,
    })
    .from(recipes)
    .orderBy(sql`name collate nocase`);

  return { list };
};
