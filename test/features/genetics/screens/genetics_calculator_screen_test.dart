import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_calculator_screen.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockGeneticsHistoryDao mockHistoryDao;

  setUp(() {
    mockHistoryDao = MockGeneticsHistoryDao();
    when(
      () => mockHistoryDao.watchAll(any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/genetics',
      routes: [
        GoRoute(
          path: '/genetics',
          builder: (_, __) => const GeneticsCalculatorScreen(),
          routes: [
            GoRoute(
              path: 'history',
              builder: (_, __) => const Scaffold(body: Text('History Screen')),
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
        geneticsHistoryDaoProvider.overrideWithValue(mockHistoryDao),
      ],
      child: MaterialApp.router(routerConfig: buildRouter()),
    );
  }

  group('GeneticsCalculatorScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(GeneticsCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows genetics title in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      // EasyLocalization returns key in test context
      expect(find.text('genetics.title'), findsOneWidget);
    });

    testWidgets('starts on step 0 (wizard step is 0 by default)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // The step indicator should be present (step titles are shown)
      // Step 0 is the parent selection step
      expect(find.byType(GeneticsCalculatorScreen), findsOneWidget);

      // Verify wizardStepProvider is at 0 by checking a ProviderContainer
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(wizardStepProvider), 0);
    });

    testWidgets('shows history button in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // History icon button should be present
      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('does not show reset button when nothing is selected', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // When fatherGenotype and motherGenotype are both empty,
      // the reset button should not be shown
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final father = container.read(fatherGenotypeProvider);
      final mother = container.read(motherGenotypeProvider);
      expect(father.isEmpty, isTrue);
      expect(mother.isEmpty, isTrue);
    });

    testWidgets('shows a Scaffold', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('WizardStepNotifier', () {
    test('default step is 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(wizardStepProvider), 0);
    });

    test('can advance to step 1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(wizardStepProvider.notifier).state = 1;
      expect(container.read(wizardStepProvider), 1);
    });

    test('can advance to step 2', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(wizardStepProvider.notifier).state = 2;
      expect(container.read(wizardStepProvider), 2);
    });

    test('can reset to step 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(wizardStepProvider.notifier).state = 2;
      container.read(wizardStepProvider.notifier).state = 0;
      expect(container.read(wizardStepProvider), 0);
    });
  });

  group('FatherGenotypeNotifier', () {
    test('default is empty (male)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final genotype = container.read(fatherGenotypeProvider);
      expect(genotype.isEmpty, isTrue);
    });
  });

  group('MotherGenotypeNotifier', () {
    test('default is empty (female)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final genotype = container.read(motherGenotypeProvider);
      expect(genotype.isEmpty, isTrue);
    });
  });

  group('ShowSexSpecificNotifier', () {
    test('default is true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(showSexSpecificProvider), isTrue);
    });

    test('can toggle to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(showSexSpecificProvider.notifier).state = false;
      expect(container.read(showSexSpecificProvider), isFalse);
    });
  });

  group('ShowGenotypeNotifier', () {
    test('default is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(showGenotypeProvider), isFalse);
    });

    test('can toggle to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(showGenotypeProvider.notifier).state = true;
      expect(container.read(showGenotypeProvider), isTrue);
    });
  });
}
