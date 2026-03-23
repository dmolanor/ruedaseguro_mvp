-- ============================================================
-- RS-012: Add licencia de conducir support
-- ============================================================
-- Adds driver's license fields to profiles and a new document_type
-- enum value. Run AFTER RS-007 series.
-- ============================================================

-- 1. Add 'licencia_conducir' to document_type enum
ALTER TYPE document_type ADD VALUE IF NOT EXISTS 'licencia_conducir' AFTER 'cedula';

-- 2. Add licencia fields to profiles
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS licencia_number TEXT,
  ADD COLUMN IF NOT EXISTS licencia_categories TEXT[] DEFAULT '{}',   -- e.g. {'1°','2°'}
  ADD COLUMN IF NOT EXISTS licencia_expiry DATE,
  ADD COLUMN IF NOT EXISTS blood_type TEXT;                           -- e.g. 'A+', 'O-'

-- 3. Update carriers.required_documents default to include licencia
ALTER TABLE carriers
  ALTER COLUMN required_documents
  SET DEFAULT '["cedula","licencia_conducir","carnet_circulacion","vehicle_photo"]';
