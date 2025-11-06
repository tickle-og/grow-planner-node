import type { RequestHandler } from './$types';
import { json, jsonError } from '$lib/utils/json';

export const GET: RequestHandler = async ({ params }) => {
  try {
    const id = Number(params.id);
    if (!Number.isFinite(id) || id <= 0) return jsonError(400, { message: 'invalid id' });
    // Minimal stub; expand as needed.
    return json(200, { ok: true, id });
  } catch (e: any) {
    console.error('locations/[id] error:', e);
    return jsonError(500);
  }
};
