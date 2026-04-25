-- Convert marketplace_listings.price from DOUBLE PRECISION to NUMERIC(10,2).
-- Rationale: Postgres best-practices rule 4.1 — money uses exact decimal
-- arithmetic; floating-point rounding (0.1 + 0.2 != 0.3) can create
-- buyer/seller mismatches on listing prices. NUMERIC(10,2) supports up to
-- 99,999,999.99 which comfortably covers rare-color budgie prices.

-- Pre-check: fail fast if any existing row exceeds NUMERIC(10,2) range.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM marketplace_listings WHERE price > 99999999.99
  ) THEN
    RAISE EXCEPTION
      'Cannot convert price to NUMERIC(10,2): rows exceed 99,999,999.99';
  END IF;
END $$;

-- Explicit ROUND avoids surprises from floating-point representation
-- artefacts (e.g. 199.9900000000001 stored as double).
ALTER TABLE marketplace_listings
  ALTER COLUMN price TYPE NUMERIC(10, 2)
  USING ROUND(price::numeric, 2);
