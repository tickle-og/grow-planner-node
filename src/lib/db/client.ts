import Database from "better-sqlite3";
import { drizzle } from "drizzle-orm/better-sqlite3";
import { env } from "../env";

if (!env.DATABASE_URL.startsWith("file:")) {
  throw new Error("SQLite dev client only: set DATABASE_URL like file:./dev.db (use a Postgres client in prod)");
}

const sqlitePath = env.DATABASE_URL.replace("file:", "");
export const sqlite = new Database(sqlitePath);
export const db = drizzle(sqlite);
