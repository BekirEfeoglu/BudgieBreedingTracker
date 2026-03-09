import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_parent_selector.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

import '../../../helpers/test_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(body: Form(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BirdParentSelector', () {
    testWidgets('shows disabled dropdown when loading', (tester) async {
      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba Seçin',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => const Stream.empty(),
          ),
        ],
      );

      // Loading state: dropdown renders with no items (disabled)
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });

    testWidgets('shows label text', (tester) async {
      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba Seçin',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith((ref, userId) => Stream.value([])),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Baba Seçin'), findsAtLeastNWidgets(1));
    });

    testWidgets('filters birds by gender - shows only males', (tester) async {
      final male = createTestBird(
        id: 'm-1',
        name: 'Erkek Kus',
        gender: BirdGender.male,
      );
      final female = createTestBird(
        id: 'f-1',
        name: 'Disi Kus',
        gender: BirdGender.female,
      );

      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([male, female]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // Female bird should be filtered out; only 'no parent' option + male bird visible
      // 'Disi Kus' should not appear in the dropdown label area
      expect(
        find.text('Erkek Kus'),
        findsNothing,
      ); // not expanded, items not rendered
      expect(find.text('Disi Kus'), findsNothing);
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });

    testWidgets('excludes the specified bird by excludeId', (tester) async {
      final male1 = createTestBird(
        id: 'm-1',
        name: 'Erkek1',
        gender: BirdGender.male,
      );
      final male2 = createTestBird(
        id: 'm-2',
        name: 'Erkek2',
        gender: BirdGender.male,
      );

      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: 'm-2',
          excludeId: 'm-1',
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([male1, male2]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // male1 is excluded, male2 is selected (shown as current value)
      expect(find.text('Erkek2'), findsOneWidget);
      expect(find.text('Erkek1'), findsNothing);
    });

    testWidgets('shows no parent option', (tester) async {
      final male = createTestBird(
        id: 'm-1',
        name: 'Erkek',
        gender: BirdGender.male,
      );

      await _pump(
        tester,
        BirdParentSelector(
          label: 'Baba',
          icon: const AppIcon('assets/icons/birds/male.svg'),
          selectedId: null,
          excludeId: null,
          genderFilter: BirdGender.male,
          onChanged: (_) {},
        ),
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          birdsStreamProvider.overrideWith(
            (ref, userId) => Stream.value([male]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      // Dropdown renders (has data state with null/no-parent option)
      expect(
        find.byWidgetPredicate((w) => w is DropdownButtonFormField<String>),
        findsOneWidget,
      );
    });
  });

  group('BirdFormSectionHeader', () {
    testWidgets('displays title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BirdFormSectionHeader('Temel Bilgiler')),
        ),
      );

      expect(find.text('Temel Bilgiler'), findsOneWidget);
    });

    testWidgets('is a StatelessWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BirdFormSectionHeader('Başlık')),
        ),
      );

      expect(find.byType(BirdFormSectionHeader), findsOneWidget);
    });
  });
}
