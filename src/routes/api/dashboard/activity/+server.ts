import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { grows, yieldData } from "$lib/db/schema";
import { and, eq, sql, gte } from "drizzle-orm";
import { getLocationIdOrThrow, getNum, yyyymmdd } from "../_util";

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event);
    const days = getNum(event, "days", 14, 1, 365);
    const limit = getNum(event, "limit", 30, 1, 200);
    const startISO = yyyymmdd(new Date(Date.now() - days * 86400000));

    // fetch grows once, then emit pseudo-events based on notable timestamps
    const gs = await db
      .select({
        id: grows.id,
        batchCode: grows.batchCode,
        startDate: grows.startDate,
        inoculationDate: grows.inoculationDate,
        incubationStartAt: grows.incubationStartAt,
        colonizationCompleteAt: grows.colonizationCompleteAt,
        movedToFruitingAt: grows.movedToFruitingAt,
        updatedAt: grows.updatedAt
      })
      .from(grows)
      .where(eq(grows.locationId, locationId));

    type Item = { ts: string, type: string, growId?: number, label?: string };
    const items: Item[] = [];

    const pushIf = (ts: string | null | undefined, type: string, growId: number, label?: string) => {
      if (!ts) return;
      if (ts.slice(0,10) >= startISO) items.push({ ts, type, growId, label });
    };

    for (const g of gs) {
      pushIf(g.startDate, "grow_started", g.id, g.batchCode ?? undefined);
      pushIf(g.inoculationDate, "inoculated", g.id, g.batchCode ?? undefined);
      pushIf(g.incubationStartAt, "incubation_started", g.id, g.batchCode ?? undefined);
      pushIf(g.colonizationCompleteAt, "colonization_done", g.id, g.batchCode ?? undefined);
      pushIf(g.movedToFruitingAt, "moved_to_fruiting", g.id, g.batchCode ?? undefined);
      pushIf(g.updatedAt, "updated", g.id, g.batchCode ?? undefined);
    }

    // yields as events
    const ys = await db
      .select({
        id: yieldData.id,
        growId: yieldData.growId,
        flushNumber: yieldData.flushNumber,
        harvestDate: yieldData.harvestDate,
        wetWeightG: yieldData.wetWeightG
      })
      .from(yieldData)
      .where(and(eq(yieldData.locationId, locationId), gte(sql`DATE(${yieldData.harvestDate})`, startISO)));

    for (const y of ys) {
      if (y.harvestDate) items.push({ ts: y.harvestDate, type: "harvest", growId: y.growId, label: `flush ${y.flushNumber}` });
    }

    items.sort((a, b) => b.ts.localeCompare(a.ts));
    const trimmed = items.slice(0, limit);

    return new Response(JSON.stringify({ locationId, days, count: trimmed.length, items: trimmed }), {
      headers: { "content-type": "application/json" }
    });
  } catch (err: any) {
    console.error("GET /api/dashboard/activity:", err);
    return new Response(JSON.stringify({ message: "Internal Error" }), { status: 500, headers: { "content-type": "application/json; charset=utf-8" } });
  }
};
