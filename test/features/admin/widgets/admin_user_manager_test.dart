import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_user_detail_content.dart';

import '../../../helpers/test_localization.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
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
      await pumpLocalizedApp(
        tester,
        _wrap(UserDetailProfileHeader(detail: _makeDetail())),
      );
      expect(find.byType(UserDetailProfileHeader), findsOneWidget);
    });

    testWidgets('shows user full name', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          UserDetailProfileHeader(detail: _makeDetail(fullName: 'Jane Doe')),
        ),
      );
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('shows email address', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          UserDetailProfileHeader(
            detail: _makeDetail(email: 'jane@example.com'),
          ),
        ),
      );
      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('shows no_name when fullName is null', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(UserDetailProfileHeader(detail: _makeDetail(fullName: null))),
      );
      expect(find.text(l10n('admin.no_name')), findsOneWidget);
    });

    testWidgets('shows CircleAvatar', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(UserDetailProfileHeader(detail: _makeDetail())),
      );
      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });

  group('UserDetailSubscriptionSection', () {
    testWidgets('renders without crashing for free user', (tester) async {
      await pumpLocalizedApp(
        tester,
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

    testWidgets('shows disabled premium access switch for free user', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'free'),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      final toggle = tester.widget<Switch>(
        find.byKey(const Key('admin_premium_access_switch')),
      );
      expect(toggle.value, isFalse);
    });

    testWidgets('shows enabled premium access switch for premium user', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'premium'),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      final toggle = tester.widget<Switch>(
        find.byKey(const Key('admin_premium_access_switch')),
      );
      expect(toggle.value, isTrue);
    });

    testWidgets('calls onGrantPremium when switch is enabled', (tester) async {
      var tapped = false;
      await pumpLocalizedApp(
        tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'free'),
            onGrantPremium: () => tapped = true,
            onRevokePremium: () {},
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('admin_premium_access_switch')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('calls onRevokePremium when switch is disabled', (
      tester,
    ) async {
      var tapped = false;
      await pumpLocalizedApp(
        tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'premium'),
            onGrantPremium: () {},
            onRevokePremium: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('admin_premium_access_switch')));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('shows subscription label', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(),
            onGrantPremium: () {},
            onRevokePremium: () {},
          ),
        ),
      );
      expect(find.text(l10n('admin.subscription')), findsOneWidget);
    });

    testWidgets(
      'hides premium access switch for founder/admin role-based premium',
      (tester) async {
        await pumpLocalizedApp(
          tester,
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
        expect(
          find.byKey(const Key('admin_premium_access_switch')),
          findsNothing,
        );
        expect(find.text(l10n('admin.role_based_premium')), findsOneWidget);
      },
    );

    testWidgets('shows progress and disables switch while action is loading', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _wrap(
          UserDetailSubscriptionSection(
            detail: _makeDetail(subscriptionPlan: 'free'),
            isActionLoading: true,
            onGrantPremium: () {},
          ),
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.byKey(const Key('admin_premium_access_switch')),
        findsNothing,
      );
    });
  });

  group('UserDetailStatsRow', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(UserDetailStatsRow(detail: _makeDetail(birdsCount: 10))),
      );
      expect(find.byType(UserDetailStatsRow), findsOneWidget);
    });

    testWidgets('shows birds count', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(UserDetailStatsRow(detail: _makeDetail(birdsCount: 7))),
      );
      expect(find.text('7'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows admin.birds label', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(UserDetailStatsRow(detail: _makeDetail())),
      );
      expect(find.text(l10n('admin.birds')), findsOneWidget);
    });

    testWidgets('shows events count label', (tester) async {
      await pumpLocalizedApp(
        tester,
        _wrap(UserDetailStatsRow(detail: _makeDetail())),
      );
      expect(find.text(l10n('admin.events_count')), findsOneWidget);
    });
  });

  group('UserDetailContent', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(
        tester,
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
      await pumpLocalizedApp(
        tester,
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
