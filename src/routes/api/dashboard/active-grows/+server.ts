import type { RequestHandler } from './$types';
import { json, jsonError } from '$lib/utils/json';
import { getLocationIdOrThrow } from '../_util';

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event.url ?? new URL(event.request.url));
    return json(200, { ok: true, locationId, rows: [] });
  } catch (e: any) {
    console.error('active-grows error:', e);
    return jsonError(400, { message: e?.message ?? 'Bad Request' });
  }
};
