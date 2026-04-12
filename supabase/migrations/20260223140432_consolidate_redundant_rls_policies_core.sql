
-- ================================================================
-- Consolidate redundant RLS policies: merge admin ALL into specific
-- policies to reduce multiple permissive policy evaluation overhead.
-- Core entity tables: birds, breeding_pairs, chicks, clutches, eggs,
-- incubations, nests, growth_measurements, health_records
-- ================================================================

-- === BIRDS ===
DROP POLICY IF EXISTS "birds: admin all" ON birds;
DROP POLICY IF EXISTS "Users can insert own birds" ON birds;
CREATE POLICY "Users can insert own birds" ON birds FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own birds" ON birds;
CREATE POLICY "Users can delete own birds" ON birds FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own birds" ON birds;
CREATE POLICY "Users can update own birds" ON birds FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === BREEDING_PAIRS ===
DROP POLICY IF EXISTS "breeding_pairs: admin all" ON breeding_pairs;
DROP POLICY IF EXISTS "Users can insert own breeding_pairs" ON breeding_pairs;
CREATE POLICY "Users can insert own breeding_pairs" ON breeding_pairs FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own breeding_pairs" ON breeding_pairs;
CREATE POLICY "Users can delete own breeding_pairs" ON breeding_pairs FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own breeding_pairs" ON breeding_pairs;
CREATE POLICY "Users can update own breeding_pairs" ON breeding_pairs FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === CHICKS ===
DROP POLICY IF EXISTS "chicks: admin all" ON chicks;
DROP POLICY IF EXISTS "Users can insert own chicks" ON chicks;
CREATE POLICY "Users can insert own chicks" ON chicks FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own chicks" ON chicks;
CREATE POLICY "Users can delete own chicks" ON chicks FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own chicks" ON chicks;
CREATE POLICY "Users can update own chicks" ON chicks FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === CLUTCHES ===
DROP POLICY IF EXISTS "clutches: admin all" ON clutches;
DROP POLICY IF EXISTS "Users can insert own clutches" ON clutches;
CREATE POLICY "Users can insert own clutches" ON clutches FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own clutches" ON clutches;
CREATE POLICY "Users can delete own clutches" ON clutches FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own clutches" ON clutches;
CREATE POLICY "Users can update own clutches" ON clutches FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === EGGS ===
DROP POLICY IF EXISTS "eggs: admin all" ON eggs;
DROP POLICY IF EXISTS "Users can insert own eggs" ON eggs;
CREATE POLICY "Users can insert own eggs" ON eggs FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own eggs" ON eggs;
CREATE POLICY "Users can delete own eggs" ON eggs FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own eggs" ON eggs;
CREATE POLICY "Users can update own eggs" ON eggs FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === INCUBATIONS ===
DROP POLICY IF EXISTS "incubations: admin all" ON incubations;
DROP POLICY IF EXISTS "Users can insert own incubations" ON incubations;
CREATE POLICY "Users can insert own incubations" ON incubations FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own incubations" ON incubations;
CREATE POLICY "Users can delete own incubations" ON incubations FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own incubations" ON incubations;
CREATE POLICY "Users can update own incubations" ON incubations FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === NESTS ===
DROP POLICY IF EXISTS "nests: admin all" ON nests;
DROP POLICY IF EXISTS "Users can insert own nests" ON nests;
CREATE POLICY "Users can insert own nests" ON nests FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own nests" ON nests;
CREATE POLICY "Users can delete own nests" ON nests FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own nests" ON nests;
CREATE POLICY "Users can update own nests" ON nests FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === GROWTH_MEASUREMENTS ===
DROP POLICY IF EXISTS "growth_measurements: admin all" ON growth_measurements;
DROP POLICY IF EXISTS "Users can insert own growth_measurements" ON growth_measurements;
CREATE POLICY "Users can insert own growth_measurements" ON growth_measurements FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own growth_measurements" ON growth_measurements;
CREATE POLICY "Users can delete own growth_measurements" ON growth_measurements FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own growth_measurements" ON growth_measurements;
CREATE POLICY "Users can update own growth_measurements" ON growth_measurements FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));

-- === HEALTH_RECORDS ===
DROP POLICY IF EXISTS "health_records: admin all" ON health_records;
DROP POLICY IF EXISTS "Users can insert own health_records" ON health_records;
CREATE POLICY "Users can insert own health_records" ON health_records FOR INSERT
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can delete own health_records" ON health_records;
CREATE POLICY "Users can delete own health_records" ON health_records FOR DELETE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
DROP POLICY IF EXISTS "Users can update own health_records" ON health_records;
CREATE POLICY "Users can update own health_records" ON health_records FOR UPDATE
  USING ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()))
  WITH CHECK ((( SELECT auth.uid()) = user_id) OR ( SELECT is_admin()));
;
