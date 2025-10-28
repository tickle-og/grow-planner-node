import 'dotenv/config';
import Database from 'better-sqlite3';

const url = process.env.DATABASE_URL ?? 'file:./dev.db';
const path = url.replace(/^file:/, '');
const db = new Database(path);
const rows = db.prepare("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").all();
console.log(rows.map(r => r.name));
