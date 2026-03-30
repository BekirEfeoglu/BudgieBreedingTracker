import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/avatar_widget.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_form.dart';

Future<void> _pump(
  WidgetTester tester, {
  String? initialFullName,
  String? email,
  bool isLoading = false,
  Future<void> Function({required String fullName})? onSave,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileForm(
              initialFullName: initialFullName,
              email: email,
              isLoading: isLoading,
              onSave: onSave ?? ({required String fullName}) async {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProfileForm', () {
    testWidgets('renders without crashing', (tester) async {
      await _pump(tester);

      expect(find.byType(ProfileForm), findsOneWidget);
    });

    testWidgets('shows AvatarWidget', (tester) async {
      await _pump(tester);

      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('shows full name text field', (tester) async {
      await _pump(tester);

      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('full name field has profile.full_name label', (tester) async {
      await _pump(tester);

      expect(find.text(l10n('profile.full_name')), findsOneWidget);
    });

    testWidgets('shows email field when email is provided', (tester) async {
      await _pump(tester, email: 'test@example.com');

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('does not show email field when email is null', (tester) async {
      await _pump(tester, email: null);

      // Only one TextFormField (full name), no email field
      expect(find.text(l10n('profile.email')), findsNothing);
    });

    testWidgets('pre-fills full name from initialFullName', (tester) async {
      await _pump(tester, initialFullName: 'Ali Veli');

      final field = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(field.controller?.text, 'Ali Veli');
    });

    testWidgets('shows save button with common.save label', (tester) async {
      await _pump(tester);

      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text(l10n('common.save')), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (
      tester,
    ) async {
      await _pump(tester, isLoading: true);

      // PrimaryButton shows loading state
      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.isLoading, isTrue);
    });

    testWidgets('shows validation error when name is empty and save tapped', (
      tester,
    ) async {
      await _pump(tester, initialFullName: '');

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(find.text(l10n('profile.full_name_required')), findsOneWidget);
    });

    testWidgets('calls onSave with trimmed name when valid', (tester) async {
      String? savedName;
      await _pump(
        tester,
        initialFullName: '  Ali Veli  ',
        onSave: ({required String fullName}) async {
          savedName = fullName;
        },
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(savedName, 'Ali Veli');
    });

    testWidgets('does not call onSave when name is empty', (tester) async {
      var called = false;
      await _pump(
        tester,
        initialFullName: '',
        onSave: ({required String fullName}) async {
          called = true;
        },
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pump();

      expect(called, isFalse);
    });
  });
}
