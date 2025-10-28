// src/routes/api/dashboard/status-counts/+server.ts
import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { grows } from "$lib/db/schema";
import { eq, sql } from "drizzle-orm";
import { getLocationIdOrThrow } from "../_util";

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event);
    const rows = await db
      .select({ status: grows.status, count: sql<number>`COUNT(*)` })
      .from(grows)
      .where(eq(grows.locationId, locationId))
      .groupBy(grows.status);

    const breakdown: Record<string, number> = {};
    for (const r of rows) breakdown[r.status ?? "unknown"] = Number(r.count);
    const total = Object.values(breakdown).reduce((a, b) => a + b, 0);

    const groups = {
      pending: (breakdown.planning ?? breakdown.pending ?? 0),
      active: (breakdown.incubating ?? 0) + (breakdown.fruiting ?? 0) + (breakdown.active ?? 0),
      completed: (breakdown.complete ?? breakdown.completed ?? 0),
      failed: (breakdown.contaminated ?? 0) + (breakdown.retired ?? 0) + (breakdown.failed ?? 0),
    };

    return new Response(JSON.stringify({ locationId, total, breakdown, groups }), {
      headers: { "content-type": "application/json" }
    });
  } catch (err: any) {
    console.error("GET /api/dashboard/status-counts:", err);
    return new Response(JSON.stringify({ message: "Internal Error" }), { status: 500, headers: { "content-type": "application/json; charset=utf-8" } });
  }
};
