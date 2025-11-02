import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, url }) => {
  const locationId = Number(url.searchParams.get('locationId') ?? 1);
  const q = (p: string) => `/api/${p}${p.includes('?') ? '&' : '?'}locationId=${locationId}`;

  const [lowStock, activeGrows, recentYields, nextActions, activity, shelves] = await Promise.all([
    fetch(q('dashboard/low-stock')).then(r => r.json()).catch(() => ({ message: 'Internal Error' })),
    fetch(q('dashboard/active-grows')).then(r => r.json()).catch(() => ({ message: 'Internal Error' })),
    fetch(q('dashboard/recent-yields')).then(r => r.json()).catch(() => ({ message: 'Internal Error' })),
    fetch(q('dashboard/next-actions')).then(r => r.json()).catch(() => ({ message: 'Internal Error' })),
    fetch(q('dashboard/activity')).then(r => r.json()).catch(() => ({ message: 'Internal Error' })),
    // As a simple proxy for "Shelf Utilization", list shelves; fuller util later.
    fetch(`/api/locations/${locationId}/shelves`).then(r => r.json()).catch(() => ({ message: 'Internal Error' })),
  ]);

  return {
    locationId,
    lowStock,
    activeGrows,
    recentYields,
    nextActions,
    activity,
    shelves
  };
};
