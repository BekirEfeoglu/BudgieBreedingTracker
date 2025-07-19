-- 🚨 SUPABASE HIZLI DÜZELTME - Tek tek çalıştırın

-- 1. Tüm rate limiting'i devre dışı bırak
UPDATE auth.config 
SET 
  rate_limit_email_sent = 999999999,
  rate_limit_sms_sent = 999999999,
  rate_limit_verify = 999999999,
  rate_limit_email_change = 999999999,
  rate_limit_phone_change = 999999999,
  rate_limit_signup = 999999999,
  rate_limit_signin = 999999999,
  rate_limit_reset = 999999999;

-- 2. E-posta doğrulamayı devre dışı bırak
UPDATE auth.config 
SET enable_email_confirmations = false;

-- 3. Site URL'lerini güncelle
UPDATE auth.config 
SET 
  site_url = 'https://www.budgiebreedingtracker.com',
  redirect_urls = ARRAY['https://www.budgiebreedingtracker.com', 'https://www.budgiebreedingtracker.com/'];

-- 4. Mevcut rate limit kayıtlarını temizle
DELETE FROM auth.flow_state WHERE created_at < NOW() - INTERVAL '1 hour';

-- 5. Ayarları kontrol et (son adım)
SELECT 
  rate_limit_email_sent,
  rate_limit_sms_sent,
  rate_limit_verify,
  rate_limit_email_change,
  rate_limit_phone_change,
  rate_limit_signup,
  rate_limit_signin,
  rate_limit_reset,
  enable_email_confirmations,
  site_url
FROM auth.config; 