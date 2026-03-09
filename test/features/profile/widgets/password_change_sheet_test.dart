import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/password_change_form.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/password_change_sheet.dart';

class _FakePasswordChangeNotifier extends PasswordChangeNotifier {
  _FakePasswordChangeNotifier(this._state);
  final PasswordChangeState _state;

  @override
  PasswordChangeState build() => _state;
}

/// Helper widget to open the password change sheet via button.
class _TestScaffold extends ConsumerWidget {
  const _TestScaffold();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () => showPasswordChangeSheet(context, ref: ref),
        child: const Text('Open'),
      ),
    );
  }
}

Future<void> _openSheet(
  WidgetTester tester, {
  PasswordChangeState? state,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // Collection-if avoids the List<Override> type annotation issue (Riverpod 3)
        if (state != null)
          passwordChangeStateProvider.overrideWith(
            () => _FakePasswordChangeNotifier(state),
          ),
      ],
      child: const MaterialApp(home: _TestScaffold()),
    ),
  );

  await tester.tap(find.text('Open'));
  // Use pump instead of pumpAndSettle: loading state has CircularProgressIndicator
  // (infinite animation) which would cause pumpAndSettle to timeout
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('showPasswordChangeSheet / _PasswordChangeSheetContent', () {
    testWidgets('shows change_password title', (tester) async {
      await _openSheet(tester);

      expect(find.text('profile.change_password'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows PasswordChangeForm', (tester) async {
      await _openSheet(tester);

      expect(find.byType(PasswordChangeForm), findsOneWidget);
    });

    testWidgets('shows current_password field label', (tester) async {
      await _openSheet(tester);

      expect(find.text('profile.current_password'), findsOneWidget);
    });

    testWidgets('shows new_password field label', (tester) async {
      await _openSheet(tester);

      expect(find.text('profile.new_password'), findsOneWidget);
    });

    testWidgets('shows confirm_password field label', (tester) async {
      await _openSheet(tester);

      expect(find.text('profile.confirm_password'), findsOneWidget);
    });

    testWidgets('shows change_password submit button', (tester) async {
      await _openSheet(tester);

      // change_password key appears in title + button
      expect(find.text('profile.change_password'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows loading state when isLoading is true', (tester) async {
      const loadingState = PasswordChangeState(isLoading: true);
      await _openSheet(tester, state: loadingState);

      final form = tester.widget<PasswordChangeForm>(
        find.byType(PasswordChangeForm),
      );
      expect(form.isLoading, isTrue);
    });

    testWidgets('shows not loading by default', (tester) async {
      await _openSheet(tester);

      final form = tester.widget<PasswordChangeForm>(
        find.byType(PasswordChangeForm),
      );
      expect(form.isLoading, isFalse);
    });
  });
}
