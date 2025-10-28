import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { shelfBins, binAssignments, locationShelves, grows } from '$lib/db/schema';
import { and, eq, isNull } from 'drizzle-orm';

export const GET: RequestHandler = async ({ url }) => {
  const locationId = Number(url.searchParams.get('location_id') ?? '0');
  if (!locationId) return new Response(JSON.stringify({ bins: [], assignments: [] }), { status: 200 });

  try {
    const bins = await db
      .select({
        id: shelfBins.id,
        label: shelfBins.label,
        capacityCm2: shelfBins.capacityCm2,
        shelfId: shelfBins.shelfId,
        shelfLabel: locationShelves.label
      })
      .from(shelfBins)
      .leftJoin(locationShelves, eq(shelfBins.shelfId, locationShelves.id))
      .where(eq(shelfBins.locationId, locationId));

    const assignments = await db
      .select({
        id: binAssignments.id,
        binId: binAssignments.binId,
        growId: binAssignments.growId,
        groupLabel: binAssignments.groupLabel,
        placedAt: binAssignments.placedAt,
        removedAt: binAssignments.removedAt,
        batchCode: grows.batchCode,
        status: grows.status
      })
      .from(binAssignments)
      .leftJoin(grows, eq(binAssignments.growId, grows.id))
      .where(and(eq(binAssignments.locationId, locationId), isNull(binAssignments.removedAt)));

    return new Response(JSON.stringify({ bins, assignments }), { status: 200 });
  } catch (e: any) {
    return new Response(JSON.stringify({ bins: [], assignments: [], error: e?.message }), { status: 500 });
  }
};
