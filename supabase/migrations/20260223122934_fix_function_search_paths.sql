
-- Fix mutable search_path on 5 SECURITY DEFINER functions
ALTER FUNCTION public.admin_reset_all_user_data() SET search_path = '';
ALTER FUNCTION public.admin_reset_table(text) SET search_path = '';
ALTER FUNCTION public.get_server_capacity() SET search_path = '';
ALTER FUNCTION public.handle_new_user() SET search_path = '';
ALTER FUNCTION public.set_admin_log_ip() SET search_path = '';
;
