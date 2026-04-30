-- ============================================================
-- RS-007: Schema Migration v1 → v2 — Part 1: Enum Updates
-- ============================================================
-- Run AFTER the v1 schema has been applied.
-- Adds new enum types and new values to existing enums.
-- ============================================================

-- ============================================================
-- NEW ENUM TYPES
-- ============================================================

CREATE TYPE payment_method AS ENUM (
  'pago_movil_p2p',   -- Standard Pago Móvil P2P transfer
  'bank_transfer',    -- Bank transfer with receipt upload
  'guia_pay_c2p',     -- GUIA PAY pull-based (Phase 1.5)
  'card_tokenized',   -- Tokenized card (Phase 2)
  'domiciliacion'     -- Auto-debit standing order (Phase 1.5)
);

CREATE TYPE broker_status AS ENUM ('active', 'inactive', 'suspended');
CREATE TYPE promoter_status AS ENUM ('active', 'inactive', 'suspended');

-- ============================================================
-- ADD VALUES TO EXISTING ENUMS
-- ============================================================

-- policy_status: add emission-related statuses
ALTER TYPE policy_status ADD VALUE IF NOT EXISTS 'pending_emission' AFTER 'pending_payment';
ALTER TYPE policy_status ADD VALUE IF NOT EXISTS 'observed' AFTER 'active';
ALTER TYPE policy_status ADD VALUE IF NOT EXISTS 'rejected_emission' AFTER 'observed';

-- document_type: add vehicle photo, factura, payment receipt, RCV certificate
ALTER TYPE document_type ADD VALUE IF NOT EXISTS 'vehicle_photo' AFTER 'carnet_circulacion';
ALTER TYPE document_type ADD VALUE IF NOT EXISTS 'factura_compra' AFTER 'vehicle_photo';
ALTER TYPE document_type ADD VALUE IF NOT EXISTS 'payment_receipt' AFTER 'factura_compra';
ALTER TYPE document_type ADD VALUE IF NOT EXISTS 'rcv_certificate' AFTER 'policy_pdf';
