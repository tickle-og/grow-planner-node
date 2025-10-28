#!/usr/bin/env bash
set -euo pipefail

root="$(pwd)"

# 1) Write robust GET+POST for shelves (uses name+label; coalesces for UI)
mkdir -p src/routes/api/locations/[id]/shelves
cat > src/routes/api/locations/[id]/shelves/+server.ts <<'TS'
// src/routes/api/locations/[id]/shelves/+server.ts
import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { locationShelves } from '$lib/db/schema';
import { json, jsonError } from '$lib/server/http';
import { eq } from 'drizzle-orm';
import { z } from 'zod';

const Body = z.object({
  name: z.string().min(1).optional(),
  label: z.string().min(1).optional(),
  lengthCm: z.number().int().positive().optional(),
  widthCm: z.number().int().positive().optional(),
  heightCm: z.number().int().positive().optional(),
  levels: z.number().int().positive().default(1).optional()
});

export const POST: RequestHandler = async ({ params, request }) => {
  try {
    const locationId = Number(params.id);
    if (!Number.isFinite(locationId)) return json({ ok:false, error:'invalid location id' }, 400);

    const raw = await request.json().catch(() => ({}));
    const parsed = Body.safeParse(raw);
    if (!parsed.success) {
      return json({ ok:false, error: parsed.error.errors.map(e=>e.message).join(', ') }, 400);
    }

    const b = parsed.data;
    const name = (b.name?.trim() || b.label?.trim());
    if (!name) return json({ ok:false, error:'name or label required' }, 400);

    const [row] = await db.insert(locationShelves).values({
      locationId,
      name,                     // DB requires NOT NULL
      label: b.label ?? null,   // optional nicety
      lengthCm: b.lengthCm ?? null,
      widthCm:  b.widthCm  ?? null,
      heightCm: b.heightCm ?? null,
      levels:   b.levels   ?? 1
    }).returning({ id: locationShelves.id });

    return json({ ok:true, id: row.id }, 201);
  } catch (e) {
    console.error('POST /locations/:id/shelves failed:', e);
    return jsonError(500);
  }
};

export const GET: RequestHandler = async ({ params }) => {
  try {
    const locationId = Number(params.id);
    if (!Number.isFinite(locationId)) return json({ ok:false, error:'invalid location id' }, 400);

    const rows = await db.select({
      id:       locationShelves.id,
      name:     locationShelves.name,
      label:    locationShelves.label,
      lengthCm: locationShelves.lengthCm,
      widthCm:  locationShelves.widthCm,
      heightCm: locationShelves.heightCm,
      levels:   locationShelves.levels
    }).from(locationShelves)
      .where(eq(locationShelves.locationId, locationId));

    const shelves = rows.map(r => ({
      id: r.id,
      label: r.label ?? r.name,   // always have something displayable
      name: r.name,
      lengthCm: r.lengthCm ?? null,
      widthCm:  r.widthCm  ?? null,
      heightCm: r.heightCm ?? null,
      levels:   r.levels   ?? 1
    }));

    return json({ ok:true, count: shelves.length, shelves }, 200);
  } catch (e) {
    console.error('GET /locations/:id/shelves failed:', e);
    return jsonError(500);
  }
};
TS

# 2) Ensure a backfill migration exists for old rows without name
mkdir -p drizzle
if ! grep -q "backfill_shelves_name" -R drizzle 2>/dev/null; then
  cat > drizzle/0002_backfill_shelves_name.sql <<'SQL'
BEGIN;
UPDATE location_shelves
SET name = COALESCE(NULLIF(name, ''), COALESCE(label, 'Shelf ' || id))
WHERE name IS NULL OR name = '';
COMMIT;
SQL
fi

# 3) Run migrations
pnpm drizzle-kit migrate

echo
echo "[ok] Shelves endpoint updated and migrations applied."
echo
echo "Smoke tests:"
echo "  # Create a shelf"
echo "  curl -s -X POST http://localhost:5173/api/locations/1/shelves \\"
echo "    -H 'content-type: application/json' \\"
echo "    -d '{\"label\":\"Main Rack A\",\"lengthCm\":120,\"widthCm\":45,\"heightCm\":200,\"levels\":4}' | jq ."
echo
echo "  # List shelves"
echo "  curl -s http://localhost:5173/api/locations/1/shelves | jq ."
