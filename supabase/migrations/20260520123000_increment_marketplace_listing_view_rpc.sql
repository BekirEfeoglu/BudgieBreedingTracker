-- Atomic view-count increment for marketplace listings.
--
-- Replaces the client-side select-then-update pattern which lost
-- concurrent views: N viewers reading view_count=10 within the same
-- read window would each compute newCount=11 and write 11, dropping
-- N-1 increments.
--
-- This SQL function runs as a single UPDATE statement so concurrent
-- transactions each contribute their own increment.

CREATE OR REPLACE FUNCTION public.increment_marketplace_listing_view(
  p_id uuid
)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE public.marketplace_listings
  SET view_count = COALESCE(view_count, 0) + 1
  WHERE id = p_id;
$$;

-- Allow authenticated clients to call this. View counts are a public
-- attribute of marketplace listings; the function does not expose any
-- private fields and is constrained to incrementing a single column.
GRANT EXECUTE ON FUNCTION public.increment_marketplace_listing_view(uuid)
  TO authenticated;

COMMENT ON FUNCTION public.increment_marketplace_listing_view(uuid) IS
  'Atomic +1 on marketplace_listings.view_count. Used by the client to '
  'avoid the lost-update race in select-then-update view counters.';
