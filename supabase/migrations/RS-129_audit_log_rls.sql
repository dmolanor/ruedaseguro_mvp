-- ============================================================
-- RS-129: Audit Log — authenticated INSERT policy
-- ============================================================
-- Without this, audit_log is service-role-only and all INSERT
-- calls from the mobile anon-key client fail silently.
-- Riders may only write rows where actor_id = their own UID.
-- No SELECT policy: riders cannot read the audit log.
-- ============================================================

CREATE POLICY "riders_insert_own_audit"
  ON audit_log FOR INSERT
  WITH CHECK (actor_id = auth.uid());
