
-- community_follows: tracks user follow relationships
CREATE TABLE IF NOT EXISTS public.community_follows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  CONSTRAINT community_follows_no_self_follow CHECK (follower_id != following_id),
  CONSTRAINT community_follows_unique_pair UNIQUE (follower_id, following_id)
);

-- community_reports: tracks user reports on posts/comments
CREATE TABLE IF NOT EXISTS public.community_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  target_id uuid NOT NULL,
  target_type text NOT NULL,
  reason text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.community_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_reports ENABLE ROW LEVEL SECURITY;

-- RLS policies for community_follows
CREATE POLICY "Users can view their own follows"
  ON public.community_follows FOR SELECT
  USING (auth.uid() = follower_id OR auth.uid() = following_id);

CREATE POLICY "Users can follow others"
  ON public.community_follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow"
  ON public.community_follows FOR DELETE
  USING (auth.uid() = follower_id);

-- RLS policies for community_reports
CREATE POLICY "Users can view their own reports"
  ON public.community_reports FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create reports"
  ON public.community_reports FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_community_follows_follower
  ON public.community_follows (follower_id);

CREATE INDEX IF NOT EXISTS idx_community_follows_following
  ON public.community_follows (following_id);

CREATE INDEX IF NOT EXISTS idx_community_reports_user
  ON public.community_reports (user_id);

CREATE INDEX IF NOT EXISTS idx_community_reports_target
  ON public.community_reports (target_id, target_type);
;
