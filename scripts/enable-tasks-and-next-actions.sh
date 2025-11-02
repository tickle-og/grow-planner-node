# scripts/enable-tasks-and-next-actions.sh
# -----------------------------
# Adds:
#  - Drizzle SQL migration for `tasks`
#  - Schema append for `tasks` in src/lib/db/schema.ts (only if missing)
#  - /api/dashboard/next-actions endpoint (GET)
#  - /api/dev/seed/tasks endpoint (POST) for quick demo data
# Then prints next steps.

set -euo pipefail

root="${PWD}"

# 0) sanity
test -f "package.json" || { echo "[x] Run from project root"; exit 1; }

# 1) Make folders
mkdir -p drizzle
mkdir -p src/routes/api/dashboard/next-actions
mkdir -p src/routes/api/dev/seed/tasks
mkdir -p src/lib/utils

# 2) Add a SQL migration for tasks
ts="$(date +%Y%m%d%H%M%S)"
mig="drizzle/${ts}_add_tasks.sql"
if [ -f "$mig" ]; then
  # rare collision; add a suffix
  mig="drizzle/${ts}_add_tasks_01.sql"
fi

cat > "$mig" <<'SQL'
-- drizzle migration: add tasks table
CREATE TABLE IF NOT EXISTS "tasks" (
  "id"           INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "location_id"  INTEGER NOT NULL,
  "grow_id"      INTEGER,
  "title"        TEXT NOT NULL,
  "status"       TEXT NOT NULL DEFAULT 'pending', -- pending | active | completed | failed
  "due_at"       TEXT,                            -- ISO datetime (local or UTC string)
  "notes"        TEXT,
  "created_at"   TEXT DEFAULT (CURRENT_TIMESTAMP),
  "updated_at"   TEXT,
  FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY ("grow_id") REFERENCES "grows"("id") ON UPDATE NO ACTION ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "idx_tasks_location" ON "tasks" ("location_id");
CREATE INDEX IF NOT EXISTS "idx_tasks_due_at"   ON "tasks" ("due_at");
CREATE INDEX IF NOT EXISTS "idx_tasks_status"   ON "tasks" ("status");
SQL
echo "[add] $mig"

# 3) Append `tasks` model to schema.ts if missing
schema="src/lib/db/schema.ts"
if ! rg -n "export const tasks" "$schema" >/dev/null 2>&1; then
  # ensure the file exists
  test -f "$schema" || { echo "[x] Missing $schema"; exit 1; }

  cp -n "$schema" "${schema}.bak.$(date +%Y%m%d-%H%M%S)" || true

  # We assume `sql` is already imported in this file (it is elsewhere in your project).
  cat >> "$schema" <<'TS'

/** Tasks: time-based actions for dashboard/calendar */
export const tasks = sqliteTable("tasks", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  locationId: integer("location_id").notNull().references(() => locations.id, { onDelete: "cascade" }),
  growId: integer("grow_id").references(() => grows.id, { onDelete: "set null" }),
  title: text("title").notNull(),
  status: text("status").$type<'pending' | 'active' | 'completed' | 'failed'>().notNull().default('pending'),
  dueAt: text("due_at"),
  notes: text("notes"),
  createdAt: text("created_at").default(sql`CURRENT_TIMESTAMP`),
  updatedAt: text("updated_at"),
});
TS
  echo "[patch] appended tasks model to $schema"
else
  echo "[ok] tasks model already present in $schema"
fi

# 4) Helpers (json/jsonError) – assume present; create if missing (no-op if exists)
json_helper="src/lib/utils/json.ts"
if [ ! -f "$json_helper" ]; then
cat > "$json_helper" <<'TS'
export function json(data: unknown, init: ResponseInit = {}) {
  return new Response(JSON.stringify(data), {
    headers: { "content-type": "application/json; charset=utf-8", ...(init.headers || {}) },
    ...init,
  });
}
export function jsonError(status = 500, message = "Internal Error") {
  return json({ message }, { status });
}
TS
  echo "[add] $json_helper"
else
  echo "[ok] $json_helper exists"
fi

# 5) Next-actions endpoint (GET)
cat > src/routes/api/dashboard/next-actions/+server.ts <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { tasks } from '$lib/db/schema';
import { and, gte, lte, eq, inArray, isNotNull } from 'drizzle-orm';
import { json, jsonError } from '$lib/utils/json';

function iso(d: Date) {
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 19);
}
function startOfDay(d = new Date()) {
  const x = new Date(d);
  x.setHours(0,0,0,0);
  return x;
}
function addDays(d: Date, n: number) {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
}

export const GET: RequestHandler = async ({ url }) => {
  try {
    // Window control
    const scope = (url.searchParams.get('scope') || 'week').toLowerCase(); // week | 14 | all
    const locationId = Number(url.searchParams.get('location_id') || '1');

    const now0 = startOfDay(new Date());
    let end = addDays(now0, 7);
    if (scope === '14') end = addDays(now0, 14);
    if (scope === 'all') end = addDays(now0, 90); // practical cap for UI

    // pending + active with a due date in window
    const rows = await db.select().from(tasks).where(
      and(
        eq(tasks.locationId, locationId),
        inArray(tasks.status, ['pending','active']),
        isNotNull(tasks.dueAt),
        gte(tasks.dueAt, iso(now0)),
        lte(tasks.dueAt, iso(end))
      )
    ).orderBy(tasks.dueAt);

    // Also pull unscheduled tasks (no due_at), limited to 20 for sidebar lists
    const unscheduled = await db.select().from(tasks).where(
      and(
        eq(tasks.locationId, locationId),
        inArray(tasks.status, ['pending','active']),
        tasks.dueAt.isNull?.() ?? (tasks.dueAt as any).isNull() // compat across drizzle versions
      )
    ).limit(20);

    // Calendar grouping by YYYY-MM-DD
    const calendar: Record<string, typeof rows> = {};
    for (const t of rows) {
      const day = String(t.dueAt).slice(0, 10); // YYYY-MM-DD
      (calendar[day] ||= []).push(t);
    }

    return json({
      ok: true,
      locationId,
      scope,
      range: { start: iso(now0), end: iso(end) },
      list: rows,            // already sorted ASC by due_at
      calendar,              // for grid rendering
      unscheduled            // optional panel
    });
  } catch {
    return jsonError(500);
  }
};
TS
echo "[add] src/routes/api/dashboard/next-actions/+server.ts"

# 6) Dev seed endpoint for tasks
cat > src/routes/api/dev/seed/tasks/+server.ts <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { tasks } from '$lib/db/schema';
import { json, jsonError } from '$lib/utils/json';

function isoLocal(d: Date) {
  return new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0,19);
}
function at(h: number, m=0) { const d = new Date(); d.setHours(h,m,0,0); return d; }
function addDays(d: Date, n: number) { const x = new Date(d); x.setDate(x.getDate()+n); return x; }

export const POST: RequestHandler = async ({ request }) => {
  try {
    const body = await request.json().catch(() => ({}));
    const locationId = Number(body.locationId ?? 1);

    const now = new Date();
    const sample = [
      { title: 'Check monotub FAE filters', status: 'active',   dueAt: isoLocal(at(17)),         notes: 'Quick visual check' },
      { title: 'Inoculate grain jars',      status: 'pending',  dueAt: isoLocal(addDays(at(10),1)), notes: 'Use LC A1' },
      { title: 'Harvest shoebox A',         status: 'active',   dueAt: isoLocal(addDays(at(12),2)), notes: 'Weigh wet yield' },
      { title: 'Tidy SAB workspace',        status: 'pending',  dueAt: isoLocal(addDays(at(19),-1)), notes: 'Overdue cleanup' }
    ] as const;

    await db.insert(tasks).values(sample.map(s => ({
      locationId,
      title: s.title,
      status: s.status as any,
      dueAt: s.dueAt,
      notes: s.notes
    })));

    return json({ ok: true, inserted: sample.length, locationId });
  } catch {
    return jsonError(500);
  }
};
TS
echo "[add] src/routes/api/dev/seed/tasks/+server.ts"

echo
echo "Next steps:"
echo "  1) Apply migration:    pnpm drizzle-kit migrate"
echo "  2) Seed tasks:         curl -s -X POST http://localhost:5173/api/dev/seed/tasks -H 'content-type: application/json' -d '{\"locationId\":1}' | jq ."
echo "  3) Try the API:        curl -s 'http://localhost:5173/api/dashboard/next-actions?location_id=1&scope=week' | jq ."
echo "  4) Dev server:         pnpm dev"
echo
echo "If Today still says 'no actions', bump scope to 14 days:"
echo "  curl -s 'http://localhost:5173/api/dashboard/next-actions?location_id=1&scope=14' | jq ."
