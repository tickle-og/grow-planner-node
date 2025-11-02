// src/routes/recipes/+page.server.ts
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async () => {
  // Placeholder: avoids drizzle select/columns mismatch while WIP.
  return { recipes: [] };
};
