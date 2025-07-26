-- Fix missing database tables and columns
-- Run this in Supabase SQL Editor

-- 1. Fix profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    first_name TEXT,
    last_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add missing columns if table exists
DO $$ 
BEGIN
    -- Add email column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'email') THEN
        ALTER TABLE public.profiles ADD COLUMN email TEXT;
    END IF;
    
    -- Add first_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'first_name') THEN
        ALTER TABLE public.profiles ADD COLUMN first_name TEXT;
    END IF;
    
    -- Add last_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'last_name') THEN
        ALTER TABLE public.profiles ADD COLUMN last_name TEXT;
    END IF;
    
    -- Add avatar_url column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'avatar_url') THEN
        ALTER TABLE public.profiles ADD COLUMN avatar_url TEXT;
    END IF;
END $$;

-- 2. Create user_notification_settings table
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    push_notifications BOOLEAN DEFAULT TRUE,
    breeding_reminders BOOLEAN DEFAULT TRUE,
    health_reminders BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add unique constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'user_notification_settings_user_id_key'
    ) THEN
        ALTER TABLE public.user_notification_settings ADD CONSTRAINT user_notification_settings_user_id_key UNIQUE (user_id);
    END IF;
END $$;

-- 3. Enable RLS on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies for profiles (with IF NOT EXISTS check)
DO $$
BEGIN
    -- Check and create "Users can view own profile" policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Users can view own profile'
    ) THEN
        CREATE POLICY "Users can view own profile" ON public.profiles
            FOR SELECT USING (auth.uid() = id);
    END IF;

    -- Check and create "Users can update own profile" policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Users can update own profile'
    ) THEN
        CREATE POLICY "Users can update own profile" ON public.profiles
            FOR UPDATE USING (auth.uid() = id);
    END IF;

    -- Check and create "Users can insert own profile" policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'profiles' 
        AND policyname = 'Users can insert own profile'
    ) THEN
        CREATE POLICY "Users can insert own profile" ON public.profiles
            FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
END $$;

-- 5. Enable RLS on user_notification_settings
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies for user_notification_settings (with IF NOT EXISTS check)
DO $$
BEGIN
    -- Check and create "Users can view own notification settings" policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_notification_settings' 
        AND policyname = 'Users can view own notification settings'
    ) THEN
        CREATE POLICY "Users can view own notification settings" ON public.user_notification_settings
            FOR SELECT USING (auth.uid() = user_id);
    END IF;

    -- Check and create "Users can update own notification settings" policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_notification_settings' 
        AND policyname = 'Users can update own notification settings'
    ) THEN
        CREATE POLICY "Users can update own notification settings" ON public.user_notification_settings
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;

    -- Check and create "Users can insert own notification settings" policy
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_notification_settings' 
        AND policyname = 'Users can insert own notification settings'
    ) THEN
        CREATE POLICY "Users can insert own notification settings" ON public.user_notification_settings
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- 7. Create function to handle new user registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, first_name, last_name)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name'
    );
    
    INSERT INTO public.user_notification_settings (user_id)
    VALUES (NEW.id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Create trigger for new user registration
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 9. Insert profile for existing user (if needed)
INSERT INTO public.profiles (id, email, first_name, last_name)
VALUES (
    'e070a1d7-26a0-491f-bfde-77177bdeba2d',
    'bekirefe016@gmail.com',
    'Bekir',
    'Efeoğlu'
)
ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name;

-- 10. Insert notification settings for existing user (if needed)
INSERT INTO public.user_notification_settings (user_id)
VALUES ('e070a1d7-26a0-491f-bfde-77177bdeba2d')
ON CONFLICT (user_id) DO NOTHING; 