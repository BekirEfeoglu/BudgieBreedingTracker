@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/widgets/marketplace_bird_picker_sheet.dart';

import '../../../helpers/test_localization.dart';

const _testUserId = 'test-user-picker';

const _aliveBird = Bird(
  id: 'bird-1',
  name: 'Mavi',
  gender: BirdGender.male,
  userId: _testUserId,
  species: Species.budgie,
  status: BirdStatus.alive,
);

const _deadBird = Bird(
  id: 'bird-2',
  name: 'Sari',
  gender: BirdGender.female,
  userId: _testUserId,
  species: Species.budgie,
  status: BirdStatus.dead,
);

const _femaleBird = Bird(
  id: 'bird-3',
  name: 'Yesil',
  gender: BirdGender.female,
  userId: _testUserId,
  species: Species.budgie,
  status: BirdStatus.alive,
);

Widget _buildSubject({
  required AsyncValue<List<Bird>> birdsAsync,
}) {
  return ProviderScope(
    overrides: [
      birdsStreamProvider(_testUserId).overrideWith(
        (ref) => switch (birdsAsync) {
          AsyncData(:final value) => Stream.value(value),
          AsyncError(:final error) => Stream.error(error),
          _ => const Stream.empty(),
        },
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: MarketplaceBirdPickerSheet(userId: _testUserId),
      ),
    ),
  );
}

void main() {
  group('MarketplaceBirdPickerSheet', () {
    testWidgets('should_show_loading_state_when_birds_are_loading',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(birdsAsync: const AsyncLoading()),
        settle: false,
      );

      expect(find.byType(LoadingState), findsOneWidget);
    });

    testWidgets('should_show_empty_state_when_no_alive_birds', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(birdsAsync: const AsyncData([_deadBird])),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('marketplace.no_birds_to_link'), findsOneWidget);
    });

    testWidgets('should_show_alive_birds_only_when_data_available',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(
          birdsAsync: const AsyncData([_aliveBird, _deadBird, _femaleBird]),
        ),
      );

      // Alive birds shown
      expect(find.text('Mavi'), findsOneWidget);
      expect(find.text('Yesil'), findsOneWidget);
      // Dead bird not shown
      expect(find.text('Sari'), findsNothing);
    });

    testWidgets('should_show_select_bird_title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(birdsAsync: const AsyncData([_aliveBird])),
      );

      expect(find.text('marketplace.select_bird'), findsOneWidget);
    });

    testWidgets('should_show_error_state_when_stream_errors', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildSubject(
          birdsAsync: AsyncError(Exception('fail'), StackTrace.empty),
        ),
      );

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('errors.unknown_error'), findsOneWidget);
    });
  });
}
