import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { locationShelves } from '$lib/db/schema';
import { json, jsonError } from '$lib/server/http';
import { eq } from 'drizzle-orm';

export const GET: RequestHandler = async ({ url }) => {
  try {
    const locationId = Number(url.searchParams.get('location_id') ?? '');
    if (!Number.isFinite(locationId)) return json({ message: 'location_id required' }, 400);

    const rows = await db.select({
      id: locationShelves.id,
      name: locationShelves.name,
      label: locationShelves.label,
      lengthCm: locationShelves.lengthCm,
      widthCm: locationShelves.widthCm,
      heightCm: locationShelves.heightCm,
      levels: locationShelves.levels
    })
    .from(locationShelves)
    .where(eq(locationShelves.locationId, locationId));

    const shelves = rows.map(r => ({
      id: r.id,
      label: r.label ?? r.name,
      lengthCm: r.lengthCm ?? null,
      widthCm: r.widthCm ?? null,
      heightCm: r.heightCm ?? null,
      levels: r.levels ?? 1
    }));

    return json({ locationId, count: shelves.length, shelves }, 200);
  } catch {
    return jsonError(500);
  }
};
