// src/routes/api/catalog/container-presets/+server.ts
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { containerPresets } from '$lib/db/schema';

export const GET: RequestHandler = async () => {
  try {
    const rows = await db
      .select({
        key: containerPresets.key,
        containerType: containerPresets.containerType,
        label: containerPresets.label,
        defaultsJson: containerPresets.defaultsJson,
        active: containerPresets.active
      })
      .from(containerPresets);

    return new Response(JSON.stringify(rows), {
      status: 200,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'public, max-age=60'
      }
    });
  } catch (e) {
    // Log server-side for debugging, but don't leak to the client
    console.error('GET /api/catalog/container-presets failed:', e);
    return new Response(JSON.stringify({ message: "Internal Error" }), {
      status: 500,
      headers: { 'content-type': 'application/json; charset=utf-8' }
    });
  }
};
