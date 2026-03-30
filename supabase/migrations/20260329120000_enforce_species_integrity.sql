-- Enforce bird parent and breeding pair integrity at the database level.
-- These guards apply even if a client bypasses application validation.

create or replace function public.validate_bird_parent_integrity()
returns trigger
language plpgsql
as $$
declare
  father_record public.birds%rowtype;
  mother_record public.birds%rowtype;
begin
  if new.father_id is not null then
    if new.father_id = new.id then
      raise exception using
        errcode = 'P0001',
        message = 'bird_parent_self_reference',
        detail = 'A bird cannot reference itself as father';
    end if;

    select *
    into father_record
    from public.birds
    where id = new.father_id;

    if not found then
      raise exception using
        errcode = 'P0001',
        message = 'bird_father_not_found',
        detail = 'Referenced father bird does not exist';
    end if;

    if father_record.gender <> 'male' then
      raise exception using
        errcode = 'P0001',
        message = 'bird_invalid_father_gender',
        detail = 'Father must be a male bird';
    end if;

    if father_record.species <> new.species then
      raise exception using
        errcode = 'P0001',
        message = 'bird_parent_species_mismatch',
        detail = 'Father species must match child species';
    end if;
  end if;

  if new.mother_id is not null then
    if new.mother_id = new.id then
      raise exception using
        errcode = 'P0001',
        message = 'bird_parent_self_reference',
        detail = 'A bird cannot reference itself as mother';
    end if;

    select *
    into mother_record
    from public.birds
    where id = new.mother_id;

    if not found then
      raise exception using
        errcode = 'P0001',
        message = 'bird_mother_not_found',
        detail = 'Referenced mother bird does not exist';
    end if;

    if mother_record.gender <> 'female' then
      raise exception using
        errcode = 'P0001',
        message = 'bird_invalid_mother_gender',
        detail = 'Mother must be a female bird';
    end if;

    if mother_record.species <> new.species then
      raise exception using
        errcode = 'P0001',
        message = 'bird_parent_species_mismatch',
        detail = 'Mother species must match child species';
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_bird_parent_integrity on public.birds;

create trigger trg_validate_bird_parent_integrity
before insert or update on public.birds
for each row
execute function public.validate_bird_parent_integrity();

create or replace function public.validate_breeding_pair_integrity()
returns trigger
language plpgsql
as $$
declare
  male_record public.birds%rowtype;
  female_record public.birds%rowtype;
begin
  if new.male_id is not null then
    select *
    into male_record
    from public.birds
    where id = new.male_id;

    if not found then
      raise exception using
        errcode = 'P0001',
        message = 'breeding_pair_male_not_found',
        detail = 'Referenced male bird does not exist';
    end if;

    if male_record.gender <> 'male' then
      raise exception using
        errcode = 'P0001',
        message = 'breeding_pair_invalid_male_gender',
        detail = 'Male breeding pair bird must be male';
    end if;
  end if;

  if new.female_id is not null then
    select *
    into female_record
    from public.birds
    where id = new.female_id;

    if not found then
      raise exception using
        errcode = 'P0001',
        message = 'breeding_pair_female_not_found',
        detail = 'Referenced female bird does not exist';
    end if;

    if female_record.gender <> 'female' then
      raise exception using
        errcode = 'P0001',
        message = 'breeding_pair_invalid_female_gender',
        detail = 'Female breeding pair bird must be female';
    end if;
  end if;

  if new.male_id is not null
     and new.female_id is not null
     and male_record.species <> female_record.species then
    raise exception using
      errcode = 'P0001',
      message = 'breeding_pair_species_mismatch',
      detail = 'Breeding pair birds must share the same species';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_validate_breeding_pair_integrity on public.breeding_pairs;

create trigger trg_validate_breeding_pair_integrity
before insert or update on public.breeding_pairs
for each row
execute function public.validate_breeding_pair_integrity();
