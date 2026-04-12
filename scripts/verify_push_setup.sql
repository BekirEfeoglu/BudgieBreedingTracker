select
  user_id,
  platform,
  is_active,
  device_id,
  created_at,
  updated_at,
  left(token, 16) || '...' as token_preview
from public.fcm_tokens
order by updated_at desc;
