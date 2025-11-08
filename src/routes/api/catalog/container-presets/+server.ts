// src/routes/api/catalog/container-presets/+server.ts
import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { containerPresets } from '$lib/db/schema';
import { json, jsonError } from '$lib/server/http';

export const GET: RequestHandler = async () => {
	try {
		const rows = await db
			.select({
				key: containerPresets.key,
				containerType: containerPresets.containerType,
				label: containerPresets.label,
				defaultsJson: containerPresets.defaultsJson,
				active: containerPresets.active
			})
			.from(containerPresets);

		return json(rows, 200, {
			'cache-control': 'public, max-age=60, stale-while-revalidate=120'
		});
	} catch (e) {
		return jsonError(500);
	}
};
