import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { grows } from "$lib/db/schema";
import { and, eq, ne, sql } from "drizzle-orm";
import { getLocationIdOrThrow, getNum } from "../_util";

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event);
    const limit = getNum(event, "limit", 20, 1, 100);

    const gs = await db
      .select({
        id: grows.id,
        status: grows.status,
        startDate: grows.startDate,
        inoculationDate: grows.inoculationDate,
        incubationStartAt: grows.incubationStartAt,
        colonizationCompleteAt: grows.colonizationCompleteAt,
        movedToFruitingAt: grows.movedToFruitingAt,
        containerType: grows.containerType,
        batchCode: grows.batchCode
      })
      .from(grows)
      .where(and(
        eq(grows.locationId, locationId),
        ne(grows.status, "complete"),
        ne(grows.status, "retired"),
        ne(grows.status, "contaminated")
      ));

    const actions: Array<{ growId: number; action: string; reason: string }> = [];
    for (const g of gs) {
      if (!g.startDate) actions.push({ growId: g.id, action: "Set start date", reason: "planning with no startDate" });
      if (g.status === "planning" && g.startDate && !g.inoculationDate) {
        actions.push({ growId: g.id, action: "Inoculate", reason: "started but no inoculation_date" });
      }
      if (g.inoculationDate && !g.incubationStartAt) {
        actions.push({ growId: g.id, action: "Start incubation", reason: "inoculated but no incubation_start_at" });
      }
      if (g.incubationStartAt && !g.colonizationCompleteAt) {
        actions.push({ growId: g.id, action: "Check colonization", reason: "incubating and not marked complete" });
      }
      if (g.colonizationCompleteAt && !g.movedToFruitingAt) {
        actions.push({ growId: g.id, action: "Move to fruiting", reason: "colonized but not in fruiting" });
      }
    }

    return new Response(JSON.stringify({ locationId, count: actions.length, actions: actions.slice(0, limit) }), {
      headers: { "content-type": "application/json" }
    });
  } catch (err: any) {
    console.error("GET /api/dashboard/next-actions:", err);
    return new Response(JSON.stringify({ message: "Internal Error", detail: String(err?.message ?? err) }), { status: 500 });
  }
};
