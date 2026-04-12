import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_filter_bar.dart';

Widget _createSubject({
  HealthRecordFilter initialFilter = HealthRecordFilter.all,
}) {
  return ProviderScope(
    overrides: [
      healthRecordFilterProvider.overrideWith(
        () => _FakeFilterNotifier(initialFilter),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: HealthRecordFilterBar())),
  );
}

class _FakeFilterNotifier extends HealthRecordFilterNotifier {
  _FakeFilterNotifier(this._initial);
  final HealthRecordFilter _initial;

  @override
  HealthRecordFilter build() => _initial;
}

void main() {
  group('HealthRecordFilterBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(HealthRecordFilterBar), findsOneWidget);
    });

    testWidgets('shows ChoiceChip for each filter type', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      // FadeScrollableChipBar uses a horizontal ListView which lazily renders
      // only visible items. At minimum, the first chips should be in the tree.
      expect(find.byType(ChoiceChip), findsAtLeastNWidgets(1));
    });

    testWidgets('shows l10n label for "all" filter', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text(l10n('common.all')), findsOneWidget);
    });

    testWidgets('shows l10n label for "checkup" filter', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text('health_records.type_checkup'), findsOneWidget);
    });

    testWidgets('shows l10n label for "illness" filter', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text('health_records.type_illness'), findsOneWidget);
    });

    testWidgets('tapping a chip updates the filter provider', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthRecordFilterProvider.overrideWith(
              () => _FakeFilterNotifier(HealthRecordFilter.all),
            ),
          ],
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(body: HealthRecordFilterBar()),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('health_records.type_checkup'));
      await tester.pump();

      expect(
        container.read(healthRecordFilterProvider),
        HealthRecordFilter.checkup,
      );
    });
  });
}
