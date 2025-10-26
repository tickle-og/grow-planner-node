import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { grows } from "$lib/db/schema";
import { eq, sql } from "drizzle-orm";
import { getLocationIdOrThrow } from "../_util";

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event);

    const rows = await db
      .select({
        status: grows.status,
        count: sql<number>`COUNT(*)`
      })
      .from(grows)
      .where(eq(grows.locationId, locationId))
      .groupBy(grows.status);

    const total = rows.reduce((s, r) => s + Number(r.count), 0);
    const breakdown = Object.fromEntries(rows.map(r => [r.status ?? "unknown", Number(r.count)]));

    return new Response(JSON.stringify({ locationId, total, breakdown }), {
      headers: { "content-type": "application/json" }
    });
  } catch (err: any) {
    console.error("GET /api/dashboard/status-counts:", err);
    return new Response(JSON.stringify({ message: "Internal Error", detail: String(err?.message ?? err) }), { status: 500 });
  }
};
