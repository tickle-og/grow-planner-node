import { json, jsonError } from '$lib/server/http';

import { json, jsonError } from '$lib/server/http';

import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { locationShelves, locations } from '$lib/db/schema';
import { eq } from 'drizzle-orm';

export const GET: RequestHandler = async ({ params }) => {
  const locationId = Number(params.id);
  try {
    const rows = await db
      .select()
      .from(locationShelves)
      .where(eq(locationShelves.locationId, locationId));
    return json(rows, 200);
  } catch (e: any) {
    return jsonError(500);
  }
};

export const POST: RequestHandler = async ({ request, params }) => {
  const locationId = Number(params.id);
  try {
    // 1) verify the location exists (prevents FK surprises)
    const [loc] = await db.select().from(locations).where(eq(locations.id, locationId)).limit(1);
    if (!loc) {
      return jsonError(500);
  }
};
