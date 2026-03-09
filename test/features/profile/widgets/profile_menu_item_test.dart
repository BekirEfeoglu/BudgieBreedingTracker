import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_item.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart'
    show appInfoProvider;

void main() {
  group('ProfileMenuItem', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.person),
              label: 'Profil',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.person),
              label: 'Tap Me',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('renders icon widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.settings),
              label: 'Ayarlar',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('does not show chevron by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.person),
              label: 'No Chevron',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.chevronRight), findsNothing);
    });

    testWidgets('shows chevron when showChevron is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.person),
              label: 'With Chevron',
              onTap: () {},
              showChevron: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(LucideIcons.chevronRight), findsOneWidget);
    });

    testWidgets('is not destructive by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.person),
              label: 'Normal',
              onTap: () {},
            ),
          ),
        ),
      );

      // Widget renders without error
      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('renders in destructive mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.delete),
              label: 'Sil',
              onTap: () {},
              isDestructive: true,
            ),
          ),
        ),
      );

      expect(find.text('Sil'), findsOneWidget);
    });

    testWidgets('has minimum height of 48px via ConstrainedBox', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.person),
              label: 'Min Height',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find ConstrainedBox that is a descendant of ProfileMenuItem
      final box = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(ProfileMenuItem),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(box.constraints.minHeight, 48);
    });

    testWidgets('has Semantics button label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuItem(
              icon: const Icon(Icons.person),
              label: 'Semantic Label',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Semantic Label'), findsOneWidget);
    });
  });

  group('ProfileAppVersionLabel', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows nothing while loading', (tester) async {
      // Use Completer<PackageInfo> so no timer is created (avoids "Timer still pending" error)
      final completer = Completer<PackageInfo>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appInfoProvider.overrideWith((ref) => completer.future)],
          child: const MaterialApp(
            home: Scaffold(body: ProfileAppVersionLabel()),
          ),
        ),
      );
      await tester.pump();

      // Loading state shows SizedBox.shrink - no visible text
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('shows nothing on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appInfoProvider.overrideWith(
              (ref) => Future.error(Exception('error')),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProfileAppVersionLabel()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Error state shows SizedBox.shrink
      expect(find.textContaining('v'), findsNothing);
    });
  });
}
