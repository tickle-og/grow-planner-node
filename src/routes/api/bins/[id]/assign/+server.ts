import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { shelfBins, binAssignments, grows } from '$lib/db/schema';
import { and, eq, isNull } from 'drizzle-orm';

export const POST: RequestHandler = async ({ params, request }) => {
	const binId = Number(params.id);
	try {
		const body = await request.json();
		const { locationId, growId, groupLabel = null, notes = null } = body ?? {};
		if (!locationId)
			return new Response(JSON.stringify({ ok: false, error: 'locationId required' }), {
				status: 400
			});
		if (!growId)
			return new Response(JSON.stringify({ ok: false, error: 'growId required' }), { status: 400 });

		// Check bin exists + belongs to location
		const [bin] = await db.select().from(shelfBins).where(eq(shelfBins.id, binId)).limit(1);
		if (!bin)
			return new Response(JSON.stringify({ ok: false, error: `bin ${binId} not found` }), {
				status: 404
			});
		if (bin.locationId !== locationId) {
			return new Response(
				JSON.stringify({ ok: false, error: 'bin belongs to a different location' }),
				{ status: 409 }
			);
		}

		// Check grow exists + belongs to location
		const [grow] = await db
			.select()
			.from(grows)
			.where(eq(grows.id, Number(growId)))
			.limit(1);
		if (!grow)
			return new Response(JSON.stringify({ ok: false, error: `grow ${growId} not found` }), {
				status: 404
			});
		if (grow.locationId !== locationId) {
			return new Response(
				JSON.stringify({ ok: false, error: 'grow belongs to a different location' }),
				{ status: 409 }
			);
		}

		// Close any active assignment for this grow
		const active = await db
			.select({ id: binAssignments.id })
			.from(binAssignments)
			.where(and(eq(binAssignments.growId, grow.id), isNull(binAssignments.removedAt)));

		if (active.length) {
			await db
				.update(binAssignments)
				.set({ removedAt: new Date().toISOString() })
				.where(eq(binAssignments.id, active[0].id));
		}

		const [row] = await db
			.insert(binAssignments)
			.values({
				locationId,
				binId,
				growId: grow.id,
				groupLabel,
				notes,
				placedAt: new Date().toISOString()
			})
			.returning({ id: binAssignments.id });

		return new Response(JSON.stringify({ ok: true, id: row?.id }), { status: 201 });
	} catch (e: any) {
		return new Response(JSON.stringify({ ok: false, error: e?.message }), { status: 500 });
	}
};

export const DELETE: RequestHandler = async ({ params }) => {
	const binId = Number(params.id);
	try {
		// Soft-unassign: mark any active assignments on this bin as removed now
		const now = new Date().toISOString();
		await db
			.update(binAssignments)
			.set({ removedAt: now })
			.where(and(eq(binAssignments.binId, binId), isNull(binAssignments.removedAt)));

		return new Response(JSON.stringify({ ok: true, removedAt: now }), { status: 200 });
	} catch (e: any) {
		return new Response(JSON.stringify({ ok: false, error: e?.message }), { status: 500 });
	}
};
