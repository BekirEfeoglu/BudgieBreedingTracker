-- Performance optimizations: Add compound indexes for better query performance (v2)

-- 1. Compound indexes for birds table
CREATE INDEX IF NOT EXISTS idx_birds_user_gender ON public.birds(user_id, gender);
CREATE INDEX IF NOT EXISTS idx_birds_user_birth_date ON public.birds(user_id, birth_date);
CREATE INDEX IF NOT EXISTS idx_birds_user_created_at ON public.birds(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_birds_parents ON public.birds(father_id, mother_id) WHERE father_id IS NOT NULL OR mother_id IS NOT NULL;

-- 2. Compound indexes for eggs table  
CREATE INDEX IF NOT EXISTS idx_eggs_user_status ON public.eggs(user_id, status);
CREATE INDEX IF NOT EXISTS idx_eggs_user_lay_date ON public.eggs(user_id, lay_date);
CREATE INDEX IF NOT EXISTS idx_eggs_incubation_status ON public.eggs(incubation_id, status);
CREATE INDEX IF NOT EXISTS idx_eggs_user_hatch_date ON public.eggs(user_id, hatch_date) WHERE hatch_date IS NOT NULL;

-- 3. Compound indexes for chicks table
CREATE INDEX IF NOT EXISTS idx_chicks_user_hatch_date ON public.chicks(user_id, hatch_date);
CREATE INDEX IF NOT EXISTS idx_chicks_user_gender ON public.chicks(user_id, gender);
CREATE INDEX IF NOT EXISTS idx_chicks_incubation_hatch ON public.chicks(incubation_id, hatch_date);
CREATE INDEX IF NOT EXISTS idx_chicks_parents ON public.chicks(father_id, mother_id) WHERE father_id IS NOT NULL OR mother_id IS NOT NULL;

-- 4. Compound indexes for incubations table
CREATE INDEX IF NOT EXISTS idx_incubations_user_start_date ON public.incubations(user_id, start_date);
CREATE INDEX IF NOT EXISTS idx_incubations_user_created_at ON public.incubations(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_incubations_parents ON public.incubations(male_bird_id, female_bird_id) WHERE male_bird_id IS NOT NULL OR female_bird_id IS NOT NULL;

-- 5. Compound indexes for clutches table
CREATE INDEX IF NOT EXISTS idx_clutches_user_pair_date ON public.clutches(user_id, pair_date);
CREATE INDEX IF NOT EXISTS idx_clutches_user_expected_hatch ON public.clutches(user_id, expected_hatch_date) WHERE expected_hatch_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_clutches_birds ON public.clutches(male_bird_id, female_bird_id) WHERE male_bird_id IS NOT NULL OR female_bird_id IS NOT NULL;

-- 6. Functional indexes for common search patterns
CREATE INDEX IF NOT EXISTS idx_birds_name_search ON public.birds USING gin(to_tsvector('turkish', name));
CREATE INDEX IF NOT EXISTS idx_chicks_name_search ON public.chicks USING gin(to_tsvector('turkish', name));

-- 7. Partial indexes for active data (using specific dates instead of NOW())
CREATE INDEX IF NOT EXISTS idx_birds_recent_2024 ON public.birds(user_id, created_at) 
WHERE created_at > '2024-01-01'::timestamp;

CREATE INDEX IF NOT EXISTS idx_incubations_recent_2024 ON public.incubations(user_id, start_date) 
WHERE start_date > '2024-01-01'::date;

CREATE INDEX IF NOT EXISTS idx_eggs_active_status ON public.eggs(user_id, lay_date) 
WHERE status IN ('laid', 'fertile');

-- 8. Performance monitoring function
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

-- 9. Query optimization function for genealogy
CREATE OR REPLACE FUNCTION public.get_bird_family_optimized(bird_id uuid, user_id uuid)
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

-- 10. Statistics update function for better query planning
CREATE OR REPLACE FUNCTION public.update_table_statistics()
RETURNS void AS $$
BEGIN
  ANALYZE public.birds;
  ANALYZE public.chicks;
  ANALYZE public.eggs;
  ANALYZE public.incubations;
  ANALYZE public.clutches;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;