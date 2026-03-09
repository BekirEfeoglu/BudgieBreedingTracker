import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/domain/services/auth/two_factor_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockGoTrueMFAApi extends Mock implements GoTrueMFAApi {}

class MockUser extends Mock implements User {}

AuthMFAVerifyResponse _verifyResponse(User user) {
  return AuthMFAVerifyResponse(
    accessToken: 'access-token',
    tokenType: 'bearer',
    expiresIn: const Duration(hours: 1),
    refreshToken: 'refresh-token',
    user: user,
  );
}

Factor _factor({required String id, required FactorStatus status}) {
  return Factor(
    id: id,
    friendlyName: 'My device',
    factorType: FactorType.totp,
    status: status,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockGoTrueMFAApi mockMfa;
  late MockUser mockUser;
  late TwoFactorService service;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockMfa = MockGoTrueMFAApi();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.mfa).thenReturn(mockMfa);

    service = TwoFactorService(mockClient);
  });

  group('TwoFactorService', () {
    test('enroll returns factor id and TOTP details', () async {
      const enrollResponse = AuthMFAEnrollResponse(
        id: 'factor-1',
        type: FactorType.totp,
        totp: TOTPEnrollment(
          qrCode: '<svg/>',
          secret: 'ABC123',
          uri: 'otpauth://totp/Budgie',
        ),
      );
      when(
        () => mockMfa.enroll(
          factorType: FactorType.totp,
          issuer: 'BudgieBreedingTracker',
          friendlyName: 'Budgie Tracker',
        ),
      ).thenAnswer((_) async => enrollResponse);

      final result = await service.enroll();

      expect(result.factorId, 'factor-1');
      expect(result.secret, 'ABC123');
      expect(result.totpUri, 'otpauth://totp/Budgie');
      verify(
        () => mockMfa.enroll(
          factorType: FactorType.totp,
          issuer: 'BudgieBreedingTracker',
          friendlyName: 'Budgie Tracker',
        ),
      ).called(1);
    });

    test('enroll uses provided friendly name', () async {
      const enrollResponse = AuthMFAEnrollResponse(
        id: 'factor-custom',
        type: FactorType.totp,
        totp: TOTPEnrollment(
          qrCode: '<svg/>',
          secret: 'SECRET',
          uri: 'otpauth://totp/custom',
        ),
      );
      when(
        () => mockMfa.enroll(
          factorType: FactorType.totp,
          issuer: 'BudgieBreedingTracker',
          friendlyName: 'My Device',
        ),
      ).thenAnswer((_) async => enrollResponse);

      final result = await service.enroll(friendlyName: 'My Device');

      expect(result.factorId, 'factor-custom');
      verify(
        () => mockMfa.enroll(
          factorType: FactorType.totp,
          issuer: 'BudgieBreedingTracker',
          friendlyName: 'My Device',
        ),
      ).called(1);
    });

    test('enroll rethrows when TOTP enrollment data is missing', () async {
      const enrollResponse = AuthMFAEnrollResponse(
        id: 'factor-1',
        type: FactorType.totp,
      );
      when(
        () => mockMfa.enroll(
          factorType: FactorType.totp,
          issuer: 'BudgieBreedingTracker',
          friendlyName: 'Budgie Tracker',
        ),
      ).thenAnswer((_) async => enrollResponse);

      expect(() => service.enroll(), throwsException);
    });

    test('verifyEnrollment creates challenge then verifies code', () async {
      final challenge = AuthMFAChallengeResponse(
        id: 'challenge-1',
        expiresAt: DateTime(2025, 1, 1),
      );
      when(
        () => mockMfa.challenge(factorId: 'factor-1'),
      ).thenAnswer((_) async => challenge);
      when(
        () => mockMfa.verify(
          factorId: 'factor-1',
          challengeId: 'challenge-1',
          code: '123456',
        ),
      ).thenAnswer((_) async => _verifyResponse(mockUser));

      final ok = await service.verifyEnrollment(
        factorId: 'factor-1',
        code: '123456',
      );

      expect(ok, isTrue);
      verify(() => mockMfa.challenge(factorId: 'factor-1')).called(1);
      verify(
        () => mockMfa.verify(
          factorId: 'factor-1',
          challengeId: 'challenge-1',
          code: '123456',
        ),
      ).called(1);
    });

    test('verifyEnrollment returns false on failure', () async {
      final challenge = AuthMFAChallengeResponse(
        id: 'challenge-1',
        expiresAt: DateTime(2025, 1, 1),
      );
      when(
        () => mockMfa.challenge(factorId: 'factor-1'),
      ).thenAnswer((_) async => challenge);
      when(
        () => mockMfa.verify(
          factorId: 'factor-1',
          challengeId: 'challenge-1',
          code: '000000',
        ),
      ).thenThrow(Exception('invalid code'));

      final ok = await service.verifyEnrollment(
        factorId: 'factor-1',
        code: '000000',
      );

      expect(ok, isFalse);
    });

    test('challengeAndVerify returns true on success', () async {
      final challenge = AuthMFAChallengeResponse(
        id: 'challenge-2',
        expiresAt: DateTime(2025, 1, 1),
      );
      when(
        () => mockMfa.challenge(factorId: 'factor-2'),
      ).thenAnswer((_) async => challenge);
      when(
        () => mockMfa.verify(
          factorId: 'factor-2',
          challengeId: 'challenge-2',
          code: '654321',
        ),
      ).thenAnswer((_) async => _verifyResponse(mockUser));

      final ok = await service.challengeAndVerify(
        factorId: 'factor-2',
        code: '654321',
      );

      expect(ok, isTrue);
    });

    test('challengeAndVerify returns false on failure', () async {
      when(
        () => mockMfa.challenge(factorId: 'factor-2'),
      ).thenThrow(Exception('network'));

      final ok = await service.challengeAndVerify(
        factorId: 'factor-2',
        code: '654321',
      );

      expect(ok, isFalse);
    });

    test('unenroll returns true on success and false on error', () async {
      when(
        () => mockMfa.unenroll('factor-1'),
      ).thenAnswer((_) async => const AuthMFAUnenrollResponse(id: 'factor-1'));
      expect(await service.unenroll('factor-1'), isTrue);

      when(
        () => mockMfa.unenroll('factor-2'),
      ).thenThrow(Exception('permission denied'));
      expect(await service.unenroll('factor-2'), isFalse);
    });

    test('getFactors returns TOTP factors and [] on errors', () async {
      final verified = _factor(id: 'factor-1', status: FactorStatus.verified);
      final listResponse = AuthMFAListFactorsResponse(
        all: [verified],
        totp: [verified],
        phone: const [],
      );
      when(() => mockMfa.listFactors()).thenAnswer((_) async => listResponse);

      final factors = await service.getFactors();
      expect(factors, [verified]);

      when(() => mockMfa.listFactors()).thenThrow(Exception('failed'));
      expect(await service.getFactors(), isEmpty);
    });

    test('isEnabled is true only when verified factors exist', () async {
      final verified = _factor(id: 'factor-1', status: FactorStatus.verified);
      final unverified = _factor(
        id: 'factor-2',
        status: FactorStatus.unverified,
      );

      when(() => mockMfa.listFactors()).thenAnswer(
        (_) async => AuthMFAListFactorsResponse(
          all: [verified, unverified],
          totp: [verified],
          phone: const [],
        ),
      );
      expect(await service.isEnabled(), isTrue);

      when(() => mockMfa.listFactors()).thenAnswer(
        (_) async => AuthMFAListFactorsResponse(
          all: [unverified],
          totp: [unverified],
          phone: const [],
        ),
      );
      expect(await service.isEnabled(), isFalse);
    });

    test('needsVerification checks assurance levels correctly', () async {
      when(() => mockMfa.getAuthenticatorAssuranceLevel()).thenReturn(
        const AuthMFAGetAuthenticatorAssuranceLevelResponse(
          currentLevel: AuthenticatorAssuranceLevels.aal1,
          nextLevel: AuthenticatorAssuranceLevels.aal2,
          currentAuthenticationMethods: [],
        ),
      );
      expect(await service.needsVerification(), isTrue);

      when(() => mockMfa.getAuthenticatorAssuranceLevel()).thenReturn(
        const AuthMFAGetAuthenticatorAssuranceLevelResponse(
          currentLevel: AuthenticatorAssuranceLevels.aal2,
          nextLevel: AuthenticatorAssuranceLevels.aal2,
          currentAuthenticationMethods: [],
        ),
      );
      expect(await service.needsVerification(), isFalse);
    });
  });
}
