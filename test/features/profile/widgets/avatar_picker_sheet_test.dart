import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/profile/widgets/avatar_picker_sheet.dart';

/// Helper widget to open the avatar picker sheet via button
class _TestScaffold extends ConsumerWidget {
  const _TestScaffold({required this.hasAvatar});

  final bool hasAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () =>
            showAvatarPickerSheet(context, ref: ref, hasAvatar: hasAvatar),
        child: const Text('Open'),
      ),
    );
  }
}

Future<void> _openSheet(WidgetTester tester, {bool hasAvatar = false}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(home: _TestScaffold(hasAvatar: hasAvatar)),
    ),
  );

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('showAvatarPickerSheet / _AvatarPickerContent', () {
    testWidgets('shows sheet title', (tester) async {
      await _openSheet(tester);

      expect(find.text('profile.edit_avatar'), findsOneWidget);
    });

    testWidgets('shows gallery option', (tester) async {
      await _openSheet(tester);

      expect(find.text('profile.avatar_source_gallery'), findsOneWidget);
    });

    testWidgets('shows camera option', (tester) async {
      await _openSheet(tester);

      expect(find.text('profile.avatar_source_camera'), findsOneWidget);
    });

    testWidgets('does not show remove option when hasAvatar is false', (
      tester,
    ) async {
      await _openSheet(tester, hasAvatar: false);

      expect(find.text('profile.avatar_remove'), findsNothing);
    });

    testWidgets('shows remove option when hasAvatar is true', (tester) async {
      await _openSheet(tester, hasAvatar: true);

      expect(find.text('profile.avatar_remove'), findsOneWidget);
    });

    testWidgets('shows exactly 2 ListTiles when no avatar', (tester) async {
      await _openSheet(tester, hasAvatar: false);

      // Gallery + Camera
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('shows 3 ListTiles when avatar exists', (tester) async {
      await _openSheet(tester, hasAvatar: true);

      // Gallery + Camera + Remove
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('sheet can be dismissed by tap outside', (tester) async {
      await _openSheet(tester, hasAvatar: false);

      // Tap outside the sheet to dismiss
      await tester.tapAt(const Offset(200, 50));
      await tester.pumpAndSettle();

      expect(find.text('profile.edit_avatar'), findsNothing);
    });
  });
}
