// src/routes/+page.server.ts
import type { PageServerLoad } from "./$types";
import { db } from "$lib/db/drizzle";
import { locations, locationMembers } from "$lib/db/schema";
import { eq, and } from "drizzle-orm";

async function resolveLocationId(event: Parameters<PageServerLoad>[0]): Promise<number | null> {
  const fromQuery = Number(event.url.searchParams.get("location_id"));
  if (Number.isFinite(fromQuery) && fromQuery > 0) return fromQuery;

  const fromCookie = Number(event.cookies.get("location_id"));
  if (Number.isFinite(fromCookie) && fromCookie > 0) return fromCookie;

  const uid = event.locals.user?.id ?? 1;
  const membership = await db
    .select({ id: locations.id })
    .from(locationMembers)
    .innerJoin(locations, eq(locations.id, locationMembers.locationId))
    .where(and(eq(locationMembers.userId, uid), eq(locations.isActive, true)))
    .limit(1);

  if (membership[0]?.id) return membership[0].id;

  const anyLoc = await db.select({ id: locations.id }).from(locations).limit(1);
  return anyLoc[0]?.id ?? null;
}

export const load: PageServerLoad = async (event) => {
  const locationId = await resolveLocationId(event);

  if (!locationId) return { locationId: null };

  event.cookies.set("location_id", String(locationId), {
    path: "/", httpOnly: false, sameSite: "lax", maxAge: 60 * 60 * 24 * 365
  });

  const qs = `?location_id=${locationId}`;
  const [statusCounts, activeGrows, lowStock, recentYields, activity, nextActions, shelfUtil, recentNotes, assetLocations] =
    await Promise.all([
      event.fetch(`/api/dashboard/status-counts${qs}`).then(r => r.json()),
      event.fetch(`/api/dashboard/active-grows${qs}&limit=8`).then(r => r.json()),
      event.fetch(`/api/dashboard/low-stock${qs}`).then(r => r.json()),
      event.fetch(`/api/dashboard/recent-yields${qs}&days=30`).then(r => r.json()),
      event.fetch(`/api/dashboard/activity${qs}&days=14&limit=20`).then(r => r.json()),
      event.fetch(`/api/dashboard/next-actions${qs}&limit=20`).then(r => r.json()),
      event.fetch(`/api/dashboard/shelf-utilization${qs}`).then(r => r.json()),
      event.fetch(`/api/dashboard/recent-notes${qs}`).then(r => r.json()).catch(() => ({ rows: [] })),
      event.fetch(`/api/dashboard/asset-locations${qs}`).then(r => r.json()).catch(() => ({ bins: [], assignments: [] })),
    ]);

  return { locationId, statusCounts, activeGrows, lowStock, recentYields, activity, nextActions, shelfUtil, recentNotes, assetLocations };
};
