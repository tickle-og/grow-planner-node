import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { locations, shelfBins, locationShelves } from '$lib/db/schema';
import { and, eq, isNull, desc } from 'drizzle-orm';

export const GET: RequestHandler = async ({ params }) => {
	const locationId = Number(params.id);
	try {
		const bins = await db
			.select({
				id: shelfBins.id,
				locationId: shelfBins.locationId,
				shelfId: shelfBins.shelfId,
				label: shelfBins.label,
				capacityCm2: shelfBins.capacityCm2,
				createdAt: shelfBins.createdAt,
				shelfLabel: locationShelves.label
			})
			.from(shelfBins)
			.leftJoin(locationShelves, eq(shelfBins.shelfId, locationShelves.id))
			.where(eq(shelfBins.locationId, locationId))
			.orderBy(desc(shelfBins.id));

		return new Response(JSON.stringify(bins), { status: 200 });
	} catch (e: any) {
		return new Response(JSON.stringify({ ok: false, error: e?.message }), { status: 500 });
	}
};

export const POST: RequestHandler = async ({ params, request }) => {
	const locationId = Number(params.id);
	try {
		const [loc] = await db.select().from(locations).where(eq(locations.id, locationId)).limit(1);
		if (!loc)
			return new Response(
				JSON.stringify({ ok: false, error: `location ${locationId} not found` }),
				{ status: 404 }
			);

		const body = await request.json();
		const { label, capacityCm2 = null, shelfId = null } = body ?? {};
		if (!label)
			return new Response(JSON.stringify({ ok: false, error: 'label required' }), { status: 400 });

		// If shelfId provided, ensure shelf belongs to same location
		if (shelfId != null) {
			const [shelf] = await db
				.select({ id: locationShelves.id, locationId: locationShelves.locationId })
				.from(locationShelves)
				.where(eq(locationShelves.id, Number(shelfId)))
				.limit(1);
			if (!shelf)
				return new Response(JSON.stringify({ ok: false, error: `shelf ${shelfId} not found` }), {
					status: 404
				});
			if (shelf.locationId !== locationId) {
				return new Response(
					JSON.stringify({ ok: false, error: 'shelf belongs to a different location' }),
					{ status: 409 }
				);
			}
		}

		const [row] = await db
			.insert(shelfBins)
			.values({ locationId, shelfId, label, capacityCm2 })
			.returning({ id: shelfBins.id });

		return new Response(JSON.stringify({ ok: true, id: row?.id }), { status: 201 });
	} catch (e: any) {
		return new Response(JSON.stringify({ ok: false, error: e?.message }), { status: 500 });
	}
};
