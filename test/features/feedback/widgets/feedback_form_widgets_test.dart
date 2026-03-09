import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_category_selector.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_detail_sheet.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_device_info_section.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_history_card.dart';
import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';

// feedback_form_widgets.dart is a barrel export; this test verifies that all
// exported widgets are accessible and renderable.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('feedback_form_widgets barrel exports', () {
    testWidgets('FeedbackCategorySelector is accessible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackCategorySelector(
                selected: FeedbackCategory.bug,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedbackCategorySelector), findsOneWidget);
    });

    testWidgets('FeedbackDetailSheet is accessible', (tester) async {
      const entry = FeedbackEntry(
        id: 'barrel-test-1',
        category: FeedbackCategory.feature,
        subject: 'Barrel subject',
        message: 'Barrel message',
        status: FeedbackStatus.open,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackDetailSheet(
                entry: entry,
                scrollController: ScrollController(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
    });

    testWidgets('FeedbackDeviceInfoSection is accessible', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackDeviceInfoSection(
                deviceInfo: 'OS: Android\nVersion: 14',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedbackDeviceInfoSection), findsOneWidget);
    });

    testWidgets('FeedbackHistoryCard is accessible', (tester) async {
      final entry = FeedbackEntry(
        id: 'barrel-test-2',
        category: FeedbackCategory.general,
        subject: 'Barrel card subject',
        message: 'Barrel card message',
        status: FeedbackStatus.resolved,
        createdAt: DateTime(2024, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: FeedbackHistoryCard(entry: entry)),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedbackHistoryCard), findsOneWidget);
    });

    testWidgets('FeedbackStatusBadge is accessible from detail_sheet export', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackStatusBadge(status: FeedbackStatus.closed),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedbackStatusBadge), findsOneWidget);
    });
  });
}
