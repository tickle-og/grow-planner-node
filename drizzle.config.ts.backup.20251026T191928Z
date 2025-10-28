// drizzle.config.ts
import { defineConfig } from 'drizzle-kit';
import { config as loadEnv } from 'dotenv';

loadEnv({ path: '.env' }); // populate process.env for the CLI

const url = process.env.DATABASE_URL || 'file:./.data/grow-planner.db';

export default defineConfig({
  schema: './src/lib/db/schema.ts',
  out: './drizzle',
  dialect: 'sqlite',
  dbCredentials: { url },
  strict: true,
  verbose: true,
});
