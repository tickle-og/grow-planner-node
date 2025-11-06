import type { RequestHandler } from './$types';
import { json, jsonError } from '$lib/utils/json';
import { db } from '$lib/db/drizzle';
import { sql } from 'drizzle-orm';

export const POST: RequestHandler = async () => {
  try {
    // Minimal tasks table if it doesn't exist
    await db.execute(sql`
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        location_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        due_at TEXT NULL,
        status TEXT NOT NULL DEFAULT 'pending'
      );
    `);

    const now = new Date();
    const addDays = (d: number) => {
      const x = new Date(now);
      x.setDate(x.getDate() + d);
      return x.toISOString();
    };

    const demo = [
      { title: 'Sterilize jars', due_at: addDays(0), status: 'pending' },
      { title: 'Shake grain', due_at: addDays(2), status: 'pending' },
      { title: 'Spawn to bulk', due_at: addDays(5), status: 'pending' },
      { title: 'Mist + fan', due_at: addDays(7), status: 'pending' },
    ];

    for (const t of demo) {
      await db.execute(sql`
        INSERT INTO tasks (location_id, title, due_at, status)
        VALUES (1, ${t.title}, ${t.due_at}, ${t.status});
      `);
    }

    return json(200, { ok: true, created: demo.length });
  } catch (e) {
    console.error('demo-tasks seed error:', e);
    return jsonError(500);
  }
};
