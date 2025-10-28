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
    if (!Number.isFinite(locationId)) return json({ ok: false, error: 'invalid location id' }, 400);

    const raw = await request.json().catch(() => ({}));
    const parsed = Body.safeParse(raw);
    if (!parsed.success) {
      return json({ ok: false, error: parsed.error.errors.map(e => e.message).join(', ') }, 400);
    }

    const b = parsed.data;
    const name = (b.name?.trim() || b.label?.trim());
    if (!name) return json({ ok: false, error: 'name or label required' }, 400);

    const [row] = await db
      .insert(locationShelves)
      .values({
        locationId,
        name,                   // DB requires NOT NULL
        label: b.label ?? null, // optional nicety
        lengthCm: b.lengthCm ?? null,
        widthCm: b.widthCm ?? null,
        heightCm: b.heightCm ?? null,
        levels: b.levels ?? 1
      })
      .returning({ id: locationShelves.id });

    return json({ ok: true, id: row.id }, 201);
  } catch (e) {
    console.error('POST /locations/:id/shelves failed:', e);
    return jsonError(500);
  }
};

export const GET: RequestHandler = async ({ params }) => {
  try {
    const locationId = Number(params.id);
    if (!Number.isFinite(locationId)) return json({ ok: false, error: 'invalid location id' }, 400);

    // Safer: select * (drizzle typed) and normalize in JS.
    const rows = await db
      .select()
      .from(locationShelves)
      .where(eq(locationShelves.locationId, locationId));

    // Normalize keys defensively in case schema jittered:
    const shelves = rows.map((r: any) => ({
      id: r.id,
      // always give UI something to show:
      label: r.label ?? r.name ?? `Shelf ${r.id}`,
      name: r.name ?? r.label ?? `Shelf ${r.id}`,
      // prefer camelCase (drizzle field names); fall back to raw snake just in case
      lengthCm: r.lengthCm ?? r.length_cm ?? null,
      widthCm:  r.widthCm  ?? r.width_cm  ?? null,
      heightCm: r.heightCm ?? r.height_cm ?? null,
      levels:   r.levels ?? 1
    }));

    return json({ ok: true, count: shelves.length, shelves }, 200);
  } catch (e) {
    console.error('GET /locations/:id/shelves failed:', e);
    return jsonError(500);
  }
};
