import { json, jsonError } from '$lib/server/http';

import { json, jsonError } from '$lib/server/http';

// src/routes/api/dashboard/recent-notes/+server.ts
import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { sql } from 'drizzle-orm';
import { getLocationIdOrThrow } from '../_util';

export const GET: RequestHandler = async (event) => {
	try {
		const locationId = getLocationIdOrThrow(event);

		// Try yield_data.notes
		let parts: Array<{ ts: string; source: string; note: string; growId?: number }> = [];
		try {
			// @ts-ignore raw SQL for resilience to schema drift
			const y = await db.execute(
				sql`SELECT harvest_date AS ts, 'yield' AS source, notes AS note, grow_id AS growId
            FROM yield_data
            WHERE location_id = ${locationId} AND notes IS NOT NULL AND TRIM(notes) <> ''
            ORDER BY datetime(ts) DESC LIMIT 10`
			);
			// libsql returns rows in y.rows; better-sqlite3 returns y as any[]
			const yr = Array.isArray(y) ? y : (y.rows ?? []);
			parts.push(...(yr as any));
		} catch {}

		if (parts.length < 10) {
			try {
				const g = await db.execute(
					sql`SELECT COALESCE(updated_at, start_date) AS ts, 'grow' AS source, notes AS note, id AS growId
              FROM grows
              WHERE location_id = ${locationId} AND notes IS NOT NULL AND TRIM(notes) <> ''
              ORDER BY datetime(ts) DESC LIMIT ${10 - parts.length}`
				);
				const gr = Array.isArray(g) ? g : (g.rows ?? []);
				parts.push(...(gr as any));
			} catch {}
		}

		parts.sort((a, b) => String(b.ts).localeCompare(String(a.ts)));
		parts = parts.slice(0, 10);

		return json({ locationId, rows: parts }, 200);
	} catch (err: any) {
		console.error('GET /api/dashboard/recent-notes:', err);
		return jsonError(500);
	}
};
