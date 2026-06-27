# Presence (Online / Last-Seen)

`UserPresenceService` (`lib/domain/services/presence/`) kullanıcıların online durumunu, son görülme zamanını ve aktif oturum sayısını yönetir. Messaging'de typing indikator + online rozetinin kaynağı.

## Stack
| Katman | Bileşen |
|--------|---------|
| Service | `UserPresenceService` |
| Providers | `user_presence_providers.dart` |
| Constants | `user_presence_constants.dart` (TTL, heartbeat interval) |
| Storage | Supabase realtime channels + `user_presence` table |
| Integration | messaging (typing), community (online badge), profile (last-seen) |

## Presence Model
| Durum | Anlam |
|-------|-------|
| `online` | Heartbeat son N saniye içinde + foreground |
| `away` | App background veya idle > 5dk |
| `offline` | Heartbeat TTL doldu, son görülme görünür |
| `invisible` | Privacy: online'ken offline gibi görün |

## Heartbeat
- Interval: 30 saniye (foreground)
- Mekanizma: Supabase realtime `track` payload + `user_presence` table upsert
- App background → heartbeat dur, `away` state'e geç
- App foreground → heartbeat resume + immediate update
- Network kopukluğunda: 90s TTL içinde `offline`

## TTL & Cleanup
- `user_presence.last_heartbeat_at` 90s'den eskiyse offline say
- Cleanup cron veya query-time filter (`now() - last_heartbeat_at < interval '90 seconds'`)
- Realtime channel disconnect server tarafında otomatik temizlik
- Logout: explicit `clearPresence()` çağrısı (sticky online engeli)

## Privacy Settings
- `profile.presence_visibility`: `everyone` | `contacts` | `nobody`
- `nobody` mode: kullanıcı `invisible` görünür, last-seen kimseye yansımaz
- `contacts`: sadece daha önce DM yaptığın kişiler görür
- Settings ekranı opt-in, default `everyone`

## Typing Indicator (Messaging)
- Sender input event → debounced 500ms → realtime broadcast `typing_<conversation_id>`
- Receiver "yazıyor..." 3s timeout
- Ephemeral — DB'ye yazılmaz, sadece realtime payload
- Multiple typing event reset timer

## Last-Seen Format
- < 1dk: "Az önce"
- < 1 saat: "5dk önce"
- < 24 saat: "3 saat önce"
- < 7 gün: "Dün" / "3 gün önce"
- > 7 gün: "Geçen ay" / tarih
- L10n: relative time anahtarları `common.minutes_ago` / `common.hours_ago` / `common.days_ago` (ayrı `time` kategorisi yok)

## UI Indicators
| Yer | Gösterim |
|-----|----------|
| Conversation list | Yeşil nokta avatar köşesinde |
| Profile screen | "Çevrimiçi" / "Az önce görüldü" |
| Message thread header | Status + typing |
| Community feed | (Online badge GÖSTERME — privacy) |

Privacy: feed'de online badge YOK (passive scrolling kullanıcıyı outvalue eder, izinsiz tracking hissi).

## Battery Optimization
- Heartbeat sadece foreground (background'da bandwidth + battery israfı)
- Background fetch ile presence sync YAPMA (iOS BGTaskScheduler farklı amaçla)
- Realtime channel sayısı sınırlı (Supabase free tier 200 concurrent) — sadece aktif conversation'da subscribe
- Throttle: 30s minimum heartbeat aralığı (rapid foreground/background toggle koruması)

## Edge Cases
- iOS app suspended (background 30s+): realtime socket düşer, server `offline` görür
- Push notification ile app açılırsa: presence resume edilmeli, otomatik değil
- Multi-device: en son heartbeat eden cihaz "online" sayılır
- Concurrent session: 5 cihaz limiti (security.md MFA policy ile uyumlu)

## Performance
- Heartbeat overhead: < 1KB/30s = ~3KB/dk
- Realtime channel: 1 global presence channel + 1 per active conversation
- Last-seen render: cached değer (5sn TTL), her rebuild server fetch YAPMA
- Bulk profile lookup: batch (`profileLookupProvider`) — N+1 query engeli

## Testing
- Unit: TTL hesabı (`isOnline(lastHeartbeat, now)`), state transitions
- Integration: heartbeat send + presence read round-trip
- Privacy: `invisible` mode → server presence yazmıyor mu? (RLS test)
- Edge: background → online transition (lifecycle event mock)

```dart
test('reports offline after TTL expires', () {
  final lastBeat = DateTime.now().subtract(const Duration(seconds: 95));
  expect(UserPresenceService.isOnline(lastBeat), isFalse);
});

test('respects invisible privacy mode', () async {
  await service.setVisibility(PresenceVisibility.nobody);
  await service.heartbeat();
  final reported = await fetchPresence(myUserId);
  expect(reported.status, PresenceStatus.offline);
});
```

## Sentry & Logging
- Presence update event'leri Sentry'ye GİTMEZ (gürültü)
- Heartbeat fail (network) → `AppLogger.debug` (üretimde gizli)
- Realtime subscribe fail → `AppLogger.warning` + retry
- Privacy ihlali (yanlış visibility) → `AppLogger.error` + Sentry

## Anti-Patterns
1. Background'da heartbeat (battery drain, iOS API misuse)
2. Realtime channel'ı dispose etmemek (concurrent limit dolar)
3. Last-seen'i client clock'tan hesaplamak (timezone bug — server timestamp)
4. `invisible` modu client-only flag yapmak (server presence yazmaya devam ederse leak)
5. Feed'de online badge göstermek (privacy)
6. Heartbeat'i `setState` ile UI thread'inde hesaplamak (jank)
7. Logout'ta explicit clearPresence atlamak (sticky online görünür)
8. TTL'i çok kısa yapmak (90s makul — 30s aşırı flicker)
9. Multi-device'ta tüm session'ları "online" saymak (en son heartbeat tek doğru)
10. Typing indicator'ı DB'ye yazmak (anti-pattern: messaging.md ile çelişir)

> **İlgili**: messaging.md (typing, online status), community.md (privacy), notifications.md (push wake → presence resume), security.md (session limit)
