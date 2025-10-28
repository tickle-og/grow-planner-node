import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { locations } from '$lib/db/schema';
import { eq } from 'drizzle-orm';

export const GET: RequestHandler = async ({ params }) => {
  const id = Number(params.id);
  try {
    const [row] = await db.select().from(locations).where(eq(locations.id, id)).limit(1);
    if (!row) return new Response(JSON.stringify({ ok: false, error: 'not found' }), { status: 404 });
    return new Response(JSON.stringify(row), { status: 200 });
  } catch (e: any) {
    return new Response(JSON.stringify({ message: "Internal Error" }), { status: 500, headers: { "content-type": "application/json; charset=utf-8" } });
  }
};
