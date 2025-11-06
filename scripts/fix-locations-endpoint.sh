# scripts/fix-locations-endpoint.sh
set -euo pipefail
FILE="src/routes/api/locations/[id]/+server.ts"
mkdir -p "$(dirname "$FILE")"
cp -n "$FILE" "$FILE.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

cat > "$FILE" <<'TS'
import type { RequestHandler } from './$types';
import { db } from '$lib/db/drizzle';
import { locations } from '$lib/db/schema';
import { eq } from 'drizzle-orm';
import { json, jsonError } from '$lib/utils/json';

export const GET: RequestHandler = async ({ params }) => {
  try {
    const id = Number(params.id);
    if (!Number.isFinite(id)) return jsonError(400);

    const rows = await db
      .select()
      .from(locations)
      .where(eq(locations.id, id))
      .limit(1);

    const row = rows[0];
    if (!row) return jsonError(404);

    return json(200, row);
  } catch (err) {
    console.error('GET /api/locations/[id] failed:', err);
    return jsonError(500);
  }
};
TS

echo "[ok] Patched $FILE"
