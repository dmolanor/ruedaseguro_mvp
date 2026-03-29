-- ============================================================
-- RS-010: Seed Data for Development and Demos
-- ============================================================
-- Realistic test data for the full B2B2C hierarchy.
-- Idempotent: uses ON CONFLICT DO NOTHING where possible.
-- Run AFTER all RS-007 migrations and RS-009 storage.
-- ============================================================

-- ============================================================
-- CARRIERS
-- ============================================================

INSERT INTO carriers (id, name, rif, contact_email, contact_phone, is_active, required_documents, config)
VALUES
  (
    '11111111-1111-1111-1111-111111111111',
    'Seguros Pirámide',
    'J-00312345-6',
    'contacto@segurospir.com',
    '+58 212-555-0001',
    true,
    '["cedula","carnet_circulacion","vehicle_photo"]',
    '{"emission_endpoint": null, "api_key": null}'::jsonb
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'Seguros Caracas',
    'J-00012345-6',
    'contacto@seguroscaracas.com',
    '+58 212-555-0002',
    true,
    '["cedula","carnet_circulacion","vehicle_photo"]',
    '{"emission_endpoint": null, "api_key": null}'::jsonb
  )
ON CONFLICT (rif) DO NOTHING;

-- ============================================================
-- POLICY TYPES (per carrier — matching v2.0 multi-tier products)
-- ============================================================

-- Seguros Pirámide products
INSERT INTO policy_types (id, carrier_id, code, name, description, tier, price_usd, coverage_amount_usd, duration_days, payment_frequency, coverage_details, upsell_options, target_percentage, is_active)
VALUES
  (
    'aaaa1111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'RCV_BASICA',
    'Solo RCV',
    'Responsabilidad Civil Vehicular básica. Cobertura obligatoria ante terceros.',
    'basica',
    17.00,
    50000.00,
    365,
    'annual',
    '{"danos_cosas": 25000, "danos_personas": 50000, "defensa_legal": true}'::jsonb,
    '[]'::jsonb,
    70.00,
    true
  ),
  (
    'aaaa2222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'RCV_GRUA',
    'RCV + Grúa',
    'RCV básica con servicio de grúa incluido ante siniestro.',
    'basica',
    22.00,
    50000.00,
    365,
    'annual',
    '{"danos_cosas": 25000, "danos_personas": 50000, "defensa_legal": true, "grua": true}'::jsonb,
    '[]'::jsonb,
    null,
    true
  ),
  (
    'aaaa3333-3333-3333-3333-333333333333',
    '11111111-1111-1111-1111-111111111111',
    'RCV_PLUS',
    'RCV Plus',
    'RCV con asistencia médica inmediata vía Venemergencia. Incluye grúa y asistencia legal ampliada.',
    'plus',
    31.00,
    75000.00,
    365,
    'annual',
    '{"danos_cosas": 37500, "danos_personas": 75000, "defensa_legal": true, "grua": true, "asistencia_medica": true}'::jsonb,
    '[{"name": "Gastos Funerarios", "price_usd": 10}]'::jsonb,
    30.00,
    true
  ),
  (
    'aaaa4444-4444-4444-4444-444444444444',
    '11111111-1111-1111-1111-111111111111',
    'RCV_AMPLIADA',
    'RCV Ampliada',
    'Cobertura extendida: RCV + Accidentes Personales 24/7 + Asistencia Médica + Grúa + Defensa Legal Premium.',
    'ampliada',
    110.00,
    150000.00,
    365,
    'annual',
    '{"danos_cosas": 75000, "danos_personas": 150000, "defensa_legal": true, "grua": true, "asistencia_medica": true, "accidentes_personales_24_7": true}'::jsonb,
    '[{"name": "Gastos Funerarios", "price_usd": 10}, {"name": "Responsabilidad Civil Patronal", "price_usd": 15}]'::jsonb,
    5.00,
    true
  )
ON CONFLICT (carrier_id, code) DO NOTHING;

-- Seguros Caracas products (same structure, different carrier)
INSERT INTO policy_types (id, carrier_id, code, name, description, tier, price_usd, coverage_amount_usd, duration_days, payment_frequency, target_percentage, is_active)
VALUES
  (
    'bbbb1111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    'RCV_BASICA',
    'Solo RCV',
    'Responsabilidad Civil Vehicular básica.',
    'basica',
    17.00,
    50000.00,
    365,
    'annual',
    70.00,
    true
  ),
  (
    'bbbb2222-2222-2222-2222-222222222222',
    '22222222-2222-2222-2222-222222222222',
    'RCV_PLUS',
    'RCV Plus',
    'RCV con asistencia médica y grúa.',
    'plus',
    31.00,
    75000.00,
    365,
    'annual',
    30.00,
    true
  )
ON CONFLICT (carrier_id, code) DO NOTHING;

-- ============================================================
-- BROKERS (Corredores de Seguros)
-- ============================================================

INSERT INTO brokers (id, carrier_id, full_name, rif, email, phone, policy_quota, commission_rate, status)
VALUES
  (
    'b00c1111-1111-1111-1111-111111111111',
    '11111111-1111-1111-1111-111111111111',
    'María González',
    'V-12345678-0',
    'maria.gonzalez@corredor.test',
    '+58 412-555-1001',
    800,
    0.2500,
    'active'
  ),
  (
    'b00c2222-2222-2222-2222-222222222222',
    '11111111-1111-1111-1111-111111111111',
    'Carlos Rodríguez',
    'V-23456789-0',
    'carlos.rodriguez@corredor.test',
    '+58 414-555-1002',
    800,
    0.2500,
    'active'
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- PROMOTERS (Promotores — motorized sales allies)
-- ============================================================

INSERT INTO promoters (id, broker_id, full_name, id_number, phone, email, referral_code, status)
VALUES
  (
    'face1111-1111-1111-1111-111111111111',
    'b00c1111-1111-1111-1111-111111111111',
    'Luis Martínez',
    'V-34567890',
    '+58 416-555-2001',
    'luis.martinez@promotor.test',
    'RS-LUIS-0001',
    'active'
  ),
  (
    'face2222-2222-2222-2222-222222222222',
    'b00c1111-1111-1111-1111-111111111111',
    'Ana Pérez',
    'V-45678901',
    '+58 424-555-2002',
    'ana.perez@promotor.test',
    'RS-ANAP-0002',
    'active'
  ),
  (
    'face3333-3333-3333-3333-333333333333',
    'b00c2222-2222-2222-2222-222222222222',
    'Jorge Ramírez',
    'V-56789012',
    '+58 412-555-2003',
    'jorge.ramirez@promotor.test',
    'RS-JORG-0003',
    'active'
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- POINTS OF SALE
-- ============================================================

INSERT INTO points_of_sale (id, broker_id, name, type, address, city, state, latitude, longitude, is_active)
VALUES
  (
    'c0de1111-1111-1111-1111-111111111111',
    'b00c1111-1111-1111-1111-111111111111',
    'Estación Caracas Centro',
    'gas_station',
    'Av. Baralt, Centro, Caracas',
    'Caracas',
    'Distrito Capital',
    10.5061,
    -66.9146,
    true
  ),
  (
    'c0de2222-2222-2222-2222-222222222222',
    'b00c2222-2222-2222-2222-222222222222',
    'Repuestos Express Altamira',
    'parts_shop',
    'Av. San Juan Bosco, Altamira, Caracas',
    'Caracas',
    'Miranda',
    10.4963,
    -66.8548,
    true
  )
ON CONFLICT DO NOTHING;

-- ============================================================
-- EXCHANGE RATE (current approximate BCV rate)
-- ============================================================

INSERT INTO exchange_rates (currency_pair, rate, source, fetched_at, is_official, raw_response)
VALUES
  (
    'USD/VES',
    78.50,                    -- Approximate BCV rate — update when running
    'BCV',
    now(),
    true,
    '{"note": "Seed data — replace with real BCV rate"}'::jsonb
  );

-- ============================================================
-- NOTE: Carrier admin users
-- ============================================================
-- Carrier admin users (admin@segurospir.test, admin@seguroscar.test)
-- must be created through Supabase Auth first (email signup),
-- then linked to carrier_users table.
--
-- After creating auth users via Dashboard or API:
--
-- INSERT INTO carrier_users (auth_user_id, carrier_id, role, full_name, email)
-- VALUES
--   ('<auth_user_uuid_for_admin@segurospir.test>', '11111111-1111-1111-1111-111111111111', 'admin', 'Admin Pirámide', 'admin@segurospir.test'),
--   ('<auth_user_uuid_for_admin@seguroscar.test>', '22222222-2222-2222-2222-222222222222', 'admin', 'Admin Caracas', 'admin@seguroscar.test');
