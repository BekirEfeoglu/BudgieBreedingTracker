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

`MarketplaceFormScreen` gender `ChoiceChip` avatars use domain SVG icons
(`AppIcon(AppIcons.male / .female)`, unknown falls back to a generic
`LucideIcons.helpCircle`) — domain concepts must not use `LucideIcons`
(anti-pattern #24).

## Messaging Bridge

"Contact seller" CTA opens a DM thread via [[features/messaging]]
`new_dm_screen.dart` pre-filled with the listing reference. Message
copy includes a deeplink card to the listing.

## Verification Badge

Listings from `verified_breeder` users (see [[domain/gamification-service]])
render a checkmark. **Fixed 2026-07-02** (same day as discovery): the
`profiles` UPDATE RLS policy never pinned `is_verified_breeder`/`level`/
`xp_title`, and — a broader problem found while fixing it —
`xp_transactions`/`user_levels`/`user_badges` had no `WITH CHECK` at all,
so a user could directly overwrite their own level/XP/badge-unlock state
regardless of what `profiles` itself allowed. A naive RLS lock-down on just
`profiles` would have been security theater (still bypassable via
`user_levels`), and simply requiring "unchanged" would have broken the
app's own legitimate write path (`GamificationService` writes level/XP via
a normal authenticated client call, not a service-role RPC — there was no
RPC to redirect to).

Fix: new `private.xp_action_amount()`/`private.xp_calculate_level()`/
`private.xp_title_for_level()`/`private.meets_verified_breeder_criteria()`
SQL functions mirror the Dart `XpConstants`/`LevelCalculator`/
`GamificationService` logic exactly, and `WITH CHECK` clauses on all four
tables validate client-supplied values against them instead of trusting
them — writes stay client-initiated (no RPC migration needed) but are now
server-validated. Migrations: `20260702175125_gamification_server_side_helpers.sql`,
`20260702175232_gamification_lock_down_self_grant.sql`. Verified live via
a rolled-back transaction simulating a non-admin authenticated user: direct
`is_verified_breeder`/level self-grant, arbitrary XP amount, arbitrary
`user_levels` overwrite (both on an existing row and fabricating a fresh
one), and `verified_breeder` badge self-unlock were all rejected; the
legitimate self-service insert/update path (consistent values) still
succeeded. See `.claude/rules/gamification.md` § Server-Side Write
Enforcement for the full constraint list and the one remaining known gap
(daily XP cooldown is still client-only — a `WITH CHECK` can't do
aggregate/count validation per row).

## Premium

Premium users get bumps (higher list position) and extended listing
duration. Free users limited by `validate-free-tier-limit` Edge Function —
**this was a real gap until 2026-07-02**: `createListing()` never actually
called the Edge Function (a comment claimed it did) and
`FreeTierLimitService`'s `_validTables` didn't include
`marketplace_listings`, so only the client-side `canCreateListingProvider`
count check gated listing creation — trivially bypassed by calling the
repository directly. Now fixed: `guardMarketplaceListingLimit()` calls the
Edge Function before `repo.create()`.

## Rules

- `.claude/rules/marketplace.md` — listing lifecycle, strict moderation threshold, premium gates, ad placement (entitlement aware), contact flow, RLS, location privacy
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
