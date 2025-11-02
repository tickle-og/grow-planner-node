# scripts/patch-shelves-endpoint.sh
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
 * - Works with older DBs that only had `name` by selecting COALESCE(label, name) AS label
 * - Always returns 200 with { ok, shelves: [] }
 */
export const GET: RequestHandler = async ({ params }) => {
  const locationId = Number(params.id);
  if (!Number.isFinite(locationId)) {
    return json({ ok: false, error: 'invalid location id' }, 400);
  }

  try {
    const rows = await db
      .select({
        id: locationShelves.id,
        locationId: locationShelves.locationId,
        // Use raw column names so legacy DBs without `label` won't explode on prepare
        label: sql<string>`COALESCE(label, name)`.as('label'),
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
    return jsonError(500);
  }
};

/**
 * POST /api/locations/:id/shelves
 * Body: { label, lengthCm, widthCm, heightCm, levels? }
 * - Returns 201 Created on success
 */
export const POST: RequestHandler = async ({ params, request }) => {
  const locationId = Number(params.id);
  if (!Number.isFinite(locationId)) {
    return json({ ok: false, error: 'invalid location id' }, 400);
  }

  try {
    const body = await request.json().catch(() => ({} as any));
    const { label, lengthCm, widthCm, heightCm, levels = 1 } = body ?? {};
    if (!label) return json({ ok: false, error: 'label required' }, 400);

    const inserted = await db
      .insert(locationShelves)
      .values({
        locationId,
        label,
        lengthCm,
        widthCm,
        heightCm,
        levels
      })
      .returning({ id: locationShelves.id });

    const id = inserted?.[0]?.id ?? null;
    return json({ ok: true, id }, 201);
  } catch {
    return jsonError(500);
  }
};
TS

echo "[✓] Patched shelves endpoint."
echo "Run tests with a separate DB to avoid locks:"
echo "  DB_URL='file:./dev_test.db' pnpm test"
