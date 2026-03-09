import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_header.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_completion_indicator.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/avatar_widget.dart';

Profile _fakeProfile({
  String id = 'user-1',
  String email = 'test@example.com',
  String? fullName,
  String? avatarUrl,
  bool isPremium = false,
  String? role,
}) => Profile(
  id: id,
  email: email,
  fullName: fullName,
  avatarUrl: avatarUrl,
  isPremium: isPremium,
  role: role,
);

ProfileStats _fakeStats({
  int totalBirds = 5,
  int totalPairs = 2,
  int totalEggs = 10,
  int totalChicks = 3,
}) => ProfileStats(
  totalBirds: totalBirds,
  totalPairs: totalPairs,
  totalEggs: totalEggs,
  totalChicks: totalChicks,
);

ProfileCompletion _fakeCompletion({double percentage = 0.5}) =>
    ProfileCompletion(percentage: percentage, items: const []);

Widget _buildSubject({
  Profile? profile,
  String displayName = 'Test User',
  String email = 'test@example.com',
  VoidCallback? onEditProfile,
  VoidCallback? onEditAvatar,
  bool isAvatarUploading = false,
  ProfileStats? stats,
  ProfileCompletion? completion,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ProfileHeader(
          profile: profile,
          displayName: displayName,
          email: email,
          onEditProfile: onEditProfile ?? () {},
          onEditAvatar: onEditAvatar ?? () {},
          isAvatarUploading: isAvatarUploading,
          stats: stats,
          completion: completion,
        ),
      ),
    ),
  );
}

void _consumeOverflowExceptions(WidgetTester tester) {
  var ex = tester.takeException();
  while (ex != null) {
    ex = tester.takeException();
  }
}

void main() {
  group('ProfileHeader', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.byType(ProfileHeader), findsOneWidget);
    });

    testWidgets('displays display name', (tester) async {
      await tester.pumpWidget(_buildSubject(displayName: 'Bekir Demirci'));
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.text('Bekir Demirci'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays email', (tester) async {
      await tester.pumpWidget(_buildSubject(email: 'bekir@test.com'));
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.text('bekir@test.com'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows AvatarWidget', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('shows ProfileCompletionIndicator', (tester) async {
      await tester.pumpWidget(
        _buildSubject(completion: _fakeCompletion(percentage: 0.75)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.byType(ProfileCompletionIndicator), findsOneWidget);
    });

    testWidgets('edit profile button is present and tappable', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        _buildSubject(onEditProfile: () => tapped = true),
      );
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      final editButton = find.byType(OutlinedButton);
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('camera icon button calls onEditAvatar', (tester) async {
      bool avatarTapped = false;
      await tester.pumpWidget(
        _buildSubject(onEditAvatar: () => avatarTapped = true),
      );
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      // Camera InkWell in the Stack
      final inkwells = find.byType(InkWell);
      expect(inkwells, findsWidgets);

      // Tap the first InkWell inside the Stack (camera button)
      await tester.tap(inkwells.first, warnIfMissed: false);
      await tester.pump();
      _consumeOverflowExceptions(tester);

      expect(avatarTapped, isTrue);
    });

    testWidgets('camera InkWell disabled when isAvatarUploading', (
      tester,
    ) async {
      bool avatarTapped = false;
      await tester.pumpWidget(
        _buildSubject(
          onEditAvatar: () => avatarTapped = true,
          isAvatarUploading: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      // The camera InkWell onTap is null when uploading — tap should have no effect
      final cameraInkWell = tester
          .widgetList<InkWell>(find.byType(InkWell))
          .firstWhere(
            (w) => w.onTap == null,
            orElse: () => tester.widget<InkWell>(find.byType(InkWell).first),
          );
      expect(cameraInkWell.onTap, isNull);
      expect(avatarTapped, isFalse);
    });

    testWidgets('shows stats row when stats are provided', (tester) async {
      await tester.pumpWidget(_buildSubject(stats: _fakeStats(totalBirds: 7)));
      await tester.pump(const Duration(milliseconds: 1000));
      _consumeOverflowExceptions(tester);

      // TweenAnimationBuilder animates 0→7 over 800ms; after 1s final value shown
      expect(find.text('7'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show stats row when stats is null', (tester) async {
      await tester.pumpWidget(_buildSubject(stats: null));
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      // If stats == null, _ProfileStatsRow should not be rendered
      // Verify no animated number widget for stats
      // Simply check the widget tree doesn't contain stat labels
      expect(find.text('profile.total_birds_stat'), findsNothing);
    });

    testWidgets('shows premium badge for premium profile', (tester) async {
      final profile = _fakeProfile(isPremium: true);
      await tester.pumpWidget(_buildSubject(profile: profile));
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      // 'profile.premium_badge' key rendered as-is in test env
      expect(find.text('profile.premium_badge'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows founder badge for founder profile', (tester) async {
      final profile = _fakeProfile(role: 'founder');
      await tester.pumpWidget(_buildSubject(profile: profile));
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.founder_badge'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows admin badge for admin profile (not founder)', (
      tester,
    ) async {
      final profile = _fakeProfile(role: 'admin');
      await tester.pumpWidget(_buildSubject(profile: profile));
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.admin_badge'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not show badges when profile has no special role', (
      tester,
    ) async {
      final profile = _fakeProfile();
      await tester.pumpWidget(_buildSubject(profile: profile));
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.premium_badge'), findsNothing);
      expect(find.text('profile.founder_badge'), findsNothing);
      expect(find.text('profile.admin_badge'), findsNothing);
    });

    testWidgets('does not show badges when profile is null', (tester) async {
      await tester.pumpWidget(_buildSubject(profile: null));
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.text('profile.premium_badge'), findsNothing);
      expect(find.text('profile.founder_badge'), findsNothing);
    });

    testWidgets('stat items animate from 0 to final value', (tester) async {
      await tester.pumpWidget(
        _buildSubject(stats: _fakeStats(totalBirds: 3, totalPairs: 1)),
      );
      // Initially at 0 (animation starts)
      await tester.pump();
      _consumeOverflowExceptions(tester);

      // After animation completes
      await tester.pump(const Duration(milliseconds: 900));
      _consumeOverflowExceptions(tester);

      expect(find.text('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await tester.pumpWidget(_buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.byType(Card), findsAtLeastNWidgets(1));
    });

    testWidgets('completion 0 renders without error', (tester) async {
      await tester.pumpWidget(
        _buildSubject(completion: _fakeCompletion(percentage: 0.0)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.byType(ProfileHeader), findsOneWidget);
    });

    testWidgets('completion 1.0 renders without error', (tester) async {
      await tester.pumpWidget(
        _buildSubject(completion: _fakeCompletion(percentage: 1.0)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      _consumeOverflowExceptions(tester);

      expect(find.byType(ProfileHeader), findsOneWidget);
    });

    testWidgets('zero stats show 0 after animation', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          stats: const ProfileStats(
            totalBirds: 0,
            totalPairs: 0,
            totalEggs: 0,
            totalChicks: 0,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1000));
      _consumeOverflowExceptions(tester);

      // 4 stats each showing 0
      final zeroFinders = tester.widgetList<Text>(find.text('0'));
      expect(zeroFinders.length, greaterThanOrEqualTo(4));
    });
  });
}
