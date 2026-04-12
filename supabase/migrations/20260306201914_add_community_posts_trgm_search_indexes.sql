-- Enable pg_trgm extension for trigram-based similarity search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- GIN indexes for fast ILIKE/similarity search on community_posts
-- These indexes accelerate the existing .or('content.ilike.%query%,title.ilike.%query%') pattern
CREATE INDEX IF NOT EXISTS idx_community_posts_content_trgm
  ON public.community_posts USING gin (content gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_community_posts_title_trgm
  ON public.community_posts USING gin (title gin_trgm_ops);
;
