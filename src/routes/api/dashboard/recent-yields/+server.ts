import { json, jsonError } from '$lib/server/http';

import { json, jsonError } from '$lib/server/http';

import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { yieldData, grows } from "$lib/db/schema";
import { and, eq, sql, gte } from "drizzle-orm";
import { getLocationIdOrThrow, getNum, yyyymmdd } from "../_util";

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event);
    const days = getNum(event, "days", 30, 1, 365);
    const start = new Date(Date.now() - days * 86400000);
    const startISO = yyyymmdd(start);

    const rows = await db
      .select({
        id: yieldData.id,
        growId: yieldData.growId,
        flushNumber: yieldData.flushNumber,
        harvestDate: yieldData.harvestDate,
        wetWeightG: yieldData.wetWeightG,
        dryWeightG: yieldData.dryWeightG
      })
      .from(yieldData)
      .innerJoin(grows, eq(grows.id, yieldData.growId))
      .where(and(
        eq(yieldData.locationId, locationId),
        gte(sql`DATE(${yieldData.harvestDate})`, startISO)
      ))
      .orderBy(sql`DATE(${yieldData.harvestDate}) DESC`);

    const totals = rows.reduce((acc, r) => {
      acc.wetWeightG += r.wetWeightG ?? 0;
      acc.dryWeightG += r.dryWeightG ?? 0;
      return acc;
    }, { wetWeightG: 0, dryWeightG: 0 });

    return json({ locationId, days, totals, rows }, 200);
  } catch (err: any) {
    console.error("GET /api/dashboard/recent-yields:", err);
    return jsonError(500);
  }
};
