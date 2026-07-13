# Auth (Kimlik Doğrulama)

Login, kayıt, OAuth, MFA (TOTP), session yaşam döngüsü ve logout zinciri. `lib/features/auth/` + `lib/domain/services/auth/`. Politika sahibi security.md'dir (secure storage, MFA lockout, OAuth topolojisi) — bu dosya **istemci akış sözleşmesini** toplar.

## Stack
| Bileşen | Yer |
|---------|-----|
| Sağlayıcı | Supabase Auth (email/password, Google, Apple) |
| Google | `google_sign_in ^7.2.0` (`auth_oauth_methods.dart`, `native_google_auth_errors.dart`) |
| Apple | `sign_in_with_apple ^8.0.0` |
| Providers | `lib/features/auth/providers/` — `auth_providers.dart` (state), `auth_actions.dart`, `auth_account_methods.dart`, `auth_error_mapper.dart`, `post_login_mfa_checker.dart`, `two_factor_providers.dart` |
| Domain servisler | `lib/domain/services/auth/` — `two_factor_service.dart`, `mfa_lockout_service.dart`, `password_policy.dart` |
| Edge fn | `mfa-lockout`, `revoke-oauth-token` (edge-functions.md) |
| MFA challenge UI | `lib/features/auth/widgets/mfa_challenge_dialog.dart` (facade: `lib/shared/widgets/auth.dart`) |

## Router Entegrasyonu
Redirect zincirindeki auth katmanları `lib/router/redirect_guards.dart`'ta, sırası SABİT (app_router.dart):
1. `sessionLockRedirect` — kilitli session → login
2. `authRedirect` — oturumsuz kullanıcı → login (anonymous-allowed rotalar hariç); oturumlu kullanıcı auth ekranından → home
3. `twoFactorRedirect` — `pendingMfaFactorIdProvider` doluysa 2FA verify'a zorla

`RouterNotifier` bu provider'ları dinler ve TEK notify ile redirect'i yeniden koşturur — router'ı yeniden OLUŞTURMA. Guard'lar stateless'tır; provider state'inden türetilir.

## Session
- Token'lar secure storage'da (SDK yönetir) — SharedPreferences ASLA (security.md tablosu)
- SDK otomatik refresh (expire'dan 5dk önce); refresh fail → `AuthException` → login redirect
- Offline'da local session ile devam; online'da refresh
- Startup kritik yolu: `appInitializationProvider` sadece MFA check → profil pull → local notification init bekler; FCM kaydı ve full sync deferred (performance.md § Startup)

## MFA (TOTP)
- Enroll: Settings → Security → 2FA; TOTP secret + QR; `verify` sonrası aktif
- Login: password → `post_login_mfa_checker.dart` MFA challenge'a yönlendirir
- Lockout: 5 hatalı deneme → lockout, 7 gün decay — `mfa-lockout` edge fn server-side enforce (security.md § MFA Lockout Policy tek kaynak)
- **Recovery codes — shipped (2026-07-09):** 2FA kurulumunda 10 tek-kullanımlık kod üretilir (`RecoveryCodeService`, SHA-256 hash olarak `mfa_recovery_codes`'ta saklanır). Login 2FA verify ekranında "Kurtarma kodu kullan" → `redeem_mfa_recovery_code` RPC MFA'yı server-side devre dışı bırakır (AAL1 login tamamlanır, re-enroll'a yönlendirir). Detay: security.md § MFA UX Flow

## AAL2 & Destructive Aksiyonlar (şifre değişimi, hesap silme)
Password re-auth (`signInWithPassword`) MFA'lı session'ı **AAL1'e düşürür** — "check → reauth → check" dizisi MFA'lı her kullanıcıda `MfaAssuranceRequiredException` fırlatır (2026-07-02'de düzeltilen gerçek bug).

Doğru pattern:
1. Aksiyon `...ForVerifiedSession` varyantıyla çağrılır (`changePasswordForVerifiedSession`, `requestAccountDeletionForVerifiedSession` — `auth_account_methods.dart`)
2. `MfaAssuranceRequiredException` yakalanır → `showMfaChallengeDialog` → `TwoFactorService.challengeAndVerify` (bu TEK BAŞINA AAL2'yi geri kurar, ikinci şifre isteme)
3. Verified-session varyantı retry edilir

AAL2 kontrolü HER destructive adımdan ÖNCE koşar — hesap silmede storage temizliği AAL2 doğrulamasından önce başlatılamaz (profile.md § Hesap Silme sıra sözleşmesi).

## Cooldown & Abuse Koruması
- Password-reset / e-posta istekleri: **2 dakika cooldown** (`auth_actions.dart`) — email bombing engeli
- Cooldown SharedPreferences'a persist edilir (app restart bypass'ı kapatıldı, 2026-05-19 audit)
- Şifre kuralları `password_policy.dart` tek kaynak — UI'da ayrı regex kopyalama

## Hata Eşleme
- Raw Supabase/GoogleSignIn hataları `auth_error_mapper.dart` + `native_google_auth_errors.dart` ile l10n anahtarına çevrilir
- UI'ya asla raw exception metni gösterme (error-handling.md); auth hataları `auth.*`/`errors.*` kategorisinde

## Logout Zinciri (sıra önemli)
```
1. revoke-oauth-token edge fn (best-effort — Google/Apple)
2. Supabase signOut()
3. Bu cihazın FCM token'ını deaktive et — pushNotificationService.deactivateCurrentToken() (notifications.md: bu cihaza eski hesabın bildirimi gitmesin; per-device, diğer cihaz oturumları korunur)
4. Presence temizle — UserPresenceController.markInactive() → endSession() (presence.md: sticky online engeli)
5. Sentry user scope null (observability.md: PII)
6. Session/secure storage temizliği + provider invalidation
```
Best-effort adımların hatası zinciri DURDURMAZ (log + devam). Hesap silme bu zincirin üstünde ek adımlar içerir — profile.md sahibidir.

## Testing
- Guard redirect testleri: `test/router/` (oturumsuz → login, MFA pending → verify)
- Provider testleri: cooldown persist, error mapper eşlemeleri, `...ForVerifiedSession` MFA-required path
- `mfa_challenge_dialog` akışı: challenge başarı/iptal her iki dal

## Anti-Patterns
1. Token'ı SharedPreferences'ta tutmak (secure storage zorunlu — security.md)
2. Korunan rotada guard atlamak ("hızlı test" dahil — ai-workflow prohibited)
3. Destructive aksiyonun AAL2 kontrolünü ilk yıkıcı adımdan SONRA yapmak (2026-07-02 bug'ının tekrarı)
4. MFA-required durumu password re-auth ile çözmeye çalışmak (AAL1'e düşürür — challenge dialog kullan)
5. Recovery-code redeem'i client-side unenroll ile çözmeye çalışmak (AAL1'de kullanıcı verified factor'ı silemez — server-side `redeem_mfa_recovery_code` RPC zorunlu); veya kodu plaintext saklamak (yalnız SHA-256 hash)
6. Cooldown'ı yalnız bellekte tutmak (restart bypass — persist zorunlu)
7. Logout'ta FCM/presence/Sentry temizliğini atlamak (cross-device bildirim sızıntısı, sticky online, PII)
8. Raw auth hata metnini kullanıcıya göstermek (error mapper + l10n)
9. Router'ı auth state değişiminde yeniden oluşturmak (`RouterNotifier` refreshListenable tek yol)

> **İlgili**: security.md (secure storage, MFA lockout, OAuth topolojisi), profile.md (hesap silme, AAL2), edge-functions.md (mfa-lockout, revoke-oauth-token), notifications.md (FCM token temizliği), presence.md (logout markInactive/endSession), observability.md (Sentry user scope), performance.md (startup kritik yolu)
