import { json, jsonError } from '$lib/server/http';

import { json, jsonError } from '$lib/server/http';

import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { locations, locationMembers, users } from '$lib/db/schema';
import { eq } from 'drizzle-orm';

export const POST: RequestHandler = async ({ request }) => {
	try {
		const body = await request.json().catch(() => ({}));
		const ownerUserId = Number(body.owner_user_id ?? 1);
		const name = String(body.name ?? 'Default Lab');
		const tz = String(body.timezone ?? 'America/Denver');

		const [u] = await db.select().from(users).where(eq(users.id, ownerUserId)).limit(1);
		if (!u) {
			await db.insert(users).values({
				id: ownerUserId,
				username: `user${ownerUserId}`,
				email: `user${ownerUserId}@example.test`,
				passwordHash: 'dev',
				roleGlobal: 'admin',
				isActive: true
			} as any);
		}

		const [loc] = await db.select().from(locations).where(eq(locations.name, name)).limit(1);
		const locId =
			loc?.id ??
			(
				await db
					.insert(locations)
					.values({
						ownerUserId,
						name,
						nickname: 'Home',
						timezone: tz,
						isActive: true
					} as any)
					.returning({ id: locations.id })
			)[0].id;

		const [m] = await db
			.select()
			.from(locationMembers)
			.where(eq(locationMembers.locationId, locId))
			.limit(1);
		if (!m) {
			await db
				.insert(locationMembers)
				.values({ locationId: locId, userId: ownerUserId, memberRole: 'owner' } as any);
		}

		return json({ ok: true, location_id: locId }, 200);
	} catch (err: any) {
		console.error('ERROR /api/dev/seed/default-location:', err);
		return jsonError(500);
	}
};
