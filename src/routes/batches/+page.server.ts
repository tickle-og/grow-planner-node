// src/routes/batches/+page.server.ts
import type { PageServerLoad } from './$types';
export const load: PageServerLoad = async () => {
  // Placeholder: keeps the page functional without DB shape assumptions.
  return { batches: [] };
};
