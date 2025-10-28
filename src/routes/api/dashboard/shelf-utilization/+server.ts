import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { locationShelves, grows } from '$lib/db/schema';
import { eq, and, inArray } from 'drizzle-orm';

export const GET: RequestHandler = async ({ url }) => {
  const locationId = Number(url.searchParams.get('location_id'));
  if (!Number.isFinite(locationId)) {
    return json({ capacityCm2: 0, usedCm2: 0, percent: 0, itemsCounted: 0, shelvesCount: 0 });
  }

  const shelves = await db
    .select({
      id: locationShelves.id,
      lengthCm: locationShelves.lengthCm,
      widthCm: locationShelves.widthCm,
      levels: locationShelves.levels
    })
    .from(locationShelves)
    .where(eq(locationShelves.locationId, locationId));

  const shelvesCount = shelves.length;
  const capacityCm2 = shelves.reduce((sum, s) => {
    const L = Number(s.lengthCm ?? 0);
    const W = Number(s.widthCm ?? 0);
    const lv = Number(s.levels ?? 1);
    return sum + L * W * lv;
  }, 0);

  const active = await db
    .select({
      id: grows.id,
      status: grows.status,
      containerType: grows.containerType,
      containerConfig: grows.containerConfigJson
    })
    .from(grows)
    .where(and(eq(grows.locationId, locationId), inArray(grows.status, ['incubating', 'fruiting'])));

  const itemsCounted = active.length;
  const usedCm2 = active.reduce((sum, g) => {
    let area = 0;
    try {
      const cfg = g.containerConfig ? JSON.parse(String(g.containerConfig)) : {};
      const L = Number(cfg.length_cm ?? 0);
      const W = Number(cfg.width_cm ?? 0);
      if (L && W) area = L * W;
      else if (g.containerType === 'bag') area = 400; // heuristic
      else if (g.containerType === 'jar') area = 50;  // heuristic
      else area = 900;                                // default
    } catch {
      area = 900;
    }
    return sum + area;
  }, 0);

  const percent = capacityCm2 ? Math.min(100, Math.round((usedCm2 / capacityCm2) * 100)) : 0;

  return json({ capacityCm2, usedCm2, percent, itemsCounted, shelvesCount });
};

function json(obj: unknown, status = 200) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'content-type': 'application/json' }
  });
}
