-- Fix RLS performance issues by optimizing auth.uid() calls
-- Replace direct auth.uid() calls with (select auth.uid()) for better performance

-- 1. Fix user_notification_tokens table RLS policy
DROP POLICY IF EXISTS "Users can manage their own notification tokens" ON public.user_notification_tokens;

CREATE POLICY "Users can manage their own notification tokens" 
ON public.user_notification_tokens 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 2. Fix user_notification_settings table RLS policy  
DROP POLICY IF EXISTS "Users can manage their own notification settings" ON public.user_notification_settings;

CREATE POLICY "Users can manage their own notification settings" 
ON public.user_notification_settings 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);

-- 3. Fix notification_interactions table RLS policy
DROP POLICY IF EXISTS "Users can manage their own notification interactions" ON public.notification_interactions;

CREATE POLICY "Users can manage their own notification interactions" 
ON public.notification_interactions 
FOR ALL 
USING ((SELECT auth.uid()) = user_id);