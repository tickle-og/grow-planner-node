# scripts/add-json-helper.sh
#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] Create src/lib/utils/json.ts helper…"
mkdir -p src/lib/utils
cat > src/lib/utils/json.ts <<'TS'
// Tiny JSON response helpers used by API routes.

type HeadersInit = Record<string, string>;

export function json(
  data: unknown,
  status = 200,
  extraHeaders: HeadersInit = {}
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...extraHeaders,
    },
  });
}

export function jsonError(
  status = 500,
  message = 'Internal Error',
  extraHeaders: HeadersInit = {}
): Response {
  return json({ message }, status, extraHeaders);
}

export function jsonCache(
  data: unknown,
  seconds = 300,
  status = 200
): Response {
  return json(data, status, {
    'cache-control': `public, max-age=${seconds}`,
  });
}
TS

echo "[2/3] Ensure Vitest alias for \$lib…"
if ! [ -f vitest.config.ts ] || ! grep -qs "\$lib" vitest.config.ts; then
  cat > vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config';
import path from 'node:path';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
    setupFiles: ['tests/setup.ts'],
    coverage: { reporter: ['text'] },
  },
  resolve: {
    alias: {
      $lib: path.resolve(__dirname, 'src/lib'),
    },
  },
});
TS
  echo "[info] wrote vitest.config.ts with \$lib alias"
else
  echo "[ok] vitest.config.ts already defines \$lib (or custom config)"
fi

echo "[3/3] Ensure tests/setup.ts exists…"
mkdir -p tests
[ -f tests/setup.ts ] || : > tests/setup.ts

echo "Done. Run: pnpm test"
