import 'dotenv/config';
import { db } from '../src/lib/db/drizzle';
import { locations, locationMembers, users } from '../src/lib/db/schema';
import { eq } from 'drizzle-orm';

async function main() {
	const ownerUserId = 1;
	const name = 'Default Lab';
	const tz = 'America/Denver';

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

	console.log(JSON.stringify({ ok: true, location_id: locId }, null, 2));
}

main().catch((e) => {
	console.error(e);
	process.exit(1);
});
