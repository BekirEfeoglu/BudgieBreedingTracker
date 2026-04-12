-- Fix missing SET search_path on trigger functions from enforce_species_integrity migration.
-- Also restrict verify_rls_profiles_update_guards to service_role only.

-- Fix validate_bird_parent_integrity: add SET search_path = ''
CREATE OR REPLACE FUNCTION public.validate_bird_parent_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  father_record public.birds%ROWTYPE;
  mother_record public.birds%ROWTYPE;
BEGIN
  IF NEW.father_id IS NOT NULL THEN
    IF NEW.father_id = NEW.id THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'bird_parent_self_reference',
        detail = 'A bird cannot reference itself as father';
    END IF;

    SELECT *
    INTO father_record
    FROM public.birds
    WHERE id = NEW.father_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'bird_father_not_found',
        detail = 'Referenced father bird does not exist';
    END IF;

    IF father_record.gender <> 'male' THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'bird_invalid_father_gender',
        detail = 'Father must be a male bird';
    END IF;

    IF father_record.species <> NEW.species THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'bird_parent_species_mismatch',
        detail = 'Father species must match child species';
    END IF;
  END IF;

  IF NEW.mother_id IS NOT NULL THEN
    IF NEW.mother_id = NEW.id THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'bird_parent_self_reference',
        detail = 'A bird cannot reference itself as mother';
    END IF;

    SELECT *
    INTO mother_record
    FROM public.birds
    WHERE id = NEW.mother_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'bird_mother_not_found',
        detail = 'Referenced mother bird does not exist';
    END IF;

    IF mother_record.gender <> 'female' THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'bird_invalid_mother_gender',
        detail = 'Mother must be a female bird';
    END IF;

    IF mother_record.species <> NEW.species THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'bird_parent_species_mismatch',
        detail = 'Mother species must match child species';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Fix validate_breeding_pair_integrity: add SET search_path = ''
CREATE OR REPLACE FUNCTION public.validate_breeding_pair_integrity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  male_record public.birds%ROWTYPE;
  female_record public.birds%ROWTYPE;
BEGIN
  IF NEW.male_id IS NOT NULL THEN
    SELECT *
    INTO male_record
    FROM public.birds
    WHERE id = NEW.male_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'breeding_pair_male_not_found',
        detail = 'Referenced male bird does not exist';
    END IF;

    IF male_record.gender <> 'male' THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'breeding_pair_invalid_male_gender',
        detail = 'Male breeding pair bird must be male';
    END IF;
  END IF;

  IF NEW.female_id IS NOT NULL THEN
    SELECT *
    INTO female_record
    FROM public.birds
    WHERE id = NEW.female_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'breeding_pair_female_not_found',
        detail = 'Referenced female bird does not exist';
    END IF;

    IF female_record.gender <> 'female' THEN
      RAISE EXCEPTION USING
        errcode = 'P0001',
        message = 'breeding_pair_invalid_female_gender',
        detail = 'Female breeding pair bird must be female';
    END IF;
  END IF;

  IF NEW.male_id IS NOT NULL
     AND NEW.female_id IS NOT NULL
     AND male_record.species <> female_record.species THEN
    RAISE EXCEPTION USING
      errcode = 'P0001',
      message = 'breeding_pair_species_mismatch',
      detail = 'Breeding pair birds must share the same species';
  END IF;

  RETURN NEW;
END;
$$;

-- Restrict verify_rls_profiles_update_guards to service_role only (not for production use)
REVOKE EXECUTE ON FUNCTION public.verify_rls_profiles_update_guards() FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.verify_rls_profiles_update_guards() FROM anon;
