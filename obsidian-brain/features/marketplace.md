# Feature: marketplace

**Purpose**: Peer-to-peer bird listings — sellers create listings,
buyers browse + filter + message. Public read, auth write — listings are
cross-user content, so they live online-only.

## Key Screens

| Screen | Route |
|--------|-------|
| `MarketplaceScreen` | `AppRoutes.marketplace` — feed + filters |
| `MarketplaceDetailScreen` | `AppRoutes.marketplaceDetail` (`/marketplace/:id`) |
| `MarketplaceFormScreen` | `AppRoutes.marketplaceForm` — create / edit |
| `MarketplaceMyListingsScreen` | `AppRoutes.marketplaceMyListings` |
| `MarketplaceFavoritesScreen` | bookmarks (private to user) |
| `MarketplaceSellerListingsScreen` | other seller's profile listings |

## Online-First by Design

`marketplace_listing_remote_source.dart` follows the `*RemoteSource`
naming (NOT `*Repository`) — listings are cross-user content where local
mirror would not help UX (see [[architecture/online-first-exemption]]).

| Surface | Read | Write |
|---------|------|-------|
| Listings table | Public (RLS allows any auth user) | Owner-only |
| Photos bucket | Public CDN | Auth write, owner update |

## Photo Pipeline

Listing photos go through the full upload pipeline:

1. `ImagePicker` → file
2. 10 MB guard
3. Compress → 1920px JPEG q85
4. `scan-image-safety` Edge Function (fail-closed — App Store policy)
5. Upload to `marketplace-listings` Supabase Storage bucket

Multi-photo listings reorder via drag, primary photo first.

## Filters

Filterable by species, gender, price range, location radius (if user
opts in to location), free-text search. Filter state is ephemeral
(not persisted across launches) to avoid stale "saved searches" surprise.

## Messaging Bridge

"Contact seller" CTA opens a DM thread via [[features/messaging]]
`new_dm_screen.dart` pre-filled with the listing reference. Message
copy includes a deeplink card to the listing.

## Verification Badge

Listings from `verified_breeder` users (see [[domain/gamification-service]])
render a checkmark. Verification is server-side authoritative.

## Premium

Premium users get bumps (higher list position) and extended listing
duration. Free users limited by `validate-free-tier-limit` Edge Function.

## Rules

- `.claude/rules/assets-images.md` — photo upload pipeline
- `.claude/rules/security.md` — RLS policies, public vs private buckets
- `.claude/rules/edge-functions.md` — `scan-image-safety`,
  `validate-free-tier-limit`

## See Also

- [[features/messaging]] — contact seller DM
- [[features/community]] — sister online-first feature
- [[domain/moderation-service]] — text + image moderation
- [[architecture/online-first-exemption]]
- [[features/_features-index]]
