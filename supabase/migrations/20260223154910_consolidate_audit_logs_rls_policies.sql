
-- audit_logs: Replace admin ALL + user INSERT with specific per-command policies
-- Users can only INSERT own logs, admins can do everything.

DROP POLICY IF EXISTS "audit_logs: admin all" ON audit_logs;
DROP POLICY IF EXISTS "audit_logs: insert own" ON audit_logs;

-- INSERT: users insert own + admins insert any
CREATE POLICY "audit_logs: insert" ON audit_logs FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- SELECT: admin only
CREATE POLICY "audit_logs: select" ON audit_logs FOR SELECT
  USING (( SELECT is_admin()));

-- UPDATE: admin only
CREATE POLICY "audit_logs: update" ON audit_logs FOR UPDATE
  USING (( SELECT is_admin()))
  WITH CHECK (( SELECT is_admin()));

-- DELETE: admin only
CREATE POLICY "audit_logs: delete" ON audit_logs FOR DELETE
  USING (( SELECT is_admin()));
;
