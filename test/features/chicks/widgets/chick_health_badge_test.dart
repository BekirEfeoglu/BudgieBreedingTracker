import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_health_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ChickHealthBadge', () {
    testWidgets('renders without crashing for healthy status', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.healthy)),
      );
      await tester.pump();

      expect(find.byType(ChickHealthBadge), findsOneWidget);
    });

    testWidgets('shows healthy label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.healthy)),
      );
      await tester.pump();

      expect(find.text(l10n('chicks.status_healthy')), findsOneWidget);
    });

    testWidgets('shows sick label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.sick)),
      );
      await tester.pump();

      expect(find.text(l10n('chicks.status_sick')), findsOneWidget);
    });

    testWidgets('shows deceased label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.deceased)),
      );
      await tester.pump();

      expect(find.text(l10n('chicks.status_deceased')), findsOneWidget);
    });

    testWidgets('shows unknown label text', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.unknown)),
      );
      await tester.pump();

      expect(find.text(l10n('chicks.status_unknown')), findsOneWidget);
    });

    testWidgets('renders all status values without crashing', (tester) async {
      for (final status in ChickHealthStatus.values) {
        await tester.pumpWidget(_wrap(ChickHealthBadge(status: status)));
        await tester.pump();

        expect(find.byType(ChickHealthBadge), findsOneWidget);
      }
    });

    testWidgets('wraps a StatusBadge widget', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.healthy)),
      );
      await tester.pump();

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('healthy status uses success color', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.healthy)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.success);
    });

    testWidgets('sick status uses warning color', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.sick)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.warning);
    });

    testWidgets('deceased status uses error color', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.deceased)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.error);
    });

    testWidgets('unknown status uses genderUnknown color', (tester) async {
      await tester.pumpWidget(
        _wrap(const ChickHealthBadge(status: ChickHealthStatus.unknown)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.genderUnknown);
    });

    testWidgets('each status has a non-null icon', (tester) async {
      final expectedIconAssets = {
        ChickHealthStatus.healthy: AppIcons.health,
        ChickHealthStatus.sick: AppIcons.care,
      };

      for (final status in ChickHealthStatus.values) {
        await tester.pumpWidget(_wrap(ChickHealthBadge(status: status)));
        await tester.pump();

        final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
        if (expectedIconAssets.containsKey(status)) {
          expect(badge.icon, isA<AppIcon>());
          final appIcon = badge.icon! as AppIcon;
          expect(appIcon.asset, expectedIconAssets[status]);
        } else {
          expect(badge.icon, isA<Icon>());
        }
      }
    });
  });
}
