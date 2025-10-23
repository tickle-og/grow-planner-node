import { z } from "zod";

// Always available in SSR/Node. In Vite/SvelteKit dev this is fine.
const raw = (typeof process !== "undefined" ? process.env : {}) as Record<string, string | undefined>;

const EnvSchema = z.object({
  DATABASE_URL: z.string().default("file:./.data/grow-planner.db"),
  JWT_SECRET: z.string().min(1).default("dev-secret-"+Math.random().toString(36).slice(2)),
});

export const env = EnvSchema.parse(raw);
