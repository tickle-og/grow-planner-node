import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, url }) => {
	const locationId = Number(url.searchParams.get('location_id') ?? 1);
	const qs = (p: string) => `${p}?location_id=${locationId}`;

	const [statusRes, nextRes] = await Promise.all([
		fetch(qs('/api/dashboard/status-counts')),
		fetch(qs('/api/dashboard/next-actions'))
	]);

	const statusCounts = statusRes.ok
		? await statusRes.json()
		: { pending: 0, active: 0, completed: 0, failed: 0, total: 0 };

	const nextActions = nextRes.ok ? await nextRes.json() : { ok: true, items: [] };

	return { locationId, statusCounts, nextActions };
};
