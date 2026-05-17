# Domain Services Index

23 service directories in `lib/domain/services/` (ads, app_update, auth, backup, breeding, calendar, eggs, encryption, export, gamification, genetics, home_widget, import, incubation, local_ai, moderation, notifications, payment, premium, presence, profile, sync, update_check).

| Service | Purpose | Network Required |
|---------|---------|-----------------|
| [[domain/genetics-engine]] | Punnett, MUTAVI, inbreeding | No |
| [[domain/sync-service]] | Background sync orchestration | Yes (online trigger) |
| [[domain/local-ai]] | LLM image + text analysis | Yes (always) |
| [[domain/premium-service]] | RevenueCat + entitlement | Yes |
| [[domain/notification-service]] | FCM + local notifications | Partial |
| [[domain/calendar-service]] | Event scheduling | No |
| [[domain/auth-service]] | Login, session refresh | Yes |
| Breeding / IncubationRiskAssistant | Derived risk summary (overdue eggs, hatch-rate decline, chick health loss) | No |
| Incubation service | Hatch day calculation, species config | No |
| Eggs service | Egg status transitions, hatched→chick auto-create | No |
| Encryption service | Local secure storage primitives | No |
| Home widget service | iOS lock-screen + home widget snapshot sync | No |
| Backup / Import / Export | PDF/Excel/JSON I/O | Partial |
| Gamification service | Badge unlock logic | No |
| Moderation service | Report triggers, threshold flagging | Yes |
| Payment / Premium service | RevenueCat purchase + entitlement | Yes |
| Presence service | Online status broadcast | Yes |
| Profile service | User profile orchestration | Yes |
| Ads service | Premium upsell ad gating | Partial |
| Update check service | Forced update prompt | Yes |
| App update service | In-app update flow | Yes |
| Notifications service | Channel/category + scheduling | Partial |

## Naming Rules

- `*Service` — business logic (network may or may not be required)
- `*Repository` — offline-first data access (must have Drift mirror)
- `*RemoteSource` / `*OnlineSource` — online-only data, no local mirror

`LocalAiService` is the canonical example of a correctly named online-only service.

## See Also

- [[architecture/layers]] — domain layer rules
- [[architecture/online-first-exemption]] — naming contract
