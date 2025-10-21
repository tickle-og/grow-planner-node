# Grow Planner (SvelteKit + Drizzle)

## Quickstart
pnpm install
cp .env.example .env
# edit DATABASE_URL / JWT_SECRET as needed
pnpm run dev

## DB (Drizzle)
pnpm drizzle:generate   # emit SQL from schema
pnpm drizzle:migrate    # apply to DATABASE_URL

## Scripts
- dev, build, preview, lint, typecheck, test
