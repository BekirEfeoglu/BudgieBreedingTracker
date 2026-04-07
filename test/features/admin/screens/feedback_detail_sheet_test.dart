import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/screens/_feedback_detail_sheet.dart';

import '../../../helpers/test_localization.dart';

final _testItem = <String, dynamic>{
  'subject': 'Login issue',
  'message': 'I cannot log in after update',
  'email': 'user@test.com',
  'platform': 'ios',
  'app_version': '1.0.2',
  'status': 'open',
  'priority': 'normal',
  'admin_response': '',
};

final _minimalItem = <String, dynamic>{
  'subject': 'Minimal feedback',
  'message': 'A short message',
  'status': 'open',
  'priority': 'low',
};

/// Show the sheet via showModalBottomSheet so DraggableScrollableSheet works.
Widget _createSubject({
  Map<String, dynamic>? item,
  FeedbackSaveCallback? onSave,
}) {
  final feedbackItem = item ?? _testItem;
  final callback = onSave ??
      ({required status, adminResponse, required priority}) async {};

  return MaterialApp(
    home: _SheetLauncher(item: feedbackItem, onSave: callback),
  );
}

class _SheetLauncher extends StatefulWidget {
  final Map<String, dynamic> item;
  final FeedbackSaveCallback onSave;
  const _SheetLauncher({required this.item, required this.onSave});

  @override
  State<_SheetLauncher> createState() => _SheetLauncherState();
}

class _SheetLauncherState extends State<_SheetLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
          height: 700,
          child: FeedbackDetailSheet(
            item: widget.item,
            onSave: widget.onSave,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}

void main() {
  group('FeedbackDetailSheet', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
    });

    testWidgets('shows feedback detail title', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      expect(
        find.text(l10n('admin.feedback_detail')),
        findsOneWidget,
      );
    });

    testWidgets('shows subject and message', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      expect(find.text('Login issue'), findsOneWidget);
      expect(find.text('I cannot log in after update'), findsOneWidget);
    });

    testWidgets('shows email when present', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      expect(find.text('user@test.com'), findsOneWidget);
    });

    testWidgets('shows platform when present', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      expect(find.text('ios'), findsOneWidget);
    });

    testWidgets('shows app version when present', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      expect(find.text('1.0.2'), findsOneWidget);
    });

    testWidgets('hides optional fields when absent', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(item: _minimalItem),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n('admin.feedback_email_label')), findsNothing);
      expect(find.text(l10n('admin.feedback_platform_label')), findsNothing);
      expect(find.text(l10n('admin.feedback_version_label')), findsNothing);
    });

    testWidgets('shows priority segmented button', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      expect(
        find.text(l10n('admin.feedback_priority_low')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('admin.feedback_priority_normal')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('admin.feedback_priority_high')),
        findsOneWidget,
      );
    });

    testWidgets('shows status segmented button', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      // The status SegmentedButton is below priority, scroll to see it
      final listView = find.byType(ListView);
      await tester.drag(listView, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n('admin.feedback_status_resolved')),
        findsOneWidget,
      );
    });

    testWidgets('shows save button after scrolling', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      // Scroll down enough to reveal save button at the bottom
      final listView = find.byType(ListView);
      await tester.drag(listView, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.drag(listView, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        find.text(l10n('admin.feedback_save')),
        findsOneWidget,
      );
    });

    testWidgets('shows existing admin response in text field', (tester) async {
      final item = Map<String, dynamic>.from(_testItem);
      item['admin_response'] = 'We are looking into this';
      await pumpLocalizedApp(tester, _createSubject(item: item));
      await tester.pumpAndSettle();
      // Scroll to see admin response field
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(find.text('We are looking into this'), findsOneWidget);
    });

    testWidgets('renders two SegmentedButton widgets', (tester) async {
      await pumpLocalizedApp(tester, _createSubject());
      await tester.pumpAndSettle();
      // Scroll to ensure both are rendered
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(SegmentedButton<String>),
        findsNWidgets(2),
      );
    });

    testWidgets('calls onSave with current state on save tap', (tester) async {
      String? savedStatus;
      String? savedPriority;

      await pumpLocalizedApp(
        tester,
        _createSubject(
          onSave: ({
            required status,
            adminResponse,
            required priority,
          }) async {
            savedStatus = status;
            savedPriority = priority;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down multiple times to reveal save button at the bottom
      final listView = find.byType(ListView);
      await tester.drag(listView, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.drag(listView, const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('admin.feedback_save')));
      await tester.pumpAndSettle();

      expect(savedStatus, 'open');
      expect(savedPriority, 'normal');
    });
  });
}
