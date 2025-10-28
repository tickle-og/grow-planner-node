import { json, jsonError } from '$lib/server/http';

import { json, jsonError } from '$lib/server/http';

import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { supplies } from "$lib/db/schema";
import { and, eq, sql } from "drizzle-orm";
import { getLocationIdOrThrow, getNum } from "../_util";

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event);
    const limit = getNum(event, "limit", 10, 1, 50);

    const rows = await db
      .select({
        id: supplies.id,
        name: supplies.name,
        sku: supplies.sku,
        category: supplies.category,
        inStockQty: supplies.inStockQty,
        reorderPoint: supplies.reorderPoint,
        preferredSupplier: supplies.preferredSupplier
      })
      .from(supplies)
      .where(and(
        eq(supplies.locationId, locationId),
        eq(supplies.isActive, true),
        sql`COALESCE(${supplies.inStockQty}, 0) <= COALESCE(${supplies.reorderPoint}, 0)`
      ))
      .orderBy(sql`(COALESCE(${supplies.inStockQty}, 0) - COALESCE(${supplies.reorderPoint}, 0)) ASC`)
      .limit(limit);

    return json({ locationId, rows }, 200);
  } catch (err: any) {
    console.error("GET /api/dashboard/low-stock:", err);
    return jsonError(500);
  }
};
