import { createClient } from "@libsql/client/node";
import { drizzle } from "drizzle-orm/libsql";
import { env } from "$lib/env";
import * as schema from "$lib/db/schema";

export const client = createClient({ url: env.DATABASE_URL });
export const db = drizzle(client, { schema });

// Re-export for convenience where legacy code expects it
export { schema };
