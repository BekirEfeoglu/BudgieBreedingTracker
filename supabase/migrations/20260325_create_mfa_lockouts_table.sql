-- MFA lockout tracking table for server-side brute-force protection.
-- Stores failed 2FA attempt counts and lockout timestamps per user.

create table if not exists public.mfa_lockouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  failed_attempts integer not null default 0,
  locked_until timestamptz,
  last_attempt_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint mfa_lockouts_user_id_key unique (user_id)
);

-- Enable RLS
alter table public.mfa_lockouts enable row level security;

-- Users can read their own lockout row
create policy "Users can read own mfa_lockout"
  on public.mfa_lockouts for select
  using (auth.uid() = user_id);

-- Users can update their own lockout row
create policy "Users can update own mfa_lockout"
  on public.mfa_lockouts for update
  using (auth.uid() = user_id);

-- Users can insert their own lockout row
create policy "Users can insert own mfa_lockout"
  on public.mfa_lockouts for insert
  with check (auth.uid() = user_id);

-- Index for fast lookups by user_id
create index if not exists idx_mfa_lockouts_user_id
  on public.mfa_lockouts(user_id);
