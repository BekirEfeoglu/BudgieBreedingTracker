import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/screens/health_record_list_screen.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_card.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

void main() {
  HealthRecord makeRecord({
    String id = 'rec-1',
    HealthRecordType type = HealthRecordType.checkup,
    String title = 'Genel Kontrol',
  }) {
    return HealthRecord(
      id: id,
      userId: 'test-user',
      type: type,
      title: title,
      date: DateTime(2024, 1, 1),
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
  }

  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/health-records',
      routes: [
        GoRoute(
          path: '/health-records',
          builder: (_, __) => const HealthRecordListScreen(),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) => const Scaffold(body: Text('Form')),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  Scaffold(body: Text('Detail: ${state.pathParameters['id']}')),
            ),
          ],
        ),
      ],
    );
  });

  Widget createSubject({required Stream<List<HealthRecord>> recordsStream}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        userProfileProvider.overrideWith((_) => Stream.value(null)),
        unreadNotificationsProvider(
          'test-user',
        ).overrideWith((_) => Stream.value([])),
        healthRecordsStreamProvider(
          'test-user',
        ).overrideWith((_) => recordsStream),
        animalNameCacheProvider('test-user').overrideWith((_) => {}),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('HealthRecordListScreen', () {
    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      final controller = StreamController<List<HealthRecord>>();

      await tester.pumpWidget(createSubject(recordsStream: controller.stream));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows empty state when no records exist', (tester) async {
      await tester.pumpWidget(createSubject(recordsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(recordsStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows health record cards when data is available', (
      tester,
    ) async {
      final records = [
        makeRecord(id: 'r1', title: 'Kontrol 1'),
        makeRecord(id: 'r2', title: 'Kontrol 2'),
      ];

      await tester.pumpWidget(
        createSubject(recordsStream: Stream.value(records)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(HealthRecordCard), findsNWidgets(2));
    });

    testWidgets('shows AppBar with health records title', (tester) async {
      await tester.pumpWidget(createSubject(recordsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.text('health_records.title'), findsOneWidget);
    });

    testWidgets('has search text field', (tester) async {
      await tester.pumpWidget(createSubject(recordsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('has floating action button', (tester) async {
      await tester.pumpWidget(createSubject(recordsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows no results empty state when search has no matches', (
      tester,
    ) async {
      final records = [makeRecord(id: 'r1', title: 'Genel Kontrol')];

      await tester.pumpWidget(
        createSubject(recordsStream: Stream.value(records)),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzznomatch');
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows filter chips for health record categories', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(recordsStream: Stream.value([])));

      await tester.pumpAndSettle();

      // Filter bar should exist with ChoiceChip widgets
      expect(find.byType(ChoiceChip), findsWidgets);
    });
  });
}
