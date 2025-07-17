-- Geri bildirim sistemi için tablo
CREATE TABLE public.feedback (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email TEXT,
  type TEXT NOT NULL CHECK (type IN ('bug', 'feature', 'improvement', 'general')),
  priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'critical')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  system_info JSONB,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'in_progress', 'resolved', 'closed')),
  admin_notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- İndeksler
CREATE INDEX idx_feedback_user_id ON public.feedback(user_id);
CREATE INDEX idx_feedback_type ON public.feedback(type);
CREATE INDEX idx_feedback_priority ON public.feedback(priority);
CREATE INDEX idx_feedback_status ON public.feedback(status);
CREATE INDEX idx_feedback_created_at ON public.feedback(created_at);

-- RLS politikaları
ALTER TABLE public.feedback ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar kendi geri bildirimlerini görebilir
CREATE POLICY "Users can view their own feedback" ON public.feedback
  FOR SELECT USING (auth.uid() = user_id);

-- Kullanıcılar geri bildirim ekleyebilir
CREATE POLICY "Users can insert feedback" ON public.feedback
  FOR INSERT WITH CHECK (true);

-- Kullanıcılar kendi geri bildirimlerini güncelleyebilir
CREATE POLICY "Users can update their own feedback" ON public.feedback
  FOR UPDATE USING (auth.uid() = user_id);

-- Admin kullanıcılar tüm geri bildirimleri görebilir (opsiyonel)
-- Bu politikayı sadece admin rolü varsa ekleyin
-- CREATE POLICY "Admins can view all feedback" ON public.feedback
--   FOR ALL USING (auth.jwt() ->> 'role' = 'admin');

-- Otomatik updated_at güncellemesi
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_feedback_updated_at 
    BEFORE UPDATE ON public.feedback 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column(); 