// src/routes/calendar/+page.server.ts
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, url }) => {
	const locationId = Number(url.searchParams.get('location_id') ?? 1);
	const res = await fetch(`/api/dashboard/next-actions?location_id=${locationId}&limit=200`);
	const data = res.ok ? await res.json() : { actions: [] };
	return {
		locationId,
		tasks: data.actions ?? []
	};
};
