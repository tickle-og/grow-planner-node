// scripts/demo-seed.ts
import { db } from '../src/lib/db/drizzle';
import {
  locations,
  locationShelves,
  shelfBins,
} from '../src/lib/db/schema';
import { eq } from 'drizzle-orm';

async function ensureLocation(): Promise<number> {
  const existing = await db.select().from(locations).limit(1);
  if (existing.length) return existing[0].id;

  const [row] = await db
    .insert(locations)
    .values({
      ownerUserId: 1,
      name: 'Demo Lab',
      nickname: 'Demo',
      timezone: 'America/Denver',
      isActive: 1
    })
    .returning({ id: locations.id });

  return row.id;
}

async function ensureShelf(locationId: number): Promise<number> {
  const existing = await db
    .select({ id: locationShelves.id })
    .from(locationShelves)
    .where(eq(locationShelves.locationId, locationId))
    .limit(1);

  if (existing.length) return existing[0].id;

  const [row] = await db
    .insert(locationShelves)
    .values({
      locationId,
      name: 'Main Rack A',      // required by DB
      label: 'Main Rack A',
      lengthCm: 120,
      widthCm: 45,
      heightCm: 200,
      levels: 4
    })
    .returning({ id: locationShelves.id });

  return row.id;
}

async function ensureBins(locationId: number, shelfId: number) {
  // Upsert-ish: only add if there are no bins at this location yet
  const bins = await db
    .select({ id: shelfBins.id })
    .from(shelfBins)
    .where(eq(shelfBins.locationId, locationId))
    .limit(1);

  if (bins.length) return;

  await db.insert(shelfBins).values([
    { locationId, shelfId, label: 'Bin A', capacityCm2: 3000 },
    { locationId, shelfId, label: 'Bin B', capacityCm2: 2800 }
  ]);
}

async function main() {
  const locationId = await ensureLocation();
  const shelfId = await ensureShelf(locationId);
  await ensureBins(locationId, shelfId);
  console.log(JSON.stringify({ ok: true, locationId, shelfId }, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
