import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { locationShelves, locations } from '$lib/db/schema';
import { eq } from 'drizzle-orm';

export const GET: RequestHandler = async ({ params }) => {
  const locationId = Number(params.id);
  try {
    const rows = await db
      .select()
      .from(locationShelves)
      .where(eq(locationShelves.locationId, locationId));
    return new Response(JSON.stringify(rows), { status: 200 });
  } catch (e: any) {
    return new Response(JSON.stringify({ ok: false, error: e?.message, detail: e?.cause?.message }), { status: 500 });
  }
};

export const POST: RequestHandler = async ({ request, params }) => {
  const locationId = Number(params.id);
  try {
    // 1) verify the location exists (prevents FK surprises)
    const [loc] = await db.select().from(locations).where(eq(locations.id, locationId)).limit(1);
    if (!loc) {
      return new Response(
        JSON.stringify({ ok: false, error: `location ${locationId} not found in this database` }),
        { status: 404 }
      );
    }

    // 2) create shelf
    const body = await request.json();
    const { label, lengthCm, widthCm, heightCm, levels = 1 } = body ?? {};
    if (!label) return new Response(JSON.stringify({ ok: false, error: 'label required' }), { status: 400 });

    const [row] = await db
      .insert(locationShelves)
      .values({
        locationId,
        label,
        lengthCm: lengthCm ?? null,
        widthCm: widthCm ?? null,
        heightCm: heightCm ?? null,
        levels: levels ?? 1
      })
      .returning({ id: locationShelves.id });

    return new Response(JSON.stringify({ ok: true, id: row?.id }), { status: 201 });
  } catch (e: any) {
    return new Response(JSON.stringify({ ok: false, error: e?.message, detail: e?.cause?.message }), { status: 500 });
  }
};
