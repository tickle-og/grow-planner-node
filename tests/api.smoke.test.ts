import { describe, it, expect, beforeAll } from 'vitest';
import { db } from '../src/lib/db/drizzle';
import { locations, locationShelves, shelfBins } from '../src/lib/db/schema';
import { eq } from 'drizzle-orm';

// Import handlers directly (no dev server needed)
import * as ShelvesHandlers from '../src/routes/api/locations/[id]/shelves/+server';
import * as PresetsHandlers from '../src/routes/api/catalog/container-presets/+server';
import * as JarsHandlers from '../src/routes/api/catalog/jar-variants/+server';

// minimal mock of SvelteKit's RequestEvent for our handlers
function mkEvent(method: string, url: string, body?: any, params?: Record<string, string>) {
	const init: RequestInit = { method, headers: { 'content-type': 'application/json' } };
	if (body !== undefined) init.body = JSON.stringify(body);
	return {
		request: new Request(url, init),
		params: params ?? {},
		url: new URL(url)
		// the rest of RequestEvent props aren't needed by our handlers
	} as any;
}

let locationId = 1;

describe('API Smoke', () => {
	beforeAll(async () => {
		// Ensure demo seed is present (idempotent)
		const locs = await db.select().from(locations).limit(1);
		if (locs.length) {
			locationId = locs[0].id;
		} else {
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
			locationId = row.id;
		}

		const shelves = await db
			.select()
			.from(locationShelves)
			.where(eq(locationShelves.locationId, locationId))
			.limit(1);

		if (!shelves.length) {
			await db.insert(locationShelves).values({
				locationId,
				name: 'Main Rack A',
				label: 'Main Rack A',
				lengthCm: 120,
				widthCm: 45,
				heightCm: 200,
				levels: 4
			});
		}

		const bins = await db
			.select()
			.from(shelfBins)
			.where(eq(shelfBins.locationId, locationId))
			.limit(1);

		if (!bins.length) {
			const shelf = await db
				.select({ id: locationShelves.id })
				.from(locationShelves)
				.where(eq(locationShelves.locationId, locationId))
				.limit(1);
			await db.insert(shelfBins).values([
				{ locationId, shelfId: shelf[0].id, label: 'Bin A', capacityCm2: 3000 },
				{ locationId, shelfId: shelf[0].id, label: 'Bin B', capacityCm2: 2800 }
			]);
		}
	});

	it('GET /api/catalog/container-presets returns array', async () => {
		const res = await PresetsHandlers.GET(
			mkEvent('GET', 'http://local/api/catalog/container-presets')
		);
		expect(res.status).toBe(200);
		const data = await res.json();
		expect(Array.isArray(data)).toBe(true);
	});

	it('GET /api/catalog/jar-variants returns array', async () => {
		const res = await JarsHandlers.GET(mkEvent('GET', 'http://local/api/catalog/jar-variants'));
		expect(res.status).toBe(200);
		const data = await res.json();
		expect(Array.isArray(data)).toBe(true);
	});

	it('GET /api/locations/:id/shelves returns shelves', async () => {
		const res = await ShelvesHandlers.GET(
			mkEvent('GET', `http://local/api/locations/${locationId}/shelves`, undefined, {
				id: String(locationId)
			})
		);
		expect(res.status).toBe(200);
		const data = await res.json();
		expect(data.ok).toBe(true);
		expect(Array.isArray(data.shelves)).toBe(true);
		expect(data.shelves.length).toBeGreaterThan(0);
		// each shelf has a label (name fallback happens in handler)
		expect(data.shelves[0].label).toBeTruthy();
	});

	it('POST /api/locations/:id/shelves creates a shelf', async () => {
		const res = await ShelvesHandlers.POST(
			mkEvent(
				'POST',
				`http://local/api/locations/${locationId}/shelves`,
				{ label: 'Smoke Rack', lengthCm: 90, widthCm: 40, heightCm: 180, levels: 3 },
				{ id: String(locationId) }
			)
		);
		expect(res.status).toBe(201);
		const data = await res.json();
		expect(data.ok).toBe(true);
		expect(typeof data.id).toBe('number');
	});
});
