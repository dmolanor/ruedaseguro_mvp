-- ============================================================
-- RS-009: Configure Supabase Storage Buckets
-- ============================================================
-- Run in SQL Editor or via Supabase Dashboard.
-- Note: Supabase storage buckets are typically created via
-- Dashboard or the storage API, but can be created via SQL
-- using the storage schema directly.
-- ============================================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('documents', 'documents', false, 10485760, -- 10MB
   ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']),
  ('policies', 'policies', false, 5242880,   -- 5MB
   ARRAY['application/pdf']),
  ('receipts', 'receipts', false, 10485760,  -- 10MB
   ARRAY['image/jpeg', 'image/png', 'application/pdf']),
  ('public', 'public', true, 2097152,        -- 2MB
   ARRAY['image/jpeg', 'image/png', 'image/svg+xml', 'image/webp'])
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- STORAGE RLS POLICIES
-- ============================================================

-- DOCUMENTS bucket: users upload to their own folder, read their own files
CREATE POLICY "Users can upload documents to own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'documents'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'documents'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- POLICIES bucket: users can read their own policy PDFs
CREATE POLICY "Users can view own policies"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'policies'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Service role inserts policy PDFs (server-side generation)
-- No INSERT policy needed for riders — only service role writes here

-- RECEIPTS bucket: users upload to their own folder, read their own files
CREATE POLICY "Users can upload receipts to own folder"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'receipts'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can view own receipts"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'receipts'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- PUBLIC bucket: anyone can read
CREATE POLICY "Public bucket is readable by all"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'public');

-- Public bucket writes are service-role only (no policy needed)
