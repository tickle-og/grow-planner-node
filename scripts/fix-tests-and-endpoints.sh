# scripts/fix-tests-and-endpoints.sh
set -euo pipefail

echo "[1/5] Update drizzle client to set WAL/busy_timeout…"
cat > src/lib/db/drizzle.ts <<'TS'
import { drizzle } from 'drizzle-orm/libsql';
import { createClient } from '@libsql/client';

// Lightweight env shim
const DATABASE_URL = process.env.DATABASE_URL ?? 'file:./dev.db';
const TURSO_AUTH_TOKEN = process.env.TURSO_AUTH_TOKEN;

const client = createClient({
  url: DATABASE_URL,
  authToken: TURSO_AUTH_TOKEN,
});

export const db = drizzle(client);

// Make local sqlite play nice under parallel access (tests/dev)
(async () => {
  try {
    if (DATABASE_URL.startsWith('file:')) {
      await client.execute('PRAGMA journal_mode=WAL;');
      await client.execute('PRAGMA busy_timeout=3000;');
      await client.execute('PRAGMA synchronous=NORMAL;');
    }
  } catch {
    // best-effort; ignore in environments that don't support PRAGMA
  }
})();
TS

echo "[2/5] Harden status-counts (always return all buckets)…"
cat > src/routes/api/dashboard/status-counts/+server.ts <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { grows } from '$lib/db/schema';
import { eq, sql } from 'drizzle-orm';
import { json } from '$lib/utils/json';

export const GET: RequestHandler = async ({ url }) => {
  try {
    const locationId = Number(url.searchParams.get('location_id') ?? '0');
    if (!locationId) return json({ pending:0, active:0, completed:0, failed:0, total:0 });

    const rows = await db
      .select({
        status: grows.status,
        count: sql<number>`count(*)`.as('count'),
      })
      .from(grows)
      .where(eq(grows.locationId, locationId))
      .groupBy(grows.status);

    const out = { pending: 0, active: 0, completed: 0, failed: 0 } as Record<string, number>;
    for (const r of rows) {
      const key = (r.status ?? '') as keyof typeof out;
      if (key in out) out[key] = Number((r as any).count ?? 0);
    }
    const total = out.pending + out.active + out.completed + out.failed;
    return json({ ...out, total });
  } catch {
    return new Response(JSON.stringify({ message: 'Internal Error' }), {
      status: 500,
      headers: { 'content-type': 'application/json; charset=utf-8' },
    });
  }
};
TS

echo "[3/5] Harden shelves endpoint (label/name + stable JSON)…"
cat > src/routes/api/locations/[id]/shelves/+server.ts <<'TS'
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { locationShelves } from '$lib/db/schema';
import { eq } from 'drizzle-orm';
import { json } from '$lib/utils/json';

export const GET: RequestHandler = async ({ params }) => {
  try {
    const id = Number(params.id);
    const rows = await db
      .select({
        id: locationShelves.id,
        locationId: locationShelves.locationId,
        name: locationShelves.name as any,     // historical column
        label: locationShelves.label as any,   // new column
        lengthCm: locationShelves.lengthCm,
        widthCm: locationShelves.widthCm,
        heightCm: locationShelves.heightCm,
        levels: locationShelves.levels,
        createdAt: locationShelves.createdAt,
      })
      .from(locationShelves)
      .where(eq(locationShelves.locationId, id));

    const shelves = rows.map(r => ({
      id: r.id,
      locationId: r.locationId,
      label: r.label ?? r.name ?? `Shelf #${r.id}`,
      lengthCm: r.lengthCm ?? null,
      widthCm: r.widthCm ?? null,
      heightCm: r.heightCm ?? null,
      levels: r.levels ?? 1,
      createdAt: r.createdAt ?? null,
    }));

    return json({ ok: true, count: shelves.length, shelves });
  } catch {
    return new Response(JSON.stringify({ message: 'Internal Error' }), {
      status: 500,
      headers: { 'content-type': 'application/json; charset=utf-8' },
    });
  }
};

export const POST: RequestHandler = async ({ params, request }) => {
  try {
    const locationId = Number(params.id);
    const body = await request.json().catch(() => ({}));
    const label = (body.label ?? body.name ?? '').toString().trim();
    if (!label) return json({ ok: false, error: 'label required' }, 400);

    const { lengthCm = null, widthCm = null, heightCm = null, levels = 1 } = body;

    const [row] = await db.insert(locationShelves).values({
      locationId,
      // keep both so old/new schemas are happy
      name: label,
      label,
      lengthCm,
      widthCm,
      heightCm,
      levels,
    }).returning({ id: locationShelves.id });

    return json({ ok: true, id: row.id });
  } catch {
    return new Response(JSON.stringify({ message: 'Internal Error' }), {
      status: 500,
      headers: { 'content-type': 'application/json; charset=utf-8' },
    });
  }
};
TS

echo "[4/5] Vitest setup: isolate DB for tests and auto-migrate…"
mkdir -p tests
cat > tests/setup.ts <<'TS'
process.env.DATABASE_URL = process.env.TEST_DATABASE_URL || 'file:./dev.test.db';
process.env.DRIZZLE_DIALECT = 'sqlite';

import { migrate } from 'drizzle-orm/libsql/migrator';
import { db } from '../src/lib/db/drizzle';

// Run migrations once for the test DB
await migrate(db as any, { migrationsFolder: 'drizzle' });
TS

echo "[5/5] Update vitest.config.ts to load setup file…"
cat > vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
    setupFiles: ['tests/setup.ts'],
    coverage: { reporter: ['text'] },
  },
  resolve: {
    alias: {
      $lib: path.resolve(__dirname, 'src/lib'),
    }
  }
});
TS

echo "[DONE] Patched DB client, endpoints, and test setup. Now run:"
echo "  1) Close any running dev server that holds dev.db (Ctrl+C in that terminal)."
echo "  2) pnpm test"
