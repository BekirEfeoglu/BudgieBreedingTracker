# Profile

Kullanıcının kendi profili: kimlik alanları, avatar, güvenlik bölümü, istatistik sayaçları ve hesap silme. `lib/features/profile/` + offline-first `ProfileRepository`. Hesap silme bu app'in en yıkıcı akışıdır — sırası ve guard'ları sabittir.

## Stack
| Bileşen | Yer |
|---------|-----|
| Model | `Profile` (`lib/data/models/profile_model.dart`, Freezed) |
| Repository | `ProfileRepository` (offline-first, `watchProfile(userId)`) |
| Avatar | `AvatarWidget` + `showAvatarPickerSheet` → `StorageService.uploadAvatar` (`avatars` bucket) |
| Hesap silme | `AccountDeletionController` (`account_deletion_providers.dart`) + `accountStorageCleanupProvider` (`lib/domain/services/profile/`) |
| Güvenlik | `SecuritySection` + `securityScoreProvider` (`profile_stats_providers.dart`) |
| Sayaçlar | `profileStatsProvider` (SQL COUNT bazlı) |

## Model Alanları (shipped)
`id` + `email` (required); `displayName, fullName, avatarUrl, role, isPremium, subscriptionStatus, showInLeaderboard (default true), language, premiumExpiresAt, gracePeriodUntil`.
- `role`/`isPremium`/`premiumExpiresAt`/`gracePeriodUntil` **server-authoritative** — client'tan set edilmez (admin.md founder guard'ları, premium-revenuecat.md)
- `profiles.quiet_hours` gibi bazı DB kolonları server-side kullanılır (notifications.md) ama Dart `Profile` modelinde YOK — modele alan eklerken DB kolonu var diye otomatik taşıma; kullanım yeri belirle
- Profil `id == auth.uid()` — repository client-side de doğrular, RLS server-side zorlar

## Avatar Akışı
```
ImagePicker (max 512px, quality 80) -> StorageService.uploadAvatar -> avatars bucket
  -> local profile update + sync pending -> AvatarWidget (CachedNetworkImage)
```
- Picker sonrası raw 2 MiB guard, `StorageService`, safety scan ve avatar bucket
  `file_size_limit` ile aynıdır; picker resize/quality tek başına boyut garantisi değildir
- Kaldırma: `deleteAvatar()` + `avatarUrl` temizle
- `showAvatarPickerSheet`: galeri/kamera/kaldır; `ScaffoldMessenger` pop'tan ÖNCE yakalanır ki izin hatası SnackBar'ı kaybolmasın — bu sırayı bozma
- Bucket private (assets-images.md § Storage Buckets)

## Hesap Silme (sıra SABİT, geri dönüşsüz)
```
1. Mevcut şifre doğrulama (verifyCurrentPassword)
2. requireAal2ForDestructiveAction() — MFA kayıtlıysa AAL2 zorunlu;
   MfaAssuranceRequiredException -> MFA challenge dialog -> completeAfterMfaChallenge()
3. Storage temizliği: accountStorageCleanupProvider.deleteAllUserFiles(userId) (tüm bucket'lar)
4. OAuth token revoke (best-effort — revoke-oauth-token edge fn)
5. RPC requestAccountDeletionForVerifiedSession() -> auth.users server-side silinir
6. Local: appDatabase.clearAllUserData(userId) + SharedPreferences tam temizlik
7. Tüm oturumlardan sign-out (best-effort — auth.users silindiyse hata normal)
```
- Guard şifre + AAL2'dir; type-to-confirm bu akışta YOK (admin.md'deki admin-panel kuralıyla karıştırma)
- 3-7 adımları kısmi başarısızlığa dayanıklı olmalı: RPC (adım 5) sonrası geri dönüş YOK — öncesindeki adımlar idempotent/best-effort kalır
- Adım sırası değiştirilemez: storage temizliği auth silinmeden önce (yetki varken), local wipe RPC başarısından sonra
- FCM token temizliği logout zincirinin parçası (notifications.md § FCM Token Management)

## Security Section & Skor
- Girişler: şifre değiştir (MFA challenge destekli sheet), 2FA kurulum (`AppRoutes.twoFactorSetup`)
- `securityScoreProvider` (100 üzerinden): şifre 25 + 2FA 30 + email doğrulama 20 + profil tamamlama/avatar 15 + premium 10; seviye eşikleri 80/60/40
- Skor bilgilendirme amaçlı — hiçbir özelliği GATE'lemez

## Stats Sayaçları
- `profileStatsProvider`: `totalBirds/totalPairs/totalEggs/totalChicks` — SQL COUNT query'leri, tam liste ÇEKMEZ (performance.md)
- Sayaç için entity listesi provider'ı watch etme (gereksiz rebuild + bellek)

## Testing
- `profile_repository_test.dart` (save, uploadAvatar, pushPending, hardDelete), `profile_model_test.dart`, `test/e2e/profile_flow_test.dart`
- Hesap silme: MFA-required path + best-effort adımların hata toleransı test edilir

## Anti-Patterns
1. Hesap silme adım sırasını değiştirmek (storage temizliği auth silmeden önce olmalı)
2. AAL2 kontrolünü atlamak veya sadece şifreyle silmek (MFA kayıtlıysa challenge zorunlu)
3. `isPremium`/`role`/grace alanlarını client'tan yazmak (server-authoritative)
4. Silme sonrası local DB/SharedPreferences temizliğini atlamak (hayalet veri + eski hesaba bildirim)
5. Best-effort adımların (OAuth revoke, sign-out) hatasını akışı durduran hata gibi işlemek
6. Avatar'ı resize/quality parametresiz yüklemek (512px/80 sabitleri)
7. Sayaçları COUNT yerine liste provider'ından türetmek
8. Email/telefonu public alanlara veya log'a sızdırmak (community.md PII kuralı)

> **İlgili**: security.md (MFA, secure storage, OAuth revoke), premium-revenuecat.md (subscription alanları), gamification.md (showInLeaderboard), assets-images.md (avatars bucket), notifications.md (FCM token temizliği), data-layer.md (offline-first repo)
