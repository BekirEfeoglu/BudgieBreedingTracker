import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/post_login_mfa_checker.dart';

import '../../../helpers/mocks.dart';

/// Minimal fake Factor for testing.
class _FakeFactor extends Fake implements Factor {
  @override
  final String id;

  _FakeFactor(this.id);
}

void main() {
  late MockTwoFactorService mockTwoFactor;
  late MockAuthActions mockAuth;
  late PostLoginMfaChecker checker;

  setUp(() {
    mockTwoFactor = MockTwoFactorService();
    mockAuth = MockAuthActions();
    checker = PostLoginMfaChecker(
      twoFactorService: mockTwoFactor,
      authActions: mockAuth,
    );
  });

  group('PostLoginMfaChecker', () {
    test('returns MfaNotRequired when user has no 2FA', () async {
      when(() => mockTwoFactor.needsVerification())
          .thenAnswer((_) async => false);

      final result = await checker.check();

      expect(result, isA<MfaNotRequired>());
      verifyNever(() => mockTwoFactor.getFactors());
      verifyNever(() => mockAuth.signOut());
    });

    test('returns MfaVerificationNeeded when user has TOTP factor', () async {
      when(() => mockTwoFactor.needsVerification())
          .thenAnswer((_) async => true);
      when(() => mockTwoFactor.getFactors())
          .thenAnswer((_) async => [_FakeFactor('factor-123')]);

      final result = await checker.check();

      expect(result, isA<MfaVerificationNeeded>());
      expect((result as MfaVerificationNeeded).factorId, 'factor-123');
      verifyNever(() => mockAuth.signOut());
    });

    test(
        'signs out and returns MfaCheckFailed when needsVerification but no factors',
        () async {
      when(() => mockTwoFactor.needsVerification())
          .thenAnswer((_) async => true);
      when(() => mockTwoFactor.getFactors()).thenAnswer((_) async => []);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      final result = await checker.check();

      expect(result, isA<MfaCheckFailed>());
      expect((result as MfaCheckFailed).didSignOut, isTrue);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('signs out and returns MfaCheckFailed when getFactors throws',
        () async {
      when(() => mockTwoFactor.needsVerification())
          .thenAnswer((_) async => true);
      when(() => mockTwoFactor.getFactors()).thenThrow(Exception('MFA error'));
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      final result = await checker.check();

      expect(result, isA<MfaCheckFailed>());
      expect((result as MfaCheckFailed).didSignOut, isTrue);
      verify(() => mockAuth.signOut()).called(1);
    });

    test('returns MfaCheckFailed with didSignOut=false when signOut also fails',
        () async {
      when(() => mockTwoFactor.needsVerification())
          .thenAnswer((_) async => true);
      when(() => mockTwoFactor.getFactors()).thenThrow(Exception('MFA error'));
      when(() => mockAuth.signOut()).thenThrow(Exception('SignOut failed'));

      final result = await checker.check();

      expect(result, isA<MfaCheckFailed>());
      expect((result as MfaCheckFailed).didSignOut, isFalse);
      verify(() => mockAuth.signOut()).called(1);
    });

    test(
        'signs out and returns MfaCheckFailed when needsVerification itself throws',
        () async {
      when(() => mockTwoFactor.needsVerification())
          .thenThrow(Exception('Service down'));
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      final result = await checker.check();

      expect(result, isA<MfaCheckFailed>());
      expect((result as MfaCheckFailed).didSignOut, isTrue);
      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
