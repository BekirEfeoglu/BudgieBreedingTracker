# Features Index

24 feature modules in `lib/features/`. Each has `screens/`, `widgets/`, `providers/`.

| Module | Purpose |
|--------|---------|
| [[features/admin]] | Admin dashboard, system management |
| [[features/app_update]] | In-app update prompting |
| [[features/auth]] | Login, register, MFA, OAuth |
| [[features/birds]] | Bird CRUD, profile, gallery |
| [[features/breeding]] | Breeding pairs, incubation management |
| [[features/calendar]] | Event calendar view |
| [[features/chicks]] | Chick tracking and growth |
| [[features/community]] | Community posts and feed |
| [[features/eggs]] | Egg tracking, status transitions |
| [[features/feedback]] | In-app feedback submission |
| [[features/gamification]] | Badges, leaderboard, achievements |
| [[features/genealogy]] | Family tree visualization |
| [[features/genetics]] | Punnett square, mutation calculator |
| [[features/health_records]] | Vet notes, health events |
| [[features/home]] | Dashboard home screen |
| [[features/marketplace]] | Bird listings, buy/sell |
| [[features/messaging]] | Direct messages between users |
| [[features/more]] | Secondary nav hub |
| [[features/notifications]] | Notification settings |
| [[features/premium]] | Subscription management, upsell |
| [[features/profile]] | User profile editing |
| [[features/settings]] | App settings |
| [[features/splash]] | Splash screen, deep link handling |
| [[features/statistics]] | Breeding stats and charts |

## Entity Lifecycle (cross-feature)

```
Bird → BreedingPair → Incubation → Clutch → Egg → Chick
```

The `breeding` and `eggs` features own this chain. Rule: `.claude/rules/breeding-eggs.md`

## Navigation

73 routes defined in `lib/router/`. Route guards: `AdminGuard`, `PremiumGuard`.
See [[patterns/ui-patterns]] § GoRouter.
