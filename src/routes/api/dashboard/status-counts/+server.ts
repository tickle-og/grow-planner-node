import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { grows } from '$lib/db/schema';
import { eq, sql } from 'drizzle-orm';
import { json } from '$lib/server/http';

export const GET: RequestHandler = async ({ url }) => {
	try {
		const locationId = Number(url.searchParams.get('location_id') ?? '0');
		if (!locationId) return json({ pending: 0, active: 0, completed: 0, failed: 0, total: 0 });

		const rows = await db
			.select({
				status: grows.status,
				count: sql<number>`count(*)`.as('count')
			})
			.from(grows)
			.where(eq(grows.locationId, locationId))
			.groupBy(grows.status);

		const out = { pending: 0, active: 0, completed: 0, failed: 0 } as Record<string, number>;
		for (const r of rows) {
			const key = (r.status ?? '') as keyof typeof out;
			if (key in out) out[key] = Number((r as any).count ?? 0);
		}
		const total = out.pending + out.active + out.completed + out.failed;
		return json({ ...out, total });
	} catch {
		return new Response(JSON.stringify({ message: 'Internal Error' }), {
			status: 500,
			headers: { 'content-type': 'application/json; charset=utf-8' }
		});
	}
};
