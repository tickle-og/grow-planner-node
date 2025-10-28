BEGIN;
UPDATE location_shelves
SET name = COALESCE(NULLIF(name, ''), COALESCE(label, 'Shelf ' || id))
WHERE name IS NULL OR name = '';
COMMIT;
