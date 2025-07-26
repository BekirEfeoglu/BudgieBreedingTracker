-- BudgieBreedingTracker - Step 3: Supabase Realtime and Utility Functions
-- Bu dosya Supabase Realtime kurulumu ve utility fonksiyonlarını oluşturur

-- 1. SUPABASE REALTIME SETUP
-- Publication oluştur
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    CREATE PUBLICATION supabase_realtime FOR ALL TABLES;
  END IF;
END
$$;

-- Tabloları publication'a ekle
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.birds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.incubations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.eggs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chicks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.clutches;
ALTER PUBLICATION supabase_realtime ADD TABLE public.calendar;
ALTER PUBLICATION supabase_realtime ADD TABLE public.photos;
ALTER PUBLICATION supabase_realtime ADD TABLE public.backup_settings;
ALTER PUBLICATION supabase_realtime ADD TABLE public.backup_jobs;
ALTER PUBLICATION supabase_realtime ADD TABLE public.backup_history;
ALTER PUBLICATION supabase_realtime ADD TABLE public.feedback;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;

-- 2. UTILITY FUNCTIONS

-- Genealogy function - Kuş aile ağacını getirir
CREATE OR REPLACE FUNCTION public.get_bird_family(bird_id uuid, user_id uuid)
RETURNS TABLE(
  relation_type text,
  bird_id uuid,
  bird_name text,
  bird_gender text,
  is_chick boolean
) AS $$
BEGIN
  RETURN QUERY
  -- Parents
  SELECT 'father'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE b.id = (SELECT father_id FROM public.birds WHERE id = bird_id AND user_id = user_id)
  
  UNION ALL
  
  SELECT 'mother'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE b.id = (SELECT mother_id FROM public.birds WHERE id = bird_id AND user_id = user_id)
  
  UNION ALL
  
  -- Children (birds)
  SELECT 'child'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE (b.father_id = bird_id OR b.mother_id = bird_id) AND b.user_id = user_id
  
  UNION ALL
  
  -- Children (chicks)
  SELECT 'child'::text, c.id, c.name, c.gender, true::boolean
  FROM public.chicks c
  WHERE (c.father_id = bird_id OR c.mother_id = bird_id) AND c.user_id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Statistics function - Kullanıcı istatistiklerini getirir
CREATE OR REPLACE FUNCTION public.get_user_statistics(user_id uuid)
RETURNS TABLE(
  total_birds bigint,
  total_chicks bigint,
  total_eggs bigint,
  active_incubations bigint,
  total_photos bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM public.birds WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.chicks WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.eggs WHERE user_id = get_user_statistics.user_id),
    (SELECT COUNT(*) FROM public.incubations WHERE user_id = get_user_statistics.user_id AND start_date >= CURRENT_DATE - INTERVAL '30 days'),
    (SELECT COUNT(*) FROM public.photos WHERE user_id = get_user_statistics.user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Breeding statistics function - Üretim istatistiklerini getirir
CREATE OR REPLACE FUNCTION public.get_breeding_statistics(user_id uuid, start_date date DEFAULT CURRENT_DATE - INTERVAL '1 year', end_date date DEFAULT CURRENT_DATE)
RETURNS TABLE(
  total_incubations bigint,
  total_eggs bigint,
  fertile_eggs bigint,
  hatched_eggs bigint,
  success_rate numeric
) AS $$
BEGIN
  RETURN QUERY
  WITH stats AS (
    SELECT 
      COUNT(DISTINCT i.id) as total_incubations,
      COUNT(e.id) as total_eggs,
      COUNT(CASE WHEN e.status = 'fertile' THEN 1 END) as fertile_eggs,
      COUNT(CASE WHEN e.status = 'hatched' THEN 1 END) as hatched_eggs
    FROM public.incubations i
    LEFT JOIN public.eggs e ON i.id = e.incubation_id
    WHERE i.user_id = get_breeding_statistics.user_id
      AND i.start_date BETWEEN start_date AND end_date
  )
  SELECT 
    total_incubations,
    total_eggs,
    fertile_eggs,
    hatched_eggs,
    CASE 
      WHEN total_eggs > 0 THEN ROUND((hatched_eggs::numeric / total_eggs::numeric) * 100, 2)
      ELSE 0
    END as success_rate
  FROM stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Search birds function - Kuş arama fonksiyonu
CREATE OR REPLACE FUNCTION public.search_birds(user_id uuid, search_term text)
RETURNS TABLE(
  id uuid,
  name text,
  gender text,
  color text,
  birth_date date,
  ring_number text
) AS $$
BEGIN
  RETURN QUERY
  SELECT b.id, b.name, b.gender, b.color, b.birth_date, b.ring_number
  FROM public.birds b
  WHERE b.user_id = search_birds.user_id
    AND (
      b.name ILIKE '%' || search_term || '%'
      OR b.color ILIKE '%' || search_term || '%'
      OR b.ring_number ILIKE '%' || search_term || '%'
    )
  ORDER BY b.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Get upcoming events function - Yaklaşan olayları getirir
CREATE OR REPLACE FUNCTION public.get_upcoming_events(user_id uuid, days_ahead integer DEFAULT 30)
RETURNS TABLE(
  id uuid,
  title text,
  description text,
  event_date date,
  event_type text,
  related_bird_name text,
  related_chick_name text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.title,
    c.description,
    c.event_date,
    c.event_type,
    b.name as related_bird_name,
    ch.name as related_chick_name
  FROM public.calendar c
  LEFT JOIN public.birds b ON c.related_bird_id = b.id
  LEFT JOIN public.chicks ch ON c.related_chick_id = ch.id
  WHERE c.user_id = get_upcoming_events.user_id
    AND c.event_date BETWEEN CURRENT_DATE AND CURRENT_DATE + (days_ahead || ' days')::interval
  ORDER BY c.event_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Get bird lineage function - Kuş soy ağacını getirir
CREATE OR REPLACE FUNCTION public.get_bird_lineage(bird_id uuid, user_id uuid, max_generations integer DEFAULT 3)
RETURNS TABLE(
  generation integer,
  bird_id uuid,
  bird_name text,
  bird_gender text,
  relation text
) AS $$
DECLARE
  current_gen integer := 0;
  current_birds uuid[] := ARRAY[bird_id];
  next_birds uuid[] := '{}';
  temp_birds uuid[];
BEGIN
  -- Self
  RETURN QUERY SELECT 
    0 as generation,
    b.id as bird_id,
    b.name as bird_name,
    b.gender as bird_gender,
    'self' as relation
  FROM public.birds b
  WHERE b.id = bird_id AND b.user_id = user_id;
  
  -- Parents and children
  WHILE current_gen < max_generations AND array_length(current_birds, 1) > 0 LOOP
    current_gen := current_gen + 1;
    
    -- Get parents
    FOR temp_birds IN 
      SELECT DISTINCT ARRAY[father_id, mother_id]
      FROM public.birds
      WHERE id = ANY(current_birds) 
        AND user_id = user_id
        AND (father_id IS NOT NULL OR mother_id IS NOT NULL)
    LOOP
      next_birds := array_cat(next_birds, temp_birds);
    END LOOP;
    
    -- Get children
    FOR temp_birds IN 
      SELECT DISTINCT ARRAY[id]
      FROM public.birds
      WHERE (father_id = ANY(current_birds) OR mother_id = ANY(current_birds))
        AND user_id = user_id
    LOOP
      next_birds := array_cat(next_birds, temp_birds);
    END LOOP;
    
    -- Remove duplicates and nulls
    next_birds := array_remove(next_birds, NULL);
    next_birds := array(
      SELECT DISTINCT unnest(next_birds)
      ORDER BY unnest
    );
    
    -- Return results for this generation
    IF array_length(next_birds, 1) > 0 THEN
      RETURN QUERY SELECT 
        current_gen as generation,
        b.id as bird_id,
        b.name as bird_name,
        b.gender as bird_gender,
        CASE 
          WHEN b.id IN (SELECT father_id FROM public.birds WHERE id = ANY(current_birds)) THEN 'parent'
          WHEN b.id IN (SELECT mother_id FROM public.birds WHERE id = ANY(current_birds)) THEN 'parent'
          ELSE 'child'
        END as relation
      FROM public.birds b
      WHERE b.id = ANY(next_birds) AND b.user_id = user_id;
    END IF;
    
    current_birds := next_birds;
    next_birds := '{}';
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Performance monitoring function
CREATE OR REPLACE FUNCTION public.get_table_stats(table_name text)
RETURNS TABLE(
  table_name text,
  row_count bigint,
  total_size text,
  index_size text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    table_name::text,
    COALESCE((SELECT n_tup_ins - n_tup_del FROM pg_stat_user_tables WHERE relname = table_name), 0),
    pg_size_pretty(pg_total_relation_size(('public.' || table_name)::regclass)),
    pg_size_pretty(pg_indexes_size(('public.' || table_name)::regclass));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Statistics update function for better query planning
CREATE OR REPLACE FUNCTION public.update_table_statistics()
RETURNS void AS $$
BEGIN
  ANALYZE public.birds;
  ANALYZE public.chicks;
  ANALYZE public.eggs;
  ANALYZE public.incubations;
  ANALYZE public.clutches;
  ANALYZE public.calendar;
  ANALYZE public.photos;
  ANALYZE public.backup_settings;
  ANALYZE public.backup_jobs;
  ANALYZE public.backup_history;
  ANALYZE public.feedback;
  ANALYZE public.notifications;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. FINAL SETUP
-- Statistics'leri güncelle
SELECT public.update_table_statistics();

SELECT 'Step 3: Supabase Realtime and utility functions created successfully' as status; 