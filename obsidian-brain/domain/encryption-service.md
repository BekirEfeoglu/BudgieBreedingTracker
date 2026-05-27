# Encryption Service

Source: `.claude/rules/encryption.md` (primary — AES-256-CBC + HMAC, key rotation, payload codec, sub-key derivation, what-to-encrypt), `.claude/rules/security.md`

**Location**: `lib/domain/services/encryption/`

## Responsibility

AES-256-CBC encryption with HMAC-SHA256 authentication, used for sensitive
fields (ring number, genetic info, pedigree notes) and optional backup
encryption. Master key lives in `FlutterSecureStorage` (iOS Keychain /
Android Keystore) — never in app memory longer than necessary, never on
disk in plaintext, never in SharedPreferences.

## Payload Format

```
BBTENC1!  (8-byte magic)
+ IV       (16 bytes, random per encrypt)
+ ciphertext (AES-256-CBC)
+ HMAC-SHA256 (32 bytes, computed over IV + ciphertext with derived MAC key)
```

Base64-encoded for storage. The magic prefix lets the service detect
legacy unauthenticated payloads and trigger migration on read.

## Sub-Key Derivation

`_deriveSubKeys(masterKey)` runs HMAC-SHA256(masterKey, "BBTENC") for the
encryption sub-key and HMAC-SHA256(masterKey, "BBTMAC") for the MAC
sub-key, then caches by master-key hash. Separate sub-keys mean MAC
forgery doesn't recover the encryption key and vice-versa.

## Public API

| Method | Purpose |
|--------|---------|
| `encrypt(plain)` | New encryption with random IV + HMAC |
| `decrypt(cipher)` | Authenticated decryption; falls back to previous key versions on MAC fail |
| `hasKey()` | Returns false on storage unavailable (read-without-throw) |
| `deleteKey()` | Wipes the active key — previously encrypted data becomes unreadable |
| `rotateKey()` | Stores active key as `v{N-1}`, generates new active key |
| `reEncrypt(cipher)` | Decrypt with any known key → re-encrypt with current → migrate format |
| `_needsReEncryption(data)` | True for legacy payloads missing `BBTENC1!` magic |

## Key Rotation

`rotateKey()` writes the active key to `budgie_encryption_key_v{N}` and
generates a new active key. `decrypt()` tries the active key first, then
walks previous versions — encrypted data outlives rotation. Callers should
invoke `reEncrypt` on each row to migrate to the new key.

`EncryptionMigration` (part file) is the batch helper that walks tables
re-encrypting rows after rotation or format upgrade.

## Hooks Into Other Services

- [[domain/data-io]] — optional backup encryption (`.enc.json`)
- Birds, breeding, genetics features encrypt sensitive fields before
  writing to Drift / Supabase (defense in depth — RLS is primary)

## Anti-Patterns

1. Caching the master key in a long-lived Dart field — secure storage round-trip is the safety boundary
2. Skipping HMAC verification on decrypt (tamper detection)
3. Using deterministic IVs (every encrypt MUST use a fresh random IV)
4. Storing previous keys without version index (rotation breaks decryption)
5. Logging plaintext or key material to AppLogger / Sentry (PII / secret leak)

## See Also

- [[patterns/security]] — secure storage policy
- [[domain/data-io]] — backup encryption integration
- [[domain/services-index]]
