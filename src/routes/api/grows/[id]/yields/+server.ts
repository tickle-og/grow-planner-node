// src/routes/api/grows/[id]/yields/+server.ts
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { yield_data } from '$lib/db/schema';

export const POST: RequestHandler = async ({ request, params }) => {
	const growId = Number(params.id);
	try {
		const body = await request.json();
		const {
			flushIndex = 1,
			weightG,
			qualityGrade = null,
			capSizeAvgMm = null,
			stipeLengthAvgMm = null,
			contaminationFlag = 0
		} = body ?? {};

		if (!weightG)
			return new Response(JSON.stringify({ ok: false, error: 'weightG required' }), {
				status: 400
			});

		const [row] = await db
			.insert(yield_data)
			.values({
				grow_id: growId,
				flush_index: flushIndex,
				weight_g: Number(weightG),
				quality_grade: qualityGrade,
				cap_size_avg_mm: capSizeAvgMm,
				stipe_length_avg_mm: stipeLengthAvgMm,
				contamination_flag: contaminationFlag,
				created_at: new Date().toISOString().replace('T', ' ').slice(0, 19)
			})
			.returning({ id: yield_data.id });

		return new Response(JSON.stringify({ ok: true, id: row?.id }), { status: 201 });
	} catch (e: any) {
		return new Response(JSON.stringify({ ok: false, error: e?.message ?? String(e) }), {
			status: 500
		});
	}
};
