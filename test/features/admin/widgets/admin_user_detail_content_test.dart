import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_user_detail_content.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_user_detail_sections.dart';

final _freeUserDetail = AdminUserDetail(
  id: 'user-1',
  email: 'test@example.com',
  fullName: 'Test User',
  createdAt: DateTime(2024, 1, 15),
  isActive: true,
  subscriptionPlan: 'free',
  subscriptionStatus: 'free',
  birdsCount: 10,
  activityLogs: [],
);

final _premiumUserDetail = AdminUserDetail(
  id: 'user-2',
  email: 'premium@example.com',
  fullName: 'Premium User',
  createdAt: DateTime(2024, 2, 20),
  isActive: true,
  subscriptionPlan: 'premium',
  subscriptionStatus: 'active',
  subscriptionUpdatedAt: DateTime(2024, 6, 1, 10, 30),
  birdsCount: 50,
  activityLogs: [
    AdminLog(
      id: 'log-1',
      action: 'premium_granted',
      createdAt: DateTime(2024, 2, 20, 10, 0),
    ),
  ],
);

final _founderUserDetail = AdminUserDetail(
  id: 'user-3',
  email: 'founder@example.com',
  fullName: 'Founder User',
  createdAt: DateTime(2023, 1, 1),
  isActive: true,
  subscriptionPlan: 'premium',
  subscriptionStatus: 'founder',
  birdsCount: 100,
  activityLogs: [],
);

final _adminUserDetail = AdminUserDetail(
  id: 'user-4',
  email: 'admin@example.com',
  fullName: 'Admin User',
  createdAt: DateTime(2023, 6, 15),
  isActive: true,
  subscriptionPlan: 'premium',
  subscriptionStatus: 'admin',
  birdsCount: 75,
  activityLogs: [],
);

final _noNameUserDetail = AdminUserDetail(
  id: 'user-5',
  email: 'noname@example.com',
  createdAt: DateTime(2024, 5, 1),
  isActive: true,
  birdsCount: 0,
  activityLogs: [],
);

final _trialUserDetail = AdminUserDetail(
  id: 'user-7',
  email: 'trial@example.com',
  fullName: 'Trial User',
  createdAt: DateTime(2024, 4, 1),
  isActive: true,
  subscriptionPlan: 'free',
  subscriptionStatus: 'trial',
  birdsCount: 3,
  activityLogs: [],
);

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('UserDetailContent', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailContent(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(UserDetailContent), findsOneWidget);
    });

    testWidgets('shows UserDetailProfileHeader', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailContent(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(UserDetailProfileHeader), findsOneWidget);
    });

    testWidgets('shows UserDetailSubscriptionSection', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailContent(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(UserDetailSubscriptionSection), findsOneWidget);
    });

    testWidgets('shows UserDetailStatsRow', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailContent(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(UserDetailStatsRow), findsOneWidget);
    });

    testWidgets('shows UserDetailActivityLogSection', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailContent(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(UserDetailActivityLogSection), findsOneWidget);
    });

    testWidgets('renders SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailContent(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('UserDetailProfileHeader', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailProfileHeader(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(UserDetailProfileHeader), findsOneWidget);
    });

    testWidgets('shows full name', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailProfileHeader(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows email', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailProfileHeader(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('shows no_name when fullName is null', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailProfileHeader(detail: _noNameUserDetail)),
      );
      await tester.pump();
      expect(find.text('admin.no_name'), findsOneWidget);
    });

    testWidgets('shows joined date text', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailProfileHeader(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.textContaining('admin.joined'), findsOneWidget);
    });

    testWidgets('renders CircleAvatar', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailProfileHeader(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailProfileHeader(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('UserDetailSubscriptionSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(UserDetailSubscriptionSection), findsOneWidget);
    });

    testWidgets('shows subscription title', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.text('admin.subscription'), findsOneWidget);
    });

    testWidgets('shows free plan label for free user', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.text('premium.free'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows pro plan label for premium user', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _premiumUserDetail)),
      );
      await tester.pump();
      expect(find.text('premium.pro'), findsOneWidget);
    });

    testWidgets('shows active status for premium user', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _premiumUserDetail)),
      );
      await tester.pump();
      expect(find.text('common.active'), findsOneWidget);
    });

    testWidgets('shows revoke_premium button for premium user', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          UserDetailSubscriptionSection(
            detail: _premiumUserDetail,
            onRevokePremium: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('admin.revoke_premium'), findsOneWidget);
    });

    testWidgets('shows grant_premium button for free user', (tester) async {
      await tester.pumpWidget(
        _wrap(
          UserDetailSubscriptionSection(
            detail: _freeUserDetail,
            onGrantPremium: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('admin.grant_premium'), findsOneWidget);
    });

    testWidgets('triggers onGrantPremium callback', (tester) async {
      var granted = false;
      await tester.pumpWidget(
        _wrap(
          UserDetailSubscriptionSection(
            detail: _freeUserDetail,
            onGrantPremium: () => granted = true,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('admin.grant_premium'));
      expect(granted, isTrue);
    });

    testWidgets('triggers onRevokePremium callback', (tester) async {
      var revoked = false;
      await tester.pumpWidget(
        _wrap(
          UserDetailSubscriptionSection(
            detail: _premiumUserDetail,
            onRevokePremium: () => revoked = true,
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('admin.revoke_premium'));
      expect(revoked, isTrue);
    });

    testWidgets('shows role_based_premium text for founder', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _founderUserDetail)),
      );
      await tester.pump();
      expect(find.text('admin.role_based_premium'), findsOneWidget);
    });

    testWidgets('shows role_based_premium text for admin', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _adminUserDetail)),
      );
      await tester.pump();
      expect(find.text('admin.role_based_premium'), findsOneWidget);
    });

    testWidgets('hides grant/revoke buttons for founder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          UserDetailSubscriptionSection(
            detail: _founderUserDetail,
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.text('admin.grant_premium'), findsNothing);
      expect(find.text('admin.revoke_premium'), findsNothing);
    });

    testWidgets('shows founder status label for founder user', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _founderUserDetail)),
      );
      await tester.pump();
      expect(find.text('profile.role_founder'), findsOneWidget);
    });

    testWidgets('shows admin status label for admin user', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _adminUserDetail)),
      );
      await tester.pump();
      expect(find.text('profile.role_admin'), findsOneWidget);
    });

    testWidgets('shows trial badge for trial user', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _trialUserDetail)),
      );
      await tester.pump();
      expect(find.text('premium.trial_badge'), findsOneWidget);
    });

    testWidgets('shows subscription_updated when date is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _premiumUserDetail)),
      );
      await tester.pump();
      expect(
        find.textContaining('admin.subscription_updated'),
        findsOneWidget,
      );
    });

    testWidgets('hides subscription_updated when date is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.textContaining('admin.subscription_updated'), findsNothing);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailSubscriptionSection(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('UserDetailStatsRow', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailStatsRow(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(UserDetailStatsRow), findsOneWidget);
    });

    testWidgets('shows birds count', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailStatsRow(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('shows activity logs count', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailStatsRow(detail: _premiumUserDetail)),
      );
      await tester.pump();
      // premiumUserDetail has 1 activity log
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows birds label', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailStatsRow(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.text('admin.birds'), findsOneWidget);
    });

    testWidgets('shows log_entries label', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailStatsRow(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.text('admin.log_entries'), findsOneWidget);
    });

    testWidgets('renders two Card widgets for stats', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailStatsRow(detail: _freeUserDetail)),
      );
      await tester.pump();
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('shows zero for user with no birds', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailStatsRow(detail: _noNameUserDetail)),
      );
      await tester.pump();
      expect(find.text('0'), findsAtLeastNWidgets(1));
    });
  });
}
