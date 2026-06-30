import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_timeline_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_timeline.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/test_localization.dart';

void main() {
  final bird = createTestBird();

  Future<void> pumpTimeline(
    WidgetTester tester,
    Widget child, {
    required List<BirdTimelineEvent> events,
  }) {
    return pumpLocalizedApp(
      tester,
      ProviderScope(
        overrides: [
          birdTimelineProvider.overrideWith((ref, b) => events),
          dateFormatProvider.overrideWith(() => DateFormatNotifier()),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  group('BirdDetailTimeline', () {
    testWidgets('renders nothing when there are no events', (tester) async {
      await pumpTimeline(
        tester,
        BirdDetailTimeline(bird: bird),
        events: const [],
      );

      expect(find.text('birds.timeline_title'), findsNothing);
    });

    testWidgets('shows one row per event with its title and date', (
      tester,
    ) async {
      final events = [
        BirdTimelineEvent(
          type: BirdTimelineEventType.registered,
          date: DateTime(2025, 1, 10),
          titleKey: 'birds.timeline_registered',
          iconAsset: AppIcons.bird,
        ),
        BirdTimelineEvent(
          type: BirdTimelineEventType.breeding,
          date: DateTime(2025, 3, 5),
          titleKey: 'birds.timeline_breeding_started',
          iconAsset: AppIcons.bird,
        ),
      ];

      await pumpTimeline(tester, BirdDetailTimeline(bird: bird), events: events);

      expect(find.text('birds.timeline_title'), findsOneWidget);
      expect(find.text('birds.timeline_registered'), findsOneWidget);
      expect(find.text('birds.timeline_breeding_started'), findsOneWidget);
    });
  });

  group('BirdDetailTimelineSection', () {
    testWidgets('renders nothing when there are no events', (tester) async {
      await pumpTimeline(
        tester,
        BirdDetailTimelineSection(bird: bird),
        events: const [],
      );

      expect(find.byType(Divider), findsNothing);
      expect(find.text('birds.timeline_title'), findsNothing);
    });

    testWidgets('shows a leading divider before the timeline content', (
      tester,
    ) async {
      final events = [
        BirdTimelineEvent(
          type: BirdTimelineEventType.registered,
          date: DateTime(2025, 1, 10),
          titleKey: 'birds.timeline_registered',
          iconAsset: AppIcons.bird,
        ),
      ];

      await pumpTimeline(
        tester,
        BirdDetailTimelineSection(bird: bird),
        events: events,
      );

      expect(find.byType(Divider), findsOneWidget);
      expect(find.text('birds.timeline_title'), findsOneWidget);
    });
  });
}
