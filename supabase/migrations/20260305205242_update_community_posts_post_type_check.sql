
ALTER TABLE community_posts DROP CONSTRAINT community_posts_post_type_check;
ALTER TABLE community_posts ADD CONSTRAINT community_posts_post_type_check
  CHECK (post_type = ANY (ARRAY['text', 'photo', 'poll', 'question', 'tip', 'achievement', 'guide', 'showcase', 'general']));
;
