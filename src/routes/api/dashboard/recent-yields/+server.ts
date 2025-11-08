import type { RequestHandler } from './$types';
import { json, jsonError } from '$lib/server/http';
import { getLocationIdOrThrow } from '../_util';

export const GET: RequestHandler = async (event) => {
	try {
		const locationId = getLocationIdOrThrow(event.url ?? new URL(event.request.url));
		return json(200, {
			ok: true,
			locationId,
			days: 30,
			totals: { wetWeightG: 0, dryWeightG: 0 },
			rows: []
		});
	} catch (e: any) {
		console.error('recent-yields error:', e);
		return jsonError(400, { message: e?.message ?? 'Bad Request' });
	}
};
