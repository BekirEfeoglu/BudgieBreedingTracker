import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/birds/screens/bird_form_screen.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockBirdRepository mockBirdRepo;

  setUp(() {
    mockBirdRepo = MockBirdRepository();
    registerFallbackValue(createTestBird(id: 'fallback', name: 'Fallback'));
  });

  GoRouter buildRouter({String? editBirdId}) {
    return GoRouter(
      initialLocation: '/birds/form',
      routes: [
        GoRoute(
          path: '/birds',
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, state) => BirdFormScreen(
                editBirdId: editBirdId ?? state.uri.queryParameters['editId'],
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  Scaffold(body: Text('Detail ${state.pathParameters['id']}')),
            ),
          ],
          builder: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  Widget buildSubject({String? editBirdId}) {
    when(
      () => mockBirdRepo.watchAll(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(() => mockBirdRepo.getAll(any())).thenAnswer((_) async => []);

    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        birdRepositoryProvider.overrideWithValue(mockBirdRepo),
        birdsStreamProvider('test-user').overrideWith((_) => Stream.value([])),
      ],
      child: MaterialApp.router(
        routerConfig: buildRouter(editBirdId: editBirdId),
      ),
    );
  }

  group('BirdFormScreen - new bird', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(BirdFormScreen), findsOneWidget);
    });

    testWidgets('shows new bird title in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      // EasyLocalization returns key in test context
      expect(find.text('birds.new_bird'), findsOneWidget);
    });

    testWidgets('shows name text field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('prefills automatic bird name', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('Kuş-1'), findsOneWidget);
    });

    testWidgets('shows a Form widget', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('shows genetics section', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text('genetics.title'), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      // PrimaryButton renders a FilledButton
      expect(find.byType(FilledButton), findsWidgets);
    });

    testWidgets('does not show error initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('shows validation error on empty name submit', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.pump();

      // Tap save with an empty name
      final saveButton = find.widgetWithText(FilledButton, 'common.save').first;
      await tester.ensureVisible(saveButton);
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Validation error key should appear
      expect(find.text('birds.name_required'), findsOneWidget);
    });

    testWidgets('shows multiple text form fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // name, ring, cage, notes, colorNote → at least 3 visible in viewport
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('SingleChildScrollView wraps form body', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });
  });
}
