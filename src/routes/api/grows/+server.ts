import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { grows, locations, users } from '$lib/db/schema';
import { eq } from 'drizzle-orm';

export const GET: RequestHandler = async ({ url }) => {
  const locationId = Number(url.searchParams.get('location_id') ?? '0') || undefined;
  try {
    const rows = locationId
      ? await db.select().from(grows).where(eq(grows.locationId, locationId))
      : await db.select().from(grows);
    return new Response(JSON.stringify(rows), { status: 200 });
  } catch (e: any) {
    return new Response(JSON.stringify({ ok: false, error: e?.message }), { status: 500 });
  }
};

export const POST: RequestHandler = async ({ request }) => {
  try {
    const body = await request.json();
    const {
      locationId,
      createdByUserId,
      status = 'planning',
      batchCode = null,
      containerType = null,
      containerPresetKey = null,
      containerConfig = null,
      notes = null
    } = body ?? {};

    if (!locationId) return new Response(JSON.stringify({ ok: false, error: 'locationId required' }), { status: 400 });
    if (!createdByUserId) return new Response(JSON.stringify({ ok: false, error: 'createdByUserId required' }), { status: 400 });

    // FK sanity
    const [loc] = await db.select().from(locations).where(eq(locations.id, Number(locationId))).limit(1);
    if (!loc) return new Response(JSON.stringify({ ok: false, error: `location ${locationId} not found` }), { status: 404 });

    const [usr] = await db.select().from(users).where(eq(users.id, Number(createdByUserId))).limit(1);
    if (!usr) return new Response(JSON.stringify({ ok: false, error: `user ${createdByUserId} not found` }), { status: 404 });

    const now = new Date().toISOString();
    const cfg = containerConfig && typeof containerConfig !== 'string'
      ? JSON.stringify(containerConfig)
      : containerConfig;

    const [row] = await db
      .insert(grows)
      .values({
        locationId,
        createdByUserId,
        status,
        batchCode,
        containerType,
        containerPresetKey,
        containerConfig: cfg,
        notes,
        updatedAt: now // satisfy NOT NULL updated_at if your DB enforces it
      })
      .returning({ id: grows.id });

    return new Response(JSON.stringify({ ok: true, id: row?.id }), { status: 201 });
  } catch (e: any) {
    return new Response(JSON.stringify({ ok: false, error: e?.message }), { status: 500 });
  }
};
