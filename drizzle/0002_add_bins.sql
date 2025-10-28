-- Idempotent creation for local dev
CREATE TABLE IF NOT EXISTS shelf_bins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  location_id INTEGER NOT NULL,
  shelf_id INTEGER,
  label TEXT NOT NULL,
  capacity_cm2 INTEGER,
  created_at TEXT DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
  FOREIGN KEY (shelf_id) REFERENCES location_shelves(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS bin_assignments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  location_id INTEGER NOT NULL,
  bin_id INTEGER NOT NULL,
  grow_id INTEGER,
  group_label TEXT,
  notes TEXT,
  placed_at TEXT DEFAULT (CURRENT_TIMESTAMP),
  removed_at TEXT,
  FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
  FOREIGN KEY (bin_id) REFERENCES shelf_bins(id) ON DELETE CASCADE,
  FOREIGN KEY (grow_id) REFERENCES grows(id) ON DELETE SET NULL
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_shelf_bins_location ON shelf_bins(location_id);
CREATE INDEX IF NOT EXISTS idx_bin_assignments_bin ON bin_assignments(bin_id);
CREATE INDEX IF NOT EXISTS idx_bin_assignments_active ON bin_assignments(bin_id, removed_at);
