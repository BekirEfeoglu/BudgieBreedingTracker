
-- Admin paneli için RLS'yi bypass eden tablo sayım fonksiyonu
-- SECURITY DEFINER olarak çalışır (admin yetkisi provider'da kontrol ediliyor)
CREATE OR REPLACE FUNCTION admin_get_table_counts()
RETURNS TABLE(table_name text, row_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Sadece admin kontrolü (çağıran admin_users tablosunda olmalı)
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  RETURN QUERY
  SELECT 'birds'::text, COUNT(*)::bigint FROM birds
  UNION ALL SELECT 'eggs', COUNT(*) FROM eggs
  UNION ALL SELECT 'chicks', COUNT(*) FROM chicks
  UNION ALL SELECT 'incubations', COUNT(*) FROM incubations
  UNION ALL SELECT 'clutches', COUNT(*) FROM clutches
  UNION ALL SELECT 'breeding_pairs', COUNT(*) FROM breeding_pairs
  UNION ALL SELECT 'nests', COUNT(*) FROM nests
  UNION ALL SELECT 'health_records', COUNT(*) FROM health_records
  UNION ALL SELECT 'growth_measurements', COUNT(*) FROM growth_measurements
  UNION ALL SELECT 'profiles', COUNT(*) FROM profiles
  UNION ALL SELECT 'events', COUNT(*) FROM events
  UNION ALL SELECT 'notifications', COUNT(*) FROM notifications
  UNION ALL SELECT 'notification_settings', COUNT(*) FROM notification_settings
  UNION ALL SELECT 'photos', COUNT(*) FROM photos
  UNION ALL SELECT 'user_subscriptions', COUNT(*) FROM user_subscriptions
  UNION ALL SELECT 'admin_logs', COUNT(*) FROM admin_logs;
END;
$$;

-- Admin stats için toplam count'ları RLS bypass ile alan fonksiyon
CREATE OR REPLACE FUNCTION admin_get_stats()
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result json;
  v_today timestamp;
BEGIN
  -- Sadece admin kontrolü
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Admin permission denied';
  END IF;

  v_today := date_trunc('day', now() at time zone 'UTC');

  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM profiles),
    'total_birds', (SELECT COUNT(*) FROM birds),
    'active_breedings', (SELECT COUNT(*) FROM breeding_pairs),
    'active_today', COALESCE(
      (SELECT COUNT(DISTINCT user_id) FROM user_sessions WHERE created_at >= v_today),
      0
    ) + CASE 
      WHEN (SELECT COUNT(DISTINCT user_id) FROM user_sessions WHERE created_at >= v_today) = 0
      THEN (SELECT COUNT(*) FROM profiles WHERE updated_at >= v_today)
      ELSE 0
    END,
    'new_users_today', (SELECT COUNT(*) FROM profiles WHERE created_at >= v_today)
  ) INTO result;

  RETURN result;
END;
$$;
;
