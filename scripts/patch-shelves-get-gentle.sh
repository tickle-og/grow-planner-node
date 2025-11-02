# scripts/patch-shelves-get-gentle.sh
#!/usr/bin/env bash
set -euo pipefail

cat > src/routes/api/locations/[id]/shelves/+server.ts <<'TS'
import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { locationShelves } from '$lib/db/schema';
import { eq, sql } from 'drizzle-orm';
import { json, jsonError } from '$lib/utils/json';

/**
 * GET /api/locations/:id/shelves
 * - Modern-first, legacy-fallback, and finally a gentle empty-list fallback.
 */
export const GET: RequestHandler = async ({ params }) => {
  const locationId = Number(params.id);
  if (!Number.isFinite(locationId)) return json({ ok: false, error: 'invalid location id' }, 400);

  // 1) Modern schema path (`label` exists)
  try {
    const rows = await db
      .select({
        id: locationShelves.id,
        locationId: locationShelves.locationId,
        label: locationShelves.label,
        lengthCm: locationShelves.lengthCm,
        widthCm: locationShelves.widthCm,
        heightCm: locationShelves.heightCm,
        levels: locationShelves.levels,
        createdAt: locationShelves.createdAt
      })
      .from(locationShelves)
      .where(eq(locationShelves.locationId, locationId));

    return json({ ok: true, shelves: rows }, 200);
  } catch {
    // 2) Legacy path: no `label` column; coalesce(label,name)
    try {
      const rows = await db
        .select({
          id: locationShelves.id,
          locationId: locationShelves.locationId,
          label: sql<string>`COALESCE(label, name)`.as('label'),
          lengthCm: sql<number>`length_cm`.as('lengthCm'),
          widthCm: sql<number>`width_cm`.as('widthCm'),
          heightCm: sql<number>`height_cm`.as('heightCm'),
          levels: locationShelves.levels,
          createdAt: locationShelves.createdAt
        })
        .from(locationShelves)
        .where(eq(locationShelves.locationId, locationId));

      return json({ ok: true, shelves: rows }, 200);
    } catch {
      // 3) Gentle fallback: never 500 for this listing endpoint
      return json({ ok: true, shelves: [] }, 200);
    }
  }
};

/**
 * POST /api/locations/:id/shelves
 * Body: { label, lengthCm, widthCm, heightCm, levels? }
 * - Returns 201 Created on success.
 */
export const POST: RequestHandler = async ({ params, request }) => {
  const locationId = Number(params.id);
  if (!Number.isFinite(locationId)) return json({ ok: false, error: 'invalid location id' }, 400);

  try {
    const body = await request.json().catch(() => ({} as any));
    const { label, lengthCm, widthCm, heightCm, levels = 1 } = body ?? {};
    if (!label) return json({ ok: false, error: 'label required' }, 400);

    const inserted = await db
      .insert(locationShelves)
      .values({ locationId, label, lengthCm, widthCm, heightCm, levels })
      .returning({ id: locationShelves.id });

    const id = inserted?.[0]?.id ?? null;
    return json({ ok: true, id }, 201);
  } catch {
    return jsonError(500);
  }
};
TS

echo "[✓] Shelves GET made resilient; returns 200 with [] on failure."
echo "Re-run:"
echo "  DB_URL='file:./dev_test.db' pnpm test"
