-- Badges definition table (admin-seeded)
CREATE TABLE IF NOT EXISTS badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL DEFAULT 'milestone'
    CHECK (category IN ('breeding', 'community', 'marketplace', 'health', 'milestone', 'special')),
  tier TEXT NOT NULL DEFAULT 'bronze'
    CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  name_key TEXT NOT NULL DEFAULT '',
  description_key TEXT NOT NULL DEFAULT '',
  icon_path TEXT NOT NULL DEFAULT '',
  xp_reward INTEGER NOT NULL DEFAULT 0,
  requirement INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_badges_category ON badges(category);
CREATE INDEX IF NOT EXISTS idx_badges_tier ON badges(tier);
CREATE INDEX IF NOT EXISTS idx_badges_sort_order ON badges(sort_order);

ALTER TABLE badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "badges_public_read" ON badges
  FOR SELECT USING (true);

-- User badges (progress + unlock tracking)
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  badge_key TEXT NOT NULL DEFAULT '',
  progress INTEGER NOT NULL DEFAULT 0,
  is_unlocked BOOLEAN NOT NULL DEFAULT false,
  unlocked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON user_badges(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_badge_id ON user_badges(badge_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_is_unlocked ON user_badges(is_unlocked) WHERE is_unlocked = true;

ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_badges_public_read" ON user_badges
  FOR SELECT USING (true);

CREATE POLICY "user_badges_own_insert" ON user_badges
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_badges_own_update" ON user_badges
  FOR UPDATE USING (user_id = auth.uid());

-- User levels (XP + level tracking)
CREATE TABLE IF NOT EXISTS user_levels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  total_xp INTEGER NOT NULL DEFAULT 0,
  level INTEGER NOT NULL DEFAULT 1,
  current_level_xp INTEGER NOT NULL DEFAULT 0,
  next_level_xp INTEGER NOT NULL DEFAULT 100,
  title TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_levels_user_id ON user_levels(user_id);
CREATE INDEX IF NOT EXISTS idx_user_levels_total_xp ON user_levels(total_xp DESC);

ALTER TABLE user_levels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_levels_public_read" ON user_levels
  FOR SELECT USING (true);

CREATE POLICY "user_levels_own_insert" ON user_levels
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_levels_own_update" ON user_levels
  FOR UPDATE USING (user_id = auth.uid());

-- XP transactions (history)
CREATE TABLE IF NOT EXISTS xp_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL DEFAULT 'unknown',
  amount INTEGER NOT NULL DEFAULT 0,
  reference_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_xp_transactions_user_id ON xp_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_transactions_created_at ON xp_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_xp_transactions_action ON xp_transactions(action);
CREATE INDEX IF NOT EXISTS idx_xp_transactions_user_action_date ON xp_transactions(user_id, action, created_at);

ALTER TABLE xp_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "xp_transactions_own_read" ON xp_transactions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "xp_transactions_own_insert" ON xp_transactions
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Add is_verified_breeder, level, xp_title to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS is_verified_breeder BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS level INTEGER NOT NULL DEFAULT 1;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS xp_title TEXT NOT NULL DEFAULT '';

-- Seed badge definitions (16 badges including verified_breeder)
INSERT INTO badges (id, key, category, tier, name_key, description_key, icon_path, xp_reward, requirement, sort_order)
VALUES
  (gen_random_uuid(), 'first_bird', 'milestone', 'bronze', 'badges.first_bird', 'badges.first_bird_desc', 'assets/icons/badges/first_bird.svg', 20, 1, 1),
  (gen_random_uuid(), 'bird_lover_10', 'breeding', 'bronze', 'badges.bird_lover_10', 'badges.bird_lover_10_desc', 'assets/icons/badges/bird_lover.svg', 30, 10, 2),
  (gen_random_uuid(), 'bird_paradise_50', 'breeding', 'gold', 'badges.bird_paradise_50', 'badges.bird_paradise_50_desc', 'assets/icons/badges/bird_paradise.svg', 100, 50, 3),
  (gen_random_uuid(), 'first_breeding', 'breeding', 'bronze', 'badges.first_breeding', 'badges.first_breeding_desc', 'assets/icons/badges/first_breeding.svg', 20, 1, 4),
  (gen_random_uuid(), 'breeder_10', 'breeding', 'silver', 'badges.breeder_10', 'badges.breeder_10_desc', 'assets/icons/badges/breeder.svg', 50, 10, 5),
  (gen_random_uuid(), 'breeder_50', 'breeding', 'gold', 'badges.breeder_50', 'badges.breeder_50_desc', 'assets/icons/badges/breeder_master.svg', 100, 50, 6),
  (gen_random_uuid(), 'first_chick', 'breeding', 'bronze', 'badges.first_chick', 'badges.first_chick_desc', 'assets/icons/badges/first_chick.svg', 20, 1, 7),
  (gen_random_uuid(), 'chick_100', 'breeding', 'platinum', 'badges.chick_100', 'badges.chick_100_desc', 'assets/icons/badges/chick_master.svg', 200, 100, 8),
  (gen_random_uuid(), 'social_butterfly_50', 'community', 'silver', 'badges.social_butterfly_50', 'badges.social_butterfly_50_desc', 'assets/icons/badges/social.svg', 50, 50, 9),
  (gen_random_uuid(), 'commenter_100', 'community', 'silver', 'badges.commenter_100', 'badges.commenter_100_desc', 'assets/icons/badges/commenter.svg', 50, 100, 10),
  (gen_random_uuid(), 'market_pro_20', 'marketplace', 'silver', 'badges.market_pro_20', 'badges.market_pro_20_desc', 'assets/icons/badges/market_pro.svg', 50, 20, 11),
  (gen_random_uuid(), 'health_tracker_50', 'health', 'silver', 'badges.health_tracker_50', 'badges.health_tracker_50_desc', 'assets/icons/badges/health.svg', 50, 50, 12),
  (gen_random_uuid(), 'genetics_expert_100', 'milestone', 'gold', 'badges.genetics_expert_100', 'badges.genetics_expert_100_desc', 'assets/icons/badges/genetics.svg', 100, 100, 13),
  (gen_random_uuid(), 'one_year', 'milestone', 'gold', 'badges.one_year', 'badges.one_year_desc', 'assets/icons/badges/one_year.svg', 150, 365, 14),
  (gen_random_uuid(), 'five_years', 'milestone', 'platinum', 'badges.five_years', 'badges.five_years_desc', 'assets/icons/badges/five_years.svg', 300, 1825, 15),
  (gen_random_uuid(), 'verified_breeder', 'special', 'platinum', 'badges.verified_breeder', 'badges.verified_breeder_desc', 'assets/icons/badges/verified.svg', 500, 1, 16)
ON CONFLICT (key) DO NOTHING;
