-- Fix birds table RLS policies
-- Run this in Supabase SQL Editor

-- 1. Check if birds table exists and has RLS enabled
DO $$
BEGIN
    -- Enable RLS on birds table if not already enabled
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'birds') THEN
        ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- 2. Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON public.birds;

-- 3. Create new RLS policies for birds table
CREATE POLICY "Users can view own birds" ON public.birds
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own birds" ON public.birds
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own birds" ON public.birds
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own birds" ON public.birds
    FOR DELETE USING (auth.uid() = user_id);

-- 4. Check birds table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'birds' 
ORDER BY ordinal_position;

-- 5. Verify RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'birds';

-- 6. List all policies on birds table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'birds'; 