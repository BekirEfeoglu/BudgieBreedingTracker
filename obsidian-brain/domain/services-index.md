# Domain Services Index

21 service directories in `lib/domain/services/`.

| Service | Purpose | Network Required |
|---------|---------|-----------------|
| [[domain/genetics-engine]] | Punnett, MUTAVI, inbreeding | No |
| [[domain/sync-service]] | Background sync orchestration | Yes (online trigger) |
| [[domain/local-ai]] | LLM image + text analysis | Yes (always) |
| [[domain/premium-service]] | RevenueCat + entitlement | Yes |
| [[domain/notification-service]] | FCM + local notifications | Partial |
| [[domain/calendar-service]] | Event scheduling | No |
| [[domain/auth-service]] | Login, session refresh | Yes |
| Incubation service | Hatch day calculation | No |
| Storage service | Photo upload pipeline | Yes |
| Export service | PDF/Excel generation | No |
| Genealogy service | Family tree computation | No |
| Gamification service | Badge unlock logic | No |
| Analytics service | Event tracking | Yes |
| App config service | Remote kill switches | Yes |
| Free tier limit service | Entity count checks | Yes (edge fn) |
| Connectivity service | Network state | No |
| FCM token service | Token registration/cleanup | Yes |
| Content moderation | Report triggers | Yes |
| User guide service | Onboarding flow | No |
| Image compress service | Resize before upload | No |
| Error reporting service | Sentry wrapper | Yes |

## Naming Rules

- `*Service` — business logic (network may or may not be required)
- `*Repository` — offline-first data access (must have Drift mirror)
- `*RemoteSource` / `*OnlineSource` — online-only data, no local mirror

`LocalAiService` is the canonical example of a correctly named online-only service.

## See Also

- [[architecture/layers]] — domain layer rules
- [[architecture/online-first-exemption]] — naming contract
