import type { PageServerLoad } from './$types';
import { db } from '$lib/db/drizzle';
import { supplies } from '$lib/db/schema';
import { sql } from 'drizzle-orm';

export const load: PageServerLoad = async () => {
	const list = await db
		.select()
		.from(supplies)
		.orderBy(sql`name collate nocase`);
	return { list };
};
