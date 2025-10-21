// @ts-nocheck
import type { PageServerLoad } from './$types';
import { db, schema } from '$lib/db/drizzle';
import { eq } from 'drizzle-orm';
import { error } from '@sveltejs/kit';

export const load = async ({ params }: Parameters<PageServerLoad>[0]) => {
  const id = params.id;
  const recipe = db
    .select()
    .from(schema.recipes)
    .where(eq(schema.recipes.id, id))
    .get();
  if (!recipe) throw error(404, 'Recipe not found');
  const steps = JSON.parse(recipe.steps);
  const media = JSON.parse(recipe.media);
  return { recipe, steps, media };
};
