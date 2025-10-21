// src/lib/db/drizzle.ts
import { createClient } from '@libsql/client';
import { drizzle } from 'drizzle-orm/libsql';
import * as schema from './schema.js';

// IMPORTANT: Use the same URL here and in drizzle.config.ts
const client = createClient({ url: 'file:./.data/grow-planner.db' });

export const db = drizzle(client, { schema });
export { schema };
