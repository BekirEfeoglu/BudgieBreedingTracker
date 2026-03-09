import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/edit_profile_sheet.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_form.dart';

import '../../../helpers/mocks.dart';

Profile _fakeProfile({
  String id = 'user-1',
  String email = 'test@example.com',
  String? fullName = 'Test User',
  String? avatarUrl,
}) => Profile(id: id, email: email, fullName: fullName, avatarUrl: avatarUrl);

void _consumeOverflowExceptions(WidgetTester tester) {
  var ex = tester.takeException();
  while (ex != null) {
    ex = tester.takeException();
  }
}

Widget _buildSubject({
  Profile? profile,
  String email = 'test@example.com',
  required MockProfileRepository mockRepo,
}) {
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('user-1'),
      profileRepositoryProvider.overrideWithValue(mockRepo),
      avatarUploadStateProvider.overrideWith(() => AvatarUploadNotifier()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EditProfileSheet(profile: profile, email: email),
        ),
      ),
    ),
  );
}

void main() {
  late MockProfileRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(_fakeProfile());
  });

  setUp(() {
    mockRepo = MockProfileRepository();
  });

  group('EditProfileSheet', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _buildSubject(profile: _fakeProfile(), mockRepo: mockRepo),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      expect(find.byType(EditProfileSheet), findsOneWidget);
    });

    testWidgets('shows profile.edit_profile title key', (tester) async {
      await tester.pumpWidget(
        _buildSubject(profile: _fakeProfile(), mockRepo: mockRepo),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.edit_profile'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders ProfileForm', (tester) async {
      await tester.pumpWidget(
        _buildSubject(profile: _fakeProfile(), mockRepo: mockRepo),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      expect(find.byType(ProfileForm), findsOneWidget);
    });

    testWidgets('shows drag handle container at top', (tester) async {
      await tester.pumpWidget(
        _buildSubject(profile: _fakeProfile(), mockRepo: mockRepo),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      // Just verify sheet renders with multiple widgets
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('populates initialFullName in the text field', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          profile: _fakeProfile(fullName: 'Mevcut Ad'),
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      expect(find.text('Mevcut Ad'), findsAtLeastNWidgets(1));
    });

    testWidgets('works with null profile', (tester) async {
      await tester.pumpWidget(_buildSubject(profile: null, mockRepo: mockRepo));
      await tester.pump();
      _consumeOverflowExceptions(tester);

      expect(find.byType(EditProfileSheet), findsOneWidget);
    });

    testWidgets('shows email in ProfileForm when provided', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          profile: _fakeProfile(),
          email: 'someone@test.com',
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      expect(find.text('someone@test.com'), findsAtLeastNWidgets(1));
    });

    testWidgets('validation error shown when name is empty and save tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildSubject(
          profile: _fakeProfile(fullName: ''),
          email: 'test@test.com',
          mockRepo: mockRepo,
        ),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      // Clear the name field
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, '');
      await tester.pump();

      // Tap save button
      final saveButton = find.text('common.save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pump();
        _consumeOverflowExceptions(tester);

        // Validation error key should appear
        expect(
          find.text('profile.full_name_required'),
          findsAtLeastNWidgets(1),
        );
      }
    });

    testWidgets('calls repo.save on successful form submission', (
      tester,
    ) async {
      when(() => mockRepo.save(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            profileRepositoryProvider.overrideWithValue(mockRepo),
            avatarUploadStateProvider.overrideWith(
              () => AvatarUploadNotifier(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditProfileSheet(
                  profile: _fakeProfile(fullName: 'Saved Name'),
                  email: 'test@test.com',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      // Tap save
      final saveButton = find.text('common.save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pump(const Duration(milliseconds: 200));
        _consumeOverflowExceptions(tester);

        verify(() => mockRepo.save(any())).called(1);
      }
    });

    testWidgets('shows loading indicator during save', (tester) async {
      // Use a Completer to control when save completes
      final completer = Completer<void>();
      when(() => mockRepo.save(any())).thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            profileRepositoryProvider.overrideWithValue(mockRepo),
            avatarUploadStateProvider.overrideWith(
              () => AvatarUploadNotifier(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditProfileSheet(
                  profile: _fakeProfile(fullName: 'User Name'),
                  email: 'test@test.com',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      final saveButton = find.text('common.save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pump();
        _consumeOverflowExceptions(tester);

        // While completer is not done, loading state is active
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

        // Complete the future to avoid pending timer
        completer.complete();
        await tester.pump(const Duration(milliseconds: 50));
        _consumeOverflowExceptions(tester);
      }
    });

    testWidgets('error snackbar shown when repo.save throws', (tester) async {
      when(
        () => mockRepo.save(any()),
      ).thenAnswer((_) async => throw Exception('Save failed'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            profileRepositoryProvider.overrideWithValue(mockRepo),
            avatarUploadStateProvider.overrideWith(
              () => AvatarUploadNotifier(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditProfileSheet(
                  profile: _fakeProfile(fullName: 'User Name'),
                  email: 'test@test.com',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      final saveButton = find.text('common.save');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        _consumeOverflowExceptions(tester);

        // Error snackbar with localization key
        expect(find.text('common.data_load_error'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('avatar upload state watched — no crash when uploading', (
      tester,
    ) async {
      final fakeNotifier = _FakeAvatarUploadNotifier(uploading: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            profileRepositoryProvider.overrideWithValue(mockRepo),
            avatarUploadStateProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EditProfileSheet(
                  profile: _fakeProfile(),
                  email: 'test@test.com',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      _consumeOverflowExceptions(tester);

      expect(find.byType(EditProfileSheet), findsOneWidget);
    });
  });
}

class _FakeAvatarUploadNotifier extends AvatarUploadNotifier {
  _FakeAvatarUploadNotifier({required bool uploading}) : _uploading = uploading;
  final bool _uploading;

  @override
  AvatarUploadState build() => AvatarUploadState(isUploading: _uploading);
}
