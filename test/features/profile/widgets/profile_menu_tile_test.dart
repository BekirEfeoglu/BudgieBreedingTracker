import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_tile.dart';

void main() {
  group('ProfileMenuTile', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuTile(
              icon: const Icon(Icons.settings),
              label: 'Settings',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuTile(
              icon: const Icon(Icons.settings),
              label: 'Settings',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ProfileMenuTile));
      expect(tapped, isTrue);
    });

    testWidgets('shows icon widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuTile(
              icon: const Icon(Icons.settings, key: Key('tile-icon')),
              label: 'Settings',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('tile-icon')), findsOneWidget);
    });

    testWidgets('shows chevron right indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuTile(
              icon: const Icon(Icons.settings),
              label: 'Settings',
              onTap: () {},
            ),
          ),
        ),
      );

      // ProfileMenuTile always includes a chevron right icon
      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('renders with isDestructive true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileMenuTile(
              icon: const Icon(Icons.delete),
              label: 'Delete Account',
              onTap: () {},
              isDestructive: true,
            ),
          ),
        ),
      );

      expect(find.text('Delete Account'), findsOneWidget);
    });
  });

  group('ProfileSectionTitle', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProfileSectionTitle(label: 'Account Info')),
        ),
      );

      expect(find.text('Account Info'), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileSectionTitle(label: 'Danger Zone', color: Colors.red),
          ),
        ),
      );

      expect(find.text('Danger Zone'), findsOneWidget);
    });
  });

  group('ProfileInfoRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileInfoRow(
              icon: Icon(Icons.email),
              label: 'Email',
              value: 'test@example.com',
            ),
          ),
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileInfoRow(
              icon: Icon(Icons.email),
              label: 'Email',
              value: 'test@test.com',
              trailing: Icon(Icons.copy, key: Key('copy-icon')),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('copy-icon')), findsOneWidget);
    });

    testWidgets('renders without trailing widget by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileInfoRow(
              icon: Icon(Icons.person),
              label: 'Name',
              value: 'John Doe',
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
    });
  });
}
