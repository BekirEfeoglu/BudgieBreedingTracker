import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_animal_selector.dart';

import '../../../helpers/test_localization.dart';

const _testBird1 = Bird(
  id: 'bird-1',
  name: 'Tweety',
  gender: BirdGender.male,
  userId: 'user-1',
);

const _testBird2 = Bird(
  id: 'bird-2',
  name: 'Mavi',
  gender: BirdGender.female,
  userId: 'user-1',
);

const _testChick = Chick(id: 'chick-1', userId: 'user-1');

void main() {
  group('HealthRecordAnimalSelector', () {
    testWidgets('shows LinearProgressIndicator when loading with empty lists', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        HealthRecordAnimalSelector(
          selectedId: null,
          birds: const [],
          chicks: const [],
          isLoading: true,
          onChanged: (_) {},
        ),
        settle: false,
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows DropdownButtonFormField when not loading', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        HealthRecordAnimalSelector(
          selectedId: null,
          birds: const [],
          chicks: const [],
          isLoading: false,
          onChanged: (_) {},
        ),
        settle: false,
      );

      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField),
        findsOneWidget,
      );
    });

    testWidgets('shows DropdownButtonFormField even when loading with data', (
      tester,
    ) async {
      await pumpLocalizedWidget(
        tester,
        HealthRecordAnimalSelector(
          selectedId: null,
          birds: [_testBird1],
          chicks: const [],
          isLoading: true,
          onChanged: (_) {},
        ),
        settle: false,
      );

      // isLoading is true but lists are not empty → shows dropdown
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField),
        findsOneWidget,
      );
    });

    testWidgets('shows label text from l10n', (tester) async {
      await pumpLocalizedWidget(
        tester,
        HealthRecordAnimalSelector(
          selectedId: null,
          birds: const [],
          chicks: const [],
          isLoading: false,
          onChanged: (_) {},
        ),
        settle: false,
      );

      expect(find.text('health_records.select_animal'), findsOneWidget);
    });

    testWidgets('renders with bird list', (tester) async {
      await pumpLocalizedWidget(
        tester,
        HealthRecordAnimalSelector(
          selectedId: null,
          birds: [_testBird1, _testBird2],
          chicks: const [],
          isLoading: false,
          onChanged: (_) {},
        ),
        settle: false,
      );

      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField),
        findsOneWidget,
      );
    });

    testWidgets('renders with chick list', (tester) async {
      await pumpLocalizedWidget(
        tester,
        HealthRecordAnimalSelector(
          selectedId: null,
          birds: const [],
          chicks: [_testChick],
          isLoading: false,
          onChanged: (_) {},
        ),
        settle: false,
      );

      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField),
        findsOneWidget,
      );
    });

    testWidgets('calls onChanged when value selected', (tester) async {
      String? changedValue;

      await pumpLocalizedWidget(
        tester,
        HealthRecordAnimalSelector(
          selectedId: null,
          birds: [_testBird1],
          chicks: [_testChick],
          isLoading: false,
          onChanged: (value) => changedValue = value,
        ),
        settle: false,
      );

      await tester.tap(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tweety').last);
      await tester.pumpAndSettle();

      expect(changedValue, 'bird-1');
    });
  });
}
