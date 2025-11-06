# scripts/harden-today-loader.sh
set -euo pipefail
FILE="src/routes/+page.server.ts"
mkdir -p "$(dirname "$FILE")"
cp -n "$FILE" "$FILE.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

cat > "$FILE" <<'TS'
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, url }) => {
  const locationId = Number(url.searchParams.get('location_id') ?? 1);

  const safe = async <T>(path: string, fallback: T): Promise<T> => {
    try {
      const res = await fetch(path, { headers: { 'accept': 'application/json' } });
      if (!res.ok) return fallback as T;
      return (await res.json()) as T;
    } catch {
      return fallback as T;
    }
  };

  const statusCounts = await safe(`/api/dashboard/status-counts?location_id=${locationId}`, {
    pending: 0, active: 0, completed: 0, failed: 0, total: 0
  });

  const activeGrows = await safe(`/api/dashboard/active-grows?location_id=${locationId}`, {
    locationId, rows: []
  });

  const lowStock = await safe(`/api/dashboard/low-stock?location_id=${locationId}`, {
    locationId, rows: []
  });

  const recentYields = await safe(`/api/dashboard/recent-yields?location_id=${locationId}`, {
    locationId, days: 30, totals: { wetWeightG: 0, dryWeightG: 0 }, rows: []
  });

  const activity = await safe(`/api/dashboard/activity?location_id=${locationId}`, {
    locationId, days: 14, count: 0, items: []
  });

  // Even if the endpoint fails, the page now has a defined shape.
  const nextActions = await safe(`/api/dashboard/next-actions?location_id=${locationId}`, {
    locationId, count: 0, actions: []
  });

  // May not exist yet; still safe to include
  const shelfUtil = await safe(`/api/dashboard/shelf-util?location_id=${locationId}`, {
    locationId, rows: []
  });

  const recentNotes = await safe(`/api/dashboard/recent-notes?location_id=${locationId}`, {
    locationId, rows: []
  });

  // Basic location fallback to avoid null deref in templates
  const locationRow = await safe(`/api/locations/${locationId}`, {
    id: locationId, name: 'Default Lab', nickname: 'Home'
  });

  return {
    locationId,
    statusCounts,
    activeGrows,
    lowStock,
    recentYields,
    activity,
    nextActions,
    shelfUtil,
    recentNotes,
    assetLocations: locationRow
  };
};
TS

echo "[ok] Hardened Today loader with safe fallbacks: $FILE"
