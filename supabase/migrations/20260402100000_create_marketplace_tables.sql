-- Marketplace Listings table
CREATE TABLE IF NOT EXISTS marketplace_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  listing_type TEXT NOT NULL DEFAULT 'sale'
    CHECK (listing_type IN ('sale', 'adoption', 'trade', 'wanted')),
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price DOUBLE PRECISION,
  currency TEXT NOT NULL DEFAULT 'TRY',
  bird_id UUID,
  species TEXT NOT NULL DEFAULT '',
  mutation TEXT,
  gender TEXT NOT NULL DEFAULT 'unknown',
  age TEXT,
  image_urls JSONB NOT NULL DEFAULT '[]'::jsonb,
  city TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'sold', 'reserved', 'closed')),
  view_count INTEGER NOT NULL DEFAULT 0,
  message_count INTEGER NOT NULL DEFAULT 0,
  is_verified_breeder BOOLEAN NOT NULL DEFAULT false,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  needs_review BOOLEAN NOT NULL DEFAULT false,
  reviewed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_user_id ON marketplace_listings(user_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_city ON marketplace_listings(city);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_listing_type ON marketplace_listings(listing_type);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_status ON marketplace_listings(status);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_created_at ON marketplace_listings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_needs_review ON marketplace_listings(needs_review) WHERE needs_review = true;

-- Full-text search with tRGM (requires pg_trgm extension)
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_title_trgm ON marketplace_listings USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_desc_trgm ON marketplace_listings USING gin (description gin_trgm_ops);

-- RLS
ALTER TABLE marketplace_listings ENABLE ROW LEVEL SECURITY;

-- Public read for active, non-deleted listings
CREATE POLICY "marketplace_listings_public_read" ON marketplace_listings
  FOR SELECT USING (
    (status = 'active' AND is_deleted = false AND needs_review = false)
    OR user_id = auth.uid()
  );

-- Users manage own listings
CREATE POLICY "marketplace_listings_insert" ON marketplace_listings
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "marketplace_listings_update" ON marketplace_listings
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "marketplace_listings_delete" ON marketplace_listings
  FOR DELETE USING (user_id = auth.uid());

-- Marketplace Favorites table
CREATE TABLE IF NOT EXISTS marketplace_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  listing_id UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, listing_id)
);

CREATE INDEX IF NOT EXISTS idx_marketplace_favorites_user_id ON marketplace_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_favorites_listing_id ON marketplace_favorites(listing_id);

-- RLS
ALTER TABLE marketplace_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "marketplace_favorites_own_read" ON marketplace_favorites
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "marketplace_favorites_own_insert" ON marketplace_favorites
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "marketplace_favorites_own_delete" ON marketplace_favorites
  FOR DELETE USING (user_id = auth.uid());

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_marketplace_listings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER marketplace_listings_updated_at
  BEFORE UPDATE ON marketplace_listings
  FOR EACH ROW
  EXECUTE FUNCTION update_marketplace_listings_updated_at();
