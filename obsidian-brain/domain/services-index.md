# Domain Services Index

22 service directories in `lib/domain/services/` (ads, app_update, auth, backup, breeding, calendar, eggs, encryption, export, gamification, genetics, home_widget, import, incubation, local_ai, moderation, notifications, payment, premium, presence, profile, sync).

| Service | Page | Purpose | Network Required |
|---------|------|---------|------------------|
| Auth | [[domain/auth-service]] | Login, session refresh, MFA | Yes |
| Calendar | [[domain/calendar-service]] | Event scheduling, auto-milestones | No |
| Data I/O | [[domain/data-io]] | JSON backup (+AES), Excel I/O, PDF export | Partial |
| Eggs | [[domain/eggs-service]] | Egg actions notifier, chick auto-create | No |
| Encryption | [[domain/encryption-service]] | AES-256-CBC + HMAC, key rotation | No |
| Gamification | [[domain/gamification-service]] | XP, levels, badges, verified breeder | Yes |
| Genetics | [[domain/genetics-engine]] | Punnett, MUTAVI, inbreeding | No |
| Home Widget | [[domain/home-widget-service]] | iOS/Android home + lock-screen widget | No |
| Incubation | [[domain/incubation-service]] | Day math, milestones, environment monitor | No |
| Local AI | [[domain/local-ai]] | LLM image + text analysis | Yes (always) |
| Moderation | [[domain/moderation-service]] | Text + image safety (fail-closed) | Yes |
| Notifications | [[domain/notification-service]] | FCM + local + channels | Partial |
| Premium / Payment | [[domain/premium-service]] | RevenueCat + entitlement + grace | Yes |
| Presence | [[domain/presence-service]] | Online status, heartbeat sessions | Yes |
| Sync | [[domain/sync-service]] | Background sync orchestration | Yes (online trigger) |
| Breeding / IncubationRiskAssistant | (see [[features/breeding]]) | Derived risk summary | No |
| Profile | (see [[features/profile]]) | Account orchestration, storage cleanup | Yes |
| Ads | (see [[domain/premium-service]] / ad gating) | Reward-based feature unlock | Partial |
| Update check / App update | (see [[features/app_update]]) | In-app update prompting (optional + hard-block) | Yes |

## Naming Rules

- `*Service` — business logic (network may or may not be required)
- `*Repository` — offline-first data access (must have Drift mirror)
- `*RemoteSource` / `*OnlineSource` — online-only data, no local mirror

`LocalAiService` is the canonical example of a correctly named online-only service.

## See Also

- [[architecture/layers]] — domain layer rules
- [[architecture/online-first-exemption]] — naming contract
