import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_form_providers.dart';

import '../../../helpers/mocks.dart';

Profile _profile({String? avatarUrl}) =>
    Profile(id: 'user-1', email: 'test@example.com', avatarUrl: avatarUrl);

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockAuthActions mockAuthActions;

  setUpAll(() {
    registerFallbackValue(XFile('test.jpg'));
    registerFallbackValue(_profile());
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockAuthActions = MockAuthActions();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        authActionsProvider.overrideWithValue(mockAuthActions),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // ---------------------------------------------------------------------------
  // AvatarUploadNotifier
  // ---------------------------------------------------------------------------
  group('AvatarUploadNotifier', () {
    test('initial state has default values', () {
      final container = createContainer();
      final state = container.read(avatarUploadStateProvider);

      expect(state.isUploading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('uploadAvatar sets isUploading then isSuccess', () async {
      when(
        () => mockProfileRepo.uploadAvatar(
          userId: any(named: 'userId'),
          file: any(named: 'file'),
        ),
      ).thenAnswer((_) async {});

      final container = createContainer();
      final notifier = container.read(avatarUploadStateProvider.notifier);

      await notifier.uploadAvatar(XFile('photo.jpg'));

      final state = container.read(avatarUploadStateProvider);
      expect(state.isUploading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);

      verify(
        () => mockProfileRepo.uploadAvatar(
          userId: 'user-1',
          file: any(named: 'file'),
        ),
      ).called(1);
    });

    test('uploadAvatar sets error on failure', () async {
      when(
        () => mockProfileRepo.uploadAvatar(
          userId: any(named: 'userId'),
          file: any(named: 'file'),
        ),
      ).thenThrow(Exception('upload failed'));

      final container = createContainer();
      final notifier = container.read(avatarUploadStateProvider.notifier);

      await notifier.uploadAvatar(XFile('photo.jpg'));

      final state = container.read(avatarUploadStateProvider);
      expect(state.isUploading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, contains('upload failed'));
    });

    test('removeAvatar sets isUploading then isSuccess', () async {
      when(() => mockProfileRepo.removeAvatar(any())).thenAnswer((_) async {});

      final container = createContainer();
      final notifier = container.read(avatarUploadStateProvider.notifier);

      await notifier.removeAvatar();

      final state = container.read(avatarUploadStateProvider);
      expect(state.isUploading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);

      verify(() => mockProfileRepo.removeAvatar('user-1')).called(1);
    });

    test('removeAvatar sets error on failure', () async {
      when(
        () => mockProfileRepo.removeAvatar(any()),
      ).thenThrow(Exception('delete failed'));

      final container = createContainer();
      final notifier = container.read(avatarUploadStateProvider.notifier);

      await notifier.removeAvatar();

      final state = container.read(avatarUploadStateProvider);
      expect(state.isUploading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.error, contains('delete failed'));
    });

    test('reset clears state to defaults', () async {
      when(
        () => mockProfileRepo.uploadAvatar(
          userId: any(named: 'userId'),
          file: any(named: 'file'),
        ),
      ).thenThrow(Exception('fail'));

      final container = createContainer();
      final notifier = container.read(avatarUploadStateProvider.notifier);

      // Drive into an error state first
      await notifier.uploadAvatar(XFile('photo.jpg'));
      expect(container.read(avatarUploadStateProvider).error, isNotNull);

      notifier.reset();

      final state = container.read(avatarUploadStateProvider);
      expect(state.isUploading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // PasswordChangeNotifier
  // ---------------------------------------------------------------------------
  group('PasswordChangeNotifier', () {
    test('initial state has default values', () {
      final container = createContainer();
      final state = container.read(passwordChangeStateProvider);

      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('changePassword succeeds', () async {
      when(
        () => mockAuthActions.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});

      final container = createContainer();
      final notifier = container.read(passwordChangeStateProvider.notifier);

      await notifier.changePassword(
        currentPassword: 'old123',
        newPassword: 'new456',
      );

      final state = container.read(passwordChangeStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.error, isNull);

      verify(
        () => mockAuthActions.changePassword(
          currentPassword: 'old123',
          newPassword: 'new456',
        ),
      ).called(1);
    });

    test(
      'changePassword sets profile.password_incorrect on AuthException with invalid',
      () async {
        when(
          () => mockAuthActions.changePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenThrow(const AuthException('Invalid credentials'));

        final container = createContainer();
        final notifier = container.read(passwordChangeStateProvider.notifier);

        await notifier.changePassword(
          currentPassword: 'wrong',
          newPassword: 'new456',
        );

        final state = container.read(passwordChangeStateProvider);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.error, equals('profile.password_incorrect'));
      },
    );

    test(
      'changePassword sets profile.password_change_error on generic error',
      () async {
        when(
          () => mockAuthActions.changePassword(
            currentPassword: any(named: 'currentPassword'),
            newPassword: any(named: 'newPassword'),
          ),
        ).thenThrow(Exception('network error'));

        final container = createContainer();
        final notifier = container.read(passwordChangeStateProvider.notifier);

        await notifier.changePassword(
          currentPassword: 'old123',
          newPassword: 'new456',
        );

        final state = container.read(passwordChangeStateProvider);
        expect(state.isLoading, isFalse);
        expect(state.isSuccess, isFalse);
        expect(state.error, equals('profile.password_change_error'));
      },
    );

    test('reset clears state to defaults', () async {
      when(
        () => mockAuthActions.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenThrow(Exception('fail'));

      final container = createContainer();
      final notifier = container.read(passwordChangeStateProvider.notifier);

      // Drive into an error state first
      await notifier.changePassword(currentPassword: 'a', newPassword: 'b');
      expect(container.read(passwordChangeStateProvider).error, isNotNull);

      notifier.reset();

      final state = container.read(passwordChangeStateProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });
  });
}
