-- Add needs_review column to community_posts and community_comments tables.
-- Posts/comments flagged when server-side moderation was unavailable.
ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS needs_review BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE community_comments
  ADD COLUMN IF NOT EXISTS needs_review BOOLEAN NOT NULL DEFAULT FALSE;

-- Index for admin queries filtering pending review content.
CREATE INDEX IF NOT EXISTS idx_community_posts_needs_review
  ON community_posts (needs_review) WHERE needs_review = TRUE;

CREATE INDEX IF NOT EXISTS idx_community_comments_needs_review
  ON community_comments (needs_review) WHERE needs_review = TRUE;;
