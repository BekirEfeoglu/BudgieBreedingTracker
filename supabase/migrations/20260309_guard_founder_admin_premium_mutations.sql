-- Prevent premium flag mutations for protected roles (founder/admin).
-- This is a DB-level guard and applies even when requests bypass app UI logic.

create or replace function public.guard_protected_role_premium_mutation()
returns trigger
language plpgsql
as $$
begin
  if old.role in ('founder', 'admin')
     and (
       new.is_premium is distinct from old.is_premium
       or coalesce(new.subscription_status, '') is distinct from coalesce(old.subscription_status, '')
     ) then
    raise exception using
      errcode = 'P0001',
      message = 'protected_role_premium_mutation',
      detail = 'Cannot change premium fields for founder/admin users';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_guard_protected_role_premium_mutation on public.profiles;

create trigger trg_guard_protected_role_premium_mutation
before update on public.profiles
for each row
execute function public.guard_protected_role_premium_mutation();
