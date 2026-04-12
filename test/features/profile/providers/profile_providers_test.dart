import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('userProfileProvider', () {
    test('returns null when userId is anonymous', () async {
      final container = ProviderContainer(
        overrides: [currentUserIdProvider.overrideWithValue('anonymous')],
      );
      addTearDown(container.dispose);

      container.listen(userProfileProvider, (_, __) {});
      final result = await container.read(userProfileProvider.future);
      expect(result, isNull);
    });

    test('delegates to repo.watchProfile for authenticated user', () async {
      final mockRepo = MockProfileRepository();
      when(
        () => mockRepo.watchProfile('user-1'),
      ).thenAnswer((_) => Stream.value(null));

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(userProfileProvider, (_, __) {});
      final result = await container.read(userProfileProvider.future);
      expect(result, isNull);
      verify(() => mockRepo.watchProfile('user-1')).called(1);
    });

    test('does not call repo when anonymous', () async {
      final mockRepo = MockProfileRepository();

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          profileRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      container.listen(userProfileProvider, (_, __) {});
      await container.read(userProfileProvider.future);
      verifyNever(() => mockRepo.watchProfile(any()));
    });
  });

  group('SecurityScore.levelKey', () {
    test('returns excellent for score >= 80', () {
      const score = SecurityScore(score: 80, factors: []);
      expect(score.levelKey, 'profile.security_excellent');
    });

    test('returns excellent for score of 100', () {
      const score = SecurityScore(score: 100, factors: []);
      expect(score.levelKey, 'profile.security_excellent');
    });

    test('returns high for score >= 60 and < 80', () {
      const score = SecurityScore(score: 60, factors: []);
      expect(score.levelKey, 'profile.security_high');
    });

    test('returns high for score of 75', () {
      const score = SecurityScore(score: 75, factors: []);
      expect(score.levelKey, 'profile.security_high');
    });

    test('returns medium for score >= 40 and < 60', () {
      const score = SecurityScore(score: 40, factors: []);
      expect(score.levelKey, 'profile.security_medium');
    });

    test('returns medium for score of 55', () {
      const score = SecurityScore(score: 55, factors: []);
      expect(score.levelKey, 'profile.security_medium');
    });

    test('returns low for score < 40', () {
      const score = SecurityScore(score: 39, factors: []);
      expect(score.levelKey, 'profile.security_low');
    });

    test('returns low for score of 0', () {
      const score = SecurityScore(score: 0, factors: []);
      expect(score.levelKey, 'profile.security_low');
    });
  });

  group('AvatarUploadState', () {
    test('default state is not uploading, no error, not success', () {
      const state = AvatarUploadState();
      expect(state.isUploading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates isUploading', () {
      const state = AvatarUploadState();
      final updated = state.copyWith(isUploading: true);
      expect(updated.isUploading, isTrue);
      expect(updated.error, isNull);
      expect(updated.isSuccess, isFalse);
    });

    test('copyWith can set error', () {
      const state = AvatarUploadState();
      final updated = state.copyWith(error: 'Upload failed');
      expect(updated.error, 'Upload failed');
    });

    test('copyWith clears error when null is passed', () {
      const state = AvatarUploadState(error: 'Old error');
      final updated = state.copyWith(error: null);
      expect(updated.error, isNull);
    });

    test('copyWith can set isSuccess', () {
      const state = AvatarUploadState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });
  });

  group('AvatarUploadNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('initial state is not uploading', () {
      final state = container.read(avatarUploadStateProvider);
      expect(state.isUploading, isFalse);
    });
  });

  group('PasswordChangeState', () {
    test('default state has no error and is not loading', () {
      const state = PasswordChangeState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates isLoading', () {
      const state = PasswordChangeState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
    });

    test('copyWith updates error key', () {
      const state = PasswordChangeState();
      final updated = state.copyWith(error: 'password_incorrect');
      expect(updated.error, 'password_incorrect');
    });
  });

  group('PasswordChangeNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('initial state is not loading', () {
      final state = container.read(passwordChangeStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('reset clears state', () {
      container.read(passwordChangeStateProvider.notifier).reset();
      final state = container.read(passwordChangeStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });
}
