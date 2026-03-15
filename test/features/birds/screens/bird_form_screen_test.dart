import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
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

  Widget buildSubject({String? editBirdId, Bird? editBird}) {
    when(
      () => mockBirdRepo.watchAll(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(() => mockBirdRepo.getAll(any())).thenAnswer((_) async => []);
    when(() => mockBirdRepo.save(any())).thenAnswer((_) async {});
    when(() => mockBirdRepo.watchById(any())).thenAnswer((invocation) {
      final id = invocation.positionalArguments.first as String;
      if (editBirdId != null && id == editBirdId) {
        return Stream.value(editBird);
      }
      return Stream.value(null);
    });

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
      expect(find.text('birds.default_name_prefix1'), findsOneWidget);
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

  group('BirdFormScreen - edit bird', () {
    testWidgets('loads existing bird and prefills form fields', (tester) async {
      final existing = createTestBird(
        id: 'bird-1',
        name: 'Mavi',
        ringNumber: 'TR-100',
        cageNumber: 'A1',
      );

      await tester.pumpWidget(
        buildSubject(editBirdId: existing.id, editBird: existing),
      );
      await tester.pumpAndSettle();

      expect(find.text('birds.edit_bird'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'common.update'),
        findsOneWidget,
      );

      final editableTexts = tester.widgetList<EditableText>(
        find.byType(EditableText),
      );
      expect(
        editableTexts.any((field) => field.controller.text == 'Mavi'),
        isTrue,
      );
      expect(
        editableTexts.any((field) => field.controller.text == 'TR-100'),
        isTrue,
      );
      expect(
        editableTexts.any((field) => field.controller.text == 'A1'),
        isTrue,
      );
    });

    testWidgets('shows not found state when edit bird does not exist', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(editBirdId: 'missing', editBird: null),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.byType(Form), findsNothing);
    });

    testWidgets('normalizes female legacy sex-linked genotype on update', (
      tester,
    ) async {
      final existing = Bird(
        id: 'bird-legacy',
        name: 'Luna',
        gender: BirdGender.female,
        userId: 'test-user',
        mutations: const ['lutino'],
        genotypeInfo: const {'lutino': 'carrier'},
      );

      await tester.pumpWidget(
        buildSubject(editBirdId: existing.id, editBird: existing),
      );
      await tester.pumpAndSettle();

      final updateButton = find.widgetWithText(FilledButton, 'common.update');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      final saved =
          verify(() => mockBirdRepo.save(captureAny())).captured.single as Bird;

      expect(saved.mutations, isNotNull);
      expect(saved.mutations, hasLength(1));
      expect(saved.mutations!.single, 'ino');

      expect(saved.genotypeInfo, isNotNull);
      expect(saved.genotypeInfo, hasLength(1));
      expect(saved.genotypeInfo!['ino'], 'visual');
      expect(saved.genotypeInfo!.containsKey('lutino'), isFalse);
    });
  });
}
