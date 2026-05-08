import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/screens/breeding_form_screen.dart';

Bird _bird(String id, String name, BirdGender gender) => Bird(
  id: id,
  userId: 'test-user',
  name: name,
  gender: gender,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

void main() {
  late GoRouter router;

  setUp(() {
    router = GoRouter(
      initialLocation: '/breeding/form',
      routes: [
        GoRoute(
          path: '/breeding',
          builder: (_, __) => const Text('B'),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, s) => BreedingFormScreen(
                editPairId: s.uri.queryParameters['editId'],
              ),
            ),
          ],
        ),
        GoRoute(path: '/birds/form', builder: (_, __) => const Text('BF')),
        GoRoute(path: '/premium', builder: (_, __) => const Text('P')),
      ],
    );
  });

  Widget subject({
    required Stream<List<Bird>> birds,
    List<Bird> males = const [],
    List<Bird> females = const [],
    BreedingFormNotifier Function()? notifierFactory,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        birdsStreamProvider('test-user').overrideWith((_) => birds),
        maleBirdsProvider('test-user').overrideWith((_) => males),
        femaleBirdsProvider('test-user').overrideWith((_) => females),
        breedingFormStateProvider.overrideWith(
          notifierFactory ?? () => BreedingFormNotifier(),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('Empty state handling', () {
    testWidgets('no available birds shows empty state', (t) async {
      await t.pumpWidget(subject(birds: Stream.value([])));
      await t.pumpAndSettle();
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('breeding.no_birds_to_pair'), findsOneWidget);
    });

    testWidgets('form renders with only male birds (no females)', (t) async {
      final males = [_bird('m1', 'Male', BirdGender.male)];
      await t.pumpWidget(subject(birds: Stream.value(males), males: males));
      await t.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
      expect(find.textContaining('(0)'), findsAtLeastNWidgets(1));
    });

    testWidgets('form renders with only female birds (no males)', (t) async {
      final females = [_bird('f1', 'Female', BirdGender.female)];
      await t.pumpWidget(
        subject(birds: Stream.value(females), females: females),
      );
      await t.pumpAndSettle();
      expect(find.byType(Form), findsOneWidget);
      expect(find.textContaining('(0)'), findsAtLeastNWidgets(1));
    });

    testWidgets('submit without selecting birds shows validation error', (
      t,
    ) async {
      final males = [_bird('m1', 'Male', BirdGender.male)];
      await t.pumpWidget(subject(birds: Stream.value(males), males: males));
      await t.pumpAndSettle();
      final btn = find.widgetWithText(FilledButton, 'common.save');
      await t.ensureVisible(btn);
      await t.tap(btn);
      await t.pumpAndSettle();
      expect(
        find.textContaining('validation.field_required'),
        findsAtLeastNWidgets(1),
      );
    });
  });

  group('Error recovery', () {
    testWidgets('save failure shows error SnackBar', (t) async {
      final notifier = _TransitionNotifier();
      final males = [_bird('m1', 'Male', BirdGender.male)];
      await t.pumpWidget(
        subject(
          birds: Stream.value(males),
          males: males,
          notifierFactory: () => notifier,
        ),
      );
      await t.pumpAndSettle();
      notifier.simulateError('errors.unknown');
      await t.pump();
      await t.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('errors.unknown'), findsOneWidget);
    });

    testWidgets('loading state disables save button', (t) async {
      final males = [_bird('m1', 'Male', BirdGender.male)];
      await t.pumpWidget(
        subject(
          birds: Stream.value(males),
          males: males,
          notifierFactory: () => _LoadingNotifier(),
        ),
      );
      await t.pump();
      await t.pump();
      final btn = t.widget<FilledButton>(find.byType(FilledButton).first);
      expect(btn.onPressed, isNull);
    });
  });
}

class _TransitionNotifier extends BreedingFormNotifier {
  @override
  BreedingFormState build() => const BreedingFormState();
  void simulateError(String msg) => state = state.copyWith(error: msg);
}

class _LoadingNotifier extends BreedingFormNotifier {
  @override
  BreedingFormState build() => const BreedingFormState(isLoading: true);
}
