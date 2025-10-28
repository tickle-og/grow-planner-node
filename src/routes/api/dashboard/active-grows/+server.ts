import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { grows, cultures, recipes } from "$lib/db/schema";
import { and, eq, ne, sql } from "drizzle-orm";
import { getLocationIdOrThrow, getNum } from "../_util";

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event);
    const limit = getNum(event, "limit", 8, 1, 50);

    // consider "active" = not complete/retired/contaminated
    const rows = await db
      .select({
        id: grows.id,
        status: grows.status,
        startDate: grows.startDate,
        movedToFruitingAt: grows.movedToFruitingAt,
        updatedAt: grows.updatedAt,
        containerType: grows.containerType,
        batchCode: grows.batchCode,
        cultureName: cultures.name,
        recipeName: recipes.name,
      })
      .from(grows)
      .leftJoin(cultures, eq(cultures.id, grows.cultureId))
      .leftJoin(recipes, eq(recipes.id, grows.recipeId))
      .where(and(
        eq(grows.locationId, locationId),
        ne(grows.status, "complete"),
        ne(grows.status, "retired"),
        ne(grows.status, "contaminated")
      ))
      .orderBy(sql`COALESCE(${grows.updatedAt}, ${grows.startDate}) DESC`)
      .limit(limit);

    return new Response(JSON.stringify({ locationId, rows }), { headers: { "content-type": "application/json" }});
  } catch (err: any) {
    console.error("GET /api/dashboard/active-grows:", err);
    return new Response(JSON.stringify({ message: "Internal Error" }), { status: 500, headers: { "content-type": "application/json; charset=utf-8" } });
  }
};
