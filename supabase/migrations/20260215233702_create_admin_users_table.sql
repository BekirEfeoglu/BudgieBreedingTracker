
-- Admin users table
CREATE TABLE admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'founder')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);

-- Index for fast lookup
CREATE INDEX idx_admin_users_user_id ON admin_users(user_id);

-- RLS
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- Only admins/founders can read admin_users
CREATE POLICY "Admin users can read admin list"
  ON admin_users FOR SELECT
  USING (
    auth.uid() IN (SELECT user_id FROM admin_users)
  );

-- Insert founder
INSERT INTO admin_users (user_id, role)
VALUES ('141aa2f1-2db4-4fb0-a381-b4e14e65063b', 'founder');
;
