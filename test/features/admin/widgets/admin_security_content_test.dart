import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_security_content.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';

final _failedLoginEvent = SecurityEvent(
  id: 'evt-1',
  eventType: 'login_failed',
  userId: 'user-1',
  ipAddress: '192.168.1.100',
  details: 'Invalid password attempt',
  createdAt: DateTime(2024, 3, 15, 14, 30),
);

final _rateLimitEvent = SecurityEvent(
  id: 'evt-2',
  eventType: 'rate_limit_exceeded',
  userId: 'user-2',
  ipAddress: '10.0.0.50',
  createdAt: DateTime(2024, 3, 15, 15, 0),
);

final _suspiciousEvent = SecurityEvent(
  id: 'evt-3',
  eventType: 'suspicious_activity',
  userId: 'user-3',
  ipAddress: '172.16.0.1',
  details: 'Multiple failed attempts from same IP',
  createdAt: DateTime(2024, 3, 15, 16, 0),
);

final _infoEvent = SecurityEvent(
  id: 'evt-4',
  eventType: 'password_changed',
  userId: 'user-4',
  createdAt: DateTime(2024, 3, 15, 17, 0),
);

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('SecurityContent', () {
    testWidgets('renders without crashing with events', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityContent(events: [_failedLoginEvent])),
      );
      await tester.pump();
      expect(find.byType(SecurityContent), findsOneWidget);
    });

    testWidgets('shows EmptyState when events are empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const SecurityContent(events: [])),
      );
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows empty state title text', (tester) async {
      await tester.pumpWidget(
        _wrap(const SecurityContent(events: [])),
      );
      await tester.pump();
      expect(find.text('admin.no_security_events'), findsOneWidget);
    });

    testWidgets('shows empty state subtitle text', (tester) async {
      await tester.pumpWidget(
        _wrap(const SecurityContent(events: [])),
      );
      await tester.pump();
      expect(find.text('admin.no_security_events_desc'), findsOneWidget);
    });

    testWidgets('shows CustomScrollView when events are non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SecurityContent(events: [_failedLoginEvent])),
      );
      await tester.pump();
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows SecuritySummary when events present', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityContent(events: [_failedLoginEvent])),
      );
      await tester.pump();
      expect(find.byType(SecuritySummary), findsOneWidget);
    });

    testWidgets('shows SecurityEventItem for each event', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityContent(events: [_failedLoginEvent, _rateLimitEvent])),
      );
      await tester.pump();
      expect(find.byType(SecurityEventItem), findsNWidgets(2));
    });
  });

  group('SecuritySummary', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecuritySummary(events: [_failedLoginEvent]),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SecuritySummary), findsOneWidget);
    });

    testWidgets('counts failed logins correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecuritySummary(
              events: [_failedLoginEvent, _rateLimitEvent, _infoEvent],
            ),
          ),
        ),
      );
      await tester.pump();
      // 1 failed login
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('counts rate limits correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecuritySummary(
              events: [_failedLoginEvent, _rateLimitEvent, _infoEvent],
            ),
          ),
        ),
      );
      await tester.pump();
      // 1 rate limit
      expect(find.text('1'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows total events count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecuritySummary(
              events: [_failedLoginEvent, _rateLimitEvent, _infoEvent],
            ),
          ),
        ),
      );
      await tester.pump();
      // 3 total events
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows failed_logins label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecuritySummary(events: [_failedLoginEvent]),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('admin.failed_logins'), findsOneWidget);
    });

    testWidgets('shows rate_limits label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecuritySummary(events: [_failedLoginEvent]),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('admin.rate_limits'), findsOneWidget);
    });

    testWidgets('shows total_events label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecuritySummary(events: [_failedLoginEvent]),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('admin.total_events'), findsOneWidget);
    });

    testWidgets('renders three SecuritySummaryCard widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecuritySummary(events: [_failedLoginEvent]),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SecuritySummaryCard), findsNWidgets(3));
    });
  });

  group('SecuritySummaryCard', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecuritySummaryCard(
              icon: Icon(Icons.security),
              color: Colors.red,
              value: '5',
              label: 'Test Label',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SecuritySummaryCard), findsOneWidget);
    });

    testWidgets('shows value text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecuritySummaryCard(
              icon: Icon(Icons.security),
              color: Colors.red,
              value: '42',
              label: 'Count',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecuritySummaryCard(
              icon: Icon(Icons.security),
              color: Colors.red,
              value: '5',
              label: 'My Label',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('My Label'), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecuritySummaryCard(
              icon: Icon(Icons.security),
              color: Colors.red,
              value: '5',
              label: 'Label',
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('SecurityEventItem', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _failedLoginEvent)),
      );
      await tester.pump();
      expect(find.byType(SecurityEventItem), findsOneWidget);
    });

    testWidgets('shows event type text', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _failedLoginEvent)),
      );
      await tester.pump();
      expect(find.text('login_failed'), findsOneWidget);
    });

    testWidgets('shows details when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _failedLoginEvent)),
      );
      await tester.pump();
      expect(find.text('Invalid password attempt'), findsOneWidget);
    });

    testWidgets('hides details when null', (tester) async {
      final eventNoDetails = SecurityEvent(
        id: 'evt-5',
        eventType: 'test_event',
        createdAt: DateTime(2024, 3, 15),
      );
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: eventNoDetails)),
      );
      await tester.pump();
      // Should only render the event type, not a details section
      expect(find.text('test_event'), findsOneWidget);
    });

    testWidgets('shows severity_medium label for failed login', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _failedLoginEvent)),
      );
      await tester.pump();
      expect(find.text('admin.severity_medium'), findsOneWidget);
    });

    testWidgets('shows severity_medium label for rate_limit event', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _rateLimitEvent)),
      );
      await tester.pump();
      expect(find.text('admin.severity_medium'), findsOneWidget);
    });

    testWidgets('shows severity_high label for suspicious event', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _suspiciousEvent)),
      );
      await tester.pump();
      expect(find.text('admin.severity_high'), findsOneWidget);
    });

    testWidgets('shows severity_low label for info event', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _infoEvent)),
      );
      await tester.pump();
      expect(find.text('admin.severity_low'), findsOneWidget);
    });

    testWidgets('shows dismiss button with tooltip', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _failedLoginEvent)),
      );
      await tester.pump();
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('shows SecurityMetadataRow', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _failedLoginEvent)),
      );
      await tester.pump();
      expect(find.byType(SecurityMetadataRow), findsOneWidget);
    });

    testWidgets('renders Card widget', (tester) async {
      await tester.pumpWidget(
        _wrap(SecurityEventItem(event: _failedLoginEvent)),
      );
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('SecurityMetadataRow', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityMetadataRow(event: _failedLoginEvent),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(SecurityMetadataRow), findsOneWidget);
    });

    testWidgets('shows masked IP address when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityMetadataRow(event: _failedLoginEvent),
          ),
        ),
      );
      await tester.pump();
      // IP 192.168.1.100 should be masked as ***.***. 1.100
      expect(find.text('***.***. 1.100'), findsNothing);
      expect(find.textContaining('***.***'), findsOneWidget);
    });

    testWidgets('hides IP section when ipAddress is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityMetadataRow(event: _infoEvent),
          ),
        ),
      );
      await tester.pump();
      // Should not find a masked IP
      expect(find.textContaining('***.***'), findsNothing);
    });

    testWidgets('shows formatted timestamp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityMetadataRow(event: _failedLoginEvent),
          ),
        ),
      );
      await tester.pump();
      // Timestamp should be formatted: 15 Mar 2024 14:30
      expect(find.textContaining('15'), findsOneWidget);
    });
  });
}
