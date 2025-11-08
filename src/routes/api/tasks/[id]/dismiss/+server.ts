import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { sql } from 'drizzle-orm';

export const POST: RequestHandler = async ({ params }) => {
	try {
		const id = Number(params.id);
		if (!Number.isFinite(id)) {
			return new Response(JSON.stringify({ ok: false, error: 'Invalid id' }), {
				status: 400,
				headers: { 'content-type': 'application/json' }
			});
		}

		// Persist the dismissal on the task
		await db.execute(sql`UPDATE tasks SET dismissed_at = CURRENT_TIMESTAMP WHERE id = ${id}`);

		return new Response(JSON.stringify({ ok: true, id, dismissed: true }), {
			status: 200,
			headers: { 'content-type': 'application/json' }
		});
	} catch (e: any) {
		return new Response(JSON.stringify({ ok: false, error: e?.message || String(e) }), {
			status: 500,
			headers: { 'content-type': 'application/json' }
		});
	}
};
