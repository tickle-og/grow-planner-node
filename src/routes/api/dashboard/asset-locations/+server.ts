import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { shelfBins, locationShelves, binAssignments, grows } from '$lib/db/schema';
import { json, jsonError } from '$lib/server/http';
import { eq } from 'drizzle-orm';

export const GET: RequestHandler = async ({ url }) => {
	try {
		const locationId = Number(url.searchParams.get('location_id') ?? '');
		if (!Number.isFinite(locationId)) return json({ message: 'location_id required' }, 400);

		// bins + shelf label/name
		const bins = await db
			.select({
				id: shelfBins.id,
				shelfId: shelfBins.shelfId,
				binLabel: shelfBins.label,
				capacityCm2: shelfBins.capacityCm2,
				shelfName: locationShelves.name,
				shelfLabel: locationShelves.label
			})
			.from(shelfBins)
			.leftJoin(locationShelves, eq(shelfBins.shelfId, locationShelves.id))
			.where(eq(shelfBins.locationId, locationId));

		const binsNorm = bins.map((b) => ({
			id: b.id,
			shelfId: b.shelfId,
			label: b.binLabel,
			capacityCm2: b.capacityCm2,
			shelfLabel: b.shelfLabel ?? b.shelfName ?? null
		}));

		// active assignments
		const assignments = await db
			.select({
				id: binAssignments.id,
				binId: binAssignments.binId,
				growId: binAssignments.growId,
				groupLabel: binAssignments.groupLabel,
				placedAt: binAssignments.placedAt,
				removedAt: binAssignments.removedAt,
				status: grows.status,
				batchCode: grows.batchCode
			})
			.from(binAssignments)
			.leftJoin(grows, eq(binAssignments.growId, grows.id))
			.where(eq(binAssignments.locationId, locationId));

		return json({ bins: binsNorm, assignments }, 200);
	} catch {
		return jsonError(500);
	}
};
