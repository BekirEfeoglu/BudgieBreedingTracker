import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/security/certificate_pinning.dart';

void main() {
  group('CertificatePinning.isPinnedHost', () {
    group('pinned Supabase hosts', () {
      test('matches supabase.co subdomain', () {
        expect(
          CertificatePinning.isPinnedHost('lmqkwgitzvpacycujzgc.supabase.co'),
          isTrue,
        );
      });

      test('matches any supabase.co subdomain', () {
        expect(
          CertificatePinning.isPinnedHost('abcdef.supabase.co'),
          isTrue,
        );
      });

      test('is case insensitive', () {
        expect(
          CertificatePinning.isPinnedHost('PROJECT.SUPABASE.CO'),
          isTrue,
        );
      });

      test('matches mixed case', () {
        expect(
          CertificatePinning.isPinnedHost('project.Supabase.Co'),
          isTrue,
        );
      });
    });

    group('non-pinned hosts', () {
      test('rejects generic domains', () {
        expect(CertificatePinning.isPinnedHost('example.com'), isFalse);
      });

      test('rejects similar but different domains', () {
        expect(CertificatePinning.isPinnedHost('notsupabase.co'), isFalse);
      });

      test('rejects supabase with different TLD', () {
        expect(CertificatePinning.isPinnedHost('supabase.com'), isFalse);
      });

      test('rejects bare supabase.co (no subdomain)', () {
        // bare domain without subdomain prefix — edge case
        expect(CertificatePinning.isPinnedHost('supabase.co'), isFalse);
      });

      test('rejects empty string', () {
        expect(CertificatePinning.isPinnedHost(''), isFalse);
      });

      test('rejects localhost', () {
        expect(CertificatePinning.isPinnedHost('localhost'), isFalse);
      });

      test('rejects sentry domain', () {
        expect(CertificatePinning.isPinnedHost('sentry.io'), isFalse);
      });
    });
  });
}
