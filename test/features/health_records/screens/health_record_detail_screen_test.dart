import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/screens/health_record_detail_screen.dart';
import 'package:budgie_breeding_tracker/features/health_records/screens/health_record_form_screen.dart';

import '../../../helpers/mocks.dart';

/// Minimal asset loader returning empty translations so context.locale works
/// in tests without needing actual translation files loaded.
class _MockAssetLoader extends AssetLoader {
  const _MockAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => {};
}

void main() {
  final testRecord = HealthRecord(
    id: 'record-1',
    userId: 'test-user',
    date: DateTime(2024, 1, 15),
    type: HealthRecordType.checkup,
    title: 'Annual Checkup',
  );

  late GoRouter router;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(
      HealthRecord(
        id: 'fallback',
        userId: 'fallback',
        title: 'fallback',
        type: HealthRecordType.checkup,
        date: DateTime(2024, 1, 1),
      ),
    );
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });

  setUp(() {
    router = GoRouter(
      initialLocation: '/health-records/record-1',
      routes: [
        GoRoute(
          path: '/health-records/:id',
          builder: (_, state) =>
              HealthRecordDetailScreen(recordId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) => const Scaffold(body: Text('Form')),
            ),
          ],
        ),
      ],
    );
  });

  Widget createSubject({required Stream<HealthRecord?> recordStream}) {
    return EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      assetLoader: const _MockAssetLoader(),
      child: ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          healthRecordByIdProvider(
            'record-1',
          ).overrideWith((_) => recordStream),
          animalNameCacheProvider('test-user').overrideWith((_) => {}),
          healthRecordFormStateProvider.overrideWith(
            () => HealthRecordFormNotifier(),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  group('HealthRecordDetailScreen', () {
    testWidgets('shows loading state while data is loading', (tester) async {
      final controller = StreamController<HealthRecord?>();

      await tester.pumpWidget(createSubject(recordStream: controller.stream));
      await tester.pump();

      expect(find.byType(LoadingState), findsOneWidget);

      controller.close();
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(recordStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows not found error when record is null', (tester) async {
      await tester.pumpWidget(createSubject(recordStream: Stream.value(null)));

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows record title in AppBar when data loads', (tester) async {
      await tester.pumpWidget(
        createSubject(recordStream: Stream.value(testRecord)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Annual Checkup'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows popup menu button when data loads', (tester) async {
      await tester.pumpWidget(
        createSubject(recordStream: Stream.value(testRecord)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('shows scrollable body when data loads', (tester) async {
      await tester.pumpWidget(
        createSubject(recordStream: Stream.value(testRecord)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('shows edit icon button in AppBar', (tester) async {
      await tester.pumpWidget(
        createSubject(recordStream: Stream.value(testRecord)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });

    testWidgets('shows header section with record type icon', (tester) async {
      await tester.pumpWidget(
        createSubject(recordStream: Stream.value(testRecord)),
      );

      await tester.pumpAndSettle();

      // _HeaderSection renders a CircleAvatar with the type icon
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets(
      'shows not found state as ErrorState widget when record is null',
      (tester) async {
        await tester.pumpWidget(
          createSubject(recordStream: Stream.value(null)),
        );

        await tester.pumpAndSettle();

        expect(find.byType(ErrorState), findsOneWidget);
      },
    );

    testWidgets('shows health_records.not_found key when record is null', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(recordStream: Stream.value(null)));

      await tester.pumpAndSettle();

      expect(find.text('health_records.not_found'), findsOneWidget);
    });
  });

  group('HealthRecordDetailScreen navigation regression', () {
    testWidgets(
      'pops exactly once after a successful edit (no double-pop back to list)',
      (tester) async {
        final mockRepo = MockHealthRecordRepository();
        when(() => mockRepo.save(any())).thenAnswer((_) async {});
        // updateRecord re-fetches by id to detect followUpDate/birdId
        // changes and cancel stale reminders (see
        // health_record_form_providers.dart).
        when(
          () => mockRepo.getById('record-1'),
        ).thenAnswer((_) async => testRecord);

        final editRouter = GoRouter(
          initialLocation: '/health-records',
          routes: [
            GoRoute(
              path: '/health-records',
              builder: (_, __) =>
                  const Scaffold(body: Text('LIST_SCREEN_MARKER')),
              routes: [
                GoRoute(
                  path: 'form',
                  builder: (_, state) => HealthRecordFormScreen(
                    editRecordId: state.uri.queryParameters['editId'],
                  ),
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, state) => HealthRecordDetailScreen(
                    recordId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            assetLoader: const _MockAssetLoader(),
            child: ProviderScope(
              overrides: [
                currentUserIdProvider.overrideWithValue('test-user'),
                healthRecordRepositoryProvider.overrideWithValue(mockRepo),
                healthRecordByIdProvider(
                  'record-1',
                ).overrideWith((_) => Stream.value(testRecord)),
                animalNameCacheProvider('test-user').overrideWith((_) => {}),
                birdsStreamProvider(
                  'test-user',
                ).overrideWith((_) => Stream.value([])),
                chicksStreamProvider(
                  'test-user',
                ).overrideWith((_) => Stream.value([])),
              ],
              child: MaterialApp.router(routerConfig: editRouter),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('LIST_SCREEN_MARKER'), findsOneWidget);

        editRouter.push('/health-records/record-1');
        await tester.pumpAndSettle();
        expect(find.byType(HealthRecordDetailScreen), findsOneWidget);

        editRouter.push('/health-records/form?editId=record-1');
        await tester.pumpAndSettle();
        expect(find.byType(HealthRecordFormScreen), findsOneWidget);

        // Title is pre-populated from the existing record, so submitting
        // immediately is a valid update — no need to type anything first.
        final updateButton = find.widgetWithText(
          FilledButton,
          'common.update',
        );
        await tester.ensureVisible(updateButton);
        await tester.pump();
        await tester.tap(updateButton);
        await tester.pumpAndSettle();

        // The form screen and the still-mounted-underneath detail screen
        // used to both listen to the same unscoped healthRecordFormStateProvider
        // and both pop on isSuccess — that double-pop landed the user back on
        // the list instead of the detail screen. Only one pop should happen.
        expect(find.byType(HealthRecordFormScreen), findsNothing);
        expect(find.byType(HealthRecordDetailScreen), findsOneWidget);
        expect(find.text('LIST_SCREEN_MARKER'), findsNothing);
      },
    );
  });
}
