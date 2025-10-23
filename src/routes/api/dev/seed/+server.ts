import type { RequestHandler } from "./$types";
import { client } from "$lib/db/drizzle";

async function tableHasRow(table: string, whereCol: string, value: unknown) {
  const q = `select 1 from ${table} where ${whereCol} = ? limit 1`;
  const r = await client.execute({ sql: q, args: [value] });
  return r.rows.length > 0;
}

type ColumnInfo = {
  name: string;
  type?: string;
  notnull?: number;
  dflt_value?: string | null;
  pk?: number;
};

async function buildSuppliesInsertRow(base: Record<string, unknown>) {
  const infoRes = await client.execute(`PRAGMA table_info('supplies')`);
  const cols = infoRes.rows as unknown as ColumnInfo[];

  const row: Record<string, unknown> = {};
  const present = new Set(cols.map(c => c.name));

  if (base.name) row["name"] = base.name;

  const commonDefaults: Record<string, unknown> = {
    unit: "unit",
    on_hand_qty: 0,
    onHandQty: 0,
    cost_per_unit: 0,
    costPerUnit: 0,
    category: "General",
    vendor: "",
    sku: "",
    min_qty: 0,
    minQty: 0,
    notes: "",
  };

  for (const [k, v] of Object.entries(base)) {
    if (present.has(k)) row[k] = v;
  }

  for (const c of cols) {
    if (c.notnull === 1 && c.dflt_value == null && c.pk !== 1) {
      if (row[c.name] == null) {
        if (c.name in commonDefaults) row[c.name] = commonDefaults[c.name];
        else if ((c.type || "").toUpperCase().includes("INT")) row[c.name] = 0;
        else if ((c.type || "").toUpperCase().includes("REAL")) row[c.name] = 0;
        else row[c.name] = "";
      }
    }
  }

  const columns = Object.keys(row);
  const placeholders = columns.map(() => "?").join(",");
  const args = columns.map(k => row[k]);

  return { sql: `insert into supplies (${columns.join(",")}) values (${placeholders})`, args };
}

async function seedRecipes() {
  const items = [
    {
      name: "PF Tek (Grain → Cake)",
      type: "tek",
      version: 1,
      is_default: 1,
      instructions: `1) Prepare BRF jars. 2) Sterilize. 3) Inoculate. 4) Colonize. 5) Dunk & roll. 6) Fruit.`
    },
    {
      name: "Monotub Bulk (CVG)",
      type: "tek",
      version: 1,
      is_default: 0,
      instructions: `1) Spawn to CVG. 2) Level. 3) FAE. 4) Watch for pins. 5) Harvest at veil break.`
    }
  ];

  for (const r of items) {
    if (!(await tableHasRow("recipes", "name", r.name))) {
      await client.execute({
        sql: `insert into recipes (name, type, instructions, version, is_default) values (?, ?, ?, ?, ?)`,
        args: [r.name, r.type, r.instructions, r.version, r.is_default]
      });
    }
  }
}

async function seedSupplies() {
  const items: Array<Record<string, unknown>> = [
    { name: "Popcorn Grain", unit: "lb", on_hand_qty: 0, cost_per_unit: 2.5, category: "Grain", notes: "Food-grade kernels" },
    { name: "CVG Substrate", unit: "bag", on_hand_qty: 0, cost_per_unit: 8.0, category: "Substrate", notes: "Coco/verm/gypsum" },
    { name: "Unicorn 3T Bags", unit: "bag", on_hand_qty: 0, cost_per_unit: 1.2, category: "Consumables", notes: "0.2µ filter patch" },
    { name: "Isopropyl Alcohol 70%", unit: "bottle", on_hand_qty: 1, cost_per_unit: 3.0, category: "Sanitation", notes: "Surface sterilization" }
  ];

  for (const s of items) {
    if (!(await tableHasRow("supplies", "name", s.name as string))) {
      const { sql, args } = await buildSuppliesInsertRow(s);
      await client.execute({ sql, args });
    }
  }
}

export const GET: RequestHandler = async () => {
  try {
    await client.execute("select 1");
    await seedRecipes();
    await seedSupplies();
    return new Response(JSON.stringify({ ok: true }), { headers: { "content-type": "application/json" } });
  } catch (err) {
    console.error("[seed] failed:", err);
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
      headers: { "content-type": "application/json" }
    });
  }
};
