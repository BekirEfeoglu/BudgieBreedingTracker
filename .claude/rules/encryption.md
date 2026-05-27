# Encryption

`EncryptionService` (`lib/domain/services/encryption/`) hassas alanları (ring_number, pedigree_info, genetic_info) AES-256-CBC + HMAC-SHA256 ile şifreler. Anahtar `flutter_secure_storage` üzerinde platform keychain/keystore'da tutulur.

## Algoritma
| Bileşen | Spesifikasyon |
|---------|---------------|
| Cipher | AES-256-CBC (32-byte key, 16-byte IV) |
| MAC | HMAC-SHA256 (32-byte tag) |
| Encoding | Base64 (transport + DB storage) |
| Magic prefix | `BBTENC1!` (ASCII 8 byte) |
| Layout | `magic ‖ version ‖ iv ‖ ciphertext ‖ mac` |

`encrypt-then-MAC` sırası zorunlu — önce cipher, sonra MAC. Decryption'da önce MAC verify, sonra decrypt (constant-time compare).

## Anahtar Yönetimi
- Master key: 32 byte, `Random.secure()` ile üretilir
- Storage: `FlutterSecureStorage` (`encryptedSharedPreferences` Android + Keychain iOS)
- Storage key: `budgie_encryption_key`
- Version key: `budgie_encryption_key_version` — rotation için
- Eski key arşivi: `budgie_encryption_key_v<N>` (her version için ayrı slot)

```dart
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
);
```

## Sub-Key Derivation
Master key tek başına hem encrypt hem MAC için kullanılmaz — sub-key'ler türetilir:
- Encryption sub-key: HMAC-SHA256(master, "enc")
- MAC sub-key: HMAC-SHA256(master, "mac")

Sub-key hesabı her encrypt/decrypt'te tekrar edilmez — bir kere hesaplanıp `_cachedMasterKeyHash` ve `_cachedEncKey`/`_cachedMacKey` alanlarında cache'lenir. App restart'ta yeniden hesaplanır.

## Key Rotation
- Trigger: 90 günde bir veya kompromise şüphesinde
- `encryption_migration.dart` mevcut tüm encrypted alanları eski key ile decrypt + yeni key ile re-encrypt
- Eski key SİLİNMEZ — `_previousKeyPrefix` ile arşivlenir (eski cihazdan restore senaryosu)
- Rotation atomic değil; migration sırasında crash → partial state mümkün → migration log'u zorunlu (resume capability)
- Rotation sonrası version field bump (`_keyVersionName`)

## Payload Codec
`encryption_payload_codec.dart`:
```
[magic (8B)] [version (1B)] [iv (16B)] [ciphertext (N)] [mac (32B)]
```
- Magic mismatch → `InvalidPayloadException` (yanlış formata karşı koruma)
- Version mismatch → key archive'dan eski key ile decrypt attempt
- MAC verify fail → `IntegrityException` + Sentry (tampering şüphesi)
- IV random per encrypt (asla reuse)

## Sentry & Logging
- Encrypt/decrypt hata: `Sentry.captureException` zorunlu (data corruption sinyali)
- Asla plaintext'i log'lama — sadece byte length + magic verify result
- Key rotation event'i: `AppLogger.info('Encryption', 'rotated key v$old → v$new')`
- PII log etme: ring_number, pedigree içeriği Sentry'ye GİTMEZ

## What to Encrypt
| Alan | Şifrele |
|------|---------|
| ring_number | EVET (kuş ID hırsızlık riski) |
| pedigree_info | EVET (kişisel + ticari değer) |
| genetic_info | EVET (premium içerik) |
| photoUrl | HAYIR (zaten signed URL + RLS) |
| name / notes | HAYIR (kullanıcı zaten görüyor) |
| timestamps | HAYIR (operational data) |

Kural: PII + ticari değer + RLS yetmiyor = şifrele. UX yardımcı veri = düz.

## Boundary Behavior
- Drift DB: encrypted field text olarak (base64)
- Supabase: encrypted field text — server düz veriyi GÖRMEZ (zero-knowledge)
- UI: decrypted in-memory, asla disk'e plain dump etme
- Backup (`data-io.md`): backup'a yazılırken yeniden encrypt (backup key ≠ runtime key)

## Performance
- Encrypt/decrypt < 5ms/field (cached sub-key)
- 100 kayıtlı liste ekranı: bulk decrypt arka plan isolate (UI thread'i bloklama)
- LRU cache: son 100 decrypted plaintext (privacy: app background'a giderken flush)
- Sub-key cache miss = key load + 2x HMAC (ilk launch ~10ms)

## Migration Yolu
1. Yeni encrypted alan eklenirse: nullable kolon → backfill migration → NOT NULL
2. Algoritma değişikliği (örn. AES-CBC → AES-GCM): version bump + lazy re-encrypt on read
3. Asla migration'da plaintext dump → re-encrypt cycle (transient plaintext disk'te kalır)

## Testing
- Round-trip: encrypt → decrypt eşitlik (1000 random payload)
- Tamper detection: ciphertext'in 1 byte'ını değiştir, decrypt MUST throw `IntegrityException`
- Wrong key: farklı key ile decrypt → throw, asla bozuk plaintext döndürme
- Key rotation: eski key ile yazılmış payload yeni key sonrası decrypt edilebilmeli (archive'dan)
- Performance: encrypt 1000 field < 5sn (cache aktif)

```dart
test('detects ciphertext tampering', () async {
  final encrypted = await service.encrypt('secret');
  final bytes = base64.decode(encrypted);
  bytes[bytes.length - 5] ^= 0xFF; // MAC bölgesini boz
  final tampered = base64.encode(bytes);
  await expectLater(
    service.decrypt(tampered),
    throwsA(isA<IntegrityException>()),
  );
});
```

## Anti-Patterns
1. Aynı IV ile birden fazla encrypt (ECB-equivalent leak)
2. MAC verify atlayıp doğrudan decrypt (tampering algılanmaz)
3. Master key'i log/Sentry/error message'a koymak
4. `==` ile MAC compare (timing attack — `constantTimeBytesEquals` kullan)
5. Encryption key'i SharedPreferences'ta tutmak (secure storage zorunlu)
6. Rotation'da eski key'i silmek (eski yedek geri yüklenemez)
7. Encrypted field'ı düz string gibi indexlemek (SQL LIKE çalışmaz — server-side query yapısı plan edilmeli)
8. Migration sırasında plaintext disk'e geçici dump
9. Magic prefix'siz custom payload kabul etmek (format spoofing)
10. Sub-key cache'i app background'da temizlememek (memory dump riski)

> **İlgili**: security.md (secure storage, MFA), data-layer.md (encrypted field storage), data-io.md (backup encryption), observability.md (PII log politikası)
