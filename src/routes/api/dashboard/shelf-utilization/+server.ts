import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { locationShelves, grows } from "$lib/db/schema";
import { and, eq, ne } from "drizzle-orm";
import { getLocationIdOrThrow } from "../_util";

export const GET: RequestHandler = async (event) => {
  try {
    const locationId = getLocationIdOrThrow(event);

    const shelves = await db.select().from(locationShelves).where(eq(locationShelves.locationId, locationId));
    const capacityCm2 = shelves.reduce((sum, s) => sum + (s.lengthCm ?? 0) * (s.widthCm ?? 0) * (s.levels ?? 1), 0);

    const gs = await db
      .select({ id: grows.id, containerConfigJson: grows.containerConfigJson, containerType: grows.containerType })
      .from(grows)
      .where(and(eq(grows.locationId, locationId), ne(grows.status, "complete")));

    // naive: if container_config has length_cm/width_cm, use it; else assume 1000 cm^2 footprint
    let usedCm2 = 0;
    let counted = 0;
    for (const g of gs) {
      let footprint = 1000; // fallback
      try {
        if (g.containerConfigJson) {
          const cfg = JSON.parse(g.containerConfigJson as unknown as string);
          if (typeof cfg?.length_cm === "number" && typeof cfg?.width_cm === "number") {
            footprint = Math.max(0, cfg.length_cm) * Math.max(0, cfg.width_cm);
          }
        }
      } catch { /* ignore JSON parse */ }
      usedCm2 += footprint;
      counted++;
    }

    const pct = capacityCm2 > 0 ? Math.min(100, Math.round((usedCm2 / capacityCm2) * 100)) : 0;

    return new Response(JSON.stringify({
      locationId,
      capacityCm2,
      usedCm2,
      percent: pct,
      itemsCounted: counted,
      shelvesCount: shelves.length
    }), { headers: { "content-type": "application/json" }});
  } catch (err: any) {
    console.error("GET /api/dashboard/shelf-utilization:", err);
    return new Response(JSON.stringify({ message: "Internal Error", detail: String(err?.message ?? err) }), { status: 500 });
  }
};
