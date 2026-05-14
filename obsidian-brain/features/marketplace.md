# Feature: marketplace

**Purpose**: Bird listing marketplace — buy, sell, and browse birds.

## Key Screens

- Listing feed (filterable)
- Listing detail
- Create/edit listing
- My listings

## Data

- `marketplace_listing_remote_source.dart` — correctly named `*RemoteSource` (not Repository)
- Listings stored in Supabase (public read, auth write)
- Photos in `marketplace-listings` bucket (public CDN)

## Key Providers

- Listing feed provider (online-first, paginated)
- My listings provider

## Messaging Integration

Users message sellers via [[features/messaging]] DM flow.

## Rules

- `.claude/rules/assets-images.md` — listing photo upload (10MB guard, scan-image-safety)
- `.claude/rules/security.md` — RLS on marketplace tables

## See Also

- [[features/messaging]]
- [[features/_features-index]]
