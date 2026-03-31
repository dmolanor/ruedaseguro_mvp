-- RS-068: Add 'CC' (cédula colombiana) to the id_type enum
-- The UI offers V / E / CC but the enum only had V and E.

ALTER TYPE id_type ADD VALUE IF NOT EXISTS 'CC';
