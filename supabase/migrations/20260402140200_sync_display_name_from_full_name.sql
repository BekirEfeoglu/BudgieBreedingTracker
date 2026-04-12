-- Sync display_name from full_name for existing profiles where display_name is NULL.
-- This fixes community posts showing "Anonim Kullanıcı" because the profile cache
-- reads display_name but auth sync only populates full_name.

UPDATE profiles
SET display_name = full_name
WHERE display_name IS NULL
  AND full_name IS NOT NULL
  AND full_name <> '';

-- Also keep display_name in sync going forward via a trigger.
CREATE OR REPLACE FUNCTION sync_display_name_from_full_name()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.full_name IS NOT NULL AND NEW.full_name <> '' AND NEW.display_name IS NULL THEN
    NEW.display_name := NEW.full_name;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_display_name ON profiles;
CREATE TRIGGER trg_sync_display_name
  BEFORE INSERT OR UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION sync_display_name_from_full_name();
