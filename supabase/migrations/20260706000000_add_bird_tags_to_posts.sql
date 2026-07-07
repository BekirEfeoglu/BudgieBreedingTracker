-- Add bird link and mutation tags to community posts
ALTER TABLE public.community_posts
ADD COLUMN IF NOT EXISTS bird_id UUID REFERENCES public.birds(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS bird_name TEXT,
ADD COLUMN IF NOT EXISTS mutation_tags TEXT[];

-- Add an index for bird_id
CREATE INDEX IF NOT EXISTS idx_community_posts_bird_id ON public.community_posts(bird_id) WHERE bird_id IS NOT NULL;
