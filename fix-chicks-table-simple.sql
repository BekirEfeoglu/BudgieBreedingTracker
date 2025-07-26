-- Basit Chicks tablosu oluşturma
-- Bu script chicks tablosunu oluşturur

-- 1. Chicks tablosunu oluştur
CREATE TABLE IF NOT EXISTS public.chicks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    hatch_date DATE NOT NULL,
    egg_id UUID REFERENCES public.eggs(id) ON DELETE SET NULL,
    incubation_id UUID NOT NULL REFERENCES public.incubations(id) ON DELETE CASCADE,
    mother_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
    father_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
    gender TEXT,
    color TEXT,
    ring_number TEXT,
    health_notes TEXT,
    photo_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. RLS etkinleştir
ALTER TABLE public.chicks ENABLE ROW LEVEL SECURITY;

-- 3. RLS politikaları (güvenli)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chicks' AND policyname = 'Users can view own chicks') THEN
        CREATE POLICY "Users can view own chicks" ON public.chicks FOR SELECT USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chicks' AND policyname = 'Users can insert own chicks') THEN
        CREATE POLICY "Users can insert own chicks" ON public.chicks FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chicks' AND policyname = 'Users can update own chicks') THEN
        CREATE POLICY "Users can update own chicks" ON public.chicks FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'chicks' AND policyname = 'Users can delete own chicks') THEN
        CREATE POLICY "Users can delete own chicks" ON public.chicks FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 4. Realtime için tabloyu yayınla
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'chicks') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END $$; 