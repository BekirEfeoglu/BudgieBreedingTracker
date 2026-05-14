# Security

Source: `.claude/rules/security.md`

## Authentication Methods

| Method | Package |
|--------|---------|
| Email/password | Supabase Auth |
| Google OAuth | google_sign_in ^7.2.0 |
| Apple Sign-In | sign_in_with_apple ^8.0.0 |
| MFA (TOTP) | Supabase Auth + mfa-lockout Edge Function |

## Secure Storage

```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
```

| Item | Storage |
|------|---------|
| Supabase session token | Secure storage (auto by SDK) |
| Refresh token | Secure storage |
| User preferences | SharedPreferences (OK) |
| FCM token | Supabase DB |

**Never store tokens in SharedPreferences.**

## MFA Lockout Policy

- 5 failed TOTP attempts → lockout
- 7-day inactivity decay (not 24h — prevents 1 try/day forever attack)
- Server-side enforcement in `mfa-lockout` Edge Function

## Route Guards

| Guard | Protects | Behavior |
|-------|---------|---------|
| Auth redirect | Protected routes | → login if unauthenticated |
| `AdminGuard` | Admin screens | → home if not admin |
| `PremiumGuard` | Premium features | → upsell if not premium/grace |

All guards in `lib/router/guards/`. Never skip for "quick testing".

## Row-Level Security (RLS)

- ALL RLS policies managed server-side in Supabase
- Never modify RLS from client code
- Never use `service_role` key in client app
- Each user accesses only their own data (`auth.uid()` in policies)
- Verify with `scripts/verify_rls_staging.sql` before production migration

## Remote Payload Validation

- All Supabase responses deserialize through Freezed models
- `@JsonKey(unknownEnumValue: X.unknown)` on all enum fields
- Critical models assert required fields in factory body
- Edge function responses: parse to Freezed model, not `Map<String, dynamic>`
- Malformed payload → `ValidationException`, not silent null

## Credentials & Secrets

- Supabase URL/anon key: `--dart-define` or `.env` (never hardcoded)
- RevenueCat secret key: Edge Function secret only (never client)
- Never commit `.env`, `credentials.json`, key files
- CI: GitHub Secrets; Codemagic: env groups

## OAuth Token Management

- Google/Apple token revocation: `revoke-oauth-token` Edge Function on logout
- FCM tokens: deleted from DB on logout

## Anti-Patterns

1. Hardcoding Supabase credentials
2. `service_role` key in client app
3. Modifying RLS from client code
4. Tokens in SharedPreferences (use secure storage)
5. Skipping auth guards
6. Trusting client-side validation alone
7. Logging PII (passwords, tokens)
8. Committing `.env` or secrets to git

## See Also

- [[patterns/anti-patterns]] — #7 (client.from in features)
- [[patterns/observability]] — PII rules
- [[infrastructure/edge-functions]] — JWT enforcement
- [[domain/auth-service]] — session management
