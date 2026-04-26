alter table public.feedback
  add column if not exists category text not null default 'general',
  add column if not exists assigned_admin_id uuid references auth.users(id) on delete set null,
  add column if not exists internal_note text;

create index if not exists feedback_category_idx
  on public.feedback(category);

create index if not exists feedback_assigned_admin_id_idx
  on public.feedback(assigned_admin_id)
  where assigned_admin_id is not null;
