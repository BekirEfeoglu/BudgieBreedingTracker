-- Chicks tablosu oluşturma/düzeltme
-- Bu script chicks tablosunu oluşturur veya eksik kolonları ekler

-- 1. Chicks tablosunu oluştur (eğer yoksa)
CREATE TABLE IF NOT EXISTS public.chicks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    hatch_date DATE NOT NULL,
    egg_id UUID REFERENCES public.eggs(id) ON DELETE SET NULL,
    incubation_id UUID NOT NULL REFERENCES public.incubations(id) ON DELETE CASCADE,
    mother_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
    father_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
    clutch_id UUID REFERENCES public.clutches(id) ON DELETE SET NULL,
    gender TEXT,
    color TEXT,
    ring_number TEXT,
    health_notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Eksik kolonları ekle (eğer varsa)
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS name TEXT;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS hatch_date DATE;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS egg_id UUID REFERENCES public.eggs(id) ON DELETE SET NULL;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS incubation_id UUID REFERENCES public.incubations(id) ON DELETE CASCADE;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS mother_id UUID REFERENCES public.birds(id) ON DELETE SET NULL;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS father_id UUID REFERENCES public.birds(id) ON DELETE SET NULL;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS clutch_id UUID REFERENCES public.clutches(id) ON DELETE SET NULL;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS color TEXT;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS ring_number TEXT;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS health_notes TEXT;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.chicks ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. İndeksler oluştur
CREATE INDEX IF NOT EXISTS idx_chicks_user_id ON public.chicks(user_id);
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_id ON public.chicks(incubation_id);
CREATE INDEX IF NOT EXISTS idx_chicks_egg_id ON public.chicks(egg_id);
CREATE INDEX IF NOT EXISTS idx_chicks_mother_id ON public.chicks(mother_id);
CREATE INDEX IF NOT EXISTS idx_chicks_father_id ON public.chicks(father_id);
CREATE INDEX IF NOT EXISTS idx_chicks_hatch_date ON public.chicks(hatch_date);

-- 4. RLS politikaları oluştur
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi yavrularını görebilir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chicks' AND policyname = 'Users can view own chicks') THEN
        CREATE POLICY "Users can view own chicks" ON public.chicks
            FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

-- Kullanıcılar sadece kendi yavrularını ekleyebilir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chicks' AND policyname = 'Users can insert own chicks') THEN
        CREATE POLICY "Users can insert own chicks" ON public.chicks
            FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- Kullanıcılar sadece kendi yavrularını güncelleyebilir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chicks' AND policyname = 'Users can update own chicks') THEN
        CREATE POLICY "Users can update own chicks" ON public.chicks
            FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Kullanıcılar sadece kendi yavrularını silebilir
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chicks' AND policyname = 'Users can delete own chicks') THEN
        CREATE POLICY "Users can delete own chicks" ON public.chicks
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 5. Realtime için tabloyu yayınla
DO $$
BEGIN
    -- Tabloyu yayına ekle (eğer yoksa)
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' 
        AND tablename = 'chicks'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- Hata durumunda sessizce devam et
        NULL;
END $$;

-- 6. Kontrol sorguları
SELECT 'Chicks tablosu yapısı:' as info;
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'chicks' 
AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 'Chicks tablosu realtime durumu:' as info;
SELECT 
    schemaname,
    tablename,
    pubname
FROM pg_publication_tables 
WHERE tablename = 'chicks';

-- 7. RLS politikalarını kontrol et
SELECT 'Chicks tablosu RLS politikaları:' as info;
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
WHERE tablename = 'chicks'; 