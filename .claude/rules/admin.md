# Admin Panel

Admin yetkili kullanıcıların moderasyon, sistem sağlığı, kullanıcı yönetimi, içerik kuyrukları üzerinde çalıştığı dashboard. `lib/features/admin/` altında. Audit gerekçesiyle son birkaç release'de yoğun fix geldi (`fix(admin):` commit pattern).

## Erişim Kontrolü
- Route guard: `AdminGuard` (`lib/router/guards/admin_guard.dart`)
- Server-side: `profiles.is_admin` flag (RLS bypass DEĞİL — admin için ayrı policy)
- `AdminGuard.redirect` → admin değilse `AppRoutes.home`
- Client cache: admin durumu app start'ta + login sonrası refresh
- Asla `--dart-define` veya runtime flag ile admin enable etme (security.md)

## Repository Pattern Exception
- Admin feature `client.from()` doğrudan kullanabilir (CLAUDE.md anti-pattern #7 exception)
- Sebep: admin operasyonları RLS bypass değil ama farklı policy seti kullanır
- Yine de `SupabaseConstants` zorunlu (hardcoded string YOK)
- `.toSupabase()` extension her zaman kullanılır

## Audit Logs
- Her destructive admin işlemi `admin_audit_logs` tablosuna kaydedilir
- Schema: `(id, admin_user_id, action, target_type, target_id, payload, performed_at)`
- Server-side trigger ile yazılır (admin client trust etme)
- Audit log SİLİNEMEZ — sadece append
- Retention: 365 gün, sonrası archive

```sql
-- Audit trigger örneği
CREATE TRIGGER log_admin_user_ban
AFTER UPDATE OF banned_at ON profiles
WHEN OLD.banned_at IS DISTINCT FROM NEW.banned_at
EXECUTE FUNCTION audit_admin_action('ban_user');
```

## Destructive Guards
- Tüm destructive aksiyonlar (ban, delete, force logout) **iki adımlı** onay:
  1. Confirm dialog — açık açıklama ("Bu kullanıcıyı yasaklayacaksınız. Geri alınamaz.")
  2. Type-to-confirm: kullanıcı email veya ID'yi yazmalı
- Asla tek tap ile destructive aksiyon (yanlış tıklama → telafisi yok)
- Bulk operations: max 100 entity tek seferde
- `admin_get_stats` ve benzeri read-only RPC'ler bu guard'lara tabi değil

## RBAC (Role-Based)
- `is_admin` bool tek tier (super admin yok, henüz)
- İleride genişlerse: `admin_role` enum (`moderator`, `support`, `super`)
- Bu rule güncel implementation'a göre yazılır — multi-role yoksa eklenmez

## Monitoring Dashboard
| Bölüm | Veri kaynağı | Refresh |
|-------|--------------|---------|
| User stats | `admin_get_stats` RPC | Manuel + 5dk auto |
| System health | `system-health` edge fn | 30s polling (focused screen) |
| Moderation queue | `community_reports` table | Realtime + manuel |
| Edge function logs | Supabase Dashboard link | External |

- Refresh tetikleyici: pull-to-refresh + manual button
- Background polling: sadece focused screen aktifken (battery + cost)
- Bekleyen rapor sayısı badge: cache 60s TTL

## Moderation Queue
- Bekleyen `community_reports` listesi (status: pending)
- Her rapor: içerik snapshot + raporlayanlar + AI moderation skoru
- Aksiyonlar: approve (içerik kalır), remove (soft delete), warn user, ban user
- Decision audit log'a düşer
- Locale: admin paneli Türkçe + İngilizce (kullanıcı locale fallback)

## User Management
- Search: email, display name, user ID
- Pagination: 50/page, cursor-based
- Detay sayfası: bird count, last login, premium status, ban history
- Aksiyonlar: reset password (email tetikle), force MFA, ban, premium grant (debug only)

## Data Privacy
- Admin **kullanıcı şifresi, MFA secret, encrypted field plaintext** görmez (zero-knowledge)
- Sentry'ye admin işlem detayı GİTMEZ (PII risk)
- Audit log'a action + target ID yazılır, payload sadece non-PII
- Admin'in kendi yaptığı işlemi `admin_audit_logs`'tan silmesi engellenir (RLS policy)

## Realtime Updates
- Yeni rapor geldiğinde realtime channel `admin_reports` event
- Toast bildirimi (badge artar)
- Admin ekran kapalıysa: push DEĞİL, sadece app açıldığında badge

## Empty / Error State
- Boş queue: "Bekleyen rapor yok" + güneş ikonu (pozitif feedback)
- System health red: ErrorState + edge fn log link
- RPC fail: retry + Sentry breadcrumb (admin user context)

## Race Condition Mitigation
- 2026-04-25 audit: admin panel race fixes — concurrent action queue
- Aksiyon devam ederken aynı entity'ye ikinci aksiyon: disable button + spinner
- Optimistic UI: rollback on failure + l10n error

## Localization
- Admin paneli kullanıcı locale'ine uyar (tr/en/de)
- Audit detayında server-locale (en) görünür — i18n consistency
- 2026-04-25 audit: locale eksikleri kapatıldı

## Accessibility
- 48dp touch target (audit'te eksikti, fix'lendi)
- ConfirmDialog screen reader label'ları
- Keyboard navigation: tab order + Enter to confirm

## Testing
- Unit: guard logic (admin/non-admin redirect)
- Integration: RPC mock ile dashboard render
- E2E: ban flow happy path + cancel + double-tap (race)
- Audit log assertion: aksiyondan sonra row var mı?

```dart
test('ban user requires type-to-confirm', () async {
  await pumpAdminUserDetail(tester, user);
  await tester.tap(find.byKey(const Key('ban_button')));
  await tester.pumpAndSettle();
  // Type wrong email
  await tester.enterText(find.byKey(const Key('confirm_input')), 'wrong@test.com');
  expect(find.byKey(const Key('final_ban_button')).hitTestable(), findsNothing);
});
```

## Anti-Patterns
1. RLS bypass için `service_role` key'i client'a koymak (release-blocker, security.md)
2. Destructive aksiyonda tek-tap onay (yanlış tıklama → ban)
3. Audit log atlamak (compliance + dispute resolution gerekli)
4. Admin'in kendi audit log'unu silebilmesi (RLS yetersiz)
5. Sentry'ye admin işlem payload'ı (PII leak)
6. Bulk operation'ı 100+ entity'de tek transaction (timeout + lock)
7. Realtime queue badge'i push'a bağlamak (admin uyandırma)
8. Concurrent action'da race condition (audit history fix)
9. Type-to-confirm input'unu locale-sensitive yapmak (Almanca'da çalışmaz)
10. Reset password gibi sensitive aksiyonu admin client'tan tetiklemek yerine server-side trigger ile yapmamak

> **İlgili**: security.md (RLS, MFA), edge-functions.md (`system-health`), moderation.md (queue), community.md (report flow), code-review.md (admin reviewer checklist)
