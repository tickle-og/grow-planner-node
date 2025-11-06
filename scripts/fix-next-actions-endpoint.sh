# scripts/fix-next-actions-endpoint.sh
set -euo pipefail
FILE="src/routes/api/dashboard/next-actions/+server.ts"
mkdir -p "$(dirname "$FILE")"
cp -n "$FILE" "$FILE.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true

cat > "$FILE" <<'TS'
import type { RequestHandler } from './$types';
import { json, jsonError } from '$lib/utils/json';

export const GET: RequestHandler = async ({ url }) => {
  try {
    const locParam = url.searchParams.get('location_id') ?? url.searchParams.get('locationId');
    const limitParam = url.searchParams.get('limit');

    const locationId = locParam ? Number(locParam) : null;
    const limit = limitParam ? Math.max(1, Math.min(100, Number(limitParam))) : 10;

    // Placeholder until task seeding/wiring lands:
    // Return empty list with consistent shape so UI renders cleanly.
    return json(200, {
      locationId,
      count: 0,
      actions: [],
      hint: 'todo: populate from tasks table'
    });
  } catch (err) {
    console.error('GET /api/dashboard/next-actions failed:', err);
    return jsonError(500);
  }
};
TS

echo "[ok] Patched $FILE"
