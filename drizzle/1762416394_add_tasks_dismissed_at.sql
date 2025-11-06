-- Persist "dismiss" on tasks
-- idempotent-ish for local dev (SQLite ignores IF EXISTS on ADD COLUMN)
ALTER TABLE tasks ADD COLUMN dismissed_at TEXT;
CREATE INDEX IF NOT EXISTS idx_tasks_dismissed_at ON tasks(dismissed_at);
