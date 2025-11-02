// tests/setup.ts
import { migrate } from 'drizzle-orm/libsql/migrator';
import { db } from '../src/lib/db/drizzle';

async function migrateWithRetry(tries = 5, delayMs = 150) {
  for (let i = 0; i < tries; i++) {
    try {
      await migrate(db as any, { migrationsFolder: 'drizzle' });
      return;
    } catch (e: any) {
      const msg = String(e?.code || e?.message || e);
      if (msg.includes('BUSY')) {
        await new Promise(r => setTimeout(r, delayMs));
        continue;
      }
      throw e;
    }
  }
}
await migrateWithRetry();
