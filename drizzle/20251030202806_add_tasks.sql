-- drizzle migration: add tasks table
CREATE TABLE IF NOT EXISTS "tasks" (
  "id"           INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  "location_id"  INTEGER NOT NULL,
  "grow_id"      INTEGER,
  "title"        TEXT NOT NULL,
  "status"       TEXT NOT NULL DEFAULT 'pending', -- pending | active | completed | failed
  "due_at"       TEXT,                            -- ISO datetime (local or UTC string)
  "notes"        TEXT,
  "created_at"   TEXT DEFAULT (CURRENT_TIMESTAMP),
  "updated_at"   TEXT,
  FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON UPDATE NO ACTION ON DELETE CASCADE,
  FOREIGN KEY ("grow_id") REFERENCES "grows"("id") ON UPDATE NO ACTION ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS "idx_tasks_location" ON "tasks" ("location_id");
CREATE INDEX IF NOT EXISTS "idx_tasks_due_at"   ON "tasks" ("due_at");
CREATE INDEX IF NOT EXISTS "idx_tasks_status"   ON "tasks" ("status");
