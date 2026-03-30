import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_header.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_completion_indicator.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/avatar_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../helpers/test_localization.dart';

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

Future<void> _pumpHeader(
  WidgetTester tester, {
  Profile? profile,
  String displayName = 'Test User',
  String email = 'test@example.com',
  VoidCallback? onEditProfile,
  VoidCallback? onEditAvatar,
  bool isAvatarUploading = false,
  ProfileStats? stats,
  ProfileCompletion? completion,
  Duration? animationDuration,
}) async {
  await pumpLocalizedApp(
    tester,
    _buildSubject(
      profile: profile,
      displayName: displayName,
      email: email,
      onEditProfile: onEditProfile,
      onEditAvatar: onEditAvatar,
      isAvatarUploading: isAvatarUploading,
      stats: stats,
      completion: completion,
    ),
    settle: false,
  );
  if (animationDuration != null) {
    await tester.pump(animationDuration);
  }
}

void main() {
  group('ProfileHeader', () {
    testWidgets('renders without crashing', (tester) async {
      await _pumpHeader(tester);
      expect(find.byType(ProfileHeader), findsOneWidget);
    });

    testWidgets('displays display name', (tester) async {
      await _pumpHeader(tester, displayName: 'Bekir Demirci');
      expect(find.text('Bekir Demirci'), findsOneWidget);
    });

    testWidgets('displays email', (tester) async {
      await _pumpHeader(tester, email: 'bekir@test.com');
      expect(find.text('bekir@test.com'), findsOneWidget);
    });

    testWidgets('shows AvatarWidget', (tester) async {
      await _pumpHeader(tester);
      expect(find.byType(AvatarWidget), findsOneWidget);
    });

    testWidgets('shows ProfileCompletionIndicator', (tester) async {
      await _pumpHeader(tester, completion: _fakeCompletion(percentage: 0.75));
      expect(find.byType(ProfileCompletionIndicator), findsOneWidget);
    });

    testWidgets('edit profile button is present and tappable', (tester) async {
      bool tapped = false;
      await _pumpHeader(tester, onEditProfile: () => tapped = true);
      final editButton = find.byType(OutlinedButton);
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('camera icon button calls onEditAvatar', (tester) async {
      bool avatarTapped = false;
      await _pumpHeader(tester, onEditAvatar: () => avatarTapped = true);

      final cameraButton = find.ancestor(
        of: find.byIcon(LucideIcons.camera),
        matching: find.byType(InkWell),
      );
      expect(cameraButton, findsOneWidget);

      await tester.tap(cameraButton);
      await tester.pump();

      expect(avatarTapped, isTrue);
    });

    testWidgets('camera InkWell disabled when isAvatarUploading', (
      tester,
    ) async {
      bool avatarTapped = false;
      await _pumpHeader(
        tester,
        onEditAvatar: () => avatarTapped = true,
        isAvatarUploading: true,
      );

      final cameraInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.byIcon(LucideIcons.camera),
          matching: find.byType(InkWell),
        ),
      );
      expect(cameraInkWell.onTap, isNull);
      expect(avatarTapped, isFalse);
    });

    testWidgets('shows stats row when stats are provided', (tester) async {
      await _pumpHeader(
        tester,
        stats: _fakeStats(totalBirds: 7),
        animationDuration: const Duration(milliseconds: 1000),
      );
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('does not show stats row when stats is null', (tester) async {
      await _pumpHeader(tester, stats: null);
      expect(find.text(l10n('profile.total_birds_stat')), findsNothing);
    });

    testWidgets('shows premium badge for premium profile', (tester) async {
      final profile = _fakeProfile(isPremium: true);
      await _pumpHeader(tester, profile: profile);
      expect(find.text(l10n('profile.premium_badge')), findsOneWidget);
    });

    testWidgets('shows founder badge for founder profile', (tester) async {
      final profile = _fakeProfile(role: 'founder');
      await _pumpHeader(tester, profile: profile);
      expect(find.text(l10n('profile.founder_badge')), findsOneWidget);
    });

    testWidgets('shows admin badge for admin profile (not founder)', (
      tester,
    ) async {
      final profile = _fakeProfile(role: 'admin');
      await _pumpHeader(tester, profile: profile);
      expect(find.text(l10n('profile.admin_badge')), findsOneWidget);
    });

    testWidgets('does not show badges when profile has no special role', (
      tester,
    ) async {
      final profile = _fakeProfile();
      await _pumpHeader(tester, profile: profile);
      expect(find.text(l10n('profile.premium_badge')), findsNothing);
      expect(find.text(l10n('profile.founder_badge')), findsNothing);
      expect(find.text(l10n('profile.admin_badge')), findsNothing);
    });

    testWidgets('does not show badges when profile is null', (tester) async {
      await _pumpHeader(tester, profile: null);
      expect(find.text(l10n('profile.premium_badge')), findsNothing);
      expect(find.text(l10n('profile.founder_badge')), findsNothing);
    });

    testWidgets('stat items animate from 0 to final value', (tester) async {
      await _pumpHeader(
        tester,
        stats: _fakeStats(totalBirds: 3, totalPairs: 1),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text('3'), findsWidgets);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await _pumpHeader(tester);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('completion 0 renders without error', (tester) async {
      await _pumpHeader(tester, completion: _fakeCompletion(percentage: 0.0));
      expect(find.byType(ProfileHeader), findsOneWidget);
    });

    testWidgets('completion 1.0 renders without error', (tester) async {
      await _pumpHeader(tester, completion: _fakeCompletion(percentage: 1.0));
      expect(find.byType(ProfileHeader), findsOneWidget);
    });

    testWidgets('zero stats show 0 after animation', (tester) async {
      await _pumpHeader(
        tester,
        stats: const ProfileStats(
          totalBirds: 0,
          totalPairs: 0,
          totalEggs: 0,
          totalChicks: 0,
        ),
        animationDuration: const Duration(milliseconds: 1000),
      );
      final zeroFinders = tester.widgetList<Text>(find.text('0'));
      expect(zeroFinders.length, greaterThanOrEqualTo(4));
    });
  });
}
