import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_user_detail_content.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

AdminUserDetail _makeDetail({
  String id = 'uid-1',
  String email = 'test@example.com',
  String? fullName = 'Test User',
  bool isActive = true,
  String subscriptionPlan = 'free',
  String subscriptionStatus = 'active',
  int birdsCount = 5,
  List<AdminLog> activityLogs = const [],
}) => AdminUserDetail(
  id: id,
  email: email,
  fullName: fullName,
  createdAt: DateTime(2024, 1, 15),
  isActive: isActive,
  subscriptionPlan: subscriptionPlan,
  subscriptionStatus: subscriptionStatus,
  birdsCount: birdsCount,
  activityLogs: activityLogs,
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('tr');
  });

  group('UserDetailProfileHeader', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(UserDetailProfileHeader(detail: _makeDetail())),
      );
      expect(find.byType(UserDetailProfileHeader), findsOneWidget);
    });

    testWidgets('shows user full name', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailProfileHeader(detail: _makeDetail(fullName: 'Jane Doe')),
        ),
      );
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('shows email address', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailProfileHeader(
            detail: _makeDetail(email: 'jane@example.com'),
          ),
        ),
      );
      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('shows no_name when fullName is null', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(UserDetailProfileHeader(detail: _makeDetail(fullName: null))),
      );
      expect(find.text('admin.no_name'), findsOneWidget);
    });

    testWidgets('shows CircleAvatar', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(UserDetailProfileHeader(detail: _makeDetail())),
      );
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });

  group('UserDetailSubscriptionSection', () {
    testWidgets('renders without crashing for free user', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      expect(find.byType(UserDetailSubscriptionSection), findsOneWidget);
    });

    testWidgets('shows grant_premium button for free user', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'free'),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      expect(find.text('admin.grant_premium'), findsOneWidget);
    });

    testWidgets('shows revoke_premium button for premium user', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'premium'),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      expect(find.text('admin.revoke_premium'), findsOneWidget);
    });

    testWidgets('calls onGrantPremium when grant button tapped', (
      tester,
    ) async {
      var tapped = false;
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'free'),
            onGrantPremium: () => tapped = true,
            onRevokePremium: () {},
          ),
        ),
      );
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onRevokePremium when revoke button tapped', (
      tester,
    ) async {
      var tapped = false;
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'premium'),
            onGrantPremium: () {},
            onRevokePremium: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows subscription label', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      expect(find.text('admin.subscription'), findsOneWidget);
    });

    testWidgets(
      'hides premium action buttons for founder/admin role-based premium',
      (tester) async {
        await pumpLocalizedApp(tester,
          _wrap(
            UserDetailSubscriptionSection(
              detail: _makeDetail(
                subscriptionPlan: 'premium',
                subscriptionStatus: 'founder',
              ),
              onGrantPremium: () {},
              onRevokePremium: () {},
            ),
          ),
        );
        expect(find.byType(FilledButton), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
        expect(find.text('admin.role_based_premium'), findsOneWidget);
      },
    );
  });

  group('UserDetailStatsRow', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(UserDetailStatsRow(detail: _makeDetail(birdsCount: 10))),
      );
      expect(find.byType(UserDetailStatsRow), findsOneWidget);
    });

    testWidgets('shows birds count', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(UserDetailStatsRow(detail: _makeDetail(birdsCount: 7))),
      );
      expect(find.text('7'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows admin.birds label', (tester) async {
      await pumpLocalizedApp(tester,_wrap(UserDetailStatsRow(detail: _makeDetail())));
      expect(find.text('admin.birds'), findsOneWidget);
    });

    testWidgets('shows activity log count', (tester) async {
      final logs = [
        AdminLog(id: 'l1', action: 'login', createdAt: DateTime(2024, 1, 1)),
        AdminLog(id: 'l2', action: 'update', createdAt: DateTime(2024, 1, 2)),
      ];

      await pumpLocalizedApp(tester,
        _wrap(UserDetailStatsRow(detail: _makeDetail(activityLogs: logs))),
      );
      expect(find.text('2'), findsAtLeastNWidgets(1));
    });
  });

  group('UserDetailContent', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailContent(
            detail: _makeDetail(),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      expect(find.byType(UserDetailContent), findsOneWidget);
    });

    testWidgets('shows profile header', (tester) async {
      await pumpLocalizedApp(tester,
        _wrap(
          UserDetailContent(
            detail: _makeDetail(),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      expect(find.byType(UserDetailProfileHeader), findsOneWidget);
    });
  });
}
