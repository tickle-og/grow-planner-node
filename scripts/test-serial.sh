# scripts/test-serial.sh
cat > vitest.config.ts <<'TS'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  resolve: {
    alias: {
      $lib: '/src/lib',
    },
  },
  test: {
    // make sure our helpers run
    setupFiles: ['tests/setup.ts'],
    environment: 'node',
    globals: true,

    // ✅ single-thread to avoid SQLite file locks
    pool: 'threads',
    poolOptions: {
      threads: { singleThread: true },
    },
    sequence: { concurrent: false },
  },
});
TS

echo "[✓] vitest.config.ts set to single-thread."
