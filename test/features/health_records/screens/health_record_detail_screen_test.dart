import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/screens/health_record_detail_screen.dart';

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
}
