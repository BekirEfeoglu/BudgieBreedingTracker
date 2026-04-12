
-- Fix 4a: Replace auth.uid() with (select auth.uid()) for core domain tables
-- This is a PostgreSQL performance optimization: subquery form is evaluated once and cached

-- ========== BIRDS ==========
DROP POLICY IF EXISTS "Users can view own birds" ON birds;
DROP POLICY IF EXISTS "Users can insert own birds" ON birds;
DROP POLICY IF EXISTS "Users can update own birds" ON birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON birds;

CREATE POLICY "Users can view own birds" ON birds FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own birds" ON birds FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own birds" ON birds FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own birds" ON birds FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== EGGS ==========
DROP POLICY IF EXISTS "Users can view own eggs" ON eggs;
DROP POLICY IF EXISTS "Users can insert own eggs" ON eggs;
DROP POLICY IF EXISTS "Users can update own eggs" ON eggs;
DROP POLICY IF EXISTS "Users can delete own eggs" ON eggs;

CREATE POLICY "Users can view own eggs" ON eggs FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own eggs" ON eggs FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own eggs" ON eggs FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own eggs" ON eggs FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== CHICKS ==========
DROP POLICY IF EXISTS "Users can view own chicks" ON chicks;
DROP POLICY IF EXISTS "Users can insert own chicks" ON chicks;
DROP POLICY IF EXISTS "Users can update own chicks" ON chicks;
DROP POLICY IF EXISTS "Users can delete own chicks" ON chicks;

CREATE POLICY "Users can view own chicks" ON chicks FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own chicks" ON chicks FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own chicks" ON chicks FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own chicks" ON chicks FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== BREEDING_PAIRS ==========
DROP POLICY IF EXISTS "Users can view own breeding_pairs" ON breeding_pairs;
DROP POLICY IF EXISTS "Users can insert own breeding_pairs" ON breeding_pairs;
DROP POLICY IF EXISTS "Users can update own breeding_pairs" ON breeding_pairs;
DROP POLICY IF EXISTS "Users can delete own breeding_pairs" ON breeding_pairs;

CREATE POLICY "Users can view own breeding_pairs" ON breeding_pairs FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own breeding_pairs" ON breeding_pairs FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own breeding_pairs" ON breeding_pairs FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own breeding_pairs" ON breeding_pairs FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== INCUBATIONS ==========
DROP POLICY IF EXISTS "Users can view own incubations" ON incubations;
DROP POLICY IF EXISTS "Users can insert own incubations" ON incubations;
DROP POLICY IF EXISTS "Users can update own incubations" ON incubations;
DROP POLICY IF EXISTS "Users can delete own incubations" ON incubations;

CREATE POLICY "Users can view own incubations" ON incubations FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own incubations" ON incubations FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own incubations" ON incubations FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own incubations" ON incubations FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== HEALTH_RECORDS ==========
DROP POLICY IF EXISTS "Users can view own health_records" ON health_records;
DROP POLICY IF EXISTS "Users can insert own health_records" ON health_records;
DROP POLICY IF EXISTS "Users can update own health_records" ON health_records;
DROP POLICY IF EXISTS "Users can delete own health_records" ON health_records;

CREATE POLICY "Users can view own health_records" ON health_records FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own health_records" ON health_records FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own health_records" ON health_records FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own health_records" ON health_records FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== GROWTH_MEASUREMENTS ==========
DROP POLICY IF EXISTS "Users can view own growth_measurements" ON growth_measurements;
DROP POLICY IF EXISTS "Users can insert own growth_measurements" ON growth_measurements;
DROP POLICY IF EXISTS "Users can update own growth_measurements" ON growth_measurements;
DROP POLICY IF EXISTS "Users can delete own growth_measurements" ON growth_measurements;

CREATE POLICY "Users can view own growth_measurements" ON growth_measurements FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can insert own growth_measurements" ON growth_measurements FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can update own growth_measurements" ON growth_measurements FOR UPDATE TO authenticated
  USING ((select auth.uid()) = user_id);
CREATE POLICY "Users can delete own growth_measurements" ON growth_measurements FOR DELETE TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== CLUTCHES ==========
DROP POLICY IF EXISTS "Users can manage own clutches" ON clutches;
CREATE POLICY "Users can manage own clutches" ON clutches FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== NESTS ==========
DROP POLICY IF EXISTS "Users can manage own nests" ON nests;
CREATE POLICY "Users can manage own nests" ON nests FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== PHOTOS ==========
DROP POLICY IF EXISTS "Users can manage own photos" ON photos;
CREATE POLICY "Users can manage own photos" ON photos FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== DELETED_EGGS ==========
DROP POLICY IF EXISTS "Users can insert own deleted eggs" ON deleted_eggs;
DROP POLICY IF EXISTS "Users can view own deleted eggs" ON deleted_eggs;
CREATE POLICY "Users can insert own deleted eggs" ON deleted_eggs FOR INSERT TO authenticated
  WITH CHECK ((select auth.uid()) = user_id);
CREATE POLICY "Users can view own deleted eggs" ON deleted_eggs FOR SELECT TO authenticated
  USING ((select auth.uid()) = user_id);

-- ========== EGG_ARCHIVES ==========
DROP POLICY IF EXISTS "Users can manage own egg archives" ON egg_archives;
CREATE POLICY "Users can manage own egg archives" ON egg_archives FOR ALL TO authenticated
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- ========== PROFILES ==========
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT TO authenticated
  USING ((select auth.uid()) = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE TO authenticated
  USING ((select auth.uid()) = id);
;
