-- Fix storage RLS policies for avatars bucket
CREATE POLICY "Users can delete their own avatars" 
ON storage.objects 
FOR DELETE 
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Anyone can view avatars" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'avatars');

-- Enhance database function security with input validation
CREATE OR REPLACE FUNCTION public.get_bird_family_optimized(target_bird_id uuid, target_user_id uuid)
 RETURNS TABLE(relation_type text, bird_id uuid, bird_name text, bird_gender text, is_chick boolean)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Input validation
  IF target_bird_id IS NULL OR target_user_id IS NULL THEN
    RAISE EXCEPTION 'Invalid input parameters';
  END IF;
  
  -- Verify user owns the target bird
  IF NOT EXISTS (
    SELECT 1 FROM public.birds 
    WHERE id = target_bird_id AND user_id = target_user_id
  ) THEN
    RAISE EXCEPTION 'Access denied: bird not found or not owned by user';
  END IF;
  
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
$function$;

-- Enhanced validation triggers with input sanitization
CREATE OR REPLACE FUNCTION public.validate_egg_relationships()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Input validation and sanitization
  IF NEW.incubation_id IS NULL THEN
    RAISE EXCEPTION 'Yumurta bir kuluçka ile ilişkilendirilmelidir';
  END IF;
  
  -- Sanitize text inputs
  NEW.notes = TRIM(COALESCE(NEW.notes, ''));
  IF LENGTH(NEW.notes) > 1000 THEN
    NEW.notes = LEFT(NEW.notes, 1000);
  END IF;
  
  -- Validate numeric inputs
  IF NEW.weight_grams IS NOT NULL AND NEW.weight_grams < 0 THEN
    RAISE EXCEPTION 'Ağırlık negatif olamaz';
  END IF;
  
  -- Ensure incubation_id exists and belongs to the same user
  IF NOT EXISTS (
    SELECT 1 FROM public.incubations 
    WHERE id = NEW.incubation_id AND user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'Geçersiz incubation_id veya yetki hatası: %', NEW.incubation_id;
  END IF;
  
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.validate_chick_relationships()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Input validation
  IF NEW.incubation_id IS NULL THEN
    RAISE EXCEPTION 'Civciv bir kuluçka ile ilişkilendirilmelidir';
  END IF;
  
  -- Sanitize text inputs
  NEW.name = TRIM(COALESCE(NEW.name, ''));
  NEW.health_notes = TRIM(COALESCE(NEW.health_notes, ''));
  NEW.ring_number = TRIM(COALESCE(NEW.ring_number, ''));
  
  -- Validate text lengths
  IF LENGTH(NEW.name) = 0 THEN
    RAISE EXCEPTION 'Civciv adı boş olamaz';
  END IF;
  
  IF LENGTH(NEW.health_notes) > 1000 THEN
    NEW.health_notes = LEFT(NEW.health_notes, 1000);
  END IF;
  
  -- Ensure incubation_id exists and belongs to the same user
  IF NOT EXISTS (
    SELECT 1 FROM public.incubations 
    WHERE id = NEW.incubation_id AND user_id = NEW.user_id
  ) THEN
    RAISE EXCEPTION 'Geçersiz incubation_id veya yetki hatası: %', NEW.incubation_id;
  END IF;
  
  RETURN NEW;
END;
$function$;

-- Add rate limiting table for security monitoring
CREATE TABLE IF NOT EXISTS public.security_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  event_type text NOT NULL,
  ip_address inet,
  user_agent text,
  metadata jsonb,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS on security events
ALTER TABLE public.security_events ENABLE ROW LEVEL SECURITY;

-- Only admins can view security events
CREATE POLICY "Admins can view security events" 
ON public.security_events 
FOR SELECT 
USING (false); -- Will be updated when admin roles are implemented

-- Users can create their own security events
CREATE POLICY "Users can create security events" 
ON public.security_events 
FOR INSERT 
WITH CHECK (user_id = auth.uid());