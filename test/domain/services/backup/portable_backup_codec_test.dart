import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/backup/portable_backup_codec.dart';

void main() {
  const codec = PortableBackupCodec();
  const password = 'correct horse battery staple';

  group('PortableBackupCodec', () {
    test('round-trips authenticated content with versioned metadata', () async {
      const plainText = '{"version":2,"data":{"birds":[]}}';

      final envelope = await codec.encrypt(plainText, password);
      final decoded = jsonDecode(envelope) as Map<String, dynamic>;

      expect(decoded['format'], PortableBackupCodec.format);
      expect(decoded['format_version'], PortableBackupCodec.formatVersion);
      expect(decoded['kdf'], PortableBackupCodec.kdf);
      expect(decoded['iterations'], PortableBackupCodec.iterations);
      expect(PortableBackupCodec.looksPortable(envelope), isTrue);
      expect(await codec.decrypt(envelope, password), plainText);
    });

    test(
      'rejects a wrong password and authenticated-field tampering',
      () async {
        final envelope = await codec.encrypt('sensitive backup', password);

        await expectLater(
          codec.decrypt(envelope, 'this password is incorrect'),
          throwsFormatException,
        );

        final decoded = jsonDecode(envelope) as Map<String, dynamic>;
        decoded['ciphertext'] = '${decoded['ciphertext']}A';
        await expectLater(
          codec.decrypt(jsonEncode(decoded), password),
          throwsFormatException,
        );
      },
    );

    test('uses fresh random salt and IV for every backup', () async {
      final first =
          jsonDecode(await codec.encrypt('same backup', password))
              as Map<String, dynamic>;
      final second =
          jsonDecode(await codec.encrypt('same backup', password))
              as Map<String, dynamic>;

      expect(first['salt'], isNot(second['salt']));
      expect(first['iv'], isNot(second['iv']));
      expect(first['ciphertext'], isNot(second['ciphertext']));
    });

    test('rejects short passwords before encryption', () async {
      await expectLater(
        codec.encrypt('backup', 'too-short'),
        throwsFormatException,
      );
    });
  });
}
