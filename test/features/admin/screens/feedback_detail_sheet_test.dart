import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/screens/_feedback_detail_sheet.dart';

void main() {
  final sampleItem = <String, dynamic>{
    'id': 'f-1',
    'type': 'bug',
    'status': 'open',
    'priority': 'high',
    'subject': 'App crashes on startup',
    'message': 'When I open the app it crashes immediately.',
    'email': 'user@test.com',
    'platform': 'android',
    'app_version': '2.1.0',
    'admin_response': 'Looking into it',
  };

  Future<void> pumpSheet(
    WidgetTester tester, {
    Map<String, dynamic>? item,
    FeedbackSaveCallback? onSave,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Immediately show bottom sheet after build.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => FeedbackDetailSheet(
                    item: item ?? sampleItem,
                    onSave: onSave ??
                        ({
                          required String status,
                          String? adminResponse,
                          required String priority,
                        }) async {},
                  ),
                );
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    // First pump triggers the post-frame callback to show the sheet.
    await tester.pump();
    // Second pump lets the sheet animation begin.
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('FeedbackDetailSheet', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpSheet(tester);

      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
    });

    testWidgets('shows title', (tester) async {
      await pumpSheet(tester);

      expect(find.text(l10n('admin.feedback_detail')), findsOneWidget);
    });

    testWidgets('displays subject info row', (tester) async {
      await pumpSheet(tester);

      expect(find.text('App crashes on startup'), findsOneWidget);
    });

    testWidgets('displays message info row', (tester) async {
      await pumpSheet(tester);

      expect(
        find.text('When I open the app it crashes immediately.'),
        findsOneWidget,
      );
    });

    testWidgets('displays email info row', (tester) async {
      await pumpSheet(tester);

      expect(find.text('user@test.com'), findsOneWidget);
    });

    testWidgets('displays platform info row', (tester) async {
      await pumpSheet(tester);

      expect(find.text('android'), findsOneWidget);
    });

    testWidgets('displays app version info row', (tester) async {
      await pumpSheet(tester);

      expect(find.text('2.1.0'), findsOneWidget);
    });

    testWidgets('shows priority segmented button', (tester) async {
      await pumpSheet(tester);

      expect(find.byType(SegmentedButton<String>), findsAtLeastNWidgets(1));
    });

    testWidgets('contains a ListView for scrollable content', (tester) async {
      await pumpSheet(tester);

      // The sheet renders a ListView with scrollable content
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('contains DraggableScrollableSheet', (tester) async {
      await pumpSheet(tester);

      expect(
        find.byType(DraggableScrollableSheet),
        findsOneWidget,
      );
    });

    testWidgets('omits optional fields when absent', (tester) async {
      final minimalItem = <String, dynamic>{
        'id': 'f-2',
        'status': 'open',
        'priority': 'normal',
        'subject': 'Some subject',
        'message': 'Some message',
      };

      await pumpSheet(tester, item: minimalItem);

      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
      expect(find.text('Some subject'), findsOneWidget);
    });
  });
}
