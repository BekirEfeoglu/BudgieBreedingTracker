import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_header.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/avatar_widget.dart';
import 'package:budgie_breeding_tracker/shared/providers/gamification.dart'
    as gamification;

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

gamification.EnrichedBadge _fakeUnlockedBadge({
  required String id,
  required String key,
  required String nameKey,
  gamification.BadgeCategory category = gamification.BadgeCategory.milestone,
  gamification.BadgeTier tier = gamification.BadgeTier.gold,
}) {
  return gamification.EnrichedBadge(
    badge: gamification.Badge(
      id: id,
      key: key,
      category: category,
      tier: tier,
      nameKey: nameKey,
      requirement: 1,
    ),
    userBadge: gamification.UserBadge(
      id: 'user-$id',
      userId: 'user-1',
      badgeId: id,
      isUnlocked: true,
      progress: 1,
    ),
  );
}

Widget _buildSubject({
  Profile? profile,
  String displayName = 'Test User',
  String email = 'test@example.com',
  VoidCallback? onEditProfile,
  VoidCallback? onEditAvatar,
  bool isAvatarUploading = false,
  ProfileStats? stats,
  gamification.UserLevel? userLevel,
  List<gamification.EnrichedBadge> unlockedBadges = const [],
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
          userLevel: userLevel,
          unlockedBadges: unlockedBadges,
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
  gamification.UserLevel? userLevel,
  List<gamification.EnrichedBadge> unlockedBadges = const [],
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
      userLevel: userLevel,
      unlockedBadges: unlockedBadges,
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

      final cameraButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == l10n('profile.edit_avatar'),
      );
      expect(cameraButton, findsOneWidget);

      await tester.tap(cameraButton);
      await tester.pump();

      expect(avatarTapped, isTrue);
    });

    testWidgets('camera button keeps a 48dp tap target', (tester) async {
      await _pumpHeader(tester);

      final cameraButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == l10n('profile.edit_avatar'),
      );

      expect(cameraButton, findsOneWidget);
      final size = tester.getSize(cameraButton);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('camera button disabled when isAvatarUploading', (
      tester,
    ) async {
      bool avatarTapped = false;
      await _pumpHeader(
        tester,
        onEditAvatar: () => avatarTapped = true,
        isAvatarUploading: true,
      );

      final cameraButton = tester.widget<IconButton>(
        find.byWidgetPredicate(
          (widget) =>
              widget is IconButton &&
              widget.tooltip == l10n('profile.edit_avatar'),
        ),
      );
      expect(cameraButton.onPressed, isNull);
      expect(avatarTapped, isFalse);
    });

    testWidgets('display name and email are constrained for long text', (
      tester,
    ) async {
      const longName = 'Very Long Profile Display Name For Overflow Testing';
      const longEmail = 'very.long.profile.email.address@example.test';

      await _pumpHeader(tester, displayName: longName, email: longEmail);

      final nameText = tester.widget<Text>(find.text(longName));
      final emailText = tester.widget<Text>(find.text(longEmail));

      expect(nameText.maxLines, 2);
      expect(nameText.overflow, TextOverflow.ellipsis);
      expect(emailText.maxLines, 1);
      expect(emailText.overflow, TextOverflow.ellipsis);
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

    testWidgets('shows gamification level and unlocked badges', (tester) async {
      const userLevel = gamification.UserLevel(
        id: 'level-1',
        userId: 'user-1',
        level: 100,
        title: 'gamification.title_bird_whisperer',
      );
      const unlockedBadges = [
        gamification.EnrichedBadge(
          badge: gamification.Badge(
            id: 'badge-1',
            key: 'first_bird',
            category: gamification.BadgeCategory.milestone,
            tier: gamification.BadgeTier.gold,
            nameKey: 'badges.first_bird',
            requirement: 1,
          ),
          userBadge: gamification.UserBadge(
            id: 'user-badge-1',
            userId: 'user-1',
            badgeId: 'badge-1',
            isUnlocked: true,
            progress: 1,
          ),
        ),
      ];

      await _pumpHeader(
        tester,
        userLevel: userLevel,
        unlockedBadges: unlockedBadges,
      );

      expect(
        find.textContaining('${l10n('community.level_prefix')}100'),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n('gamification.title_bird_whisperer')),
        findsOneWidget,
      );
      expect(find.text(l10n('badges.first_bird')), findsOneWidget);
    });

    testWidgets('prioritizes a compact profile badge summary', (tester) async {
      await _pumpHeader(
        tester,
        profile: _fakeProfile(isPremium: true, role: 'founder'),
        unlockedBadges: [
          _fakeUnlockedBadge(
            id: 'badge-1',
            key: 'first_bird',
            nameKey: 'badges.first_bird',
          ),
          _fakeUnlockedBadge(
            id: 'badge-2',
            key: 'verified_breeder',
            nameKey: 'badges.verified_breeder',
            category: gamification.BadgeCategory.special,
            tier: gamification.BadgeTier.platinum,
          ),
          _fakeUnlockedBadge(
            id: 'badge-3',
            key: 'one_year',
            nameKey: 'badges.one_year',
            tier: gamification.BadgeTier.gold,
          ),
        ],
      );

      expect(find.text(l10n('badges.verified_breeder')), findsOneWidget);
      expect(find.text(l10n('badges.first_bird')), findsNothing);
      expect(find.text(l10n('badges.one_year')), findsNothing);
      expect(find.text('+2'), findsOneWidget);
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
