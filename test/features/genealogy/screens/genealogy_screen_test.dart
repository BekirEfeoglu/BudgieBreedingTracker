import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/screens/genealogy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createSubject({required Stream<List<Bird>> birdsStream}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        birdsStreamProvider('test-user').overrideWith((_) => birdsStream),
        chicksStreamProvider('test-user').overrideWith((_) => Stream.value([])),
      ],
      child: const MaterialApp(home: GenealogyScreen()),
    );
  }

  group('GenealogyScreen', () {
    testWidgets('shows loading indicator while birds are loading', (
      tester,
    ) async {
      final controller = StreamController<List<Bird>>();

      await tester.pumpWidget(createSubject(birdsStream: controller.stream));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(birdsStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows empty state when no birds or chicks exist', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(birdsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('genealogy.no_birds'), findsOneWidget);
    });

    testWidgets('shows AppBar with genealogy title', (tester) async {
      final controller = StreamController<List<Bird>>();

      await tester.pumpWidget(createSubject(birdsStream: controller.stream));

      expect(find.text('genealogy.title'), findsOneWidget);

      controller.close();
    });

    testWidgets('shows entity selector when birds exist and no selection', (
      tester,
    ) async {
      final List<Bird> birds = [
        Bird(
          id: 'bird-1',
          userId: 'test-user',
          name: 'Yeşil',
          gender: BirdGender.unknown,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      await tester.pumpWidget(createSubject(birdsStream: Stream.value(birds)));
      await tester.pumpAndSettle();

      // Entity selector should be visible (list of birds to select from)
      expect(find.text('Yeşil'), findsOneWidget);
    });

    testWidgets('shows popup menu button in AppBar', (tester) async {
      final controller = StreamController<List<Bird>>();

      await tester.pumpWidget(createSubject(birdsStream: controller.stream));

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);

      controller.close();
    });
  });
}
