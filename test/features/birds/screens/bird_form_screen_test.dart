import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
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

  Widget buildSubject({
    String? editBirdId,
    Bird? editBird,
    List<Bird> birds = const [],
  }) {
    when(
      () => mockBirdRepo.watchAll(any()),
    ).thenAnswer((_) => Stream.value(birds));
    when(() => mockBirdRepo.getAll(any())).thenAnswer((_) async => birds);
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
        birdsStreamProvider(
          'test-user',
        ).overrideWith((_) => Stream.value(birds)),
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
      expect(find.text(l10n('birds.new_bird')), findsOneWidget);
    });

    testWidgets('shows name text field', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('prefills automatic bird name', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text(l10n('birds.default_name_prefix1')), findsOneWidget);
    });

    testWidgets('shows a Form widget', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('hides genetics section when species starts as unknown', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.text(l10n('genetics.title')), findsNothing);
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
      final saveButton = find.widgetWithText(FilledButton, l10n('common.save')).first;
      await tester.ensureVisible(saveButton);
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Validation error key should appear
      expect(find.text(l10n('birds.name_required')), findsOneWidget);
    });

    testWidgets('requires species selection before save', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Mavi');
      await tester.pump();

      final saveButton = find.widgetWithText(FilledButton, l10n('common.save')).first;
      await tester.ensureVisible(saveButton);
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.species_required')), findsOneWidget);
      verifyNever(() => mockBirdRepo.save(any()));
    });

    testWidgets('shows multiple text form fields', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // name, ring, cage, notes, colorNote → at least 3 visible in viewport
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('starts with empty species selection for new bird', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final speciesDropdown = tester.widget<DropdownButton<Species>>(
        find.byWidgetPredicate((widget) => widget is DropdownButton<Species>),
      );

      expect(speciesDropdown.value, isNull);
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

      expect(find.text(l10n('birds.edit_bird')), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, l10n('common.update')),
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
      const existing = Bird(
        id: 'bird-legacy',
        name: 'Luna',
        gender: BirdGender.female,
        userId: 'test-user',
        species: Species.budgie,
        mutations: ['lutino'],
        genotypeInfo: {'lutino': 'carrier'},
      );

      await tester.pumpWidget(
        buildSubject(editBirdId: existing.id, editBird: existing),
      );
      await tester.pumpAndSettle();

      final updateButton = find.widgetWithText(FilledButton, l10n('common.update'));
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

    testWidgets('clears selected parents when species changes', (tester) async {
      final father = createTestBird(
        id: 'father-1',
        name: 'Baba',
        gender: BirdGender.male,
        species: Species.budgie,
      );
      final mother = createTestBird(
        id: 'mother-1',
        name: 'Anne',
        gender: BirdGender.female,
        species: Species.budgie,
      );
      final existing = createTestBird(
        id: 'bird-1',
        name: 'Yavru',
        species: Species.budgie,
        fatherId: father.id,
        motherId: mother.id,
      );

      await tester.pumpWidget(
        buildSubject(
          editBirdId: existing.id,
          editBird: existing,
          birds: [father, mother, existing],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Baba'), findsOneWidget);
      expect(find.text('Anne'), findsOneWidget);

      await tester.tap(find.byType(DropdownButtonFormField<Species>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n('birds.canary')).last);
      await tester.pumpAndSettle();

      expect(find.text('Baba'), findsNothing);
      expect(find.text('Anne'), findsNothing);
    });
  });
}
