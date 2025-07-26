-- Fix missing columns in user_notification_settings
-- Run this in Supabase SQL Editor

-- Add missing columns to user_notification_settings
DO $$
BEGIN
    -- Add egg_turning_enabled column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'egg_turning_enabled') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN egg_turning_enabled BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add incubation_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'incubation_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN incubation_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add hatching_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'hatching_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN hatching_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add feeding_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'feeding_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN feeding_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add health_check_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'health_check_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN health_check_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add medication_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'medication_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN medication_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add cleaning_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'cleaning_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN cleaning_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add weight_tracking_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'weight_tracking_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN weight_tracking_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add breeding_season_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'breeding_season_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN breeding_season_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add molting_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'molting_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN molting_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add vet_appointment_reminders column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'vet_appointment_reminders') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN vet_appointment_reminders BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add daily_summary column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'daily_summary') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN daily_summary BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- Add weekly_report column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'weekly_report') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN weekly_report BOOLEAN DEFAULT FALSE;
    END IF;
    
    -- Add monthly_report column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notification_settings' AND column_name = 'monthly_report') THEN
        ALTER TABLE public.user_notification_settings ADD COLUMN monthly_report BOOLEAN DEFAULT FALSE;
    END IF;
END $$;

-- Show current table structure
SELECT 'Current user_notification_settings structure:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_notification_settings' 
ORDER BY ordinal_position; 