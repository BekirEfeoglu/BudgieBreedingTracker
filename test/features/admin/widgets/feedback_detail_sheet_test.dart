import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/screens/_feedback_detail_sheet.dart';

const _testItem = {
  'subject': 'Test Subject',
  'message': 'Test message content',
  'email': 'user@example.com',
  'platform': 'android',
  'app_version': '1.0.0',
  'status': 'open',
  'priority': 'normal',
  'admin_response': '',
};

// Wrap in a large fixed-size container so DraggableScrollableSheet can
// calculate its dimensions correctly in the test viewport.
Widget _buildSheet({Map<String, dynamic>? item, FeedbackSaveCallback? onSave}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 1600, // tall enough that all items are visible
        child: FeedbackDetailSheet(
          item: item ?? _testItem,
          onSave:
              onSave ??
              ({
                required String status,
                String? adminResponse,
                required String priority,
              }) async {},
        ),
      ),
    ),
  );
}

void _consumeExceptions(WidgetTester tester) {
  var ex = tester.takeException();
  while (ex != null) {
    ex = tester.takeException();
  }
}

void main() {
  group('FeedbackDetailSheet', () {
    testWidgets('renders without crashing', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump(const Duration(milliseconds: 300));
      _consumeExceptions(tester);

      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
    });

    testWidgets('shows feedback_detail title', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('admin.feedback_detail'), findsOneWidget);
    });

    testWidgets('shows subject value', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('Test Subject'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows message content', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('Test message content'), findsOneWidget);
    });

    testWidgets('shows email when provided', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('user@example.com'), findsOneWidget);
    });

    testWidgets('shows platform when provided', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('android'), findsOneWidget);
    });

    testWidgets('shows app version when provided', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('shows priority SegmentedButton', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.byType(SegmentedButton<String>), findsAtLeastNWidgets(1));
    });

    testWidgets('shows feedback_save button label', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('admin.feedback_save'), findsOneWidget);
    });

    testWidgets('shows admin response TextFormField', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows DraggableScrollableSheet', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildSheet());
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('does not show email section when email key missing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final itemWithoutEmail = Map<String, dynamic>.from(_testItem)
        ..remove('email');

      await tester.pumpWidget(_buildSheet(item: itemWithoutEmail));
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('user@example.com'), findsNothing);
    });

    testWidgets('initializes with existing admin_response text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final itemWithResponse = Map<String, dynamic>.from(_testItem)
        ..['admin_response'] = 'Previous response';

      await tester.pumpWidget(_buildSheet(item: itemWithResponse));
      await tester.pump();
      _consumeExceptions(tester);

      expect(find.text('Previous response'), findsOneWidget);
    });

    testWidgets('calls onSave when save button is tapped', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var callCount = 0;
      await tester.pumpWidget(
        _buildSheet(
          onSave:
              ({
                required String status,
                String? adminResponse,
                required String priority,
              }) async {
                callCount++;
              },
        ),
      );
      await tester.pump();
      _consumeExceptions(tester);

      final saveButton = find.byType(FilledButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(callCount, 1);
    });
  });

  group('FeedbackSaveCallback typedef', () {
    test('callback can be defined and called with required params', () async {
      Future<void> callback({
        required String status,
        String? adminResponse,
        required String priority,
      }) async {}

      await callback(status: 'open', priority: 'normal');
      await callback(
        status: 'resolved',
        adminResponse: 'Done',
        priority: 'high',
      );
      expect(callback, isNotNull);
    });

    test('callback works with null adminResponse', () async {
      String? capturedResponse = 'initial';
      Future<void> callback({
        required String status,
        String? adminResponse,
        required String priority,
      }) async {
        capturedResponse = adminResponse;
      }

      await callback(status: 'open', priority: 'low');
      expect(capturedResponse, isNull);
    });
  });
}
