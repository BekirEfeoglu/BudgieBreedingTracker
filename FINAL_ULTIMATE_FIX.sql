-- Final Ultimate fix for all issues
-- Run this in Supabase SQL Editor

-- 1. Add ALL possible missing columns to user_notification_settings
DO $$
BEGIN
    -- Add feeding_reminders_enabled column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'feeding_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN feeding_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add feeding_interval column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'feeding_interval') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN feeding_interval INTEGER DEFAULT 4;
    END IF;
    
    -- Add egg_turning_interval column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'egg_turning_interval') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN egg_turning_interval INTEGER DEFAULT 4;
    END IF;
    
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
    
    -- Add all reminder columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'incubation_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN incubation_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'hatching_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN hatching_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'feeding_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN feeding_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'health_check_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN health_check_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'medication_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN medication_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'cleaning_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN cleaning_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'weight_tracking_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN weight_tracking_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'breeding_season_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN breeding_season_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'molting_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN molting_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'vet_appointment_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN vet_appointment_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'daily_summary') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN daily_summary BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'weekly_report') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN weekly_report BOOLEAN DEFAULT FALSE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'monthly_report') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN monthly_report BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- Add any other possible columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'water_change_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN water_change_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'nest_cleaning_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN nest_cleaning_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'temperature_check_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN temperature_check_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'humidity_check_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN humidity_check_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add any other possible enabled columns
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'incubation_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN incubation_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'hatching_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN hatching_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'health_check_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN health_check_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'medication_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN medication_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'cleaning_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN cleaning_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'weight_tracking_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN weight_tracking_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'breeding_season_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN breeding_season_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'molting_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN molting_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'vet_appointment_reminders_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN vet_appointment_reminders_enabled BOOLEAN DEFAULT TRUE;
    END IF;
END $$;

-- 2. Fix birds table RLS policies - COMPLETE REWRITE
DO $$
BEGIN
    -- Enable RLS on birds table
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'birds') THEN
        ALTER TABLE public.birds ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Drop ALL existing policies
DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON public.birds;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.birds;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.birds;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.birds;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.birds;
DROP POLICY IF EXISTS "Users can view own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can insert own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can update own birds" ON public.birds;
DROP POLICY IF EXISTS "Users can delete own birds" ON public.birds;

-- Create NEW policies
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

-- 4. Update existing birds to have user_id
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

-- 7. Force refresh schema cache
NOTIFY pgrst, 'reload schema';

-- 8. Wait a moment for cache refresh
SELECT pg_sleep(3);

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