import { json, jsonError } from '$lib/server/http';

import { json, jsonError } from '$lib/server/http';

import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { jarVariants } from "$lib/db/schema";

export const GET: RequestHandler = async () => {
  try {
    const rows = await db
      .select()
      .from(jarVariants)
      .orderBy(jarVariants.sizeMl, jarVariants.mouth, jarVariants.label);
    return json(rows, 200, 'public, max-age=60');
  } catch (err: any) {
    console.error("GET /api/catalog/jar-variants:", err);
    return jsonError(500);
  }
};
