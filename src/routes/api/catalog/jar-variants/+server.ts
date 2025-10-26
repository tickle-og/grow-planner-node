import type { RequestHandler } from "./$types";
import { db } from "$lib/db/drizzle";
import { jarVariants } from "$lib/db/schema";

export const GET: RequestHandler = async () => {
  try {
    const rows = await db
      .select()
      .from(jarVariants)
      .orderBy(jarVariants.sizeMl, jarVariants.mouth, jarVariants.label);
    return new Response(JSON.stringify(rows), { headers: { "content-type": "application/json" }});
  } catch (err: any) {
    console.error("GET /api/catalog/jar-variants:", err);
    return new Response(JSON.stringify({ message: "Internal Error", detail: String(err?.message ?? err) }), { status: 500 });
  }
};
