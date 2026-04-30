-- RS-128: Add email column to profiles table
-- Email is optional — many users sign up via phone/WhatsApp OTP only.
-- The primary source of truth is auth.users.email; this column is a cached
-- copy written during onboarding if the user provides their email.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS email TEXT;

COMMENT ON COLUMN profiles.email IS
  'Optional email address for document delivery. '
  'Primary source of truth is auth.users.email.';
