-- Migration 0001: additive column changes only (no explicit transactions)

-- cultures: add new descriptive fields
ALTER TABLE cultures ADD COLUMN variety TEXT;
ALTER TABLE cultures ADD COLUMN vendor TEXT;
ALTER TABLE cultures ADD COLUMN lot_code TEXT;
ALTER TABLE cultures ADD COLUMN origin TEXT;
ALTER TABLE cultures ADD COLUMN is_public INTEGER;
ALTER TABLE cultures ADD COLUMN acquired_at TEXT;

-- location_shelves: label + created_at
ALTER TABLE location_shelves ADD COLUMN label TEXT;
ALTER TABLE location_shelves ADD COLUMN created_at TEXT DEFAULT (CURRENT_TIMESTAMP);

-- recipes: more text fields
ALTER TABLE recipes ADD COLUMN description TEXT;
ALTER TABLE recipes ADD COLUMN notes TEXT;

-- supplies: unit cost
ALTER TABLE supplies ADD COLUMN unit_cost REAL;

-- yield_data: extra measurements/flags
ALTER TABLE yield_data ADD COLUMN cap_size_avg_mm REAL;
ALTER TABLE yield_data ADD COLUMN stipe_length_avg_mm REAL;
ALTER TABLE yield_data ADD COLUMN quality_grade TEXT;
ALTER TABLE yield_data ADD COLUMN contamination_flag INTEGER;
