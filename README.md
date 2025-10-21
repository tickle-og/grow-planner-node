# Grow Planner (SvelteKit + Drizzle)

## Quickstart
pnpm install
cp .env.example .env
# set DATABASE_URL (e.g., file:./dev.db or postgres://...), set a strong JWT_SECRET
pnpm run dev

## DB (Drizzle)
pnpm drizzle:generate   # generate SQL from schema
pnpm drizzle:migrate    # apply to DATABASE_URL

## Scripts
- dev, build, preview, lint, typecheck, test
