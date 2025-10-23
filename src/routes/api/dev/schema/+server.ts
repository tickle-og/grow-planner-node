import type { RequestHandler } from "./$types";
import { client } from "$lib/db/drizzle";

const tables = ["recipes","supplies","species","strains","tasks","grows","yields","recipe_ingredients","grow_events","users","shopping_items","audit_log"];

export const GET: RequestHandler = async () => {
  try {
    const out: Record<string, Array<Record<string, unknown>>> = {};
    for (const t of tables) {
      try {
        const res = await client.execute(`PRAGMA table_info('${t}')`);
        out[t] = res.rows as any;
      } catch (e) {
        out[t] = [{ error: String(e) }];
      }
    }
    return new Response(JSON.stringify(out, null, 2), { headers: { "content-type": "application/json" } });
  } catch (err) {
    console.error("[schema] error", err);
    return new Response(JSON.stringify({ ok: false, error: String(err) }), { status: 500 });
  }
};
