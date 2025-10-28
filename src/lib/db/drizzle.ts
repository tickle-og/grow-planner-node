// src/lib/db/drizzle.ts
import { createClient } from '@libsql/client';
import { drizzle } from 'drizzle-orm/libsql';

const url = process.env.DATABASE_URL ?? 'file:./dev.db';
const client = createClient({ url }); // works with file: URLs too
export const db = drizzle(client);
