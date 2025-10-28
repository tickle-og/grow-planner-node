import { json, jsonError } from '$lib/server/http';

import { json, jsonError } from '$lib/server/http';

import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { locations } from '$lib/db/schema';
import { eq } from 'drizzle-orm';

export const GET: RequestHandler = async ({ params }) => {
  const id = Number(params.id);
  try {
    const [row] = await db.select().from(locations).where(eq(locations.id, id)).limit(1);
    if (!row) return jsonError(500);
  }
};
