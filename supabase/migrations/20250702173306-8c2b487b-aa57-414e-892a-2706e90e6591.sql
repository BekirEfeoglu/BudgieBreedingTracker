-- Fix remaining functions with search_path security issues

-- 3. Fix get_table_stats function
CREATE OR REPLACE FUNCTION public.get_table_stats(input_table_name text)
RETURNS TABLE(table_name text, row_count bigint, total_size text, index_size text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    input_table_name,
    COALESCE((SELECT n_tup_ins - n_tup_del FROM pg_stat_user_tables WHERE relname = input_table_name), 0),
    pg_size_pretty(pg_total_relation_size(('public.' || input_table_name)::regclass)),
    pg_size_pretty(pg_indexes_size(('public.' || input_table_name)::regclass));
END;
$$;

-- 4. Fix get_bird_family_optimized function
CREATE OR REPLACE FUNCTION public.get_bird_family_optimized(target_bird_id uuid, target_user_id uuid)
RETURNS TABLE(relation_type text, bird_id uuid, bird_name text, bird_gender text, is_chick boolean)
LANGUAGE plpgsql
STABLE 
SECURITY DEFINER
SET search_path TO 'public'
AS $$
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
$$;