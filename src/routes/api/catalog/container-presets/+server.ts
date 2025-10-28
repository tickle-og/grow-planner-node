import { json, jsonError } from '$lib/server/http';

import { json, jsonError } from '$lib/server/http';

// src/routes/api/catalog/container-presets/+server.ts
import type { RequestHandler } from '@sveltejs/kit';
import { db } from '$lib/db/drizzle';
import { containerPresets } from '$lib/db/schema';

export const GET: RequestHandler = async () => {
  try {
    const rows = await db
      .select({
        key: containerPresets.key,
        containerType: containerPresets.containerType,
        label: containerPresets.label,
        defaultsJson: containerPresets.defaultsJson,
        active: containerPresets.active
      })
      .from(containerPresets);

    return jsonError(500);
  }
};
