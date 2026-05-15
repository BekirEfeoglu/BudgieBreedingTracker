# Feature: gamification

**Purpose**: Achievements, badges, leaderboard to encourage breeding record-keeping.

## Key Screens

- Badge collection
- Leaderboard (community-wide)
- Achievement unlock celebration

## Key Providers

- `badgesProvider` — earned and locked badges
- `leaderboardProvider` — online-first ranking

## Statistics Synergy

- Statistics personal records expose milestone candidates: best season, top pair, and longest-lived bird.
- Badge triggering is not wired yet; future gamification work can consume `personalRecordsProvider(userId)` instead of recalculating the same aggregates.

## See Also

- [[features/statistics]]
- [[features/community]]
- [[features/_features-index]]
