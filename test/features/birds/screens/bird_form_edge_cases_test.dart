import 'dart:async';

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
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late MockBirdRepository mockBirdRepo;

  setUp(() {
    mockBirdRepo = MockBirdRepository();
    registerFallbackValue(createTestBird(id: 'fb', name: 'Fb'));
  });

  GoRouter router({String? editBirdId}) => GoRouter(
    initialLocation: '/birds/form',
    routes: [
      GoRoute(
        path: '/birds',
        builder: (_, __) => const SizedBox(),
        routes: [
          GoRoute(
            path: 'form',
            builder: (_, s) => BirdFormScreen(
              editBirdId: editBirdId ?? s.uri.queryParameters['editId'],
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (_, s) => Text('${s.pathParameters['id']}'),
          ),
        ],
      ),
    ],
  );

  void stubRepo({Bird? editBird, String? editBirdId}) {
    when(
      () => mockBirdRepo.watchAll(any()),
    ).thenAnswer((_) => Stream.value([]));
    when(() => mockBirdRepo.getAll(any())).thenAnswer((_) async => []);
    when(() => mockBirdRepo.save(any())).thenAnswer((_) async {});
    when(
      () => mockBirdRepo.hasRingNumber(any(), any()),
    ).thenAnswer((_) async => false);
    when(() => mockBirdRepo.watchById(any())).thenAnswer((inv) {
      final id = inv.positionalArguments.first as String;
      if (editBirdId != null && id == editBirdId) return Stream.value(editBird);
      return Stream.value(null);
    });
  }

  Widget subject({
    String? editBirdId,
    Bird? editBird,
    List<dynamic> extra = const [],
  }) {
    stubRepo(editBird: editBird, editBirdId: editBirdId);
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        birdRepositoryProvider.overrideWithValue(mockBirdRepo),
        birdsStreamProvider('test-user').overrideWith((_) => Stream.value([])),
        ...extra,
      ],
      child: MaterialApp.router(routerConfig: router(editBirdId: editBirdId)),
    );
  }

  group('Form validation edge cases', () {
    testWidgets('empty name shows validation error on submit', (t) async {
      await t.pumpWidget(subject());
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, '');
      await t.pump();
      final btn = find.widgetWithText(FilledButton, 'common.save').first;
      await t.ensureVisible(btn);
      await t.pump();
      await t.tap(btn);
      await t.pumpAndSettle();
      expect(find.text('birds.name_required'), findsOneWidget);
    });

    testWidgets('whitespace-only name shows validation error', (t) async {
      await t.pumpWidget(subject());
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, '   ');
      await t.pump();
      final btn = find.widgetWithText(FilledButton, 'common.save').first;
      await t.ensureVisible(btn);
      await t.pump();
      await t.tap(btn);
      await t.pumpAndSettle();
      expect(find.text('birds.name_required'), findsOneWidget);
    });

    testWidgets('very long name does not cause overflow', (t) async {
      await t.pumpWidget(subject());
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField).first, 'A' * 500);
      await t.pump();
      expect(t.takeException(), isNull);
    });

    testWidgets('loading state shows progress indicator in button', (t) async {
      await t.pumpWidget(
        subject(
          extra: [
            birdFormStateProvider.overrideWith(
              () => _FixedNotifier(const BirdFormState(isLoading: true)),
            ),
          ],
        ),
      );
      await t.pump();
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Error handling', () {
    testWidgets('error state triggers SnackBar via ref.listen', (t) async {
      final notifier = _TransitionNotifier();
      await t.pumpWidget(
        subject(extra: [birdFormStateProvider.overrideWith(() => notifier)]),
      );
      await t.pumpAndSettle();
      notifier.simulateError('errors.unknown');
      await t.pump();
      await t.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('errors.unknown'), findsOneWidget);
    });

    testWidgets('error state clears when notifier resets', (t) async {
      final notifier = _TransitionNotifier();
      await t.pumpWidget(
        subject(extra: [birdFormStateProvider.overrideWith(() => notifier)]),
      );
      await t.pumpAndSettle();
      notifier.simulateError('errors.unknown');
      await t.pump();
      await t.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      notifier.reset();
      await t.pumpAndSettle();
      expect(notifier.state.error, isNull);
    });
  });

  group('Edit mode edge cases', () {
    testWidgets('non-existent editBirdId shows error state', (t) async {
      await t.pumpWidget(subject(editBirdId: 'missing'));
      await t.pumpAndSettle();
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.byType(Form), findsNothing);
    });

    testWidgets('edit mode shows loading before data arrives', (t) async {
      final ctrl = StreamController<Bird?>();
      when(() => mockBirdRepo.watchById(any())).thenAnswer((_) => ctrl.stream);
      when(
        () => mockBirdRepo.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(() => mockBirdRepo.getAll(any())).thenAnswer((_) async => []);
      final w = ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          currentUserProvider.overrideWith((_) => null),
          birdRepositoryProvider.overrideWithValue(mockBirdRepo),
          birdsStreamProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
        ],
        child: MaterialApp.router(routerConfig: router(editBirdId: 'slow')),
      );
      await t.pumpWidget(w);
      await t.pump();
      expect(find.text('common.loading'), findsOneWidget);
      ctrl.close();
    });

    testWidgets('form fields populated from existing bird', (t) async {
      final bird = createTestBird(
        id: 'e1',
        name: 'Sari',
        ringNumber: 'TR-200',
        gender: BirdGender.female,
      );
      await t.pumpWidget(subject(editBirdId: bird.id, editBird: bird));
      await t.pumpAndSettle();
      final texts = t.widgetList<EditableText>(find.byType(EditableText));
      expect(texts.any((f) => f.controller.text == 'Sari'), isTrue);
      expect(texts.any((f) => f.controller.text == 'TR-200'), isTrue);
    });
  });

  group('Concurrent interaction', () {
    testWidgets('loading disables save button preventing double save', (
      t,
    ) async {
      await t.pumpWidget(
        subject(
          extra: [
            birdFormStateProvider.overrideWith(
              () => _FixedNotifier(const BirdFormState(isLoading: true)),
            ),
          ],
        ),
      );
      await t.pump();
      await t.pump();
      final buttons = t.widgetList<FilledButton>(find.byType(FilledButton));
      expect(buttons.where((b) => b.onPressed == null), isNotEmpty);
    });
  });
}

class _FixedNotifier extends BirdFormNotifier {
  final BirdFormState _s;
  _FixedNotifier(this._s);
  @override
  BirdFormState build() => _s;
}

class _TransitionNotifier extends BirdFormNotifier {
  @override
  BirdFormState build() => const BirdFormState();
  void simulateError(String msg) => state = state.copyWith(error: msg);
  @override
  void reset() => state = const BirdFormState();
}
