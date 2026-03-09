import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/health_records/screens/health_record_form_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/health-records/form',
      routes: [
        GoRoute(
          path: '/health-records',
          builder: (_, __) => const SizedBox(),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, __) => const HealthRecordFormScreen(),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        birdsStreamProvider('test-user').overrideWith((_) => Stream.value([])),
        chicksStreamProvider('test-user').overrideWith((_) => Stream.value([])),
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    );
  }

  group('HealthRecordFormScreen - new record', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(HealthRecordFormScreen), findsOneWidget);
    });

    testWidgets('shows new record title in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      // EasyLocalization returns key in test context
      expect(find.text('health_records.new_record'), findsOneWidget);
    });

    testWidgets('shows form with text fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows type selection chips', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      // HealthRecordType has 6 values
      expect(find.byType(ChoiceChip), findsNWidgets(6));
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      // PrimaryButton renders a FilledButton
      expect(find.byType(FilledButton), findsWidgets);
    });

    testWidgets('shows validation error on empty title submit', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tap the save button without filling in title
      final saveButton = find.widgetWithText(FilledButton, 'common.save').first;
      await tester.ensureVisible(saveButton);
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Validation error key should appear
      expect(find.text('health_records.title_required'), findsOneWidget);
    });
  });
}
