import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, url }) => {
  const locationId = Number(url.searchParams.get('location_id') ?? 1);
  const qs = (p: string) => `${p}?location_id=${locationId}`;

  const [lowStockRes, yieldsRes, utilRes, tasksRes] = await Promise.all([
    fetch(qs('/api/dashboard/low-stock')),
    fetch(qs('/api/dashboard/recent-yields')),
    fetch(qs('/api/dashboard/shelf-util')),
    fetch(qs('/api/dashboard/next-actions'))
  ]);

  const lowStock = lowStockRes.ok ? await lowStockRes.json() : { message: 'Internal Error' };
  const recentYields = yieldsRes.ok ? await yieldsRes.json() : { message: 'Internal Error' };
  const shelfUtil = utilRes.ok ? await utilRes.json() : { message: 'Internal Error' };
  const upcomingTasks = tasksRes.ok ? await tasksRes.json() : { message: 'Internal Error' };

  return { locationId, lowStock, recentYields, shelfUtil, upcomingTasks };
};
