-- Performance optimizations: Basic compound indexes (final)

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

-- 6. Basic name search optimization
CREATE INDEX IF NOT EXISTS idx_birds_name ON public.birds(user_id, name);
CREATE INDEX IF NOT EXISTS idx_chicks_name ON public.chicks(user_id, name);

-- 7. Partial indexes for common filter conditions
CREATE INDEX IF NOT EXISTS idx_eggs_active_status ON public.eggs(user_id, lay_date) 
WHERE status IN ('laid', 'fertile');

CREATE INDEX IF NOT EXISTS idx_birds_with_gender ON public.birds(user_id, name) 
WHERE gender IS NOT NULL;

-- 8. Performance monitoring function
CREATE OR REPLACE FUNCTION public.get_table_stats(input_table_name text)
RETURNS TABLE(
  table_name text,
  row_count bigint,
  total_size text,
  index_size text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    input_table_name,
    COALESCE((SELECT n_tup_ins - n_tup_del FROM pg_stat_user_tables WHERE relname = input_table_name), 0),
    pg_size_pretty(pg_total_relation_size(('public.' || input_table_name)::regclass)),
    pg_size_pretty(pg_indexes_size(('public.' || input_table_name)::regclass));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Query optimization function for genealogy
CREATE OR REPLACE FUNCTION public.get_bird_family_optimized(target_bird_id uuid, target_user_id uuid)
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
  WHERE b.id = (SELECT father_id FROM public.birds WHERE id = target_bird_id AND user_id = target_user_id)
  
  UNION ALL
  
  SELECT 'mother'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE b.id = (SELECT mother_id FROM public.birds WHERE id = target_bird_id AND user_id = target_user_id)
  
  UNION ALL
  
  -- Children (birds)
  SELECT 'child'::text, b.id, b.name, b.gender, false::boolean
  FROM public.birds b
  WHERE (b.father_id = target_bird_id OR b.mother_id = target_bird_id) AND b.user_id = target_user_id
  
  UNION ALL
  
  -- Children (chicks)
  SELECT 'child'::text, c.id, c.name, c.gender, true::boolean
  FROM public.chicks c
  WHERE (c.father_id = target_bird_id OR c.mother_id = target_bird_id) AND c.user_id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;