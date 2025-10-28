import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { containerPresets } from "$lib/db/schema";
import { eq } from "drizzle-orm";

export const GET: RequestHandler = async () => {
  try {
    const rows = await db
      .select()
      .from(containerPresets)
      .where(eq(containerPresets.active, true))
      .orderBy(containerPresets.containerType, containerPresets.label);
    return new Response(JSON.stringify(rows), { headers: { "content-type": "application/json" }});
  } catch (err: any) {
    console.error("GET /api/catalog/container-presets:", err);
    return new Response(JSON.stringify({ message: "Internal Error", detail: String(err?.message ?? err) }), { status: 500 });
  }
};
