-- RS-079: Add Certificado de Circulación fields to vehicles table
-- Sprint 4A — Run in Supabase SQL editor

-- New fields from the INTT Certificado de Circulación
ALTER TABLE vehicles
  ADD COLUMN IF NOT EXISTS vehicle_type        TEXT,          -- 'MOTO PARTICULAR', 'MOTO CARGA'
  ADD COLUMN IF NOT EXISTS vehicle_body_type   TEXT,          -- 'DEPORTIVA', 'SCOOTER', 'PASEO', etc.
  ADD COLUMN IF NOT EXISTS serial_niv          TEXT,          -- Serial NIV (VIN-equivalent in Venezuela)
  ADD COLUMN IF NOT EXISTS seats               SMALLINT,      -- Número de puestos (usually 2 for motorcycles)
  ADD COLUMN IF NOT EXISTS certificado_issued_date DATE;      -- Fecha de expedición del certificado

-- color is now optional / not extracted — column stays but no longer required
-- serial_carroceria kept for backward compatibility; prefer serial_niv going forward
COMMENT ON COLUMN vehicles.vehicle_type        IS 'Tipo de uso del vehículo, e.g. MOTO PARTICULAR';
COMMENT ON COLUMN vehicles.vehicle_body_type   IS 'Tipo de carrocería, e.g. DEPORTIVA, SCOOTER, PASEO';
COMMENT ON COLUMN vehicles.serial_niv          IS 'Número de Identificación Vehicular del INTT';
COMMENT ON COLUMN vehicles.seats               IS 'Número de puestos del vehículo';
COMMENT ON COLUMN vehicles.certificado_issued_date IS 'Fecha de expedición del Certificado de Circulación';

-- RS-085: Geolocation fields for profiles (paired with vehicle migration)
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS latitude           DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude          DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS address_from_gps   BOOLEAN DEFAULT false;

COMMENT ON COLUMN profiles.latitude           IS 'GPS latitude captured during onboarding address step';
COMMENT ON COLUMN profiles.longitude          IS 'GPS longitude captured during onboarding address step';
COMMENT ON COLUMN profiles.address_from_gps   IS 'True if estado/municipio were filled via reverse geocoding';

-- Verify
SELECT
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_name IN ('vehicles', 'profiles')
  AND column_name IN (
    'vehicle_type', 'vehicle_body_type', 'serial_niv', 'seats',
    'certificado_issued_date', 'latitude', 'longitude', 'address_from_gps'
  )
ORDER BY table_name, column_name;
