-- Final fix for all remaining issues
-- Run this in Supabase SQL Editor

-- 1. Refresh schema cache for user_notification_settings
NOTIFY pgrst, 'reload schema';

-- 2. Fix birds table RLS policies
DO $$
BEGIN
    -- Enable RLS on birds table if not already enabled
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'birds') THEN
        ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON public.birds;

-- Create new RLS policies for birds table
CREATE POLICY "Users can view own birds" ON public.birds
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own birds" ON public.birds
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own birds" ON public.birds
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own birds" ON public.birds
    FOR DELETE USING (auth.uid() = user_id);

-- 3. Check and fix birds table structure
DO $$
BEGIN
    -- Add user_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'birds' AND column_name = 'user_id') THEN
        ALTER TABLE public.birds ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Add created_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'birds' AND column_name = 'created_at') THEN
        ALTER TABLE public.birds ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'birds' AND column_name = 'updated_at') THEN
        ALTER TABLE public.birds ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 4. Update existing birds to have user_id (if any exist)
UPDATE public.birds 
SET user_id = 'e070a1d7-26a0-491f-bfde-77177bdeba2d'
WHERE user_id IS NULL;

-- 5. Create trigger to automatically set user_id on insert
CREATE OR REPLACE FUNCTION public.handle_bird_insert()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id = auth.uid();
    NEW.created_at = NOW();
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_bird_insert ON public.birds;
CREATE TRIGGER on_bird_insert
    BEFORE INSERT ON public.birds
    FOR EACH ROW EXECUTE FUNCTION public.handle_bird_insert();

-- 6. Create trigger to update updated_at on update
CREATE OR REPLACE FUNCTION public.handle_bird_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS on_bird_update ON public.birds;
CREATE TRIGGER on_bird_update
    BEFORE UPDATE ON public.birds
    FOR EACH ROW EXECUTE FUNCTION public.handle_bird_update();

-- 7. Add missing columns to user_notification_settings if not already added
DO $$
BEGIN
    -- Add egg_turning_enabled column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'egg_turning_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN egg_turning_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add all other missing columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'do_not_disturb_start') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN do_not_disturb_start TIME DEFAULT '22:00:00';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'do_not_disturb_end') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN do_not_disturb_end TIME DEFAULT '08:00:00';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'timezone') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN timezone TEXT DEFAULT 'Europe/Istanbul';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'notification_sound') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN notification_sound BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'vibration') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN vibration BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- 8. Force refresh schema cache again
NOTIFY pgrst, 'reload schema';

-- 9. Verify everything is working
SELECT 'Birds table structure:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'birds' 
ORDER BY ordinal_position;

SELECT 'Birds RLS status:' as info;
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'birds';

SELECT 'Birds policies:' as info;
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'birds';

SELECT 'Notification settings structure:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_notification_settings' 
ORDER BY ordinal_position; 