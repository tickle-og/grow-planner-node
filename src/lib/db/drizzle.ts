import { drizzle } from 'drizzle-orm/libsql';
import { createClient } from '@libsql/client';

// Lightweight env shim
const DATABASE_URL = process.env.DATABASE_URL ?? 'file:./dev.db';
const TURSO_AUTH_TOKEN = process.env.TURSO_AUTH_TOKEN;

const client = createClient({
	url: DATABASE_URL,
	authToken: TURSO_AUTH_TOKEN
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
