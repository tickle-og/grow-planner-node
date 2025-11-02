# scripts/add-dashboard-tests.sh
set -euo pipefail

mkdir -p tests

# 1) vitest config (idempotent)
if [ ! -f vitest.config.ts ]; then
  cat > vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
    coverage: { reporter: ['text'] }
  },
  resolve: {
    alias: {
      $lib: path.resolve(__dirname, 'src/lib'),
    }
  }
});
TS
fi

# 2) Minimal dashboard smoke tests (status-counts + shelves GET)
cat > tests/dashboard.smoke.test.ts <<'TS'
import { describe, it, expect, beforeAll } from 'vitest';
import { db } from '../src/lib/db/drizzle';
import { locations, locationShelves } from '../src/lib/db/schema';
import { eq } from 'drizzle-orm';

// import handlers directly
import * as StatusHandlers from '../src/routes/api/dashboard/status-counts/+server';
import * as ShelvesHandlers from '../src/routes/api/locations/[id]/shelves/+server';

// tiny RequestEvent mock
function mkEvent(method: string, url: string, body?: any, params?: Record<string, string>) {
  const init: RequestInit = { method, headers: { 'content-type': 'application/json' } };
  if (body !== undefined) init.body = JSON.stringify(body);
  return {
    request: new Request(url, init),
    params: params ?? {},
    url: new URL(url),
  } as any;
}

let locationId = 1;

describe('Dashboard API smoke', () => {
  beforeAll(async () => {
    // ensure a location exists
    const loc = await db.select().from(locations).limit(1);
    if (loc.length) {
      locationId = loc[0].id;
    } else {
      const [row] = await db.insert(locations).values({
        ownerUserId: 1,
        name: 'Demo Lab',
        nickname: 'Demo',
        timezone: 'America/Denver',
        isActive: 1
      }).returning({ id: locations.id });
      locationId = row.id;
    }

    // ensure at least one shelf (label/name differences handled in handler)
    const existing = await db
      .select({ id: locationShelves.id })
      .from(locationShelves)
      .where(eq(locationShelves.locationId, locationId))
      .limit(1);

    if (!existing.length) {
      await db.insert(locationShelves).values({
        locationId,
        name: 'Main Rack A',
        label: 'Main Rack A',
        lengthCm: 120,
        widthCm: 45,
        heightCm: 200,
        levels: 4
      });
    }
  });

  it('GET /api/dashboard/status-counts returns numeric buckets', async () => {
    const url = `http://local/api/dashboard/status-counts?location_id=${locationId}`;
    const res = await StatusHandlers.GET(mkEvent('GET', url));
    expect(res.status).toBe(200);
    const data = await res.json();
    for (const key of ['pending','active','completed','failed','total']) {
      expect(typeof data[key]).toBe('number');
    }
  });

  it('GET /api/locations/:id/shelves returns ok + shelves[]', async () => {
    const res = await ShelvesHandlers.GET(
      mkEvent('GET', `http://local/api/locations/${locationId}/shelves`, undefined, { id: String(locationId) })
    );
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.ok).toBe(true);
    expect(Array.isArray(data.shelves)).toBe(true);
    expect(data.shelves.length).toBeGreaterThan(0);
    // label/name normalization in handler means label should exist
    expect(data.shelves[0].label || data.shelves[0].name).toBeTruthy();
  });
});
TS

# 3) Package.json scripts (idempotent)
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));p.scripts=p.scripts||{};p.scripts.test=p.scripts.test||'vitest run';p.scripts['test:watch']=p.scripts['test:watch']||'vitest';fs.writeFileSync('package.json',JSON.stringify(p,null,2));"

echo "[ok] Added tests/dashboard.smoke.test.ts and ensured vitest.config.ts"
echo "Run: pnpm test"
