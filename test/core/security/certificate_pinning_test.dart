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
        expect(CertificatePinning.isPinnedHost('abcdef.supabase.co'), isTrue);
      });

      test('is case insensitive', () {
        expect(CertificatePinning.isPinnedHost('PROJECT.SUPABASE.CO'), isTrue);
      });

      test('matches mixed case', () {
        expect(CertificatePinning.isPinnedHost('project.Supabase.Co'), isTrue);
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

  group('CertificatePinning.shouldRejectProxyForHost', () {
    test('rejects proxied connections for pinned hosts', () {
      expect(
        CertificatePinning.shouldRejectProxyForHost(
          'lmqkwgitzvpacycujzgc.supabase.co',
          hasProxy: true,
        ),
        isTrue,
      );
    });

    test('allows direct connections for pinned hosts', () {
      expect(
        CertificatePinning.shouldRejectProxyForHost(
          'lmqkwgitzvpacycujzgc.supabase.co',
          hasProxy: false,
        ),
        isFalse,
      );
    });

    test('does not reject proxied connections for unpinned hosts', () {
      expect(
        CertificatePinning.shouldRejectProxyForHost(
          'example.com',
          hasProxy: true,
        ),
        isFalse,
      );
    });
  });

  group('CertificatePinning.isTrustedFingerprint', () {
    test('trusts the active Supabase leaf certificate', () {
      expect(
        CertificatePinning.isTrustedFingerprint(
          'B9:B8:F4:CE:6C:86:1D:3D:D1:67:87:08:FA:4A:40:62:10:7E:E7:05:0B:52:82:0F:99:10:50:F1:2E:B2:91:00',
        ),
        isTrue,
      );
    });

    test('rejects unknown fingerprints', () {
      expect(
        CertificatePinning.isTrustedFingerprint(
          '00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00',
        ),
        isFalse,
      );
    });
  });
}
