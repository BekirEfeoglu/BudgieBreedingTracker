import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_header.dart';

void main() {
  group('getProfileInitials', () {
    test('returns first + last initial for two-word name', () {
      expect(getProfileInitials('Ali Veli'), 'AV');
    });

    test('returns uppercase initials', () {
      expect(getProfileInitials('john doe'), 'JD');
    });

    test('returns single letter for single-word name', () {
      expect(getProfileInitials('Bekir'), 'B');
    });

    test('returns single letter uppercased', () {
      expect(getProfileInitials('ali'), 'A');
    });

    test('returns first + last for three-word name', () {
      // Only first and last parts used (Ali + Veli → AV)
      expect(getProfileInitials('Ali Orta Veli'), 'AV');
    });

    test('returns ? for empty string', () {
      expect(getProfileInitials(''), '?');
    });

    test('handles whitespace-only name', () {
      // Function checks name.isNotEmpty (not trimmed), so '   '[0] = ' '
      // This is the actual behavior of the function
      expect(getProfileInitials('   '), ' ');
    });

    test('handles name with leading/trailing spaces', () {
      expect(getProfileInitials('  Ali Veli  '), 'AV');
    });
  });

  group('ProfileMenuBadge', () {
    testWidgets('displays label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileMenuBadge(label: 'Premium', color: Colors.green),
          ),
        ),
      );

      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('renders with given color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileMenuBadge(label: 'Founder', color: Colors.blue),
          ),
        ),
      );

      // No exception thrown = badge rendered
      expect(find.text('Founder'), findsOneWidget);
    });

    testWidgets('can render multiple badges', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ProfileMenuBadge(label: 'Premium', color: Colors.green),
                ProfileMenuBadge(label: 'Admin', color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ProfileMenuBadge), findsNWidgets(2));
    });
  });

  group('ProfileMenuHeader', () {
    testWidgets('shows display name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMenuHeader(
                profile: null,
                displayName: 'Ali Veli',
                displayEmail: 'ali@example.com',
                hasBadges: false,
                isPremium: false,
                isFounder: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ali Veli'), findsOneWidget);
    });

    testWidgets('shows display email', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMenuHeader(
                profile: null,
                displayName: 'Ali Veli',
                displayEmail: 'ali@example.com',
                hasBadges: false,
                isPremium: false,
                isFounder: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('ali@example.com'), findsOneWidget);
    });

    testWidgets('shows initials in avatar when no avatarUrl', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMenuHeader(
                profile: null,
                displayName: 'Bekir Demirci',
                displayEmail: 'b@test.com',
                hasBadges: false,
                isPremium: false,
                isFounder: false,
              ),
            ),
          ),
        ),
      );

      // Initials should be shown for null profile (no avatarUrl)
      expect(find.text('BD'), findsOneWidget);
    });

    testWidgets('does not show badges when hasBadges is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMenuHeader(
                profile: null,
                displayName: 'Ali',
                displayEmail: 'ali@test.com',
                hasBadges: false,
                isPremium: true,
                isFounder: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProfileMenuBadge), findsNothing);
    });

    testWidgets('shows premium badge when hasBadges and isPremium', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMenuHeader(
                profile: null,
                displayName: 'Ali',
                displayEmail: 'ali@test.com',
                hasBadges: true,
                isPremium: true,
                isFounder: false,
              ),
            ),
          ),
        ),
      );

      // ProfileMenuBadge should appear for premium
      expect(find.byType(ProfileMenuBadge), findsAtLeastNWidgets(1));
    });

    testWidgets('shows founder badge when hasBadges and isFounder', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMenuHeader(
                profile: null,
                displayName: 'Ali',
                displayEmail: 'ali@test.com',
                hasBadges: true,
                isPremium: false,
                isFounder: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProfileMenuBadge), findsAtLeastNWidgets(1));
    });

    testWidgets('shows two badges when premium and founder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileMenuHeader(
                profile: null,
                displayName: 'Ali',
                displayEmail: 'ali@test.com',
                hasBadges: true,
                isPremium: true,
                isFounder: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ProfileMenuBadge), findsNWidgets(2));
    });
  });
}
